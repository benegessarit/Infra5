# Deployment Guide

This guide documents the actual deployment process for the Infra5 AI Development Framework.

## Deployment Method

Infra5 is deployed as a **local development framework**, not a hosted service. Users install it on their development machines to enhance their AI-assisted development workflow.

## Installation Steps (Tested)

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Infra5
   ```

2. **Run the initialization script**
   ```bash
   ./scripts/init-framework.sh
   ```
   
   This script will:
   - ✅ Check prerequisites (Node.js 18+, npm, git, bash)
   - ✅ Install npm dependencies
   - ✅ Create required directory structure
   - ✅ Set up git hooks
   - ✅ Create .env from template
   - ✅ Initialize TaskMaster configuration
   - ✅ Run TypeScript type checking to verify setup

3. **Configure environment**
   ```bash
   # Edit the generated .env file
   nano .env
   ```
   
   Required configurations:
   - `LINEAR_API_KEY`: Your Linear API key (if using Linear integration)
   - Optional: MCP server API keys (Context7, Gemini)

4. **Verify installation**
   ```bash
   # Type checking should pass
   npm run typecheck
   
   # Run tests
   npm test
   ```

## Post-Installation Setup

### For Linear Integration Users

1. Get your Linear API key from Linear Settings > API
2. Find your team's status IDs:
   ```bash
   # Use Linear GraphQL explorer or API to get status IDs
   # Default IDs in .env.example are examples only
   ```

### For Claude Code Users

1. Ensure Claude Code v1.5.5+ is installed
2. Configure MCP servers if needed:
   - Context7 for library documentation
   - Gemini for code consultation

## Distribution Options

### Via Git Repository (Current)
- Users clone the repository directly
- Simple and straightforward
- Allows easy customization

### Via npm Package (Future)
Could be packaged as:
```json
{
  "name": "@luna/infra5",
  "bin": {
    "infra5": "./bin/infra5.js"
  }
}
```

Then users would:
```bash
npm install -g @luna/infra5
infra5 init
```

### Via Homebrew (Future)
For macOS users:
```bash
brew tap luna/infra5
brew install infra5
```

## Updating

To update to the latest version:
```bash
git pull origin main
npm install
./scripts/init-framework.sh
```

## Troubleshooting

### Common Issues

1. **TypeScript errors during init**
   - Fixed in vitest.config.ts (removed TDD Guard reporter import)
   
2. **Missing .env file**
   - Init script creates it from .env.example automatically

3. **Permission errors**
   - Ensure scripts are executable: `chmod +x scripts/*.sh`

4. **Node version too old**
   - Requires Node.js 18+, init script checks this

## Security Considerations

- Never commit .env file (it's in .gitignore)
- API keys are stored locally only
- No external services required for core functionality
- All processing happens on local machine

## Success Metrics

Installation is successful when:
- ✅ Init script completes without errors
- ✅ TypeScript compilation passes
- ✅ Directory structure is created
- ✅ .env file exists (with placeholders)
- ✅ User can run `./scripts/start-issue.sh`