#!/bin/bash
# MCP servers setup script for Claude Code
# Usage: ~/.claude/setup-mcp.sh

set -e

echo "Setting up MCP servers for Claude Code..."

# GitHub
# 環境変数 GITHUB_PAT が設定されている前提
if [ -n "$GITHUB_PAT" ]; then
  echo "Adding GitHub MCP server..."
  claude mcp add -s user -e GITHUB_PERSONAL_ACCESS_TOKEN="\${GITHUB_PAT}" \
    github -- npx -y @modelcontextprotocol/server-github
else
  echo "GITHUB_PAT not set, skipping GitHub MCP server"
fi

# Fetch
echo "Adding Fetch MCP server..."
claude mcp add -s user fetch -- npx -y mcp-fetch-server

# AWS (remote managed MCP server via mcp-proxy-for-aws)
if command -v uvx &> /dev/null; then
  echo "Adding AWS MCP server..."
  claude mcp add -s user aws -- uvx mcp-proxy-for-aws@latest https://aws-mcp.us-east-1.api.aws/mcp
else
  echo "uvx not found, skipping AWS MCP server"
  echo "  Install: brew install uv"
fi

# Datadog (remote managed MCP server)
echo "Adding Datadog MCP server..."
claude mcp add -s user --transport http datadog https://mcp.datadoghq.com/mcp

# Notion (HTTP transport)
echo "Adding Notion MCP server..."
claude mcp add -s user --transport http "claude.ai Notion" https://mcp.notion.com/mcp

echo ""
echo "MCP setup complete! Verify with: claude mcp list"
