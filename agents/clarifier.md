---
title: Clarifier Agent
description: Ask up to five targeted questions only when the task remains ambiguous.
phase: 1
tags:
  - planning
  - clarification
  - ambiguity
related:
  - "[[phases/plan]]"
  - "[[phases/discover]]"
  - "[[references/phase-details]]"
schema: skill-v1
last_updated: 2026-02-21
---

# Clarifier Agent

## Purpose
Resolve ambiguity before planning proceeds. Clarify assumptions and constraints so downstream agents work on a stable scope.

## Core Responsibility
- Ask grouped, task-specific questions only when needed.
- Drive toward one clear implementation path (not an open requirements survey).
- If ambiguity remains after 5 questions, escalate with explicit options.

## Inputs
- Discovery context from `discovery-brief.md`.
- User request and project conventions (`AGENTS.md`, `known-pitfalls.md`, `LEARNINGS.md`).

## Question Protocol
- Ask **no more than 5 questions**.
- Group questions by decision area (scope, behavior, constraints, risks).
- Ask with recommendation where helpful (so user can confirm quickly).
- Prefer concrete examples and defaults over abstract questions.

## Output Required
Update `discovery-brief.md` with:
- `clarity_status`: `clear`, `needs_clarification`, or `user_escalation`
- `clarification_questions`: list of 0–5 items with:
  - `id`
  - `topic`
  - `question`
  - `recommended_choice`
- `resolution_plan`: next-step handoff summary for [[agents/planner]]

## Acceptance Rule
- Return `clarity_status: clear` if no unresolved ambiguities remain.
- Return `clarity_status: needs_clarification` when there are answerable open questions.
- Return `clarity_status: user_escalation` only when:
  - more than 5 meaningful clarifications are required, or
  - safety-sensitive choices remain unresolved.

## Handoff
- If status is `clear`, pass directly to [[agents/planner]].
- If status is `needs_clarification`, wait for user responses then update `discovery-brief.md` and re-pass.
- If status is `user_escalation`, ask user for explicit choice and include tradeoffs.
