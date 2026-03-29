import Combine
import Foundation
import SwiftUI

struct DiskInfo {
    let total: Int64
    let free: Int64
    var used: Int64 { total - free }
    var usedFraction: Double { total > 0 ? Double(used) / Double(total) : 0 }
    private static let fmt: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useGB, .useTB]
        f.countStyle = .file
        return f
    }()
    var totalFormatted: String { Self.fmt.string(fromByteCount: total) }
    var freeFormatted: String  { Self.fmt.string(fromByteCount: free) }
    var usedFormatted: String  { Self.fmt.string(fromByteCount: used) }
}

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var diskInfo: DiskInfo?
    @Published var isRunning = false

    var totalFreed: Int64 {
        sections.compactMap(\.result?.freedBytes).reduce(0, +)
    }

    lazy var sections: [CleanupSection] = [
        CleanupSection(id: "trash", icon: "trash.fill", title: "Empty Trash",
                       description: "Permanently removes everything in your Trash") {
            try await CleanupEngine.emptyTrash()
        },
        CleanupSection(id: "caches", icon: "internaldrive", title: "User Caches",
                       description: "Clears stale cache files from ~/Library/Caches") {
            try await CleanupEngine.clearUserCaches()
        },
        CleanupSection(id: "temp", icon: "thermometer.medium", title: "Temp Files",
                       description: "Removes temporary files older than 3 days") {
            try await CleanupEngine.clearTempFiles()
        },
        CleanupSection(id: "logs", icon: "doc.text", title: "Old Logs",
                       description: "Deletes log files older than 30 days") {
            try await CleanupEngine.clearOldLogs()
        },
        CleanupSection(id: "xcode", icon: "hammer.fill", title: "Xcode DerivedData",
                       description: "Clears Xcode build artefacts (safe to delete)") {
            try await CleanupEngine.clearXcodeDerivedData()
        },
        CleanupSection(id: "safari", icon: "safari", title: "Safari Cache",
                       description: "Remove browser cache and temporary files") {
            try await CleanupEngine.clearSafariCache()
        },
        CleanupSection(id: "downloads", icon: "arrow.down.circle.fill", title: "Old Downloads",
                       description: "Remove downloads older than 90 days") {
            try await CleanupEngine.clearOldDownloads()
        },
        CleanupSection(id: "developer", icon: "hammer.circle.fill", title: "Developer Caches",
                       description: "Clear npm, Homebrew, CocoaPods caches") {
            try await CleanupEngine.clearDeveloperCaches()
        },
        CleanupSection(id: "duplicates", icon: "doc.on.doc.fill", title: "Duplicate Files",
                       description: "Find duplicate files to free up space") {
            try await CleanupEngine.findDuplicateFiles()
        },
        CleanupSection(id: "largest", icon: "chart.bar.fill", title: "Largest Files",
                       description: "Locate the biggest files eating up disk space") {
            try await CleanupEngine.findLargestFiles()
        },
        CleanupSection(id: "orphans", icon: "questionmark.folder.fill", title: "Orphaned App Data",
                       description: "Finds leftover files from deleted applications") {
            try await CleanupEngine.findOrphanedAppSupport()
        }
    ]

    func runAll() async {
        isRunning = true
        for section in sections { await section.run() }
        await refreshDiskInfo()
        isRunning = false
    }

    func refreshDiskInfo() async {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
           let total = attrs[.systemSize] as? Int64,
           let free = attrs[.systemFreeSize] as? Int64 {
            diskInfo = DiskInfo(total: total, free: free)
        }
    }
}
