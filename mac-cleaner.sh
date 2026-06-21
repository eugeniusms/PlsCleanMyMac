#!/bin/bash

# ================================================================
# MAC CLEANER - DIY Mac Cleaner Alternative
# Comprehensive Mac cleanup utility
# ================================================================

VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Track total space freed
TOTAL_FREED=0

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

# ================================================================
# Cleanup Functions
# ================================================================

cleanup_system_caches() {
    print_header "1. System Caches"

    local size_before=$(get_size_bytes ~/Library/Caches)
    print_info "Current cache size: $(get_size ~/Library/Caches)"

    if confirm "Clean system caches?"; then
        # User caches (safe ones)
        find ~/Library/Caches -type d -maxdepth 1 -not -name "com.apple.*" -exec rm -rf {} \; 2>/dev/null

        local size_after=$(get_size_bytes ~/Library/Caches)
        local freed=$((size_before - size_after))
        TOTAL_FREED=$((TOTAL_FREED + freed))

        print_success "Freed: $((freed / 1024))MB"
    else
        print_warning "Skipped"
    fi
}

cleanup_browser_caches() {
    print_header "2. Browser Caches"

    local total_size=0

    # Chrome
    if [ -d ~/Library/Caches/Google/Chrome ]; then
        local chrome_size=$(get_size ~/Library/Caches/Google/Chrome)
        print_info "Chrome cache: $chrome_size"
        total_size=$((total_size + $(get_size_bytes ~/Library/Caches/Google/Chrome)))
    fi

    # Safari
    if [ -d ~/Library/Caches/com.apple.Safari ]; then
        local safari_size=$(get_size ~/Library/Caches/com.apple.Safari)
        print_info "Safari cache: $safari_size"
        total_size=$((total_size + $(get_size_bytes ~/Library/Caches/com.apple.Safari)))
    fi

    # Firefox
    if [ -d ~/Library/Caches/Firefox ]; then
        local firefox_size=$(get_size ~/Library/Caches/Firefox)
        print_info "Firefox cache: $firefox_size"
        total_size=$((total_size + $(get_size_bytes ~/Library/Caches/Firefox)))
    fi

    if [ $total_size -gt 0 ]; then
        if confirm "Clean browser caches?"; then
            rm -rf ~/Library/Caches/Google/Chrome/Default/Cache 2>/dev/null
            rm -rf ~/Library/Caches/Google/Chrome/Default/Code\ Cache 2>/dev/null
            rm -rf ~/Library/Caches/Google/Chrome/Default/GPUCache 2>/dev/null
            rm -rf ~/Library/Caches/com.apple.Safari 2>/dev/null
            rm -rf ~/Library/Caches/Firefox 2>/dev/null

            TOTAL_FREED=$((TOTAL_FREED + total_size))
            print_success "Freed: $((total_size / 1024))MB"
        else
            print_warning "Skipped"
        fi
    else
        print_info "No browser caches found"
    fi
}

cleanup_logs() {
    print_header "3. System Logs"

    local logs_size=$(get_size_bytes ~/Library/Logs)
    print_info "Logs size: $(get_size ~/Library/Logs)"

    if confirm "Clean old logs (>30 days)?"; then
        find ~/Library/Logs -name "*.log" -mtime +30 -delete 2>/dev/null
        find ~/Library/Logs -name "*.old" -delete 2>/dev/null
        find ~/Library/Logs -type d -empty -delete 2>/dev/null

        local new_size=$(get_size_bytes ~/Library/Logs)
        local freed=$((logs_size - new_size))
        TOTAL_FREED=$((TOTAL_FREED + freed))

        print_success "Freed: $((freed / 1024))MB"
    else
        print_warning "Skipped"
    fi
}

cleanup_trash() {
    print_header "4. Trash"

    local trash_size=$(get_size ~/.Trash)
    print_info "Trash size: $trash_size"

    if confirm "Empty trash?"; then
        local size_before=$(get_size_bytes ~/.Trash)
        rm -rf ~/.Trash/* 2>/dev/null
        TOTAL_FREED=$((TOTAL_FREED + size_before))
        print_success "Trash emptied: $trash_size freed"
    else
        print_warning "Skipped"
    fi
}

cleanup_downloads() {
    print_header "5. Downloads Folder"

    local downloads_size=$(get_size ~/Downloads)
    print_info "Downloads size: $downloads_size"
    print_warning "This will list files, you choose what to delete"

    if confirm "Review downloads folder?"; then
        echo ""
        print_info "Files older than 30 days:"
        find ~/Downloads -type f -mtime +30 -exec ls -lh {} \; 2>/dev/null | awk '{print $9, "("$5")"}'
        echo ""

        if confirm "Delete files older than 30 days?"; then
            local size_before=$(get_size_bytes ~/Downloads)
            find ~/Downloads -type f -mtime +30 -delete 2>/dev/null
            local size_after=$(get_size_bytes ~/Downloads)
            local freed=$((size_before - size_after))
            TOTAL_FREED=$((TOTAL_FREED + freed))
            print_success "Freed: $((freed / 1024))MB"
        fi
    else
        print_warning "Skipped"
    fi
}

cleanup_npm() {
    print_header "6. NPM Cache"

    if command -v npm &> /dev/null; then
        local npm_size=$(get_size ~/.npm)
        print_info "NPM cache size: $npm_size"

        if confirm "Clean NPM cache?"; then
            local size_before=$(get_size_bytes ~/.npm)
            npm cache clean --force 2>/dev/null
            local size_after=$(get_size_bytes ~/.npm)
            local freed=$((size_before - size_after))
            TOTAL_FREED=$((TOTAL_FREED + freed))
            print_success "Freed: $((freed / 1024))MB"
        else
            print_warning "Skipped"
        fi
    else
        print_info "NPM not installed"
    fi
}

cleanup_yarn() {
    print_header "7. Yarn Cache"

    if command -v yarn &> /dev/null; then
        local yarn_size=$(get_size ~/Library/Caches/Yarn)
        print_info "Yarn cache size: $yarn_size"

        if confirm "Clean Yarn cache?"; then
            local size_before=$(get_size_bytes ~/Library/Caches/Yarn)
            yarn cache clean 2>/dev/null
            local size_after=$(get_size_bytes ~/Library/Caches/Yarn)
            local freed=$((size_before - size_after))
            TOTAL_FREED=$((TOTAL_FREED + freed))
            print_success "Freed: $((freed / 1024))MB"
        else
            print_warning "Skipped"
        fi
    else
        print_info "Yarn not installed"
    fi
}

cleanup_homebrew() {
    print_header "8. Homebrew"

    if command -v brew &> /dev/null; then
        local brew_cache=$(get_size ~/Library/Caches/Homebrew)
        print_info "Homebrew cache: $brew_cache"

        if confirm "Clean Homebrew cache and old versions?"; then
            local size_before=$(get_size_bytes ~/Library/Caches/Homebrew)
            brew cleanup --prune=all -s 2>/dev/null
            brew autoremove 2>/dev/null
            local size_after=$(get_size_bytes ~/Library/Caches/Homebrew)
            local freed=$((size_before - size_after))
            TOTAL_FREED=$((TOTAL_FREED + freed))
            print_success "Freed: $((freed / 1024))MB"
        else
            print_warning "Skipped"
        fi
    else
        print_info "Homebrew not installed"
    fi
}

cleanup_docker() {
    print_header "9. Docker"

    if command -v docker &> /dev/null; then
        print_info "Docker system info:"
        docker system df 2>/dev/null || print_info "Docker not running"

        if confirm "Clean Docker (images, containers, volumes)?"; then
            docker system prune -a --volumes -f 2>/dev/null
            print_success "Docker cleaned"
        else
            print_warning "Skipped"
        fi
    else
        print_info "Docker not installed"
    fi
}

cleanup_xcode() {
    print_header "10. Xcode Derived Data"

    if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
        local xcode_size=$(get_size ~/Library/Developer/Xcode/DerivedData)
        print_info "Derived Data size: $xcode_size"

        if confirm "Clean Xcode derived data?"; then
            local size_before=$(get_size_bytes ~/Library/Developer/Xcode/DerivedData)
            rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null
            TOTAL_FREED=$((TOTAL_FREED + size_before))
            print_success "Freed: $xcode_size"
        else
            print_warning "Skipped"
        fi

        # Archives
        if [ -d ~/Library/Developer/Xcode/Archives ]; then
            local archives_size=$(get_size ~/Library/Developer/Xcode/Archives)
            print_info "Archives size: $archives_size"

            if confirm "Clean old Xcode archives?"; then
                local size_before=$(get_size_bytes ~/Library/Developer/Xcode/Archives)
                find ~/Library/Developer/Xcode/Archives -mtime +90 -delete 2>/dev/null
                local size_after=$(get_size_bytes ~/Library/Developer/Xcode/Archives)
                local freed=$((size_before - size_after))
                TOTAL_FREED=$((TOTAL_FREED + freed))
                print_success "Freed: $((freed / 1024))MB"
            fi
        fi
    else
        print_info "Xcode not installed"
    fi
}

cleanup_ios_simulators() {
    print_header "11. iOS Simulators"

    if command -v xcrun &> /dev/null; then
        print_info "Finding unavailable simulators..."

        if confirm "Delete unavailable iOS simulators?"; then
            xcrun simctl delete unavailable 2>/dev/null
            print_success "Unavailable simulators deleted"
        else
            print_warning "Skipped"
        fi
    else
        print_info "Xcode command line tools not installed"
    fi
}

cleanup_mail_attachments() {
    print_header "12. Mail Attachments"

    if [ -d ~/Library/Mail ]; then
        print_info "Mail attachments cache exists"

        if confirm "Clean Mail attachments cache?"; then
            rm -rf ~/Library/Mail/V*/MailData/Envelope\ Index 2>/dev/null
            print_success "Mail cache cleaned"
        else
            print_warning "Skipped"
        fi
    else
        print_info "Mail not used"
    fi
}

cleanup_spotify() {
    print_header "13. Spotify Cache"

    if [ -d ~/Library/Caches/com.spotify.client ]; then
        local spotify_size=$(get_size ~/Library/Caches/com.spotify.client)
        print_info "Spotify cache: $spotify_size"

        if confirm "Clean Spotify cache?"; then
            local size_before=$(get_size_bytes ~/Library/Caches/com.spotify.client)
            rm -rf ~/Library/Caches/com.spotify.client/Data 2>/dev/null
            local freed=$((size_before - $(get_size_bytes ~/Library/Caches/com.spotify.client)))
            TOTAL_FREED=$((TOTAL_FREED + freed))
            print_success "Freed: $((freed / 1024))MB"
        else
            print_warning "Skipped"
        fi
    else
        print_info "Spotify not installed"
    fi
}

cleanup_temp_files() {
    print_header "14. Temporary Files"

    print_info "System temp files"

    if confirm "Clean temporary files?"; then
        # User temp
        rm -rf /tmp/* 2>/dev/null

        # System temp
        if [ -d /var/folders ]; then
            sudo rm -rf /var/folders/*/* 2>/dev/null
        fi

        print_success "Temp files cleaned"
    else
        print_warning "Skipped"
    fi
}

cleanup_dsstore() {
    print_header "15. .DS_Store Files"

    print_info "Finding .DS_Store files in home directory..."
    local count=$(find ~ -name ".DS_Store" 2>/dev/null | wc -l)
    print_info "Found $count .DS_Store files"

    if [ $count -gt 0 ]; then
        if confirm "Delete all .DS_Store files?"; then
            find ~ -name ".DS_Store" -delete 2>/dev/null
            print_success "Deleted $count .DS_Store files"
        else
            print_warning "Skipped"
        fi
    fi
}

analyze_large_files() {
    print_header "16. Large Files Analysis"

    if confirm "Find large files (>500MB)?"; then
        echo ""
        print_info "Searching for large files (this may take a minute)..."
        echo ""
        find ~ -type f -size +500M -exec ls -lh {} \; 2>/dev/null | awk '{print $9, "("$5")"}'
        echo ""
    else
        print_warning "Skipped"
    fi
}

analyze_disk_usage() {
    print_header "17. Disk Usage Analysis"

    echo ""
    print_info "Current disk usage:"
    df -h / | tail -1
    echo ""

    print_info "Largest directories in home:"
    du -sh ~/* 2>/dev/null | sort -hr | head -10
    echo ""
}

# ================================================================
# Main Menu
# ================================================================

show_menu() {
    clear
    print_header "MAC CLEANER v${VERSION}"

    echo -e "${BOLD}Quick Actions:${NC}"
    echo "  1) Run all safe cleanups (recommended)"
    echo "  2) Custom cleanup (choose what to clean)"
    echo "  3) Disk usage analysis only"
    echo "  4) Exit"
    echo ""
}

run_all_safe() {
    print_header "Running All Safe Cleanups"

    cleanup_system_caches
    cleanup_browser_caches
    cleanup_logs
    cleanup_trash
    cleanup_npm
    cleanup_yarn
    cleanup_homebrew
    cleanup_xcode
    cleanup_ios_simulators
    cleanup_spotify
    cleanup_dsstore

    show_summary
}

run_custom() {
    print_header "Custom Cleanup"

    echo "Select items to clean (comma-separated, e.g., 1,2,3):"
    echo ""
    echo "  1)  System caches"
    echo "  2)  Browser caches"
    echo "  3)  Logs"
    echo "  4)  Trash"
    echo "  5)  Downloads (old files)"
    echo "  6)  NPM cache"
    echo "  7)  Yarn cache"
    echo "  8)  Homebrew"
    echo "  9)  Docker"
    echo "  10) Xcode derived data"
    echo "  11) iOS simulators"
    echo "  12) Mail attachments"
    echo "  13) Spotify cache"
    echo "  14) Temp files"
    echo "  15) .DS_Store files"
    echo "  16) Find large files"
    echo "  17) Disk analysis"
    echo ""
    echo -n "Enter choices (or 'all'): "
    read -r choices

    echo ""

    if [ "$choices" = "all" ]; then
        cleanup_system_caches
        cleanup_browser_caches
        cleanup_logs
        cleanup_trash
        cleanup_downloads
        cleanup_npm
        cleanup_yarn
        cleanup_homebrew
        cleanup_docker
        cleanup_xcode
        cleanup_ios_simulators
        cleanup_mail_attachments
        cleanup_spotify
        cleanup_temp_files
        cleanup_dsstore
        analyze_large_files
        analyze_disk_usage
    else
        IFS=',' read -ra ITEMS <<< "$choices"
        for item in "${ITEMS[@]}"; do
            case "$item" in
                1) cleanup_system_caches ;;
                2) cleanup_browser_caches ;;
                3) cleanup_logs ;;
                4) cleanup_trash ;;
                5) cleanup_downloads ;;
                6) cleanup_npm ;;
                7) cleanup_yarn ;;
                8) cleanup_homebrew ;;
                9) cleanup_docker ;;
                10) cleanup_xcode ;;
                11) cleanup_ios_simulators ;;
                12) cleanup_mail_attachments ;;
                13) cleanup_spotify ;;
                14) cleanup_temp_files ;;
                15) cleanup_dsstore ;;
                16) analyze_large_files ;;
                17) analyze_disk_usage ;;
            esac
        done
    fi

    show_summary
}

show_summary() {
    print_header "Cleanup Summary"

    echo ""
    print_success "Total space freed: $((TOTAL_FREED / 1024 / 1024))GB"
    echo ""

    print_info "Current disk usage:"
    df -h / | tail -1
    echo ""

    print_info "Press Enter to continue..."
    read
}

# ================================================================
# Main Program
# ================================================================

main() {
    # Check if running as root (not recommended)
    if [ "$EUID" -eq 0 ]; then
        print_error "Don't run this as root/sudo!"
        exit 1
    fi

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
                analyze_disk_usage
                print_info "Press Enter to continue..."
                read
                ;;
            4)
                print_info "Goodbye!"
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
main
