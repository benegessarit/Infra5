#!/bin/bash
# Tests for start-issue.sh script

source "$(dirname "$0")/test-framework.sh"

# Mock Linear MCP responses
setup_linear_mocks() {
    mkdir -p "$TEST_DIR/mocks"
    
    # Mock successful issue response
    cat > "$TEST_DIR/mocks/dav-173-response.json" << 'EOF'
{
  "id": "dav-173",
  "title": "Integrate Context Forge with Claude Code",
  "gitBranchName": "dbeyer7/dav-173-integrate-context-forge-with-claude-code",
  "status": {
    "id": "a352fb76-a25c-4cc1-808a-420bc20726a2",
    "name": "Backlog"
  }
}
EOF

    # Mock Linear status update success
    cat > "$TEST_DIR/mocks/status-update-success.json" << 'EOF'
{
  "success": true,
  "status": {
    "id": "e41cf207-0f8b-4f7b-82e0-b3471f212fe1", 
    "name": "In Progress"
  }
}
EOF
}

# Mock the start-issue.sh script (it doesn't exist yet - this should fail)
test_start_issue_script_exists() {
    # Change to project root to find scripts
    cd "$(dirname "$0")/.."
    assert_file_exists "scripts/start-issue.sh" "start-issue.sh script should exist"
}

test_linear_issue_fetching() {
    # Change to project root to find scripts
    cd "$(dirname "$0")/.."
    assert_success "scripts/start-issue.sh --dry-run DAV-173" "Should fetch Linear issue successfully"
}

test_git_branch_name_extraction() {
    # Mock issue data processing test - should fail since script doesn't exist
    setup_linear_mocks
    local expected_dir="DAV-173-integrate-context-forge"
    
    # This should fail because script doesn't exist
    local actual_dir=$(scripts/start-issue.sh --dry-run --extract-dir DAV-173 2>/dev/null || echo "SCRIPT_NOT_FOUND")
    assert_equals "$expected_dir" "$actual_dir" "Should extract sanitized directory name from gitBranchName"
}

test_linear_status_update() {
    # Test Linear status update to In Progress - should fail
    setup_linear_mocks
    assert_success "scripts/start-issue.sh --dry-run --update-status DAV-173" "Should update Linear status to In Progress"
}

test_worktree_creation() {
    # Test git worktree creation - should fail since script doesn't exist
    setup_test_env
    cd "$TEST_REPO"
    
    # Create a mock script that would create worktree
    assert_success "../../scripts/start-issue.sh --dry-run DAV-173" "Should create git worktree successfully"
    assert_dir_exists "worktrees/DAV-173-integrate-context-forge" "Worktree directory should be created"
}

test_existing_worktree_handling() {
    # Test handling of existing worktree directory - should fail
    setup_test_env
    cd "$TEST_REPO"
    mkdir -p "worktrees/DAV-173-integrate-context-forge"
    
    # Should detect existing directory and handle gracefully
    assert_failure "../../scripts/start-issue.sh DAV-173" "Should fail when worktree directory already exists"
}

test_branch_creation_from_linear() {
    # Test git branch creation using Linear gitBranchName - should fail
    setup_test_env
    cd "$TEST_REPO"
    
    assert_success "../../scripts/start-issue.sh --dry-run DAV-173" "Should create branch from Linear gitBranchName"
    # Check that branch would be created correctly
    local expected_branch="dbeyer7/dav-173-integrate-context-forge-with-claude-code"
    # This will fail since script doesn't exist
    git show-ref --verify --quiet "refs/heads/$expected_branch"
    assert_equals 0 $? "Branch should be created with correct name from Linear"
}

test_repository_state_preservation() {
    # Test that main repository state is preserved - should fail
    setup_test_env
    cd "$TEST_REPO"
    
    # Create uncommitted changes
    echo "uncommitted changes" > test-file.txt
    git add test-file.txt
    
    # Run script (will fail since it doesn't exist)
    scripts/start-issue.sh --dry-run DAV-173 &>/dev/null || true
    
    # Check that changes are still there
    assert_success "git diff --cached --quiet test-file.txt" "Staged changes should be preserved"
}

test_workspace_path_output() {
    # Test that script outputs correct workspace path - should fail
    setup_test_env
    cd "$TEST_REPO"
    
    local expected_output="Workspace ready: cd worktrees/DAV-173-integrate-context-forge/"
    local actual_output=$(../../scripts/start-issue.sh DAV-173 2>/dev/null | grep "Workspace ready" || echo "NO_OUTPUT")
    
    assert_equals "$expected_output" "$actual_output" "Should output correct workspace path"
}

test_comprehensive_status_reporting() {
    # Test comprehensive status reporting - should fail
    setup_test_env
    cd "$TEST_REPO"
    
    local output=$(../../scripts/start-issue.sh DAV-173 2>/dev/null || echo "SCRIPT_NOT_FOUND")
    
    # Should contain Linear update confirmation
    echo "$output" | grep -q "Linear status updated to In Progress"
    assert_equals 0 $? "Output should contain Linear status update confirmation"
    
    # Should contain worktree path
    echo "$output" | grep -q "worktrees/DAV-173"
    assert_equals 0 $? "Output should contain worktree path"
    
    # Should contain branch status
    echo "$output" | grep -q "branch.*created"
    assert_equals 0 $? "Output should contain branch creation status"
}

test_invalid_issue_id_handling() {
    # Test handling of invalid issue ID - should fail
    assert_failure "scripts/start-issue.sh INVALID-123" "Should fail with invalid issue ID"
    
    # Check exit code is 1
    scripts/start-issue.sh INVALID-123 &>/dev/null
    local exit_code=$?
    assert_equals 1 $exit_code "Should exit with code 1 for invalid issue"
}

test_linear_api_unavailable_handling() {
    # Test handling of Linear API unavailability - should fail
    # Mock network failure
    export LINEAR_API_MOCK_FAILURE=true
    
    assert_failure "scripts/start-issue.sh DAV-173" "Should fail gracefully when Linear API unavailable"
    
    unset LINEAR_API_MOCK_FAILURE
}

test_git_repository_issues_handling() {
    # Test handling of git repository issues - should fail
    setup_test_env
    
    # Create corrupted git repository
    rm -rf "$TEST_REPO/.git"
    cd "$TEST_REPO"
    
    assert_failure "../../scripts/start-issue.sh DAV-173" "Should fail gracefully with corrupted git repository"
}

test_dirty_repository_state_validation() {
    # Test validation of git repository clean state - should fail
    setup_test_env
    cd "$TEST_REPO"
    
    # Create uncommitted changes
    echo "dirty changes" > dirty-file.txt
    
    # Script should warn about dirty state (will fail since script doesn't exist)
    local output=$(../../scripts/start-issue.sh DAV-173 2>&1 || echo "SCRIPT_NOT_FOUND")
    
    echo "$output" | grep -q -i "warning.*dirty\|uncommitted"
    assert_equals 0 $? "Should warn about dirty repository state"
}

# Main test execution
main() {
    describe "Start Issue Script (start-issue.sh)"
    
    # Setup mocks
    setup_linear_mocks
    
    describe "Linear MCP Integration"
    test "fetches valid Linear issue successfully" test_linear_issue_fetching
    test "extracts gitBranchName for worktree directory" test_git_branch_name_extraction  
    test "updates Linear status to In Progress" test_linear_status_update
    
    describe "Git Worktree Operations"
    test "creates worktree from Linear gitBranchName" test_worktree_creation
    test "handles existing worktree directory gracefully" test_existing_worktree_handling
    test "creates branch from Linear gitBranchName field" test_branch_creation_from_linear
    test "preserves git repository state" test_repository_state_preservation
    
    describe "Output and User Experience"
    test "outputs workspace path for agent navigation" test_workspace_path_output
    test "provides comprehensive status reporting" test_comprehensive_status_reporting
    
    describe "Error Scenarios"  
    test "script exists and is executable" test_start_issue_script_exists
    test "handles Linear issue not found" test_invalid_issue_id_handling
    test "handles Linear API unavailable" test_linear_api_unavailable_handling
    test "handles git repository issues" test_git_repository_issues_handling
    test "validates git repository clean state" test_dirty_repository_state_validation
    
    show_summary
}

# Run tests
main "$@"