#!/bin/bash

# Git Commit Helper Script for Cleanup Engine Refactor
# This script helps you commit the refactored cleanup operations

echo "================================================"
echo "  MacBook Cleaner - Git Commit Helper"
echo "================================================"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not a git repository"
    echo "   Run 'git init' first"
    exit 1
fi

# Show current status
echo "📊 Current Git Status:"
echo "-------------------"
git status --short
echo ""

# Count changes
NEW_FILES=$(git status --porcelain | grep "^??" | wc -l | xargs)
MODIFIED_FILES=$(git status --porcelain | grep "^ M" | wc -l | xargs)
STAGED_FILES=$(git status --porcelain | grep "^[AM]" | wc -l | xargs)

echo "📈 Summary:"
echo "   New files: $NEW_FILES"
echo "   Modified files: $MODIFIED_FILES"
echo "   Staged files: $STAGED_FILES"
echo ""

# Ask user what to do
echo "What would you like to do?"
echo "1) Stage all changes and commit"
echo "2) View changes first"
echo "3) Stage specific files only"
echo "4) Exit"
echo ""
read -p "Choose an option (1-4): " choice

case $choice in
    1)
        echo ""
        echo "📦 Staging all changes..."
        git add .
        
        echo ""
        echo "📝 Files to be committed:"
        git diff --cached --name-status
        echo ""
        
        read -p "Proceed with commit? (y/n): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            echo ""
            echo "✍️  Committing changes..."
            git commit -m "Refactor: Modularize cleanup operations into reusable components

- Extract CleanupOperation protocol for consistent operation interface
- Create CleanupUtilities for shared helper functions
- Split each cleanup task into individual operation structs
- Update CleanupEngine to coordinate operations (backward compatible)
- Add comprehensive documentation (README.md, CLEANUP_ARCHITECTURE.md)

Benefits: improved modularity, reusability, and testability

New Files:
- CleanupOperation.swift
- CleanupUtilities.swift
- Operations/EmptyTrashOperation.swift
- Operations/ClearUserCachesOperation.swift
- Operations/ClearTempFilesOperation.swift
- Operations/ClearOldLogsOperation.swift
- Operations/ClearXcodeDerivedDataOperation.swift
- Operations/FindOrphanedAppSupportOperation.swift
- README.md
- CLEANUP_ARCHITECTURE.md
- GIT_COMMIT_GUIDE.md

Modified Files:
- CleanupEngine.swift"
            
            echo ""
            echo "✅ Commit successful!"
            echo ""
            echo "📋 Commit details:"
            git log -1 --stat
            echo ""
            echo "💡 Next steps:"
            echo "   - Review the commit: git show HEAD"
            echo "   - Push to remote: git push origin main"
            echo "   - Or amend if needed: git commit --amend"
        else
            echo ""
            echo "❌ Commit cancelled"
            git reset > /dev/null 2>&1
        fi
        ;;
        
    2)
        echo ""
        echo "📄 Viewing changes..."
        echo ""
        echo "New/Modified files:"
        git status --short
        echo ""
        read -p "View detailed diff? (y/n): " view_diff
        if [ "$view_diff" = "y" ] || [ "$view_diff" = "Y" ]; then
            git diff
            git diff --cached
        fi
        ;;
        
    3)
        echo ""
        echo "📂 Available files:"
        git status --short
        echo ""
        echo "Enter files to stage (space-separated), or 'all' for everything:"
        read -p "> " files
        
        if [ "$files" = "all" ]; then
            git add .
            echo "✅ All files staged"
        else
            git add $files
            echo "✅ Files staged"
        fi
        
        echo ""
        git status --short
        ;;
        
    4)
        echo ""
        echo "👋 Exiting..."
        exit 0
        ;;
        
    *)
        echo ""
        echo "❌ Invalid option"
        exit 1
        ;;
esac

echo ""
echo "================================================"
echo "  Done!"
echo "================================================"
