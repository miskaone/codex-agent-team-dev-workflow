#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${CODEX_HOME:-$HOME/.codex}/skills/agent-team-dev-workflow"

mkdir -p "$(dirname "$DEST")"

if [ -d "$DEST" ]; then
  rm -rf "$DEST"
fi

cp -R "$ROOT_DIR" "$DEST"
echo "Installed agent-team-dev-workflow to $DEST"
