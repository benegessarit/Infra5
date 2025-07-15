#!/bin/bash
# Test script for cycle-plan context awareness functionality

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local expected_contains="$2"
    local test_command="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "\n${YELLOW}TEST $TESTS_RUN: $test_name${NC}"
    
    # Run the test command and capture output
    local output
    output=$($test_command 2>&1 || true)
    
    # Check if output contains expected string
    if [[ "$output" == *"$expected_contains"* ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Found expected content"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: Expected to find '$expected_contains'"
        echo "Actual output:"
        echo "$output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 1: Verify current generic opening script (baseline)
echo "=== Testing Current Cycle-Plan Behavior ==="

# Create a test directory without Dev Kit markers
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

run_test "Generic project opening script" \
    "I'm in planning mode (no implementation)" \
    'grep -A5 "Generic Opening Script" "$HOME/.claude/commands/cycle-plan-[Opus].md"'

# Test 2: Verify project detection logic exists
run_test "Project detection section exists" \
    "PROJECT CONTEXT DETECTION" \
    'grep "PROJECT CONTEXT DETECTION" "$HOME/.claude/commands/cycle-plan-[Opus].md"'

# Test 3: Check if detection code is executable (not just documentation)
echo -e "\n${YELLOW}TEST 3: Checking for executable detection code${NC}"
TESTS_RUN=$((TESTS_RUN + 1))

# Look for actual bash code blocks in the detection section
if grep -A20 "PROJECT CONTEXT DETECTION" "$HOME/.claude/commands/cycle-plan-[Opus].md" | grep -q 'test -f\|\[\[ -f'; then
    echo -e "${GREEN}✓ PASS${NC}: Found executable file detection code"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ FAIL${NC}: No executable detection code found (only documentation)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 4: Simulate Dev Kit project environment
echo -e "\n${YELLOW}TEST 4: Testing Dev Kit project detection${NC}"
TESTS_RUN=$((TESTS_RUN + 1))

# Create Dev Kit markers
touch CLAUDE.md
mkdir -p docs/ai-context
touch docs/ai-context/project-structure.md
touch docs/ai-context/docs-overview.md

# This test will check if the enhanced script would be shown
# Currently this will FAIL because the implementation is just documentation
if grep -A30 "Enhanced Opening Script" "$HOME/.claude/commands/cycle-plan-[Opus].md" | grep -q 'Project detected:.*AI Development Framework'; then
    echo -e "${YELLOW}⚠ WARNING${NC}: Enhanced script template exists but no code executes it"
    TESTS_FAILED=$((TESTS_FAILED + 1))
else
    echo -e "${RED}✗ FAIL${NC}: Enhanced script not properly implemented"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 5: Performance measurement
echo -e "\n${YELLOW}TEST 5: Context loading performance${NC}"
TESTS_RUN=$((TESTS_RUN + 1))

# Since there's no actual implementation, we can't measure performance
echo -e "${RED}✗ FAIL${NC}: Cannot measure performance - no executable code"
TESTS_FAILED=$((TESTS_FAILED + 1))

# Cleanup
cd /
rm -rf "$TEST_DIR"

# Summary
echo -e "\n=== TEST SUMMARY ==="
echo -e "Tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed!${NC}"
    exit 1
fi