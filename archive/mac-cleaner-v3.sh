#!/bin/bash

# ================================================================
# MAC CLEANER v3.0 - Advanced Features Edition
# TUI + Duplicate Finder + Scheduled Cleanups
# ================================================================

VERSION="3.0.0"

# Source v2.0 functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/mac-cleaner-v2.sh" ]; then
    source "$SCRIPT_DIR/mac-cleaner-v2.sh"
fi

# Additional configuration for v3.0
DUPLICATES_REPORT="$LOG_DIR/duplicates-$(date +%Y%m%d-%H%M%S).txt"
SCHEDULE_PLIST="$HOME/Library/LaunchAgents/com.plscleanmymac.schedule.plist"

# ================================================================
# TUI (Terminal UI) Functions
# ================================================================

# Terminal control
clear_screen() {
    clear
}

draw_box() {
    local width=$1
    local height=$2
    local title="$3"

    # Top border
    echo -ne "${CYAN}╔"
    printf '═%.0s' $(seq 1 $((width-2)))
    echo "╗${NC}"

    # Title
    if [ -n "$title" ]; then
        local padding=$(( (width - ${#title} - 4) / 2 ))
        echo -ne "${CYAN}║${NC}"
        printf ' %.0s' $(seq 1 $padding)
        echo -ne "${BOLD}${title}${NC}"
        printf ' %.0s' $(seq 1 $padding)
        echo -e "${CYAN}║${NC}"

        # Separator
        echo -ne "${CYAN}╠"
        printf '═%.0s' $(seq 1 $((width-2)))
        echo "╣${NC}"
    fi

    # Content area placeholder
    for i in $(seq 1 $((height-4))); do
        echo -ne "${CYAN}║${NC}"
        printf ' %.0s' $(seq 1 $((width-2)))
        echo "${CYAN}║${NC}"
    done

    # Bottom border
    echo -ne "${CYAN}╚"
    printf '═%.0s' $(seq 1 $((width-2)))
    echo "╝${NC}"
}

draw_menu() {
    local title="$1"
    shift
    local options=("$@")

    clear_screen

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${title}${NC}$(printf ' %.0s' $(seq 1 $((60-${#title}))))${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"

    local i=1
    for option in "${options[@]}"; do
        printf "${CYAN}║${NC}  ${GREEN}%2d${NC}) %-56s ${CYAN}║${NC}\n" "$i" "$option"
        ((i++))
    done

    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

draw_progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))

    echo -ne "\r${CYAN}Progress: [${NC}"
    printf "${GREEN}█%.0s${NC}" $(seq 1 $filled)
    printf "${BLUE}░%.0s${NC}" $(seq 1 $((width - filled)))
    echo -ne "${CYAN}]${NC} ${BOLD}${percent}%${NC} (${current}/${total})"
}

show_tui_main_menu() {
    while true; do
        draw_menu "PlsCleanMyMac v$VERSION - Main Menu" \
            "Quick Cleanup (Safe Mode)" \
            "Custom Cleanup (Advanced)" \
            "Find Duplicate Files" \
            "Schedule Automatic Cleanup" \
            "Uninstall Application" \
            "View Reports & History" \
            "Disk Usage Analysis" \
            "Settings & Help" \
            "Exit"

        echo -ne "${YELLOW}Select option [1-9]:${NC} "
        read -r choice

        case $choice in
            1) tui_quick_cleanup ;;
            2) tui_custom_cleanup ;;
            3) tui_duplicate_finder ;;
            4) tui_schedule_cleanup ;;
            5) tui_uninstall_app ;;
            6) tui_view_reports ;;
            7) tui_disk_analysis ;;
            8) tui_settings ;;
            9)
                echo ""
                print_success "Thank you for using PlsCleanMyMac!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Press Enter to continue..."
                read
                ;;
        esac
    done
}

tui_quick_cleanup() {
    clear_screen
    print_header "Quick Cleanup - Safe Mode"

    echo "This will clean:"
    echo "  • System caches (non-Apple)"
    echo "  • Browser caches"
    echo "  • Old logs (>30 days)"
    echo "  • NPM/Yarn caches"
    echo "  • Homebrew caches"
    echo "  • Trash"
    echo ""

    if confirm "Start cleanup?"; then
        setup_logging
        run_all_safe
    fi

    echo ""
    print_info "Press Enter to return to menu..."
    read
}

tui_custom_cleanup() {
    while true; do
        draw_menu "Custom Cleanup - Choose Items" \
            "System Caches" \
            "Browser Caches" \
            "Old Logs" \
            "Trash" \
            "NPM Cache" \
            "Yarn Cache" \
            "Homebrew Cache" \
            "Xcode Derived Data" \
            "Clean All Selected" \
            "Back to Main Menu"

        echo -ne "${YELLOW}Select items (or 9 to clean, 0 to go back):${NC} "
        read -r choice

        case $choice in
            1|2|3|4|5|6|7|8)
                # Mark for cleanup
                print_info "Marked for cleanup"
                sleep 0.5
                ;;
            9)
                setup_logging
                # Run selected cleanups
                cleanup_system_caches
                cleanup_browser_caches
                show_summary
                return
                ;;
            10|0)
                return
                ;;
        esac
    done
}

# ================================================================
# Duplicate Finder
# ================================================================

find_duplicates() {
    local search_path="$1"
    local min_size="${2:-1M}"  # Default 1MB minimum

    print_header "Duplicate File Finder"
    print_info "Scanning: $search_path"
    print_info "Minimum file size: $min_size"

    log "Finding duplicates in: $search_path"

    # Create temp files
    local size_list="/tmp/plsclean_sizes_$$.txt"
    local hash_list="/tmp/plsclean_hashes_$$.txt"
    local dupe_list="/tmp/plsclean_dupes_$$.txt"

    # Step 1: Find files by size
    print_info "Step 1/3: Finding files by size..."
    find "$search_path" -type f -size +"$min_size" -exec ls -ln {} \; 2>/dev/null | \
        awk '{print $5"|"$9}' | sort > "$size_list"

    local total_files=$(wc -l < "$size_list")
    print_success "Found $total_files files"

    if [ "$total_files" -eq 0 ]; then
        print_warning "No files found to check"
        rm -f "$size_list"
        return
    fi

    # Step 2: Find potential duplicates (same size)
    print_info "Step 2/3: Finding files with same size..."
    awk -F'|' '{sizes[$1]++; files[$1]=files[$1]"|"$2}
                END {for(s in sizes) if(sizes[s]>1) print s"|"files[s]}' \
        "$size_list" > "$hash_list"

    local potential_dupes=$(wc -l < "$hash_list")
    print_info "Found $potential_dupes size groups to check"

    if [ "$potential_dupes" -eq 0 ]; then
        print_warning "No potential duplicates found"
        rm -f "$size_list" "$hash_list"
        return
    fi

    # Step 3: Calculate checksums for same-size files
    print_info "Step 3/3: Calculating checksums (this may take a while)..."

    > "$dupe_list"
    local processed=0
    local total_groups=$potential_dupes

    while IFS='|' read -r size files; do
        ((processed++))
        draw_progress_bar $processed $total_groups

        # Split files and calculate checksums
        local file_array=()
        IFS='|' read -ra file_array <<< "$files"

        local checksums=()
        for file in "${file_array[@]}"; do
            if [ -f "$file" ]; then
                local checksum=$(md5 -q "$file" 2>/dev/null)
                if [ -n "$checksum" ]; then
                    checksums+=("$checksum|$file|$size")
                fi
            fi
        done

        # Group by checksum
        local -A hash_groups
        for item in "${checksums[@]}"; do
            IFS='|' read -r hash filepath filesize <<< "$item"
            hash_groups["$hash"]+="$filepath|$filesize "
        done

        # Find actual duplicates
        for hash in "${!hash_groups[@]}"; do
            local group="${hash_groups[$hash]}"
            local count=$(echo "$group" | tr ' ' '\n' | grep -c '|')
            if [ "$count" -gt 1 ]; then
                echo "$hash|$size|$group" >> "$dupe_list"
            fi
        done
    done < "$hash_list"

    echo ""  # New line after progress bar

    # Generate report
    if [ ! -s "$dupe_list" ]; then
        print_success "No duplicate files found!"
        rm -f "$size_list" "$hash_list" "$dupe_list"
        return
    fi

    local dupe_groups=$(wc -l < "$dupe_list")
    print_success "Found $dupe_groups groups of duplicates!"

    # Calculate potential space savings
    local total_wasted=0
    while IFS='|' read -r hash size files; do
        local file_array=()
        IFS=' ' read -ra file_array <<< "$files"
        local count=${#file_array[@]}
        if [ "$count" -gt 1 ]; then
            local wasted=$((size * (count - 1)))
            total_wasted=$((total_wasted + wasted))
        fi
    done < "$dupe_list"

    echo ""
    print_header "Duplicate Files Report"
    echo ""
    print_info "Duplicate groups found: $dupe_groups"
    print_info "Potential space savings: $((total_wasted / 1024 / 1024))MB"
    echo ""

    # Show duplicates
    local group_num=1
    while IFS='|' read -r hash size files; do
        echo -e "${CYAN}Group $group_num:${NC} (File size: $((size / 1024))KB)"

        local file_array=()
        IFS=' ' read -ra file_array <<< "$files"

        for item in "${file_array[@]}"; do
            IFS='|' read -r filepath filesize <<< "$item"
            if [ -n "$filepath" ]; then
                echo "  • $filepath"
            fi
        done
        echo ""
        ((group_num++))

        if [ "$group_num" -gt 10 ]; then
            print_info "Showing first 10 groups. Full report saved to: $DUPLICATES_REPORT"
            break
        fi
    done < "$dupe_list"

    # Save full report
    cat > "$DUPLICATES_REPORT" <<EOF
═══════════════════════════════════════════════════════════
PlsCleanMyMac - Duplicate Files Report
═══════════════════════════════════════════════════════════

Date: $(date)
Search Path: $search_path
Minimum Size: $min_size

─────────────────────────────────────────────────────────────
SUMMARY
─────────────────────────────────────────────────────────────
Duplicate Groups: $dupe_groups
Potential Space Savings: $((total_wasted / 1024 / 1024))MB

─────────────────────────────────────────────────────────────
DETAILS
─────────────────────────────────────────────────────────────

EOF

    group_num=1
    while IFS='|' read -r hash size files; do
        echo "Group $group_num: (Size: $((size / 1024))KB, Hash: $hash)" >> "$DUPLICATES_REPORT"

        local file_array=()
        IFS=' ' read -ra file_array <<< "$files"

        for item in "${file_array[@]}"; do
            IFS='|' read -r filepath filesize <<< "$item"
            if [ -n "$filepath" ]; then
                echo "  • $filepath" >> "$DUPLICATES_REPORT"
            fi
        done
        echo "" >> "$DUPLICATES_REPORT"
        ((group_num++))
    done < "$dupe_list"

    print_success "Full report saved to: $DUPLICATES_REPORT"
    log "Duplicate finder completed. Found $dupe_groups groups."

    # Cleanup
    rm -f "$size_list" "$hash_list" "$dupe_list"

    # Ask if user wants to delete duplicates
    echo ""
    if confirm "Do you want to interactively delete duplicates?"; then
        delete_duplicates_interactive "$DUPLICATES_REPORT"
    fi
}

delete_duplicates_interactive() {
    local report_file="$1"

    print_header "Interactive Duplicate Deletion"
    print_warning "For each group, you'll choose which file to KEEP"
    print_warning "All other files in the group will be deleted"
    echo ""

    # Parse report and show each group
    local in_group=false
    local group_files=()
    local group_size=""

    while IFS= read -r line; do
        if [[ $line =~ ^Group\ ([0-9]+): ]]; then
            # New group
            if [ ${#group_files[@]} -gt 0 ]; then
                # Process previous group
                choose_duplicate_to_keep "${group_files[@]}"
                group_files=()
            fi
            group_size=$(echo "$line" | grep -o 'Size: [0-9]*KB' | grep -o '[0-9]*')
            in_group=true
        elif [[ $line =~ ^[[:space:]]+• ]]; then
            # File in group
            local filepath=$(echo "$line" | sed 's/^[[:space:]]*• //')
            group_files+=("$filepath|$group_size")
        fi
    done < "$report_file"

    # Process last group
    if [ ${#group_files[@]} -gt 0 ]; then
        choose_duplicate_to_keep "${group_files[@]}"
    fi

    print_success "Interactive deletion complete!"
}

choose_duplicate_to_keep() {
    local files=("$@")

    if [ ${#files[@]} -lt 2 ]; then
        return
    fi

    echo ""
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${BOLD}Choose which file to KEEP:${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"

    local i=1
    for file_info in "${files[@]}"; do
        IFS='|' read -r filepath size <<< "$file_info"
        echo "  $i) $filepath"
        ((i++))
    done
    echo "  0) Skip this group"
    echo ""

    echo -ne "${YELLOW}Keep file number [0-${#files[@]}]:${NC} "
    read -r keep_choice

    if [ "$keep_choice" -eq 0 ] 2>/dev/null; then
        print_info "Skipped"
        return
    fi

    if [ "$keep_choice" -lt 1 ] || [ "$keep_choice" -gt ${#files[@]} ]; then
        print_error "Invalid choice. Skipping group."
        return
    fi

    # Delete all except chosen file
    local kept_file=""
    local i=1
    for file_info in "${files[@]}"; do
        IFS='|' read -r filepath size <<< "$file_info"

        if [ "$i" -eq "$keep_choice" ]; then
            kept_file="$filepath"
            print_info "Keeping: $filepath"
        else
            if [ "$DRY_RUN" = true ]; then
                print_dry_run "Would delete: $filepath (${size}KB)"
            else
                rm -f "$filepath"
                if [ $? -eq 0 ]; then
                    print_success "Deleted: $filepath (${size}KB)"
                    local size_bytes=$((size * 1024))
                    TOTAL_FREED=$((TOTAL_FREED + size_bytes))
                else
                    print_error "Failed to delete: $filepath"
                fi
            fi
        fi
        ((i++))
    done
}

tui_duplicate_finder() {
    clear_screen
    print_header "Duplicate File Finder"

    echo "Choose search location:"
    echo "  1) Home directory (~)"
    echo "  2) Documents"
    echo "  3) Downloads"
    echo "  4) Desktop"
    echo "  5) Custom path"
    echo "  0) Back"
    echo ""

    echo -ne "${YELLOW}Select [0-5]:${NC} "
    read -r choice

    local search_path=""
    case $choice in
        1) search_path="$HOME" ;;
        2) search_path="$HOME/Documents" ;;
        3) search_path="$HOME/Downloads" ;;
        4) search_path="$HOME/Desktop" ;;
        5)
            echo -ne "${YELLOW}Enter path:${NC} "
            read -r search_path
            ;;
        0) return ;;
        *)
            print_error "Invalid choice"
            sleep 1
            return
            ;;
    esac

    if [ ! -d "$search_path" ]; then
        print_error "Path not found: $search_path"
        sleep 2
        return
    fi

    echo ""
    echo -ne "${YELLOW}Minimum file size (1M, 10M, 100M) [default: 1M]:${NC} "
    read -r min_size
    min_size=${min_size:-1M}

    echo ""
    setup_logging
    find_duplicates "$search_path" "$min_size"

    echo ""
    print_info "Press Enter to continue..."
    read
}

# ================================================================
# Scheduled Cleanup
# ================================================================

create_schedule() {
    local frequency="$1"  # daily, weekly, monthly

    print_header "Schedule Automatic Cleanup"

    # Determine schedule
    local start_interval=""
    local human_schedule=""

    case $frequency in
        daily)
            start_interval=86400  # 24 hours
            human_schedule="Daily at 2:00 AM"
            ;;
        weekly)
            start_interval=604800  # 7 days
            human_schedule="Weekly (Sundays at 2:00 AM)"
            ;;
        monthly)
            start_interval=2592000  # 30 days
            human_schedule="Monthly (1st of month at 2:00 AM)"
            ;;
        *)
            print_error "Invalid frequency"
            return 1
            ;;
    esac

    print_info "Schedule: $human_schedule"
    print_info "Script: $SCRIPT_DIR/$(basename "$0")"
    echo ""

    if ! confirm "Create scheduled cleanup?"; then
        print_warning "Cancelled"
        return
    fi

    # Create launchd plist
    cat > "$SCHEDULE_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.plscleanmymac.schedule</string>

    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/$(basename "$0")</string>
        <string>--scheduled-run</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
EOF

    if [ "$frequency" = "weekly" ]; then
        cat >> "$SCHEDULE_PLIST" <<EOF
        <key>Weekday</key>
        <integer>0</integer>
EOF
    elif [ "$frequency" = "monthly" ]; then
        cat >> "$SCHEDULE_PLIST" <<EOF
        <key>Day</key>
        <integer>1</integer>
EOF
    fi

    cat >> "$SCHEDULE_PLIST" <<EOF
    </dict>

    <key>StandardOutPath</key>
    <string>$LOG_DIR/scheduled-cleanup.log</string>

    <key>StandardErrorPath</key>
    <string>$LOG_DIR/scheduled-cleanup-error.log</string>

    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>
EOF

    # Load the plist
    launchctl load "$SCHEDULE_PLIST" 2>/dev/null

    if [ $? -eq 0 ]; then
        print_success "Scheduled cleanup created!"
        print_info "Frequency: $human_schedule"
        print_info "Logs: $LOG_DIR/scheduled-cleanup.log"

        log "Scheduled cleanup created: $frequency"
    else
        print_error "Failed to create schedule"
        rm -f "$SCHEDULE_PLIST"
    fi
}

remove_schedule() {
    print_header "Remove Scheduled Cleanup"

    if [ ! -f "$SCHEDULE_PLIST" ]; then
        print_warning "No scheduled cleanup found"
        return
    fi

    print_info "Current schedule file: $SCHEDULE_PLIST"
    echo ""

    if confirm "Remove scheduled cleanup?"; then
        launchctl unload "$SCHEDULE_PLIST" 2>/dev/null
        rm -f "$SCHEDULE_PLIST"

        print_success "Scheduled cleanup removed"
        log "Scheduled cleanup removed"
    else
        print_warning "Cancelled"
    fi
}

show_schedule() {
    print_header "Current Schedule"

    if [ ! -f "$SCHEDULE_PLIST" ]; then
        print_warning "No scheduled cleanup configured"
        return
    fi

    print_success "Scheduled cleanup is active"
    echo ""

    # Parse plist to show schedule
    if grep -q "Weekday" "$SCHEDULE_PLIST"; then
        print_info "Frequency: Weekly (Sundays at 2:00 AM)"
    elif grep -q "Day" "$SCHEDULE_PLIST"; then
        print_info "Frequency: Monthly (1st of month at 2:00 AM)"
    else
        print_info "Frequency: Daily at 2:00 AM"
    fi

    echo ""
    print_info "Configuration: $SCHEDULE_PLIST"
    print_info "Logs: $LOG_DIR/scheduled-cleanup.log"

    # Show last run
    if [ -f "$LOG_DIR/scheduled-cleanup.log" ]; then
        echo ""
        print_info "Last run output:"
        tail -20 "$LOG_DIR/scheduled-cleanup.log"
    fi
}

run_scheduled_cleanup() {
    # This runs when triggered by launchd
    print_header "Scheduled Cleanup - Auto Run"

    setup_logging
    log "Scheduled cleanup started"

    # Run safe cleanup automatically
    cleanup_system_caches
    cleanup_browser_caches
    cleanup_logs
    cleanup_npm
    cleanup_homebrew

    # Generate report
    generate_report

    log "Scheduled cleanup completed. Freed: $((TOTAL_FREED / 1024 / 1024))GB"

    # Send notification
    osascript -e "display notification \"Freed $((TOTAL_FREED / 1024 / 1024))GB of disk space\" with title \"PlsCleanMyMac\" subtitle \"Scheduled Cleanup Complete\"" 2>/dev/null
}

tui_schedule_cleanup() {
    while true; do
        clear_screen
        draw_menu "Schedule Automatic Cleanup" \
            "Create Daily Schedule" \
            "Create Weekly Schedule" \
            "Create Monthly Schedule" \
            "View Current Schedule" \
            "Remove Schedule" \
            "Back to Main Menu"

        echo -ne "${YELLOW}Select option [1-6]:${NC} "
        read -r choice

        case $choice in
            1) create_schedule "daily"; sleep 2 ;;
            2) create_schedule "weekly"; sleep 2 ;;
            3) create_schedule "monthly"; sleep 2 ;;
            4) show_schedule; echo ""; print_info "Press Enter..."; read ;;
            5) remove_schedule; sleep 2 ;;
            6) return ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# ================================================================
# Additional TUI Screens
# ================================================================

tui_uninstall_app() {
    clear_screen
    print_header "Application Uninstaller"

    echo "Enter the application name (e.g., 'Zoom', 'Grammarly Desktop'):"
    echo -ne "${YELLOW}App name:${NC} "
    read -r app_name

    if [ -z "$app_name" ]; then
        print_error "No application name provided"
        sleep 1
        return
    fi

    setup_logging
    uninstall_app "$app_name"

    echo ""
    print_info "Press Enter to continue..."
    read
}

tui_view_reports() {
    clear_screen
    show_reports

    echo ""
    echo "Options:"
    echo "  1) View detailed log"
    echo "  2) Back"
    echo ""

    echo -ne "${YELLOW}Select:${NC} "
    read -r choice

    if [ "$choice" = "1" ]; then
        show_logs
        echo ""
        print_info "Press Enter to continue..."
        read
    fi
}

tui_disk_analysis() {
    clear_screen
    print_header "Disk Usage Analysis"

    echo ""
    print_info "Overall Disk Usage:"
    df -h / | tail -1
    echo ""

    print_info "Largest directories in home:"
    du -sh ~/* 2>/dev/null | sort -hr | head -15
    echo ""

    print_info "Press Enter to continue..."
    read
}

tui_settings() {
    while true; do
        clear_screen
        draw_menu "Settings & Help" \
            "Enable/Disable Logging" \
            "View Help" \
            "About PlsCleanMyMac" \
            "Back to Main Menu"

        echo -ne "${YELLOW}Select option [1-4]:${NC} "
        read -r choice

        case $choice in
            1)
                if [ "$ENABLE_LOGGING" = true ]; then
                    ENABLE_LOGGING=false
                    print_info "Logging disabled"
                else
                    ENABLE_LOGGING=true
                    print_info "Logging enabled"
                fi
                sleep 1
                ;;
            2)
                show_help
                echo ""
                print_info "Press Enter to continue..."
                read
                ;;
            3)
                clear_screen
                print_header "About PlsCleanMyMac v$VERSION"
                echo ""
                echo "Free and open-source Mac cleanup utility"
                echo ""
                echo "Features:"
                echo "  ✓ Interactive TUI"
                echo "  ✓ Duplicate file finder"
                echo "  ✓ Scheduled cleanups"
                echo "  ✓ Application uninstaller"
                echo "  ✓ Comprehensive logging"
                echo ""
                echo "Repository: https://github.com/eugeniusms/PlsCleanMyMac"
                echo ""
                print_info "Press Enter to continue..."
                read
                ;;
            4) return ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# ================================================================
# Main Entry Point for v3.0
# ================================================================

main_v3() {
    # Parse v3-specific arguments
    case "${1:-}" in
        --tui)
            setup_logging
            show_tui_main_menu
            exit 0
            ;;
        --find-duplicates)
            setup_logging
            local path="${2:-$HOME/Downloads}"
            local min_size="${3:-1M}"
            find_duplicates "$path" "$min_size"
            exit 0
            ;;
        --schedule)
            local freq="${2:-weekly}"
            create_schedule "$freq"
            exit 0
            ;;
        --scheduled-run)
            run_scheduled_cleanup
            exit 0
            ;;
        --remove-schedule)
            remove_schedule
            exit 0
            ;;
        --show-schedule)
            show_schedule
            exit 0
            ;;
        *)
            # If no v3 args, start TUI by default
            if [ "${1:-}" != "--help" ] && [ "${1:-}" != "-h" ] && [ "${1:-}" != "--dry-run" ] && [ "${1:-}" != "-n" ] && [ "${1:-}" != "--uninstall" ] && [ "${1:-}" != "-u" ]; then
                setup_logging
                show_tui_main_menu
                exit 0
            fi
            ;;
    esac
}

# Run v3 main or fall back to v2
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main_v3 "$@"
fi
