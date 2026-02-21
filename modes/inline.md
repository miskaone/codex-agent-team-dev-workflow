---
title: Execution Mode — Inline
description: Coordinator executes each phase role sequentially in the main loop.
mode: inline
tags:
  - execution
  - sequential
  - fallback
related:
  - "[[modes/execution-modes]]"
  - "[[agent-team-dev-workflow]]"
  - "[[references/orchestration-patterns]]"
  - "[[references/phase-details]]"
  - "[[knowledge/customization]]"
schema: skill-v1
last_updated: 2026-02-21
---

# Execution Mode: Inline

Fallback when no subagent/team primitives are available.
- One context executes each role sequentially.
- Keep a small number of concise context artifacts.
