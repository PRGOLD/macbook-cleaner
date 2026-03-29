# 🍎 MacBook Cleaner

A toolkit to keep your MacBook clean, organised, and secure — available as a native macOS app or a command-line script.

## What's included

| File/Folder | Description |
|-------------|-------------|
| `macos-app/` | Native macOS SwiftUI app with a dashboard UI |
| `mac_cleanup.sh` | Bash script — same cleanup logic, runs in Terminal |
| `mac_clean_guide.html` | Interactive HTML checklist for disk space, organisation & security |

---

## macOS App (Recommended)

A native SwiftUI dashboard app built for macOS. Shows live disk usage and lets you run each cleanup section individually or all at once.

### Requirements

- macOS 13 Ventura or later
- Xcode 15 or later

### Build & run

```bash
# Clone the repo
git clone https://github.com/PRGOLD/macbook-cleaner.git

# Open the Xcode project
open macos-app/MacCleaner/MacCleaner.xcodeproj
```

Then press **⌘R** in Xcode to build and run.

### What it cleans

| Section | What it does |
|---------|-------------|
| 🗑️ Empty Trash | Permanently removes everything in `~/.Trash` |
| 📦 User Caches | Clears stale cache files from `~/Library/Caches` |
| 🌡️ Temp Files | Removes temporary files older than 3 days |
| 📋 Old Logs | Deletes log files older than 30 days |
| 🛠️ Xcode DerivedData | Clears Xcode build artefacts (safe to delete any time) |
| 🔍 Orphaned App Data | Finds leftover files from applications you've deleted |

---

## Bash Script

For those who prefer the terminal.

```bash
cd macbook-cleaner
chmod +x mac_cleanup.sh
./mac_cleanup.sh
```

Covers the same sections as the app, plus optional Docker cleanup (`docker system prune`).

---

## HTML Guide

Open `mac_clean_guide.html` in any browser. Tick off items as you go — your progress is saved automatically.

Covers:
1. **Disk Space** — Storage tool, large files, old backups
2. **File Organisation** — Desktop, Downloads, iCloud Drive, app cleanup
3. **Security & Privacy** — FileVault, Firewall, Login Items, 2FA, malware scan
4. **Bonus** — Performance tips and battery health

---

## License

MIT — free to use, modify, and share.
