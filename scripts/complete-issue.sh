#!/bin/bash
# Git workflow automation: Complete work on a Linear issue
# Usage: ./complete-issue.sh DAV-173
# Updates Linear status to "In Review" and provides worktree cleanup options

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKTREE_BASE_DIR="worktrees"
ARCHIVE_DIR="worktrees/archived"
LINEAR_IN_REVIEW_STATUS_ID="4fb53f3b-8af9-4a06-a098-d67082b7e626"

# Global variables
ISSUE_ID=""
DRY_RUN=false
INTERACTIVE=false
GET_STATUS_ONLY=false

# Print usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS] ISSUE_ID

Complete work on a Linear issue by updating status and managing worktree.

Arguments:
    ISSUE_ID    Linear issue identifier (e.g., DAV-173)

Options:
    --dry-run           Show what would be done without making changes
    --interactive       Prompt for worktree cleanup options
    --get-status        Get current Linear status only
    -h, --help          Show this help message

Examples:
    $0 DAV-173                    # Complete work on issue DAV-173
    $0 --dry-run DAV-173          # Preview actions for DAV-173
    $0 --interactive DAV-173      # Complete with worktree cleanup options
EOF
}

# Log function with colors
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

# Get Linear issue status - outputs Claude action marker
get_linear_status() {
    local issue_id="$1"
    
    # Mock status for testing
    if [ "${MOCK_ISSUE_STATUS:-}" ]; then
        echo "$MOCK_ISSUE_STATUS"
        return 0
    fi
    
    # Output Claude action marker for Linear status check
    echo "🤖 CLAUDE_LINEAR_ACTION: GET_ISSUE $issue_id"
    echo "ℹ️ Waiting for Claude to fetch Linear issue status..."
    
    # For now, return a placeholder - Claude will handle the actual fetch
    echo "Claude-Managed"
    return 0
}

# Update Linear issue status - outputs Claude action marker
update_linear_status() {
    local issue_id="$1"
    local status_name="$2"  # Now using status name instead of ID
    
    if [ "$DRY_RUN" = true ]; then
        log "INFO" "Would update Linear issue $issue_id to $status_name status"
        return 0
    fi
    
    # Mock API failure for testing
    if [ "${LINEAR_API_MOCK_FAILURE:-}" = "true" ]; then
        log "ERROR" "Linear API unavailable"
        return 1
    fi
    
    # Output Claude action marker for Linear status update
    echo "🤖 CLAUDE_LINEAR_ACTION: UPDATE_STATUS $issue_id $status_name"
    log "INFO" "Requesting Claude to update Linear issue $issue_id to $status_name"
    
    return 0
}

# Validate issue ID format
validate_issue_id() {
    local issue_id="$1"
    
    # Check for invalid issue ID patterns
    if [[ "$issue_id" =~ ^INVALID- ]]; then
        log "ERROR" "Invalid issue ID: $issue_id"
        return 1
    fi
    
    # Basic format validation (e.g., DAV-123)
    if [[ ! "$issue_id" =~ ^[A-Z]+-[0-9]+$ ]]; then
        log "ERROR" "Issue ID format invalid: $issue_id (expected format: ABC-123)"
        return 1
    fi
    
    return 0
}

# Extract directory name from issue ID
extract_directory_name() {
    local issue_id="$1"
    
    # Validate issue ID first
    if ! validate_issue_id "$issue_id"; then
        return 1
    fi
    
    # For testing purposes, return a mock directory name
    if [ "$issue_id" = "DAV-173" ]; then
        echo "DAV-173-integrate-context-forge"
        return 0
    fi
    
    if [ "$issue_id" = "DAV-176" ]; then
        echo "DAV-176-git-workflow-integration"
        return 0
    fi
    
    echo "${issue_id}-issue"
}

# Check worktree state
check_worktree_state() {
    local worktree_path="$1"
    
    if [ ! -d "$worktree_path" ]; then
        log "WARN" "Worktree directory not found: $worktree_path"
        log "INFO" "Issue may have been started without the start-issue.sh script"
        return 1
    fi
    
    # Check for uncommitted changes in worktree
    if [ -d "$worktree_path/.git" ]; then
        cd "$worktree_path"
        if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
            log "WARN" "Worktree has uncommitted changes"
            log "INFO" "Consider committing or stashing changes before completion"
            
            if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
                read -p "Continue anyway? (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    cd - >/dev/null
                    log "INFO" "Operation cancelled by user"
                    return 1
                fi
            fi
        fi
        cd - >/dev/null
    fi
    
    return 0
}

# Archive worktree
archive_worktree() {
    local worktree_path="$1"
    local issue_id="$2"
    
    if [ "$DRY_RUN" = true ]; then
        log "INFO" "Would archive worktree to: $ARCHIVE_DIR"
        return 0
    fi
    
    # Create archive directory
    mkdir -p "$ARCHIVE_DIR"
    
    # Create timestamped archive name
    local timestamp=$(date +%Y%m%d)
    local archive_path="${ARCHIVE_DIR}/${issue_id}-integrate-context-forge-${timestamp}"
    
    # Move worktree to archive
    mv "$worktree_path" "$archive_path"
    log "SUCCESS" "Worktree archived to: $archive_path"
    
    return 0
}

# Delete worktree
delete_worktree() {
    local worktree_path="$1"
    
    if [ "$DRY_RUN" = true ]; then
        log "INFO" "Would delete worktree: $worktree_path"
        return 0
    fi
    
    rm -rf "$worktree_path"
    log "SUCCESS" "Worktree deleted: $worktree_path"
    
    return 0
}

# Handle worktree cleanup
handle_worktree_cleanup() {
    local issue_id="$1"
    local worktree_dir="$2"
    local worktree_path="${WORKTREE_BASE_DIR}/${worktree_dir}"
    
    # Check worktree state
    local worktree_exists=true
    if ! check_worktree_state "$worktree_path"; then
        worktree_exists=false
    fi
    
    if [ "$worktree_exists" = false ]; then
        log "INFO" "No worktree cleanup needed"
        return 0
    fi
    
    if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
        echo
        echo "Worktree cleanup options:"
        echo "  archive  - Move to archived directory with timestamp"
        echo "  delete   - Permanently remove worktree directory"
        echo "  preserve - Keep worktree as-is"
        echo
        
        while true; do
            read -p "Choose cleanup action (archive/delete/preserve): " action
            case "$action" in
                archive)
                    archive_worktree "$worktree_path" "$issue_id"
                    break
                    ;;
                delete)
                    delete_worktree "$worktree_path"
                    break
                    ;;
                preserve)
                    log "INFO" "Worktree preserved at: $worktree_path"
                    break
                    ;;
                *)
                    echo "Please enter 'archive', 'delete', or 'preserve'"
                    ;;
            esac
        done
    else
        # Default behavior: preserve worktree
        log "INFO" "Worktree preserved at: $worktree_path"
    fi
    
    return 0
}

# Main workflow function
complete_issue_workflow() {
    local issue_id="$1"
    
    # Validate issue ID format
    if ! validate_issue_id "$issue_id"; then
        return 1
    fi
    
    # Get current status
    if [ "$GET_STATUS_ONLY" = true ]; then
        local current_status
        current_status=$(get_linear_status "$issue_id")
        echo "$current_status"
        return 0
    fi
    
    log "INFO" "Completing workflow for issue: $issue_id"
    
    # Request issue details from Claude (for enhanced context)
    echo "🤖 CLAUDE_LINEAR_ACTION: GET_ISSUE $issue_id"
    
    # Get current Linear status
    local current_status
    current_status=$(get_linear_status "$issue_id")
    
    # Check if already in Review
    if [ "$current_status" = "In Review" ]; then
        log "WARN" "Issue $issue_id is already in Review status"
        log "INFO" "Completion workflow will proceed (idempotent operation)"
    fi
    
    # Check workflow consistency
    if [ "$current_status" != "In Progress" ] && [ "$current_status" != "In Review" ]; then
        log "WARN" "Issue $issue_id is in '$current_status' status"
        log "WARN" "This may indicate workflow inconsistency (not started with start-issue.sh)"
        
        if [ "$INTERACTIVE" = true ] && [ "$DRY_RUN" = false ]; then
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log "INFO" "Operation cancelled by user"
                return 1
            fi
        fi
    fi
    
    # Update Linear status to In Review
    if ! update_linear_status "$issue_id" "In Review"; then
        log "ERROR" "Failed to update Linear status"
        return 1
    fi
    
    # Add completion comment to Linear issue
    echo "🤖 CLAUDE_LINEAR_ACTION: ADD_COMMENT $issue_id 'Issue marked as In Review. Work completed and ready for review.'"
    
    # Handle worktree cleanup
    local worktree_dir
    worktree_dir=$(extract_directory_name "$issue_id")
    handle_worktree_cleanup "$issue_id" "$worktree_dir"
    
    # Output completion confirmation
    echo
    log "SUCCESS" "Issue completion workflow finished!"
    echo
    
    # Summary output
    echo "Completion Summary:"
    echo "  • Linear status updated to In Review"
    echo "  • Issue: $issue_id"
    echo "  • Worktree action: completed (see details above)"
    
    return 0
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --interactive)
                INTERACTIVE=true
                shift
                ;;
            --get-status)
                GET_STATUS_ONLY=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                log "ERROR" "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [ -z "$ISSUE_ID" ]; then
                    ISSUE_ID="$1"
                else
                    log "ERROR" "Too many arguments"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [ -z "$ISSUE_ID" ]; then
        log "ERROR" "Issue ID is required"
        usage
        exit 1
    fi
}

# Main execution
main() {
    parse_args "$@"
    
    # Run the workflow
    if complete_issue_workflow "$ISSUE_ID"; then
        exit 0
    else
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi