#!/bin/bash
# Enhanced start-issue script that works with Linear MCP data
# This version properly handles JSON data passed via environment variables

set -euo pipefail

# Source required files
source "$(dirname "$0")/subissue-functions.sh"
source "$(dirname "$0")/linear-config.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKTREE_BASE_DIR="worktrees"

# Check for issue ID
if [ $# -eq 0 ]; then
    echo "Usage: $0 ISSUE_ID"
    exit 1
fi

ISSUE_ID="$1"

# Log function
log() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        "INFO")  echo -e "${BLUE}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
    esac
}

# Main workflow
main() {
    log "INFO" "Starting enhanced workflow for issue: $ISSUE_ID"
    
    # Check if LINEAR_ISSUE_DATA is provided
    if [ -z "${LINEAR_ISSUE_DATA:-}" ]; then
        log "ERROR" "LINEAR_ISSUE_DATA environment variable not set"
        log "INFO" "This script should be called by Claude with Linear data"
        exit 1
    fi
    
    # Validate JSON data
    if ! echo "$LINEAR_ISSUE_DATA" | jq . >/dev/null 2>&1; then
        log "ERROR" "Invalid JSON in LINEAR_ISSUE_DATA"
        exit 1
    fi
    
    # Extract directory name
    local worktree_dir
    worktree_dir=$(echo "$LINEAR_ISSUE_DATA" | extract_proper_directory_name)
    log "INFO" "Worktree directory: $worktree_dir"
    
    # Check if it's a subissue
    local is_subissue
    is_subissue=$(echo "$LINEAR_ISSUE_DATA" | detect_subissue)
    
    if [ "$is_subissue" = "true" ]; then
        log "INFO" "Detected subissue"
        
        # Handle parent context if available
        if [ -n "${LINEAR_PARENT_DATA:-}" ] && [ "$LINEAR_PARENT_DATA" != "" ]; then
            log "INFO" "Parent context available"
        fi
    fi
    
    # Check git repository state
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log "ERROR" "Not in a git repository"
        exit 1
    fi
    
    # Create worktree directory
    local full_path="${WORKTREE_BASE_DIR}/${worktree_dir}"
    
    if [ -d "$full_path" ]; then
        log "ERROR" "Worktree directory already exists: $full_path"
        exit 1
    fi
    
    # Create worktrees base directory if needed
    mkdir -p "$WORKTREE_BASE_DIR"
    
    # Extract git branch name
    local git_branch
    git_branch=$(echo "$LINEAR_ISSUE_DATA" | jq -r '.gitBranchName // empty')
    
    if [ -z "$git_branch" ]; then
        # Fallback to generated branch name
        local username=$(whoami)
        local issue_lower=$(echo "$ISSUE_ID" | tr '[:upper:]' '[:lower:]')
        git_branch="${username}/${issue_lower}-${worktree_dir#*-}"
    fi
    
    # Create the worktree
    log "INFO" "Creating worktree: $full_path"
    log "INFO" "Using branch: $git_branch"
    
    if ! git worktree add "$full_path" -b "$git_branch" 2>/dev/null; then
        # Try without creating new branch if it exists
        if ! git worktree add "$full_path" "$git_branch" 2>/dev/null; then
            log "ERROR" "Failed to create git worktree"
            exit 1
        fi
    fi
    
    # Create initial README with issue info
    local issue_title
    issue_title=$(echo "$LINEAR_ISSUE_DATA" | jq -r '.title // "No title"')
    
    cat > "$full_path/README.md" << EOF
# Issue: $ISSUE_ID

**Title**: $issue_title

This worktree was created for Linear issue $ISSUE_ID.
EOF
    
    # Create parent context file if this is a subissue
    if [ "$is_subissue" = "true" ] && [ -n "${LINEAR_PARENT_DATA:-}" ]; then
        if echo "$LINEAR_PARENT_DATA" | jq . >/dev/null 2>&1; then
            create_parent_context_file "$LINEAR_PARENT_DATA" "$full_path" || true
        fi
    fi
    
    # Success output
    log "SUCCESS" "Worktree created successfully!"
    echo -e "${GREEN}Workspace ready: cd $full_path${NC}"
    echo
    echo "Summary:"
    echo "  • Worktree created: $full_path"
    echo "  • Branch: $git_branch"
    echo "  • Linear status: Already updated to In Progress"
    
    # Return worktree path for Claude to use in comment
    echo "WORKTREE_PATH=$full_path"
    echo "GIT_BRANCH=$git_branch"
}

# Run main function
main "$@"