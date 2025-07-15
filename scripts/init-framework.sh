#!/bin/bash

# Initialize Infra5 AI Development Framework

set -e

echo "🚀 Initializing Infra5 AI Development Framework..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check prerequisites
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 is installed${NC}"
        return 0
    fi
}

echo -e "\n${YELLOW}Checking prerequisites...${NC}"
MISSING_DEPS=0

check_command "node" || MISSING_DEPS=1
check_command "npm" || MISSING_DEPS=1
check_command "git" || MISSING_DEPS=1
check_command "bash" || MISSING_DEPS=1

if [ $MISSING_DEPS -eq 1 ]; then
    echo -e "\n${RED}Please install missing dependencies before continuing.${NC}"
    exit 1
fi

# Check Node version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}❌ Node.js 18+ required (found v$NODE_VERSION)${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Node.js version OK${NC}"
fi

# Install npm dependencies
echo -e "\n${YELLOW}Installing dependencies...${NC}"
npm install

# Create required directories
echo -e "\n${YELLOW}Creating directory structure...${NC}"
mkdir -p .claude/hooks
mkdir -p .taskmaster/{docs,tasks,reports}
mkdir -p cycles
mkdir -p docs/{ai-context,git-workflow,dev-cycles,open-issues,completed-issues}
mkdir -p scripts
mkdir -p tests
mkdir -p worktrees

# Set up git hooks
echo -e "\n${YELLOW}Setting up git hooks...${NC}"
if [ -d .git ]; then
    # Make scripts executable
    chmod +x scripts/*.sh
    chmod +x .claude/hooks/*.sh 2>/dev/null || true
    echo -e "${GREEN}✓ Git hooks configured${NC}"
else
    echo -e "${YELLOW}⚠️  Not a git repository - skipping git hooks${NC}"
fi

# Check for .env file
if [ ! -f .env ]; then
    echo -e "\n${YELLOW}Creating .env from template...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}⚠️  Please edit .env with your API keys${NC}"
else
    echo -e "${GREEN}✓ .env file exists${NC}"
fi

# Initialize taskmaster if not already done
if [ ! -f .taskmaster/config.json ]; then
    echo -e "\n${YELLOW}Initializing TaskMaster...${NC}"
    # Create basic taskmaster config
    cat > .taskmaster/config.json << 'EOF'
{
  "version": "1.0.0",
  "models": {
    "main": "claude-3-5-sonnet-20241022",
    "fallback": "claude-3-haiku-20240307"
  },
  "preferences": {
    "language": "English",
    "gitIntegration": true
  }
}
EOF
    echo -e "${GREEN}✓ TaskMaster initialized${NC}"
fi

# Run tests to verify setup
echo -e "\n${YELLOW}Running verification tests...${NC}"
npm run typecheck

echo -e "\n${GREEN}✅ Infra5 Framework initialized successfully!${NC}"
echo -e "\nNext steps:"
echo -e "1. Edit ${YELLOW}.env${NC} with your API keys"
echo -e "2. Run ${YELLOW}./scripts/start-issue.sh${NC} to begin working on an issue"
echo -e "3. Use ${YELLOW}/cycle-plan${NC} and ${YELLOW}/cycle-start${NC} commands in Claude Code"
echo -e "\nFor more information, see the README.md"