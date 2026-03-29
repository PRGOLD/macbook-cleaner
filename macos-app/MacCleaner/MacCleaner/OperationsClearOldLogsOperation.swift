import Foundation

/// Clears old log files from the user's Library/Logs folder
struct ClearOldLogsOperation: CleanupOperation {
    
    let name = "Clear Old Logs"
    let description = "Remove log files older than 30 days"
    
    /// Enable dry run mode (preview without deleting)
    var dryRun: Bool = false
    
    /// Number of days after which log files should be deleted
    let daysOld: Int
    
    init(daysOld: Int = 30, dryRun: Bool = false) {
        self.daysOld = daysOld
        self.dryRun = dryRun
    }
    
    func execute() async throws -> CleanupResult {
        let logsPath = NSHomeDirectory() + "/Library/Logs"
        let before = CleanupUtilities.folderSize(logsPath)
        
        if dryRun {
            let prefix = "[DRY RUN] Would free"
            return CleanupResult(
                freedBytes: before,
                message: before > 0 ? "\(prefix) ~\(CleanupUtilities.formatBytes(before)) of old logs" : "No old logs found",
                details: ["Would remove .log and .log.gz files older than \(daysOld) days"]
            )
        }
        
        _ = try? CleanupUtilities.shell("find \"\(logsPath)\" -name '*.log' -mtime +\(daysOld) -delete 2>/dev/null")
        _ = try? CleanupUtilities.shell("find \"\(logsPath)\" -name '*.log.gz' -mtime +\(daysOld) -delete 2>/dev/null")
        
        let freed = max(0, before - CleanupUtilities.folderSize(logsPath))
        return CleanupResult(
            freedBytes: freed,
            message: freed > 0 ? "Freed \(CleanupUtilities.formatBytes(freed)) of old logs" : "No old logs found",
            details: ["Removed .log and .log.gz files older than \(daysOld) days"]
        )
    }
}
