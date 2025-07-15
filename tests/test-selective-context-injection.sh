#!/bin/bash
# Test Selective Context Injection Behavior
# Verifies that context is only injected for parallel execution patterns

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_PATH="$PROJECT_ROOT/.claude/hooks/selective-subagent-context-injector.sh"

echo "=== Testing Selective Context Injection Hook ==="
echo "Hook path: $HOOK_PATH"
echo ""

# Make hook executable
chmod +x "$HOOK_PATH"

# Clear detection log
rm -f /tmp/claude-hook-detections.log

# Test 1: Single agent task (should NOT inject context)
test_single_agent() {
    echo "Test 1: Single Agent Task (No Injection Expected)"
    
    local json='{
        "tool_name": "Task",
        "tool_input": {
            "prompt": "Please analyze this single file and provide feedback",
            "description": "Simple file analysis task"
        }
    }'
    
    echo "Input: $json"
    local output=$(echo "$json" | bash "$HOOK_PATH")
    echo "Output: $output"
    
    if [[ "$output" == '{"continue": true}' ]]; then
        echo "✓ PASS: No context injection for single agent task"
    else
        echo "✗ FAIL: Context was injected when it shouldn't have been"
    fi
    echo ""
}

# Test 2: Parallel keyword in prompt (should inject context)
test_parallel_keyword() {
    echo "Test 2: Parallel Keyword Detection (Injection Expected)"
    
    local json='{
        "tool_name": "Task",
        "tool_input": {
            "prompt": "Execute this task in parallel with other agents for comprehensive analysis",
            "description": "Multi-agent coordination task"
        }
    }'
    
    echo "Input: $json"
    local output=$(echo "$json" | bash "$HOOK_PATH")
    
    if echo "$output" | jq -r '.tool_input.prompt' | grep -q "Auto-Loaded Project Context"; then
        echo "✓ PASS: Context injected for parallel execution"
    else
        echo "✗ FAIL: Context not injected despite parallel keyword"
    fi
    echo ""
}

# Test 3: Code review command (should inject context)
test_code_review() {
    echo "Test 3: Code Review Command (Injection Expected)"
    
    local json='{
        "tool_name": "Task",
        "tool_input": {
            "prompt": "You are Security_Auditor. Perform comprehensive code security analysis focusing on...",
            "description": "Security review agent"
        }
    }'
    
    echo "Input: $json"
    local output=$(echo "$json" | bash "$HOOK_PATH")
    
    if echo "$output" | jq -r '.tool_input.prompt' | grep -q "Auto-Loaded Project Context"; then
        echo "✓ PASS: Context injected for code review agent"
    else
        echo "✗ FAIL: Context not injected for multi-agent command"
    fi
    echo ""
}

# Test 4: Simple question (should NOT inject context)
test_simple_question() {
    echo "Test 4: Simple Question (No Injection Expected)"
    
    local json='{
        "tool_name": "Task",
        "tool_input": {
            "prompt": "What is the purpose of this function?",
            "description": "Code understanding question"
        }
    }'
    
    echo "Input: $json"
    local output=$(echo "$json" | bash "$HOOK_PATH")
    
    if [[ "$output" == '{"continue": true}' ]]; then
        echo "✓ PASS: No context injection for simple question"
    else
        echo "✗ FAIL: Context was injected unnecessarily"
    fi
    echo ""
}

# Test 5: Refactoring investigation (should inject context)
test_refactoring() {
    echo "Test 5: Refactoring Investigation (Injection Expected)"
    
    local json='{
        "tool_name": "Task",
        "tool_input": {
            "prompt": "Investigation Area: Database Layer - Analyze current implementation and synthesize refactoring plan",
            "description": "Refactoring analysis"
        }
    }'
    
    echo "Input: $json"
    local output=$(echo "$json" | bash "$HOOK_PATH")
    
    if echo "$output" | jq -r '.tool_input.prompt' | grep -q "Auto-Loaded Project Context"; then
        echo "✓ PASS: Context injected for refactoring investigation"
    else
        echo "✗ FAIL: Context not injected for investigation task"
    fi
    echo ""
}

# Test 6: MCP tool (should pass through)
test_mcp_tool() {
    echo "Test 6: MCP Tool (Pass Through Expected)"
    
    local json='{
        "tool_name": "mcp__task-master__get_tasks",
        "tool_input": {
            "projectRoot": "/Users/davidbeyer/Infra5"
        }
    }'
    
    echo "Input: $json"
    local output=$(echo "$json" | bash "$HOOK_PATH")
    
    if [[ "$output" == '{"continue": true}' ]]; then
        echo "✓ PASS: MCP tool passed through unchanged"
    else
        echo "✗ FAIL: MCP tool was modified"
    fi
    echo ""
}

# Show detection log
show_detection_log() {
    echo "=== Pattern Detection Log ==="
    if [[ -f /tmp/claude-hook-detections.log ]]; then
        cat /tmp/claude-hook-detections.log
    else
        echo "No detections logged"
    fi
    echo ""
}

# Run all tests
main() {
    test_single_agent
    test_parallel_keyword
    test_code_review
    test_simple_question
    test_refactoring
    test_mcp_tool
    
    show_detection_log
    
    echo "=== Summary ==="
    echo "The selective hook should only inject context when parallel execution patterns are detected."
    echo "This prevents unnecessary token bloat for simple single-agent tasks."
}

main "$@"