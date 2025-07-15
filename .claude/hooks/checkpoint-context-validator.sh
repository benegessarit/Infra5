#!/bin/bash
# Checkpoint Context Metadata Validator Hook
# Ensures checkpoints include contextMetadata before being written
#
# This hook intercepts Write tool calls to checkpoint files and:
# 1. Validates that contextMetadata exists in the JSON
# 2. Blocks the write if contextMetadata is missing
# 3. Provides helpful error message to include the required structure
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Debug logging
LOG_FILE="/tmp/claude-checkpoint-validator-$(date +%Y%m%d).log"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Hook executed" >> "$LOG_FILE"

# Read input from stdin
INPUT_JSON=$(cat)

# Extract tool information
tool_name=$(echo "$INPUT_JSON" | jq -r '.tool_name // ""')
file_path=$(echo "$INPUT_JSON" | jq -r '.tool_input.file_path // ""')

# Only process Write tool calls
if [[ "$tool_name" != "Write" ]]; then
    echo "Non-Write tool passed through: $tool_name" >> "$LOG_FILE"
    echo '{"continue": true}'
    exit 0
fi

# Check if this is a checkpoint file write
if [[ ! "$file_path" =~ checkpoint\.json$ ]]; then
    echo "Non-checkpoint file passed through: $file_path" >> "$LOG_FILE"
    echo '{"continue": true}'
    exit 0
fi

# Extract the content being written
content=$(echo "$INPUT_JSON" | jq -r '.tool_input.content // ""')

# Try to parse as JSON and check for contextMetadata
has_context_metadata=$(echo "$content" | jq -e '.contextMetadata' > /dev/null 2>&1 && echo "true" || echo "false")

if [[ "$has_context_metadata" == "false" ]]; then
    echo "BLOCKED: Missing contextMetadata in checkpoint: $file_path" >> "$LOG_FILE"
    
    # Return error response that blocks the write
    cat <<EOF
{
  "continue": false,
  "error": "Checkpoint validation failed: Missing contextMetadata",
  "message": "⚠️ CHECKPOINT VALIDATION ERROR\n\nThis checkpoint is missing the required 'contextMetadata' field.\n\nPlease include the following structure in your checkpoint:\n\n\"contextMetadata\": {\n  \"capturedAt\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\n  \"autoLoadedDocs\": {\n    \"tier1\": [\n      {\n        \"path\": \"$PROJECT_ROOT/CLAUDE.md\",\n        \"checksum\": \"sha256-hash\",\n        \"lastModified\": \"timestamp\"\n      },\n      {\n        \"path\": \"$PROJECT_ROOT/docs/ai-context/project-structure.md\",\n        \"checksum\": \"sha256-hash\",\n        \"lastModified\": \"timestamp\"\n      },\n      {\n        \"path\": \"$PROJECT_ROOT/docs/ai-context/docs-overview.md\",\n        \"checksum\": \"sha256-hash\",\n        \"lastModified\": \"timestamp\"\n      }\n    ],\n    \"tier2\": [],\n    \"tier3\": []\n  },\n  \"commandContext\": {\n    \"command\": \"cycle-plan|cycle-start|etc\",\n    \"workingDirectory\": \"$PROJECT_ROOT\"\n  },\n  \"documentationSystem\": {\n    \"version\": \"3-tier\",\n    \"autoLoadEnabled\": true\n  }\n}\n\nThis ensures context preservation across cycle resumptions."
}
EOF
    exit 0
fi

echo "Checkpoint has contextMetadata, allowing write: $file_path" >> "$LOG_FILE"

# Pass through unchanged if validation passes
echo '{"continue": true}'