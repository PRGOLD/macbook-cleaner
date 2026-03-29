import Foundation

/// Clears old files from the Downloads folder
struct ClearOldDownloadsOperation: CleanupOperation {
    
    let name = "Clear Old Downloads"
    let description = "Remove download files older than a specified number of days"
    
    /// Enable dry run mode (preview without deleting)
    var dryRun: Bool = false
    
    /// Number of days after which downloads should be considered old
    let daysOld: Int
    
    /// Minimum file size to consider (ignore tiny files)
    let minimumFileSize: Int64
    
    /// File extensions to target (empty = all files)
    let targetExtensions: [String]
    
    init(daysOld: Int = 90, minimumFileSize: Int64 = 1024 * 1024, dryRun: Bool = false, targetExtensions: [String] = []) {
        self.daysOld = daysOld
        self.minimumFileSize = minimumFileSize
        self.dryRun = dryRun
        self.targetExtensions = targetExtensions
    }
    
    func execute() async throws -> CleanupResult {
        let fm = FileManager.default
        let downloadsURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads")
        
        guard fm.fileExists(atPath: downloadsURL.path) else {
            return CleanupResult(freedBytes: 0, message: "Downloads folder not found", details: [])
        }
        
        var totalFreed: Int64 = 0
        var details: [String] = []
        let cutoffDate = Date().addingTimeInterval(TimeInterval(-daysOld * 24 * 60 * 60))
        
        guard let contents = try? fm.contentsOfDirectory(at: downloadsURL, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey], options: [.skipsHiddenFiles]) else {
            return CleanupResult(freedBytes: 0, message: "Could not read Downloads folder", details: [])
        }
        
        for fileURL in contents {
            // Skip directories
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: fileURL.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
                continue
            }
            
            // Check file extension if specified
            if !targetExtensions.isEmpty && !targetExtensions.contains(fileURL.pathExtension.lowercased()) {
                continue
            }
            
            // Get file attributes
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                  let modDate = resourceValues.contentModificationDate,
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            
            // Check if file is old enough and large enough
            guard modDate < cutoffDate && Int64(fileSize) >= minimumFileSize else {
                continue
            }
            
            if dryRun {
                totalFreed += Int64(fileSize)
                details.append("Would delete: \(fileURL.lastPathComponent) (\(CleanupUtilities.formatBytes(Int64(fileSize))))")
            } else {
                do {
                    try fm.removeItem(at: fileURL)
                    totalFreed += Int64(fileSize)
                    details.append("Deleted: \(fileURL.lastPathComponent) (\(CleanupUtilities.formatBytes(Int64(fileSize))))")
                } catch {
                    details.append("Failed to delete: \(fileURL.lastPathComponent)")
                }
            }
        }
        
        let prefix = dryRun ? "[DRY RUN] Would free" : "Freed"
        return CleanupResult(
            freedBytes: totalFreed,
            message: totalFreed > 0 
                ? "\(prefix) \(CleanupUtilities.formatBytes(totalFreed)) from Downloads (older than \(daysOld) days)" 
                : "No old downloads found",
            details: details.isEmpty ? ["No files matched criteria (>\(daysOld) days old, >\(CleanupUtilities.formatBytes(minimumFileSize)))"] : details
        )
    }
}
