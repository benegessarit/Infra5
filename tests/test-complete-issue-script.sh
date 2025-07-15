#!/bin/bash
# Tests for complete-issue.sh script

source "$(dirname "$0")/test-framework.sh"

# Mock the complete-issue.sh script (it doesn't exist yet - this should fail)
test_complete_issue_script_exists() {
    assert_file_exists "scripts/complete-issue.sh" "complete-issue.sh script should exist"
}

test_linear_status_update_to_review() {
    # Test Linear status update to In Review - should fail since script doesn't exist
    assert_success "scripts/complete-issue.sh --dry-run DAV-173" "Should update Linear status to In Review"
    
    # Mock checking the status update response
    local expected_status="In Review"
    local actual_status=$(scripts/complete-issue.sh --dry-run --get-status DAV-173 2>/dev/null || echo "SCRIPT_NOT_FOUND")
    assert_equals "$expected_status" "$actual_status" "Status should be updated to In Review"
}

test_issue_already_in_review_handling() {
    # Test handling of issue already in Review status - should fail
    # Mock issue already in review
    export MOCK_ISSUE_STATUS="In Review"
    
    local output=$(scripts/complete-issue.sh DAV-173 2>&1 || echo "SCRIPT_NOT_FOUND")
    
    echo "$output" | grep -q -i "warning.*already.*review"
    assert_equals 0 $? "Should warn when issue already in Review status"
    
    # Should still complete successfully (idempotent)
    scripts/complete-issue.sh DAV-173 &>/dev/null
    local exit_code=$?
    assert_equals 0 $exit_code "Should complete successfully even if already in Review"
    
    unset MOCK_ISSUE_STATUS
}

test_workflow_inconsistency_validation() {
    # Test validation that issue was started with script - should fail
    # Mock issue manually moved to In Progress
    export MOCK_WORKFLOW_STARTED=false
    
    local output=$(scripts/complete-issue.sh DAV-173 2>&1 || echo "SCRIPT_NOT_FOUND")
    
    echo "$output" | grep -q -i "warning.*workflow.*inconsistency"
    assert_equals 0 $? "Should warn about workflow inconsistency"
    
    unset MOCK_WORKFLOW_STARTED
}

test_worktree_cleanup_options() {
    # Test worktree cleanup options - should fail
    setup_test_env
    cd "$TEST_REPO"
    
    # Create mock worktree directory
    mkdir -p "worktrees/DAV-173-integrate-context-forge"
    
    local output=$(../../scripts/complete-issue.sh --interactive DAV-173 2>&1 || echo "SCRIPT_NOT_FOUND")
    
    # Should offer cleanup options
    echo "$output" | grep -q -i "archive\|delete\|preserve"
    assert_equals 0 $? "Should offer worktree cleanup options (archive, delete, preserve)"
}

test_worktree_state_validation() {
    # Test validation of worktree state before completion - should fail
    setup_test_env
    cd "$TEST_REPO"
    
    # Create worktree with uncommitted changes
    mkdir -p "worktrees/DAV-173-integrate-context-forge"
    cd "worktrees/DAV-173-integrate-context-forge"
    git init --quiet
    echo "uncommitted work" > uncommitted-file.txt
    cd - >/dev/null
    
    local output=$(../../scripts/complete-issue.sh DAV-173 2>&1 || echo "SCRIPT_NOT_FOUND")
    
    echo "$output" | grep -q -i "warning.*uncommitted.*changes"
    assert_equals 0 $? "Should warn about uncommitted changes in worktree"
}

test_completion_confirmation_output() {
    # Test completion confirmation output - should fail
    setup_test_env
    cd "$TEST_REPO"
    
    local output=$(../../scripts/complete-issue.sh DAV-173 2>&1 || echo "SCRIPT_NOT_FOUND")
    
    # Should contain completion confirmation
    echo "$output" | grep -q -i "completion.*confirmation\|issue.*completed"
    assert_equals 0 $? "Output should contain completion confirmation"
    
    # Should contain Linear status info
    echo "$output" | grep -q -i "linear.*status.*review"
    assert_equals 0 $? "Output should contain Linear status information"
    
    # Should contain worktree action info
    echo "$output" | grep -q -i "worktree.*action"
    assert_equals 0 $? "Output should contain worktree action information"
}

test_invalid_issue_id_handling() {
    # Test handling of invalid issue ID - should fail
    assert_failure "scripts/complete-issue.sh INVALID-123" "Should fail with invalid issue ID"
    
    # Check exit code is 1
    scripts/complete-issue.sh INVALID-123 &>/dev/null
    local exit_code=$?
    assert_equals 1 $exit_code "Should exit with code 1 for invalid issue"
}

test_linear_api_unavailable_handling() {
    # Test handling of Linear API unavailability - should fail
    export LINEAR_API_MOCK_FAILURE=true
    
    assert_failure "scripts/complete-issue.sh DAV-173" "Should fail gracefully when Linear API unavailable"
    
    unset LINEAR_API_MOCK_FAILURE
}

test_missing_worktree_handling() {
    # Test handling of missing worktree - should fail
    setup_test_env
    cd "$TEST_REPO"
    
    # No worktree directory exists
    local output=$(../../scripts/complete-issue.sh DAV-173 2>&1 || echo "SCRIPT_NOT_FOUND")
    
    echo "$output" | grep -q -i "warning.*worktree.*not.*found"
    assert_equals 0 $? "Should warn when worktree directory not found"
    
    # Should still complete the Linear status update
    echo "$output" | grep -q -i "linear.*status.*updated"
    assert_equals 0 $? "Should still update Linear status even without worktree"
}

test_worktree_cleanup_archive_option() {
    # Test worktree cleanup archive functionality - should fail
    setup_test_env
    cd "$TEST_REPO"
    
    mkdir -p "worktrees/DAV-173-integrate-context-forge"
    
    # Test archive option
    echo "archive" | scripts/complete-issue.sh --interactive DAV-173 &>/dev/null || true
    
    # Should move worktree to archived location
    assert_dir_exists "worktrees/archived/DAV-173-integrate-context-forge-$(date +%Y%m%d)" "Worktree should be archived with timestamp"
}

test_worktree_cleanup_delete_option() {
    # Test worktree cleanup delete functionality - should fail
    setup_test_env
    cd "$TEST_REPO"
    
    mkdir -p "worktrees/DAV-173-integrate-context-forge"
    
    # Test delete option
    echo "delete" | scripts/complete-issue.sh --interactive DAV-173 &>/dev/null || true
    
    # Directory should be removed
    assert_failure "test -d worktrees/DAV-173-integrate-context-forge" "Worktree directory should be deleted"
}

test_worktree_cleanup_preserve_option() {
    # Test worktree cleanup preserve functionality - should fail
    setup_test_env
    cd "$TEST_REPO"
    
    mkdir -p "worktrees/DAV-173-integrate-context-forge"
    
    # Test preserve option
    echo "preserve" | scripts/complete-issue.sh --interactive DAV-173 &>/dev/null || true
    
    # Directory should still exist
    assert_dir_exists "worktrees/DAV-173-integrate-context-forge" "Worktree directory should be preserved"
}

test_script_executable_permissions() {
    # Test that script has proper executable permissions - should fail
    if [ -f "scripts/complete-issue.sh" ]; then
        assert_success "test -x scripts/complete-issue.sh" "Script should be executable"
    else
        assert_file_exists "scripts/complete-issue.sh" "Script should exist first"
    fi
}

# Main test execution
main() {
    describe "Complete Issue Script (complete-issue.sh)"
    
    describe "Linear Status Management"
    test "script exists and is executable" test_complete_issue_script_exists
    test "script has executable permissions" test_script_executable_permissions
    test "updates Linear status to In Review" test_linear_status_update_to_review
    test "handles issue already in Review status" test_issue_already_in_review_handling
    test "validates issue was started with script" test_workflow_inconsistency_validation
    
    describe "Worktree Management"
    test "provides worktree cleanup options" test_worktree_cleanup_options
    test "validates worktree state before completion" test_worktree_state_validation
    test "handles missing worktree gracefully" test_missing_worktree_handling
    test "supports worktree archive option" test_worktree_cleanup_archive_option
    test "supports worktree delete option" test_worktree_cleanup_delete_option
    test "supports worktree preserve option" test_worktree_cleanup_preserve_option
    
    describe "Completion Reporting"
    test "outputs completion confirmation" test_completion_confirmation_output
    
    describe "Error Scenarios"
    test "handles Linear issue not found" test_invalid_issue_id_handling
    test "handles Linear API unavailable" test_linear_api_unavailable_handling
    
    show_summary
}

# Run tests
main "$@"