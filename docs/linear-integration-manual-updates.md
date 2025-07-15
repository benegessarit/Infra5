# Manual Updates Required for Linear Integration

This document outlines the manual changes needed to complete the Linear integration in the cycle commands.

## 1. cycle-start Command Updates

### Add Linear Context Detection (after step 1, before step 2)

```javascript
1b. **Linear Context Detection** (NEW):
   ```javascript
   // Try to read Linear context from filesystem
   let linearContext = null;
   try {
     const contextData = await fs.readFile('.linear-context.json', 'utf-8');
     linearContext = JSON.parse(contextData);
     console.log(`Found Linear context: ${linearContext.identifier}`);
   } catch (e) {
     console.log('No Linear context - using traditional flow');
   }
   ```
```

### Add Dynamic State Resolution (in step 1a, before update call)

Replace the existing update with:

```javascript
# Get team ID and resolve state dynamically
teamId = issue.team.id

# Get available states for the team
states = await mcp__linear-server__list_issue_statuses({ teamId })

# Find "In Progress" state
inProgressState = states.find(s => s.name === 'In Progress')
if (!inProgressState) {
  console.warn('Could not find "In Progress" state, skipping status update')
} else {
  # Update with resolved state ID
  mcp__linear-server__update_issue(issueId, { 
    stateId: inProgressState.id
  })
}
```

### Update File Discovery (step 2)

Replace existing with:

```javascript
2. Find latest plan:
   ```javascript
   // Determine directory based on Linear context
   const dateDir = new Date().toISOString().split('T')[0];
   const cycleDir = linearContext 
     ? `cycles/${linearContext.identifier}/${dateDir}`
     : `cycles/${dateDir}`;
   
   // Find latest plan file
   const planPattern = `${cycleDir}/*-plan.md`;
   const latestPlan = await findLatestFile(planPattern);
   ```
```

## 2. cycle-complete Command Updates

### Add Linear Context Detection (at the beginning)

```javascript
### 1. Detect Current Cycle

1. **Linear Context Detection** (NEW):
   ```javascript
   let linearContext = null;
   try {
     const contextData = await fs.readFile('.linear-context.json', 'utf-8');
     linearContext = JSON.parse(contextData);
   } catch (e) {
     // No Linear context
   }
   ```

2. Find current checkpoint:
   ```javascript
   const dateDir = new Date().toISOString().split('T')[0];
   const cycleDir = linearContext 
     ? `cycles/${linearContext.identifier}/${dateDir}`
     : `cycles/${dateDir}`;
   const checkpointPattern = `${cycleDir}/*-checkpoint.json`;
   ```
```

### Add Dynamic State Resolution (in step 2)

Replace the state update section with:

```javascript
# Update Linear status to "In Review"
# First get the team ID
teamId = checkpoint.gitWorkflowMetadata?.teamId || 
         (await mcp__linear-server__get_issue(issueId)).team.id

# Get available states
states = await mcp__linear-server__list_issue_statuses({ teamId })

# Find "In Review" state
inReviewState = states.find(s => s.name === 'In Review')
if (!inReviewState) {
  console.warn('Could not find "In Review" state, skipping status update')
} else {
  mcp__linear-server__update_issue(issueId, {
    stateId: inReviewState.id
  })
}
```

## 3. cycle-plan Command Updates

### Add Linear Context Detection (after step 1)

```javascript
1a. **Linear Context Detection** (NEW):
   ```javascript
   let linearContext = null;
   try {
     const contextData = await fs.readFile('.linear-context.json', 'utf-8');
     linearContext = JSON.parse(contextData);
     console.log(`Linear context found: ${linearContext.identifier}`);
   } catch (e) {
     console.log('No Linear context - using traditional flow');
   }
   ```
```

### Update File Saving (section 9)

```javascript
### 9. File Saving (CRITICAL - NEVER SKIP!)
**MUST DO FIRST**: Use Bash to get current date/time:
```bash
date '+%Y-%m-%d %H:%M:%S'
```

**THEN**:
1. Create directory:
   ```javascript
   const dateDir = date.split(' ')[0]; // YYYY-MM-DD
   const baseDir = linearContext 
     ? `cycles/${linearContext.identifier}/${dateDir}`
     : `cycles/${dateDir}`;
   await fs.mkdir(baseDir, { recursive: true });
   ```
2. Save as: `${baseDir}/${time}-${topic}-plan.md`
3. **Linear Comment** (NEW):
   ```javascript
   if (linearContext) {
     await mcp__linear-server__create_comment({
       issueId: linearContext.issueId,
       body: `📋 Cycle plan created: ${planTitle}\n\nPlan: ${baseDir}/${time}-${topic}-plan.md`
     });
   }
   ```
```

## 4. cycle-log Command Updates

### Add Linear Context Detection

```javascript
### 1. Setup
Add after timestamp:
```javascript
// Linear context detection
let linearContext = null;
try {
  const contextData = await fs.readFile('.linear-context.json', 'utf-8');
  linearContext = JSON.parse(contextData);
} catch (e) {
  // No Linear context
}

// Determine cycle directory
const dateDir = new Date().toISOString().split('T')[0];
const cycleDir = linearContext 
  ? `cycles/${linearContext.identifier}/${dateDir}`
  : `cycles/${dateDir}`;
```
```

### Update File Discovery

Replace checkpoint finding with:
```javascript
// Find latest checkpoint in appropriate directory
const checkpointFiles = await fs.readdir(cycleDir);
const checkpoints = checkpointFiles
  .filter(f => f.endsWith('-checkpoint.json'))
  .sort()
  .reverse();
const latestCheckpoint = checkpoints[0];
```

### Add Linear Comment (at the end)

```javascript
// Post Linear comment if context exists
if (linearContext && checkpoint.gitWorkflowMetadata) {
  const summary = `Tests: ${metrics.tests.passing}/${metrics.tests.written} | ` +
                  `TDD Cycles: ${metrics.implementation.tddCyclesCompleted}`;
  
  await mcp__linear-server__create_comment({
    issueId: linearContext.issueId,
    body: `📝 Implementation log created\n\n${summary}\n\nLog: ${logPath}`
  });
}
```

## 5. cycle-check Command Updates

Similar pattern to others - add Linear context detection and comments.

## Testing the Integration

1. Create a test `.linear-context.json`:
```json
{
  "issueId": "test-uuid-123",
  "identifier": "TEST-123",
  "title": "Test Linear Integration",
  "teamId": "team-123",
  "gitBranch": "test/linear-integration"
}
```

2. Run cycle commands and verify:
   - Files are created in `cycles/TEST-123/YYYY-MM-DD/`
   - State resolution works (check Linear API calls)
   - Comments are posted (check Linear issue)