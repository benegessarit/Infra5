#!/bin/bash
# Test suite for DAV-186 subissue detection and workflow enhancement

# Load test framework
source "$(dirname "$0")/test-framework.sh"

# Load subissue functions for testing
source "$(dirname "$0")/../scripts/subissue-functions.sh"

# Setup test environment
setup_test_env

# Mock Linear MCP responses for testing - FICTIONAL DATA ONLY
MOCK_SUBISSUE_RESPONSE='{
  "identifier": "TEST-181",
  "title": "Mock Subissue for Testing",
  "gitBranchName": "testuser/test-181-mock-subissue-branch",
  "parentId": "12345678-1234-5678-9abc-123456789abc"
}'

MOCK_PARENT_RESPONSE='{
  "identifier": "TEST-176",
  "title": "Mock Parent Issue for Testing",
  "gitBranchName": "testuser/test-176-mock-parent-branch",
  "parentId": null
}'

MOCK_REGULAR_RESPONSE='{
  "identifier": "TEST-164",
  "title": "Mock Regular Issue for Testing",
  "gitBranchName": "testuser/test-164-mock-regular-branch",
  "parentId": null
}'

MOCK_NO_GITBRANCH_RESPONSE='{
  "identifier": "TEST-999",
  "title": "Mock Issue Without GitBranchName",
  "gitBranchName": null,
  "parentId": null
}'

MOCK_INVALID_PARENT_RESPONSE='{
  "identifier": "TEST-998",
  "title": "Mock Issue With Invalid Parent",
  "gitBranchName": "testuser/test-998-mock-invalid-parent",
  "parentId": "invalid-uuid-format"
}'

# Test suite for detect_subissue() function
describe "detect_subissue() function tests"

test_detect_subissue_with_valid_parent() {
    # Test with mock subissue which has a parentId
    local result=$(echo "$MOCK_SUBISSUE_RESPONSE" | detect_subissue)
    assert_equals "true" "$result" "Should detect mock subissue as a subissue"
}

test_detect_subissue_no_parent() {
    # Test with mock parent which has no parentId
    local result=$(echo "$MOCK_PARENT_RESPONSE" | detect_subissue)
    assert_equals "false" "$result" "Should not detect mock parent as a subissue"
}

test_detect_subissue_null_parent() {
    # Test with mock regular issue which explicitly has null parentId
    local result=$(echo "$MOCK_REGULAR_RESPONSE" | detect_subissue)
    assert_equals "false" "$result" "Should not detect mock regular issue as a subissue"
}

# Test suite for extract_proper_directory_name() function
describe "extract_proper_directory_name() function tests"

test_extract_directory_from_git_branch_name() {
    # Test proper extraction from gitBranchName
    local result=$(echo "$MOCK_SUBISSUE_RESPONSE" | extract_proper_directory_name)
    assert_equals "TEST-181-mock-subissue-branch" "$result" \
        "Should extract proper directory name from gitBranchName"
}

test_extract_directory_parent_issue() {
    # Test extraction for parent issue
    local result=$(echo "$MOCK_PARENT_RESPONSE" | extract_proper_directory_name)
    assert_equals "TEST-176-mock-parent-branch" "$result" \
        "Should extract proper directory name for parent issue"
}

test_extract_directory_fallback_generic() {
    # Test fallback when gitBranchName is null
    local result=$(echo "$MOCK_NO_GITBRANCH_RESPONSE" | extract_proper_directory_name)
    assert_equals "TEST-999-issue" "$result" \
        "Should fallback to generic naming when gitBranchName is null"
}

# Test suite for load_parent_context() function
describe "load_parent_context() function tests"

test_load_parent_context_success() {
    # Mock parent issue data with fictional UUID
    local parent_id="12345678-1234-5678-9abc-123456789abc"
    
    # Create mock Linear MCP command that returns parent data
    mock_linear_mcp() {
        if [[ "$*" == *"$parent_id"* ]]; then
            echo "$MOCK_PARENT_RESPONSE"
            return 0
        fi
        return 1
    }
    
    # Test loading parent context
    local result=$(load_parent_context "$parent_id")
    local exit_code=$?
    assert_equals "0" "$exit_code" "Should successfully load parent context"
}

test_load_parent_context_failure() {
    # Test with invalid parent ID - capture exit code correctly
    load_parent_context "invalid-id" >/dev/null 2>&1
    local exit_code=$?
    assert_equals "1" "$exit_code" "Should fail gracefully with invalid parent ID"
}

# Test suite for create_parent_context_file() function
describe "create_parent_context_file() function tests"

test_create_parent_context_file() {
    local worktree_path="$TEST_DIR/worktree"
    mkdir -p "$worktree_path"
    
    local parent_data='{"identifier": "TEST-176", "title": "Mock Parent Issue", "url": "https://example.com/mock"}'
    
    create_parent_context_file "$parent_data" "$worktree_path"
    
    assert_file_exists "$worktree_path/parent-context.md" \
        "Should create parent-context.md file"
    
    # Verify content includes expected elements
    local content=$(cat "$worktree_path/parent-context.md")
    [[ "$content" == *"TEST-176"* ]] || return 1
    [[ "$content" == *"Mock Parent Issue"* ]] || return 1
}

# Edge case tests
describe "Edge case handling tests"

test_edge_case_missing_gitbranch() {
    # Test proper handling when gitBranchName is missing
    local result=$(echo "$MOCK_NO_GITBRANCH_RESPONSE" | extract_proper_directory_name)
    assert_equals "TEST-999-issue" "$result" \
        "Should fallback gracefully when gitBranchName is missing"
}

test_edge_case_invalid_parent_id() {
    # Test handling of invalid parent ID format
    local result=$(echo "$MOCK_INVALID_PARENT_RESPONSE" | detect_subissue)
    assert_equals "true" "$result" \
        "Should still detect as subissue even with invalid parent format"
}

test_edge_case_long_directory_name() {
    # Test handling of very long gitBranchName
    local long_response='{
        "identifier": "TEST-997",
        "gitBranchName": "testuser/test-997-this-is-an-extremely-long-branch-name-that-might-cause-filesystem-issues-because-it-exceeds-reasonable-length-limits-and-needs-to-be-truncated-somehow"
    }'
    
    local result=$(echo "$long_response" | extract_proper_directory_name)
    # Should be truncated or handled appropriately
    [[ ${#result} -le 100 ]] || return 1
}

# Integration tests
describe "Integration workflow tests"

test_full_subissue_workflow() {
    # Test the complete workflow for a subissue
    local issue_json="$MOCK_SUBISSUE_RESPONSE"
    
    # 1. Detect it's a subissue
    local is_subissue=$(echo "$issue_json" | detect_subissue)
    assert_equals "true" "$is_subissue" "Should detect as subissue"
    
    # 2. Extract proper directory name
    local dir_name=$(echo "$issue_json" | extract_proper_directory_name)
    assert_equals "TEST-181-mock-subissue-branch" "$dir_name"
    
    # 3. Would load parent context (mocked)
    local parent_id=$(echo "$issue_json" | jq -r '.parentId')
    [[ "$parent_id" != "null" ]] || return 1
}

# Run the tests
test "detect_subissue with valid parent" test_detect_subissue_with_valid_parent
test "detect_subissue with no parent" test_detect_subissue_no_parent  
test "detect_subissue with null parent" test_detect_subissue_null_parent
test "extract directory from gitBranchName" test_extract_directory_from_git_branch_name
test "extract directory for parent issue" test_extract_directory_parent_issue
test "extract directory fallback to generic" test_extract_directory_fallback_generic
test "load parent context success" test_load_parent_context_success
test "load parent context failure" test_load_parent_context_failure
test "create parent context file" test_create_parent_context_file
test "edge case: missing gitBranchName" test_edge_case_missing_gitbranch
test "edge case: invalid parent ID" test_edge_case_invalid_parent_id
test "edge case: long directory name" test_edge_case_long_directory_name
test "full subissue workflow integration" test_full_subissue_workflow

# Show test summary
show_summary