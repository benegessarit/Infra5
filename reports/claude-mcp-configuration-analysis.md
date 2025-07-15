# Claude MCP Configuration Analysis Report

**Date:** 2025-07-14  
**Issue:** Nia MCP server configuration not working  
**Research Method:** Multiple parallel subagents investigating different aspects

## Executive Summary

The nia-codebase-mcp server configuration failed to work due to several key issues:
1. **Wrong configuration file location** - Using `mcp-settings.json` instead of `claude_desktop_config.json`
2. **Incorrect package name** - Should use `nia-codebase-mcp` not the existing `nia-mcp-server`
3. **Environment variable handling issues** - Claude Desktop has known bugs with env variable expansion
4. **Missing Claude Desktop restart** - Configuration changes require app restart

## Root Cause Analysis

### Primary Issues Identified

1. **Configuration File Location Error**
   - **Current:** `/Users/davidbeyer/.claude/mcp-settings.json`
   - **Required:** `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Impact:** Claude Desktop doesn't read from mcp-settings.json

2. **Package Confusion**
   - **Current:** `nia-mcp-server` (via uvx)
   - **Required:** `nia-codebase-mcp@1.0.1` (via npx)
   - **Impact:** Wrong package provides different functionality

3. **Environment Variable Bug**
   - **Issue:** Claude Desktop's `env` section doesn't properly pass variables to MCP servers
   - **Workaround:** Pass API key directly in args array

## Claude Settings Architecture

### Settings File Hierarchy (Precedence Order)
1. **Enterprise/Managed Settings** (Highest)
   - macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`
   - Linux/Windows: `/etc/claude-code/managed-settings.json`

2. **Local Project Settings**
   - `.claude/settings.local.json` (in project root)

3. **Project Settings**
   - `.claude/settings.json` (in project root)

4. **User/Global Settings** (Lowest)
   - `~/.claude/settings.json`

### MCP-Specific Configuration
- **Claude Desktop:** `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Claude Code CLI:** `.mcp.json` files with various scopes

## MCP Server Configuration Best Practices

### Correct JSON Structure
```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "package-name", "additional-args"],
      "env": {
        "ENV_VAR": "value"
      }
    }
  }
}
```

### Transport Types
1. **STDIO** (Default) - Standard input/output
2. **SSE** - Server-Sent Events for HTTP-based servers
3. **HTTP** - Direct HTTP communication
4. **WebSockets** - Real-time bidirectional communication

### Environment Variable Handling
- **Claude Desktop:** Known bugs with `env` section - use direct args
- **Claude Code CLI:** Robust `${VAR_NAME}` expansion support
- **Security:** Never hardcode API keys in committed configs

## Nia-Codebase-MCP Package Analysis

### Package Details
- **NPM Name:** `nia-codebase-mcp`
- **Version:** 1.0.1
- **Publisher:** Nozomio Labs
- **Downloads:** ~479 (as of research date)
- **Repository:** https://github.com/nozomio-labs/nia-mcp

### Required Configuration
```json
{
  "mcpServers": {
    "nia-codebase": {
      "command": "npx",
      "args": [
        "-y", 
        "nia-codebase-mcp@1.0.1", 
        "--api-key=YOUR_NIA_API_KEY"
      ]
    }
  }
}
```

### API Key Requirements
- **Source:** app.trynia.ai
- **Free Tier:** 25 requests
- **Format:** Standard API key string
- **Base URL:** https://apigcp.trynia.ai/

## Recommended Solution

### Step 1: Create Correct Configuration File
**Location:** `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "nia-codebase": {
      "command": "npx",
      "args": [
        "-y",
        "nia-codebase-mcp@1.0.1",
        "--api-key=8Fu9WQ4EBOG0ER8mYLofv4EM7l5JHXzN",
        "--transport=stdio"
      ]
    }
  }
}
```

### Step 2: Verify Prerequisites
- ✅ Node.js 16+ installed
- ✅ Valid Nia API key
- ✅ Internet connectivity for npx downloads

### Step 3: Test Configuration
```bash
# Manual test
npx -y nia-codebase-mcp@1.0.1 --api-key=YOUR_KEY --debug=true

# Check Claude Desktop logs
tail -f ~/Library/Logs/Claude/mcp-*.log
```

### Step 4: Restart Claude Desktop
Configuration changes require a complete restart of Claude Desktop.

## Alternative Solutions

### Option 1: Use Claude Code CLI Instead
```bash
claude mcp add nia-codebase npx -y nia-codebase-mcp@1.0.1 --api-key=YOUR_KEY
```

### Option 2: Local Installation
```bash
npm install -g nia-codebase-mcp@1.0.1
```
Then reference the global installation in config.

### Option 3: Docker Container
```json
{
  "mcpServers": {
    "nia-codebase": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-e", "NIA_API_KEY=YOUR_KEY",
        "nia-codebase-mcp:latest"
      ]
    }
  }
}
```

## Debug Techniques

### Enable Debug Mode
Add `--debug=true` to args array for verbose logging.

### Check MCP Status
Use `/mcp` command in Claude Code to verify server status.

### Validate JSON
```bash
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq .
```

### Monitor Logs
```bash
# Claude Desktop logs
tail -f ~/Library/Logs/Claude/*.log

# MCP-specific logs
ls ~/Library/Logs/Claude/mcp-*.log
```

## Security Considerations

### API Key Management
- ❌ **Never commit API keys** to version control
- ✅ **Use environment variables** for sensitive data
- ✅ **Implement key rotation** for production use
- ✅ **Monitor API usage** for anomalies

### MCP Server Security
- Review server source code before use
- Use specific package versions (avoid `@latest`)
- Monitor network traffic for data exfiltration
- Implement access controls for sensitive codebases

## Known Issues and Limitations

### Claude Desktop Bugs
1. **Environment variable expansion** - Use direct args instead
2. **Hot reload** - Requires full restart for config changes
3. **Error reporting** - Limited error messages for MCP failures

### Nia-Codebase-MCP Limitations
1. **Codebase indexing** - Must be indexed in Nia platform first
2. **API rate limits** - 25 free requests, then paid tiers
3. **Language support** - Limited to supported programming languages

## Conclusion

The configuration failure was caused by using the wrong configuration file location and package name. The correct solution involves:
1. Using `claude_desktop_config.json` instead of `mcp-settings.json`
2. Configuring `nia-codebase-mcp@1.0.1` instead of `nia-mcp-server`
3. Passing the API key directly in args to avoid environment variable bugs
4. Restarting Claude Desktop after configuration changes

This analysis provides a comprehensive understanding of Claude's MCP configuration system and specific solutions for the nia-codebase integration.