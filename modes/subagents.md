---
title: Execution Mode — Subagents
description: Parallelized role execution using `spawn_agent` when available and teams are not enabled.
mode: subagents
tags:
  - execution
  - subagent
  - parallel
related:
  - "[[modes/execution-modes]]"
  - "[[agent-team-dev-workflow]]"
  - "[[references/orchestration-patterns]]"
  - "[[references/phase-details]]"
schema: skill-v1
last_updated: 2026-02-21
---

# Execution Mode: Subagents

Use when `spawn_agent` is available without agent-team mode.
- Role-based subagents spawn in parallel.
- Coordinator keeps scope and receives outputs.
