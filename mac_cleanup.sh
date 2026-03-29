#!/bin/bash
# ============================================================
#  mac_cleanup.sh — Safe macOS Disk Cleanup Script
#  Run with:  chmod +x mac_cleanup.sh && ./mac_cleanup.sh
# ============================================================

set -e

DIVIDER="────────────────────────────────────────────────"

log()  { echo "  ✅  $1"; }
warn() { echo "  ⚠️   $1"; }
info() { echo "  ℹ️   $1"; }
section() { echo; echo "$DIVIDER"; echo "  $1"; echo "$DIVIDER"; }

echo
echo "  🧹  macOS Cleanup Script"
echo "  Running as: $(whoami) on $(hostname)"
echo "  Date: $(date)"

# ── 1. Trash ──────────────────────────────────────────────
section "1 / 6  Empty Trash"
TRASH_SIZE=$(du -sh ~/.Trash 2>/dev/null | awk '{print $1}' || echo "0B")
echo "  Trash size before: $TRASH_SIZE"
rm -rf ~/.Trash/* 2>/dev/null && log "User Trash emptied" || warn "Could not empty Trash (may already be empty)"

# ── 2. User Caches ────────────────────────────────────────
section "2 / 6  User Cache Files"
CACHE_SIZE=$(du -sh ~/Library/Caches 2>/dev/null | awk '{print $1}' || echo "0B")
echo "  Cache size before: $CACHE_SIZE"
find ~/Library/Caches -mindepth 1 -maxdepth 3 -type f -name "*.cache" -delete 2>/dev/null || true
find ~/Library/Caches -mindepth 1 -maxdepth 3 -type d -empty -delete 2>/dev/null || true
log "User cache files cleared (safe subset)"

# ── 3. System Temp Files ──────────────────────────────────
section "3 / 6  Temporary Files"
TEMP_SIZE=$(du -sh /private/var/folders 2>/dev/null | awk '{print $1}' || echo "n/a")
echo "  Temp folder size: $TEMP_SIZE"
find /private/tmp -mindepth 1 -maxdepth 1 -mtime +3 -delete 2>/dev/null || true
find /private/var/folders -name "*.cache" -mtime +7 -delete 2>/dev/null || true
log "Old temp files removed (3+ days old)"

# ── 4. Old Log Files ──────────────────────────────────────
section "4 / 6  Old Log Files"
LOG_SIZE=$(du -sh ~/Library/Logs 2>/dev/null | awk '{print $1}' || echo "0B")
echo "  Log folder size: $LOG_SIZE"
find ~/Library/Logs -name "*.log" -mtime +30 -delete 2>/dev/null || true
find ~/Library/Logs -name "*.log.gz" -mtime +30 -delete 2>/dev/null || true
log "Log files older than 30 days removed"

# ── 5. Xcode / Developer Derived Data ─────────────────────
section "5 / 6  Xcode Derived Data & Archives (if present)"
XCODE_DERIVED=~/Library/Developer/Xcode/DerivedData
XCODE_ARCHIVES=~/Library/Developer/Xcode/Archives

if [ -d "$XCODE_DERIVED" ]; then
    SIZE=$(du -sh "$XCODE_DERIVED" | awk '{print $1}')
    echo "  Xcode DerivedData size: $SIZE"
    read -r -p "  Delete Xcode DerivedData? [y/N] " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        rm -rf "$XCODE_DERIVED"/* && log "Xcode DerivedData cleared"
    else
        info "Skipped Xcode DerivedData"
    fi
else
    info "No Xcode DerivedData found — skipping"
fi

if [ -d "$XCODE_ARCHIVES" ]; then
    SIZE=$(du -sh "$XCODE_ARCHIVES" | awk '{print $1}')
    echo "  Xcode Archives size: $SIZE"
    info "Old Xcode archives are in: $XCODE_ARCHIVES"
    info "Review and delete old ones manually in Xcode → Window → Organizer"
fi

# ── 6. Docker (if installed) ──────────────────────────────
section "6 / 6  Docker Cleanup (if Docker is running)"
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    echo "  Docker is running — pruning unused images, containers, volumes..."
    read -r -p "  Run 'docker system prune -f'? [y/N] " reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        docker system prune -f && log "Docker cleaned up"
    else
        info "Skipped Docker cleanup"
    fi
else
    info "Docker not running — skipping"
fi

# ── Summary ───────────────────────────────────────────────
section "✅  Cleanup Complete"
echo "  Disk usage now:"
df -h / | tail -1 | awk '{printf "  Used: %s / %s  (%s full)\n", $3, $2, $5}'
echo
echo "  💡 Tips for more space:"
echo "     • Open 'About This Mac → More Storage' for Apple's built-in suggestions"
echo "     • Review ~/Downloads — often the biggest offender"
echo "     • Check for large files: du -sh ~/* | sort -rh | head -20"
echo "     • Remove unused apps via Launchpad or Finder → Applications"
echo
