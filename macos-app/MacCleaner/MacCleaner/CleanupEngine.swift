import Foundation

/// Central coordinator for all cleanup operations
struct CleanupEngine {
    
    // MARK: - Backward Compatibility Methods
    
    /// These methods maintain backward compatibility with existing code
    /// while delegating to the new modular operation structs
    
    static func emptyTrash() async throws -> CleanupResult {
        try await EmptyTrashOperation().execute()
    }
    
    static func clearUserCaches() async throws -> CleanupResult {
        try await ClearUserCachesOperation().execute()
    }
    
    static func clearTempFiles() async throws -> CleanupResult {
        try await ClearTempFilesOperation().execute()
    }
    
    static func clearOldLogs() async throws -> CleanupResult {
        try await ClearOldLogsOperation().execute()
    }
    
    static func clearXcodeDerivedData() async throws -> CleanupResult {
        try await ClearXcodeDerivedDataOperation().execute()
    }
    
    static func findOrphanedAppSupport() async throws -> CleanupResult {
        try await FindOrphanedAppSupportOperation().execute()
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
        [
            EmptyTrashOperation(),
            ClearUserCachesOperation(),
            ClearTempFilesOperation(),
            ClearOldLogsOperation(),
            ClearXcodeDerivedDataOperation(),
            FindOrphanedAppSupportOperation()
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
