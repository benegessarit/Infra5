#!/bin/bash
# Claude-Linear Integration Helper
# This script outputs commands that Claude interprets and executes via MCP

set -euo pipefail

# Function to request Linear action from Claude
request_linear_action() {
    local action="$1"
    shift
    local args="$*"
    
    # Output a special marker that Claude will recognize and act upon
    echo "🤖 CLAUDE_LINEAR_ACTION: $action $args"
}

# Function to get issue details (Claude will fetch via MCP)
get_issue_details() {
    local issue_id="$1"
    request_linear_action "GET_ISSUE" "$issue_id"
}

# Function to update issue status (Claude will update via MCP)
update_issue_status() {
    local issue_id="$1"
    local status_name="$2"
    request_linear_action "UPDATE_STATUS" "$issue_id" "$status_name"
}

# Function to create comment (Claude will create via MCP)
add_issue_comment() {
    local issue_id="$1"
    local comment="$2"
    request_linear_action "ADD_COMMENT" "$issue_id" "$comment"
}

# Example usage in start-issue workflow
start_issue_with_claude() {
    local issue_id="$1"
    
    echo "Starting Claude-integrated workflow for $issue_id..."
    
    # Request issue details from Claude
    get_issue_details "$issue_id"
    
    # Create git worktree (local operation)
    echo "Creating git worktree..."
    # ... worktree creation logic ...
    
    # Request status update from Claude
    echo "Requesting Linear status update..."
    update_issue_status "$issue_id" "In Progress"
    
    # Add a comment about the worktree
    add_issue_comment "$issue_id" "Created git worktree for development. Branch: feature/$issue_id"
    
    echo "✅ Workflow complete! Claude has handled all Linear operations."
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <issue-id>"
        echo "Example: $0 DAV-173"
        exit 1
    fi
    
    start_issue_with_claude "$1"
fi