# What's New in v2.0 🚀

## 🎉 Major New Features

### 1. **Dry-Run Mode** 🔍
Preview exactly what will be deleted before doing it!

```bash
# Preview cleanup without deleting anything
./mac-cleaner-v2.sh --dry-run

# Or from interactive menu with dry-run enabled
./mac-cleaner-v2.sh -n
```

**Benefits:**
- ✅ See what will be deleted
- ✅ Check space that would be freed
- ✅ 100% safe - no files touched
- ✅ Perfect for first-time users

**Example Output:**
```
[DRY RUN] Would delete: Chrome Cache (1.2GB)
[DRY RUN] Would delete: Safari Cache (450MB)
[DRY RUN] Would delete: System Logs (230MB)

Total space that would be freed: 1.88GB
```

---

### 2. **Cleanup Reports & Logging** 📊
Automatic reports after every cleanup!

**Features:**
- ✅ Detailed cleanup logs
- ✅ Professional reports
- ✅ Track history over time
- ✅ See before/after disk usage

**Location:**
```
~/Library/Logs/PlsCleanMyMac/
├── cleanup-20260622-010000.log    # Detailed log
├── report-20260622-010000.txt     # Summary report
```

**View Reports:**
```bash
# Show latest report
./mac-cleaner-v2.sh --show-reports

# Show recent logs
./mac-cleaner-v2.sh --show-logs

# Or manually
cat ~/Library/Logs/PlsCleanMyMac/report-*.txt
```

**Sample Report:**
```
═══════════════════════════════════════════════════════════
PlsCleanMyMac - Cleanup Report
═══════════════════════════════════════════════════════════

Date: 2026-06-22 01:15:30
Version: 2.0.0
Mode: LIVE CLEANUP

─────────────────────────────────────────────────────────────
SUMMARY
─────────────────────────────────────────────────────────────
Total Space Freed: 8 GB (8192 MB)
Items Processed: 24

─────────────────────────────────────────────────────────────
DETAILS
─────────────────────────────────────────────────────────────
Chrome Cache                             1.2GB           DELETED
Safari Cache                             450MB           DELETED
System Logs                              230MB           DELETED
NPM Cache                                2.3GB           DELETED
Homebrew Cache                           680MB           DELETED
...
```

---

### 3. **Application Uninstaller** 🗑️
Complete app removal - not just the .app file!

**What it removes:**
- ✅ Application bundle (.app)
- ✅ Application Support files
- ✅ Caches
- ✅ Preferences (.plist)
- ✅ Logs
- ✅ Saved states
- ✅ WebKit data
- ✅ Containers
- ✅ Launch Agents/Daemons
- ✅ Helper tools

**Usage:**
```bash
# Uninstall via command line
./mac-cleaner-v2.sh --uninstall "Grammarly Desktop"

# Or from interactive menu
./mac-cleaner-v2.sh
# Choose option 4: Uninstall application
```

**Example:**
```
═══════════════════════════════════════════════════════════
Uninstaller: Grammarly Desktop
═══════════════════════════════════════════════════════════

Searching for all files related to 'Grammarly Desktop'...

Found 12 items:

  • /Applications/Grammarly Desktop.app (150MB)
  • ~/Library/Application Support/com.grammarly.ProjectLlama (45MB)
  • ~/Library/Caches/com.grammarly.ProjectLlama (23MB)
  • ~/Library/Preferences/com.grammarly.ProjectLlama.plist (8KB)
  • ~/Library/WebKit/com.grammarly.ProjectLlama (12MB)
  • ~/Library/LaunchAgents/com.grammarly.ProjectLlama.*.plist (3 files)
  • /Library/LaunchDaemons/com.grammarly.service.plist
  ...

Total size: 230MB

Remove all these files? [y/N]:
```

---

## 🔧 Enhanced Features

### Command Line Options
```bash
# Show help
./mac-cleaner-v2.sh --help

# Dry run mode
./mac-cleaner-v2.sh --dry-run

# Uninstall app
./mac-cleaner-v2.sh --uninstall "AppName"

# Disable logging
./mac-cleaner-v2.sh --no-log

# View reports
./mac-cleaner-v2.sh --show-reports
./mac-cleaner-v2.sh --show-logs
```

### Improved Safety
- ✅ Better error handling
- ✅ Safer file removal with `safe_remove()` function
- ✅ Auto-confirm in dry-run mode
- ✅ Detailed logging of all operations

### Better Output
- 🎨 Color-coded dry-run messages (magenta)
- 📝 More informative status messages
- 📊 Detailed summaries

---

## 📊 Comparison: v1.0 vs v2.0

| Feature | v1.0 | v2.0 |
|---------|------|------|
| **Interactive Cleanup** | ✅ | ✅ |
| **17 Cleanup Categories** | ✅ | ✅ |
| **Dry-Run Mode** | ❌ | ✅ NEW |
| **Cleanup Reports** | ❌ | ✅ NEW |
| **Logging** | ❌ | ✅ NEW |
| **App Uninstaller** | ❌ | ✅ NEW |
| **Command Line Args** | ❌ | ✅ NEW |
| **View History** | ❌ | ✅ NEW |
| **Better Error Handling** | Basic | ✅ Enhanced |
| **Safe Remove Function** | ❌ | ✅ NEW |

---

## 🚀 Getting Started

### Try Dry-Run First!
```bash
# Always safe to run - preview only
./mac-cleaner-v2.sh --dry-run
```

### Then Run Real Cleanup
```bash
# Interactive mode
./mac-cleaner-v2.sh

# Choose option 1 for safe cleanup
```

### Check Your Report
```bash
# View what was cleaned
./mac-cleaner-v2.sh --show-reports
```

---

## 🔄 Migration from v1.0

### Keep Both Versions?
- **v1.0** (`mac-cleaner.sh`) - Simple, no logs
- **v2.0** (`mac-cleaner-v2.sh`) - Full-featured

### Or Replace v1.0
```bash
# Backup v1
mv mac-cleaner.sh mac-cleaner-v1-backup.sh

# Use v2 as main
mv mac-cleaner-v2.sh mac-cleaner.sh
```

---

## 📖 Usage Examples

### Example 1: First-Time User
```bash
# Preview first
./mac-cleaner-v2.sh --dry-run
# Choose option 1

# Then do real cleanup
./mac-cleaner-v2.sh
# Choose option 1

# Check report
./mac-cleaner-v2.sh --show-reports
```

### Example 2: Uninstall Apps
```bash
# Uninstall Grammarly
./mac-cleaner-v2.sh --uninstall "Grammarly Desktop"

# Uninstall Zoom
./mac-cleaner-v2.sh --uninstall "zoom.us"

# Uninstall Teams
./mac-cleaner-v2.sh --uninstall "Microsoft Teams"
```

### Example 3: Check History
```bash
# See all past cleanups
./mac-cleaner-v2.sh --show-reports

# See detailed logs
./mac-cleaner-v2.sh --show-logs
```

---

## 💡 Pro Tips

### 1. **Always Dry-Run First**
Especially when using uninstaller on new apps:
```bash
./mac-cleaner-v2.sh --dry-run
# Choose option 4 (Uninstall)
# Enter app name
# Review what will be deleted
```

### 2. **Keep Reports**
Reports are automatically saved and dated. Perfect for:
- Tracking cleanup history
- Seeing space trends
- Audit trail

### 3. **Combine with Original**
Use v2.0 for:
- ✅ First-time cleanups (dry-run)
- ✅ Uninstalling apps
- ✅ When you want reports

Use v1.0 for:
- ✅ Quick cleanups
- ✅ No logging needed

---

## 🐛 Bug Fixes & Improvements

### From v1.0:
- ✅ Fixed permission issues with safer removal
- ✅ Better error handling
- ✅ More consistent output format
- ✅ Improved size calculations
- ✅ Better confirmation handling

---

## 🔮 Coming Soon (v3.0 Ideas)

Based on this release, future features might include:
- [ ] TUI (Terminal UI) interface
- [ ] Config file support
- [ ] Scheduled cleanups
- [ ] Duplicate file finder
- [ ] Language files cleaner
- [ ] macOS notifications

---

## 📝 Changelog

### v2.0.0 (2026-06-22)
- ➕ **NEW**: Dry-run mode (`--dry-run`)
- ➕ **NEW**: Cleanup reports & logging
- ➕ **NEW**: Application uninstaller
- ➕ **NEW**: Command line argument parsing
- ➕ **NEW**: `--show-reports` and `--show-logs` commands
- ✨ **IMPROVED**: Better error handling
- ✨ **IMPROVED**: Safer file removal
- ✨ **IMPROVED**: More informative output
- 🐛 **FIXED**: Permission issues
- 🐛 **FIXED**: Size calculation accuracy

### v1.0.0 (2026-06-22)
- Initial release
- 17 cleanup categories
- Interactive menu system

---

**Ready to try v2.0?**

```bash
./mac-cleaner-v2.sh --help
```
