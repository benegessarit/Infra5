#!/bin/bash
# Integration tests for end-to-end git workflow automation

source "$(dirname "$0")/test-framework.sh"

# Setup integration test environment
setup_integration_env() {
    setup_test_env
    
    # Create additional test issues for parallel testing
    mkdir -p "$TEST_DIR/mocks"
    
    # Mock for DAV-173
    cat > "$TEST_DIR/mocks/dav-173.json" << 'EOF'
{
  "id": "DAV-173",
  "title": "Integrate Context Forge with Claude Code",
  "gitBranchName": "dbeyer7/dav-173-integrate-context-forge-with-claude-code",
  "status": {"id": "a352fb76-a25c-4cc1-808a-420bc20726a2", "name": "Backlog"}
}
EOF

    # Mock for DAV-176
    cat > "$TEST_DIR/mocks/dav-176.json" << 'EOF'
{
  "id": "DAV-176", 
  "title": "Git Workflow Integration",
  "gitBranchName": "dbeyer7/dav-176-git-workflow-integration",
  "status": {"id": "a352fb76-a25c-4cc1-808a-420bc20726a2", "name": "Backlog"}
}
EOF
}

test_complete_start_to_finish_workflow() {
    # Test complete workflow: start → work → complete - should fail
    setup_integration_env
    cd "$TEST_REPO"
    
    # Step 1: Start issue (should fail - script doesn't exist)
    assert_success "../../scripts/start-issue.sh DAV-173" "Should start issue successfully"
    
    # Verify worktree created
    assert_dir_exists "worktrees/DAV-173-integrate-context-forge" "Worktree should be created"
    
    # Verify Linear status updated to In Progress (mock verification)
    local status=$(../../scripts/start-issue.sh --get-status DAV-173 2>/dev/null || echo "SCRIPT_NOT_FOUND")
    assert_equals "In Progress" "$status" "Linear status should be In Progress"
    
    # Step 2: Simulate work in worktree
    cd "worktrees/DAV-173-integrate-context-forge" 2>/dev/null || mkdir -p "worktrees/DAV-173-integrate-context-forge"
    echo "# Feature implementation" > feature.md
    
    # Step 3: Complete issue (should fail - script doesn't exist)
    cd "$TEST_REPO"
    assert_success "../../scripts/complete-issue.sh DAV-173" "Should complete issue successfully"
    
    # Verify Linear status updated to In Review (mock verification) 
    local final_status=$(../../scripts/complete-issue.sh --get-status DAV-173 2>/dev/null || echo "SCRIPT_NOT_FOUND")
    assert_equals "In Review" "$final_status" "Linear status should be In Review"
}

test_parallel_worktree_support() {
    # Test parallel worktree creation for multiple issues - should fail
    setup_integration_env
    cd "$TEST_REPO"
    
    # Start first issue
    assert_success "../../scripts/start-issue.sh DAV-173" "Should start DAV-173 successfully"
    
    # Start second issue in parallel
    assert_success "../../scripts/start-issue.sh DAV-176" "Should start DAV-176 successfully"
    
    # Verify both worktrees exist
    assert_dir_exists "worktrees/DAV-173-integrate-context-forge" "DAV-173 worktree should exist"
    assert_dir_exists "worktrees/DAV-176-git-workflow-integration" "DAV-176 worktree should exist"
    
    # Verify both Linear issues updated to In Progress
    local status_173=$(../../scripts/start-issue.sh --get-status DAV-173 2>/dev/null || echo "SCRIPT_NOT_FOUND")
    local status_176=$(../../scripts/start-issue.sh --get-status DAV-176 2>/dev/null || echo "SCRIPT_NOT_FOUND")
    
    assert_equals "In Progress" "$status_173" "DAV-173 should be In Progress"
    assert_equals "In Progress" "$status_176" "DAV-176 should be In Progress"
    
    # Verify worktrees are isolated (no conflicts)
    cd "worktrees/DAV-173-integrate-context-forge" 2>/dev/null || mkdir -p "worktrees/DAV-173-integrate-context-forge"
    echo "DAV-173 work" > work173.txt
    cd - >/dev/null
    
    cd "worktrees/DAV-176-git-workflow-integration" 2>/dev/null || mkdir -p "worktrees/DAV-176-git-workflow-integration"
    echo "DAV-176 work" > work176.txt
    cd - >/dev/null
    
    # Files should be isolated
    assert_failure "test -f worktrees/DAV-173-integrate-context-forge/work176.txt" "Work should be isolated between worktrees"
    assert_failure "test -f worktrees/DAV-176-git-workflow-integration/work173.txt" "Work should be isolated between worktrees"
}

test_existing_git_workflow_preservation() {
    # Test that existing git workflow is preserved - should fail
    setup_integration_env
    cd "$TEST_REPO"
    
    # Setup existing workflow state
    git checkout -b existing-feature --quiet
    echo "existing work" > existing-file.txt
    git add existing-file.txt
    git commit -m "Existing work" --quiet
    
    # Switch back to main with uncommitted changes
    git checkout main --quiet  
    echo "uncommitted main work" > main-work.txt
    git add main-work.txt
    
    # Start issue workflow
    ../../scripts/start-issue.sh DAV-173 &>/dev/null || true
    
    # Verify main repository state preserved
    assert_success "git diff --cached --quiet main-work.txt" "Staged changes should be preserved"
    assert_success "git show-ref --verify --quiet refs/heads/existing-feature" "Existing branch should be preserved"
    
    # Verify existing branch work is intact
    git checkout existing-feature --quiet
    assert_file_exists "existing-file.txt" "Existing work should be preserved"
    git checkout main --quiet
    
    # Verify worktree operates independently
    if [ -d "worktrees/DAV-173-integrate-context-forge" ]; then
        cd "worktrees/DAV-173-integrate-context-forge"
        # Worktree should not have main repository files
        assert_failure "test -f main-work.txt" "Worktree should be isolated from main repository"
        assert_failure "test -f existing-file.txt" "Worktree should be isolated from other branches"
        cd - >/dev/null
    fi
}

test_error_recovery_scenarios() {
    # Test recovery from various failure scenarios - should fail
    setup_integration_env
    cd "$TEST_REPO"
    
    # Test recovery from partial worktree creation
    mkdir -p "worktrees/DAV-173-integrate-context-forge"
    
    # Should detect existing directory and handle gracefully
    local output=$(../../scripts/start-issue.sh DAV-173 2>&1 || echo "SCRIPT_NOT_FOUND")
    echo "$output" | grep -q -i "already.*exists\|conflict"
    assert_equals 0 $? "Should detect and report existing worktree directory"
    
    # Test recovery from Linear API failure during completion
    export LINEAR_API_MOCK_FAILURE=true
    
    local complete_output=$(../../scripts/complete-issue.sh DAV-173 2>&1 || echo "SCRIPT_NOT_FOUND")
    echo "$complete_output" | grep -q -i "api.*unavailable\|network.*error"
    assert_equals 0 $? "Should handle Linear API failure gracefully"
    
    unset LINEAR_API_MOCK_FAILURE
}

test_worktree_lifecycle_management() {
    # Test complete worktree lifecycle - should fail
    setup_integration_env
    cd "$TEST_REPO"
    
    # Create → Use → Archive workflow
    ../../scripts/start-issue.sh DAV-173 &>/dev/null || true
    
    if [ -d "worktrees/DAV-173-integrate-context-forge" ]; then
        # Simulate work
        cd "worktrees/DAV-173-integrate-context-forge"
        echo "completed feature" > feature.txt
        cd - >/dev/null
        
        # Complete and archive
        echo "archive" | ../../scripts/complete-issue.sh --interactive DAV-173 &>/dev/null || true
        
        # Verify archival
        local archive_dir="worktrees/archived/DAV-173-integrate-context-forge"
        assert_dir_exists "${archive_dir}-*" "Worktree should be archived with timestamp"
        
        # Verify original directory cleaned up
        assert_failure "test -d worktrees/DAV-173-integrate-context-forge" "Original worktree should be removed after archival"
    fi
}

test_multi_agent_coordination() {
    # Test multi-agent coordination scenarios - should fail
    setup_integration_env
    cd "$TEST_REPO"
    
    # Simulate Agent 1 starting DAV-173
    ../../scripts/start-issue.sh DAV-173 &>/dev/null || true
    
    # Simulate Agent 2 starting DAV-176  
    ../../scripts/start-issue.sh DAV-176 &>/dev/null || true
    
    # Both agents should be able to work independently
    if [ -d "worktrees/DAV-173-integrate-context-forge" ] && [ -d "worktrees/DAV-176-git-workflow-integration" ]; then
        # Agent 1 work
        cd "worktrees/DAV-173-integrate-context-forge"
        echo "agent1 work" > agent1-work.txt
        cd - >/dev/null
        
        # Agent 2 work (parallel)
        cd "worktrees/DAV-176-git-workflow-integration"  
        echo "agent2 work" > agent2-work.txt
        cd - >/dev/null
        
        # Verify isolation
        assert_failure "test -f worktrees/DAV-173-integrate-context-forge/agent2-work.txt" "Agent work should be isolated"
        assert_failure "test -f worktrees/DAV-176-git-workflow-integration/agent1-work.txt" "Agent work should be isolated"
        
        # Both agents should be able to complete independently
        ../../scripts/complete-issue.sh DAV-173 &>/dev/null || true
        ../../scripts/complete-issue.sh DAV-176 &>/dev/null || true
        
        # Both issues should reach In Review status
        local status_173=$(../../scripts/complete-issue.sh --get-status DAV-173 2>/dev/null || echo "SCRIPT_NOT_FOUND")
        local status_176=$(../../scripts/complete-issue.sh --get-status DAV-176 2>/dev/null || echo "SCRIPT_NOT_FOUND")
        
        assert_equals "In Review" "$status_173" "DAV-173 should reach In Review"
        assert_equals "In Review" "$status_176" "DAV-176 should reach In Review"
    fi
}

test_script_integration_points() {
    # Test integration points between scripts - should fail
    setup_integration_env
    cd "$TEST_REPO"
    
    # Verify start-issue.sh outputs can be consumed by complete-issue.sh
    local start_output=$(../../scripts/start-issue.sh DAV-173 2>&1 || echo "SCRIPT_NOT_FOUND")
    
    # Should output workspace path for agent navigation
    echo "$start_output" | grep -q "cd worktrees/DAV-173"
    assert_equals 0 $? "start-issue.sh should output workspace navigation command"
    
    # complete-issue.sh should be able to find worktree started by start-issue.sh
    if echo "$start_output" | grep -q "worktrees/DAV-173"; then
        local complete_output=$(../../scripts/complete-issue.sh DAV-173 2>&1 || echo "SCRIPT_NOT_FOUND")
        
        echo "$complete_output" | grep -q -v "worktree.*not.*found"
        assert_equals 0 $? "complete-issue.sh should find worktree created by start-issue.sh"
    fi
}

# Test runner utility
run_all_tests() {
    local start_tests_result=0
    local complete_tests_result=0
    local integration_tests_result=0
    
    echo -e "${YELLOW}=== Running All Test Suites ===${NC}"
    
    # Run start-issue tests
    echo -e "${YELLOW}--- start-issue.sh tests ---${NC}"
    tests/test-start-issue-script.sh
    start_tests_result=$?
    
    # Run complete-issue tests  
    echo -e "${YELLOW}--- complete-issue.sh tests ---${NC}"
    tests/test-complete-issue-script.sh
    complete_tests_result=$?
    
    # Run integration tests
    echo -e "${YELLOW}--- Integration tests ---${NC}"
    tests/test-integration-workflow.sh
    integration_tests_result=$?
    
    # Summary
    echo -e "${YELLOW}=== All Tests Summary ===${NC}"
    local total_failed=$((start_tests_result + complete_tests_result + integration_tests_result))
    
    if [ $total_failed -eq 0 ]; then
        echo -e "${GREEN}All test suites passed!${NC}"
        return 0
    else
        echo -e "${RED}$total_failed test suite(s) failed.${NC}"
        return 1
    fi
}

# Main test execution
main() {
    if [ "$1" = "--all" ]; then
        run_all_tests
        return $?
    fi
    
    describe "End-to-End Workflow Integration"
    
    test "complete start-to-finish workflow" test_complete_start_to_finish_workflow
    test "parallel worktree support" test_parallel_worktree_support
    test "existing git workflow preservation" test_existing_git_workflow_preservation
    test "error recovery scenarios" test_error_recovery_scenarios
    test "worktree lifecycle management" test_worktree_lifecycle_management
    test "multi-agent coordination" test_multi_agent_coordination
    test "script integration points" test_script_integration_points
    
    show_summary
}

# Run tests
main "$@"