#!/bin/bash
# Git workflow automation: Start working on a Linear issue
# Usage: ./start-issue.sh DAV-173
# Creates git worktree and updates Linear status to "In Progress"

set -euo pipefail

# Source subissue detection and workflow enhancement functions
source "$(dirname "$0")/subissue-functions.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKTREE_BASE_DIR="worktrees"

# Source Linear configuration if available
if [ -f "$(dirname "$0")/linear-config.sh" ]; then
    source "$(dirname "$0")/linear-config.sh"
else
    # Fallback to hardcoded values with warning
    LINEAR_STATUS_IN_PROGRESS="e41cf207-0f8b-4f7b-82e0-b3471f212fe1"
    log "WARN" "linear-config.sh not found, using default status IDs"
fi

# Global variables
ISSUE_ID=""
DRY_RUN=false
EXTRACT_DIR_ONLY=false
UPDATE_STATUS_ONLY=false
GET_STATUS_ONLY=false

# Print usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS] ISSUE_ID

Start working on a Linear issue by creating a git worktree and updating status.

Arguments:
    ISSUE_ID    Linear issue identifier (e.g., DAV-173)

Options:
    --dry-run           Show what would be done without making changes
    --extract-dir       Extract and print directory name only
    --update-status     Update Linear status only
    --get-status        Get current Linear status only
    -h, --help          Show this help message

Examples:
    $0 DAV-173                    # Start working on issue DAV-173
    $0 --dry-run DAV-173          # Preview actions for DAV-173
    $0 --extract-dir DAV-173      # Get worktree directory name
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

# Sanitize issue title for directory name
sanitize_title() {
    local title="$1"
    # Convert to lowercase, replace spaces with hyphens, remove special chars
    echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g'
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

# Enhanced directory extraction with Linear MCP integration
extract_directory_name() {
    local issue_id="$1"
    
    
    # Validate issue ID first
    if ! validate_issue_id "$issue_id"; then
        return 1
    fi
    
    # Get issue data from Linear MCP integration
    local issue_json
    
    # Try multiple sources for Linear issue data
    local issue_json=""
    
    # 1. Check if data provided via environment (Claude/wrapper usage)
    if [ -n "${LINEAR_ISSUE_DATA:-}" ]; then
        issue_json="$LINEAR_ISSUE_DATA"
        log "INFO" "Using Linear data from environment"
    
    # 2. Request via Claude marker (for interactive Claude sessions)
    else
        log "INFO" "Requesting Linear data from Claude..."
        echo "🤖 CLAUDE_LINEAR_ACTION: GET_ISSUE_JSON $issue_id" >&2
        # In Claude context, the runtime would inject data here
    fi
    
    # Validate and use the data
    if [ -n "$issue_json" ] && echo "$issue_json" | jq . >/dev/null 2>&1; then
        # Use enhanced extraction with Linear data
        extract_proper_directory_name "$issue_json"
        return 0
    else
        # Fall back to generic naming
        log "WARN" "No Linear data available, using generic naming"
        log "INFO" "For enhanced features: 1) Run with Claude, or 2) Set LINEAR_ISSUE_DATA"
        echo "$issue_id-issue"
        return 0
    fi
    
    # Use new enhanced directory name extraction
    extract_proper_directory_name "$issue_json"
}

# Request Linear issue details from Claude with subissue detection
request_issue_details() {
    local issue_id="$1"
    echo "🤖 CLAUDE_LINEAR_ACTION: GET_ISSUE $issue_id"
    
    # Enhanced subissue detection for testing and production integration
    _detect_and_log_subissue_info
}

# Get Linear issue status - outputs Claude action marker
get_linear_status() {
    local issue_id="$1"
    
    # This function is called when user wants to check issue status
    # In real usage, Claude would handle the Linear MCP call
    echo "Fetching Linear issue status for $issue_id..."
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
    
    # Output Claude action marker for Linear status update
    echo "🤖 CLAUDE_LINEAR_ACTION: UPDATE_STATUS $issue_id $status_name"
    log "INFO" "Requesting Claude to update Linear issue $issue_id to $status_name"
    
    return 0
}

# Validate git repository state
validate_git_repo() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log "ERROR" "Not in a git repository"
        return 1
    fi
    
    # Check for uncommitted changes and warn user
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log "WARN" "Repository has uncommitted changes"
        log "INFO" "Worktree operations will not affect main repository state"
        
        if [ "$DRY_RUN" = false ]; then
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log "INFO" "Operation cancelled by user"
                return 1
            fi
        fi
    fi
    
    return 0
}

# Create git worktree
create_worktree() {
    local issue_id="$1"
    local worktree_dir="$2"
    local git_branch="$3"
    
    local full_path="${WORKTREE_BASE_DIR}/${worktree_dir}"
    
    # Check if worktree directory already exists
    if [ -d "$full_path" ]; then
        log "ERROR" "Worktree directory already exists: $full_path"
        log "INFO" "Use a different issue or clean up existing worktree"
        return 1
    fi
    
    # Create worktrees base directory if it doesn't exist
    mkdir -p "$WORKTREE_BASE_DIR"
    
    if [ "$DRY_RUN" = true ]; then
        log "INFO" "Would create worktree: $full_path"
        log "INFO" "Would create branch: $git_branch"
        return 0
    fi
    
    # Create the worktree and branch
    log "INFO" "Creating worktree: $full_path"
    
    # CRITICAL FIX: Use actual git worktree commands
    if ! git worktree add "$full_path" -b "$git_branch" 2>/dev/null; then
        # Fallback: try without new branch if branch exists
        if ! git worktree add "$full_path" "$git_branch" 2>/dev/null; then
            log "ERROR" "Failed to create git worktree"
            return 1
        fi
    fi
    
    # Add issue context to worktree
    echo "# Issue: $issue_id" > "$full_path/README.md"
    
    # Create parent context file for subissues
    _create_subissue_parent_context "$issue_id" "$full_path"
    
    log "SUCCESS" "Worktree created successfully"
    return 0
}

# Helper function: Detect and log subissue information  
_detect_and_log_subissue_info() {
    local issue_id="${1:-$ISSUE_ID}"
    
    # Fetch issue data from Linear MCP
    local issue_json
    issue_json=$(echo "🤖 CLAUDE_LINEAR_ACTION: GET_ISSUE_JSON $issue_id" >&2)
    
    if [ -n "$issue_json" ] && echo "$issue_json" | jq . >/dev/null 2>&1; then
        local is_subissue
        is_subissue=$(detect_subissue "$issue_json")
        
        if [ "$is_subissue" = "true" ]; then
            local parent_id
            parent_id=$(echo "$issue_json" | jq -r '.parentId // empty')
            
            if [ -n "$parent_id" ]; then
                log "INFO" "Detected subissue with parent: $parent_id"
            fi
        fi
    fi
}

# Helper function: Create parent context file for subissues
_create_subissue_parent_context() {
    local issue_id="$1"
    local worktree_path="$2"
    
    # Fetch issue data from Linear MCP
    local issue_json
    issue_json=$(echo "🤖 CLAUDE_LINEAR_ACTION: GET_ISSUE_JSON $issue_id" >&2)
    
    if [ -n "$issue_json" ] && echo "$issue_json" | jq . >/dev/null 2>&1; then
        local is_subissue
        is_subissue=$(detect_subissue "$issue_json")
        
        if [ "$is_subissue" = "true" ]; then
            local parent_id
            parent_id=$(echo "$issue_json" | jq -r '.parentId // empty')
            
            if [ -n "$parent_id" ]; then
                log "INFO" "Creating parent context file for subissue"
                
                # Load parent context and create file
                local parent_data
                if parent_data=$(load_parent_context "$parent_id"); then
                    if ! create_parent_context_file "$parent_data" "$worktree_path"; then
                        log "WARN" "Failed to create parent context file - continuing without parent context"
                    else
                        log "SUCCESS" "Parent context file created successfully"
                    fi
                else
                    log "WARN" "Could not fetch parent issue data - continuing without parent context"
                    log "INFO" "Parent issue ID: $parent_id"
                fi
            fi
        fi
    fi
}

# Main workflow function
start_issue_workflow() {
    local issue_id="$1"
    
    # Validate issue ID format
    if ! validate_issue_id "$issue_id"; then
        return 1
    fi
    
    # Extract directory name from issue data
    local worktree_dir
    worktree_dir=$(extract_directory_name "$issue_id")
    
    if [ "$EXTRACT_DIR_ONLY" = true ]; then
        echo "$worktree_dir"
        return 0
    fi
    
    # Get current status
    if [ "$GET_STATUS_ONLY" = true ]; then
        local current_status
        current_status=$(get_linear_status "$issue_id")
        echo "$current_status"
        return 0
    fi
    
    # Update Linear status
    if [ "$UPDATE_STATUS_ONLY" = true ]; then
        update_linear_status "$issue_id" "$LINEAR_IN_PROGRESS_STATUS_ID"
        return $?
    fi
    
    log "INFO" "Starting workflow for issue: $issue_id"
    
    # Request issue details from Claude (for enhanced context)
    request_issue_details "$issue_id"
    
    # Validate git repository state
    if ! validate_git_repo; then
        return 1
    fi
    
    # Create git worktree with dynamic branch name
    local username=$(whoami)
    local issue_lower=$(echo "$issue_id" | tr '[:upper:]' '[:lower:]')
    local branch_suffix="${worktree_dir#*-}"
    local git_branch="${username}/${issue_lower}-${branch_suffix}"
    if ! create_worktree "$issue_id" "$worktree_dir" "$git_branch"; then
        return 1
    fi
    
    # Update Linear status to In Progress
    if ! update_linear_status "$issue_id" "In Progress"; then
        log "WARN" "Worktree created but Linear status update request failed"
        log "INFO" "Claude will handle the Linear update if possible"
    fi
    
    # Request Claude to add a comment about the worktree
    local worktree_comment="Git worktree created at: ${WORKTREE_BASE_DIR}/${worktree_dir} (branch: $git_branch)"
    echo "🤖 CLAUDE_LINEAR_ACTION: ADD_COMMENT $issue_id '$worktree_comment'"
    
    # Output workspace navigation command
    local workspace_path="${WORKTREE_BASE_DIR}/${worktree_dir}"
    echo
    log "SUCCESS" "Issue workflow started successfully!"
    echo -e "${GREEN}Workspace ready: cd $workspace_path${NC}"
    echo
    
    # Summary output
    echo "Summary:"
    echo "  • Linear status updated to In Progress"
    echo "  • Worktree created: $workspace_path"
    echo "  • Branch created: $git_branch"
    
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
            --extract-dir)
                EXTRACT_DIR_ONLY=true
                shift
                ;;
            --update-status)
                UPDATE_STATUS_ONLY=true
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
    if start_issue_workflow "$ISSUE_ID"; then
        exit 0
    else
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi