#!/bin/bash
# Hook Test Scenarios
# Systematic testing of context injection hook behavior patterns

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Context Injection Hook Test Scenarios ==="
echo "Testing hook behavior patterns to identify token bloat root cause"
echo ""

# Function to trigger a minimal Task tool call (simulated)
test_minimal_task_call() {
    echo "Test 1: Minimal Task Call"
    echo "Creating minimal Task tool JSON input..."
    
    minimal_json='{
        "tool_name": "Task",
        "tool_input": {
            "prompt": "Hello world test",
            "description": "Minimal test prompt"
        }
    }'
    
    echo "Input JSON: $minimal_json"
    echo "Processing through debug hook..."
    
    # Process through debug hook
    output=$(echo "$minimal_json" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
    
    echo "Output JSON size: $(echo "$output" | wc -c) characters"
    echo "Test 1 completed - check logs for detailed metrics"
    echo ""
}

# Function to test MCP tool behavior
test_mcp_tool_call() {
    echo "Test 2: MCP Tool Call (Task Master)"
    echo "Creating MCP Task Master tool JSON input..."
    
    mcp_json='{
        "tool_name": "mcp__task-master__get_tasks",
        "tool_input": {
            "projectRoot": "/Users/davidbeyer/Infra5"
        }
    }'
    
    echo "Input JSON: $mcp_json"
    echo "Processing through debug hook..."
    
    # Process through debug hook
    output=$(echo "$mcp_json" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
    
    echo "Output JSON: $output"
    echo "Test 2 completed - MCP tools should pass through unchanged"
    echo ""
}

# Function to test @ reference behavior
test_reference_processing() {
    echo "Test 3: @ Reference Processing Behavior"
    echo "Creating Task with different @ reference formats..."
    
    reference_json='{
        "tool_name": "Task",
        "tool_input": {
            "prompt": "Test @/full/path and @relative/path and @nonexistent/file references",
            "description": "Testing @ reference expansion"
        }
    }'
    
    echo "Input JSON: $reference_json"
    echo "Processing through debug hook..."
    
    # Process through debug hook
    output=$(echo "$reference_json" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
    
    echo "Output contains $(echo "$output" | grep -o "@" | wc -l) @ references"
    echo "Test 3 completed - check logs for @ reference impact"
    echo ""
}

# Function to test JSON processing integrity
test_json_processing() {
    echo "Test 4: JSON Processing Integrity"
    echo "Creating Task with special characters and complex prompt..."
    
    complex_json='{
        "tool_name": "Task",
        "tool_input": {
            "prompt": "Complex test with \"quotes\" and \\backslashes\\ and newlines\nand special chars: !@#$%^&*()",
            "description": "Testing JSON processing integrity"
        }
    }'
    
    echo "Input JSON: $complex_json"
    echo "Processing through debug hook..."
    
    # Process through debug hook
    output=$(echo "$complex_json" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
    
    # Verify JSON is still valid
    if echo "$output" | jq . >/dev/null 2>&1; then
        echo "✓ Output JSON is valid"
    else
        echo "✗ Output JSON is invalid!"
    fi
    
    echo "Test 4 completed - JSON processing integrity verified"
    echo ""
}

# Function to test execution frequency
test_execution_frequency() {
    echo "Test 5: Execution Frequency Analysis"
    echo "Running multiple Task calls in sequence..."
    
    # Clear execution counter
    rm -f /tmp/claude-hook-executions.count
    
    for i in {1..3}; do
        test_json='{
            "tool_name": "Task",
            "tool_input": {
                "prompt": "Execution test '$i'",
                "description": "Frequency test"
            }
        }'
        
        echo "Execution $i..."
        echo "$test_json" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh" >/dev/null
    done
    
    executions=$(cat /tmp/claude-hook-executions.count 2>/dev/null || echo 0)
    echo "Total executions recorded: $executions (expected: 3)"
    
    if [[ "$executions" == "3" ]]; then
        echo "✓ Execution frequency matches expected"
    else
        echo "✗ Execution frequency mismatch!"
    fi
    
    echo "Test 5 completed"
    echo ""
}

# Main test execution
main() {
    echo "Starting comprehensive hook test scenarios..."
    echo "Debug hook location: $PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh"
    echo ""
    
    # Verify debug hook exists
    if [[ ! -f "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh" ]]; then
        echo "ERROR: Debug hook not found!"
        exit 1
    fi
    
    # Make sure debug hook is executable
    chmod +x "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh"
    
    # Run all test scenarios
    test_minimal_task_call
    test_mcp_tool_call
    test_reference_processing
    test_json_processing
    test_execution_frequency
    
    echo "=== All Test Scenarios Completed ==="
    echo "Run './analyze-hook-logs.sh' to view detailed analysis"
}

# Execute main function
main "$@"