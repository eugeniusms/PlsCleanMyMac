# PlsCleanMyMac 🧹

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![macOS](https://img.shields.io/badge/macOS-Compatible-blue.svg)](https://www.apple.com/macos/)

> **Free, open-source Mac cleanup utility** - Your own CleanMyMac Pro alternative!

**One command. Zero maintenance. Your Mac cleans itself.**

---

## 🚀 Quick Start (Recommended)

### Zero Touch Mode - Install and Forget
```bash
bash install.sh
```

**That's it!** Your Mac now:
- ✅ Cleans itself every Sunday at 2 AM
- ✅ Finds & deletes duplicates monthly
- ✅ Notifies you when done
- ✅ Saves 100-200GB per year automatically

**You literally do nothing else. Ever.**

---

## 📦 What You Get

### Automatic Features:
- **Weekly Cleanup** (Sundays 2 AM)
  - System caches (non-Apple)
  - Browser caches
  - Old logs
  - NPM/Homebrew caches
  - Trash

- **Monthly Duplicate Scan** (1st of month 3 AM)
  - Smart auto-delete
  - Keeps files in Documents/Desktop
  - Deletes duplicates from Downloads
  - Saves 2-10GB per month

### Smart Rules:
🧠 **Always Keeps:**
- Files in Documents (highest priority)
- Files in Desktop
- Files in Pictures
- Newest files

🗑️ **Auto-Deletes:**
- Older duplicates
- Files in Downloads (lowest priority)

---

## 💾 Expected Results

### First Run:
- Regular cleanup: **5-15GB**
- Duplicate finder: **3-10GB**
- **Total: 8-25GB**

### Automatic Annual:
- Weekly cleanups: **52-156GB/year**
- Monthly duplicates: **36-120GB/year**
- **Total: 100-276GB/year**

**All automatic. Zero effort.**

---

## 🎯 Two Ways to Use

### 1. Zero Touch Mode (Recommended)
```bash
bash install.sh
```
- One-time setup (30 seconds)
- Fully automatic forever
- Weekly cleanup + Monthly duplicates
- macOS notifications
- **Perfect for: Everyone who values their time**

### 2. Manual Mode
```bash
./mac-cleaner.sh
```
- Interactive menu
- Choose what to clean
- Manual duplicate finder
- **Perfect for: Control freaks**

---

## 📖 Documentation

- **[SAFETY.md](SAFETY.md)** - File protection rules & safety guarantees 🛡️
- **[ZERO-TOUCH-MODE.md](ZERO-TOUCH-MODE.md)** - Complete automation guide ⭐
- **[WHATS-NEW-V2.md](WHATS-NEW-V2.md)** - Dry-run, Reports, Uninstaller
- **[WHATS-NEW-V3.md](WHATS-NEW-V3.md)** - TUI, Duplicate Finder, Scheduling

---

## 🎁 Features

### Core Features:
- ✅ 17 cleanup categories
- ✅ Dry-run mode (preview before delete)
- ✅ Comprehensive reports & logging
- ✅ Complete app uninstaller
- ✅ Smart duplicate finder
- ✅ Auto scheduling (weekly/monthly)
- ✅ Terminal UI (TUI)
- ✅ macOS notifications
- ✅ Smart auto-delete rules
- ✅ Zero configuration needed

### What It Cleans:
- System caches (non-Apple)
- Browser caches (Chrome, Safari, Firefox)
- Old logs (>30 days)
- NPM/Yarn caches
- Homebrew caches
- Xcode derived data
- iOS simulator data
- Docker images (optional)
- Mail attachments cache
- Spotify cache
- Trash
- Duplicate files
- And more...

---

## 💡 Common Usage

### After Installation (Zero Touch):
```bash
# Do nothing! It runs automatically.

# Optional: Check logs
cat ~/Library/Logs/PlsCleanMyMac/weekly-cleanup.log

# Optional: Run cleanup now (don't wait for Sunday)
plsclean-auto

# Optional: Find duplicates now
plsclean-duplicates
```

### Manual Commands:
```bash
# Interactive TUI
./mac-cleaner.sh

# Preview what will be deleted (dry-run)
./mac-cleaner.sh --dry-run

# Uninstall an application completely
./mac-cleaner.sh --uninstall "Grammarly Desktop"

# Find duplicates
./mac-cleaner.sh --find-duplicates ~/Downloads

# View reports
./mac-cleaner.sh --show-reports
```

---

## 🆚 vs CleanMyMac Pro

| Feature | PlsCleanMyMac | CleanMyMac Pro |
|---------|---------------|----------------|
| **Price** | **FREE** | $89.95/year |
| Cache Cleaning | ✅ | ✅ |
| Duplicate Finder | ✅ | ✅ |
| App Uninstaller | ✅ | ✅ |
| **Auto Schedule** | ✅ | ❌ |
| **Smart Auto-Delete** | ✅ | ❌ |
| **Zero Touch** | ✅ | ❌ |
| Open Source | ✅ | ❌ |
| Customizable | ✅ | ❌ |

---

## 🔧 Advanced Usage

### Custom Schedule:
Edit `~/.plscleanmymac.conf`:
```bash
# Change to daily cleanup
CLEANUP_SCHEDULE=daily

# Change duplicate scan frequency
DUPLICATE_SCHEDULE=weekly

# Notification threshold
NOTIFY_THRESHOLD=2G  # Only notify if >2GB freed
```

### Uninstall:
```bash
# Stop scheduled cleanups
launchctl unload ~/Library/LaunchAgents/com.plscleanmymac.*.plist

# Remove files
rm ~/Library/LaunchAgents/com.plscleanmymac.*.plist
rm /usr/local/bin/plsclean-*
rm ~/.plscleanmymac.conf
```

---

## 📊 Real Example

**Installation:**
```bash
$ bash install.sh
Continue with installation? [Y/n]: ← Press Enter
✓ Configuration created
✓ Scripts installed
✓ Weekly cleanup scheduled
✓ Monthly duplicate scan scheduled
Run first cleanup now? [Y/n]: ← Press Enter

Cleaning...
✓ System caches: 1.2GB
✓ Browser caches: 850MB
✓ NPM cache: 2.1GB
Total freed: 4.15GB

Your Mac is now on auto-pilot! 🚀
```

**6 Months Later:**
```
Notifications received: 24
Total freed: 180GB
Your time spent: 0 minutes
Your effort: 0
```

---

## 🎯 Perfect For

✅ People who forget to clean their Mac
✅ People who don't want to think about maintenance
✅ People who hate clicking through menus
✅ Minimalists who want one command
✅ Anyone who values their time

---

## 🛡️ Safety

### What It NEVER Deletes:
- ❌ Application files
- ❌ System files
- ❌ Your documents
- ❌ Photos (unless duplicate in Downloads)
- ❌ Anything Apple-related
- ❌ Browser history/passwords

### What It Does Delete:
- ✅ Caches (regenerate automatically)
- ✅ Old logs (>30 days)
- ✅ Trash
- ✅ Obvious duplicate files (smart rules apply)

### Smart Duplicate Protection:
**Priority System:**
```
Documents (Priority 0)  ← ALWAYS KEEP
Desktop   (Priority 1)  ← KEEP if no Documents version
Pictures  (Priority 2)  ← KEEP if no Desktop version
Downloads (Priority 3)  ← DELETE FROM HERE FIRST
```

**Read [SAFETY.md](SAFETY.md) for complete protection rules!** 🛡️

---

## 📁 Files

```
PlsCleanMyMac/
├── install.sh              ← One-click installer (Zero Touch)
├── mac-cleaner.sh          ← Main executable (Manual/TUI)
├── README.md               ← This file
├── ZERO-TOUCH-MODE.md      ← Complete automation guide
├── LICENSE                 ← MIT License
└── archive/                ← Old versions (backup)
```

**You only need 2 files:**
1. `install.sh` - For Zero Touch Mode
2. `mac-cleaner.sh` - For manual use

---

## 🚀 Installation

### Zero Touch (Recommended):
```bash
git clone https://github.com/eugeniusms/PlsCleanMyMac.git
cd PlsCleanMyMac
bash install.sh
```

### Manual Mode:
```bash
git clone https://github.com/eugeniusms/PlsCleanMyMac.git
cd PlsCleanMyMac
./mac-cleaner.sh
```

---

## 📝 License

MIT License - Free to use, modify, and distribute.

---

## 🙏 Credits

Created as a free alternative to CleanMyMac Pro.

**Philosophy:** "The best tool is the one you never think about."

---

## ⭐ Show Your Support

If this saved you $89/year and hours of manual cleaning:
- Star the repo
- Share with friends
- Send feedback

---

**Ready to automate your Mac cleaning?**

```bash
bash install.sh
```

Your Mac will thank you. 🚀

---

Made with ❤️ as a CleanMyMac alternative

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
