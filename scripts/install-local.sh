#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${CODEX_HOME:-$HOME/.codex}/skills/agent-team-dev-workflow"

mkdir -p "$(dirname "$DEST")"

if [ -d "$DEST" ]; then
  rm -rf "$DEST"
fi

mkdir -p "$DEST"
rsync -a --delete \
  --exclude='.git' \
  --exclude='.gitignore' \
  "$ROOT_DIR/" "$DEST/"
echo "Installed agent-team-dev-workflow to $DEST"
