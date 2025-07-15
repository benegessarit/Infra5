#!/bin/bash
# Debug-Enabled Sub-Agent Context Auto-Loader
# Enhanced version of the original hook with comprehensive logging and metrics
#
# This debug hook provides detailed insights into:
# - Hook execution frequency and timing
# - Input/output JSON sizes and content analysis  
# - @ reference processing behavior
# - Tool type interactions (regular vs MCP tools)
# - JSON processing integrity verification

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Debug logging configuration
LOG_FILE="/tmp/claude-hook-debug-$(date +%Y%m%d).log"
EXECUTION_COUNT_FILE="/tmp/claude-hook-executions.count"

# Log execution with timestamp - TEST METRIC: Hook execution frequency
echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook executed" >> "$LOG_FILE"

# Count executions - TEST METRIC: Execution frequency tracking
echo $(($(cat "$EXECUTION_COUNT_FILE" 2>/dev/null || echo 0) + 1)) > "$EXECUTION_COUNT_FILE"

# Read input from stdin
INPUT_JSON=$(cat)

# Log input details - TEST METRIC: Content size verification
echo "Input JSON size: $(echo "$INPUT_JSON" | wc -c) characters" >> "$LOG_FILE"
echo "Tool name: $(echo "$INPUT_JSON" | jq -r '.tool_name // ""')" >> "$LOG_FILE"
echo "Original prompt size: $(echo "$INPUT_JSON" | jq -r '.tool_input.prompt // ""' | wc -c)" >> "$LOG_FILE"

# Extract tool information
tool_name=$(echo "$INPUT_JSON" | jq -r '.tool_name // ""')

# Only process Task tool calls - pass through all other tools unchanged
if [[ "$tool_name" != "Task" ]]; then
    echo "Non-Task tool passed through: $tool_name" >> "$LOG_FILE"
    echo '{"continue": true}'
    exit 0
fi

# Extract current prompt from the Task tool input
current_prompt=$(echo "$INPUT_JSON" | jq -r '.tool_input.prompt // ""')

# Build context injection header with project documentation references
# CRITICAL: Fixed incorrect path - CLAUDE.md is at root, not in docs/
context_injection="## Auto-Loaded Project Context

This sub-agent has automatic access to the following project documentation:
- @$PROJECT_ROOT/CLAUDE.md (Project overview, coding standards, and AI instructions)
- @$PROJECT_ROOT/docs/ai-context/project-structure.md (Complete file tree and tech stack)
- @$PROJECT_ROOT/docs/ai-context/docs-overview.md (Documentation architecture)

---

## Your Task

"

# Combine context injection with original prompt
modified_prompt="${context_injection}${current_prompt}"

# Update the input JSON with the modified prompt - TEST METRIC: JSON processing integrity
output_json=$(echo "$INPUT_JSON" | jq --arg new_prompt "$modified_prompt" '.tool_input.prompt = $new_prompt')

# Log output details - TEST METRIC: Content size verification and token impact
echo "Modified prompt size: $(echo "$modified_prompt" | wc -c) characters" >> "$LOG_FILE"
echo "Output JSON size: $(echo "$output_json" | wc -c) characters" >> "$LOG_FILE"
echo "Size increase: $(($(echo "$output_json" | wc -c) - $(echo "$INPUT_JSON" | wc -c))) characters" >> "$LOG_FILE"
echo "Context injection size: $(echo "$context_injection" | wc -c) characters" >> "$LOG_FILE"
echo "@ references count: 3" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"

# Output the modified JSON for Claude Code to process
echo "$output_json"