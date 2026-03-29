import Foundation

/// Central coordinator for all cleanup operations
struct CleanupEngine {
    
    // MARK: - Backward Compatibility Methods
    
    /// These methods maintain backward compatibility with existing code
    /// while delegating to the new modular operation structs
    
    static func emptyTrash() async throws -> CleanupResult {
        var op = EmptyTrashOperation()
        op.dryRun = CleanupSettings.shared.dryRunMode
        return try await op.execute()
    }
    
    static func clearUserCaches() async throws -> CleanupResult {
        var op = ClearUserCachesOperation()
        op.dryRun = CleanupSettings.shared.dryRunMode
        return try await op.execute()
    }
    
    static func clearTempFiles() async throws -> CleanupResult {
        var op = ClearTempFilesOperation(
            daysOld: CleanupSettings.shared.tempFileRetentionDays,
            cacheDaysOld: CleanupSettings.shared.cacheRetentionDays
        )
        op.dryRun = CleanupSettings.shared.dryRunMode
        return try await op.execute()
    }
    
    static func clearOldLogs() async throws -> CleanupResult {
        var op = ClearOldLogsOperation(daysOld: CleanupSettings.shared.logRetentionDays)
        op.dryRun = CleanupSettings.shared.dryRunMode
        return try await op.execute()
    }
    
    static func clearXcodeDerivedData() async throws -> CleanupResult {
        var op = ClearXcodeDerivedDataOperation()
        op.dryRun = CleanupSettings.shared.dryRunMode
        return try await op.execute()
    }
    
    static func findOrphanedAppSupport() async throws -> CleanupResult {
        var op = FindOrphanedAppSupportOperation()
        op.dryRun = CleanupSettings.shared.dryRunMode
        return try await op.execute()
    }
    
    // MARK: - New Operations
    
    static func clearSafariCache() async throws -> CleanupResult {
        let settings = CleanupSettings.shared
        var op = ClearSafariCacheOperation(
            dryRun: settings.dryRunMode,
            clearCookies: settings.clearSafariCookies,
            clearHistory: settings.clearSafariHistory
        )
        op.dryRun = settings.dryRunMode
        return try await op.execute()
    }
    
    static func clearOldDownloads() async throws -> CleanupResult {
        let settings = CleanupSettings.shared
        var op = ClearOldDownloadsOperation(
            daysOld: settings.downloadRetentionDays,
            minimumFileSize: settings.minimumFileSize,
            dryRun: settings.dryRunMode
        )
        op.dryRun = settings.dryRunMode
        return try await op.execute()
    }
    
    static func clearDeveloperCaches() async throws -> CleanupResult {
        let settings = CleanupSettings.shared
        var op = ClearDeveloperCachesOperation(
            dryRun: settings.dryRunMode,
            clearNpm: settings.clearNpmCache,
            clearHomebrew: settings.clearHomebrewCache,
            clearCocoaPods: settings.clearCocoaPodsCache
        )
        op.dryRun = settings.dryRunMode
        return try await op.execute()
    }
    
    // MARK: - Legacy Utility Methods (Deprecated)
    
    /// Use CleanupUtilities.shell() instead
    @available(*, deprecated, message: "Use CleanupUtilities.shell() instead")
    static func shell(_ args: String...) throws -> String {
        try CleanupUtilities.shell(args.joined(separator: " "))
    }
    
    /// Use CleanupUtilities.folderSize() instead
    @available(*, deprecated, message: "Use CleanupUtilities.folderSize() instead")
    static func folderSize(_ path: String) -> Int64 {
        CleanupUtilities.folderSize(path)
    }
    
    /// Use CleanupUtilities.formatBytes() instead
    @available(*, deprecated, message: "Use CleanupUtilities.formatBytes() instead")
    static func formatBytes(_ bytes: Int64) -> String {
        CleanupUtilities.formatBytes(bytes)
    }
    
    // MARK: - Batch Operations
    
    /// All available cleanup operations
    static var allOperations: [any CleanupOperation] {
        let settings = CleanupSettings.shared
        return [
            EmptyTrashOperation(dryRun: settings.dryRunMode),
            ClearUserCachesOperation(dryRun: settings.dryRunMode),
            ClearTempFilesOperation(daysOld: settings.tempFileRetentionDays, cacheDaysOld: settings.cacheRetentionDays, dryRun: settings.dryRunMode),
            ClearOldLogsOperation(daysOld: settings.logRetentionDays, dryRun: settings.dryRunMode),
            ClearXcodeDerivedDataOperation(dryRun: settings.dryRunMode),
            ClearSafariCacheOperation(dryRun: settings.dryRunMode, clearCookies: settings.clearSafariCookies, clearHistory: settings.clearSafariHistory),
            ClearOldDownloadsOperation(daysOld: settings.downloadRetentionDays, minimumFileSize: settings.minimumFileSize, dryRun: settings.dryRunMode),
            ClearDeveloperCachesOperation(dryRun: settings.dryRunMode, clearNpm: settings.clearNpmCache, clearHomebrew: settings.clearHomebrewCache, clearCocoaPods: settings.clearCocoaPodsCache),
            FindOrphanedAppSupportOperation(dryRun: settings.dryRunMode)
        ]
    }
    
    /// Execute multiple operations in sequence
    static func executeOperations(_ operations: [any CleanupOperation]) async throws -> [CleanupResult] {
        var results: [CleanupResult] = []
        for operation in operations {
            let result = try await operation.execute()
            results.append(result)
        }
        return results
    }
    
    /// Execute all available operations
    static func executeAll() async throws -> [CleanupResult] {
        try await executeOperations(allOperations)
    }
}
