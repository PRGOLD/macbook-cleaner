import Foundation
import CryptoKit

/// Finds duplicate files based on content hash
struct FindDuplicateFilesOperation: CleanupOperation {
    
    let name = "Find Duplicate Files"
    let description = "Locate duplicate files to free up space"
    
    /// Enable dry run mode (preview without deleting)
    var dryRun: Bool = false
    
    /// Directories to scan for duplicates
    let scanDirectories: [String]
    
    /// Minimum file size to check (skip tiny files)
    let minimumFileSize: Int64
    
    init(
        dryRun: Bool = false,
        scanDirectories: [String] = [
            NSHomeDirectory() + "/Documents",
            NSHomeDirectory() + "/Downloads",
            NSHomeDirectory() + "/Desktop"
        ],
        minimumFileSize: Int64 = 1024 * 1024 // 1 MB
    ) {
        self.dryRun = dryRun
        self.scanDirectories = scanDirectories
        self.minimumFileSize = minimumFileSize
    }
    
    func execute() async throws -> CleanupResult {
        var filesByHash: [String: [URL]] = [:]
        var totalSize: Int64 = 0
        var details: [String] = []
        
        let fm = FileManager.default
        
        // Scan directories for files
        for directory in scanDirectories {
            guard fm.fileExists(atPath: directory) else { continue }
            
            guard let enumerator = fm.enumerator(
                at: URL(fileURLWithPath: directory),
                includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }
            
            for case let fileURL as URL in enumerator {
                // Skip directories
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                      let isRegularFile = resourceValues.isRegularFile,
                      isRegularFile,
                      let fileSize = resourceValues.fileSize,
                      Int64(fileSize) >= minimumFileSize else {
                    continue
                }
                
                // Calculate hash
                if let hash = hashFile(at: fileURL) {
                    filesByHash[hash, default: []].append(fileURL)
                }
            }
        }
        
        // Find duplicates
        var duplicateGroups: [[URL]] = []
        for (_, urls) in filesByHash where urls.count > 1 {
            duplicateGroups.append(urls)
        }
        
        // Calculate space that could be freed
        for group in duplicateGroups {
            if let firstFile = group.first,
               let resourceValues = try? firstFile.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                // All duplicates except one can be deleted
                let duplicatesSize = Int64(fileSize) * Int64(group.count - 1)
                totalSize += duplicatesSize
                
                let sizeStr = CleanupUtilities.formatBytes(Int64(fileSize))
                details.append("📁 \(group.count) copies of '\(firstFile.lastPathComponent)' (\(sizeStr) each)")
                for (index, url) in group.enumerated() {
                    details.append("  \(index == 0 ? "✓" : "  ") \(url.path)")
                }
            }
        }
        
        let prefix = dryRun ? "[DRY RUN] Would free" : "Could free"
        let message: String
        if duplicateGroups.isEmpty {
            message = "No duplicate files found"
        } else {
            message = "\(prefix) \(CleanupUtilities.formatBytes(totalSize)) by removing \(duplicateGroups.count) set(s) of duplicates"
        }
        
        return CleanupResult(
            freedBytes: totalSize,
            message: message,
            details: details.isEmpty ? ["No duplicates found in scanned directories"] : details
        )
    }
    
    /// Hash a file's contents using SHA256
    private func hashFile(at url: URL) -> String? {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            return nil
        }
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
