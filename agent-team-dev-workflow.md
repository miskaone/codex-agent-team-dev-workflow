---
title: Agent Team Development Workflow
description: >
  Six-phase compound engineering cycle for development tasks that orchestrates specialized
  agents in a planning/plan/work/review loop and captures reusable learnings.
shortcuts:
  - build
  - fix
  - implement
  - refactor
  - code change
tags:
  - workflow
  - agents
  - development
  - self-improving
related:
  - "[[agent-team-dev-workflow]]"
  - "[[_MOCs/dev-workflow]]"
  - "[[phases/discover]]"
  - "[[phases/plan]]"
  - "[[phases/work]]"
  - "[[phases/test]]"
  - "[[phases/review]]"
  - "[[phases/compound]]"
  - "[[modes/execution-modes]]"
  - "[[knowledge/system]]"
schema: skill-v1
last_updated: 2026-02-21
---

# Agent Team Development Workflow

A lightweight entrypoint for the graph-based workflow. Trigger automatically on
`build`, `fix`, `implement`, `refactor`, or any explicit development task.

## Philosophy
- Planning and review are weighted heavily because future work becomes easier.
- Work is scoped per contract and verified before moving forward.
- Every cycle updates the knowledge graph so repeat mistakes are reduced over time.

## Quick Start
- Default path: [[phases/discover]] → [[phases/plan]] → [[phases/work]] → [[phases/test]] → [[phases/review]] → [[phases/compound]]
- Small fixes can use [[phases/plan]] → [[phases/work]] → [[phases/test]] → [[phases/compound]].

## Execution
1. Open [[references/phase-details]] for full role contracts.
2. Follow mode from [[modes/execution-modes]].
3. Run the phase nodes in order, then repeat only if gates require backtracking.
4. End every cycle with [[phases/compound]].

## Primary Outputs
- discovery-brief.md
- implementation-plan.md
- verification-report.md
- review-findings.md
- cycle-report.md
