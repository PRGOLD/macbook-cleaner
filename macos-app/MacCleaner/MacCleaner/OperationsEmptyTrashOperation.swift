import Foundation

/// Empties the user's Trash folder
struct EmptyTrashOperation: CleanupOperation {
    
    let name = "Empty Trash"
    let description = "Permanently delete all items in the Trash"
    
    /// Enable dry run mode (preview without deleting)
    var dryRun: Bool = false
    
    func execute() async throws -> CleanupResult {
        let trashURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash")
        let before = CleanupUtilities.folderSize(trashURL.path)
        let fm = FileManager.default
        var details: [String] = []
        
        if let contents = try? fm.contentsOfDirectory(at: trashURL, includingPropertiesForKeys: nil) {
            for item in contents {
                if dryRun {
                    details.append("Would delete: \(item.lastPathComponent)")
                } else {
                    try? fm.removeItem(at: item)
                    details.append("Deleted: \(item.lastPathComponent)")
                }
            }
        }
        
        let freed = dryRun ? before : (before - CleanupUtilities.folderSize(trashURL.path))
        let prefix = dryRun ? "[DRY RUN] Would empty" : "Emptied"
        return CleanupResult(
            freedBytes: freed,
            message: freed > 0 ? "\(prefix) \(CleanupUtilities.formatBytes(freed))" : "Trash was already empty",
            details: details
        )
    }
}
