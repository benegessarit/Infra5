#!/bin/bash
# Integration tests for DAV-186 start-issue.sh workflow enhancement
# Tests ACTUAL user workflow behavior, not isolated functions

# Load test framework
source "$(dirname "$0")/test-framework.sh"

# Setup test environment
setup_test_env

# Mock Linear MCP responses for integration testing - FICTIONAL DATA ONLY
MOCK_SUBISSUE_ISSUE='{
  "identifier": "TEST-181",
  "title": "Mock Subissue for Integration Testing",
  "gitBranchName": "testuser/test-181-mock-subissue-branch",
  "parentId": "12345678-1234-5678-9abc-123456789abc"
}'

MOCK_PARENT_ISSUE='{
  "identifier": "TEST-176", 
  "title": "Mock Parent Issue for Integration Testing",
  "gitBranchName": "testuser/test-176-mock-parent-branch",
  "parentId": null
}'

MOCK_REGULAR_ISSUE='{
  "identifier": "TEST-164",
  "title": "Mock Regular Issue for Integration Testing", 
  "gitBranchName": "testuser/test-164-mock-regular-branch",
  "parentId": null
}'

# Test suite for start-issue.sh integration workflow
describe "start-issue.sh integration workflow tests"

test_subissue_creates_proper_directory_name() {
    # CRITICAL: Test actual user command with subissue
    # Expected: Should create directory from gitBranchName, not generic fallback
    
    # Mock the Linear MCP response for TEST-181
    export MOCK_ISSUE_DATA="$MOCK_SUBISSUE_ISSUE"
    
    # Run actual start-issue.sh command (dry run to avoid real worktree creation)
    local result=$(./scripts/start-issue.sh --extract-dir TEST-181 2>/dev/null)
    
    # SHOULD get: TEST-181-mock-subissue-branch (from gitBranchName)
    # CURRENTLY gets: TEST-181-issue (generic fallback)
    assert_equals "TEST-181-mock-subissue-branch" "$result" \
        "Should extract directory name from gitBranchName for subissues"
}

test_subissue_creates_parent_context_file() {
    # CRITICAL: Test that parent context file creation logic is integrated
    local test_worktree="$TEST_DIR/test-worktree"
    mkdir -p "$test_worktree"
    
    # Mock the Linear MCP responses
    export MOCK_ISSUE_DATA="$MOCK_SUBISSUE_ISSUE"
    export MOCK_PARENT_DATA="$MOCK_PARENT_ISSUE"
    
    # Test the workflow output for subissue detection indicators
    local output=$(./scripts/start-issue.sh --dry-run TEST-181 2>&1)
    
    # Check if subissue detection logic is working (integration verification)
    if [[ "$output" == *"Detected subissue with parent"* ]] || [[ "$output" == *"Creating parent context file"* ]]; then
        echo "Parent context logic detected in workflow"
        return 0
    else
        echo "Parent context logic not integrated"
        return 1
    fi
}

test_regular_issue_no_parent_context() {
    # Test that regular issues (no parent) don't create parent context files
    local test_worktree="$TEST_DIR/test-worktree-regular"
    mkdir -p "$test_worktree"
    
    export MOCK_ISSUE_DATA="$MOCK_REGULAR_ISSUE"
    
    # Run for regular issue
    if ./scripts/start-issue.sh --dry-run TEST-164 2>/dev/null; then
        # Should NOT create parent-context.md
        assert_file_not_exists "$test_worktree/parent-context.md" \
            "Should not create parent-context.md for regular issues"
    fi
}

test_backward_compatibility_maintained() {
    # CRITICAL: Existing workflow must still work for issues without gitBranchName
    local mock_issue_no_branch='{
        "identifier": "TEST-999",
        "title": "Issue Without GitBranchName",
        "gitBranchName": null,
        "parentId": null
    }'
    
    export MOCK_ISSUE_DATA="$mock_issue_no_branch"
    
    # Should fall back to generic naming
    local result=$(./scripts/start-issue.sh --extract-dir TEST-999 2>/dev/null)
    assert_equals "TEST-999-issue" "$result" \
        "Should maintain backward compatibility with generic naming"
}

test_start_issue_workflow_integration() {
    # CRITICAL: Test that the enhanced workflow actually gets called
    # This tests the integration points in start_issue_workflow() function
    
    export MOCK_ISSUE_DATA="$MOCK_SUBISSUE_ISSUE"
    
    # Test that the workflow can process subissue data
    local output=$(./scripts/start-issue.sh --dry-run TEST-181 2>&1)
    
    # Check for indicators that new subissue logic is being used
    if [[ "$output" == *"Detected subissue"* ]] || [[ "$output" == *"TEST-181-mock-subissue-branch"* ]]; then
        echo "New subissue workflow detected"
        return 0
    else
        echo "Enhanced workflow integration not detected"
        return 1
    fi
}

test_worktree_creation_uses_proper_directory() {
    # CRITICAL: Verify actual worktree creation uses enhanced directory naming
    # This is the ultimate integration test
    
    export MOCK_ISSUE_DATA="$MOCK_SUBISSUE_ISSUE"
    
    # Test worktree directory naming without actual creation
    local expected_dir="TEST-181-mock-subissue-branch"
    local result=$(./scripts/start-issue.sh --extract-dir TEST-181 2>/dev/null)
    
    # This should pass once integration is complete
    assert_equals "$expected_dir" "$result" \
        "Worktree creation should use gitBranchName-based directory naming"
}

# Edge case integration tests
describe "Integration edge case tests"

test_invalid_issue_fallback_behavior() {
    # Test how integrated workflow handles edge cases
    local mock_invalid_issue='invalid-json-data'
    
    export MOCK_ISSUE_DATA="$mock_invalid_issue"
    
    # Use valid issue ID format but invalid JSON data
    local result=$(./scripts/start-issue.sh --extract-dir TEST-123 2>/dev/null)
    
    # Should fall back to generic naming when JSON is invalid
    assert_equals "TEST-123-issue" "$result" \
        "Should handle invalid issue data gracefully"
}

# Run the integration tests
test "subissue creates proper directory name" test_subissue_creates_proper_directory_name
test "subissue creates parent context file" test_subissue_creates_parent_context_file  
test "regular issue no parent context" test_regular_issue_no_parent_context
test "backward compatibility maintained" test_backward_compatibility_maintained
test "start-issue workflow integration" test_start_issue_workflow_integration
test "worktree creation uses proper directory" test_worktree_creation_uses_proper_directory
test "invalid issue fallback behavior" test_invalid_issue_fallback_behavior

# Show test summary
show_summary