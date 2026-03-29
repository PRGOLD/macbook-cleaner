# ⚡ Quick Start Checklist

## Before You Build

### ☑️ Files to Add to Xcode Project

Make sure these new files are in your Xcode project:

**Settings:**
- [ ] `CleanupSettings.swift`
- [ ] `SettingsView.swift`

**New Operations:**
- [ ] `OperationsClearSafariCacheOperation.swift`
- [ ] `OperationsClearOldDownloadsOperation.swift`
- [ ] `OperationsClearDeveloperCachesOperation.swift`

**Documentation** (optional, but helpful):
- [ ] `IMPROVEMENTS_SUMMARY.md`
- [ ] `UI_INTEGRATION_GUIDE.md`
- [ ] `IMPROVEMENTS_COMPLETE.md`

## Build & Test

### 1. Build the App
```bash
⌘B in Xcode
```

**Expected:** Should build without errors

If you get errors:
- Check all files are added to target
- Clean build folder (⌘⇧K) and try again
- Verify all Operations files are included

### 2. Run the App
```bash
⌘R in Xcode
```

**Expected:** App should launch normally with existing 6 operations working

### 3. Test Settings System

**Without UI integration (in code):**
```swift
// Add to your app temporarily to test
print("Current dry run mode:", CleanupSettings.shared.dryRunMode)
CleanupSettings.shared.dryRunMode = true
CleanupSettings.shared.save()
print("Updated dry run mode:", CleanupSettings.shared.dryRunMode)
```

**Expected:** Settings should persist between app launches

### 4. Test Dry Run Mode

Enable dry run and run an operation:
```swift
CleanupSettings.shared.dryRunMode = true
CleanupSettings.shared.save()

// Then run any operation
let result = try await CleanupEngine.emptyTrash()
```

**Expected:** Result message should contain "[DRY RUN]" and no files deleted

### 5. Test New Operations (Without UI)

Add temporary test code:
```swift
Task {
    // Safari
    let safari = try await CleanupEngine.clearSafariCache()
    print("Safari:", safari.message)
    
    // Downloads
    let downloads = try await CleanupEngine.clearOldDownloads()
    print("Downloads:", downloads.message)
    
    // Developer
    let dev = try await CleanupEngine.clearDeveloperCaches()
    print("Developer:", dev.message)
}
```

**Expected:** Operations should complete (in dry run mode, they'll just preview)

## UI Integration (Optional but Recommended)

### 6. Add New Operations to Dashboard

**File:** `DashboardViewModel.swift`

Add these 3 sections to your `sections` array (see `UI_INTEGRATION_GUIDE.md` for full code):

```swift
CleanupSection(id: "safari", icon: "safari", title: "Safari Cache", ...),
CleanupSection(id: "downloads", icon: "arrow.down.circle.fill", title: "Old Downloads", ...),
CleanupSection(id: "developer", icon: "hammer.circle.fill", title: "Developer Caches", ...)
```

**Expected:** Dashboard now shows 9 operations instead of 6

### 7. Add Settings Button

**File:** `ContentView.swift`

Add:
```swift
@State private var showSettings = false

// In toolbar or bottom bar:
Button("Settings") { showSettings = true }

// After body:
.sheet(isPresented: $showSettings) { SettingsView() }
```

**Expected:** Clicking Settings button opens settings sheet

### 8. Add Dry Run Indicator

**File:** `ContentView.swift`

Add indicator to show when dry run is active:
```swift
if CleanupSettings.shared.dryRunMode {
    Label("Dry Run Mode Active", systemImage: "eye.fill")
        .foregroundStyle(.orange)
}
```

**Expected:** Orange badge shows when dry run is enabled

## Final Checks

### 9. Visual Verification

Run the app and verify:
- [ ] All 9 operations appear in UI
- [ ] Settings button is visible
- [ ] Settings window opens and closes properly
- [ ] Dry run indicator appears when enabled
- [ ] Operations show "[DRY RUN]" prefix when dry run is on

### 10. Functional Testing

With dry run OFF:
- [ ] Empty Trash actually empties trash
- [ ] User Caches actually clears caches
- [ ] New operations work

With dry run ON:
- [ ] No files are actually deleted
- [ ] Results show what WOULD happen
- [ ] "[DRY RUN]" appears in messages

### 11. Settings Persistence

1. [ ] Open Settings
2. [ ] Change retention days (e.g., logs from 30 to 60)
3. [ ] Enable dry run mode
4. [ ] Click Done
5. [ ] Quit app (⌘Q)
6. [ ] Relaunch app
7. [ ] Open Settings again
8. [ ] Verify settings are still changed

**Expected:** All settings persist across launches

## Performance Check

### 12. Test with Real Data

Disable dry run and try:
- [ ] Empty Trash (if you have items in trash)
- [ ] Clear User Caches
- [ ] Clear Safari Cache
- [ ] Check results make sense

**Expected:** 
- Operations complete quickly (< 10 seconds)
- Disk space is actually freed
- Results show accurate byte counts

## Commit Changes

### 13. Review What Changed

```bash
git status
```

**Expected:** Should see all new and modified files

### 14. Commit

```bash
git add .
git commit -m "Add settings, dry run mode, and 3 new cleanup operations

Features:
- CleanupSettings with persistent preferences
- SettingsView for UI configuration
- Dry run mode for all operations
- ClearSafariCacheOperation
- ClearOldDownloadsOperation
- ClearDeveloperCachesOperation

All operations now support dry run and respect global settings."

git push origin main
```

## Troubleshooting

### Build Fails

**Problem:** "Cannot find type 'CleanupSettings'"
**Solution:** Make sure `CleanupSettings.swift` is added to your target

**Problem:** "Cannot find type 'SettingsView'"
**Solution:** Make sure `SettingsView.swift` is added to your target

**Problem:** Operations files not found
**Solution:** Verify all `Operations*.swift` files are in project

### Runtime Errors

**Problem:** Settings don't persist
**Solution:** Make sure you call `.save()` after changing settings

**Problem:** Dry run doesn't work
**Solution:** Verify you're setting `dryRun = true` BEFORE calling `execute()`

**Problem:** New operations not in UI
**Solution:** Check you updated `DashboardViewModel.swift` sections array

### UI Issues

**Problem:** Settings button doesn't show
**Solution:** Make sure you added the button to ContentView

**Problem:** Settings window is blank
**Solution:** Verify `SettingsView.swift` is properly imported

**Problem:** Dry run indicator doesn't appear
**Solution:** Check the conditional logic and that settings are being read

## Success Criteria

You're done when:

✅ App builds without errors  
✅ App runs without crashes  
✅ All 9 operations appear in UI  
✅ Settings window opens and works  
✅ Dry run mode prevents deletion  
✅ Settings persist across launches  
✅ New operations (Safari, Downloads, Developer) work  
✅ All changes committed to git  

## What's Next?

After completing this checklist, consider:

1. **Add Tests** - Unit tests for each operation
2. **Add More Operations** - Mail attachments, iOS backups, etc.
3. **Improve UI** - Add charts, animations, better feedback
4. **Add Scheduling** - Automatic cleanup on a schedule
5. **Add Notifications** - Alert when disk is low

See `IMPROVEMENTS_SUMMARY.md` for more ideas!

---

**Ready? Let's go! Build that app! 🚀**

Start with step 1 and work your way down. Check off each item as you complete it!
