#!/bin/bash
# Simple test script for cycle-plan context awareness

set -euo pipefail

echo "=== Testing Cycle-Plan Context Awareness Implementation ==="

# Define file path
CYCLE_PLAN_FILE="$HOME/.claude/commands/cycle-plan-[Opus].md"

# Test 1: Check if file exists
echo -e "\nTest 1: Checking if cycle-plan file exists..."
if [[ -f "$CYCLE_PLAN_FILE" ]]; then
    echo "✓ File exists"
else
    echo "✗ File not found: $CYCLE_PLAN_FILE"
    exit 1
fi

# Test 2: Check for AUTOMATED PROJECT DETECTION section
echo -e "\nTest 2: Checking for AUTOMATED PROJECT DETECTION section..."
if grep -q "AUTOMATED PROJECT DETECTION" "$CYCLE_PLAN_FILE"; then
    echo "✓ AUTOMATED PROJECT DETECTION section found"
else
    echo "✗ AUTOMATED PROJECT DETECTION section not found"
fi

# Test 3: Check for executable bash code (not just documentation)
echo -e "\nTest 3: Checking for executable detection code..."
if grep -A20 "AUTOMATED PROJECT DETECTION" "$CYCLE_PLAN_FILE" | grep -q 'test -f\|\[\[ -f'; then
    echo "✓ Found executable file detection code"
else
    echo "✗ No executable detection code found - only documentation"
    echo "  (Looking for 'test -f' or '[[ -f' commands)"
fi

# Test 4: Check for Bash tool usage instructions
echo -e "\nTest 4: Looking for Bash tool usage instructions..."
if grep -A30 "AUTOMATED PROJECT DETECTION" "$CYCLE_PLAN_FILE" | grep -q 'using Bash tool'; then
    echo "✓ Found Bash tool usage instructions"
else
    echo "✗ No Bash tool usage instructions found"
fi

# Test 5: Check if the detection logic actually runs commands
echo -e "\nTest 5: Checking if detection uses Claude tools (Bash, Read)..."
if grep -A50 "AUTOMATED PROJECT DETECTION" "$CYCLE_PLAN_FILE" | grep -q 'using Bash tool\|using Read tool\|Read tool'; then
    echo "✓ Instructions reference Claude tools"
else
    echo "✗ No references to Claude tools for execution"
fi

# Test 6: Verify current opening script content
echo -e "\nTest 6: Checking current opening script content..."
if grep -A5 "Generic Opening Script" "$CYCLE_PLAN_FILE" | grep -q "I'm in planning mode (no implementation)"; then
    echo "✓ Generic opening script found"
else
    echo "✗ Generic opening script not found or modified"
fi

# Summary based on Opus's critique
echo -e "\n=== CRITICAL ISSUES (per Opus review) ==="
echo "1. Implementation Status: The current 'implementation' is just documentation"
echo "2. Executable Code: No actual code that Claude will execute automatically"
echo "3. Test Evidence: No executable tests exist (this script is the first real test)"
echo "4. What's Needed: Actual Claude tool commands in the instruction flow"

echo -e "\n=== WHAT CORRECT IMPLEMENTATION LOOKS LIKE ==="
echo "The cycle-plan command should include instructions like:"
echo "1. Use Bash tool to check: [[ -f \"./CLAUDE.md\" ]]"
echo "2. Use Read tool to load: ./CLAUDE.md"
echo "3. Use conditional logic to choose opening script based on results"
echo ""
echo "NOT just markdown documentation about what to check!"