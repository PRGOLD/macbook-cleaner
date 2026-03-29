import Foundation

/// Clears temporary files older than a specified number of days
struct ClearTempFilesOperation: CleanupOperation {
    
    let name = "Clear Temp Files"
    let description = "Remove temporary files older than 3 days"
    
    /// Number of days after which temp files should be deleted
    let daysOld: Int
    
    /// Number of days for cache files in /private/var/folders
    let cacheDaysOld: Int
    
    init(daysOld: Int = 3, cacheDaysOld: Int = 7) {
        self.daysOld = daysOld
        self.cacheDaysOld = cacheDaysOld
    }
    
    func execute() async throws -> CleanupResult {
        let before1 = CleanupUtilities.folderSize("/private/tmp")
        
        _ = try? CleanupUtilities.shell("find /private/tmp -mindepth 1 -maxdepth 1 -mtime +\(daysOld) -delete 2>/dev/null")
        _ = try? CleanupUtilities.shell("find /private/var/folders -name '*.cache' -mtime +\(cacheDaysOld) -delete 2>/dev/null")
        
        let freed = max(0, before1 - CleanupUtilities.folderSize("/private/tmp"))
        return CleanupResult(
            freedBytes: freed,
            message: "Removed temp files older than \(daysOld) days",
            details: [
                "Cleared /private/tmp",
                "Cleared stale cache files in /private/var/folders"
            ]
        )
    }
}
