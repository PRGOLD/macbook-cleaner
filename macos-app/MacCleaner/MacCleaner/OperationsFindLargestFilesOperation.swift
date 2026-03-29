import Foundation

/// Finds the largest files on the system
struct FindLargestFilesOperation: CleanupOperation {
    
    let name = "Find Largest Files"
    let description = "Locate the biggest files eating up disk space"
    
    /// Enable dry run mode (preview without deleting)
    var dryRun: Bool = false
    
    /// Directories to scan
    let scanDirectories: [String]
    
    /// Number of largest files to find
    let topCount: Int
    
    /// Minimum file size to consider (in bytes)
    let minimumFileSize: Int64
    
    init(
        dryRun: Bool = false,
        scanDirectories: [String] = [
            NSHomeDirectory() + "/Documents",
            NSHomeDirectory() + "/Downloads",
            NSHomeDirectory() + "/Desktop",
            NSHomeDirectory() + "/Movies",
            NSHomeDirectory() + "/Pictures"
        ],
        topCount: Int = 20,
        minimumFileSize: Int64 = 100 * 1024 * 1024 // 100 MB
    ) {
        self.dryRun = dryRun
        self.scanDirectories = scanDirectories
        self.topCount = topCount
        self.minimumFileSize = minimumFileSize
    }
    
    func execute() async throws -> CleanupResult {
        struct FileInfo {
            let url: URL
            let size: Int64
        }
        
        var largeFiles: [FileInfo] = []
        let fm = FileManager.default
        
        // Scan directories
        for directory in scanDirectories {
            guard fm.fileExists(atPath: directory) else { continue }
            
            guard let enumerator = fm.enumerator(
                at: URL(fileURLWithPath: directory),
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }
            
            for case let fileURL as URL in enumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                      let isRegularFile = resourceValues.isRegularFile,
                      isRegularFile,
                      let fileSize = resourceValues.fileSize,
                      Int64(fileSize) >= minimumFileSize else {
                    continue
                }
                
                largeFiles.append(FileInfo(url: fileURL, size: Int64(fileSize)))
            }
        }
        
        // Sort by size and take top N
        largeFiles.sort { $0.size > $1.size }
        let topFiles = Array(largeFiles.prefix(topCount))
        
        // Calculate total size
        let totalSize = topFiles.reduce(0) { $0 + $1.size }
        
        // Create details
        var details: [String] = []
        for (index, file) in topFiles.enumerated() {
            let sizeStr = CleanupUtilities.formatBytes(file.size)
            details.append("\(index + 1). \(sizeStr) - \(file.url.lastPathComponent)")
            details.append("   📍 \(file.url.deletingLastPathComponent().path)")
        }
        
        let message: String
        if topFiles.isEmpty {
            message = "No large files found (>\(CleanupUtilities.formatBytes(minimumFileSize)))"
        } else {
            message = "Found \(topFiles.count) large files totaling \(CleanupUtilities.formatBytes(totalSize))"
        }
        
        return CleanupResult(
            freedBytes: totalSize,
            message: message,
            details: details.isEmpty ? ["No files larger than \(CleanupUtilities.formatBytes(minimumFileSize))"] : details
        )
    }
}
