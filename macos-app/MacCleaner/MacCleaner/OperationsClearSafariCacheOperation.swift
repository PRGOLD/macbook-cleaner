import Foundation

/// Clears Safari browser cache and data
struct ClearSafariCacheOperation: CleanupOperation {
    
    let name = "Clear Safari Cache"
    let description = "Remove Safari browser cache and temporary files"
    
    /// Enable dry run mode (preview without deleting)
    var dryRun: Bool = false
    
    /// Clear cookies (off by default for safety)
    let clearCookies: Bool
    
    /// Clear history (off by default for safety)
    let clearHistory: Bool
    
    init(dryRun: Bool = false, clearCookies: Bool = false, clearHistory: Bool = false) {
        self.dryRun = dryRun
        self.clearCookies = clearCookies
        self.clearHistory = clearHistory
    }
    
    func execute() async throws -> CleanupResult {
        let fm = FileManager.default
        var totalFreed: Int64 = 0
        var details: [String] = []
        
        // Safari cache locations
        let cachePaths = [
            NSHomeDirectory() + "/Library/Caches/com.apple.Safari",
            NSHomeDirectory() + "/Library/Caches/com.apple.WebKit.Networking",
            NSHomeDirectory() + "/Library/Safari/LocalStorage",
            NSHomeDirectory() + "/Library/Safari/Databases"
        ]
        
        for path in cachePaths {
            guard fm.fileExists(atPath: path) else { continue }
            
            let sizeBefore = CleanupUtilities.folderSize(path)
            
            if dryRun {
                totalFreed += sizeBefore
                details.append("Would clear: \(path.split(separator: "/").last ?? "") (\(CleanupUtilities.formatBytes(sizeBefore)))")
            } else {
                if let contents = try? fm.contentsOfDirectory(atPath: path) {
                    for item in contents {
                        try? fm.removeItem(atPath: path + "/" + item)
                    }
                }
                let freed = sizeBefore - CleanupUtilities.folderSize(path)
                if freed > 0 {
                    totalFreed += freed
                    details.append("Cleared: \(path.split(separator: "/").last ?? "") (\(CleanupUtilities.formatBytes(freed)))")
                }
            }
        }
        
        // Optional: Clear cookies
        if clearCookies {
            let cookiesPath = NSHomeDirectory() + "/Library/Cookies"
            if fm.fileExists(atPath: cookiesPath) {
                let sizeBefore = CleanupUtilities.folderSize(cookiesPath)
                if dryRun {
                    totalFreed += sizeBefore
                    details.append("Would clear cookies (\(CleanupUtilities.formatBytes(sizeBefore)))")
                } else {
                    _ = try? CleanupUtilities.shell("find \"\(cookiesPath)\" -name '*.binarycookies' -delete")
                    let freed = sizeBefore - CleanupUtilities.folderSize(cookiesPath)
                    totalFreed += freed
                    details.append("Cleared cookies (\(CleanupUtilities.formatBytes(freed)))")
                }
            }
        }
        
        // Optional: Clear history
        if clearHistory {
            let historyPath = NSHomeDirectory() + "/Library/Safari/History.db"
            if fm.fileExists(atPath: historyPath) {
                if dryRun {
                    details.append("Would clear browsing history")
                } else {
                    try? fm.removeItem(atPath: historyPath)
                    details.append("Cleared browsing history")
                }
            }
        }
        
        let prefix = dryRun ? "[DRY RUN] Would free" : "Freed"
        return CleanupResult(
            freedBytes: totalFreed,
            message: totalFreed > 0 ? "\(prefix) \(CleanupUtilities.formatBytes(totalFreed)) from Safari" : "No Safari cache found",
            details: details
        )
    }
}
