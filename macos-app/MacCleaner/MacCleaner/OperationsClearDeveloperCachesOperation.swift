import Foundation

/// Clears developer tool caches (npm, Homebrew, CocoaPods, etc.)
struct ClearDeveloperCachesOperation: CleanupOperation {
    
    let name = "Clear Developer Caches"
    let description = "Remove caches from npm, Homebrew, CocoaPods, and other dev tools"
    
    /// Enable dry run mode (preview without deleting)
    var dryRun: Bool = false
    
    /// Clear npm cache
    let clearNpm: Bool
    
    /// Clear Homebrew cache
    let clearHomebrew: Bool
    
    /// Clear CocoaPods cache
    let clearCocoaPods: Bool
    
    /// Clear Yarn cache
    let clearYarn: Bool
    
    /// Clear pip cache
    let clearPip: Bool
    
    init(dryRun: Bool = false, clearNpm: Bool = true, clearHomebrew: Bool = true, clearCocoaPods: Bool = true, clearYarn: Bool = true, clearPip: Bool = true) {
        self.dryRun = dryRun
        self.clearNpm = clearNpm
        self.clearHomebrew = clearHomebrew
        self.clearCocoaPods = clearCocoaPods
        self.clearYarn = clearYarn
        self.clearPip = clearPip
    }
    
    func execute() async throws -> CleanupResult {
        let fm = FileManager.default
        var totalFreed: Int64 = 0
        var details: [String] = []
        
        // npm cache
        if clearNpm {
            let npmCachePath = NSHomeDirectory() + "/.npm"
            if fm.fileExists(atPath: npmCachePath) {
                let sizeBefore = CleanupUtilities.folderSize(npmCachePath)
                
                if dryRun {
                    totalFreed += sizeBefore
                    details.append("Would clear npm cache (\(CleanupUtilities.formatBytes(sizeBefore)))")
                } else {
                    _ = try? CleanupUtilities.shell("npm cache clean --force 2>/dev/null")
                    let freed = sizeBefore - CleanupUtilities.folderSize(npmCachePath)
                    if freed > 0 {
                        totalFreed += freed
                        details.append("Cleared npm cache (\(CleanupUtilities.formatBytes(freed)))")
                    }
                }
            }
        }
        
        // Homebrew cache
        if clearHomebrew {
            let brewCachePath = NSHomeDirectory() + "/Library/Caches/Homebrew"
            if fm.fileExists(atPath: brewCachePath) {
                let sizeBefore = CleanupUtilities.folderSize(brewCachePath)
                
                if dryRun {
                    totalFreed += sizeBefore
                    details.append("Would clear Homebrew cache (\(CleanupUtilities.formatBytes(sizeBefore)))")
                } else {
                    _ = try? CleanupUtilities.shell("brew cleanup --prune=all 2>/dev/null")
                    let freed = sizeBefore - CleanupUtilities.folderSize(brewCachePath)
                    if freed > 0 {
                        totalFreed += freed
                        details.append("Cleared Homebrew cache (\(CleanupUtilities.formatBytes(freed)))")
                    }
                }
            }
        }
        
        // CocoaPods cache
        if clearCocoaPods {
            let podsCachePath = NSHomeDirectory() + "/Library/Caches/CocoaPods"
            if fm.fileExists(atPath: podsCachePath) {
                let sizeBefore = CleanupUtilities.folderSize(podsCachePath)
                
                if dryRun {
                    totalFreed += sizeBefore
                    details.append("Would clear CocoaPods cache (\(CleanupUtilities.formatBytes(sizeBefore)))")
                } else {
                    _ = try? CleanupUtilities.shell("pod cache clean --all 2>/dev/null")
                    let freed = sizeBefore - CleanupUtilities.folderSize(podsCachePath)
                    if freed > 0 {
                        totalFreed += freed
                        details.append("Cleared CocoaPods cache (\(CleanupUtilities.formatBytes(freed)))")
                    }
                }
            }
        }
        
        // Yarn cache
        if clearYarn {
            let yarnCachePath = NSHomeDirectory() + "/Library/Caches/Yarn"
            if fm.fileExists(atPath: yarnCachePath) {
                let sizeBefore = CleanupUtilities.folderSize(yarnCachePath)
                
                if dryRun {
                    totalFreed += sizeBefore
                    details.append("Would clear Yarn cache (\(CleanupUtilities.formatBytes(sizeBefore)))")
                } else {
                    _ = try? CleanupUtilities.shell("yarn cache clean 2>/dev/null")
                    let freed = sizeBefore - CleanupUtilities.folderSize(yarnCachePath)
                    if freed > 0 {
                        totalFreed += freed
                        details.append("Cleared Yarn cache (\(CleanupUtilities.formatBytes(freed)))")
                    }
                }
            }
        }
        
        // pip cache
        if clearPip {
            let pipCachePath = NSHomeDirectory() + "/Library/Caches/pip"
            if fm.fileExists(atPath: pipCachePath) {
                let sizeBefore = CleanupUtilities.folderSize(pipCachePath)
                
                if dryRun {
                    totalFreed += sizeBefore
                    details.append("Would clear pip cache (\(CleanupUtilities.formatBytes(sizeBefore)))")
                } else {
                    _ = try? CleanupUtilities.shell("pip cache purge 2>/dev/null || pip3 cache purge 2>/dev/null")
                    let freed = sizeBefore - CleanupUtilities.folderSize(pipCachePath)
                    if freed > 0 {
                        totalFreed += freed
                        details.append("Cleared pip cache (\(CleanupUtilities.formatBytes(freed)))")
                    }
                }
            }
        }
        
        let prefix = dryRun ? "[DRY RUN] Would free" : "Freed"
        return CleanupResult(
            freedBytes: totalFreed,
            message: totalFreed > 0 
                ? "\(prefix) \(CleanupUtilities.formatBytes(totalFreed)) from developer caches" 
                : "No developer caches found",
            details: details.isEmpty ? ["No developer caches found on this system"] : details
        )
    }
}
