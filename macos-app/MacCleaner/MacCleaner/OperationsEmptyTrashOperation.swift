import Foundation

/// Empties the user's Trash folder
struct EmptyTrashOperation: CleanupOperation {
    
    let name = "Empty Trash"
    let description = "Permanently delete all items in the Trash"
    
    func execute() async throws -> CleanupResult {
        let trashURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash")
        let before = CleanupUtilities.folderSize(trashURL.path)
        let fm = FileManager.default
        var details: [String] = []
        
        if let contents = try? fm.contentsOfDirectory(at: trashURL, includingPropertiesForKeys: nil) {
            for item in contents {
                try? fm.removeItem(at: item)
                details.append("Deleted: \(item.lastPathComponent)")
            }
        }
        
        let freed = before - CleanupUtilities.folderSize(trashURL.path)
        return CleanupResult(
            freedBytes: freed,
            message: freed > 0 ? "Emptied \(CleanupUtilities.formatBytes(freed))" : "Trash was already empty",
            details: details
        )
    }
}
