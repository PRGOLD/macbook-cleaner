import Foundation

/// Finds application support folders for apps that are no longer installed
struct FindOrphanedAppSupportOperation: CleanupOperation {
    
    let name = "Find Orphaned App Support"
    let description = "Detect leftover files from uninstalled applications"
    
    /// Directories to scan for installed applications
    let appDirectories: [String]
    
    /// Directories to scan for orphaned support files
    let scanDirectories: [String]
    
    init(
        appDirectories: [String] = [
            "/Applications",
            NSHomeDirectory() + "/Applications",
            "/System/Applications"
        ],
        scanDirectories: [String] = [
            NSHomeDirectory() + "/Library/Application Support",
            NSHomeDirectory() + "/Library/Containers",
            NSHomeDirectory() + "/Library/Group Containers"
        ]
    ) {
        self.appDirectories = appDirectories
        self.scanDirectories = scanDirectories
    }
    
    func execute() async throws -> CleanupResult {
        // Build a set of installed app bundle IDs and names
        var bundleIDs = Set<String>()
        var appNames = Set<String>()
        
        for dir in appDirectories {
            let fm = FileManager.default
            guard let enumerator = fm.enumerator(
                at: URL(fileURLWithPath: dir),
                includingPropertiesForKeys: nil,
                options: [.skipsPackageDescendants]
            ) else { continue }
            
            for case let url as URL in enumerator where url.pathExtension == "app" {
                appNames.insert(url.deletingPathExtension().lastPathComponent.lowercased())
                let plist = url.appendingPathComponent("Contents/Info.plist")
                if let dict = NSDictionary(contentsOf: plist),
                   let bid = dict["CFBundleIdentifier"] as? String {
                    bundleIDs.insert(bid)
                }
            }
        }
        
        // Scan for orphaned support folders
        var orphans: [(path: String, size: Int64)] = []
        let fm = FileManager.default
        
        for dir in scanDirectories {
            guard let contents = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            
            for item in contents {
                guard !item.hasPrefix(".") else { continue }
                let itemLc = item.lowercased()
                
                // Skip known system directories
                if itemLc.hasPrefix("com.apple.") || itemLc.hasPrefix("com.microsoft.") { continue }
                
                // Check if this folder matches an installed app
                if bundleIDs.contains(item) { continue }
                if appNames.contains(itemLc) { continue }
                if bundleIDs.contains(where: { $0.lowercased().contains(itemLc) }) { continue }
                
                // Handle container naming pattern (e.g., "XXXXXXXXXX.com.example.app")
                if item.count > 11, item.dropFirst(10).first == "." {
                    let stripped = String(item.dropFirst(11)).lowercased()
                    if bundleIDs.contains(where: { $0.lowercased().contains(stripped) }) { continue }
                }
                
                // This appears to be orphaned
                let fullPath = dir + "/" + item
                orphans.append((path: fullPath, size: CleanupUtilities.folderSize(fullPath)))
            }
        }
        
        let totalFreeable = orphans.reduce(0) { $0 + $1.size }
        return CleanupResult(
            freedBytes: totalFreeable,
            message: orphans.isEmpty 
                ? "No orphaned app leftovers found" 
                : "Found \(orphans.count) orphaned folder(s) — \(CleanupUtilities.formatBytes(totalFreeable)) recoverable",
            details: orphans.map { "\(CleanupUtilities.formatBytes($0.size))  \($0.path)" }
        )
    }
}
