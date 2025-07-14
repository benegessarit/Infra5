#!/bin/bash
# Production validation tests for DAV-186 implementation
# These tests validate the actual production behavior without mock data

# Load test framework
source "$(dirname "$0")/test-framework.sh"

# Setup test environment
setup_test_env

# Test suite for production validation
describe "Production validation tests"

test_no_mock_environment_variables() {
    # Ensure production code doesn't use MOCK_ISSUE_DATA
    local script_content
    script_content=$(cat ./scripts/start-issue.sh)
    
    if [[ "$script_content" == *"MOCK_ISSUE_DATA"* ]]; then
        echo "FAIL: Production code contains MOCK_ISSUE_DATA references"
        return 1
    fi
    
    if [[ "$script_content" == *"MOCK_ISSUE_STATUS"* ]]; then
        echo "FAIL: Production code contains MOCK_ISSUE_STATUS references"
        return 1
    fi
    
    echo "PASS: No mock environment variables in production code"
    return 0
}

test_no_hardcoded_issue_ids() {
    # Ensure production code doesn't have hardcoded DAV-xxx issue IDs
    local script_content
    script_content=$(cat ./scripts/start-issue.sh)
    
    # Check for specific hardcoded patterns
    if [[ "$script_content" == *'"DAV-173"'* ]] || [[ "$script_content" == *'"DAV-176"'* ]]; then
        echo "FAIL: Production code contains hardcoded issue IDs"
        return 1
    fi
    
    echo "PASS: No hardcoded issue IDs in production code"
    return 0
}

test_no_todo_comments() {
    # Ensure production code doesn't have TODO comments
    local todo_count
    todo_count=$(grep -c "TODO:" ./scripts/subissue-functions.sh 2>/dev/null || echo "0")
    
    if [ "$todo_count" -gt 0 ]; then
        echo "FAIL: Production code contains $todo_count TODO comment(s)"
        return 1
    fi
    
    echo "PASS: No TODO comments in production code"
    return 0
}

test_linear_mcp_integration_markers() {
    # Verify that Linear MCP integration uses proper Claude action markers
    local script_content
    script_content=$(cat ./scripts/start-issue.sh)
    
    # Check for Claude Linear action markers
    if [[ "$script_content" != *"CLAUDE_LINEAR_ACTION"* ]]; then
        echo "FAIL: No Linear MCP integration markers found"
        return 1
    fi
    
    # Check specific integration points
    local markers_found=0
    [[ "$script_content" == *"CLAUDE_LINEAR_ACTION: GET_ISSUE_JSON"* ]] && ((markers_found++))
    [[ "$script_content" == *"CLAUDE_LINEAR_ACTION: UPDATE_STATUS"* ]] && ((markers_found++))
    [[ "$script_content" == *"CLAUDE_LINEAR_ACTION: ADD_COMMENT"* ]] && ((markers_found++))
    
    if [ "$markers_found" -lt 3 ]; then
        echo "FAIL: Missing Linear MCP integration markers (found $markers_found/3)"
        return 1
    fi
    
    echo "PASS: All Linear MCP integration markers present"
    return 0
}

test_error_handling_user_feedback() {
    # Verify proper error handling with user feedback
    local functions_content
    functions_content=$(cat ./scripts/subissue-functions.sh)
    
    # Check for user-friendly error messages
    if [[ "$functions_content" != *"Ensure Linear MCP is configured"* ]]; then
        echo "FAIL: Missing user guidance for Linear MCP configuration"
        return 1
    fi
    
    # Check for proper error propagation
    if [[ "$functions_content" != *"return 1"* ]]; then
        echo "FAIL: Missing proper error return codes"
        return 1
    fi
    
    echo "PASS: Proper error handling with user feedback"
    return 0
}

test_no_silent_error_suppression() {
    # Ensure errors aren't silently suppressed with 2>/dev/null || true
    local script_content
    script_content=$(cat ./scripts/start-issue.sh)
    
    # Look for problematic patterns in critical functions
    if grep -q "load_parent_context.*2>/dev/null.*||.*true" <<< "$script_content"; then
        echo "FAIL: Silent error suppression found in load_parent_context"
        return 1
    fi
    
    echo "PASS: No silent error suppression in critical paths"
    return 0
}

test_production_ready_functions() {
    # Verify all functions are production-ready
    source ./scripts/subissue-functions.sh
    
    # Test that functions exist and are callable
    if ! type detect_subissue >/dev/null 2>&1; then
        echo "FAIL: detect_subissue function not found"
        return 1
    fi
    
    if ! type extract_proper_directory_name >/dev/null 2>&1; then
        echo "FAIL: extract_proper_directory_name function not found"
        return 1
    fi
    
    if ! type load_parent_context >/dev/null 2>&1; then
        echo "FAIL: load_parent_context function not found"
        return 1
    fi
    
    if ! type create_parent_context_file >/dev/null 2>&1; then
        echo "FAIL: create_parent_context_file function not found"
        return 1
    fi
    
    echo "PASS: All required functions are production-ready"
    return 0
}

test_script_execution_safety() {
    # Verify scripts have proper error handling setup
    local start_script
    start_script=$(head -n 20 ./scripts/start-issue.sh)
    
    if [[ "$start_script" != *"set -euo pipefail"* ]]; then
        echo "FAIL: Missing strict error handling in start-issue.sh"
        return 1
    fi
    
    local functions_script
    functions_script=$(head -n 20 ./scripts/subissue-functions.sh)
    
    if [[ "$functions_script" != *"set -euo pipefail"* ]]; then
        echo "FAIL: Missing strict error handling in subissue-functions.sh"
        return 1
    fi
    
    echo "PASS: Scripts have proper error handling setup"
    return 0
}

test_security_no_injection_paths() {
    # Verify no injection vulnerabilities through environment variables
    local script_content
    script_content=$(cat ./scripts/start-issue.sh ./scripts/subissue-functions.sh)
    
    # Check for dangerous eval patterns
    if [[ "$script_content" == *"eval"* ]]; then
        echo "FAIL: Dangerous eval usage found"
        return 1
    fi
    
    # Check for unvalidated variable expansion (excluding color variables and safe expansions)
    local unsafe_vars
    unsafe_vars=$(grep -E '\$\{[A-Z_]+\}[^:-]' <<< "$script_content" | 
                  grep -v "BASH_SOURCE" | 
                  grep -v "\${RED}" | 
                  grep -v "\${GREEN}" | 
                  grep -v "\${YELLOW}" | 
                  grep -v "\${BLUE}" | 
                  grep -v "\${NC}" | 
                  grep -v "\${WORKTREE_BASE_DIR}")
    
    if [ -n "$unsafe_vars" ]; then
        echo "FAIL: Unvalidated environment variable expansion found:"
        echo "$unsafe_vars"
        return 1
    fi
    
    echo "PASS: No obvious injection vulnerabilities"
    return 0
}

# Run the production validation tests
test "no mock environment variables" test_no_mock_environment_variables
test "no hardcoded issue IDs" test_no_hardcoded_issue_ids
test "no TODO comments" test_no_todo_comments
test "Linear MCP integration markers" test_linear_mcp_integration_markers
test "error handling user feedback" test_error_handling_user_feedback
test "no silent error suppression" test_no_silent_error_suppression
test "production ready functions" test_production_ready_functions
test "script execution safety" test_script_execution_safety
test "security no injection paths" test_security_no_injection_paths

# Show test summary
show_summary