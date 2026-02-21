# Orchestration Patterns

How to execute the workflow across different Claude Code environments.

## Table of Contents

1. [Mode Detection](#mode-detection)
2. [Authority and Escalation](#authority-and-escalation)
3. [Subagent Mode](#subagent-mode)
4. [Agent Team Mode](#agent-team-mode)
5. [Inline Mode](#inline-mode)
6. [Parallelism Map](#parallelism-map)
7. [Error Handling](#error-handling)

---

## Mode Detection

At the start of every cycle, determine which execution mode is available:

```
1. Check if CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS is enabled
   → If yes: use Agent Team Mode
2. Check if spawn_agent tool is available
   → If yes: use Subagent Mode
3. Fallback: use Inline Mode
```

**Step 4: Read workflow configuration and check MCP search availability**

Before spawning any agents, probe for the `claude-context` MCP server:

```
mcp__claude-context__get_indexing_status({ path: project_root })
```

- **Tool exists + project is indexed** → `mcp_search_available = true`
- **Tool exists + project is NOT indexed** → trigger `mcp__claude-context__index_codebase({ path: project_root })`, wait for completion (~30-90s), then `mcp_search_available = true`
- **Tool call fails (no MCP configured)** → `mcp_search_available = false`

Pass `mcp_search_available` to the research-scout in its spawn prompt. This flag
tells the scout whether to attempt Tier 2 (semantic search) or skip to Tier 3.

Read optional workflow knobs from project instructions (AGENTS.md or `.workflow/config.md`)
to control scale and fan-out:

```markdown
## Workflow Configuration
- Enable multi-engineer Builder mode: true
- Max parallel engineers: 2
- Engineer shard strategy: task-boundary | file-boundary
```

- `max_parallel_engineers` is the explicit hard cap for parallel engineers in Work.
  If the value is missing or invalid, default to `1`.
- `engineer_shard_strategy` should stay `task-boundary` by default; use `file-boundary`
  only for UI-heavy changes where files are naturally partitioned.

**Selection heuristic** (when both are available):
- Simple features (< 5 files affected): Subagent Mode (lower overhead)
- Complex features (cross-cutting concerns, multiple modules): Agent Team Mode
- Exploration/research heavy: Agent Team Mode (teammates can share findings)
- Tight deadline, well-defined task: Subagent Mode (faster, less coordination)
- Multi-engineer is enabled only when Agent Team Mode is selected and complexity warrants it.

---

## Authority and Escalation

Authority is role-bound and coordinator-owned. No role starts implementation work outside
the phase contract.

- `SCOPE_ELEVATION`: work required outside contract (e.g., engineer touches unlisted files).
- `PLAN_DRIFT`: plan missing required acceptance criteria/tests after kickoff.
- `USER_ESCALATION`: unresolved verification failure at Ladder Level 4 or repeated critical findings.

Policy handling:
- If `policy-overrides.md` exists at the project root, include matching role rules in each
  engineer/reviewer spawn prompt.
- If missing, continue with `AGENTS.md` + phase instructions only.

For Work phase fan-out, set `engineer_count` from config:

1. Parse `max_parallel_engineers` from project workflow config.
2. Clamp it to at least `1`.
3. Only apply `engineer_count > 1` in Agent Team Mode; Subagent and Inline modes always use 1.

If `engineer_count` is not set, the workflow uses `1` (single engineer).

Use the following sequence on any escalation:
1. Pause work for the involved phase.
2. Route the failure packet to the coordinator with artifact references.
3. Resume only after user/planner approval and contract update.

## Subagent Mode

Use `spawn_agent` to spawn focused subagents. Each agent gets its own context window
and returns results to the coordinator.

### Spawning Agents

```
# Phase 0: Discover (sequential — must complete before Plan)
spawn_agent({
  description: "Research scout for [task]",
  prompt: "[Include: task description, project root, knowledge file paths,
           mcp_search_available=true/false]
           Read references/phase-details.md#phase-0-discover and follow the procedure.",
  model: "sonnet"
})

# Phase 1: Plan (planner gets opus 4.6 — highest-leverage model spend)
spawn_agent({
  description: "Create implementation plan for [task]",
  prompt: "[Include: task description, discovery brief, user answers]
           Read references/phase-details.md#phase-1-plan and follow the procedure.",
  model: "opus"
})

# Phase 2: Work (parallel — engineer + test-writer, both sonnet)
# Spawn both in the same turn.
# IMPORTANT: Blind Testing Protocol — test-writer gets contracts only, NOT source code.
# For N engineers, use one worker per task shard (N from engineer_count, typically 1-4).
spawn_agent({
  description: "Engineer #1 implementing [task]",
  prompt: "[Include: implementation plan shard assignment for Engineer #1, project root,
           policy-overrides.md rules for 'Engineer' if present,
           explicit file/task ownership map]
           Read references/phase-details.md#agent-engineer and follow the procedure.",
  model: "sonnet"
})
spawn_agent({
  description: "Engineer #2 implementing [task]",
  prompt: "[Include: implementation plan shard assignment for Engineer #2, project root,
           policy-overrides.md rules for 'Engineer' if present,
           explicit file/task ownership map]
           Read references/phase-details.md#agent-engineer and follow the procedure.",
  model: "sonnet"
})
spawn_agent({
  description: "Test writer for [task]",
  prompt: "[Include: implementation plan goal, delegation contracts, test strategy,
           ownership map from all engineer shards, public API signatures/interfaces ONLY
           — do NOT include engineer source code]
           Read references/phase-details.md#agent-test-writer and follow the Blind Testing Protocol.",
  model: "sonnet"
})

# Phase 4: Review (parallel — all three reviewers, all sonnet)
# Spawn all in the same turn:
spawn_agent({
  description: "Security review of [task]",
  prompt: "[Include: diff of changes]
           Read references/phase-details.md#agent-security-reviewer and follow the procedure.",
  model: "sonnet"
})
spawn_agent({
  description: "Architecture review of [task]",
  prompt: "[Include: diff of changes, discovery brief]
           Read references/phase-details.md#agent-architecture-reviewer and follow the procedure.",
  model: "sonnet"
})
spawn_agent({
  description: "Code quality review of [task]",
  prompt: "[Include: diff of changes]
           Read references/phase-details.md#agent-code-quality-reviewer and follow the procedure.",
  model: "sonnet"
})
```

### Model Selection for Subagents

All agents run on **Sonnet** by default except the planner which uses **Opus 4.6**.
The planner is the one agent where plan quality justifies the cost — a bad plan
wastes every downstream agent's work.

| Agent | Model | Rationale |
|-------|-------|-----------|
| research-scout | sonnet | Research and pattern matching |
| clarifier | (runs in main loop) | Needs user interaction |
| planner | **opus (claude-opus-4-6)** | Plan quality is the highest-leverage investment |
| engineer | sonnet | Follows the plan, doesn't need deep reasoning |
| test-writer | sonnet | Tests follow established patterns |
| verifier | sonnet | Runs commands and checks output |
| security-reviewer | sonnet | Checklist-driven review |
| architecture-reviewer | sonnet | Pattern comparison against conventions |
| code-quality-reviewer | sonnet | Checklist-driven review |
| knowledge-compounder | sonnet | Summarization and extraction |

### Context Handoff

Each subagent needs sufficient context to do its job without asking questions.
Include in the spawn prompt:

- **Always**: The task description, relevant file paths, applicable rules from `policy-overrides.md`
  (if present)
- **Discover**: Knowledge file paths, project root, `mcp_search_available` flag
- **Plan**: Discovery Brief (full content or path)
- **Work (engineer)**: Implementation Plan, task slice from shard plan, explicit ownership map,
  non-overlap constraint, policy overrides for "Engineer" (if present)
- **Work (test-writer)**: Goal, Delegation Contracts, Test Strategy, public interfaces ONLY (Blind Testing Protocol)
- **Test**: Verification commands, acceptance criteria, delegation contracts,
  engineer proofs (`{output_dir}/contract-proof.md` plus `contract-proof-engineer-*.md` if split)
- **Review**: Diff of all changes, Discovery Brief for convention context
- **Compound**: All cycle artifacts, current knowledge file content, current
  policy-overrides.md (if present)

---

## Agent Team Mode

If the runtime supports persistent teammate execution, use this mode to let work streams
coordinate with each other.

### Team Structure

Use a single coordinator role plus domain roles:

- Scout: `research-scout`
- Builder: one or more engineers + test-writer
- Auditors: `security-reviewer`, `architecture-reviewer`, `code-quality-reviewer`
- Scribe: `knowledge-compounder`

### Communication Pattern

- Share findings from scout directly with builder before implementation.
- If multiple engineers run, the builder team should share a lightweight ownership map in a shared
  channel before Work starts (files/tickets each engineer owns, dependencies, merge order).
- Route audit findings into the next decision point before moving to Compound.
- Keep shared artifacts (`implementation-plan.md`, `discovery-brief.md`, `engineer_task_assignments.md`, and findings)
  as the coordination boundary.

### Multi-Engineer Conditions and Limit

- Multi-engineer fan-out is opt-in and should only be used when tasks can be split safely.
- Practical upper bound should stay at `max_parallel_engineers` from configuration.
- If you have no explicit config, assume `1`. This means no hardcoded code limit in the skill itself;
  the runtime limit is controlled by project-specific instructions.
- Recommended default range is `1-4` engineers; higher values should be used only with strict ownership
  and integration plans.

### When to Use Agent Teams vs Subagents

| Signal | → Agent Teams | → Subagents |
|--------|---------------|-------------|
| Agents need to share findings | ✅ | ❌ |
| Task has many cross-cutting concerns | ✅ | ❌ |
| Research findings affect how code is written | ✅ | ❌ |
| Simple, well-scoped task | ❌ | ✅ |
| Cost is a concern | ❌ | ✅ |
| Fast turnaround needed | ❌ | ✅ |

---

## Inline Mode

When agent-team runtime is not available, execute all agent roles
sequentially in the main conversation loop.

### Procedure

1. Read each agent's reference file (references/*.md) before executing that phase
2. Follow the procedure as written — the agent files work as inline instructions
3. Between phases, summarize what was done and what's next
4. For the Review phase, do all three reviews sequentially (security → architecture → quality)

### Limitations

- Same context window executes and reviews its own code (reduced objectivity)
- No parallelism — everything is sequential
- Context window fills up faster
- Acknowledge to the user that review rigor is reduced

### Mitigation

- Be extra explicit about switching "hats" between phases
- After writing code, re-read the diff as if seeing it for the first time
- For review, focus on the checklist items — don't skip because "I just wrote this"
- Consider breaking large tasks into multiple inline cycles

---

## Parallelism Map

Which agents can run in parallel within each mode:

```
Phase 0: Discover     → [research-scout]            (sequential)
Phase 1: Plan         → [clarifier] → [planner]     (sequential)
Phase 2: Work         → [engineer x N] + [test-writer]   (PARALLEL)
Phase 3: Test         → [verifier]                   (sequential)
Phase 4: Review       → [security] + [arch] + [quality]  (PARALLEL)
Phase 5: Compound     → [knowledge-compounder]       (sequential)
```

In Subagent Mode: Spawn parallel agents in the same turn.
In Agent Team Mode: Spawn parallel teammates and let them self-coordinate.
In Inline Mode: Execute all sequentially.

---

## Error Handling

### Test Failures (Phase 3 → Phase 2 escalation ladder)

```
Level 1: Run tests → fail
  → Return to Phase 2 with: failed test output + specific failing assertion
  → Engineer fixes quickly and re-runs verifier

Level 2: Run tests → fail again (or same failure pattern persists)
  → Return to Phase 2 with: Level 1 packet + failure-class analysis
    (scope mismatch, wrong assumption, missing prerequisite, plan drift)
  → Planner may amend tasks before Work resumes

Level 3: Run tests → fail again (or failure persists after re-work and re-plan)
  → Return to Phase 2 with a re-discovery package:
    - alternate causes, assumptions, and hypotheses tested
    - fresh evidence from logs, mocks, and environment checks
    - a revised workplan and ownership map

Level 4: Run tests → fail again (or failure still unresolved)
  → Escalate to user: "Verification hit the escalation ladder.
    Here's what changed and what remains blocked.
    Options: [alternative approach], [narrow scope], [you take a look]"
```

### Critical Review Findings (Phase 4 → Phase 2 loop)

```
Review finds Critical issue:
  → Return to Phase 2 with: specific finding, file:line, remediation
  → Engineer applies the fix
  → Re-run ONLY the relevant reviewer (not all three)
  → If the fix introduces new issues, escalate to user
```

### Discovery Conflicts (Phase 0 → User)

```
If Discovery Brief reveals conflicting patterns in the codebase:
  → Flag to user: "The codebase has two different approaches to [X]:
    [Approach A in files...] and [Approach B in files...].
    Which should I follow?"
  → Wait for user decision before planning
```

### Agent Communication Failures (Agent Team Mode)

```
If a teammate becomes unresponsive:
  → Wait 60 seconds
  → Send a follow-up message
  → If still unresponsive after 120 seconds, spawn a replacement
  → Provide the replacement with the original task + any partial results
```
