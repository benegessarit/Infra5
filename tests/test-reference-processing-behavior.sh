#!/bin/bash
# @ Reference Processing Behavior Test
# Isolates and analyzes how Claude Code processes @ references to identify duplication patterns

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== @ Reference Processing Behavior Test ==="
echo "Analyzing @ reference expansion and potential duplication patterns"
echo ""

# Function to test different @ reference formats
test_reference_formats() {
    echo "1. Testing Different @ Reference Formats:"
    echo ""
    
    # Test 1: Absolute path @ reference
    test_absolute_reference() {
        echo "Test 1a: Absolute Path @ Reference"
        
        absolute_json='{
            "tool_name": "Task",
            "tool_input": {
                "prompt": "Please read @/Users/davidbeyer/Infra5/CLAUDE.md and summarize it",
                "description": "Absolute path test"
            }
        }'
        
        echo "Input: Absolute @ reference to CLAUDE.md"
        echo "Processing through debug hook..."
        
        output=$(echo "$absolute_json" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
        output_size=$(echo "$output" | wc -c)
        
        # Count @ references in output
        ref_count=$(echo "$output" | grep -o "@" | wc -l)
        
        echo "Output size: $output_size characters"
        echo "@ references in output: $ref_count"
        echo ""
    }
    
    # Test 2: Variable-based @ reference (like our hook uses)
    test_variable_reference() {
        echo "Test 1b: Variable-Based @ Reference"
        
        variable_json='{
            "tool_name": "Task", 
            "tool_input": {
                "prompt": "Test with variable reference",
                "description": "Variable path test"
            }
        }'
        
        echo "Input: Variable @ references (from hook injection)"
        echo "Processing through debug hook..."
        
        output=$(echo "$variable_json" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
        output_size=$(echo "$output" | wc -c)
        
        # Extract the actual @ references added by hook
        modified_prompt=$(echo "$output" | jq -r '.tool_input.prompt')
        echo "Modified prompt excerpt:"
        echo "$modified_prompt" | head -10
        echo "..."
        
        # Count @ references in final output
        ref_count=$(echo "$output" | grep -o "@" | wc -l)
        
        echo "Output size: $output_size characters"
        echo "@ references in output: $ref_count"
        echo ""
    }
    
    # Test 3: No @ references (control)
    test_no_references() {
        echo "Test 1c: No @ References (Control)"
        
        control_json='{
            "tool_name": "Task",
            "tool_input": {
                "prompt": "Simple prompt with no file references",
                "description": "Control test"
            }
        }'
        
        echo "Input: No original @ references"
        echo "Processing through debug hook..."
        
        output=$(echo "$control_json" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
        output_size=$(echo "$output" | wc -c)
        ref_count=$(echo "$output" | grep -o "@" | wc -l)
        
        echo "Output size: $output_size characters"
        echo "@ references in output: $ref_count"
        echo ""
    }
    
    test_absolute_reference
    test_variable_reference  
    test_no_references
}

# Function to analyze @ reference expansion impact
analyze_expansion_impact() {
    echo "2. Analyzing @ Reference Expansion Impact:"
    echo ""
    
    # Create a minimal file for controlled testing
    test_file="$PROJECT_ROOT/test-reference-file.txt"
    echo "This is a test file for @ reference analysis. It contains exactly 100 characters to measure." > "$test_file"
    
    test_file_size=$(wc -c < "$test_file")
    echo "Created test file: $test_file ($test_file_size characters)"
    
    # Test with single @ reference to our test file
    single_ref_json='{
        "tool_name": "Task",
        "tool_input": {
            "prompt": "Please analyze @'$PROJECT_ROOT'/test-reference-file.txt for this test",
            "description": "Single reference test"
        }
    }'
    
    echo "Testing single @ reference to test file..."
    output=$(echo "$single_ref_json" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
    
    # Analyze the output
    output_size=$(echo "$output" | wc -c)
    modified_prompt=$(echo "$output" | jq -r '.tool_input.prompt')
    prompt_size=$(echo "$modified_prompt" | wc -c)
    
    echo "Single @ reference results:"
    echo "- Output JSON size: $output_size characters"
    echo "- Modified prompt size: $prompt_size characters"
    echo "- Test file size: $test_file_size characters"
    echo "- Expected expansion factor: If @ reference expands to full content"
    echo ""
    
    # Clean up test file
    rm -f "$test_file"
}

# Function to compare expansion behavior
compare_expansion_behavior() {
    echo "3. Comparing @ Reference vs Direct Content:"
    echo ""
    
    # Test A: Using @ reference
    reference_test='{
        "tool_name": "Task",
        "tool_input": {
            "prompt": "Analyze project using @'$PROJECT_ROOT'/CLAUDE.md",
            "description": "Reference expansion test"
        }
    }'
    
    echo "Test A: Using @ reference to CLAUDE.md"
    ref_output=$(echo "$reference_test" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
    ref_size=$(echo "$ref_output" | wc -c)
    echo "Output size with @ reference: $ref_size characters"
    
    # Test B: Including actual file content directly  
    claude_content=$(cat "$PROJECT_ROOT/CLAUDE.md")
    direct_test=$(jq -n --arg content "$claude_content" '{
        "tool_name": "Task",
        "tool_input": {
            "prompt": ("Analyze project using this content: " + $content),
            "description": "Direct content test"
        }
    }')
    
    echo "Test B: Including CLAUDE.md content directly"
    direct_output=$(echo "$direct_test" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
    direct_size=$(echo "$direct_output" | wc -c)
    echo "Output size with direct content: $direct_size characters"
    
    echo ""
    echo "Comparison:"
    echo "- @ reference method: $ref_size characters"
    echo "- Direct content method: $direct_size characters"
    echo "- Difference: $((ref_size - direct_size)) characters"
    
    if [[ $ref_size -gt $direct_size ]]; then
        echo "🔍 @ reference produces larger output - possible expansion overhead"
    elif [[ $ref_size -lt $direct_size ]]; then
        echo "🔍 @ reference produces smaller output - may not be expanding in hook"
    else
        echo "🔍 @ reference and direct content produce same size"
    fi
    echo ""
}

# Function to identify duplication patterns
identify_duplication_patterns() {
    echo "4. Identifying Duplication Patterns:"
    echo ""
    
    # Create a test with multiple identical @ references
    duplicate_test='{
        "tool_name": "Task",
        "tool_input": {
            "prompt": "Compare @'$PROJECT_ROOT'/CLAUDE.md with @'$PROJECT_ROOT'/CLAUDE.md and also @'$PROJECT_ROOT'/CLAUDE.md",
            "description": "Duplication pattern test"
        }
    }'
    
    echo "Testing multiple identical @ references..."
    dup_output=$(echo "$duplicate_test" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
    dup_size=$(echo "$dup_output" | wc -c)
    
    # Count @ references
    dup_ref_count=$(echo "$dup_output" | grep -o "@$PROJECT_ROOT/CLAUDE.md" | wc -l)
    
    echo "Multiple @ reference results:"
    echo "- Output size: $dup_size characters"
    echo "- @ references to CLAUDE.md found: $dup_ref_count"
    echo "- Expected if no deduplication: 3 references"
    echo ""
    
    # Calculate potential expansion
    claude_size=$(wc -c < "$PROJECT_ROOT/CLAUDE.md")
    echo "CLAUDE.md actual size: $claude_size characters"
    echo "If each @ reference expands to full content:"
    echo "- Single reference: ~$claude_size characters"
    echo "- Triple reference: ~$((claude_size * 3)) characters" 
    echo "- Plus hook context injection: ~$((claude_size * 3 + 416)) characters"
    echo ""
}

# Main execution
main() {
    echo "Testing @ reference processing to understand token bloat mechanism..."
    echo ""
    
    test_reference_formats
    analyze_expansion_impact
    compare_expansion_behavior
    identify_duplication_patterns
    
    echo "=== @ Reference Processing Analysis Complete ==="
    echo "Key findings documented above for root cause identification"
}

# Execute main function
main "$@"