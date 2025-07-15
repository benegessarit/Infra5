#!/bin/bash
# Subissue detection and workflow enhancement functions for DAV-186
# Created: 2025-07-14 04:13:43
# Implements: detect_subissue, extract_proper_directory_name, load_parent_context, create_parent_context_file

# Set strict error handling
set -euo pipefail

# Constants
readonly MAX_DIRECTORY_LENGTH=100
readonly UUID_PATTERN='^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

# Helper function: Get JSON input from stdin or argument
_get_json_input() {
    if [ -p /dev/stdin ]; then
        cat
    else
        echo "$1"
    fi
}

# Function 1: Detect if issue has a parent (is a subissue)
# Input: JSON from Linear MCP (via stdin or argument)
# Output: "true" if subissue, "false" if not
detect_subissue() {
    local issue_json
    issue_json=$(_get_json_input "$@")
    
    # Use jq to safely extract parentId, handle null/undefined
    local parent_id
    parent_id=$(echo "$issue_json" | jq -r '.parentId // empty')
    
    # Return "true" if parentId exists and is not empty, "false" otherwise
    [ -n "$parent_id" ] && echo "true" || echo "false"
}

# Function 2: Extract proper directory name from gitBranchName
# Input: JSON from Linear MCP (via stdin or argument)  
# Output: Proper directory name for worktree
extract_proper_directory_name() {
    local issue_json
    issue_json=$(_get_json_input "$@")
    
    # Extract gitBranchName and identifier safely
    local git_branch_name issue_id
    git_branch_name=$(echo "$issue_json" | jq -r '.gitBranchName // empty')
    issue_id=$(echo "$issue_json" | jq -r '.identifier // empty')
    
    if [ -n "$git_branch_name" ]; then
        _extract_directory_from_branch "$git_branch_name"
    else
        # Fallback to generic naming for backward compatibility
        echo "${issue_id}-issue"
    fi
}

# Helper function: Extract directory name from git branch
_extract_directory_from_branch() {
    local git_branch_name="$1"
    
    # Extract the part after the last slash: "testuser/test-181-feature" → "test-181-feature"
    local directory_name="${git_branch_name##*/}"
    
    # Convert to uppercase format: "test-181-feature" → "TEST-181-feature"
    directory_name=$(echo "$directory_name" | sed 's/^test-/TEST-/')
    
    # Truncate if too long for filesystem compatibility
    if [ ${#directory_name} -gt "$MAX_DIRECTORY_LENGTH" ]; then
        echo "Warning: Directory name truncated for filesystem compatibility" >&2
        directory_name="${directory_name:0:$((MAX_DIRECTORY_LENGTH - 3))}..."
    fi
    
    echo "$directory_name"
}

# Function 3: Load parent context from Linear MCP
# Input: parent UUID
# Output: JSON parent data or error message
load_parent_context() {
    local parent_id="$1"
    
    # Validate parent ID format using constant
    if [[ ! "$parent_id" =~ $UUID_PATTERN ]]; then
        echo "Error: Invalid parent ID format" >&2
        return 1
    fi
    
    # Use Linear MCP to fetch parent issue data by UUID
    # Note: Future optimization opportunity - cache parent data to avoid repeated API calls
    echo "Fetching parent issue data..." >&2
    local parent_json
    parent_json=$(echo "🤖 CLAUDE_LINEAR_ACTION: GET_ISSUE_BY_ID $parent_id" >&2)
    
    # Validate response
    if [ -z "$parent_json" ] || ! echo "$parent_json" | jq . >/dev/null 2>&1; then
        echo "Error: Failed to fetch parent issue data from Linear" >&2
        echo "Error: Ensure Linear MCP is configured in Claude" >&2
        return 1
    fi
    
    echo "$parent_json"
}


# Helper function: Get parent ID from issue JSON
# Input: JSON from Linear MCP
# Output: Parent ID if exists, empty otherwise
get_parent_id() {
    local issue_json
    issue_json=$(_get_json_input "$@")
    
    # Extract parentId safely
    echo "$issue_json" | jq -r '.parentId // empty'
}

# Function 4: Create parent context file in worktree
# Input: parent JSON data, worktree path
# Output: Creates parent-context.md file
create_parent_context_file() {
    local parent_data="$1"
    local worktree_path="$2"
    
    # Validate inputs
    _validate_parent_context_inputs "$parent_data" "$worktree_path"
    
    # Extract parent information safely
    local parent_id parent_title parent_url
    parent_id=$(echo "$parent_data" | jq -r '.identifier // "Unknown"')
    parent_title=$(echo "$parent_data" | jq -r '.title // "No title"')
    parent_url=$(echo "$parent_data" | jq -r '.url // ""')
    
    # Create parent context file
    _write_parent_context_file "$worktree_path" "$parent_id" "$parent_title" "$parent_url"
    
    echo "Parent context file created successfully at: $worktree_path/parent-context.md"
}

# Helper function: Validate parent context file inputs
_validate_parent_context_inputs() {
    local parent_data="$1"
    local worktree_path="$2"
    
    if [ -z "$parent_data" ] || [ -z "$worktree_path" ]; then
        echo "Error: Missing parent data or worktree path" >&2
        return 1
    fi
}

# Helper function: Write parent context markdown file
_write_parent_context_file() {
    local worktree_path="$1"
    local parent_id="$2"
    local parent_title="$3"
    local parent_url="$4"
    
    # Create parent context file content
    cat > "$worktree_path/parent-context.md" << EOF
# Parent Issue Context

**Issue**: $parent_id  
**Title**: $parent_title

## Parent Information

This is a subissue of the parent issue above. The parent provides the broader context for this work.

EOF
    
    # Add URL if available
    if [ -n "$parent_url" ]; then
        echo "**Linear URL**: $parent_url" >> "$worktree_path/parent-context.md"
        echo >> "$worktree_path/parent-context.md"
    fi
}