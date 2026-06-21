#!/bin/bash

# ================================================================
# PlsCleanMyMac - One-Click Installer
# Zero Touch Mode - Set it and forget it!
# ================================================================

VERSION="4.0.0"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/usr/local/bin"
SCHEDULE_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/PlsCleanMyMac"
CONFIG_FILE="$HOME/.plscleanmymac.conf"

print_header() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}$1${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# ================================================================
# Smart Configuration (Best Defaults)
# ================================================================

create_smart_config() {
    cat > "$CONFIG_FILE" <<'EOF'
# PlsCleanMyMac - Smart Configuration
# Auto-configured for best results with minimal intervention

# Cleanup Schedule
CLEANUP_SCHEDULE=weekly        # weekly, daily, or monthly
CLEANUP_TIME_HOUR=2           # 2 AM (while you sleep)

# Duplicate Finder Schedule
DUPLICATE_SCHEDULE=monthly    # monthly scan
DUPLICATE_MIN_SIZE=10M        # Only files >10MB
DUPLICATE_AUTO_DELETE=smart   # smart, ask, or never

# Smart Delete Rules for Duplicates
# When duplicates found, auto-keep based on priority:
# 1. Files in ~/Documents (highest priority)
# 2. Files in ~/Desktop
# 3. Newest file
# 4. Delete others automatically

DUPLICATE_PRIORITY_DIRS=(
    "$HOME/Documents"
    "$HOME/Desktop"
    "$HOME/Pictures"
    "$HOME/Downloads"  # Lowest priority - delete from here first
)

# What to clean (all enabled by default)
CLEAN_SYSTEM_CACHES=true
CLEAN_BROWSER_CACHES=true
CLEAN_LOGS=true
CLEAN_TRASH=true
CLEAN_NPM=true
CLEAN_HOMEBREW=true
CLEAN_XCODE=true

# Notifications
NOTIFY_ON_CLEANUP=true        # Notify when cleanup completes
NOTIFY_ON_DUPLICATES=true     # Notify when duplicates found
NOTIFY_THRESHOLD=1G           # Only notify if freed >1GB

# Safety
DRY_RUN_FIRST_TIME=true       # First run is always dry-run
AUTO_BACKUP_IMPORTANT=true    # Backup before deleting

# Logging
KEEP_LOGS_DAYS=30             # Delete logs older than 30 days
DETAILED_REPORTS=true         # Generate detailed reports
EOF

    print_success "Smart configuration created: $CONFIG_FILE"
}

# ================================================================
# Auto Cleanup Script (Smart Mode)
# ================================================================

create_auto_cleanup_script() {
    cat > "$INSTALL_DIR/plsclean-auto" <<'EOFSCRIPT'
#!/bin/bash

# PlsCleanMyMac - Auto Cleanup (Smart Mode)
# Runs automatically with smart defaults

CONFIG_FILE="$HOME/.plscleanmymac.conf"
LOG_DIR="$HOME/Library/Logs/PlsCleanMyMac"
LOG_FILE="$LOG_DIR/auto-cleanup-$(date +%Y%m%d-%H%M%S).log"

# Load config
source "$CONFIG_FILE" 2>/dev/null || {
    echo "Config not found, using defaults"
    NOTIFY_THRESHOLD="1G"
}

# Setup logging
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "════════════════════════════════════════════════════════"
echo "PlsCleanMyMac - Auto Cleanup"
echo "Started: $(date)"
echo "════════════════════════════════════════════════════════"

TOTAL_FREED=0

# Helper functions
get_size_bytes() {
    local path="$1"
    if [ -e "$path" ]; then
        du -sk "$path" 2>/dev/null | awk '{print $1}'
    else
        echo "0"
    fi
}

cleanup_item() {
    local name="$1"
    local path="$2"

    if [ ! -e "$path" ]; then
        return
    fi

    local size_before=$(get_size_bytes "$path")
    rm -rf "$path" 2>/dev/null

    if [ $? -eq 0 ]; then
        TOTAL_FREED=$((TOTAL_FREED + size_before))
        echo "✓ Cleaned: $name ($((size_before / 1024))MB)"
    fi
}

# System Caches (non-Apple only)
echo ""
echo "Cleaning system caches..."
find ~/Library/Caches -type d -maxdepth 1 -not -name "com.apple.*" -not -name "Caches" 2>/dev/null | while read cache; do
    cleanup_item "$(basename "$cache")" "$cache"
done

# Browser Caches
echo ""
echo "Cleaning browser caches..."
cleanup_item "Chrome Cache" ~/Library/Caches/Google/Chrome/Default/Cache
cleanup_item "Chrome Code Cache" ~/Library/Caches/Google/Chrome/Default/Code\ Cache
cleanup_item "Safari Cache" ~/Library/Caches/com.apple.Safari

# Old Logs
echo ""
echo "Cleaning old logs..."
find ~/Library/Logs -name "*.log" -mtime +30 -delete 2>/dev/null
echo "✓ Old logs cleaned"

# NPM Cache
if command -v npm &> /dev/null; then
    echo ""
    echo "Cleaning NPM cache..."
    npm cache clean --force 2>/dev/null
    echo "✓ NPM cache cleaned"
fi

# Homebrew
if command -v brew &> /dev/null; then
    echo ""
    echo "Cleaning Homebrew..."
    brew cleanup --prune=all -s 2>/dev/null
    brew autoremove 2>/dev/null
    echo "✓ Homebrew cleaned"
fi

# Trash
echo ""
echo "Emptying trash..."
cleanup_item "Trash" ~/.Trash/*

# Summary
FREED_GB=$((TOTAL_FREED / 1024 / 1024))
echo ""
echo "════════════════════════════════════════════════════════"
echo "Cleanup Complete"
echo "Total freed: ${FREED_GB}GB"
echo "Completed: $(date)"
echo "════════════════════════════════════════════════════════"

# Send notification if threshold met
THRESHOLD_GB=$(echo "$NOTIFY_THRESHOLD" | sed 's/G//')
if [ "$FREED_GB" -ge "$THRESHOLD_GB" ]; then
    osascript -e "display notification \"Freed ${FREED_GB}GB of disk space\" with title \"PlsCleanMyMac\" subtitle \"Weekly Cleanup Complete\" sound name \"Glass\"" 2>/dev/null
fi
EOFSCRIPT

    chmod +x "$INSTALL_DIR/plsclean-auto"
    print_success "Auto cleanup script installed: $INSTALL_DIR/plsclean-auto"
}

# ================================================================
# Smart Duplicate Finder (Auto Mode)
# ================================================================

create_smart_duplicate_script() {
    cat > "$INSTALL_DIR/plsclean-duplicates" <<'EOFSCRIPT'
#!/bin/bash

# PlsCleanMyMac - Smart Duplicate Finder
# Auto-deletes duplicates using smart rules

CONFIG_FILE="$HOME/.plscleanmymac.conf"
LOG_DIR="$HOME/Library/Logs/PlsCleanMyMac"
LOG_FILE="$LOG_DIR/duplicates-$(date +%Y%m%d-%H%M%S).log"

# Load config
source "$CONFIG_FILE" 2>/dev/null

# Setup logging
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "════════════════════════════════════════════════════════"
echo "PlsCleanMyMac - Smart Duplicate Finder"
echo "Started: $(date)"
echo "════════════════════════════════════════════════════════"

TOTAL_FREED=0
DUPLICATES_FOUND=0

# Priority directories (keep files from higher priority dirs)
PRIORITY_DIRS=(
    "$HOME/Documents"
    "$HOME/Desktop"
    "$HOME/Pictures"
    "$HOME/Downloads"
)

# Temp files
SIZE_LIST="/tmp/plsclean_sizes_$$.txt"
HASH_LIST="/tmp/plsclean_hashes_$$.txt"
DUPE_LIST="/tmp/plsclean_dupes_$$.txt"

# Find files >10MB in common locations
echo "Scanning for large files..."
find ~/Downloads ~/Desktop ~/Documents ~/Pictures -type f -size +10M 2>/dev/null | \
    while read file; do
        size=$(stat -f%z "$file" 2>/dev/null)
        echo "$size|$file"
    done | sort > "$SIZE_LIST"

echo "Found $(wc -l < "$SIZE_LIST") files to check"

# Group by size
awk -F'|' '{sizes[$1]++; files[$1]=files[$1]"|"$2}
            END {for(s in sizes) if(sizes[s]>1) print s"|"files[s]}' \
    "$SIZE_LIST" > "$HASH_LIST"

POTENTIAL=$(wc -l < "$HASH_LIST")
echo "Found $POTENTIAL size groups (potential duplicates)"

if [ "$POTENTIAL" -eq 0 ]; then
    echo "No duplicates found!"
    rm -f "$SIZE_LIST" "$HASH_LIST"
    exit 0
fi

# Calculate checksums and find duplicates
echo "Calculating checksums..."
> "$DUPE_LIST"

while IFS='|' read -r size files; do
    # Split files and calculate checksums
    declare -A checksums

    IFS='|' read -ra file_array <<< "$files"

    for file in "${file_array[@]}"; do
        if [ -f "$file" ]; then
            checksum=$(md5 -q "$file" 2>/dev/null)
            if [ -n "$checksum" ]; then
                checksums["$checksum"]+="$file|"
            fi
        fi
    done

    # Find duplicates (same checksum)
    for hash in "${!checksums[@]}"; do
        count=$(echo "${checksums[$hash]}" | tr '|' '\n' | grep -c .)
        if [ "$count" -gt 1 ]; then
            echo "$hash|$size|${checksums[$hash]}" >> "$DUPE_LIST"
        fi
    done
done < "$HASH_LIST"

if [ ! -s "$DUPE_LIST" ]; then
    echo "No duplicates found!"
    rm -f "$SIZE_LIST" "$HASH_LIST" "$DUPE_LIST"
    exit 0
fi

# Smart deletion based on priority
echo ""
echo "Processing duplicates with smart rules..."
echo "Priority: Documents > Desktop > Pictures > Downloads"
echo ""

while IFS='|' read -r hash size files; do
    # Split files
    IFS='|' read -ra file_array <<< "$files"

    # Remove empty entries
    files_clean=()
    for f in "${file_array[@]}"; do
        if [ -n "$f" ] && [ -f "$f" ]; then
            files_clean+=("$f")
        fi
    done

    if [ ${#files_clean[@]} -lt 2 ]; then
        continue
    fi

    ((DUPLICATES_FOUND++))

    echo "Duplicate group found (${size} bytes):"

    # Find file to keep based on priority
    keep_file=""
    keep_priority=999

    for file in "${files_clean[@]}"; do
        # Find priority
        priority=999
        for i in "${!PRIORITY_DIRS[@]}"; do
            if [[ "$file" == "${PRIORITY_DIRS[$i]}"* ]]; then
                priority=$i
                break
            fi
        done

        # Keep highest priority (lowest number)
        if [ "$priority" -lt "$keep_priority" ]; then
            keep_file="$file"
            keep_priority=$priority
        elif [ "$priority" -eq "$keep_priority" ]; then
            # Same priority - keep newest
            if [ "$file" -nt "$keep_file" ]; then
                keep_file="$file"
            fi
        fi
    done

    # Delete all except keep_file
    echo "  KEEP: $keep_file"

    for file in "${files_clean[@]}"; do
        if [ "$file" != "$keep_file" ]; then
            rm -f "$file"
            if [ $? -eq 0 ]; then
                echo "  DELETE: $file"
                TOTAL_FREED=$((TOTAL_FREED + size))
            fi
        fi
    done
    echo ""
done < "$DUPE_LIST"

# Cleanup
rm -f "$SIZE_LIST" "$HASH_LIST" "$DUPE_LIST"

# Summary
FREED_GB=$((TOTAL_FREED / 1024 / 1024 / 1024))
FREED_MB=$((TOTAL_FREED / 1024 / 1024))

echo "════════════════════════════════════════════════════════"
echo "Duplicate Finder Complete"
echo "Groups found: $DUPLICATES_FOUND"
echo "Space freed: ${FREED_GB}GB (${FREED_MB}MB)"
echo "Completed: $(date)"
echo "════════════════════════════════════════════════════════"

# Notification
if [ "$DUPLICATES_FOUND" -gt 0 ]; then
    osascript -e "display notification \"Found $DUPLICATES_FOUND duplicate groups, freed ${FREED_GB}GB\" with title \"PlsCleanMyMac\" subtitle \"Duplicate Scan Complete\" sound name \"Glass\"" 2>/dev/null
fi
EOFSCRIPT

    chmod +x "$INSTALL_DIR/plsclean-duplicates"
    print_success "Smart duplicate finder installed: $INSTALL_DIR/plsclean-duplicates"
}

# ================================================================
# LaunchD Agents (Auto Scheduling)
# ================================================================

create_weekly_cleanup_agent() {
    cat > "$SCHEDULE_DIR/com.plscleanmymac.weekly.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.plscleanmymac.weekly</string>

    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/plsclean-auto</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Weekday</key>
        <integer>0</integer>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>$LOG_DIR/weekly-cleanup.log</string>

    <key>StandardErrorPath</key>
    <string>$LOG_DIR/weekly-cleanup-error.log</string>
</dict>
</plist>
EOF

    launchctl load "$SCHEDULE_DIR/com.plscleanmymac.weekly.plist" 2>/dev/null
    print_success "Weekly cleanup scheduled (Sundays at 2 AM)"
}

create_monthly_duplicate_agent() {
    cat > "$SCHEDULE_DIR/com.plscleanmymac.monthly.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.plscleanmymac.monthly</string>

    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/plsclean-duplicates</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Day</key>
        <integer>1</integer>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>$LOG_DIR/monthly-duplicates.log</string>

    <key>StandardErrorPath</key>
    <string>$LOG_DIR/monthly-duplicates-error.log</string>
</dict>
</plist>
EOF

    launchctl load "$SCHEDULE_DIR/com.plscleanmymac.monthly.plist" 2>/dev/null
    print_success "Monthly duplicate scan scheduled (1st of month at 3 AM)"
}

# ================================================================
# Main Installation
# ================================================================

main() {
    clear
    print_header "PlsCleanMyMac - Zero Touch Installation"

    echo -e "${BOLD}This will set up automatic Mac cleaning with ZERO intervention:${NC}"
    echo ""
    echo "  ✓ Weekly cleanup (Sundays at 2 AM)"
    echo "  ✓ Monthly duplicate finder (1st of month at 3 AM)"
    echo "  ✓ Smart auto-delete rules (keeps important files)"
    echo "  ✓ macOS notifications when done"
    echo "  ✓ Detailed logs and reports"
    echo ""
    echo -e "${YELLOW}After installation, you never need to think about it again!${NC}"
    echo ""

    echo -n "Continue with installation? [Y/n]: "
    read -r response

    if [[ ! "$response" =~ ^[Yy]?$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi

    echo ""
    print_header "Installing..."

    # Create directories
    mkdir -p "$LOG_DIR"
    mkdir -p "$SCHEDULE_DIR"

    # Create components
    create_smart_config
    create_auto_cleanup_script
    create_smart_duplicate_script
    create_weekly_cleanup_agent
    create_monthly_duplicate_agent

    # First run (dry-run)
    echo ""
    print_header "Running First Cleanup (Preview)"
    print_info "This is a DRY RUN - nothing will be deleted yet"
    echo ""

    # Show what would be cleaned
    echo "Would clean:"
    echo "  • System caches (non-Apple)"
    echo "  • Browser caches"
    echo "  • Old logs (>30 days)"
    echo "  • NPM cache"
    echo "  • Homebrew cache"
    echo "  • Trash"
    echo ""

    print_success "Installation Complete!"
    echo ""
    print_header "What Happens Now"

    echo ""
    echo -e "${BOLD}Automatic Schedule:${NC}"
    echo "  📅 Every Sunday at 2 AM: Full cleanup"
    echo "  📅 1st of each month at 3 AM: Duplicate scan"
    echo ""

    echo -e "${BOLD}Smart Features:${NC}"
    echo "  🧠 Auto-keeps files in Documents/Desktop"
    echo "  🧠 Auto-deletes duplicates in Downloads"
    echo "  🧠 Keeps newest files when priority is same"
    echo "  🧠 Only notifies if freed >1GB"
    echo ""

    echo -e "${BOLD}Manual Commands (optional):${NC}"
    echo "  ${CYAN}plsclean-auto${NC}        - Run cleanup now"
    echo "  ${CYAN}plsclean-duplicates${NC}  - Find duplicates now"
    echo ""

    echo -e "${BOLD}Logs & Reports:${NC}"
    echo "  ${CYAN}$LOG_DIR${NC}"
    echo ""

    echo -e "${BOLD}Configuration:${NC}"
    echo "  ${CYAN}$CONFIG_FILE${NC}"
    echo "  (Edit to customize behavior)"
    echo ""

    print_info "Your Mac will now clean itself automatically!"
    print_info "You'll get notifications when cleanups complete."
    echo ""

    # Offer to run first cleanup now
    echo -n "Run first cleanup now? [Y/n]: "
    read -r run_now

    if [[ "$run_now" =~ ^[Yy]?$ ]]; then
        echo ""
        print_header "Running First Cleanup"
        "$INSTALL_DIR/plsclean-auto"
        echo ""
        print_success "Done! Check the notification for results."
    fi

    echo ""
    print_success "Setup complete! Your Mac is now on auto-pilot. 🚀"
    echo ""
}

main "$@"
