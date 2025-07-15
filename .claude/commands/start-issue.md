# Claude Command: start-issue

A Claude command that properly integrates Linear MCP with git workflow automation.

## Usage

```
/start-issue DAV-187
```

## Implementation Steps

1. Fetch Linear issue data using `mcp__linear-server__get_issue`
2. Check if it's a subissue (has parentId)
3. If subissue, fetch parent data
4. Create environment variables with the data
5. Execute the enhanced start-issue script
6. Update Linear status to "In Progress"
7. Add comment with worktree location

## Command Logic

```javascript
// Pseudo-code for Claude command
async function startIssue(issueId) {
    // 1. Fetch issue data
    const issue = await mcp.linear.getIssue(issueId);
    
    // 2. Check for parent
    let parentData = null;
    if (issue.parentId) {
        parentData = await mcp.linear.getIssue(issue.parentId);
    }
    
    // 3. Execute script with data
    const env = {
        LINEAR_ISSUE_DATA: JSON.stringify(issue),
        LINEAR_PARENT_DATA: parentData ? JSON.stringify(parentData) : ''
    };
    
    await bash('./scripts/start-issue-enhanced.sh', [issueId], { env });
    
    // 4. Update Linear status
    await mcp.linear.updateIssue(issueId, { 
        stateId: 'e41cf207-0f8b-4f7b-82e0-b3471f212fe1' // In Progress
    });
}
```

## Benefits

- Seamless Linear integration
- Proper subissue detection
- Automatic status updates
- No manual data handling