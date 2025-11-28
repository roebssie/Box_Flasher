#!/bin/bash

##############################################################################
# Cache Management Script
# Manages cached downloads and build artifacts
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_ROOT/data"
CACHE_DIR="$DATA_DIR/cache"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
}

print_step() {
    echo -e "${YELLOW}→${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

show_cache_usage() {
    print_header "Cache Directory Usage"
    
    echo "Cache location: $CACHE_DIR"
    echo ""
    echo "Cache breakdown:"
    echo ""
    
    if [ -d "$CACHE_DIR/downloaded" ]; then
        size=$(du -sh "$CACHE_DIR/downloaded" 2>/dev/null | awk '{print $1}')
        count=$(find "$CACHE_DIR/downloaded" -type f 2>/dev/null | wc -l)
        echo "  Downloaded files: $size ($count files)"
        ls -lh "$CACHE_DIR/downloaded" 2>/dev/null | tail -5 | sed 's/^/    /'
    fi
    
    if [ -d "$CACHE_DIR/build" ]; then
        size=$(du -sh "$CACHE_DIR/build" 2>/dev/null | awk '{print $1}')
        count=$(find "$CACHE_DIR/build" -type f 2>/dev/null | wc -l)
        echo "  Build artifacts: $size ($count files)"
    fi
    
    if [ -d "$CACHE_DIR/backups" ]; then
        size=$(du -sh "$CACHE_DIR/backups" 2>/dev/null | awk '{print $1}')
        count=$(find "$CACHE_DIR/backups" -type f 2>/dev/null | wc -l)
        echo "  Backups: $size ($count files)"
    fi
    
    echo ""
    total=$(du -sh "$CACHE_DIR" 2>/dev/null | awk '{print $1}')
    echo "  Total cache size: $total"
    echo ""
}

clean_downloaded_cache() {
    print_header "Cleaning Downloaded Cache"
    
    if [ -z "$(find "$CACHE_DIR/downloaded" -type f 2>/dev/null)" ]; then
        print_step "Cache is empty"
        return
    fi
    
    print_step "Contents of cache/downloaded:"
    ls -lh "$CACHE_DIR/downloaded"
    echo ""
    
    read -p "Remove all downloaded files? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CACHE_DIR/downloaded"/*
        mkdir -p "$CACHE_DIR/downloaded"
        print_success "Downloaded cache cleared"
    else
        print_step "Cancelled"
    fi
}

clean_build_cache() {
    print_header "Cleaning Build Cache"
    
    if [ -z "$(find "$CACHE_DIR/build" -type f 2>/dev/null)" ]; then
        print_step "Build cache is empty"
        return
    fi
    
    print_step "Contents of cache/build:"
    du -sh "$CACHE_DIR/build"/*
    echo ""
    
    read -p "Remove all build artifacts? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CACHE_DIR/build"/*
        mkdir -p "$CACHE_DIR/build"
        print_success "Build cache cleared"
    else
        print_step "Cancelled"
    fi
}

clean_old_backups() {
    print_header "Cleaning Old Backups"
    
    if [ -z "$(find "$CACHE_DIR/backups" -type f 2>/dev/null)" ]; then
        print_step "No backups found"
        return
    fi
    
    # Remove backups older than 30 days
    find "$CACHE_DIR/backups" -type f -mtime +30 -delete
    print_success "Old backups removed (>30 days)"
}

clean_all_cache() {
    print_header "Cleaning All Cache"
    
    read -p "This will remove ALL cache files. Continue? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CACHE_DIR"/*
        mkdir -p "$CACHE_DIR"/{downloaded,build,backups}
        print_success "All cache cleared"
    else
        print_step "Cancelled"
    fi
}

# Main menu
case "${1:-help}" in
    show|status)
        show_cache_usage
        ;;
    clean-downloaded)
        clean_downloaded_cache
        ;;
    clean-build)
        clean_build_cache
        ;;
    clean-backups)
        clean_old_backups
        ;;
    clean-all)
        clean_all_cache
        ;;
    *)
        echo "Cache Management Tool"
        echo ""
        echo "Usage: $(basename $0) <command>"
        echo ""
        echo "Commands:"
        echo "  show              Show cache usage"
        echo "  clean-downloaded  Remove downloaded files"
        echo "  clean-build       Remove build artifacts"
        echo "  clean-backups     Remove old backups (>30 days)"
        echo "  clean-all         Remove all cache"
        echo ""
        echo "Current cache status:"
        show_cache_usage
        ;;
esac
