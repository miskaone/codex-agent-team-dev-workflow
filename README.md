# codex-agent-team-dev-workflow

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
cp -R /Users/michaellydick/dev/codex-agent-team-dev-workflow "$CODEX_HOME/skills/agent-team-dev-workflow"
```

Or run the included helper:

```bash
cd /Users/michaellydick/dev/codex-agent-team-dev-workflow
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
