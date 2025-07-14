# Claude Code AI Development Framework

## Overview

The `.claude` directory implements a sophisticated AI Development Automation Framework that enhances Claude Code with intelligent command orchestration, automated security scanning, context injection, and workflow automation.

## Current Status: ACTIVE

The framework is fully operational with:
- 7 production-ready command templates
- 4 automated hook behaviors
- Comprehensive security scanning
- Multi-agent orchestration capabilities

## Architecture

### Directory Structure
```
.claude/
├── commands/              # Multi-agent orchestration templates
│   ├── code-review.md    # Multi-agent code quality analysis
│   ├── create-docs.md    # Intelligent documentation generation
│   ├── full-context.md   # Adaptive context gathering
│   ├── gemini-consult.md # Deep AI consultation sessions
│   ├── handoff.md        # Session continuity management
│   ├── refactor.md       # Intelligent code restructuring
│   └── update-docs.md    # Documentation synchronization
├── hooks/                # Automated lifecycle behaviors
│   ├── config/          # Hook configuration files
│   ├── setup/           # Installation templates
│   ├── sounds/          # Audio notification files
│   ├── gemini-context-injector.sh
│   ├── mcp-security-scan.sh
│   ├── notify.sh
│   └── subagent-context-injector.sh
└── settings.local.json  # Claude Code configuration
```

## Command System

### Design Philosophy
Commands use intelligent multi-agent orchestration to handle complex development tasks. Each command:
- Auto-loads essential project context
- Selects appropriate execution strategy based on complexity
- Launches specialized agents in parallel for efficiency
- Synthesizes findings into actionable outputs

### Command Reference

#### `/full-context` - Adaptive Context Gathering
- **Purpose**: Comprehensive codebase analysis with scalable agent deployment
- **Strategies**: Direct (0-1 agents) → Focused (2-3 agents) → Comprehensive (3+ agents)
- **Use Cases**: Understanding new codebases, impact analysis, dependency mapping

#### `/code-review` - Multi-Agent Code Quality Analysis
- **Purpose**: Surface only critical, high-impact findings
- **Coverage**: Security vulnerabilities, performance issues, architectural problems
- **Philosophy**: "Needle-moving discoveries" over exhaustive lists

#### `/gemini-consult` - Deep AI Consultation
- **Purpose**: Persistent Gemini sessions for complex problem-solving
- **Features**: Auto-context injection, session persistence, critical thinking approach
- **Integration**: Works with Context7 MCP for library documentation

#### `/create-docs` - Intelligent Documentation Generation
- **Purpose**: Generate AI-optimized documentation following 3-tier system
- **Features**: Smart tier placement, content migration, redundancy elimination
- **Output**: New documentation files + registry updates

#### `/handoff` - Session Continuity Management
- **Purpose**: Maintain context between Claude Code sessions
- **Detection**: Automatic achievement detection through tool usage analysis
- **Updates**: Smart merge strategy for existing vs new work

#### `/refactor` - Intelligent Code Restructuring
- **Purpose**: Safe, comprehensive refactoring with dependency management
- **Safety**: Value assessment ensures improvements before changes
- **Scope**: Complete import/export restructuring across files

#### `/update-docs` - Documentation Synchronization
- **Purpose**: Keep documentation synchronized with code changes
- **Strategy**: Tier-first updates (start with Tier 3, cascade upward)
- **Sources**: Git commits, uncommitted changes, or session context

## Hooks System

### Design Philosophy
Hooks provide automated behaviors at specific Claude Code lifecycle points, enhancing security, context management, and user experience without manual intervention.

### Hook Reference

#### MCP Security Scanner
- **Trigger**: `PreToolUse` for all MCP tools
- **Function**: Prevents accidental exposure of secrets
- **Coverage**: API keys, passwords, credentials, sensitive files
- **Configuration**: `config/sensitive-patterns.json`

#### Gemini Context Injector
- **Trigger**: `PreToolUse` for Gemini consultation
- **Function**: Auto-attaches project documentation to new sessions
- **Files**: Includes project-structure.md and MCP-ASSISTANT-RULES.md
- **Session Awareness**: Only injects on new sessions, skips existing ones

#### Subagent Context Injector
- **Trigger**: `PreToolUse` for Task tool calls
- **Function**: Auto-enhances sub-agent prompts with project context
- **Context**: Injects CLAUDE.md, project-structure.md, docs-overview.md references
- **Integration**: Works with Claude Code's built-in @ reference system

#### Notification System
- **Triggers**: `Notification` (input needed) and `Stop` (task complete) events
- **Function**: Cross-platform audio feedback for development workflow
- **Audio Files**: Pleasant completion and input-needed sounds
- **Platform Support**: macOS (afplay), Linux (paplay/aplay), Windows (PowerShell)

### Configuration Architecture

#### Global vs Project-Specific Setup
- **Global Hooks**: Configured in `~/.claude/settings.json` for system-wide enhancement
- **Project Hooks**: Override capability via local `.claude/settings.json`
- **Hook Scripts**: Deployed globally in `~/.claude/hooks/` for universal access
- **Portability**: Uses `${WORKSPACE}` variables for project-agnostic paths

### Context Injection System

#### Subagent Context Injection (Operational)
- **Automatic Context Loading**: Hook system provides ~27.3k tokens of project context to all subagents
- **@ Reference System**: Injects @/CLAUDE.md, @/docs/ai-context/project-structure.md, @/docs/ai-context/docs-overview.md
- **Token Efficiency**: @ references avoid content duplication while ensuring consistency
- **Complete Coverage**: Every Task tool call receives comprehensive project context automatically

## Configuration

### settings.local.json Structure
```json
{
  "environment": {
    "WORKSPACE": "/path/to/workspace"
  },
  "experimental": {
    "tools": {
      "notification_command": {
        "command": ["bash", ".claude/hooks/notify.sh"]
      }
    },
    "hooks": {
      "pre_tool_use": ".claude/hooks/lifecycle-hook.sh",
      "notification": ".claude/hooks/notify.sh",
      "stop": ".claude/hooks/notify.sh"
    }
  },
  "mcpServers": {
    // MCP server configurations
  }
}
```

### Security Configuration
The `config/sensitive-patterns.json` file defines:
- Pattern categories (API keys, credentials, files)
- Comprehensive regex patterns for detection
- Whitelist for allowed placeholders
- Extensible for custom patterns

## Integration Patterns

### Multi-Agent Orchestration Pattern
```
1. Load project context automatically
2. Assess complexity and select strategy
3. Launch specialized agents in parallel
4. Synthesize findings from all agents
5. Generate integrated output
```

### Hook Lifecycle Pattern
```
1. Intercept tool call at PreToolUse
2. Analyze tool type and parameters
3. Apply security/context enhancements
4. Pass modified or continue unchanged
5. Log events for debugging/audit
```

### Documentation Tier Integration
- Commands respect 3-tier documentation system
- Smart content placement based on scope
- Automatic registry updates
- Content migration for hierarchy management

## Best Practices

### For Command Usage
1. Use `/full-context` before major changes
2. Run `/code-review` before merges
3. Use `/gemini-consult` for architectural decisions
4. Keep documentation current with `/update-docs`

### For Hook Configuration
1. Review security patterns regularly
2. Test hooks in isolated environments
3. Monitor hook logs for issues
4. Keep sensitive patterns updated

### For System Maintenance
1. Update command templates as patterns emerge
2. Extend hooks for new tool integrations
3. Maintain clean separation of concerns
4. Document custom modifications

## Performance Considerations

- Commands use parallel agent execution for speed
- Hooks are designed to be non-blocking
- Context injection uses references over content
- Security scanning has size limits for efficiency

## Error Handling

- Commands include graceful fallbacks
- Hooks log all events for debugging
- Security scanner fails safely (blocks on error)
- Notification system has multiple fallbacks

## Future Enhancements

Based on Linear issues, planned improvements include:
- Linear MCP workflow integration (DAV-156)
- Multi-agent workflows from CCDK (DAV-157)
- Human testing integration (DAV-158)
- CodeRabbit AI feedback cycle (DAV-161)
- Enhanced hook library integration (DAV-163)