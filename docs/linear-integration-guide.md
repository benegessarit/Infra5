# Linear Integration Guide for Cycle Commands

## Overview
This guide provides the complete integration patterns for adding Linear context awareness to all cycle commands.

## Core Utilities Created

### 1. Linear State Resolver (`src/utils/linear-state-resolver.ts`)
- Dynamically resolves state IDs by name
- Eliminates hardcoded state IDs
- Usage: `await getLinearStateId(teamId, 'In Progress', mcp__linear-server__list_issue_statuses)`

### 2. Linear Context Reader (`src/utils/linear-context-reader.ts`)
- Reads `.linear-context.json` from filesystem
- Returns null when no context exists
- Usage: `const linearContext = await readLinearContext()`

### 3. Cycle File Organizer (`src/utils/cycle-file-organizer.ts`)
- Handles both directory structures
- Pattern-based file discovery
- Usage: `const dir = await organizer.getCycleDirectory(linearContext, date)`

## Integration Patterns

### Pattern 1: Linear Context Detection
Add at the beginning of each command:
```javascript
// Linear context detection
let linearContext = null;
try {
  if (fs.existsSync('.linear-context.json')) {
    const data = fs.readFileSync('.linear-context.json', 'utf-8');
    linearContext = JSON.parse(data);
    console.log(`Linear context found: ${linearContext.identifier}`);
  }
} catch (e) {
  console.log('No Linear context - using traditional flow');
}
```

### Pattern 2: Dynamic State Resolution
Replace hardcoded state IDs:
```javascript
// OLD: stateId: 'hardcoded-uuid'
// NEW:
const teamId = issue.team.id;
const states = await mcp__linear-server__list_issue_statuses({ teamId });
const targetState = states.find(s => s.name === 'In Progress');
if (!targetState) throw new Error('State not found');

await mcp__linear-server__update_issue(issueId, { 
  stateId: targetState.id 
});
```

### Pattern 3: Directory Structure Support
Update file operations:
```javascript
// Determine directory based on context
const dateDir = new Date().toISOString().split('T')[0];
const cycleDir = linearContext 
  ? `cycles/${linearContext.identifier}/${dateDir}`
  : `cycles/${dateDir}`;

// Create directory if needed
fs.mkdirSync(cycleDir, { recursive: true });

// Save files
const filePath = `${cycleDir}/${timestamp}-${topic}-plan.md`;
```

### Pattern 4: File Discovery Updates
Update pattern matching:
```javascript
// Find files in both structures
const patterns = linearContext
  ? [`cycles/${linearContext.identifier}/${date}/*-plan.md`]
  : [`cycles/${date}/*-plan.md`];

// Also check for files in issue directories when no context
if (!linearContext) {
  // Check common issue prefixes
  const issueDirs = fs.readdirSync('cycles')
    .filter(d => d.match(/^[A-Z]+-\d+$/));
  
  for (const issueDir of issueDirs) {
    patterns.push(`cycles/${issueDir}/${date}/*-plan.md`);
  }
}
```

### Pattern 5: Linear Comment Integration
Add after major operations:
```javascript
if (linearContext) {
  await mcp__linear-server__create_comment({
    issueId: linearContext.issueId,
    body: `📋 Cycle plan created: ${planTitle}\n\nView: ${filePath}`
  });
}
```

## Command-Specific Updates

### cycle-start-[Sonnet].md
1. Add Linear context detection after timestamp
2. Replace hardcoded state ID (line ~66)
3. Update plan finding logic to check both directories
4. Include Linear context in checkpoint metadata

### cycle-complete-[Sonnet].md
1. Add Linear context detection at start
2. Replace hardcoded state ID (line ~47)
3. Read Linear context from checkpoint if not in filesystem

### cycle-plan-[Opus].md
1. Add Linear context detection after project detection
2. Update directory creation logic in file saving
3. Add Linear comment after saving plan
4. Include Linear context in checkpoint metadata

### cycle-log-[Sonnet].md
1. Add Linear context detection at start
2. Update checkpoint finding patterns
3. Save log to issue-based directory if context exists
4. Add Linear comment with implementation summary

### cycle-check-[Opus].md
1. Add Linear context detection at start
2. Update file finding patterns for both structures
3. Include Linear context in progress updates

## Testing the Integration

1. Create a test `.linear-context.json`:
```json
{
  "issueId": "test-uuid",
  "identifier": "TEST-123",
  "title": "Test Integration",
  "teamId": "team-uuid",
  "gitBranch": "user/test-123"
}
```

2. Run cycle commands and verify:
   - Files saved to `cycles/TEST-123/YYYY-MM-DD/`
   - No hardcoded state IDs used
   - Commands work without Linear context too

## Rollout Strategy

1. **Phase 1**: Update state IDs (critical fix)
   - cycle-start: Dynamic state resolution
   - cycle-complete: Dynamic state resolution

2. **Phase 2**: Add context reading
   - All commands: Linear context detection
   - All commands: Directory structure support

3. **Phase 3**: Add Linear comments
   - cycle-plan: Plan creation comment
   - cycle-log: Implementation summary
   - cycle-check: Progress updates

4. **Phase 4**: Full integration testing
   - Test with real Linear issues
   - Verify backward compatibility