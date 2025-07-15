# Git Workflow Automation Scripts

## Overview

These scripts automate git worktree creation and Linear issue management for multi-agent development workflows.

## Current Status (Phase 1 MVP)

✅ **Working Features:**
- Git worktree creation with proper isolation
- Dynamic branch naming to avoid conflicts  
- Safety checks for repository state
- Dry-run mode for testing

⚠️ **Pending Features:**
- Full Linear MCP integration (requires Claude Code API bridge)
- Automated Linear status updates (manual updates required for now)
- Direct API integration (planned for Phase 2)

## Scripts

### start-issue.sh

Creates an isolated git worktree for a Linear issue and optionally updates its status.

```bash
# Basic usage
./scripts/start-issue.sh DAV-173

# Dry run (preview without changes)
./scripts/start-issue.sh --dry-run DAV-173

# With mock Linear integration (for testing)
ENABLE_MOCK_LINEAR=true ./scripts/start-issue.sh DAV-173
```

### complete-issue.sh

Updates Linear issue status to "In Review" and manages worktree cleanup.

```bash
./scripts/complete-issue.sh DAV-173
```

## Configuration

### Environment Variables

Create a `.env` file or export these variables:

```bash
# Enable mock mode for testing (no real Linear updates)
export ENABLE_MOCK_LINEAR=true

# Linear status IDs (workspace-specific)
export LINEAR_STATUS_IN_PROGRESS="e41cf207-0f8b-4f7b-82e0-b3471f212fe1"
export LINEAR_STATUS_IN_REVIEW="4fb53f3b-8af9-4a06-a098-d67082b7e626"

# Future: API integration
export LINEAR_API_KEY="your-api-key"
export LINEAR_INTEGRATION_ENABLED=true
```

### Finding Your Linear Status IDs

1. In Claude Code, run:
   ```
   mcp__linear-server__list_issue_statuses
   ```

2. Or check Linear API Explorer at https://api.linear.app/graphql

## How It Works

1. **Worktree Creation**: Uses `git worktree add` to create isolated workspaces
2. **Branch Naming**: `username/issue-id-sanitized-title`
3. **Directory Structure**: `worktrees/ISSUE-ID-sanitized-title/`
4. **Linear Integration**: Currently requires manual status updates

## Testing

Run the test suite:

```bash
# Run all tests
./tests/run-all-tests.sh

# Test specific functionality
./tests/test-start-issue-script.sh
./tests/test-complete-issue-script.sh
```

## Known Limitations

1. **Linear MCP Integration**: MCP servers can't be called directly from bash scripts. This is a fundamental limitation of the MCP protocol design.

2. **Status Updates**: Currently require manual updates in Linear UI or mock mode for testing.

3. **Issue Data**: Uses mock data for issue titles. Real Linear data requires API integration.

## Roadmap

### Phase 1 (Current) ✅
- Basic worktree automation
- Mock Linear integration
- Test coverage

### Phase 2 (Next)
- Integration with cycle commands
- Checkpoint metadata persistence
- Basic Linear GraphQL API integration

### Phase 3 (Future)
- Full Linear API integration
- Advanced error handling
- Production-ready features

## Troubleshooting

### "Failed to create git worktree"
- Check if branch already exists: `git branch -a | grep your-branch`
- Remove stale worktrees: `git worktree prune`

### "Linear integration not configured"
- This is expected in Phase 1
- Use `ENABLE_MOCK_LINEAR=true` for testing
- Manual Linear updates required for now

### "Repository has uncommitted changes"
- Worktrees work with uncommitted changes
- Type 'y' to continue or stash changes first

## Contributing

When working on these scripts:
1. Always test with dry-run mode first
2. Use mock mode for Linear integration testing
3. Update tests when adding features
4. Document any new environment variables