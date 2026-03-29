import Foundation

/// Clears stale cache files from the user's Library/Caches folder
struct ClearUserCachesOperation: CleanupOperation {
    
    let name = "Clear User Caches"
    let description = "Remove stale .cache files from ~/Library/Caches"
    
    func execute() async throws -> CleanupResult {
        let cachesURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Caches")
        let before = CleanupUtilities.folderSize(cachesURL.path)
        
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
