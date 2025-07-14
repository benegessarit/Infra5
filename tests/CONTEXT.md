# Tests Directory - Resonance Framework Testing

## Purpose

The `tests/` directory contains validation scripts for the Resonance TDD framework and Claude Code AI Development system. These tests ensure command behaviors work correctly and maintain quality standards.

## Current Status: ACTIVE

Test coverage includes:
- Cycle-plan context awareness validation
- Command execution verification
- Tool usage detection
- Error handling scenarios

## Test Architecture

### Test Categories

#### Command Validation Tests
- **Purpose**: Verify Claude commands execute correctly
- **Approach**: Shell scripts that validate command files
- **Coverage**: Detection logic, tool usage, error handling

#### Integration Tests
- **Purpose**: Validate multi-component interactions
- **Approach**: End-to-end scenario testing
- **Coverage**: Command + hooks + context loading

## Current Test Suite

### cycle-plan Context Awareness Tests

#### test-cycle-plan-simple.sh
- **Purpose**: Basic validation of context detection
- **Tests**:
  1. File existence check
  2. Section presence validation
  3. Executable code detection (not just docs)
  4. Tool usage instruction verification
  5. Claude tool reference validation

#### test-cycle-plan-context.sh
- **Purpose**: Comprehensive context loading tests
- **Validation**: Full implementation validation with multiple scenarios

#### test-cycle-plan-final-validation.sh
- **Purpose**: Production readiness verification
- **Coverage**: All success criteria and edge cases

## Test Patterns

### Shell Script Pattern
```bash
#!/bin/bash
set -euo pipefail  # Fail on errors

# Test setup
echo "=== Testing [Feature] ==="

# Individual test cases
echo -e "\nTest N: [Description]..."
if [[ condition ]]; then
    echo "✓ Test passed"
else
    echo "✗ Test failed: [reason]"
    exit 1
fi

# Summary
echo -e "\n=== All tests passed! ==="
```

### Validation Approach
1. **Existence Checks**: Verify files/sections exist
2. **Content Validation**: Check for required patterns
3. **Executable Detection**: Ensure code, not just documentation
4. **Tool Usage**: Verify Claude tool integration
5. **Error Scenarios**: Test failure paths

## Key Testing Insights

### Lessons from Implementation
1. **Documentation vs Code**: Tests must verify executable code exists, not just documentation about code
2. **Tool Integration**: Validate actual Claude tool usage (Bash, Read, etc.)
3. **Pattern Matching**: Use appropriate grep patterns for content validation
4. **Exit Codes**: Proper error handling with exit codes

### Common Pitfalls Avoided
- Testing for markdown documentation instead of executable code
- Missing tool usage verification
- Incomplete error scenario coverage
- False positives from partial matches

## Test Execution

### Running Tests
```bash
# Individual test
./tests/test-cycle-plan-simple.sh

# All tests in sequence
for test in ./tests/test-*.sh; do
    echo "Running $test..."
    $test || exit 1
done
```

### Test Output Format
```
=== Testing [Feature] ===

Test 1: [Description]...
✓ Test passed

Test 2: [Description]...
✗ Test failed: [specific reason]
  (Additional context)

=== Summary ===
```

## Integration with Development Workflow

### TDD Cycle Integration
1. **RED Phase**: Write failing tests for new features
2. **GREEN Phase**: Implement until tests pass
3. **REFACTOR Phase**: Improve while maintaining green tests

### Continuous Validation
- Run tests before checkpoint commits
- Validate after command modifications
- Include in cycle-check validations

## Best Practices

### For Test Creation
1. **Clear Descriptions**: Name tests by what they validate
2. **Specific Assertions**: Check exact conditions
3. **Helpful Failures**: Provide context on failures
4. **Isolation**: Each test should be independent

### For Test Maintenance
1. **Update with Features**: Keep tests synchronized
2. **Remove Obsolete**: Clean up outdated tests
3. **Document Purpose**: Clear comments on intent
4. **Version Control**: Track test evolution

## Future Test Coverage

Based on system architecture, needed tests include:
- Hook execution validation
- Multi-agent orchestration tests
- Security scanner effectiveness
- Context injection verification
- Documentation generation quality

## Test Results Tracking

Test results integrate with:
- Checkpoint metrics in cycles/
- Evidence collection for TDD phases
- Quality gates in cycle-check
- Continuous improvement patterns

This testing framework ensures the Resonance system maintains high quality through evidence-based validation and continuous verification of all components.