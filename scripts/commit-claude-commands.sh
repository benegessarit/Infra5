#!/bin/bash
# Script to commit changes to .claude commands

set -e

echo "🔄 Committing changes to .claude commands..."

cd /Users/davidbeyer/.claude

# Check git status
echo "📊 Current status:"
git status --porcelain

# Add the modified commands
git add commands/cycle-start-\[Sonnet\].md
git add commands/cycle-complete-\[Sonnet\].md

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo "✅ No changes to commit"
else
    # Commit the changes
    git commit -m "feat(commands): add Linear integration to cycle commands

- Add Linear issue ID support to cycle-start
- Create new cycle-complete command with Linear integration
- Support git workflow automation
- Maintain backward compatibility

Part of DAV-182 implementation"

    echo "✅ Changes committed successfully!"
fi

echo "📍 Current branch:"
git branch --show-current

echo "📝 Recent commits:"
git log --oneline -3