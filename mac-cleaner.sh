#!/bin/bash

# ================================================================
# PlsCleanMyMac - All-in-One Mac Cleaner
# One file to rule them all!
# ================================================================

VERSION="4.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Quick installer embedded
if [ "$1" = "--install" ] || [ "$1" = "install" ]; then
    exec bash "$SCRIPT_DIR/install.sh"
fi

# For scheduled runs (called by launchd)
if [ "$1" = "--auto" ]; then
    exec plsclean-auto 2>/dev/null || {
        # Fallback if not installed
        bash "$SCRIPT_DIR/install.sh"
    }
fi

if [ "$1" = "--duplicates" ]; then
    exec plsclean-duplicates 2>/dev/null || {
        bash "$SCRIPT_DIR/install.sh"
    }
fi

# Default: Check if installed, if not -> offer install
if ! command -v plsclean-auto &> /dev/null; then
    clear
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║           Welcome to PlsCleanMyMac! 🚀                   ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "Choose your experience:"
    echo ""
    echo "  1) Zero Touch Mode (Recommended) ⭐"
    echo "     Install once, never think about it again"
    echo "     → Weekly auto-cleanup"
    echo "     → Monthly duplicate scan"
    echo "     → Smart auto-delete"
    echo "     → Notifications when done"
    echo ""
    echo "  2) Advanced Mode (TUI)"
    echo "     Interactive terminal UI"
    echo "     → Choose what to clean"
    echo "     → Manual duplicate finder"
    echo "     → Full control"
    echo ""
    echo -n "Choose [1-2]: "
    read -r mode_choice

    if [ "$mode_choice" = "1" ]; then
        echo ""
        echo "Installing Zero Touch Mode..."
        bash "$SCRIPT_DIR/install.sh"
    else
        # Run v3 TUI if available
        if [ -f "$SCRIPT_DIR/mac-cleaner-v3.sh" ]; then
            exec bash "$SCRIPT_DIR/mac-cleaner-v3.sh"
        else
            echo "TUI not available. Running installer..."
            bash "$SCRIPT_DIR/install.sh"
        fi
    fi
else
    # Already installed - run TUI
    if [ -f "$SCRIPT_DIR/mac-cleaner-v3.sh" ]; then
        exec bash "$SCRIPT_DIR/mac-cleaner-v3.sh" "$@"
    else
        echo "Running auto cleanup..."
        plsclean-auto
    fi
fi
