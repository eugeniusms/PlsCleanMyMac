#!/bin/bash

# ================================================================
# MAC CLEANER v2.0 - DIY Mac Cleaner Alternative
# Comprehensive Mac cleanup utility with advanced features
# ================================================================

VERSION="2.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
DRY_RUN=false
ENABLE_LOGGING=true
LOG_DIR="$HOME/Library/Logs/PlsCleanMyMac"
LOG_FILE="$LOG_DIR/cleanup-$(date +%Y%m%d-%H%M%S).log"
REPORT_FILE="$LOG_DIR/report-$(date +%Y%m%d-%H%M%S).txt"

# Track total space freed
TOTAL_FREED=0
CLEANUP_ITEMS=()

# ================================================================
# Logging Functions
# ================================================================

setup_logging() {
    if [ "$ENABLE_LOGGING" = true ]; then
        mkdir -p "$LOG_DIR"
        touch "$LOG_FILE"
        log "PlsCleanMyMac v$VERSION - Cleanup started"
        log "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE")"
        log "Date: $(date)"
        log "User: $(whoami)"
        log "─────────────────────────────────────────"
    fi
}

log() {
    if [ "$ENABLE_LOGGING" = true ]; then
        echo "[$(date +%H:%M:%S)] $1" >> "$LOG_FILE"
    fi
}

log_cleanup() {
    local item="$1"
    local size="$2"
    local status="$3"

    log "$status: $item ($size)"
    CLEANUP_ITEMS+=("$item|$size|$status")
}

generate_report() {
    if [ "$ENABLE_LOGGING" = false ]; then
        return
    fi

    cat > "$REPORT_FILE" <<EOF
═══════════════════════════════════════════════════════════
PlsCleanMyMac - Cleanup Report
═══════════════════════════════════════════════════════════

Date: $(date)
Version: $VERSION
Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN (Preview Only)" || echo "LIVE CLEANUP")

─────────────────────────────────────────────────────────────
SUMMARY
─────────────────────────────────────────────────────────────
Total Space Freed: $((TOTAL_FREED / 1024 / 1024)) GB ($((TOTAL_FREED / 1024)) MB)
Items Processed: ${#CLEANUP_ITEMS[@]}

─────────────────────────────────────────────────────────────
DETAILS
─────────────────────────────────────────────────────────────
EOF

    for item in "${CLEANUP_ITEMS[@]}"; do
        IFS='|' read -r name size status <<< "$item"
        printf "%-40s %-15s %s\n" "$name" "$size" "$status" >> "$REPORT_FILE"
    done

    cat >> "$REPORT_FILE" <<EOF

─────────────────────────────────────────────────────────────
DISK USAGE (After Cleanup)
─────────────────────────────────────────────────────────────
$(df -h / | tail -1)

─────────────────────────────────────────────────────────────
Full log available at: $LOG_FILE
─────────────────────────────────────────────────────────────
EOF

    echo ""
    print_success "Report saved to: $REPORT_FILE"
}

# ================================================================
# Helper Functions
# ================================================================

print_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}$1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_dry_run() {
    echo -e "${MAGENTA}[DRY RUN] $1${NC}"
}

get_size() {
    local path="$1"
    if [ -e "$path" ]; then
        du -sh "$path" 2>/dev/null | awk '{print $1}'
    else
        echo "0B"
    fi
}

get_size_bytes() {
    local path="$1"
    if [ -e "$path" ]; then
        du -sk "$path" 2>/dev/null | awk '{print $1}'
    else
        echo "0"
    fi
}

confirm() {
    local prompt="$1"

    if [ "$DRY_RUN" = true ]; then
        return 0  # Auto-confirm in dry-run mode
    fi

    echo -e "${YELLOW}${prompt} [y/N]:${NC} "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

safe_remove() {
    local path="$1"
    local item_name="$2"

    if [ ! -e "$path" ]; then
        return
    fi

    local size=$(get_size "$path")
    local size_bytes=$(get_size_bytes "$path")

    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Would delete: $item_name ($size)"
        log_cleanup "$item_name" "$size" "DRY RUN"
    else
        rm -rf "$path" 2>/dev/null
        if [ $? -eq 0 ]; then
            print_success "Deleted: $item_name ($size)"
            log_cleanup "$item_name" "$size" "DELETED"
            TOTAL_FREED=$((TOTAL_FREED + size_bytes))
        else
            print_error "Failed to delete: $item_name"
            log_cleanup "$item_name" "$size" "FAILED"
        fi
    fi
}

# ================================================================
# Uninstaller Feature
# ================================================================

find_app_files() {
    local app_name="$1"
    local files=()

    # Application bundle
    if [ -d "/Applications/${app_name}.app" ]; then
        files+=("/Applications/${app_name}.app")
    fi

    # User Library files
    files+=($(find ~/Library/Application\ Support -maxdepth 1 -iname "*${app_name}*" 2>/dev/null))
    files+=($(find ~/Library/Caches -maxdepth 1 -iname "*${app_name}*" 2>/dev/null))
    files+=($(find ~/Library/Preferences -maxdepth 1 -iname "*${app_name}*" 2>/dev/null))
    files+=($(find ~/Library/Logs -maxdepth 1 -iname "*${app_name}*" 2>/dev/null))
    files+=($(find ~/Library/Saved\ Application\ State -maxdepth 1 -iname "*${app_name}*" 2>/dev/null))
    files+=($(find ~/Library/WebKit -maxdepth 1 -iname "*${app_name}*" 2>/dev/null))
    files+=($(find ~/Library/Containers -maxdepth 1 -iname "*${app_name}*" 2>/dev/null))
    files+=($(find ~/Library/Group\ Containers -maxdepth 1 -iname "*${app_name}*" 2>/dev/null))

    # Launch Agents
    files+=($(find ~/Library/LaunchAgents -maxdepth 1 -iname "*${app_name}*" 2>/dev/null))

    # System Library files (requires sudo)
    files+=($(sudo find /Library/Application\ Support -maxdepth 1 -iname "*${app_name}*" 2>/dev/null))
    files+=($(sudo find /Library/LaunchDaemons -maxdepth 1 -iname "*${app_name}*" 2>/dev/null))
    files+=($(sudo find /Library/LaunchAgents -maxdepth 1 -iname "*${app_name}*" 2>/dev/null))
    files+=($(sudo find /Library/PrivilegedHelperTools -maxdepth 1 -iname "*${app_name}*" 2>/dev/null))

    echo "${files[@]}"
}

uninstall_app() {
    local app_name="$1"

    print_header "Uninstaller: $app_name"

    print_info "Searching for all files related to '$app_name'..."
    log "Uninstalling: $app_name"

    local files=($(find_app_files "$app_name"))

    if [ ${#files[@]} -eq 0 ]; then
        print_warning "No files found for '$app_name'"
        return
    fi

    echo ""
    print_info "Found ${#files[@]} items:"
    echo ""

    local total_size=0
    for file in "${files[@]}"; do
        local size=$(get_size "$file")
        local size_bytes=$(get_size_bytes "$file")
        total_size=$((total_size + size_bytes))
        echo "  • $file ($size)"
    done

    echo ""
    print_info "Total size: $((total_size / 1024))MB"
    echo ""

    if [ "$DRY_RUN" = true ]; then
        print_dry_run "Would remove all items above"
        log_cleanup "$app_name (uninstall)" "$((total_size / 1024))MB" "DRY RUN"
        return
    fi

    if confirm "Remove all these files?"; then
        for file in "${files[@]}"; do
            safe_remove "$file" "$(basename "$file")"
        done
        print_success "Uninstalled: $app_name"
    else
        print_warning "Uninstall cancelled"
    fi
}

# ================================================================
# Cleanup Functions (Enhanced)
# ================================================================

cleanup_system_caches() {
    print_header "1. System Caches"

    local size_before=$(get_size_bytes ~/Library/Caches)
    print_info "Current cache size: $(get_size ~/Library/Caches)"

    if confirm "Clean system caches?"; then
        log "Cleaning system caches"

        # Find non-Apple caches
        local caches=($(find ~/Library/Caches -type d -maxdepth 1 -not -name "com.apple.*" -not -name "Caches" 2>/dev/null))

        for cache in "${caches[@]}"; do
            safe_remove "$cache" "$(basename "$cache")"
        done

        if [ "$DRY_RUN" = false ]; then
            local size_after=$(get_size_bytes ~/Library/Caches)
            local freed=$((size_before - size_after))
            print_success "Total freed: $((freed / 1024))MB"
        fi
    else
        print_warning "Skipped"
    fi
}

cleanup_browser_caches() {
    print_header "2. Browser Caches"

    log "Cleaning browser caches"

    # Chrome
    if [ -d ~/Library/Caches/Google/Chrome ]; then
        safe_remove ~/Library/Caches/Google/Chrome/Default/Cache "Chrome Cache"
        safe_remove ~/Library/Caches/Google/Chrome/Default/Code\ Cache "Chrome Code Cache"
        safe_remove ~/Library/Caches/Google/Chrome/Default/GPUCache "Chrome GPU Cache"
    fi

    # Safari
    safe_remove ~/Library/Caches/com.apple.Safari "Safari Cache"

    # Firefox
    safe_remove ~/Library/Caches/Firefox "Firefox Cache"
}

cleanup_logs() {
    print_header "3. System Logs"

    log "Cleaning old logs"

    print_info "Logs size: $(get_size ~/Library/Logs)"

    if confirm "Clean old logs (>30 days)?"; then
        if [ "$DRY_RUN" = true ]; then
            local count=$(find ~/Library/Logs -name "*.log" -mtime +30 2>/dev/null | wc -l)
            print_dry_run "Would delete $count log files"
            log_cleanup "Old logs" "$count files" "DRY RUN"
        else
            find ~/Library/Logs -name "*.log" -mtime +30 -delete 2>/dev/null
            find ~/Library/Logs -name "*.old" -delete 2>/dev/null
            find ~/Library/Logs -type d -empty -delete 2>/dev/null
            print_success "Old logs cleaned"
        fi
    else
        print_warning "Skipped"
    fi
}

cleanup_trash() {
    print_header "4. Trash"

    local trash_size=$(get_size ~/.Trash)
    print_info "Trash size: $trash_size"

    if confirm "Empty trash?"; then
        safe_remove ~/.Trash/* "Trash contents"
    else
        print_warning "Skipped"
    fi
}

cleanup_npm() {
    print_header "5. NPM Cache"

    if command -v npm &> /dev/null; then
        local npm_size=$(get_size ~/.npm)
        print_info "NPM cache size: $npm_size"

        if confirm "Clean NPM cache?"; then
            log "Cleaning NPM cache"
            if [ "$DRY_RUN" = true ]; then
                print_dry_run "Would clean NPM cache ($npm_size)"
                log_cleanup "NPM cache" "$npm_size" "DRY RUN"
            else
                npm cache clean --force 2>/dev/null
                print_success "NPM cache cleaned"
                log_cleanup "NPM cache" "$npm_size" "CLEANED"
            fi
        else
            print_warning "Skipped"
        fi
    else
        print_info "NPM not installed"
    fi
}

cleanup_homebrew() {
    print_header "6. Homebrew"

    if command -v brew &> /dev/null; then
        local brew_cache=$(get_size ~/Library/Caches/Homebrew)
        print_info "Homebrew cache: $brew_cache"

        if confirm "Clean Homebrew cache and old versions?"; then
            log "Cleaning Homebrew"
            if [ "$DRY_RUN" = true ]; then
                print_dry_run "Would clean Homebrew ($brew_cache)"
                log_cleanup "Homebrew" "$brew_cache" "DRY RUN"
            else
                brew cleanup --prune=all -s 2>/dev/null
                brew autoremove 2>/dev/null
                print_success "Homebrew cleaned"
                log_cleanup "Homebrew" "$brew_cache" "CLEANED"
            fi
        else
            print_warning "Skipped"
        fi
    else
        print_info "Homebrew not installed"
    fi
}

cleanup_xcode() {
    print_header "7. Xcode Derived Data"

    if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
        local xcode_size=$(get_size ~/Library/Developer/Xcode/DerivedData)
        print_info "Derived Data size: $xcode_size"

        if confirm "Clean Xcode derived data?"; then
            safe_remove ~/Library/Developer/Xcode/DerivedData/* "Xcode Derived Data"
        else
            print_warning "Skipped"
        fi
    else
        print_info "Xcode not installed"
    fi
}

# ================================================================
# Command Line Argument Parsing
# ================================================================

show_help() {
    cat <<EOF
${BOLD}PlsCleanMyMac v$VERSION${NC}
Free and open-source Mac cleanup utility

${BOLD}USAGE:${NC}
    $(basename "$0") [OPTIONS]

${BOLD}OPTIONS:${NC}
    -h, --help              Show this help message
    -n, --dry-run           Preview what will be deleted (no actual deletion)
    -u, --uninstall APP     Completely uninstall an application
    --no-log                Disable logging
    --show-logs             Show recent cleanup logs
    --show-reports          Show recent cleanup reports

${BOLD}EXAMPLES:${NC}
    # Interactive cleanup
    $(basename "$0")

    # Preview what will be deleted
    $(basename "$0") --dry-run

    # Uninstall an application
    $(basename "$0") --uninstall "Grammarly Desktop"

    # View recent reports
    $(basename "$0") --show-reports

${BOLD}MODES:${NC}
    1. Run all safe cleanups (recommended)
    2. Custom cleanup (choose what to clean)
    3. Disk usage analysis only
    4. Uninstall application

${BOLD}REPORTS & LOGS:${NC}
    Logs:    $LOG_DIR
    Reports: Available after each cleanup

EOF
}

show_logs() {
    print_header "Recent Cleanup Logs"

    if [ ! -d "$LOG_DIR" ]; then
        print_warning "No logs found"
        return
    fi

    ls -lt "$LOG_DIR"/*.log 2>/dev/null | head -5 | while read -r line; do
        local file=$(echo "$line" | awk '{print $NF}')
        local date=$(echo "$line" | awk '{print $6, $7, $8}')
        echo "  • $(basename "$file") - $date"
    done

    echo ""
    print_info "View full log: cat $LOG_DIR/cleanup-*.log"
}

show_reports() {
    print_header "Recent Cleanup Reports"

    if [ ! -d "$LOG_DIR" ]; then
        print_warning "No reports found"
        return
    fi

    local latest=$(ls -t "$LOG_DIR"/report-*.txt 2>/dev/null | head -1)

    if [ -z "$latest" ]; then
        print_warning "No reports found"
        return
    fi

    cat "$latest"
    echo ""
    print_info "All reports: ls $LOG_DIR/report-*.txt"
}

# ================================================================
# Main Menu
# ================================================================

show_menu() {
    clear
    print_header "PlsCleanMyMac v${VERSION}"

    if [ "$DRY_RUN" = true ]; then
        print_warning "DRY RUN MODE - No files will be deleted"
        echo ""
    fi

    echo -e "${BOLD}Quick Actions:${NC}"
    echo "  1) Run all safe cleanups (recommended)"
    echo "  2) Custom cleanup (choose what to clean)"
    echo "  3) Disk usage analysis only"
    echo "  4) Uninstall application"
    echo "  5) View cleanup reports"
    echo "  6) Exit"
    echo ""
}

run_all_safe() {
    print_header "Running All Safe Cleanups"

    cleanup_system_caches
    cleanup_browser_caches
    cleanup_logs
    cleanup_trash
    cleanup_npm
    cleanup_homebrew
    cleanup_xcode

    show_summary
}

run_custom() {
    print_header "Custom Cleanup"

    echo "Select items to clean (comma-separated, e.g., 1,2,3):"
    echo ""
    echo "  1) System caches"
    echo "  2) Browser caches"
    echo "  3) Logs"
    echo "  4) Trash"
    echo "  5) NPM cache"
    echo "  6) Homebrew"
    echo "  7) Xcode derived data"
    echo ""
    echo -n "Enter choices (or 'all'): "
    read -r choices

    echo ""

    if [ "$choices" = "all" ]; then
        run_all_safe
    else
        IFS=',' read -ra ITEMS <<< "$choices"
        for item in "${ITEMS[@]}"; do
            case "$item" in
                1) cleanup_system_caches ;;
                2) cleanup_browser_caches ;;
                3) cleanup_logs ;;
                4) cleanup_trash ;;
                5) cleanup_npm ;;
                6) cleanup_homebrew ;;
                7) cleanup_xcode ;;
            esac
        done
        show_summary
    fi
}

run_uninstaller() {
    print_header "Application Uninstaller"

    echo "Enter the application name (e.g., 'Grammarly Desktop'):"
    echo -n "> "
    read -r app_name

    if [ -z "$app_name" ]; then
        print_error "No application name provided"
        return
    fi

    uninstall_app "$app_name"
    show_summary
}

show_summary() {
    print_header "Cleanup Summary"

    echo ""
    if [ "$DRY_RUN" = true ]; then
        print_warning "DRY RUN MODE - No files were actually deleted"
        print_info "Total space that would be freed: $((TOTAL_FREED / 1024 / 1024))GB"
    else
        print_success "Total space freed: $((TOTAL_FREED / 1024 / 1024))GB ($((TOTAL_FREED / 1024))MB)"
    fi
    echo ""

    print_info "Current disk usage:"
    df -h / | tail -1
    echo ""

    if [ "$ENABLE_LOGGING" = true ]; then
        generate_report
        echo ""
    fi

    print_info "Press Enter to continue..."
    read
}

# ================================================================
# Main Program
# ================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -u|--uninstall)
                if [ -z "$2" ]; then
                    print_error "Application name required"
                    exit 1
                fi
                setup_logging
                uninstall_app "$2"
                show_summary
                exit 0
                ;;
            --no-log)
                ENABLE_LOGGING=false
                shift
                ;;
            --show-logs)
                show_logs
                exit 0
                ;;
            --show-reports)
                show_reports
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Check if running as root (not recommended)
    if [ "$EUID" -eq 0 ]; then
        print_error "Don't run this as root/sudo!"
        exit 1
    fi

    # Setup logging
    setup_logging

    while true; do
        show_menu

        echo -n "Choose an option: "
        read -r choice

        case $choice in
            1)
                run_all_safe
                ;;
            2)
                run_custom
                ;;
            3)
                print_header "Disk Usage Analysis"
                df -h / | tail -1
                echo ""
                print_info "Largest directories in home:"
                du -sh ~/* 2>/dev/null | sort -hr | head -10
                echo ""
                print_info "Press Enter to continue..."
                read
                ;;
            4)
                run_uninstaller
                ;;
            5)
                show_reports
                print_info "Press Enter to continue..."
                read
                ;;
            6)
                print_info "Goodbye!"
                log "Cleanup session ended"
                exit 0
                ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# Run main program
main "$@"
