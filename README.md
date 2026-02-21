# codex-agent-team-dev-workflow
![Codex Skill](https://img.shields.io/badge/Codex-Skill-blue)


This repository contains a self-contained Codex skill bundle for the **agent-team-dev-workflow**.

## Contents
- `SKILL.md` — compact graph entrypoint/redirect
- `agent-team-dev-workflow.md` — compact hub with primary links
- `_MOCs/` — master navigation map for this skill
- `phases/` — atomic nodes for Discover → Plan → Work → Test → Review → Compound
- `agents/` — atomic agent-role nodes
- `modes/` — execution-mode selection nodes
- `knowledge/` — operating-system nodes used by workflow logic
- `references/` — preserved reference materials and templates, now with graph metadata
- `scripts/` — install helpers

## Install into a Codex environment

From your Codex home (or skill manager root), install this skill path into your local skill index:

```bash
cp -R . "$CODEX_HOME/skills/agent-team-dev-workflow"
```

Or run the included helper:

```bash
cd "$(git rev-parse --show-toplevel)"
./scripts/install-local.sh
```
### Shared-host install (recommended)

If the repo is hosted in git, use the remote installer so any machine can bootstrap:

```bash
cd /path/to/codex-agent-team-dev-workflow
./scripts/install-remote.sh <git-repo-url>
```

Example:

```bash
./scripts/install-remote.sh git@github.com:you/agency-os-codex-skills.git
```

If you prefer a fixed shared location, set `AGENT_TEAM_DEV_WORKFLOW_REPO_URL` and run:

```bash
export AGENT_TEAM_DEV_WORKFLOW_REPO_URL=git@github.com:you/agency-os-codex-skills.git
./scripts/install-remote.sh
```

You can also pass an alternate CODEX home as the second argument:

```bash
./scripts/install-remote.sh git@github.com:you/agency-os-codex-skills.git /path/to/other/.codex
```

## Quick Start (30-second demo)

1. Open any Codex workspace
2. Create or navigate to a project folder
3. Say or type:  
   `use agent-team-dev-workflow to add priority field to my todo CLI`
4. Watch the full 6-phase cycle run automatically
5. Check `.workflow/current/` and the updated `LEARNINGS.md`

See [`example-project/`](./example-project/) for a complete working example.

## Multi-host usage notes

Then in project `AGENTS.md`/`README` references, this skill can be referenced by name.

## Use in a project

When the skill is invoked, it expects to run in a project checkout with:
- `AGENTS.md`
- `known-pitfalls.md`
- `LEARNINGS.md`
- workflow output directory `.workflow/current/`

The workflow artifacts are written into `.workflow/current/` and can be committed as appropriate.

## Versioning notes

This repo is a snapshot; update this repo and commit additional workflow improvements as needed.
