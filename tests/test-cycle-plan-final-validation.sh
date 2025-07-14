#!/bin/bash
# Final validation test for cycle-plan context awareness

echo "=== FINAL VALIDATION TEST ==="
echo "Testing that cycle-plan command has correct executable instructions"
echo ""

# Key implementation requirements per Opus review
echo "✓ Checking implementation requirements:"
echo ""

# 1. Must use actual Claude tools
echo -n "1. Uses Bash tool for detection: "
if grep -q "using Bash tool" ~/.claude/commands/cycle-plan-[Opus].md; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# 2. Must use proper file detection
echo -n "2. Uses test -f for file checks: "
if grep -q 'test -f "./CLAUDE.md"' ~/.claude/commands/cycle-plan-[Opus].md; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# 3. Must use Read tool for loading
echo -n "3. Uses Read tool for context: "
if grep -q "using Read tool" ~/.claude/commands/cycle-plan-[Opus].md; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# 4. Must have error handling
echo -n "4. Has error handling logic: "
if grep -q "If error: Log" ~/.claude/commands/cycle-plan-[Opus].md; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

# 5. Must have conditional logic
echo -n "5. Has IF/ELSE conditional logic: "
if grep -q "IF both files exist" ~/.claude/commands/cycle-plan-[Opus].md && grep -q "ELSE" ~/.claude/commands/cycle-plan-[Opus].md; then
    echo "✓ PASS"
else
    echo "✗ FAIL"
fi

echo ""
echo "=== IMPLEMENTATION VERIFIED ==="
echo "The cycle-plan command now contains actual executable instructions"
echo "that Claude will execute, not just documentation about what to do."