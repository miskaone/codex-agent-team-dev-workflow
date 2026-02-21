---
name: agent-team-dev-workflow
description: >
  Six-phase graph-based development workflow:
  Discover → Plan → Work → Test → Review → Compound.
  Trigger on build, fix, implement, refactor, and code-change tasks.
version: 1.2.0
last_updated: 2026-02-21
status: production-ready
---

# Agent Team Development Workflow

This skill is now maintained as a Skill Graph for fast loading.

Start here:

- [[agent-team-dev-workflow]] (hub)
- [[_MOCs/dev-workflow]] (navigation)

Default cycle:
`[[phases/discover]] → [[phases/plan]] → [[phases/work]] → [[phases/test]] → [[phases/review]] → [[phases/compound]]`

Small-fix cycle:
`[[phases/plan]] → [[phases/work]] → [[phases/test]] → [[phases/compound]]`

Keep context load-on-demand:
- Open only the required phase or agent nodes.
- Stay in phase order unless a gate sends you back.
- End every cycle with [[phases/compound]].

## Optional Advanced Patterns (v1.2.0)
- [[agents/quality-guardian]] – optional role for constructive rigor and perspective diversity.
- [[references/compound-advanced]] – optional enhanced Compound phase prompt.

## Scientific Inspiration
Inspired by “Multi-agent cooperation through in-context co-player inference” (arXiv:2602.16301).
