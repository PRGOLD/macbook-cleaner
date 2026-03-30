# 🍎 MacBook Cleaner

A toolkit to keep your MacBook clean, organised, and secure — available as a native macOS SwiftUI app or a command-line shell script.

## What's included

| File/Folder | Description |
|---|---|
| `macos-app/` | Native macOS SwiftUI app with dashboard UI, charts, scheduler, and settings |
| `mac_cleanup.sh` | Bash script — same cleanup logic, runs in Terminal |
| `mac_clean_guide.html` | Interactive HTML checklist for disk space, organisation & security |

---

## macOS App (Recommended)

A native SwiftUI dashboard app built for macOS. Shows live disk usage with before/after charts, runs each cleanup operation individually or all at once, and supports scheduled automatic cleanup.

### Requirements

- macOS 13 Ventura or later
- Xcode 15 or later

### Build & Run

```bash
git clone https://github.com/PRGOLD/macbook-cleaner.git
open macos-app/MacCleaner/MacCleaner.xcodeproj
```

Press **⌘R** in Xcode to build and run.

### Architecture

The app follows MVVM with a modular operation-based cleanup engine:

```
MacCleaner/
├── MacCleanerApp.swift          # App entry point
├── ContentView.swift            # Main dashboard UI
├── DashboardViewModel.swift     # MVVM view model — coordinates all operations
├── CleanupEngine.swift          # Core cleanup engine
├── CleanupOperation.swift       # Base operation protocol
├── CleanupScheduler.swift       # Scheduled/automatic cleanup
├── CleanupSettings.swift        # User preferences and thresholds
├── CleanupSection.swift         # Section model
├── CleanupUtilities.swift       # Shared helpers
├── SettingsView.swift           # Settings UI
├── DiskUsageChartView.swift     # Live disk usage visualisation
├── BeforeAfterChartView.swift   # Before/after cleanup comparison chart
└── Operations/
    ├── ClearUserCachesOperation.swift
    ├── ClearDeveloperCachesOperation.swift
    ├── ClearTempFilesOperation.swift
    ├── ClearOldLogsOperation.swift
    ├── ClearOldDownloadsOperation.swift
    ├── ClearSafariCacheOperation.swift
    ├── ClearXcodeDerivedDataOperation.swift
    ├── EmptyTrashOperation.swift
    ├── FindDuplicateFilesOperation.swift
    ├── FindLargestFilesOperation.swift
    └── FindOrphanedAppSupportOperation.swift
```

### Cleanup Operations

| Operation | What it does |
|---|---|
| 🗑️ Empty Trash | Permanently removes everything in `~/.Trash` |
| 📦 User Caches | Clears stale cache files from `~/Library/Caches` |
| 🛠️ Developer Caches | Clears developer tool caches (CocoaPods, npm, pip, etc.) |
| 🌡️ Temp Files | Removes temporary files older than 3 days |
| 📋 Old Logs | Deletes log files older than 30 days |
| 📥 Old Downloads | Flags/removes downloads older than a configurable threshold |
| 🌍 Safari Cache | Clears Safari browser cache files |
| 🔨 Xcode DerivedData | Clears Xcode build artefacts (safe to delete any time) |
| 🔍 Duplicate Files | Finds duplicate files by hash comparison |
| 📊 Largest Files | Identifies the largest files on disk for manual review |
| 👻 Orphaned App Data | Finds leftover support files from applications you've deleted |

### Dashboard Features

- Live disk usage chart with used/free breakdown
- Before/after comparison chart showing space recovered per run
- Per-operation progress tracking
- Configurable settings (log retention days, download age threshold, etc.)
- Scheduled automatic cleanup via `CleanupScheduler`

---

## Bash Script

For those who prefer the terminal.

```bash
cd macbook-cleaner
chmod +x mac_cleanup.sh
./mac_cleanup.sh
```

Covers the same core cleanup sections, plus optional Docker cleanup (`docker system prune`).

---

## HTML Guide

Open `mac_clean_guide.html` in any browser. Tick off items as you go — progress saves automatically.

Covers: Disk Space, File Organisation, Security & Privacy (FileVault, Firewall, Login Items, 2FA, malware scan), and Performance tips.

---

## License

MIT — free to use, modify, and share.
