import Foundation

struct CleanupEngine {

    // MARK: - Shell helper

    static func shell(_ args: String...) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", args.joined(separator: " ")]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func folderSize(_ path: String) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            total += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        }
        return total
    }

    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Sections

    static func emptyTrash() async throws -> CleanupResult {
        let trashURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash")
        let before = folderSize(trashURL.path)
        let fm = FileManager.default
        var details: [String] = []
        if let contents = try? fm.contentsOfDirectory(at: trashURL, includingPropertiesForKeys: nil) {
            for item in contents {
                try? fm.removeItem(at: item)
                details.append("Deleted: \(item.lastPathComponent)")
            }
        }
        let freed = before - folderSize(trashURL.path)
        return CleanupResult(
            freedBytes: freed,
            message: freed > 0 ? "Emptied \(formatBytes(freed))" : "Trash was already empty",
            details: details
        )
    }

    static func clearUserCaches() async throws -> CleanupResult {
        let cachesURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Caches")
        let before = folderSize(cachesURL.path)
        _ = try? shell("find \"\(cachesURL.path)\" -mindepth 1 -maxdepth 3 -type f -name '*.cache' -delete")
        _ = try? shell("find \"\(cachesURL.path)\" -mindepth 1 -maxdepth 3 -type d -empty -delete")
        let freed = max(0, before - folderSize(cachesURL.path))
        return CleanupResult(
            freedBytes: freed,
            message: freed > 0 ? "Freed \(formatBytes(freed)) from caches" : "Nothing to clear",
            details: ["Cleared stale .cache files from ~/Library/Caches"]
        )
    }

    static func clearTempFiles() async throws -> CleanupResult {
        let before1 = folderSize("/private/tmp")
        _ = try? shell("find /private/tmp -mindepth 1 -maxdepth 1 -mtime +3 -delete 2>/dev/null")
        _ = try? shell("find /private/var/folders -name '*.cache' -mtime +7 -delete 2>/dev/null")
        let freed = max(0, before1 - folderSize("/private/tmp"))
        return CleanupResult(
            freedBytes: freed,
            message: "Removed temp files older than 3 days",
            details: ["Cleared /private/tmp", "Cleared stale cache files in /private/var/folders"]
        )
    }

    static func clearOldLogs() async throws -> CleanupResult {
        let logsPath = NSHomeDirectory() + "/Library/Logs"
        let before = folderSize(logsPath)
        _ = try? shell("find \"\(logsPath)\" -name '*.log' -mtime +30 -delete 2>/dev/null")
        _ = try? shell("find \"\(logsPath)\" -name '*.log.gz' -mtime +30 -delete 2>/dev/null")
        let freed = max(0, before - folderSize(logsPath))
        return CleanupResult(
            freedBytes: freed,
            message: freed > 0 ? "Freed \(formatBytes(freed)) of old logs" : "No old logs found",
            details: ["Removed .log and .log.gz files older than 30 days"]
        )
    }

    static func clearXcodeDerivedData() async throws -> CleanupResult {
        let path = NSHomeDirectory() + "/Library/Developer/Xcode/DerivedData"
        guard FileManager.default.fileExists(atPath: path) else {
            return CleanupResult(freedBytes: 0, message: "No Xcode DerivedData found", details: [])
        }
        let before = folderSize(path)
        let fm = FileManager.default
        var details: [String] = []
        if let contents = try? fm.contentsOfDirectory(atPath: path) {
            for item in contents {
                try? fm.removeItem(atPath: path + "/" + item)
                details.append("Deleted: \(item)")
            }
        }
        let freed = max(0, before - folderSize(path))
        return CleanupResult(
            freedBytes: freed,
            message: "Freed \(formatBytes(freed)) from DerivedData",
            details: details
        )
    }

    static func findOrphanedAppSupport() async throws -> CleanupResult {
        var bundleIDs = Set<String>()
        var appNames = Set<String>()
        let appDirs = ["/Applications", NSHomeDirectory() + "/Applications", "/System/Applications"]
        for dir in appDirs {
            let fm = FileManager.default
            guard let enumerator = fm.enumerator(at: URL(fileURLWithPath: dir),
                                                  includingPropertiesForKeys: nil,
                                                  options: [.skipsPackageDescendants]) else { continue }
            for case let url as URL in enumerator where url.pathExtension == "app" {
                appNames.insert(url.deletingPathExtension().lastPathComponent.lowercased())
                let plist = url.appendingPathComponent("Contents/Info.plist")
                if let dict = NSDictionary(contentsOf: plist),
                   let bid = dict["CFBundleIdentifier"] as? String {
                    bundleIDs.insert(bid)
                }
            }
        }
        let scanDirs = [
            NSHomeDirectory() + "/Library/Application Support",
            NSHomeDirectory() + "/Library/Containers",
            NSHomeDirectory() + "/Library/Group Containers"
        ]
        var orphans: [(path: String, size: Int64)] = []
        let fm = FileManager.default
        for dir in scanDirs {
            guard let contents = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for item in contents {
                guard !item.hasPrefix(".") else { continue }
                let itemLc = item.lowercased()
                if itemLc.hasPrefix("com.apple.") || itemLc.hasPrefix("com.microsoft.") { continue }
                if bundleIDs.contains(item) { continue }
                if appNames.contains(itemLc) { continue }
                if bundleIDs.contains(where: { $0.lowercased().contains(itemLc) }) { continue }
                if item.count > 11, item.dropFirst(10).first == "." {
                    let stripped = String(item.dropFirst(11)).lowercased()
                    if bundleIDs.contains(where: { $0.lowercased().contains(stripped) }) { continue }
                }
                let fullPath = dir + "/" + item
                orphans.append((path: fullPath, size: folderSize(fullPath)))
            }
        }
        let totalFreeable = orphans.reduce(0) { $0 + $1.size }
        return CleanupResult(
            freedBytes: totalFreeable,
            message: orphans.isEmpty ? "No orphaned app leftovers found" : "Found \(orphans.count) orphaned folder(s) — \(formatBytes(totalFreeable)) recoverable",
            details: orphans.map { "\(formatBytes($0.size))  \($0.path)" }
        )
    }
    
    // MARK: - New Operations
    
    static func clearSafariCache() async throws -> CleanupResult {
        var op = ClearSafariCacheOperation()
        op.dryRun = CleanupSettings.shared.dryRunMode
        return try await op.execute()
    }
    
    static func clearOldDownloads() async throws -> CleanupResult {
        var op = ClearOldDownloadsOperation()
        op.dryRun = CleanupSettings.shared.dryRunMode
        return try await op.execute()
    }
    
    static func clearDeveloperCaches() async throws -> CleanupResult {
        var op = ClearDeveloperCachesOperation()
        op.dryRun = CleanupSettings.shared.dryRunMode
        return try await op.execute()
    }
    
    static func findDuplicateFiles() async throws -> CleanupResult {
        var op = FindDuplicateFilesOperation()
        op.dryRun = CleanupSettings.shared.dryRunMode
        return try await op.execute()
    }
    
    static func findLargestFiles() async throws -> CleanupResult {
        var op = FindLargestFilesOperation()
        op.dryRun = CleanupSettings.shared.dryRunMode
        return try await op.execute()
    }
}
