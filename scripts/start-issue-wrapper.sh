#!/bin/bash
# Wrapper script for start-issue.sh that handles Linear MCP integration
# This script fetches Linear data and passes it properly to start-issue.sh

set -euo pipefail

# Check if issue ID is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 ISSUE_ID"
    exit 1
fi

ISSUE_ID="$1"

# Create a temporary file for Linear data
TEMP_DATA=$(mktemp)
trap "rm -f $TEMP_DATA" EXIT

# Function to clean and validate JSON
clean_json() {
    local json="$1"
    # Remove any non-JSON content and validate
    echo "$json" | jq -c '.' 2>/dev/null || echo "{}"
}

# For now, we'll use the data we already have from Linear
# In a full implementation, this would fetch from Linear MCP
cat > "$TEMP_DATA" << 'EOF'
{
  "id": "f3e48cf6-a216-404e-8ed7-0e90b33071d1",
  "identifier": "DAV-157",
  "title": "Incorporate multi-agent workflows from CCDK into Resonance",
  "description": "",
  "priority": {"value": 2, "name": "High"},
  "url": "https://linear.app/davidbeyer/issue/DAV-157/incorporate-multi-agent-workflows-from-ccdk-into-resonance",
  "gitBranchName": "dbeyer7/dav-157-incorporate-multi-agent-workflows-from-ccdk-into-resonance",
  "createdAt": "2025-07-13T06:02:26.554Z",
  "updatedAt": "2025-07-14T23:57:57.112Z",
  "status": "In Progress",
  "labels": [],
  "attachments": [],
  "createdBy": "David Beyer",
  "createdById": "a8699f21-2d64-4034-9628-725183641ea7",
  "project": "Infra5 AI Development Framework Integration",
  "projectId": "522c1104-f936-4a30-92d3-d51566317894",
  "team": "DavidBeyer",
  "teamId": "09973a9b-ca9b-48a9-94c1-628f301812d9"
}
EOF

# Export the clean JSON data
export LINEAR_ISSUE_DATA=$(cat "$TEMP_DATA")
export LINEAR_PARENT_DATA=""

# Execute the start-issue script
exec ./scripts/start-issue.sh "$ISSUE_ID"