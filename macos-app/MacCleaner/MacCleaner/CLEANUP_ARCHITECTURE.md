# Cleanup Engine - Modular Architecture

This document describes the refactored cleanup engine architecture that separates each cleanup operation into individual, reusable components.

## Structure

### Core Components

- **`CleanupOperation.swift`** - Protocol that all cleanup operations conform to
- **`CleanupUtilities.swift`** - Shared utility functions (shell execution, size calculation, formatting)
- **`CleanupEngine.swift`** - Main coordinator that provides backward compatibility and batch operations

### Individual Operations

Each operation is now a separate struct in the `Operations/` folder:

- **`EmptyTrashOperation.swift`** - Empties the user's Trash folder
- **`ClearUserCachesOperation.swift`** - Clears stale cache files from ~/Library/Caches
- **`ClearTempFilesOperation.swift`** - Removes temporary files older than N days
- **`ClearOldLogsOperation.swift`** - Removes log files older than N days
- **`ClearXcodeDerivedDataOperation.swift`** - Clears Xcode's DerivedData folder
- **`FindOrphanedAppSupportOperation.swift`** - Finds app support folders for uninstalled apps

## Usage Examples

### Using Individual Operations

You can now use any operation independently:

```swift
// Use a single operation directly
let trashOp = EmptyTrashOperation()
let result = try await trashOp.execute()
print(result.message)

// Customize operations with parameters
let logsOp = ClearOldLogsOperation(daysOld: 60)  // Custom: 60 days instead of default 30
let result = try await logsOp.execute()

// Use with custom directories
let orphanOp = FindOrphanedAppSupportOperation(
    appDirectories: ["/Applications", "/System/Applications"],
    scanDirectories: [NSHomeDirectory() + "/Library/Application Support"]
)
let result = try await orphanOp.execute()
```

### Using the CleanupEngine (Backward Compatible)

The original API still works exactly the same:

```swift
// Original static methods still work
let result = try await CleanupEngine.emptyTrash()
let result2 = try await CleanupEngine.clearUserCaches()
```

### Batch Operations

```swift
// Execute all operations
let results = try await CleanupEngine.executeAll()

// Execute selected operations
let operations: [any CleanupOperation] = [
    EmptyTrashOperation(),
    ClearXcodeDerivedDataOperation()
]
let results = try await CleanupEngine.executeOperations(operations)

// Get list of all available operations
let allOps = CleanupEngine.allOperations
```

### Using Utilities

```swift
// Shell execution
let output = try CleanupUtilities.shell("ls", "-la", "/tmp")

// Calculate folder size
let size = CleanupUtilities.folderSize("/Applications")

// Format bytes
let formatted = CleanupUtilities.formatBytes(1024 * 1024 * 100)  // "100 MB"
```

## Creating New Operations

To add a new cleanup operation:

1. Create a new file in the `Operations/` folder
2. Conform to the `CleanupOperation` protocol
3. Implement the required properties and `execute()` method
4. (Optional) Add it to `CleanupEngine.allOperations`

Example:

```swift
import Foundation

struct ClearBrowserCacheOperation: CleanupOperation {
    
    let name = "Clear Browser Cache"
    let description = "Remove Safari and other browser caches"
    
    func execute() async throws -> CleanupResult {
        // Your cleanup logic here
        let path = NSHomeDirectory() + "/Library/Caches/com.apple.Safari"
        let before = CleanupUtilities.folderSize(path)
        
        // ... perform cleanup ...
        
        return CleanupResult(
            freedBytes: freed,
            message: "Cleared browser caches",
            details: ["Removed Safari cache files"]
        )
    }
}
```

## Benefits

✅ **Modularity** - Each operation is self-contained and can be used independently  
✅ **Reusability** - Use operations anywhere in your codebase, not just through CleanupEngine  
✅ **Testability** - Easy to test individual operations in isolation  
✅ **Configurability** - Operations can accept parameters for customization  
✅ **Extensibility** - Add new operations without modifying existing code  
✅ **Backward Compatible** - Existing code continues to work without changes  
✅ **Type Safety** - Protocol ensures consistent interface across all operations
