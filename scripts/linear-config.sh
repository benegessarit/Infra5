#!/bin/bash
# Linear configuration for git workflow scripts
# Source this file to get Linear configuration

# Linear workspace configuration
# These IDs are specific to Luna's Linear workspace
# To find your status IDs:
# 1. Use Linear MCP: mcp__linear-server__list_issue_statuses with your team ID
# 2. Or check Linear API documentation

# Default status IDs (update these for your workspace)
export LINEAR_STATUS_BACKLOG="${LINEAR_STATUS_BACKLOG:-a352fb76-a25c-4cc1-808a-420bc20726a2}"
export LINEAR_STATUS_IN_PROGRESS="${LINEAR_STATUS_IN_PROGRESS:-e41cf207-0f8b-4f7b-82e0-b3471f212fe1}"
export LINEAR_STATUS_IN_REVIEW="${LINEAR_STATUS_IN_REVIEW:-4fb53f3b-8af9-4a06-a098-d67082b7e626}"
export LINEAR_STATUS_DONE="${LINEAR_STATUS_DONE:-}"

# Team configuration
export LINEAR_TEAM_ID="${LINEAR_TEAM_ID:-09973a9b-ca9b-48a9-94c1-628f301812d9}"

# API configuration (optional - for future API integration)
export LINEAR_API_KEY="${LINEAR_API_KEY:-}"
export LINEAR_API_URL="${LINEAR_API_URL:-https://api.linear.app/graphql}"

# Feature flags
export LINEAR_INTEGRATION_ENABLED="${LINEAR_INTEGRATION_ENABLED:-false}"
export LINEAR_DRY_RUN="${LINEAR_DRY_RUN:-false}"

# Print configuration status
linear_config_status() {
    echo "Linear Configuration Status:"
    echo "  Team ID: ${LINEAR_TEAM_ID:-Not set}"
    echo "  API Key: ${LINEAR_API_KEY:+Set}${LINEAR_API_KEY:-Not set}"
    echo "  Integration: ${LINEAR_INTEGRATION_ENABLED}"
    echo "  Status IDs configured: $([ -n "$LINEAR_STATUS_IN_PROGRESS" ] && echo "Yes" || echo "No")"
}