# MacBook Cleaner

A native macOS utility app built with SwiftUI that helps you reclaim disk space by safely cleaning up temporary files, caches, logs, and detecting orphaned application data.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0+-purple)

## Features

### Cleanup Operations

- **🗑️ Empty Trash** - Permanently delete all items in the Trash
- **💾 Clear User Caches** - Remove stale .cache files from ~/Library/Caches
- **🔄 Clear Temp Files** - Remove temporary files older than 3 days
- **📝 Clear Old Logs** - Remove log files older than 30 days
- **🛠️ Clear Xcode DerivedData** - Free up space from Xcode build artifacts
- **👻 Find Orphaned App Support** - Detect leftover files from uninstalled applications

### Interface

- **Real-time Disk Usage** - Monitor available disk space with visual progress indicator
- **Individual or Batch Cleanup** - Run operations one at a time or clean everything at once
- **Detailed Results** - View exactly what was cleaned and how much space was freed
- **Session Tracking** - Track total space freed during the current session
- **Modern macOS Design** - Native SwiftUI interface with unified toolbar style

## Architecture

The app uses a modular, protocol-based architecture that makes cleanup operations reusable and testable. See [CLEANUP_ARCHITECTURE.md](CLEANUP_ARCHITECTURE.md) for detailed documentation.

### Core Components

```
CleanupOperation (Protocol)
├── CleanupUtilities (Shared utilities)
├── CleanupEngine (Coordinator & backward compatibility)
└── Operations/
    ├── EmptyTrashOperation
    ├── ClearUserCachesOperation
    ├── ClearTempFilesOperation
    ├── ClearOldLogsOperation
    ├── ClearXcodeDerivedDataOperation
    └── FindOrphanedAppSupportOperation
```

Each cleanup operation is:
- ✅ Self-contained and independently reusable
- ✅ Configurable with custom parameters
- ✅ Testable in isolation
- ✅ Type-safe with protocol conformance

## Usage

### Running the App

1. Clone the repository
2. Open `MacCleaner.xcodeproj` in Xcode
3. Build and run (⌘R)
4. Click individual "Run" buttons for specific operations, or "Clean Everything" for a full cleanup

### Using Operations Programmatically

```swift
// Use individual operations
let trashOp = EmptyTrashOperation()
let result = try await trashOp.execute()
print(result.message)

// Customize with parameters
let logsOp = ClearOldLogsOperation(daysOld: 60)
let result = try await logsOp.execute()

// Use the CleanupEngine coordinator
let result = try await CleanupEngine.emptyTrash()

// Run all operations
let results = try await CleanupEngine.executeAll()
```

## Requirements

- **macOS 13.0+** (Ventura or later)
- **Xcode 15.0+**
- **Swift 5.9+**

## Project Structure

```
MacCleaner/
├── MacCleanerApp.swift          # App entry point
├── ContentView.swift            # Main UI
├── DashboardViewModel.swift     # UI state management
├── CleanupSection.swift         # Section UI model
├── CleanupOperation.swift       # Operation protocol
├── CleanupEngine.swift          # Coordinator
├── CleanupUtilities.swift       # Shared utilities
└── Operations/
    ├── EmptyTrashOperation.swift
    ├── ClearUserCachesOperation.swift
    ├── ClearTempFilesOperation.swift
    ├── ClearOldLogsOperation.swift
    ├── ClearXcodeDerivedDataOperation.swift
    └── FindOrphanedAppSupportOperation.swift
```

## Safety

This app is designed with safety in mind:

- ✅ Only cleans temporary and cache files
- ✅ Uses standard macOS file management APIs
- ✅ Does not require administrator privileges for most operations
- ✅ Provides detailed logs of what was deleted
- ✅ Orphaned app support detection only identifies files (doesn't auto-delete)

## Extending

To add a new cleanup operation:

1. Create a new struct conforming to `CleanupOperation`:

```swift
struct MyCustomOperation: CleanupOperation {
    let name = "My Operation"
    let description = "What it does"
    
    func execute() async throws -> CleanupResult {
        // Your cleanup logic
        return CleanupResult(
            freedBytes: freed,
            message: "Success message",
            details: ["Detail 1", "Detail 2"]
        )
    }
}
```

2. Add it to `CleanupEngine.allOperations` if you want it in the UI
3. Update `DashboardViewModel` to create a section for it

See [CLEANUP_ARCHITECTURE.md](CLEANUP_ARCHITECTURE.md) for more details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is available for personal and educational use. Please review the license file for details.

## Acknowledgments

Built with SwiftUI and modern Swift Concurrency (async/await).

---

**⚠️ Disclaimer**: Always review what will be deleted before running cleanup operations. While this app is designed to be safe, you should understand what each operation does before using it.
