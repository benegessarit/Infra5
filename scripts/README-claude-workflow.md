# Claude Linear Workflow

Simple workflow for starting Linear issues with proper subissue detection.

## Usage

When you want to start working on a Linear issue, ask Claude:

```
"Start working on DAV-187"
```

Claude will:
1. Fetch the Linear issue data using MCP
2. Run the start-issue script with the proper directory name
3. Create a git worktree with the correct naming
4. Update Linear status to "In Progress"
5. Add a comment to the Linear issue

## What Claude Does

```bash
# 1. Fetch Linear data
issue_data = mcp__linear-server__get_issue('DAV-187')

# 2. Run the script with the data
./scripts/start-issue-simple.sh DAV-187 '$issue_data'

# 3. Update Linear status
mcp__linear-server__update_issue('DAV-187', { stateId: 'in-progress-id' })

# 4. Add comment
mcp__linear-server__create_comment('DAV-187', 'Worktree created...')
```

## Benefits

- ✅ Proper directory names from gitBranchName
- ✅ Subissue detection works correctly
- ✅ No complex integration needed
- ✅ Claude handles all the Linear MCP calls
- ✅ Simple bash script without mock data

## Example

For DAV-187 (a subissue):
- Generic would create: `worktrees/DAV-187-issue/`
- This creates: `worktrees/dav-187-phase-15-get-agent-to-update-task-throughout-workflow/`