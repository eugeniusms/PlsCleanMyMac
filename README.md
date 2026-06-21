# MAC CLEANER - DIY Version

Comprehensive Mac cleanup utility - your own CleanMyMac alternative!

## 🚀 Quick Start

```bash
# Run the cleaner
bash ~/mac-cleaner.sh

# Or make it available globally
sudo ln -s ~/mac-cleaner.sh /usr/local/bin/mac-cleaner
mac-cleaner
```

## ✨ Features

### 1️⃣ **Safe Cleanups** (Run All mode)
- ✅ System caches (non-Apple)
- ✅ Browser caches (Chrome, Safari, Firefox)
- ✅ Old logs (>30 days)
- ✅ Trash
- ✅ NPM cache
- ✅ Yarn cache
- ✅ Homebrew cleanup
- ✅ Xcode derived data
- ✅ iOS simulators (unavailable ones)
- ✅ Spotify cache
- ✅ .DS_Store files

### 2️⃣ **Advanced Cleanups** (Custom mode)
- 🔧 Downloads folder (old files)
- 🔧 Docker cleanup
- 🔧 Mail attachments cache
- 🔧 Temp files
- 🔧 Large files finder (>500MB)

### 3️⃣ **Analysis Tools**
- 📊 Disk usage analysis
- 📊 Largest directories
- 📊 Large files finder
- 📊 Real-time space tracking

## 🎯 Usage Modes

### Mode 1: Quick Clean (Recommended)
```bash
bash ~/mac-cleaner.sh
# Select option 1: Run all safe cleanups
```

**What it does:**
- Automatically cleans all safe items
- No risk of deleting important files
- Interactive confirmations for each step
- Shows total space freed

### Mode 2: Custom Clean
```bash
bash ~/mac-cleaner.sh
# Select option 2: Custom cleanup
```

**What it does:**
- Choose specific items to clean
- Enter comma-separated numbers (e.g., `1,2,6,8`)
- Or type `all` for everything
- Full control over what gets deleted

### Mode 3: Analysis Only
```bash
bash ~/mac-cleaner.sh
# Select option 3: Disk usage analysis only
```

**What it does:**
- Shows disk usage
- Lists largest directories
- No cleanup performed

## 📋 What Gets Cleaned

| Item | Location | Safe? | Typical Size |
|------|----------|-------|--------------|
| **System Caches** | `~/Library/Caches` | ✅ Yes | 1-5GB |
| **Browser Caches** | Chrome, Safari, Firefox | ✅ Yes | 500MB-3GB |
| **Logs** | `~/Library/Logs` | ✅ Yes | 100-500MB |
| **NPM Cache** | `~/.npm` | ✅ Yes | 1-3GB |
| **Homebrew** | `~/Library/Caches/Homebrew` | ✅ Yes | 100MB-1GB |
| **Xcode Data** | `~/Library/Developer/Xcode` | ✅ Yes | 5-20GB |
| **Trash** | `~/.Trash` | ✅ Yes | Varies |
| **Downloads** | `~/Downloads` (old files) | ⚠️ Review | Varies |
| **Docker** | Images, containers, volumes | ⚠️ Review | Varies |
| **Temp Files** | `/tmp`, `/var/folders` | ✅ Yes | 100MB-1GB |

## 🛡️ Safety Features

1. **Interactive Confirmations**: Asks before deleting anything
2. **Size Preview**: Shows how much space will be freed
3. **No Root Required**: Runs with user permissions (safer)
4. **Selective Cleaning**: Choose exactly what to clean
5. **Summary Report**: Shows total space freed

## 💡 Pro Tips

### Schedule Regular Cleanups
```bash
# Add to crontab for monthly cleanup
crontab -e

# Add this line (runs first day of month at 2am):
0 2 1 * * /Users/eugeniusms/mac-cleaner.sh
```

### Create Alias
```bash
# Add to ~/.zshrc:
echo 'alias clean="bash ~/mac-cleaner.sh"' >> ~/.zshrc
source ~/.zshrc

# Now just type:
clean
```

### Before Major Updates
```bash
# Clean before macOS updates to free space
bash ~/mac-cleaner.sh
```

## 📊 Expected Results

### First Run (Fresh System):
- **Typical freed space**: 5-15GB
- **Items cleaned**: 50-200

### Monthly Maintenance:
- **Typical freed space**: 2-5GB
- **Items cleaned**: 20-100

### Heavy Developer System:
- **Typical freed space**: 10-30GB
- **Items cleaned**: 100-500

## ⚠️ Things It DOESN'T Clean

**For safety, the script does NOT:**
- ❌ Delete application files
- ❌ Remove user documents
- ❌ Clear browser history (only cache)
- ❌ Delete emails
- ❌ Remove photos/videos
- ❌ Touch system files

## 🆚 vs CleanMyMac

| Feature | mac-cleaner.sh | CleanMyMac Pro |
|---------|----------------|----------------|
| **Price** | FREE ✅ | $89.95/year |
| **Cache Cleaning** | ✅ | ✅ |
| **Browser Cleanup** | ✅ | ✅ |
| **Dev Tools** | ✅ (NPM, Yarn, Homebrew, Xcode) | ✅ |
| **Docker Cleanup** | ✅ | ❌ |
| **Interactive** | ✅ | ✅ |
| **Malware Scanner** | ❌ | ✅ |
| **Uninstaller** | ❌ | ✅ |
| **Real-time Monitor** | ❌ | ✅ |
| **Open Source** | ✅ (you can modify) | ❌ |

## 🔧 Customization

The script is fully customizable! Edit `~/mac-cleaner.sh` to:

1. **Add new cleanup targets:**
```bash
cleanup_my_app() {
    print_header "My App Cache"
    rm -rf ~/Library/Caches/MyApp
}
```

2. **Change age thresholds:**
```bash
# Change from 30 to 60 days
find ~/Library/Logs -mtime +60 -delete
```

3. **Add to menu:**
```bash
# In run_custom() function, add:
echo "  18) My custom cleanup"
# And in case statement:
18) cleanup_my_app ;;
```

## 🐛 Troubleshooting

### "Permission denied" errors
```bash
# Some directories need sudo
# Script will skip them automatically
```

### Script won't run
```bash
# Make sure it's executable
chmod +x ~/mac-cleaner.sh
```

### Want to see what will be deleted?
```bash
# Add -n flag to rm commands for dry-run
# Example: rm -rf becomes rm -rfn
```

## 📈 Monitoring

After cleanup, monitor your system:

```bash
# Check disk space
df -h

# See what's using space
du -sh ~/* | sort -hr | head -10

# Monitor in real-time
watch -n 5 'df -h /'
```

## 🎁 Bonus Features

### Find Duplicate Files
```bash
# Install fdupes
brew install fdupes

# Find duplicates
fdupes -r ~/Documents
```

### Analyze Disk Usage Visually
```bash
# Install ncdu
brew install ncdu

# Analyze interactively
ncdu ~
```

## 📝 Changelog

**v1.0.0** (2026-06-22)
- Initial release
- 17 cleanup categories
- Interactive menu system
- Space tracking
- Analysis tools

## 🤝 Contributing

Feel free to modify and improve! Some ideas:
- Add more cleanup targets
- Implement dry-run mode
- Add scheduling options
- Create log of cleanups
- Add GUI version

## ⚖️ License

Free to use, modify, and distribute. No warranty provided.

---

**Made with ❤️ as a CleanMyMac alternative**
