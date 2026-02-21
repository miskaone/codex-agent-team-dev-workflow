#!/usr/bin/env bash
set -euo pipefail

REPO_SOURCE="${1:-${AGENT_TEAM_DEV_WORKFLOW_REPO_URL:-}}"
DEST_ROOT="${2:-${CODEX_HOME:-$HOME/.codex}}"
DEST="${DEST_ROOT%/}/skills/agent-team-dev-workflow"

if [[ -z "$REPO_SOURCE" ]]; then
  cat <<'EOF'
Usage:
  ./install-remote.sh <git-repo-url-or-local-path> [CODEX_HOME]

Environment:
  AGENT_TEAM_DEV_WORKFLOW_REPO_URL can be used in place of the first argument.
  CODEX_HOME defaults to $HOME/.codex.

Examples:
  ./install-remote.sh git@github.com:you/agency-os-skills.git
  ./install-remote.sh /path/to/codex-agent-team-dev-workflow
EOF
  exit 1
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [[ "$REPO_SOURCE" == *.git || "$REPO_SOURCE" == http://* || "$REPO_SOURCE" == https://* ]]; then
  git clone --depth 1 "$REPO_SOURCE" "$TMP_DIR"
  SOURCE_DIR="$TMP_DIR"
elif [[ "$REPO_SOURCE" == /* || "$REPO_SOURCE" == .* || "$REPO_SOURCE" == ./* || -d "$REPO_SOURCE" ]]; then
  SOURCE_DIR="$REPO_SOURCE"
else
  echo "Invalid source: $REPO_SOURCE" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
rsync -a --delete \
  --exclude='.git' \
  --exclude='.gitignore' \
  "$SOURCE_DIR/" "$DEST/"

echo "Installed agent-team-dev-workflow to $DEST"
