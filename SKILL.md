---
name: agent-team-dev-workflow
description: >
  Multi-agent development workflow that orchestrates specialized agent teams through
  a six-phase engineering cycle: Discover → Plan → Work → Test → Review → Compound.
  Use this skill whenever the user asks to build a feature, fix a bug, implement a task,
  or work on any code change — even if they don't explicitly mention "agents" or "workflow."
  Also trigger when the user says "build this," "implement," "add feature," "fix this,"
  "refactor," "let's work on," or references any development task. This skill replaces
  ad-hoc coding with a structured, self-improving engineering process where every cycle
  makes the next one easier. Supports both subagent (`spawn_agent`) and agent team
  (agent team mode) execution modes.
---

# Agent Team Development Workflow

A six-phase compound engineering workflow that orchestrates specialized agent teams
to plan, build, test, review, and learn from every development cycle. Each phase
has dedicated agents with clear roles, and every completed cycle feeds learnings
back into the system so Claude never repeats mistakes.

## Philosophy

**Each unit of engineering work should make subsequent units easier — not harder.**

Traditional development accumulates technical debt. This workflow inverts that by:
- Spending 80% of effort on planning and review, 20% on execution
- Capturing learnings after every cycle into persistent knowledge files
- Using specialized agents so no single context gets overwhelmed
- Running independent work in parallel when possible

## Quick Start

When a user describes a task, run the full cycle:

```
Discover → Plan → Work → Test → Review → Compound
```

For small fixes or patches, you can abbreviate to: `Plan → Work → Test → Compound`

Read `references/phase-details.md` for the full agent specifications and prompts.
Read `references/orchestration-patterns.md` for execution mode selection and parallelism.
Read `references/knowledge-system.md` for how learnings are captured and retrieved.

This workflow enforces role boundaries and escalation events:
- Each agent must report scope and only perform actions defined in `references/phase-details.md`.
- If scope changes are required, route a `SCOPE_ELEVATION` signal to the coordinator.
- Verification failures use a **4-level escalation ladder** (Level 1 → Level 2 → Level 3 → Level 4) before user escalation.

- If `policy-overrides.md` exists at the project root, apply its role-specific rules
  when spawning each agent.

---

## The Six Phases

### Phase 0: Discover (Optimized Research)

**Purpose**: Eliminate assumptions before any plan is written — fast.  
**Agent**: `research-scout` (sonnet)  
**Time allocation**: ~10% of cycle

The research-scout uses a **three-tier context strategy** to avoid slow, brute-force
codebase scanning. Tiers are checked in order; stop as soon as you have enough context.

#### Tier 1: Pre-Built Context (instant — no scanning)

Check these first. If they answer the question, skip Tier 2 and 3 entirely:

1. **LEARNINGS.md** — Search by task keywords for past learnings
2. **known-pitfalls.md** — Check relevant area headings for traps
3. **AGENTS.md / CLAUDE.md** — Read project conventions (always loaded anyway)
4. **Codebase Map** (`references/codebase-map.md`) — A pre-generated summary of
   the project's architecture, module boundaries, key files, and patterns.
   This file is generated once and updated during the Compound phase.
   See `references/knowledge-system.md` for the codebase-map format.

If Tier 1 gives the scout enough context to identify affected files, existing patterns,
and relevant constraints → produce the Discovery Brief and move to Plan.

#### Tier 2: Semantic Code Search via MCP (fast — indexed)

If the coordinator determined that `mcp_search_available=true` (see Coordinator
Responsibilities #11), the scout uses `mcp__claude-context__search_code` for
semantic search instead of grep:

```
mcp__claude-context__search_code({
  path: "/path/to/project",
  query: "user authentication middleware",
  limit: 5
})
```

This returns relevant code chunks ranked by semantic similarity — no need to guess
file names or grep patterns. ~40% fewer tokens than brute-force scanning.

The coordinator handles indexing lifecycle (first-run indexing, re-indexing). The
scout only needs to call `search_code` — it never indexes.

See `references/mcp-setup.md` for setup options (Ollama+LanceDB local, OpenAI+LanceDB,
or no MCP).

If MCP search is available, prefer it over Tier 3 for codebase exploration.
If `mcp_search_available=false`, skip directly to Tier 3.

#### Tier 3: Targeted File Access (slower — use sparingly)

Only reach for direct file reading when Tier 1 and 2 don't have the answer:

- Read specific files identified by the codebase-map or MCP search results
- Use `git log --oneline -10 -- <specific-path>` for recent change history
- Check specific test files to understand test patterns

**Never** do broad recursive grep across the whole codebase. If you need to find
something and don't have MCP search, use the codebase-map to narrow to the right
directory first, then search within that directory only.

**Output**: `discovery-brief.md` in the working directory

### Phase 1: Plan (Clarify → Research → Specify)

**Purpose**: Turn the task into an unambiguous, executable specification.  
**Agents**: `clarifier`, `planner`  
**Time allocation**: ~30% of cycle

#### Step 1a: Clarify (Human-in-the-Loop)

The `clarifier` agent analyzes the task and the Discovery Brief, then asks the user
targeted questions. These are NOT generic questions — they are specific to what the
Discovery Brief revealed:

- Ambiguities the codebase doesn't resolve
- Competing approaches where the user's preference matters
- Scope boundaries ("Should this also handle X?")
- Acceptance criteria the user cares about

**Rule**: Ask a maximum of 5 questions. Group them. Wait for answers before proceeding.
If the task is unambiguous and the Discovery Brief is clear, skip to Step 1b.

#### Step 1b: Specify

The `planner` agent produces an **Implementation Plan** that includes:

- **Goal**: One sentence stating what this change accomplishes
- **Approach**: Which approach from the Discovery Brief was selected and why
- **Tasks**: Numbered checklist of concrete implementation steps
- **Test Strategy**: What tests to write and what they verify
- **Risk Mitigation**: How identified risks from Discovery will be handled
- **Acceptance Criteria**: How to verify the feature is complete
- **Files Affected**: Explicit list of files to create, modify, or delete

**Output**: `implementation-plan.md` in the working directory

**Gate**: Present the plan to the user for approval before proceeding to Work.

### Phase 2: Work (Build)

**Purpose**: Execute the plan. Write code and tests.  
**Agents**: `engineer` (1+ shards in Agent Team Mode), `test-writer`  
**Time allocation**: ~10% of cycle

The `engineer` agents:
1. Works through the Implementation Plan task-by-task
2. Follows existing codebase conventions identified in Discovery
3. Writes code incrementally — commits or checkpoints after each logical unit
4. Runs existing tests after each change to catch regressions immediately
5. Flags deviations from the plan with rationale

In Agent Team Mode, the coordinator can enable multiple engineers for large or modular work. Assign each
engineer a non-overlapping file/task slice and keep ownership explicit in the contract.

The `test-writer` agent (can run in parallel):
1. Writes tests according to the Test Strategy in the plan
2. Covers happy path, edge cases, and error conditions
3. Ensures tests are independent and deterministic
4. Validates tests actually fail when the feature is removed (tests-test-the-right-thing)

**Output**: Code changes + test files

**Rule**: If any existing test breaks, STOP and fix before continuing.
If the fix requires changing the plan, go back to Phase 1.

### Phase 3: Test (Verify)

**Purpose**: Run all tests, lint, type-check. Verify the feature works end-to-end.  
**Agent**: `verifier`  
**Time allocation**: ~10% of cycle

The `verifier` agent:
1. Runs the full test suite (not just new tests)
2. Runs linters and type checkers if configured
3. Performs a smoke test of the feature against acceptance criteria
4. Checks for common issues: unused imports, debug statements, hardcoded values
5. Produces a **Verification Report** with pass/fail status

If verification fails, use a 4-level escalation ladder and return to Phase 2:
- Level 1 (Self-correct): Return with minimal failure packet (failing command, assertion, and error output).
- Level 2 (Re-work): Return with failure-class analysis and adjusted approach.
- Level 3 (Re-plan): Return with revised scope/task plan and updated assertions.
- Level 4 (Re-discover): Pause and gather additional evidence/context, then propose a new plan before repeating.

Do not loop indefinitely; escalate after Level 4.

**Output**: `verification-report.md`

### Phase 4: Review (Multi-Agent Assessment)

**Purpose**: Catch issues that tests don't cover.  
**Agents**: `security-reviewer`, `architecture-reviewer`, `code-quality-reviewer`  
**Time allocation**: ~30% of cycle

Launch all three reviewers in parallel. Each produces findings independently.

#### Security Reviewer
- Input validation and sanitization
- Authentication/authorization implications
- Secrets, credentials, or sensitive data exposure
- Dependency vulnerabilities
- OWASP Top 10 relevance

#### Architecture Reviewer
- Consistency with existing patterns and conventions
- Separation of concerns
- Coupling and cohesion
- Scalability implications
- Breaking changes to public APIs

#### Code Quality Reviewer
- Readability and maintainability
- DRY violations
- Error handling completeness
- Performance concerns (N+1 queries, unnecessary allocations)
- Documentation gaps

Each reviewer produces findings with severity levels:
- **🔴 Critical**: Must fix before shipping
- **🟡 Warning**: Should fix, but not blocking
- **🟢 Suggestion**: Nice to have

**Output**: `review-findings.md` (consolidated from all reviewers)

**Gate**: If any Critical findings exist, loop back to Phase 2.
Present Warning and Suggestion findings to the user for triage.

### Phase 5: Compound (Learn and Codify)

**Purpose**: Extract learnings so future cycles improve.  
**Agent**: `knowledge-compounder`  
**Time allocation**: ~10% of cycle

This is the phase that makes the system self-improving. After the feature is complete:

1. **Reflect**: What went well? What was harder than expected? What surprised us?
2. **Extract Patterns**: New conventions, reusable approaches, or architectural decisions
3. **Document Failures**: Bugs found in review, test failures, plan deviations — and their fixes
4. **Update Knowledge Files**:
   - `LEARNINGS.md` — Append new learnings with date, context, and resolution
   - `AGENTS.md` / `CLAUDE.md` — Update project-level rules if a new convention was established
   - `references/known-pitfalls.md` — Add to the pitfalls database
5. **Rate the Cycle**: Score 1-5 on plan quality, execution quality, and review quality

**Output**: Updates to knowledge files + `cycle-report.md`

**Rule**: NEVER skip this phase. Even for small fixes, capture at least one learning.
The compound step is what differentiates this from transactional AI coding.

---

## Execution Modes

The skill automatically selects the best execution mode based on environment capabilities.
Read `references/orchestration-patterns.md` for full details.

### Mode 1: Subagents (`spawn_agent`)
- Use when `spawn_agent` is available but agent teams are not
- Each agent is spawned as a focused subagent with dedicated context
- Parallel agents are spawned in the same turn
- Results return to the coordinator (this skill)
- The coordinator remains the boundary owner for all scope changes.
- No subagent may write outside its role contract.

### Mode 2: Agent Teams (agent team mode)
- Use when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is enabled
- Each agent becomes a teammate with its own context window
- Teammates can communicate directly with each other
- Shared task list for self-coordination
- Best for complex features with cross-cutting concerns
- Teammates execute within role boundaries; scope expansion still requires coordinator/user confirmation.

### Mode 3: Inline (No Subagents)
- Fallback when neither `spawn_agent` nor agent team mode is available
- Execute each agent's role sequentially in the main loop
- Read the agent reference files and follow procedures directly
- Acknowledge reduced rigor: same context executes and reviews

---

## Knowledge System

The compound phase writes to persistent knowledge files that the discover phase reads.
This creates the learning loop.

```
                    ┌─────────────────┐
                    │  codebase-map   │ ← Tier 1 (instant)
                    │  LEARNINGS.md   │
                    │  AGENTS.md      │
                    │  known-pitfalls │
                    └────────┬────────┘
                             │ reads
                    ┌────────▼────────┐
                    │ claude-context / │ ← Tier 2 (if available)
                    │ search_code()   │
                    └────────┬────────┘
                             │ fills gaps
            ┌───────┌────────▼────────┐
            │       │    Discover     │
            │       └────────┬────────┘
            │                │
            │       ┌────────▼────────┐
            │       │      Plan       │
            │       └────────┬────────┘
            │                │
            │       ┌────────▼────────┐
   writes   │       │      Work       │
            │       └────────┬────────┘
            │                │
            │       ┌────────▼────────┐
            │       │      Test       │
            │       └────────┬────────┘
            │                │
            │       ┌────────▼────────┐
            │       │     Review      │
            │       └────────┬────────┘
            │                │
            │       ┌────────▼────────┐
            └───────┤    Compound     │ → updates codebase-map
                    └─────────────────┘    + LEARNINGS + pitfalls
```

Read `references/knowledge-system.md` for file formats and retrieval strategies.

---

## Model Policy

All agents run on **Sonnet** except the **planner** which uses **Opus 4.6** (`claude-opus-4-6`).
The planner is the highest-leverage model spend in the cycle — a precise plan means every
downstream agent (engineer, test-writer, reviewers) executes efficiently on Sonnet.
A bad plan wastes every agent's work regardless of model.

## Agent Summary

| Agent | Phase | Model | Role | Parallel? |
|-------|-------|-------|------|-----------|
| `research-scout` | Discover | sonnet | Research codebase + external best practices | No (runs first) |
| `clarifier` | Plan | (main loop) | Ask targeted questions to resolve ambiguity | No (needs user) |
| `planner` | Plan | **opus 4.6** | Produce Implementation Plan from brief + answers | No (sequential) |
| `engineer` | Work | sonnet | Implement the plan task-by-task | Yes (with test-writer; 1+ engineers when enabled) |
| `test-writer` | Work | sonnet | Write tests per the test strategy | Yes (with engineer) |
| `verifier` | Test | sonnet | Run full test suite + acceptance criteria | No (sequential) |
| `security-reviewer` | Review | sonnet | Security assessment | Yes (all reviewers) |
| `architecture-reviewer` | Review | sonnet | Architecture assessment | Yes (all reviewers) |
| `code-quality-reviewer` | Review | sonnet | Code quality assessment | Yes (all reviewers) |
| `knowledge-compounder` | Compound | sonnet | Extract and persist learnings | No (runs last) |

---

## Working Directory Structure

```
{project-root}/
├── .workflow/                        # Workflow artifacts (gitignore this)
│   ├── current/                      # Active cycle
│   │   ├── discovery-brief.md
│   │   ├── implementation-plan.md
│   │   ├── contract-proof.md
│   │   ├── verification-report.md
│   │   ├── deviations.md
│   │   ├── review-findings.md
│   │   └── cycle-report.md
│   └── history/                      # Past cycles
│       ├── 2026-02-09-add-auth/
│       └── 2026-02-08-fix-api/
├── LEARNINGS.md                      # Persistent learnings (committed)
├── AGENTS.md                         # Project-level agent instructions
└── ...
```

---

## Coordinator Responsibilities

As the coordinator, you must:

1. **Determine execution mode** at the start (subagent, team, or inline)
2. **Run Discover before Plan** — never skip research
3. **Present the plan for approval** — the user must approve before Work begins
4. **Parallelize independent work** — reviewers always run in parallel; in Agent Team Mode, multiple
   engineers can also run in parallel when risk and scope allow.
5. **Enforce gates** — Critical findings block shipping
6. **Never skip Compound** — even for one-line fixes, capture something
7. **Track cycle metrics** — time per phase, retry count, findings count
8. **Consult knowledge files first** — check LEARNINGS.md and known-pitfalls.md before every cycle
9. **Escalate don't spin** — use a 4-level verification ladder before asking the user
10. **Archive completed cycles** — move artifacts to history after compound
11. **Enforce phase boundaries** — verify each subagent stays within role authority from `references/phase-details.md`.
12. **Handle `SCOPE_ELEVATION`** — if a role must edit outside scope, pause, escalate to user/planner, then resume with updated contract.
13. **Coordinate engineer fan-out** — when multiple engineers are enabled, define ownership slices, prevent file overlap,
    and merge partial contract proofs into one final `{output_dir}/contract-proof.md` before verification.
14. **Manage MCP indexing lifecycle** — before spawning the research-scout, probe
    `mcp__claude-context__get_indexing_status({ path: project_root })`. If the tool
    exists and the project is indexed, set `mcp_search_available=true`. If the tool
    exists but the project is not indexed, trigger `mcp__claude-context__index_codebase`
    and wait for completion. If the tool call fails (no MCP configured), set
    `mcp_search_available=false`. Pass this flag to the scout in its spawn prompt.

---

## Customization

Users can customize the workflow by:
- **Skipping Discover** for trivial changes (user must explicitly opt out)
- **Adding domain-specific reviewers** (e.g., `accessibility-reviewer`, `compliance-reviewer`)
- **Adjusting review severity thresholds** per project
- **Configuring which knowledge files exist** and where they live
- **Maintaining `policy-overrides.md`** when role-specific hard rules are needed
- **Configuring the verification ladder** for test failures (default: 4 levels)

See `references/customization.md` for configuration options.
