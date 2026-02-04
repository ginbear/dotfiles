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

# Puppeteer
echo "Adding Puppeteer MCP server..."
claude mcp add -s user puppeteer -- npx -y @modelcontextprotocol/server-puppeteer

# Datadog (datadog_mcp_cli がインストールされている場合のみ)
if command -v datadog_mcp_cli &> /dev/null || [ -f ~/.local/bin/datadog_mcp_cli ]; then
  echo "Adding Datadog MCP server..."
  claude mcp add -s user datadog -- ~/.local/bin/datadog_mcp_cli
else
  echo "datadog_mcp_cli not found, skipping Datadog MCP server"
  echo "  Install: https://docs.datadoghq.com/bits_ai/mcp_server/setup/"
fi

# Zellij (ghq + npm build が必要)
ZELLIJ_MCP_DIR="$(ghq root)/github.com/GitJuhb/zellij-mcp-server"
if [ ! -d "$ZELLIJ_MCP_DIR" ]; then
  echo "Cloning zellij-mcp-server..."
  ghq get https://github.com/GitJuhb/zellij-mcp-server.git
fi
if [ ! -f "$ZELLIJ_MCP_DIR/dist/index.js" ]; then
  echo "Building zellij-mcp-server..."
  (cd "$ZELLIJ_MCP_DIR" && npm install && npm run build)
fi
echo "Adding Zellij MCP server..."
claude mcp add -s user zellij -- node "$ZELLIJ_MCP_DIR/dist/index.js"

# Notion (HTTP transport)
echo "Adding Notion MCP server..."
claude mcp add -s user --transport http "claude.ai Notion" https://mcp.notion.com/mcp

echo ""
echo "MCP setup complete! Verify with: claude mcp list"
