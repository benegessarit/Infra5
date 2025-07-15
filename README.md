# Infra5 - AI Development Framework

A comprehensive development framework for AI-assisted software engineering with integrated git workflow automation.

## Prerequisites

- Node.js 18+
- Claude Code v1.5.5+
- bash 5.0+
- git

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Infra5
```

2. Install dependencies:
```bash
npm install
```

3. Configure environment variables:
```bash
cp .env.example .env
# Edit .env with your API keys
```

4. Initialize the framework:
```bash
./scripts/init-framework.sh
```

## Quick Start

### Starting a new issue:
```bash
./scripts/start-issue.sh
```

### Working with cycles:
```bash
# Plan phase (Opus)
/cycle-plan

# Implementation phase (Sonnet)
/cycle-start

# Check progress
/cycle-check
```

### Completing an issue:
```bash
./scripts/complete-issue.sh
```

## Key Features

- **Git Workflow Automation**: Automated branch creation and issue tracking
- **TDD Guard**: Enforces test-driven development practices
- **Context Preservation**: Maintains context between work sessions
- **Multi-Agent Support**: Opus-Sonnet workflow separation
- **MCP Integration**: Gemini consultation and Context7 documentation

## Documentation

- [Project Structure](docs/ai-context/project-structure.md)
- [Git Workflow](docs/git-workflow/overview.md)
- [Development Cycles](docs/dev-cycles/overview.md)

## Testing

```bash
# Run tests
npm test

# Run tests once
npm run test:once

# Type checking
npm run typecheck
```

## License

MIT