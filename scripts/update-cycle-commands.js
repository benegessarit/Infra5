#!/usr/bin/env node

/**
 * Script to update cycle commands with Linear integration fixes
 * - Replaces hardcoded state IDs with dynamic resolution
 * - Adds Linear context file reading
 * - Updates file patterns for issue-based directories
 */

const fs = require('fs').promises;
const path = require('path');

async function updateCycleStart() {
  const filePath = '/Users/davidbeyer/.claude/commands/cycle-start-[Sonnet].md';
  let content = await fs.readFile(filePath, 'utf-8');
  
  // Replace hardcoded state ID with dynamic resolution
  const oldStateUpdate = `     # Update Linear status to "In Progress"
     mcp__linear-server__update_issue(issueId, { 
       stateId: 'e41cf207-0f8b-4f7b-82e0-b3471f212fe1'
     })`;
  
  const newStateUpdate = `     # Update Linear status to "In Progress"
     # Get team ID from issue
     teamId = issue.team.id
     
     # Dynamically resolve state ID
     states = mcp__linear-server__list_issue_statuses({ teamId })
     inProgressState = states.find(s => s.name === 'In Progress')
     
     # Update with resolved state ID
     mcp__linear-server__update_issue(issueId, { 
       stateId: inProgressState.id
     })`;
  
  content = content.replace(oldStateUpdate, newStateUpdate);
  
  // Add Linear context reading to step 2
  const findPlanStep = `2. Find latest plan: \`cycles/YYYY-MM-DD/HHMM-topic-plan.md\``;
  
  const newFindPlanStep = `1b. **Linear Context Detection** (NEW):
   - Check for Linear context file:
     \`\`\`bash
     # Try to read Linear context
     if [ -f ".linear-context.json" ]; then
       linearContext = JSON.parse(fs.readFileSync('.linear-context.json'))
       echo "Found Linear context for issue: $\{linearContext.identifier\}"
     else
       linearContext = null
       echo "No Linear context found - using traditional flow"
     fi
     \`\`\`
2. Find latest plan:
   - With Linear context: \`cycles/$\{linearContext.identifier\}/YYYY-MM-DD/HHMM-topic-plan.md\`
   - Without Linear context: \`cycles/YYYY-MM-DD/HHMM-topic-plan.md\``;
  
  content = content.replace(findPlanStep, newFindPlanStep);
  
  await fs.writeFile(filePath, content, 'utf-8');
  console.log('✅ Updated cycle-start command');
}

async function updateCycleComplete() {
  const filePath = '/Users/davidbeyer/.claude/commands/cycle-complete-[Sonnet].md';
  let content = await fs.readFile(filePath, 'utf-8');
  
  // Replace hardcoded state ID
  const oldStateId = `stateId: 'f5e57f51-9d1f-4e1f-a0eb-1dedc91ed393' // In Review`;
  
  const newStateResolution = `// Dynamically resolve state ID
      teamId = checkpoint.gitWorkflowMetadata.teamId || 
               (await mcp__linear-server__get_issue(issueId)).team.id
      
      states = await mcp__linear-server__list_issue_statuses({ teamId })
      inReviewState = states.find(s => s.name === 'In Review')
      
      stateId: inReviewState.id`;
  
  content = content.replace(oldStateId, newStateResolution);
  
  await fs.writeFile(filePath, content, 'utf-8');
  console.log('✅ Updated cycle-complete command');
}

async function createCyclePlanUpdate() {
  // Create a template for updating cycle-plan
  const template = `# Cycle-plan Linear Integration Update

Add this to the cycle-plan command after step 1 (automated project detection):

\`\`\`markdown
1a. **Linear Context Detection** (NEW):
   - Check for .linear-context.json:
     \`\`\`javascript
     let linearContext = null;
     try {
       const contextData = await fs.readFile('.linear-context.json', 'utf-8');
       linearContext = JSON.parse(contextData);
       console.log(\`Linear context found: \${linearContext.identifier}\`);
     } catch (e) {
       console.log('No Linear context - using traditional flow');
     }
     \`\`\`

### File Saving Enhancement (Update section 9):
**MUST DO FIRST**: Use Bash to get current date/time
**THEN**:
1. Create directory:
   - With Linear: \`cycles/\${linearContext.identifier}/YYYY-MM-DD/\`
   - Without Linear: \`cycles/YYYY-MM-DD/\`
2. Save as: \`HHMM-topic-plan.md\`
3. **NEW**: If Linear context exists, post comment:
   \`\`\`javascript
   if (linearContext) {
     await mcp__linear-server__create_comment({
       issueId: linearContext.issueId,
       body: \`📋 Cycle plan created: \${planTitle}\\n\\nView plan: cycles/\${linearContext.identifier}/\${date}/\${time}-\${topic}-plan.md\`
     });
   }
   \`\`\`
\`\`\``;
  
  await fs.writeFile('scripts/cycle-plan-update-template.md', template, 'utf-8');
  console.log('✅ Created cycle-plan update template');
}

async function createCycleLogUpdate() {
  const template = `# Cycle-log Linear Integration Update

Add this to the cycle-log command:

\`\`\`markdown
### 1. Setup Enhancement
Add Linear context detection:
\`\`\`javascript
// Check for Linear context
let linearContext = null;
try {
  const contextData = await fs.readFile('.linear-context.json', 'utf-8');
  linearContext = JSON.parse(contextData);
} catch (e) {
  // No Linear context
}

// Determine directory
const cycleDir = linearContext 
  ? \`cycles/\${linearContext.identifier}/\${date}\`
  : \`cycles/\${date}\`;
\`\`\`

### 2. File Discovery Enhancement
Update pattern matching:
\`\`\`javascript
// Find checkpoint file in appropriate directory
const checkpointPattern = linearContext
  ? \`cycles/\${linearContext.identifier}/\${date}/*-checkpoint.json\`
  : \`cycles/\${date}/*-checkpoint.json\`;
\`\`\`

### 3. Log Completion Enhancement
Add Linear comment:
\`\`\`javascript
if (linearContext) {
  await mcp__linear-server__create_comment({
    issueId: linearContext.issueId,
    body: \`📝 Implementation log created\\n\\nSummary: \${logSummary}\\n\\nLog: \${logPath}\`
  });
}
\`\`\`
\`\`\``;
  
  await fs.writeFile('scripts/cycle-log-update-template.md', template, 'utf-8');
  console.log('✅ Created cycle-log update template');
}

async function main() {
  console.log('🔧 Updating cycle commands with Linear integration fixes...\n');
  
  try {
    await updateCycleStart();
    await updateCycleComplete();
    await createCyclePlanUpdate();
    await createCycleLogUpdate();
    
    console.log('\n✨ All updates completed!');
    console.log('\n📝 Next steps:');
    console.log('1. Review the changes in cycle-start and cycle-complete');
    console.log('2. Manually apply updates from the template files to cycle-plan and cycle-log');
    console.log('3. Test the integration with a Linear issue');
  } catch (error) {
    console.error('❌ Error updating commands:', error);
    process.exit(1);
  }
}

main();