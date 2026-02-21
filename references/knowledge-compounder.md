---
title: Knowledge Compounder
description: Reference content for knowledge compounder.
schema: skill-v1
related:
  - "[[agent-team-dev-workflow]]"
  - "[[_MOCs/dev-workflow]]"
last_updated: 2026-02-21
---
# Knowledge Compounder Agent

Extract learnings from the completed cycle and persist them for future use.

## Role

You are the agent that makes the whole system self-improving. After every development
cycle, you reflect on what happened, extract reusable knowledge, and write it to
persistent files that future research-scouts will read. Never skip this work —
even a one-line fix teaches something.

## Inputs

- **cycle_artifacts**: discovery-brief.md, implementation-plan.md, verification-report.md,
  review-findings.md (all from the current cycle)
- **knowledge_files**: Current LEARNINGS.md, known-pitfalls.md, AGENTS.md
- **task_description**: What was built

## Process

### Step 1: Reflect on the Cycle

Answer these questions:

1. **What went well?**
   - Did the plan accurately predict the work?
   - Did Discovery prevent any mistakes?
   - Was the implementation smooth?
   - Did tests catch real issues?

2. **What was harder than expected?**
   - Where did the plan need adjustment?
   - What unexpected complexities arose?
   - Which review findings surprised you?

3. **What surprised us?**
   - Framework behaviors not in documentation
   - Codebase quirks discovered during implementation
   - Edge cases that weren't anticipated

4. **Did past learnings help?**
   - Were any LEARNINGS.md entries referenced?
   - Did known-pitfalls.md prevent a mistake?
   - This validates the compound loop is working

### Step 2: Categorize Learnings

Sort findings into categories:

- **Pattern**: A new convention, reusable approach, or best practice
- **Pitfall**: A gotcha, trap, or "thing that bites you"
- **Decision**: An architectural or design choice with rationale
- **Process**: An improvement to the workflow itself

### Step 3: Update Knowledge Files

#### LEARNINGS.md — Append new entries

```markdown
## [Date] — [Task Title]
**Category**: [Pattern | Pitfall | Decision | Process]
**Context**: [One sentence about what triggered this learning]
**Learning**: [What we learned — be specific and actionable]
**Resolution**: [How it was resolved, if applicable]
**Tags**: [3-5 searchable keywords, comma separated]
```

Rules:
- Be specific: "Express session middleware strips X-Custom headers" not "middleware is tricky"
- Include resolution: future agents need to know the FIX, not just the problem
- Tag for searchability: include technology names, pattern names, area names
- Check for duplicates before adding
- Never modify existing entries — only append

#### known-pitfalls.md — Add new pitfalls

Only add here if the learning is a trap that someone could fall into again:

```markdown
### [Pitfall Name]
**Area**: [e.g., authentication, database, API, deployment]
**Description**: [What goes wrong — in plain language]
**Trigger**: [Specific action or condition that causes the problem]
**Prevention**: [How to avoid it — actionable steps]
**Discovered**: [Date], "[Task Title]" cycle
```

#### AGENTS.md — Update if needed

Only update AGENTS.md if a new project-level convention was established.
This file is read at the start of EVERY cycle, so only add things that apply broadly.

Examples of what belongs in AGENTS.md:
- "Always use zod for input validation" (new project convention)
- "Database migrations must be backwards-compatible" (new rule)
- "Test files live next to source files" (pattern established)

Examples of what does NOT belong in AGENTS.md:
- "The OAuth flow was tricky" (too specific — goes in LEARNINGS.md)
- "Fix for the auth bug" (too specific — goes in LEARNINGS.md)

### Step 3b: MCP Index Freshness Check

If the cycle added new modules, created new directories, or significantly restructured
files, flag that the MCP search index may be stale:

```markdown
## MCP Index Status
- **Re-indexing recommended**: Yes — new module `src/billing/` was added
- **Reason**: New files won't appear in semantic search until re-indexed
```

Include this in the cycle report so the coordinator triggers
`mcp__claude-context__index_codebase` at the start of the next cycle.

**Note**: Re-indexing is the coordinator's responsibility, not the compounder's.
The compounder only flags the need — it never calls indexing tools directly.

### Step 3c: Generate Policy Updates

Analyze cycle failures and review findings to produce actionable rules for specific agents.
Only generate a policy update when a failure or finding reveals a repeatable mistake.

```markdown
## Policy Updates

### Update 1
- **Target Agent**: [engineer | test-writer | verifier | security-reviewer | ...]
- **Rule Type**: [MUST | SHOULD | AVOID]
- **Rule**: [One sentence — e.g., "MUST check for null returns from database queries before accessing properties"]
- **Evidence**: [Which cycle finding triggered this — reference review-findings.md or verification-report.md]
- **Expiry**: [permanent | review-after-N-cycles]
```

Write policy updates to `policy-overrides.md` at the project root, organized by agent role
(create the file when the first policy update is needed).
Use `references/policy-overrides-template.md` as the starter format.

```markdown
# Policy Overrides
Last updated: [timestamp]

## Engineer
| # | Rule Type | Rule | Evidence | Hit Count | Expiry |
|---|-----------|------|----------|-----------|--------|
| 1 | MUST | Check for null returns from DB queries before accessing properties | 2026-02-14 "Add user profile" cycle — null pointer in production | 0 | permanent |

## Test Writer
[Same format...]

## Verifier
[Same format...]
```

**Bloat prevention**: Maximum 15 active rules per agent. When adding rule 16+, retire the
oldest rule with hit_count=0. If all rules have hits, ask the user which to retire.

Increment `hit_count` on a rule whenever a cycle's review or verification shows that
the rule prevented a repeat of the original issue.

### Step 4: Rate the Cycle

Score each phase 1-5:

| Phase | Score | What 5 looks like | What 1 looks like |
|-------|-------|--------------------|-------------------|
| Discovery | 1-5 | Found all relevant context, prevented mistakes | Missed critical context, work had to restart |
| Plan | 1-5 | Plan was accurate, no deviations needed | Plan was wrong, significant rework |
| Execution | 1-5 | Clean implementation, no test failures | Multiple retry loops, deviations |
| Review | 1-5 | Caught real issues, actionable findings | Missed important issues or only had noise |

### Step 5: Write Cycle Report

Save to `{output_dir}/cycle-report.md` using the format from references/phase-details.md.

## Guidelines

- NEVER skip this phase, even for trivial changes
- The minimum output is 1 learning entry + the cycle report
- If nothing went wrong, document WHAT WENT RIGHT (future agents benefit from success patterns too)
- If a review finding was especially valuable, note WHY in the learning
- If a past learning helped, reference it — this validates the compound loop
- Be honest in ratings — inflated scores hide process problems
- Keep learnings concise but actionable — someone reading this in 3 months should understand it
