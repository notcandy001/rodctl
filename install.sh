#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
cd "$SCRIPT_DIR"
command -v go &>/dev/null || { echo "✗  Go not installed — https://go.dev/dl/"; exit 1; }
echo "→  Building rodctl…"
go build -o rodctl .
mkdir -p "$INSTALL_DIR"
cp -f rodctl "$INSTALL_DIR/rodctl"
chmod +x "$INSTALL_DIR/rodctl"
echo "✓  Installed to $INSTALL_DIR/rodctl"
[[ ":$PATH:" != *":$INSTALL_DIR:"* ]] && echo "!  Add $INSTALL_DIR to your PATH"
echo ""
echo "   Run: rodctl help"
