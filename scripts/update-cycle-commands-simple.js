#!/usr/bin/env node

const fs = require('fs').promises;

async function updateCycleStart() {
  const filePath = '/Users/davidbeyer/.claude/commands/cycle-start-[Sonnet].md';
  let content = await fs.readFile(filePath, 'utf-8');
  
  // Replace hardcoded state ID with dynamic resolution
  content = content.replace(
    "stateId: 'e41cf207-0f8b-4f7b-82e0-b3471f212fe1'",
    `stateId: inProgressState.id // Dynamic resolution needed`
  );
  
  await fs.writeFile(filePath, content, 'utf-8');
  console.log('✅ Marked cycle-start for state ID update');
}

async function updateCycleComplete() {
  const filePath = '/Users/davidbeyer/.claude/commands/cycle-complete-[Sonnet].md';
  let content = await fs.readFile(filePath, 'utf-8');
  
  // Replace hardcoded state ID
  content = content.replace(
    "stateId: 'f5e57f51-9d1f-4e1f-a0eb-1dedc91ed393' // In Review",
    `stateId: inReviewState.id // Dynamic resolution needed`
  );
  
  await fs.writeFile(filePath, content, 'utf-8');
  console.log('✅ Marked cycle-complete for state ID update');
}

async function main() {
  console.log('🔧 Updating cycle commands...\n');
  
  try {
    await updateCycleStart();
    await updateCycleComplete();
    
    console.log('\n✨ Basic updates completed!');
    console.log('\n📝 Manual steps needed:');
    console.log('1. Add dynamic state resolution before the update calls');
    console.log('2. Add Linear context file reading at the start of each command');
    console.log('3. Update file patterns to support issue-based directories');
    console.log('4. Add Linear comments to cycle-plan, cycle-log, and cycle-check');
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

main();