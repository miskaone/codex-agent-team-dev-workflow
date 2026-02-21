---
title: Execution Modes
description: Choose between subagent, agent-team, or inline execution based on environment capability.
schema: knowledge-map
related:
  - "[[agent-team-dev-workflow]]"
  - "[[modes/subagents]]"
  - "[[modes/agent-teams]]"
  - "[[modes/inline]]"
  - "[[references/orchestration-patterns]]"
  - "[[references/phase-details]]"
last_updated: 2026-02-21
---

# Execution Modes

Use this node from the hub and MOC when you need mode selection context.

## Modes

- [[modes/subagents]] — best when `spawn_agent` is available and teams mode is not.
- [[modes/agent-teams]] — best when multi-engineer team mode is available.
- [[modes/inline]] — fallback when subagent/team modes are not available.

## Rule

Always evaluate available runtime and project risk before selecting the mode.
