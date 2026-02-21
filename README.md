# codex-agent-team-dev-workflow

This repository contains a self-contained Codex skill bundle for the **agent-team-dev-workflow**.

## Contents
- `SKILL.md` — skill entrypoint and workflow orchestration
- `agents/` — agent role definitions/config for this workflow
- `references/` — role prompts, patterns, templates, and operational guides
- `scripts/` — supporting scripts (if present)
- `assets/` — optional support assets

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
