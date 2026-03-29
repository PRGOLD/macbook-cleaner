import Foundation

/// Clears stale cache files from the user's Library/Caches folder
struct ClearUserCachesOperation: CleanupOperation {
    
    let name = "Clear User Caches"
    let description = "Remove stale .cache files from ~/Library/Caches"
    
    /// Enable dry run mode (preview without deleting)
    var dryRun: Bool = false
    
    func execute() async throws -> CleanupResult {
        let cachesURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Caches")
        let before = CleanupUtilities.folderSize(cachesURL.path)
        
        if dryRun {
            // Count files that would be deleted
            let findCmd = "find \"\(cachesURL.path)\" -mindepth 1 -maxdepth 3 -type f -name '*.cache'"
            let output = try? CleanupUtilities.shell(findCmd)
            let fileCount = output?.split(separator: "\n").count ?? 0
            
            return CleanupResult(
                freedBytes: before,
                message: "[DRY RUN] Would free ~\(CleanupUtilities.formatBytes(before)) from caches",
                details: ["Would clear \(fileCount) .cache files from ~/Library/Caches"]
            )
        }
        
        _ = try? CleanupUtilities.shell("find \"\(cachesURL.path)\" -mindepth 1 -maxdepth 3 -type f -name '*.cache' -delete")
        _ = try? CleanupUtilities.shell("find \"\(cachesURL.path)\" -mindepth 1 -maxdepth 3 -type d -empty -delete")
        
        let freed = max(0, before - CleanupUtilities.folderSize(cachesURL.path))
        return CleanupResult(
            freedBytes: freed,
            message: freed > 0 ? "Freed \(CleanupUtilities.formatBytes(freed)) from caches" : "Nothing to clear",
            details: ["Cleared stale .cache files from ~/Library/Caches"]
        )
    }
}
