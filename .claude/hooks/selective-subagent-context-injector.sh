#!/bin/bash
# Selective Sub-Agent Context Auto-Loader
# Modified version that only injects context for parallel execution patterns
#
# This hook detects parallel execution patterns and selectively applies context injection
# to avoid unnecessary token bloat for single-agent operations.
#
# Detection patterns:
# - Multiple Task tool invocations in parallel (commands mention this)
# - Keywords in prompts: "parallel", "concurrent", "multiple agents"
# - Specific command patterns that use multi-agent strategies

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Debug logging configuration
LOG_FILE="/tmp/claude-hook-selective-$(date +%Y%m%d).log"
DETECTION_LOG="/tmp/claude-hook-detections.log"

# Log execution with timestamp
echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook executed" >> "$LOG_FILE"

# Read input from stdin
INPUT_JSON=$(cat)

# Extract tool information
tool_name=$(echo "$INPUT_JSON" | jq -r '.tool_name // ""')

# Only process Task tool calls - pass through all other tools unchanged
if [[ "$tool_name" != "Task" ]]; then
    echo "Non-Task tool passed through: $tool_name" >> "$LOG_FILE"
    echo '{"continue": true}'
    exit 0
fi

# Extract current prompt and description from the Task tool input
current_prompt=$(echo "$INPUT_JSON" | jq -r '.tool_input.prompt // ""')
description=$(echo "$INPUT_JSON" | jq -r '.tool_input.description // ""')

# Function to detect parallel execution patterns
detect_parallel_execution() {
    local prompt="$1"
    local desc="$2"
    
    # Pattern 1: Keywords in prompt or description indicating parallel execution
    if echo "$prompt $desc" | grep -qiE 'parallel|concurrent|multiple.*agent|sub-agent|multi-agent|simultaneous'; then
        echo "Pattern detected: Parallel execution keywords" >> "$DETECTION_LOG"
        return 0
    fi
    
    # Pattern 2: Commands that typically use parallel execution
    if echo "$prompt" | grep -qiE 'code.*review|security.*analysis|performance.*analysis|architecture.*review|comprehensive.*analysis|focused.*analysis'; then
        echo "Pattern detected: Multi-agent command type" >> "$DETECTION_LOG"
        return 0
    fi
    
    # Pattern 3: Explicit agent role assignments (from command templates)
    if echo "$prompt" | grep -qiE 'Code_Analyzer|Security_Auditor|Performance_Optimizer|Architecture_Reviewer|Tech_Stack_Identifier|Doc_Validator'; then
        echo "Pattern detected: Agent role assignment" >> "$DETECTION_LOG"
        return 0
    fi
    
    # Pattern 4: Investigation or analysis tasks that spawn multiple agents
    if echo "$prompt" | grep -qiE 'investigate.*analyze|analyze.*investigate|spawn.*agent|launch.*agent'; then
        echo "Pattern detected: Investigation/analysis task" >> "$DETECTION_LOG"
        return 0
    fi
    
    # Pattern 5: Refactoring command pattern
    if echo "$prompt" | grep -qiE 'refactor.*investigation|investigation.*area|synthesize.*analysis'; then
        echo "Pattern detected: Refactoring investigation" >> "$DETECTION_LOG"
        return 0
    fi
    
    # No parallel pattern detected
    return 1
}

# Check if this is a parallel execution scenario
if detect_parallel_execution "$current_prompt" "$description"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - PARALLEL EXECUTION DETECTED - Injecting context" >> "$LOG_FILE"
    echo "Prompt snippet: ${current_prompt:0:100}..." >> "$LOG_FILE"
    
    # Build context injection header with project documentation references
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
    
    # Update the input JSON with the modified prompt
    output_json=$(echo "$INPUT_JSON" | jq --arg new_prompt "$modified_prompt" '.tool_input.prompt = $new_prompt')
    
    # Log metrics
    echo "Context injected: $(echo "$context_injection" | wc -c) characters" >> "$LOG_FILE"
    echo "Total size increase: $(($(echo "$output_json" | wc -c) - $(echo "$INPUT_JSON" | wc -c))) characters" >> "$LOG_FILE"
    echo "---" >> "$LOG_FILE"
    
    # Output the modified JSON for Claude Code to process
    echo "$output_json"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - NO PARALLEL PATTERN - Passing through unchanged" >> "$LOG_FILE"
    echo "Prompt snippet: ${current_prompt:0:100}..." >> "$LOG_FILE"
    echo "---" >> "$LOG_FILE"
    
    # Pass through unchanged for single-agent tasks
    echo '{"continue": true}'
fi