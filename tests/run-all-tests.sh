#!/bin/bash
# Test runner for all git workflow automation tests

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${YELLOW}=== Git Workflow Automation Test Suite ===${NC}"
echo "Running comprehensive tests for start-issue.sh and complete-issue.sh"
echo

# Track overall results
TOTAL_SUITES=0
FAILED_SUITES=0

run_test_suite() {
    local test_file="$1"
    local suite_name="$2"
    
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    
    echo -e "${YELLOW}--- $suite_name ---${NC}"
    
    if [ -f "$SCRIPT_DIR/$test_file" ] && [ -x "$SCRIPT_DIR/$test_file" ]; then
        "$SCRIPT_DIR/$test_file"
        local result=$?
        
        if [ $result -ne 0 ]; then
            FAILED_SUITES=$((FAILED_SUITES + 1))
            echo -e "${RED}❌ $suite_name FAILED${NC}"
        else
            echo -e "${GREEN}✅ $suite_name PASSED${NC}"
        fi
        
        echo
        return $result
    else
        echo -e "${RED}❌ Test file not found or not executable: $test_file${NC}"
        FAILED_SUITES=$((FAILED_SUITES + 1))
        echo
        return 1
    fi
}

# Run all test suites
echo "🔴 RED Phase: All tests should FAIL since scripts don't exist yet"
echo

run_test_suite "test-start-issue-script.sh" "start-issue.sh Tests"
run_test_suite "test-complete-issue-script.sh" "complete-issue.sh Tests" 
run_test_suite "test-integration-workflow.sh" "Integration Workflow Tests"

# Final summary
echo -e "${YELLOW}=== Final Test Summary ===${NC}"
echo "Total test suites: $TOTAL_SUITES"
echo -e "Failed test suites: ${RED}$FAILED_SUITES${NC}"
echo -e "Passed test suites: ${GREEN}$((TOTAL_SUITES - FAILED_SUITES))${NC}"

if [ $FAILED_SUITES -eq $TOTAL_SUITES ]; then
    echo -e "${GREEN}✅ RED Phase Complete: All tests failing as expected${NC}"
    echo "Ready to proceed to GREEN phase (implement scripts to make tests pass)"
    exit 0
elif [ $FAILED_SUITES -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Mixed results: Some tests passing, some failing${NC}"
    exit 1
fi