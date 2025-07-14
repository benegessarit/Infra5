#!/usr/bin/env node
/**
 * Linear MCP Helper - Bridge between bash scripts and Linear MCP
 * Usage: node linear-mcp-helper.js <command> <args>
 * 
 * Commands:
 *   get-issue <issue-id>       - Get issue details including status
 *   update-status <issue-id> <status-id> - Update issue status
 *   get-status-id <team-id> <status-name> - Get status ID by name
 */

const { execSync } = require('child_process');

// Linear status names to match
const STATUS_NAMES = {
  'Backlog': 'Backlog',
  'In Progress': 'In Progress',
  'In Review': 'In Review',
  'Done': 'Done'
};

/**
 * Execute Claude CLI command with MCP
 */
function executeMcpCommand(command) {
  try {
    // This would need to interface with Claude Code's MCP system
    // For now, we'll output a placeholder response
    console.error('Direct MCP integration not available from Node.js subprocess');
    console.error('Consider using Linear GraphQL API directly');
    process.exit(1);
  } catch (error) {
    console.error('MCP command failed:', error.message);
    process.exit(1);
  }
}

/**
 * Get Linear issue details
 */
function getIssue(issueId) {
  if (!issueId) {
    console.error('Issue ID required');
    process.exit(1);
  }
  
  // Placeholder for MCP integration
  executeMcpCommand(`mcp linear get-issue ${issueId}`);
}

/**
 * Update Linear issue status
 */
function updateStatus(issueId, statusId) {
  if (!issueId || !statusId) {
    console.error('Issue ID and status ID required');
    process.exit(1);
  }
  
  // Placeholder for MCP integration
  executeMcpCommand(`mcp linear update-issue ${issueId} --status ${statusId}`);
}

/**
 * Get status ID by name
 */
function getStatusId(teamId, statusName) {
  if (!teamId || !statusName) {
    console.error('Team ID and status name required');
    process.exit(1);
  }
  
  // Placeholder for MCP integration
  executeMcpCommand(`mcp linear get-status ${teamId} "${statusName}"`);
}

// Main command processing
const command = process.argv[2];
const args = process.argv.slice(3);

switch (command) {
  case 'get-issue':
    getIssue(args[0]);
    break;
  case 'update-status':
    updateStatus(args[0], args[1]);
    break;
  case 'get-status-id':
    getStatusId(args[0], args[1]);
    break;
  default:
    console.error(`Unknown command: ${command}`);
    console.error('Usage: linear-mcp-helper.js <get-issue|update-status|get-status-id> <args>');
    process.exit(1);
}