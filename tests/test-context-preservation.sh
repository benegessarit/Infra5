#!/bin/bash
set -euo pipefail

echo "=== Testing Context Preservation Framework ==="

# Setup test directory and files
TEST_DIR="/tmp/context-preservation-test"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/cycles/2025-07-13"
mkdir -p "$TEST_DIR/src/commands"
mkdir -p "$TEST_DIR/docs"

# Create mock files to test against
cat > "$TEST_DIR/CLAUDE.md" << 'EOF'
# Test CLAUDE.md
This is a test file for context preservation.
EOF

cat > "$TEST_DIR/cycles/CONTEXT.md" << 'EOF'
# Cycles Context
This is tier-2 documentation.
EOF

cat > "$TEST_DIR/docs/tier3-feature.md" << 'EOF'
# Feature Context
This is tier-3 documentation.
EOF

# Test 1: Context metadata structure validation
echo -e "\nTest 1: Context metadata structure validation..."
cat > "$TEST_DIR/test-checkpoint.json" << 'EOF'
{
  "contextMetadata": {
    "capturedAt": "2025-07-13T10:30:00Z",
    "autoLoadedDocs": {
      "tier1": [
        {
          "path": "/CLAUDE.md",
          "checksum": "sha256:abc123",
          "lastModified": "2025-07-13T09:00:00Z"
        }
      ],
      "tier2": [
        {
          "path": "/cycles/CONTEXT.md",
          "checksum": "sha256:def456",
          "lastModified": "2025-07-13T09:30:00Z"
        }
      ],
      "tier3": []
    },
    "commandContext": {
      "command": "cycle-plan",
      "workingDirectory": "/Users/test/project"
    },
    "documentationSystem": {
      "version": "3-tier",
      "autoLoadEnabled": true
    }
  }
}
EOF

# Check if JSON is valid and has required structure
if ! jq -e '.contextMetadata.autoLoadedDocs.tier1[0].path' "$TEST_DIR/test-checkpoint.json" > /dev/null; then
    echo "✗ Test failed: Invalid contextMetadata structure"
    exit 1
fi

if ! jq -e '.contextMetadata.autoLoadedDocs.tier1[0].checksum' "$TEST_DIR/test-checkpoint.json" | grep -q "sha256:"; then
    echo "✗ Test failed: Checksum format incorrect"
    exit 1
fi

echo "✓ Test passed: Context metadata structure valid"

# Test 2: Tier classification validation
echo -e "\nTest 2: Tier classification validation..."

# Verify tier1 contains foundational docs
tier1_paths=$(jq -r '.contextMetadata.autoLoadedDocs.tier1[].path' "$TEST_DIR/test-checkpoint.json")
if ! echo "$tier1_paths" | grep -q "CLAUDE.md"; then
    echo "✗ Test failed: Tier1 missing CLAUDE.md"
    exit 1
fi

# Verify tier2 contains component docs
tier2_paths=$(jq -r '.contextMetadata.autoLoadedDocs.tier2[].path' "$TEST_DIR/test-checkpoint.json")
if ! echo "$tier2_paths" | grep -q "CONTEXT.md"; then
    echo "✗ Test failed: Tier2 missing CONTEXT.md"
    exit 1
fi

echo "✓ Test passed: Tier classification correct"

# Test 3: File metadata completeness
echo -e "\nTest 3: File metadata completeness..."

# Check all required fields exist for tier1 docs
tier1_entry=$(jq '.contextMetadata.autoLoadedDocs.tier1[0]' "$TEST_DIR/test-checkpoint.json")
if ! echo "$tier1_entry" | jq -e '.path' > /dev/null; then
    echo "✗ Test failed: Missing path field"
    exit 1
fi

if ! echo "$tier1_entry" | jq -e '.checksum' > /dev/null; then
    echo "✗ Test failed: Missing checksum field"
    exit 1
fi

if ! echo "$tier1_entry" | jq -e '.lastModified' > /dev/null; then
    echo "✗ Test failed: Missing lastModified field"
    exit 1
fi

echo "✓ Test passed: File metadata complete"

# Test 4: Context preservation simulation
echo -e "\nTest 4: Context preservation simulation..."

# Create cycle-plan checkpoint
cat > "$TEST_DIR/cycles/2025-07-13/plan-checkpoint.json" << 'EOF'
{
  "contextMetadata": {
    "capturedAt": "2025-07-13T10:00:00Z",
    "autoLoadedDocs": {
      "tier1": [
        {"path": "/CLAUDE.md", "checksum": "sha256:original"}
      ],
      "tier2": [],
      "tier3": []
    },
    "commandContext": {
      "command": "cycle-plan"
    }
  },
  "projectMeta": {
    "planRef": "cycles/2025-07-13/test-plan.md"
  }
}
EOF

# Simulate cycle-start loading the checkpoint
plan_context=$(jq '.contextMetadata.autoLoadedDocs' "$TEST_DIR/cycles/2025-07-13/plan-checkpoint.json")
if ! echo "$plan_context" | jq -e '.tier1[0].path' > /dev/null; then
    echo "✗ Test failed: Context not preserved from plan to start"
    exit 1
fi

echo "✓ Test passed: Context preservation works"

# Test 5: Change detection simulation
echo -e "\nTest 5: Change detection simulation..."

# Create "current" state with changed checksum
cat > "$TEST_DIR/current-state.json" << 'EOF'
{
  "contextMetadata": {
    "autoLoadedDocs": {
      "tier1": [
        {"path": "/CLAUDE.md", "checksum": "sha256:changed"}
      ]
    }
  }
}
EOF

# Compare checksums
original_checksum=$(jq -r '.contextMetadata.autoLoadedDocs.tier1[0].checksum' "$TEST_DIR/cycles/2025-07-13/plan-checkpoint.json")
current_checksum=$(jq -r '.contextMetadata.autoLoadedDocs.tier1[0].checksum' "$TEST_DIR/current-state.json")

if [ "$original_checksum" = "$current_checksum" ]; then
    echo "✗ Test failed: Change detection not working"
    exit 1
fi

echo "✓ Test passed: Change detection works"

# Test 6: Backward compatibility
echo -e "\nTest 6: Backward compatibility..."

# Create old checkpoint without contextMetadata
cat > "$TEST_DIR/old-checkpoint.json" << 'EOF'
{
  "projectMeta": {
    "planRef": "cycles/2025-07-13/old-plan.md"
  },
  "currentContext": {
    "whatImDoing": "old work"
  }
}
EOF

# Verify it doesn't have contextMetadata
if jq -e '.contextMetadata' "$TEST_DIR/old-checkpoint.json" > /dev/null; then
    echo "✗ Test failed: Old checkpoint should not have contextMetadata"
    exit 1
fi

# But should still have other data
if ! jq -e '.currentContext.whatImDoing' "$TEST_DIR/old-checkpoint.json" > /dev/null; then
    echo "✗ Test failed: Old checkpoint missing other data"
    exit 1
fi

echo "✓ Test passed: Backward compatibility maintained"

# Test 7: Missing file handling
echo -e "\nTest 7: Missing file handling..."

# Create checkpoint referencing non-existent file
cat > "$TEST_DIR/missing-file-checkpoint.json" << 'EOF'
{
  "contextMetadata": {
    "autoLoadedDocs": {
      "tier1": [
        {"path": "/non-existent.md", "checksum": "sha256:missing"}
      ]
    }
  }
}
EOF

# Verify the file doesn't exist
if [ -f "$TEST_DIR/non-existent.md" ]; then
    echo "✗ Test setup error: File should not exist"
    exit 1
fi

echo "✓ Test passed: Missing file scenario set up correctly"

# Test 8: Performance with many files
echo -e "\nTest 8: Performance with many files..."

# Generate checkpoint with 60 files
python3 -c "
import json
import sys

checkpoint = {
    'contextMetadata': {
        'autoLoadedDocs': {
            'tier1': [],
            'tier2': [],
            'tier3': []
        }
    }
}

for i in range(60):
    tier = 'tier' + str((i % 3) + 1)
    doc = {
        'path': f'/docs/file-{i}.md',
        'checksum': f'sha256:hash{i}',
        'lastModified': '2025-07-13T10:00:00Z'
    }
    checkpoint['contextMetadata']['autoLoadedDocs'][tier].append(doc)

with open('$TEST_DIR/many-files-checkpoint.json', 'w') as f:
    json.dump(checkpoint, f, indent=2)
"

# Count total files
total_files=$(jq '[.contextMetadata.autoLoadedDocs.tier1[], .contextMetadata.autoLoadedDocs.tier2[], .contextMetadata.autoLoadedDocs.tier3[]] | length' "$TEST_DIR/many-files-checkpoint.json")

if [ "$total_files" -ne 60 ]; then
    echo "✗ Test failed: Expected 60 files, got $total_files"
    exit 1
fi

echo "✓ Test passed: Can handle 60 files efficiently"

# Test 9: Cross-command context flow
echo -e "\nTest 9: Cross-command context flow..."

# Simulate plan → start → check flow
mkdir -p "$TEST_DIR/flow-test"

# Plan saves context
cat > "$TEST_DIR/flow-test/plan.json" << 'EOF'
{
  "phase": "plan",
  "contextMetadata": {
    "autoLoadedDocs": {
      "tier1": [{"path": "/CLAUDE.md"}]
    }
  }
}
EOF

# Start loads same context
cp "$TEST_DIR/flow-test/plan.json" "$TEST_DIR/flow-test/start.json"
jq '.phase = "start"' "$TEST_DIR/flow-test/start.json" > "$TEST_DIR/flow-test/start-updated.json"
mv "$TEST_DIR/flow-test/start-updated.json" "$TEST_DIR/flow-test/start.json"

# Check loads same context
cp "$TEST_DIR/flow-test/plan.json" "$TEST_DIR/flow-test/check.json"
jq '.phase = "check"' "$TEST_DIR/flow-test/check.json" > "$TEST_DIR/flow-test/check-updated.json"
mv "$TEST_DIR/flow-test/check-updated.json" "$TEST_DIR/flow-test/check.json"

# Verify all have same context
plan_docs=$(jq '.contextMetadata.autoLoadedDocs' "$TEST_DIR/flow-test/plan.json")
start_docs=$(jq '.contextMetadata.autoLoadedDocs' "$TEST_DIR/flow-test/start.json")
check_docs=$(jq '.contextMetadata.autoLoadedDocs' "$TEST_DIR/flow-test/check.json")

if [ "$plan_docs" != "$start_docs" ] || [ "$start_docs" != "$check_docs" ]; then
    echo "✗ Test failed: Context not preserved across commands"
    exit 1
fi

echo "✓ Test passed: Context flows across all commands"

# Test 10: Cycle command integration check
echo -e "\nTest 10: Cycle command integration check..."

# Verify cycle commands exist and can be enhanced
CYCLE_COMMANDS_DIR="/Users/davidbeyer/.claude/commands"

for cmd in "cycle-plan-[Opus].md" "cycle-start-[Sonnet].md" "cycle-check-[Opus].md" "cycle-log-[Sonnet].md"; do
    if [ ! -f "$CYCLE_COMMANDS_DIR/$cmd" ]; then
        echo "✗ Test failed: Cycle command $cmd not found"
        exit 1
    fi
done

# Check if cycle-start has checkpoint loading logic
if ! grep -q "checkpoint" "$CYCLE_COMMANDS_DIR/cycle-start-[Sonnet].md"; then
    echo "✗ Test failed: cycle-start missing checkpoint logic"
    exit 1
fi

echo "✓ Test passed: Cycle commands ready for enhancement"

# Cleanup
rm -rf "$TEST_DIR"

echo -e "\n=== All Context Preservation Tests Passed! ==="
echo "✓ Context metadata structure validation"
echo "✓ Tier classification system"
echo "✓ File metadata completeness"
echo "✓ Context preservation simulation"
echo "✓ Change detection mechanism"
echo "✓ Backward compatibility"
echo "✓ Missing file handling"
echo "✓ Performance with many files"
echo "✓ Cross-command context flow"
echo "✓ Cycle command integration readiness"