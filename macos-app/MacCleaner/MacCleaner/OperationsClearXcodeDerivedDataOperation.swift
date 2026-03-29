import Foundation

/// Clears Xcode's DerivedData folder
struct ClearXcodeDerivedDataOperation: CleanupOperation {
    
    let name = "Clear Xcode DerivedData"
    let description = "Remove Xcode build artifacts and intermediate files"
    
    func execute() async throws -> CleanupResult {
        let path = NSHomeDirectory() + "/Library/Developer/Xcode/DerivedData"
        guard FileManager.default.fileExists(atPath: path) else {
            return CleanupResult(freedBytes: 0, message: "No Xcode DerivedData found", details: [])
        }
        
        let before = CleanupUtilities.folderSize(path)
        let fm = FileManager.default
        var details: [String] = []
        
        if let contents = try? fm.contentsOfDirectory(atPath: path) {
            for item in contents {
                try? fm.removeItem(atPath: path + "/" + item)
                details.append("Deleted: \(item)")
            }
        }
        
        let freed = max(0, before - CleanupUtilities.folderSize(path))
        return CleanupResult(
            freedBytes: freed,
            message: "Freed \(CleanupUtilities.formatBytes(freed)) from DerivedData",
            details: details
        )
    }
}
