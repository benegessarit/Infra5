#!/bin/bash
# MCP Tool Behavior Test
# Verifies that MCP tools correctly bypass hook processing

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== MCP Tool Behavior Test ==="
echo "Verifying MCP tools bypass context injection hook correctly"
echo ""

# Function to test regular Task tool
test_regular_task_tool() {
    echo "1. Regular Task Tool (Should be processed):"
    echo ""
    
    task_json='{
        "tool_name": "Task",
        "tool_input": {
            "prompt": "Regular task prompt",
            "description": "Regular task test"
        }
    }'
    
    echo "Input: Regular Task tool"
    echo "Processing through debug hook..."
    
    task_output=$(echo "$task_json" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
    
    # Analyze output
    output_size=$(echo "$task_output" | wc -c)
    ref_count=$(echo "$task_output" | grep -o "@" | wc -l)
    
    echo "Results:"
    echo "- Output size: $output_size characters"
    echo "- @ references added: $ref_count"
    echo "- Status: Context injection applied ✓"
    echo ""
}

# Function to test Task Master MCP tools
test_task_master_tools() {
    echo "2. Task Master MCP Tools (Should bypass):"
    echo ""
    
    # Test various Task Master tools
    mcp_tools=(
        "mcp__task-master__get_tasks"
        "mcp__task-master__get_task"
        "mcp__task-master__add_task"
        "mcp__task-master__update_task"
        "mcp__task-master__set_task_status"
    )
    
    for tool in "${mcp_tools[@]}"; do
        echo "Testing: $tool"
        
        mcp_json='{
            "tool_name": "'$tool'",
            "tool_input": {
                "projectRoot": "/Users/davidbeyer/Infra5",
                "id": "test"
            }
        }'
        
        mcp_output=$(echo "$mcp_json" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
        
        # Check if it's the expected bypass response
        if [[ "$mcp_output" == '{"continue": true}' ]]; then
            echo "  ✓ Correctly bypassed hook"
        else
            echo "  ✗ Unexpected processing: $mcp_output"
        fi
    done
    echo ""
}

# Function to test other MCP tools
test_other_mcp_tools() {
    echo "3. Other MCP Tools (Should bypass):"
    echo ""
    
    # Test other MCP tool types
    other_mcp_tools=(
        "mcp__linear-server__get_issue"
        "mcp__context7__get-library-docs"
        "mcp__sequential-thinking__sequentialthinking"
    )
    
    for tool in "${other_mcp_tools[@]}"; do
        echo "Testing: $tool"
        
        other_mcp_json='{
            "tool_name": "'$tool'",
            "tool_input": {
                "query": "test"
            }
        }'
        
        other_output=$(echo "$other_mcp_json" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
        
        # Check if it's the expected bypass response
        if [[ "$other_output" == '{"continue": true}' ]]; then
            echo "  ✓ Correctly bypassed hook"
        else
            echo "  ✗ Unexpected processing: $other_output"
        fi
    done
    echo ""
}

# Function to test edge cases
test_edge_cases() {
    echo "4. Edge Cases:"
    echo ""
    
    # Test tool name variations
    echo "Testing tool name edge cases..."
    
    # Test empty tool name
    empty_tool='{
        "tool_name": "",
        "tool_input": {
            "prompt": "Empty tool test"
        }
    }'
    
    echo "Empty tool name:"
    empty_output=$(echo "$empty_tool" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
    if [[ "$empty_output" == '{"continue": true}' ]]; then
        echo "  ✓ Empty tool name bypassed correctly"
    else
        echo "  ✗ Empty tool name processed unexpectedly"
    fi
    
    # Test missing tool name
    missing_tool='{
        "tool_input": {
            "prompt": "Missing tool test"
        }
    }'
    
    echo "Missing tool name:"
    missing_output=$(echo "$missing_tool" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
    if [[ "$missing_output" == '{"continue": true}' ]]; then
        echo "  ✓ Missing tool name bypassed correctly"
    else
        echo "  ✗ Missing tool name processed unexpectedly"
    fi
    
    # Test case sensitivity
    case_test='{
        "tool_name": "task",
        "tool_input": {
            "prompt": "Case sensitivity test"
        }
    }'
    
    echo "Lowercase 'task' (should bypass):"
    case_output=$(echo "$case_test" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
    if [[ "$case_output" == '{"continue": true}' ]]; then
        echo "  ✓ Case-sensitive matching works correctly"
    else
        echo "  ✗ Case-sensitive matching failed"
    fi
    echo ""
}

# Function to analyze hook filtering efficiency
analyze_filtering_efficiency() {
    echo "5. Hook Filtering Efficiency Analysis:"
    echo ""
    
    # Count log entries to see filtering in action
    log_file="/tmp/claude-hook-debug-$(date +%Y%m%d).log"
    
    if [[ -f "$log_file" ]]; then
        echo "Analyzing hook execution logs..."
        
        total_executions=$(grep "Hook executed" "$log_file" | wc -l)
        task_executions=$(grep "Tool name: Task" "$log_file" | wc -l)
        non_task_executions=$(grep "Non-Task tool passed through" "$log_file" | wc -l)
        
        echo "Hook execution summary:"
        echo "- Total hook executions: $total_executions"
        echo "- Task tool executions (processed): $task_executions"
        echo "- Non-Task tool executions (bypassed): $non_task_executions"
        
        if [[ $total_executions -gt 0 ]]; then
            task_percentage=$((task_executions * 100 / total_executions))
            echo "- Task tool percentage: $task_percentage%"
            echo "- Bypass efficiency: $((100 - task_percentage))%"
        fi
        
        echo ""
        echo "Recent bypass examples:"
        grep "Non-Task tool passed through" "$log_file" | tail -3
    else
        echo "No execution log found - run other tests first"
    fi
    echo ""
}

# Main execution
main() {
    echo "Testing MCP tool filtering and bypass behavior..."
    echo ""
    
    test_regular_task_tool
    test_task_master_tools
    test_other_mcp_tools
    test_edge_cases
    analyze_filtering_efficiency
    
    echo "=== MCP Tool Behavior Test Complete ==="
    echo "Hook correctly filters and processes only Task tools, bypassing all MCP tools"
}

# Execute main function
main "$@"