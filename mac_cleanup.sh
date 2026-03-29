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
section "1 / 7  Empty Trash"
TRASH_SIZE=$(du -sh ~/.Trash 2>/dev/null | awk '{print $1}' || echo "0B")
echo "  Trash size before: $TRASH_SIZE"
rm -rf ~/.Trash/* 2>/dev/null && log "User Trash emptied" || warn "Could not empty Trash (may already be empty)"

# ── 2. User Caches ────────────────────────────────────────
section "2 / 7  User Cache Files"
CACHE_SIZE=$(du -sh ~/Library/Caches 2>/dev/null | awk '{print $1}' || echo "0B")
echo "  Cache size before: $CACHE_SIZE"
find ~/Library/Caches -mindepth 1 -maxdepth 3 -type f -name "*.cache" -delete 2>/dev/null || true
find ~/Library/Caches -mindepth 1 -maxdepth 3 -type d -empty -delete 2>/dev/null || true
log "User cache files cleared (safe subset)"

# ── 3. System Temp Files ──────────────────────────────────
section "3 / 7  Temporary Files"
TEMP_SIZE=$(du -sh /private/var/folders 2>/dev/null | awk '{print $1}' || echo "n/a")
echo "  Temp folder size: $TEMP_SIZE"
find /private/tmp -mindepth 1 -maxdepth 1 -mtime +3 -delete 2>/dev/null || true
find /private/var/folders -name "*.cache" -mtime +7 -delete 2>/dev/null || true
log "Old temp files removed (3+ days old)"

# ── 4. Old Log Files ──────────────────────────────────────
section "4 / 7  Old Log Files"
LOG_SIZE=$(du -sh ~/Library/Logs 2>/dev/null | awk '{print $1}' || echo "0B")
echo "  Log folder size: $LOG_SIZE"
find ~/Library/Logs -name "*.log" -mtime +30 -delete 2>/dev/null || true
find ~/Library/Logs -name "*.log.gz" -mtime +30 -delete 2>/dev/null || true
log "Log files older than 30 days removed"

# ── 5. Xcode / Developer Derived Data ─────────────────────
section "5 / 7  Xcode Derived Data & Archives (if present)"
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
section "6 / 7  Docker Cleanup (if Docker is running)"
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

# ── 7. Orphaned App Leftovers ─────────────────────────────
section "7 / 7  Orphaned Application Leftovers"
echo "  Scanning installed applications (this may take a moment)..."

# Build lookup arrays of installed bundle IDs and app names
declare -A KNOWN_IDS     # bundle IDs  → 1
declare -A KNOWN_NAMES   # app names (lowercased) → 1

# Add known Apple / system namespaces to always skip
ALWAYS_SKIP_PREFIXES=(
    "com.apple"
    "com.microsoft"   # Office apps use many sub-folders
)

while IFS= read -r -d '' app; do
    # Bundle ID
    bid=$(defaults read "${app}/Contents/Info" CFBundleIdentifier 2>/dev/null || true)
    [[ -n "$bid" ]] && KNOWN_IDS["$bid"]=1

    # App name (lower-cased, without .app)
    aname=$(basename "$app" .app)
    [[ -n "$aname" ]] && KNOWN_NAMES["${aname,,}"]=1
done < <(find /Applications ~/Applications /System/Applications \
              -maxdepth 4 -name "*.app" -print0 2>/dev/null)

echo "  Indexed ${#KNOWN_IDS[@]} bundle IDs and ${#KNOWN_NAMES[@]} app names"

# ── Helper: return 0 (true) if entry looks like it belongs to an installed app
is_known() {
    local raw="$1"
    local name
    name=$(basename "$raw")
    local name_lc="${name,,}"

    # Always skip hidden entries and pure Apple/system namespaces
    [[ "$name" == .* ]] && return 0
    for pfx in "${ALWAYS_SKIP_PREFIXES[@]}"; do
        [[ "$name_lc" == "${pfx}"* ]] && return 0
    done

    # Exact bundle-ID match
    [[ -n "${KNOWN_IDS[$name]+x}" ]] && return 0

    # Exact app-name match (case-insensitive)
    [[ -n "${KNOWN_NAMES[$name_lc]+x}" ]] && return 0

    # Fuzzy: name is a component inside a bundle ID (e.g. "Spotify" in "com.spotify.client")
    for bid in "${!KNOWN_IDS[@]}"; do
        local bid_lc="${bid,,}"
        [[ "$bid_lc" == *"$name_lc"* ]] && return 0
    done

    # Group Containers use "TEAMID.bundleid" — strip the team prefix and recheck
    if [[ "$name" =~ ^[A-Z0-9]{10}\. ]]; then
        local stripped="${name#*.}"        # remove "XXXXXXXXXX."
        [[ -n "${KNOWN_IDS[$stripped]+x}" ]] && return 0
        local stripped_lc="${stripped,,}"
        for bid in "${!KNOWN_IDS[@]}"; do
            [[ "${bid,,}" == *"$stripped_lc"* ]] && return 0
        done
    fi

    return 1   # not matched → orphan candidate
}

# ── Scan directories and collect orphan candidates
ORPHANS=()

scan_for_orphans() {
    local dir="$1"
    [[ -d "$dir" ]] || return
    while IFS= read -r -d '' entry; do
        if ! is_known "$entry"; then
            local sz
            sz=$(du -sh "$entry" 2>/dev/null | awk '{print $1}')
            ORPHANS+=("${sz}	${entry}")
        fi
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
}

scan_for_orphans "$HOME/Library/Application Support"
scan_for_orphans "$HOME/Library/Containers"
scan_for_orphans "$HOME/Library/Group Containers"

# ── Report results
if [[ ${#ORPHANS[@]} -eq 0 ]]; then
    log "No orphaned app leftovers found — you're clean!"
else
    echo
    echo "  Found ${#ORPHANS[@]} possible orphaned app folder(s):"
    echo "  (These belong to apps that are no longer installed)"
    echo
    printf "  %-8s  %s\n" "SIZE" "PATH"
    printf "  %-8s  %s\n" "────" "────────────────────────────────────"

    # Sort by size descending (human-readable — approximate, good enough for display)
    IFS=$'\n' sorted_orphans=($(printf '%s\n' "${ORPHANS[@]}" | sort -rh))
    unset IFS

    for item in "${sorted_orphans[@]}"; do
        sz="${item%%	*}"
        path="${item##*	}"
        printf "  %-8s  %s\n" "$sz" "$path"
    done

    echo
    echo "  ⚠️  Review the list above before deleting."
    echo "     Some entries may be shared or still in use."
    echo
    read -r -p "  Delete ALL of the above? [y/N] " reply_all
    if [[ "$reply_all" =~ ^[Yy]$ ]]; then
        for item in "${sorted_orphans[@]}"; do
            path="${item##*	}"
            rm -rf "$path" && log "Deleted: $(basename "$path")"
        done
    else
        echo
        read -r -p "  Review one by one instead? [y/N] " reply_one
        if [[ "$reply_one" =~ ^[Yy]$ ]]; then
            for item in "${sorted_orphans[@]}"; do
                sz="${item%%	*}"
                path="${item##*	}"
                echo
                echo "  📁  $(basename "$path")  ($sz)"
                echo "       $path"
                read -r -p "       Delete this? [y/N] " reply
                if [[ "$reply" =~ ^[Yy]$ ]]; then
                    rm -rf "$path" && log "Deleted"
                else
                    info "Skipped"
                fi
            done
        else
            info "Skipped orphan cleanup — you can delete manually from the list above"
        fi
    fi
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
