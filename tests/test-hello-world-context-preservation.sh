#!/bin/bash

# Hello World Context Preservation Integration Test
# Tests the end-to-end context preservation workflow
# Following plan: cycles/2025-07-13/0139-hello-world-context-test-plan.md

set -e  # Exit on any error

TEST_DIR="/Users/davidbeyer/Infra5"
CYCLES_DIR="$TEST_DIR/cycles/$(date +%Y-%m-%d)"
CHECKPOINT_PREFIX="hello-world-context-test"
TEST_RESULTS_FILE="$TEST_DIR/logs/hello-world-context-test-results.log"

# Create logs directory if it doesn't exist
mkdir -p "$TEST_DIR/logs"

# Initialize test results
echo "Hello World Context Preservation Test - $(date)" > "$TEST_RESULTS_FILE"
echo "=================================================" >> "$TEST_RESULTS_FILE"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo "Running test: $test_name"
    echo "Test: $test_name - $(date)" >> "$TEST_RESULTS_FILE"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if $test_function; then
        echo "✅ PASSED: $test_name"
        echo "RESULT: PASSED" >> "$TEST_RESULTS_FILE"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "❌ FAILED: $test_name"
        echo "RESULT: FAILED" >> "$TEST_RESULTS_FILE"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    echo "" >> "$TEST_RESULTS_FILE"
}

# Test 1: Verify jq extraction commands work correctly
test_jq_extraction_commands() {
    echo "Testing jq extraction commands against checkpoint..." >> "$TEST_RESULTS_FILE"
    
    # Use the current checkpoint file
    local checkpoint_file="$CYCLES_DIR/0141-hello-world-context-test-checkpoint.json"
    
    if [ ! -f "$checkpoint_file" ]; then
        echo "ERROR: Checkpoint file not found: $checkpoint_file" >> "$TEST_RESULTS_FILE"
        return 1
    fi
    
    # Test tier1 extraction
    local tier1_count
    tier1_count=$(jq -r '.contextMetadata.autoLoadedDocs.tier1[].path' "$checkpoint_file" 2>/dev/null | wc -l)
    if [ "$tier1_count" -eq 0 ]; then
        echo "ERROR: No tier1 documents found in checkpoint" >> "$TEST_RESULTS_FILE"
        return 1
    fi
    echo "Found $tier1_count tier1 documents" >> "$TEST_RESULTS_FILE"
    
    # Test tier2 extraction
    local tier2_count
    tier2_count=$(jq -r '.contextMetadata.autoLoadedDocs.tier2[].path' "$checkpoint_file" 2>/dev/null | wc -l)
    echo "Found $tier2_count tier2 documents" >> "$TEST_RESULTS_FILE"
    
    # Verify specific expected files are present
    local claude_md_found
    claude_md_found=$(jq -r '.contextMetadata.autoLoadedDocs.tier1[].path' "$checkpoint_file" | grep -c "CLAUDE.md" || true)
    if [ "$claude_md_found" -eq 0 ]; then
        echo "ERROR: CLAUDE.md not found in tier1 documents" >> "$TEST_RESULTS_FILE"
        return 1
    fi
    
    echo "jq extraction commands working correctly" >> "$TEST_RESULTS_FILE"
    return 0
}

# Test 2: Verify checkpoint contains accurate context metadata
test_checkpoint_metadata_accuracy() {
    echo "Testing checkpoint metadata accuracy..." >> "$TEST_RESULTS_FILE"
    
    local checkpoint_file="$CYCLES_DIR/0141-hello-world-context-test-checkpoint.json"
    
    if [ ! -f "$checkpoint_file" ]; then
        echo "ERROR: Checkpoint file not found" >> "$TEST_RESULTS_FILE"
        return 1
    fi
    
    # Verify required metadata structure exists
    local has_context_metadata
    has_context_metadata=$(jq 'has("contextMetadata")' "$checkpoint_file")
    if [ "$has_context_metadata" != "true" ]; then
        echo "ERROR: contextMetadata missing from checkpoint" >> "$TEST_RESULTS_FILE"
        return 1
    fi
    
    # Verify autoLoadedDocs structure
    local has_auto_loaded_docs
    has_auto_loaded_docs=$(jq '.contextMetadata | has("autoLoadedDocs")' "$checkpoint_file")
    if [ "$has_auto_loaded_docs" != "true" ]; then
        echo "ERROR: autoLoadedDocs missing from checkpoint" >> "$TEST_RESULTS_FILE"
        return 1
    fi
    
    # Verify all documented files actually exist
    local all_files_exist=true
    while IFS= read -r file_path; do
        if [ ! -f "$file_path" ]; then
            echo "ERROR: Documented file does not exist: $file_path" >> "$TEST_RESULTS_FILE"
            all_files_exist=false
        fi
    done < <(jq -r '.contextMetadata.autoLoadedDocs.tier1[].path, .contextMetadata.autoLoadedDocs.tier2[].path, .contextMetadata.autoLoadedDocs.tier3[].path' "$checkpoint_file" 2>/dev/null | grep -v "null")
    
    if [ "$all_files_exist" != "true" ]; then
        return 1
    fi
    
    echo "Checkpoint metadata is accurate" >> "$TEST_RESULTS_FILE"
    return 0
}

# Test 3: Test manual context restoration process
test_manual_context_restoration() {
    echo "Testing manual context restoration process..." >> "$TEST_RESULTS_FILE"
    
    local checkpoint_file="$CYCLES_DIR/0141-hello-world-context-test-checkpoint.json"
    
    # Simulate manual restoration by extracting file paths
    local restoration_successful=true
    local files_restored=0
    
    # Extract and verify each tier can be restored
    while IFS= read -r file_path; do
        if [ -n "$file_path" ] && [ "$file_path" != "null" ]; then
            if [ -f "$file_path" ]; then
                echo "Successfully can restore: $file_path" >> "$TEST_RESULTS_FILE"
                files_restored=$((files_restored + 1))
            else
                echo "ERROR: Cannot restore missing file: $file_path" >> "$TEST_RESULTS_FILE"
                restoration_successful=false
            fi
        fi
    done < <(jq -r '.contextMetadata.autoLoadedDocs.tier1[].path, .contextMetadata.autoLoadedDocs.tier2[].path, .contextMetadata.autoLoadedDocs.tier3[].path' "$checkpoint_file")
    
    if [ "$files_restored" -eq 0 ]; then
        echo "ERROR: No files available for restoration" >> "$TEST_RESULTS_FILE"
        restoration_successful=false
    fi
    
    echo "Manual restoration process tested: $files_restored files available" >> "$TEST_RESULTS_FILE"
    
    if [ "$restoration_successful" = "true" ]; then
        return 0
    else
        return 1
    fi
}

# Test 4: Verify Hello World can be implemented using preserved context
test_hello_world_implementation_readiness() {
    echo "Testing Hello World implementation readiness..." >> "$TEST_RESULTS_FILE"
    
    # This test verifies that the preserved context contains the necessary information
    # to implement Hello World following project standards
    
    local checkpoint_file="$CYCLES_DIR/0141-hello-world-context-test-checkpoint.json"
    
    # Check if CLAUDE.md is accessible (contains coding standards)
    local claude_md_path
    claude_md_path=$(jq -r '.contextMetadata.autoLoadedDocs.tier1[] | select(.path | contains("CLAUDE.md")) | .path' "$checkpoint_file")
    
    if [ -z "$claude_md_path" ] || [ ! -f "$claude_md_path" ]; then
        echo "ERROR: CLAUDE.md not accessible for coding standards" >> "$TEST_RESULTS_FILE"
        return 1
    fi
    
    # Verify CLAUDE.md contains TypeScript requirements
    if ! grep -q "TypeScript" "$claude_md_path"; then
        echo "ERROR: TypeScript standards not found in CLAUDE.md" >> "$TEST_RESULTS_FILE"
        return 1
    fi
    
    # Verify CLAUDE.md contains Korean commit format requirements
    if ! grep -q "Korean\|한국" "$claude_md_path"; then
        echo "ERROR: Korean commit format not found in CLAUDE.md" >> "$TEST_RESULTS_FILE"
        return 1
    fi
    
    # Check if project structure documentation is accessible
    local project_structure_path
    project_structure_path=$(jq -r '.contextMetadata.autoLoadedDocs.tier1[] | select(.path | contains("project-structure.md")) | .path' "$checkpoint_file")
    
    if [ -z "$project_structure_path" ] || [ ! -f "$project_structure_path" ]; then
        echo "ERROR: project-structure.md not accessible" >> "$TEST_RESULTS_FILE"
        return 1
    fi
    
    echo "Hello World implementation context is ready" >> "$TEST_RESULTS_FILE"
    return 0
}

# Test 5: End-to-end context preservation validation
test_end_to_end_context_preservation() {
    echo "Testing end-to-end context preservation..." >> "$TEST_RESULTS_FILE"
    
    # This test validates that the overall context preservation workflow is complete
    local checkpoint_file="$CYCLES_DIR/0141-hello-world-context-test-checkpoint.json"
    
    # Verify checkpoint exists and is valid JSON
    if ! jq empty "$checkpoint_file" 2>/dev/null; then
        echo "ERROR: Checkpoint is not valid JSON" >> "$TEST_RESULTS_FILE"
        return 1
    fi
    
    # Verify context restoration was marked as successful
    local context_restoration_successful
    context_restoration_successful=$(jq -r '.requiredTracking.metrics.contextRestorationSuccessful' "$checkpoint_file")
    
    if [ "$context_restoration_successful" != "true" ]; then
        echo "ERROR: Context restoration not marked as successful" >> "$TEST_RESULTS_FILE"
        return 1
    fi
    
    # Verify restoration timestamps exist
    local has_restoration_timestamps
    has_restoration_timestamps=$(jq -r '.contextMetadata.autoLoadedDocs.tier1[0] | has("restoredAt")' "$checkpoint_file")
    
    if [ "$has_restoration_timestamps" != "true" ]; then
        echo "ERROR: Restoration timestamps missing" >> "$TEST_RESULTS_FILE"
        return 1
    fi
    
    echo "End-to-end context preservation validated" >> "$TEST_RESULTS_FILE"
    return 0
}

# Run all tests
echo "Starting Hello World Context Preservation Tests..."
echo ""

run_test "jq extraction commands" test_jq_extraction_commands
run_test "checkpoint metadata accuracy" test_checkpoint_metadata_accuracy  
run_test "manual context restoration process" test_manual_context_restoration
run_test "Hello World implementation readiness" test_hello_world_implementation_readiness
run_test "end-to-end context preservation" test_end_to_end_context_preservation

# Print summary
echo ""
echo "Test Summary:"
echo "============="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"

# Write summary to log
echo "" >> "$TEST_RESULTS_FILE"
echo "SUMMARY: $TESTS_PASSED/$TESTS_RUN tests passed" >> "$TEST_RESULTS_FILE"

# Exit with appropriate code
if [ "$TESTS_FAILED" -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed. Check $TEST_RESULTS_FILE for details."
    exit 1
fi