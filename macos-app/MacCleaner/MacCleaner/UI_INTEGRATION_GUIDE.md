# UI Integration Guide

## Step 1: Update DashboardViewModel

Add the 3 new cleanup operations to your sections array:

```swift
lazy var sections: [CleanupSection] = [
    CleanupSection(id: "trash", icon: "trash.fill", title: "Empty Trash",
                   description: "Permanently removes everything in your Trash") {
        try await CleanupEngine.emptyTrash()
    },
    CleanupSection(id: "caches", icon: "internaldrive", title: "User Caches",
                   description: "Clears stale cache files from ~/Library/Caches") {
        try await CleanupEngine.clearUserCaches()
    },
    CleanupSection(id: "temp", icon: "thermometer.medium", title: "Temp Files",
                   description: "Removes temporary files older than 3 days") {
        try await CleanupEngine.clearTempFiles()
    },
    CleanupSection(id: "logs", icon: "doc.text", title: "Old Logs",
                   description: "Deletes log files older than 30 days") {
        try await CleanupEngine.clearOldLogs()
    },
    CleanupSection(id: "xcode", icon: "hammer.fill", title: "Xcode DerivedData",
                   description: "Clears Xcode build artefacts (safe to delete)") {
        try await CleanupEngine.clearXcodeDerivedData()
    },
    // 🆕 NEW OPERATIONS
    CleanupSection(id: "safari", icon: "safari", title: "Safari Cache",
                   description: "Remove browser cache and temporary files") {
        try await CleanupEngine.clearSafariCache()
    },
    CleanupSection(id: "downloads", icon: "arrow.down.circle.fill", title: "Old Downloads",
                   description: "Remove downloads older than 90 days") {
        try await CleanupEngine.clearOldDownloads()
    },
    CleanupSection(id: "developer", icon: "hammer.circle.fill", title: "Developer Caches",
                   description: "Clear npm, Homebrew, CocoaPods caches") {
        try await CleanupEngine.clearDeveloperCaches()
    },
    // Keep this last as it's scan-only
    CleanupSection(id: "orphans", icon: "questionmark.folder.fill", title: "Orphaned App Data",
                   description: "Finds leftover files from deleted applications") {
        try await CleanupEngine.findOrphanedAppSupport()
    }
]
```

## Step 2: Add Settings to ContentView

### Option A: Settings as a Sheet (Recommended)

Add to your `ContentView`:

```swift
struct ContentView: View {
    @StateObject private var vm = DashboardViewModel()
    @State private var showSettings = false  // Add this
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(diskInfo: vm.diskInfo)
                .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 16)
            Divider()
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(vm.sections) { section in SectionCard(section: section) }
                }
                .padding(24)
            }
            Divider()
            HStack {
                // Add dry run indicator
                if CleanupSettings.shared.dryRunMode {
                    Label("Dry Run Mode Active", systemImage: "eye.fill")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
                
                Text(vm.totalFreed > 0
                     ? "Total freed this session: \(ByteCountFormatter.string(fromByteCount: vm.totalFreed, countStyle: .file))"
                     : "Run individual sections or clean everything at once")
                    .font(.callout).foregroundStyle(.secondary)
                Spacer()
                
                // Add settings button
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button { Task { await vm.runAll() } } label: {
                    Label("Clean Everything", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent).disabled(vm.isRunning).controlSize(.large)
            }
            .padding(.horizontal, 24).padding(.vertical, 14)
        }
        .frame(minWidth: 720, minHeight: 560)
        .task { await vm.refreshDiskInfo() }
        .sheet(isPresented: $showSettings) {  // Add this
            SettingsView()
        }
    }
}
```

### Option B: Settings Window (More macOS-like)

In `MacCleanerApp.swift`:

```swift
import SwiftUI

@main
struct MacCleanerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 820, height: 700)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Settings...") {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        // Add settings window
        Settings {
            SettingsView()
        }
    }
}
```

Then users can open settings with ⌘, (standard macOS shortcut).

## Step 3: Add Dry Run Indicator

Update your `HeaderView` to show dry run status:

```swift
struct HeaderView: View {
    let diskInfo: DiskInfo?
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "apple.logo").font(.system(size: 32)).foregroundStyle(.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text("MacBook Cleaner").font(.title2.bold())
                HStack(spacing: 8) {
                    Text("Free up space \u{00B7} Stay organised \u{00B7} Stay secure")
                        .font(.callout).foregroundStyle(.secondary)
                    
                    // Add dry run badge
                    if CleanupSettings.shared.dryRunMode {
                        Text("DRY RUN")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange, in: Capsule())
                    }
                }
            }
            Spacer()
            if let disk = diskInfo {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(disk.usedFormatted) used of \(disk.totalFormatted)").font(.callout.monospacedDigit())
                    ProgressView(value: disk.usedFraction).frame(width: 160)
                        .tint(disk.usedFraction > 0.85 ? .red : disk.usedFraction > 0.65 ? .orange : .green)
                    Text("\(disk.freeFormatted) available").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}
```

## Step 4: Test the Integration

1. **Build the app** (`⌘B`)
2. **Run the app** (`⌘R`)
3. **Open Settings** (either via button or ⌘,)
4. **Enable Dry Run Mode**
5. **Run a cleanup operation** - should show "[DRY RUN]" in results
6. **Try new operations** - Safari, Downloads, Developer Caches

## Optional: Add Confirmation Dialogs

If you want to respect the "Confirm Before Delete" setting:

```swift
func runAll() async {
    // Check if confirmation is needed
    if CleanupSettings.shared.confirmBeforeDelete && !CleanupSettings.shared.dryRunMode {
        // Show confirmation dialog
        let alert = NSAlert()
        alert.messageText = "Clean Everything?"
        alert.informativeText = "This will run all cleanup operations. Continue?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clean")
        alert.addButton(withTitle: "Cancel")
        
        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }
    }
    
    isRunning = true
    for section in sections { await section.run() }
    await refreshDiskInfo()
    isRunning = false
}
```

## Visual Enhancements

### Update Grid Layout for 9 Items

With 9 operations, you might want to adjust the grid. In `ContentView`:

```swift
// Option 1: Keep 2 columns (will scroll more)
LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16)

// Option 2: Switch to 3 columns for more items
LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12)

// Option 3: Adaptive (best for different window sizes)
LazyVGrid(columns: [GridItem(.adaptive(minimum: 300, maximum: 400))], spacing: 16)
```

### Update Window Size

In `MacCleanerApp.swift`:

```swift
.defaultSize(width: 900, height: 800)  // Larger to accommodate more cards
```

## Quick Checklist

- [ ] Updated `DashboardViewModel` with 3 new sections
- [ ] Added Settings button or menu item
- [ ] Added `SettingsView` sheet or window
- [ ] Added dry run indicator in UI
- [ ] Tested dry run mode works
- [ ] Tested all 9 operations
- [ ] Verified settings persist across app launches
- [ ] Adjusted grid layout if needed
- [ ] Updated window size if needed

---

**You're ready to go!** Build, run, and enjoy your enhanced Mac cleaner app with settings and 3 new operations! 🚀
