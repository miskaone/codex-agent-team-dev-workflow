---
title: Phase 0 Discover
description: Fast context discovery using prebuilt knowledge first, then optional semantic search, then targeted file reads.
phase: 0
authority:
  owner: research-scout
related:
  - "[[agent-team-dev-workflow]]"
  - "[[agents/research-scout]]"
  - "[[references/phase-details]]"
  - "[[references/knowledge-system]]"
  - "[[references/mcp-setup]]"
  - "[[knowledge/system]]"
schema: skill-v1
last_updated: 2026-02-21
---

# Phase 0: Discover (Optimized Research)

**Purpose**: remove assumptions before planning. ~10% of cycle.

## 3-Tier strategy
1. **Tier 1 – instant context**: `LEARNINGS.md`, `known-pitfalls.md`, `AGENTS.md`, and codebase map in [[knowledge/system]].
2. **Tier 2 – MCP semantic search**: call `mcp__claude-context__search_code` when indexed.
3. **Tier 3 – targeted reads**: only specific files and recent git history.

## Rules
- Do not broad-scan or recursive grep the full codebase.
- Read until context is sufficient, then stop.

## Output
Write `discovery-brief.md`.
