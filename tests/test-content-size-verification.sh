#!/bin/bash
# Content Size Verification Test
# Measures actual file sizes vs expected content injection to identify discrepancies

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Content Size Verification Test ==="
echo "Measuring actual file sizes vs hook injection behavior"
echo ""

# Function to measure actual file sizes
measure_actual_file_sizes() {
    echo "1. Measuring Actual File Sizes:"
    echo ""
    
    # Check the files referenced in the hook
    claude_file="$PROJECT_ROOT/CLAUDE.md"
    structure_file="$PROJECT_ROOT/docs/ai-context/project-structure.md"  
    docs_file="$PROJECT_ROOT/docs/ai-context/docs-overview.md"
    
    if [[ -f "$claude_file" ]]; then
        claude_size=$(wc -c < "$claude_file")
        claude_lines=$(wc -l < "$claude_file")
        echo "CLAUDE.md: $claude_size characters, $claude_lines lines"
    else
        echo "❌ CLAUDE.md not found at $claude_file"
    fi
    
    if [[ -f "$structure_file" ]]; then
        structure_size=$(wc -c < "$structure_file")
        structure_lines=$(wc -l < "$structure_file")
        echo "project-structure.md: $structure_size characters, $structure_lines lines"
    else
        echo "❌ project-structure.md not found at $structure_file"
    fi
    
    if [[ -f "$docs_file" ]]; then
        docs_size=$(wc -c < "$docs_file")
        docs_lines=$(wc -l < "$docs_file")
        echo "docs-overview.md: $docs_size characters, $docs_lines lines"
    else
        echo "❌ docs-overview.md not found at $docs_file"
    fi
    
    total_file_size=$((claude_size + structure_size + docs_size))
    echo ""
    echo "Total actual file content: $total_file_size characters"
    echo "Estimated tokens (chars/4): $((total_file_size / 4)) tokens"
    echo ""
}

# Function to test hook size impact  
test_hook_size_impact() {
    echo "2. Testing Hook Size Impact:"
    echo ""
    
    # Create test input
    test_json='{
        "tool_name": "Task", 
        "tool_input": {
            "prompt": "Measure content injection size",
            "description": "Size measurement test"
        }
    }'
    
    input_size=$(echo "$test_json" | wc -c)
    echo "Input JSON size: $input_size characters"
    
    # Process through debug hook
    output=$(echo "$test_json" | bash "$PROJECT_ROOT/.claude/hooks/debug-subagent-context-injector.sh")
    output_size=$(echo "$output" | wc -c)
    
    echo "Output JSON size: $output_size characters"
    echo "Size increase from hook: $((output_size - input_size)) characters"
    echo ""
    
    # Extract the modified prompt to see what was actually added
    modified_prompt=$(echo "$output" | jq -r '.tool_input.prompt')
    prompt_size=$(echo "$modified_prompt" | wc -c)
    
    echo "Modified prompt size: $prompt_size characters"
    echo "Context injection added: $((prompt_size - 26)) characters" # 26 is original prompt size
    echo ""
}

# Function to analyze @ reference impact
analyze_reference_impact() {
    echo "3. Analyzing @ Reference Impact:"
    echo ""
    
    # Count @ references in the hook's context injection
    context_injection="## Auto-Loaded Project Context

This sub-agent has automatic access to the following project documentation:
- @$PROJECT_ROOT/CLAUDE.md (Project overview, coding standards, and AI instructions)
- @$PROJECT_ROOT/docs/ai-context/project-structure.md (Complete file tree and tech stack)
- @$PROJECT_ROOT/docs/ai-context/docs-overview.md (Documentation architecture)

---

## Your Task

"
    
    reference_count=$(echo "$context_injection" | grep -o "@" | wc -l)
    context_size=$(echo "$context_injection" | wc -c)
    
    echo "Context injection template size: $context_size characters"
    echo "@ references in template: $reference_count"
    echo ""
    
    # If @ references auto-expand, calculate expected expansion
    echo "Expected @ reference expansion:"
    echo "- Each @ reference loads full file content"
    echo "- 3 files × average size = significant token usage"
    echo "- Hook template ($context_size chars) + file content = total context"
    echo ""
}

# Function to identify discrepancies
identify_discrepancies() {
    echo "4. Identifying Discrepancies:"
    echo ""
    
    # Expected vs actual calculations
    expected_file_content=$((total_file_size))
    expected_context_injection=416  # From our measurements
    expected_total=$((expected_file_content + expected_context_injection))
    
    echo "Expected Breakdown:"
    echo "- File content (if @ references expand): $expected_file_content characters"
    echo "- Context injection template: $expected_context_injection characters"  
    echo "- Expected total context: $expected_total characters"
    echo "- Expected tokens (chars/4): $((expected_total / 4)) tokens"
    echo ""
    
    echo "Actual Measurements (from plan):"
    echo "- Reported token usage: 27,500 tokens"
    echo "- Expected token usage: 6,200 tokens"
    echo "- Unexplained gap: 21,300 tokens"
    echo ""
    
    # Convert tokens to characters for comparison
    reported_chars=$((27500 * 4))
    expected_chars=$((6200 * 4))
    gap_chars=$((21300 * 4))
    
    echo "Character Equivalents:"
    echo "- Reported usage: $reported_chars characters"
    echo "- Expected usage: $expected_chars characters"
    echo "- Unexplained gap: $gap_chars characters"
    echo ""
    
    if [[ $expected_total -lt $expected_chars ]]; then
        echo "❓ Our file measurements ($expected_total chars) are less than expected ($expected_chars chars)"
        echo "   This suggests additional content or processing overhead"
    elif [[ $expected_total -gt $reported_chars ]]; then
        echo "❗ Our file measurements exceed reported usage - measurement error likely"
    else
        echo "✓ File measurements align with expected usage range"
    fi
}

# Main execution
main() {
    echo "Verifying content sizes to identify token bloat root cause..."
    echo ""
    
    # Initialize variables that will be used across functions
    claude_size=0
    structure_size=0
    docs_size=0
    total_file_size=0
    
    measure_actual_file_sizes
    test_hook_size_impact  
    analyze_reference_impact
    identify_discrepancies
    
    echo "=== Content Size Verification Complete ==="
    echo "Check analysis above for discrepancy identification"
}

# Execute main function
main "$@"