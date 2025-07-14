#!/bin/bash
# Simple test framework for bash scripts
# Usage: source test-framework.sh in your test files

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test suite name
SUITE_NAME=""

# Function to start a test suite
describe() {
    SUITE_NAME="$1"
    echo -e "${YELLOW}=== $SUITE_NAME ===${NC}"
}

# Function to run a test
test() {
    local test_name="$1"
    local test_function="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    echo -n "  $test_name... "
    
    # Capture test output
    if $test_function &>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        # Run test again to show output on failure
        echo -e "    ${RED}Error details:${NC}"
        $test_function 2>&1 | sed 's/^/      /'
    fi
}

# Function to assert equality
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [ "$expected" = "$actual" ]; then
        return 0
    else
        echo "Expected: '$expected', got: '$actual'"
        [ -n "$message" ] && echo "Message: $message"
        return 1
    fi
}

# Function to assert file exists
assert_file_exists() {
    local file_path="$1"
    local message="$2"
    
    if [ -f "$file_path" ]; then
        return 0
    else
        echo "File does not exist: $file_path"
        [ -n "$message" ] && echo "Message: $message"
        return 1
    fi
}

# Assert that a file does not exist
assert_file_not_exists() {
    local file_path="$1"
    local message="$2"
    
    if [ -f "$file_path" ]; then
        echo "File should not exist but does: $file_path"
        echo "Message: $message"
        return 1
    fi
    return 0
}

# Function to assert directory exists  
assert_dir_exists() {
    local dir_path="$1"
    local message="$2"
    
    if [ -d "$dir_path" ]; then
        return 0
    else
        echo "Directory does not exist: $dir_path"
        [ -n "$message" ] && echo "Message: $message"
        return 1
    fi
}

# Function to assert command succeeds
assert_success() {
    local command="$1"
    local message="$2"
    
    if $command &>/dev/null; then
        return 0
    else
        echo "Command failed: $command"
        [ -n "$message" ] && echo "Message: $message"
        $command 2>&1 | sed 's/^/  /'
        return 1
    fi
}

# Function to assert command fails
assert_failure() {
    local command="$1"
    local message="$2"
    
    if ! $command &>/dev/null; then
        return 0
    else
        echo "Command should have failed but succeeded: $command"
        [ -n "$message" ] && echo "Message: $message"
        return 1
    fi
}

# Function to show test summary
show_summary() {
    echo
    echo -e "${YELLOW}=== Test Summary ===${NC}"
    echo "Tests run: $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        return 1
    fi
}

# Setup test environment
setup_test_env() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d)
    export TEST_DIR
    
    # Setup mock git repository for testing
    TEST_REPO="$TEST_DIR/test-repo"
    mkdir -p "$TEST_REPO"
    cd "$TEST_REPO"
    git init --quiet
    git config user.name "Test User"
    git config user.email "test@example.com"
    echo "# Test Repository" > README.md
    git add README.md
    git commit --quiet -m "Initial commit"
    cd - >/dev/null
    
    export TEST_REPO
}

# Cleanup test environment  
cleanup_test_env() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Trap to cleanup on exit
trap cleanup_test_env EXIT