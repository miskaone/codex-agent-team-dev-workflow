---
title: Phase Details
description: Cross-cut concerns, per-phase behaviors, and role contracts.
schema: skill-v1
related:
  - "[[agent-team-dev-workflow]]"
  - "[[_MOCs/dev-workflow]]"
  - "[[agents/quality-guardian]]"
  - "[[references/compound-advanced]]"
last_updated: 2026-02-21
---
# Phase Details & Agent Specifications

Complete reference for each phase's agents, inputs, outputs, and procedures.

## Table of Contents

1. [Phase 0: Discover](#phase-0-discover)
2. [Phase 1: Plan](#phase-1-plan)
3. [Phase 2: Work](#phase-2-work)
4. [Phase 3: Test](#phase-3-test)
5. [Phase 4: Review](#phase-4-review)
6. [Phase 5: Compound](#phase-5-compound)

## Role Authority Boundaries

Apply these defaults unless the task-specific policy explicitly changes them.

- `research-scout`: read context and produce a Discovery Brief; never edit code/tests/artifacts.
- `clarifier`: ask user questions and clarify scope; never change plans or code.
- `planner`: produce contracts and plans; no implementation or test execution.
- `engineer`: implement only files/tasks in the approved plan; no reviewer-style assertions.
- `test-writer`: write tests only from the plan's test strategy/contracts.
- `verifier`: execute checks and verify criteria; never patch source code.
- `security-reviewer`, `architecture-reviewer`, `code-quality-reviewer`: read and report findings only.
 - `knowledge-compounder`: update LEARNINGS/pitfalls/rules based on outcomes; no implementation changes.
 - `quality-guardian`: optional role for constructive pressure on edge-cases and coverage.

### Optional Advanced Reference Prompts
- [[agents/quality-guardian]] — optional rigor-focused role for alternating-cycle diversity.
- [[references/compound-advanced]] — optional enhancement prompt for compounding quality insights.

Escalation protocol:
- `SCOPE_ELEVATION`: role needs to exceed its boundary
- `PLAN_DRIFT`: plan is insufficient for remaining work
- `USER_ESCALATION`: unresolved conflicts, repeated failures, or critical findings blocking progress

---

## Phase 0: Discover

### Agent: research-scout

**Role**: Gather all relevant context before anyone writes a plan or touches code.
**Authority Boundary**: read-only, discovery-focused work only; create `discovery-brief.md` as the artifact.
**Escalation Trigger**: If both Tiers 1 and 2 are insufficient and Tier 3 access would be unsafe or incomplete, request `PLAN_DRIFT` with missing context details.

**Inputs**:
- User's task description
- Project root path
- Paths to knowledge files (LEARNINGS.md, AGENTS.md, known-pitfalls.md)

**Process**:

1. **Check Knowledge Files First**
   - Read LEARNINGS.md for relevant past learnings (search by keywords from the task)
   - Read known-pitfalls.md for traps related to this area
   - Read AGENTS.md for project conventions that apply
   - If any prior cycle addressed a similar task, read its cycle-report.md

2. **Scan the Codebase** (Three-Tier Strategy)

   **Tier 1** (already done in step 1 above): Knowledge files give you the module
   index, key patterns, and past learnings. If this is enough context → skip to step 5.

   **Tier 2** (if `mcp_search_available=true`): Use semantic search to fill gaps:
   ```
   mcp__claude-context__search_code({
     path: "{project_root}",
     query: "how is [specific pattern] implemented",
     limit: 5
   })
   ```
   Formulate 2-3 natural language queries targeting the gaps from Tier 1.
   If search returns empty results, note this for the Compound phase and fall to Tier 3.

   **Tier 3** (last resort): Read specific files narrowed by the codebase-map or MCP results:
   - Read specific files identified by the codebase-map or search results
   - Check test patterns: how are similar features tested?
   - Review git log for recent changes in affected areas
   - Note any TODO/FIXME/HACK comments in related files
   - **Never** grep recursively across the entire project

3. **Research External Best Practices**
   - If the task involves a framework, check current docs for recommended approach
   - If the task involves security, check for known vulnerabilities in relevant packages
   - If the task is a common pattern, find the idiomatic way to implement it
   - Use web search or MCP tools if available

4. **Identify Constraints**
   - CI/CD requirements (what must pass before merge?)
   - Dependency versions and compatibility
   - API contracts (will this change break consumers?)
   - Performance requirements or SLAs
   - Team conventions from AGENTS.md

5. **Produce Discovery Brief**

**Discovery Brief Format**:

```markdown
# Discovery Brief: [Task Title]
Generated: [timestamp]

## Task Understanding
[1-2 sentences restating the task in your own words]

## Relevant Codebase Context
- **Existing patterns**: [How similar things are done in this codebase]
- **Affected files**: [List of files that will likely need changes]
- **Test patterns**: [How similar features are tested here]
- **Recent activity**: [Relevant recent git commits]

## Knowledge from Past Cycles
- [Relevant learnings from LEARNINGS.md]
- [Relevant pitfalls from known-pitfalls.md]
- [Relevant conventions from AGENTS.md]

## External Research
- [Framework best practices]
- [Security considerations]
- [Common pitfalls for this type of task]

## Recommended Approaches
1. **[Approach A]**: [Description, pros, cons]
2. **[Approach B]**: [Description, pros, cons]
- **Recommendation**: [Which approach and why]

## Identified Risks
- [Risk 1]: [Likelihood, impact, mitigation]
- [Risk 2]: [Likelihood, impact, mitigation]

## Constraints
- [CI/CD requirements]
- [Dependency constraints]
- [API contract considerations]

## Research Method
- Tier 1 (knowledge files): [✅ Used / ⏭️ Skipped] — [details]
- Tier 2 (MCP semantic search): [✅ Used (N queries) / ⏭️ Skipped — mcp_search_available=false / ⏭️ Skipped — Tier 1 sufficient]
- Tier 3 (file reads): [✅ Used (N files) / ⏭️ Skipped]
- External research: [✅ Used / ⏭️ Skipped]

## Open Questions for User
- [Questions that research couldn't resolve]
```

---

## Phase 1: Plan

### Agent: clarifier

**Role**: Ask the user targeted questions to resolve ambiguity. Not generic questions —
questions informed by what the Discovery Brief revealed.
**Authority Boundary**: asks and synthesizes clarifying questions only; no direct implementation decisions.
**Escalation Trigger**: If ambiguity remains after 5 questions or safety-sensitive choices are required, return `USER_ESCALATION` with options.

**Inputs**:
- User's original task description
- Discovery Brief from Phase 0

**Process**:

1. Read the Discovery Brief's "Open Questions" section
2. Identify any ambiguities in the task that the Discovery Brief didn't resolve
3. If multiple approaches are viable, ask the user's preference
4. Formulate a maximum of 5 questions, grouped logically
5. Include your recommendation with each question so the user can just say "yes"

**Question Format**:

```
I've researched [task area] and have a few questions before I build the plan:

1. **[Topic]**: [Specific question]
   → I'd recommend [X] because [reason from research]. Sound good?

2. **[Topic]**: [Specific question]
   → Based on how [similar thing] is implemented, I'd suggest [Y].

[etc., max 5 questions]
```

**Skip Condition**: If the task is unambiguous AND the Discovery Brief has no open questions
AND there's only one reasonable approach, skip clarification and tell the user you're
proceeding directly to planning.

### Agent: planner

**Role**: Produce a detailed, executable Implementation Plan.
**Authority Boundary**: define scope and dependencies only; no edits to production code or tests.
**Escalation Trigger**: if required acceptance criteria or risk controls are missing, return `PLAN_DRIFT` with an update request.

**Inputs**:
- User's task description
- Discovery Brief
- User's answers to clarification questions (if any)

**Process**:

1. Select the approach (from Discovery Brief recommendations + user input)
2. Break the approach into concrete, ordered tasks
3. For each task, specify which files to touch and what changes to make
4. Define the test strategy: what tests, what they verify, where they go
5. Map risks from Discovery Brief to specific mitigation steps
6. Define acceptance criteria that a verifier can check programmatically

**Implementation Plan Format**:

```markdown
# Implementation Plan: [Task Title]
Generated: [timestamp]
Based on: discovery-brief.md

## Goal
[One sentence: what this change accomplishes]

## Selected Approach
[Which approach was selected and why]

## Tasks

### Task 1: [Description]
- **Files**: [Create/Modify/Delete which files]
- **Changes**: [Specific description of what to change]
- **Dependencies**: [Which tasks must complete before this one]

### Task 2: [Description]
[...]

## Delegation Contracts

For each task above, define a verifiable contract:

### Task 1 Contract
- **Input Preconditions**: [What must be true before this task starts]
- **Success Assertions**:
  - [ ] [Specific, verifiable statement — e.g., "POST /api/users returns 201 with valid payload"]
  - [ ] [Another assertion]
- **Proof Required**: [Test name, output snippet, or CLI command that proves it]
- **Boundary**: [What this task must NOT touch]

### Task 2 Contract
[Same format...]

> **Why contracts?** Acceptance criteria describe the end state. Contracts describe
> per-task verification — the engineer must return proof for each assertion, and the
> verifier checks assertions against proof rather than subjectively judging "does it work."

## Test Strategy
- **Unit tests**: [What to test, where to put them]
- **Integration tests**: [What to test, where to put them]
- **Edge cases**: [Specific edge cases to cover]
- **Regression**: [Existing tests that should still pass]

## Risk Mitigation
- **[Risk from Discovery]**: [How this plan handles it]

## Acceptance Criteria
- [ ] [Criterion 1 — must be verifiable]
- [ ] [Criterion 2]
- [ ] All existing tests pass
- [ ] No new linter warnings

## Files Affected
| File | Action | Reason |
|------|--------|--------|
| `src/auth/handler.ts` | Modify | Add OAuth flow |
| `src/auth/handler.test.ts` | Create | Unit tests |
| `src/types/auth.ts` | Modify | Add new types |
```

---

## Phase 2: Work

### Agent: engineer

**Role**: Implement the plan task-by-task. Write production code.
**Authority Boundary**: modify only plan-approved files and tasks; do not change test strategy or reviewer scope.
**Escalation Trigger**: if a needed change is outside plan scope, return `SCOPE_ELEVATION` and pause work.

**Inputs**:
- Implementation Plan
- Project codebase
- Optional engineering assignment map (`{output_dir}/engineer_task_assignments.md`)

If multiple engineers are running, each one gets one assignment slice and does only that slice.

**Process**:

1. Read the Implementation Plan completely before starting
2. Work through tasks in order, respecting dependencies and your slice ownership.
3. For each task:
   a. Read the affected files to understand current state
   b. Make the changes described in the plan
   c. Run existing tests to check for regressions
   d. If a test breaks, fix immediately or flag as plan deviation
4. If you need to deviate from the plan, document why
5. Keep changes within your slice. If another slice needs your file, escalate `SCOPE_ELEVATION`.
6. After all tasks complete, do a self-review pass:
   - Remove any debug statements
   - Ensure consistent formatting
   - Check for unused imports

**Expected Proof Output**:

- Default single engineer: `{output_dir}/contract-proof.md`
- Multiple engineers: `{output_dir}/contract-proof-engineer-[slug].md` for each engineer
  (coordinator merges to `{output_dir}/contract-proof.md` after Work).

**Guidelines**:
- Follow the codebase's existing style, not your preferred style
- If the Discovery Brief identified conventions, follow them exactly
- Prefer small, incremental changes over large rewrites
- If something feels wrong, stop and flag rather than pushing through

### Agent: test-writer

**Role**: Write comprehensive tests per the plan's Test Strategy.
**Authority Boundary**: create/modify test artifacts only; do not edit production code.
**Escalation Trigger**: if required scenarios are missing or uncertain from the plan/contracts, return `PLAN_DRIFT` before writing broad tests.

**Inputs**:
- Implementation Plan (specifically the Test Strategy section)
- The code changes from the engineer (or the plan, if running in parallel)
- Optional engineer assignment map for multi-engineer runs

**Process**:

1. Read the Test Strategy section of the Implementation Plan
2. For each test category (unit, integration, edge cases):
   a. Write the test file using the project's existing test patterns
   b. Include descriptive test names that explain the behavior being tested
   c. Cover both success and failure paths
   d. Include edge cases identified in the plan
3. Verify tests follow project conventions (discovered in Phase 0)
4. Run the new tests to confirm they pass
5. Temporarily break the feature to confirm tests catch the failure
   (if practical — skip for integration tests)

**Test Quality Checklist**:
- [ ] Tests are independent (no shared state, no ordering dependency)
- [ ] Tests are deterministic (no flaky behavior, no time-dependent assertions)
- [ ] Test names describe the behavior, not the implementation
- [ ] Failure messages are informative
- [ ] Edge cases from the plan are covered
- [ ] Error conditions are tested (not just happy path)

---

## Phase 3: Test

### Agent: verifier

**Role**: Run the full test suite and verify acceptance criteria.
**Authority Boundary**: execute validation only; never patch code or rewrite plan files.
**Escalation Trigger**: if this is the third failed verification attempt, return `USER_ESCALATION` with the failure timeline.

**Inputs**:
- Implementation Plan (acceptance criteria)
- Code changes + new tests from Phase 2

**Process**:

1. **Run the full test suite** (not just new tests)
   - If the project has a CI script, use it
   - Otherwise: run tests, linter, type checker in sequence
2. **Check acceptance criteria** from the Implementation Plan
   - Go through each criterion and verify it's met
   - For each criterion, document how it was verified
3. **Scan for common issues**:
   - Unused imports or variables
   - Console.log / print statements left in
   - Hardcoded values that should be configurable
   - Missing error handling
   - TODO comments added during development
4. **Produce Verification Report**

**Verification Report Format**:

```markdown
# Verification Report
Generated: [timestamp]

## Test Results
- Total tests: [N]
- Passed: [N]
- Failed: [N]
- Skipped: [N]
- New tests added: [N]

## Linter/Type Check
- Linter: [pass/fail, N warnings]
- Type check: [pass/fail, N errors]

## Contract Verification
| Task | Assertion | Engineer Proof | Verifier Check | Status |
|------|-----------|---------------|----------------|--------|
| Task 1 | [Assertion] | [Engineer's proof] | [Your independent check] | ✅/❌ |

## Acceptance Criteria
| Criterion | Status | How Verified |
|-----------|--------|-------------|
| [Criterion 1] | ✅ Pass | [How] |
| [Criterion 2] | ❌ Fail | [Why] |

## Issues Found
- [Issue 1]: [Description, severity, location]

## Verdict: [PASS / FAIL — reason]
```

**On failure**: Use the Verification Escalation Ladder.

- **Level 1 (self-correct)**: Return to Phase 2 with a minimal failure packet:
  - exact failed command(s)
  - failing assertions or acceptance criteria
  - raw assertion/error output
  - a likely root cause hypothesis
- **Level 2 (re-work)**: Return to Phase 2 with a deeper failure packet:
  - all Level 1 context
  - why Level 1 likely failed (scope mismatch, wrong assumption, missing requirement, hidden dependency)
  - a recommended approach change
  - Planner may adjust tasks before Work resumes if the failure indicates plan drift
- **Level 3 (re-plan)**: Return to Phase 2 with a re-planning packet:
  - timeline of each failure attempt
  - what changed between attempts
  - exactly what is still blocked
  - at least 2 options for next action (e.g., narrower scope, alternate architecture, user-led resolution)
- **Level 4 (re-discover)**: Pause and gather extra context before the next attempt:
  - run an alternative discovery pass focused on failure area
  - collect new evidence from logs/mocks/environment assumptions
  - propose a revised scope boundary if hidden dependencies are found

Stop automatic looping after Level 4 and request user direction before continuing.

---

## Phase 4: Review

### Agent: security-reviewer

**Role**: Identify security vulnerabilities in the changes.
**Authority Boundary**: review-only; no edits to implementation or tests.
**Escalation Trigger**: if a critical security risk is found, return `CRITICAL_REVIEW_BLOCK` with a minimal fix plan.

**Inputs**: Diff of all code changes

**Checklist**:
- Input validation: Are all user inputs validated and sanitized?
- Authentication: Are auth checks in place for protected resources?
- Authorization: Can users access only what they should?
- Secrets: Are any secrets, tokens, or API keys hardcoded?
- SQL/NoSQL injection: Are queries parameterized?
- XSS: Is output properly escaped in HTML contexts?
- CSRF: Are state-changing operations protected?
- Dependencies: Are new dependencies from trusted sources? Any known CVEs?
- Logging: Is sensitive data excluded from logs?
- Error handling: Do error messages leak internal details?

**Findings Format**:
```markdown
### Security Review Findings

#### 🔴 Critical
- **[Finding]**: [Description, file:line, remediation]

#### 🟡 Warning
- **[Finding]**: [Description, file:line, remediation]

#### 🟢 Suggestion
- **[Finding]**: [Description]

#### ✅ Positive
- [Security practices done well in this change]
```

### Agent: architecture-reviewer

**Role**: Assess architectural quality and consistency.
**Authority Boundary**: review-only; no edits to implementation or tests.
**Escalation Trigger**: if architecture drift blocks progress, return `PLATFORM_ARCHITECTURE_BLOCK` with required redesign.

**Inputs**: Diff of all code changes + Discovery Brief (for convention context)

**Checklist**:
- Pattern consistency: Do new files follow existing patterns?
- Separation of concerns: Is business logic separate from infrastructure?
- Coupling: Are new dependencies between modules justified?
- Cohesion: Does each module/class have a single responsibility?
- API design: Are new APIs consistent with existing ones?
- Breaking changes: Does this break any public contracts?
- Scalability: Will this approach work at 10x current load?
- Naming: Are names consistent with project conventions?
- File organization: Are new files in the right directories?

**Findings Format**: Same as security reviewer (Critical/Warning/Suggestion)

### Agent: code-quality-reviewer

**Role**: Assess code quality and maintainability.
**Authority Boundary**: review-only; no edits to implementation or tests.
**Escalation Trigger**: if a blocker-level quality issue is found, return `CRITICAL_REVIEW_BLOCK`.

**Inputs**: Diff of all code changes

**Checklist**:
- Readability: Can a new developer understand this in one read?
- DRY: Is there duplicated logic that should be extracted?
- Error handling: Are all error paths handled? Are errors informative?
- Performance: Any N+1 queries, unnecessary allocations, blocking calls?
- Comments: Are complex sections commented? Are comments accurate?
- Magic numbers: Are constants named and documented?
- Edge cases: Are boundary conditions handled?
- Logging: Is there appropriate logging for debugging?
- Documentation: Are public APIs documented?

**Findings Format**: Same as security reviewer (Critical/Warning/Suggestion)

### Agent: documentation-specialist

**Role**: Ensure documentation quality and alignment with implemented behavior.
**Authority Boundary**: docs-only updates; no edits to production code or tests.
**Escalation Trigger**: if required documentation artifacts are missing or materially inconsistent, return `USER_ESCALATION` with concrete gaps.

**Inputs**: implementation-plan.md, verification-report.md, review-findings.md, contract-proof.md, project docs (README, SKILL.md, LEARNINGS.md, known-pitfalls.md)

**Checklist**:
- Are public examples and installation instructions still accurate?
- Are docs aligned with changed behavior and acceptance outcomes?
- Are onboarding and quick-start paths still valid?
- Are changelog/release notes consistent with actual artifact changes?
- Are ambiguities or assumptions captured for future cycles?

**Findings Format**: Same as security reviewer (Critical/Warning/Suggestion)

---

## Phase 5: Compound

### Agent: knowledge-compounder

**Role**: Extract learnings and persist them for future cycles.
**Authority Boundary**: write/update only knowledge artifacts and reports.
**Escalation Trigger**: if a process failure should change workflow policy, route through coordinator before editing AGENTS conventions.

**Inputs**:
- All cycle artifacts (discovery brief, plan, verification report, review findings, contract proof,
  cycle report). Contract proof is expected at `{output_dir}/contract-proof.md`. If multi-engineer Work
  ran with partial proofs, include `contract-proof-engineer-*.md` and merge into
  `{output_dir}/contract-proof.md` before compound.
- Current knowledge files (LEARNINGS.md, AGENTS.md, known-pitfalls.md,
  policy-overrides.md if present)

**Process**:

1. **Reflect on the cycle**:
   - What went well? (Plan was accurate, no test failures, clean review)
   - What was harder than expected? (Unexpected dependency, missed edge case)
   - What surprised us? (Codebase behavior, framework quirks)
   - Did any past learnings help? (Validates the compound loop is working)

2. **Categorize learnings**:
   - **Patterns**: New conventions or reusable approaches discovered
   - **Pitfalls**: Bugs, gotchas, or traps to avoid next time
   - **Decisions**: Architectural choices and their rationale
   - **Process**: Improvements to the workflow itself

3. **Update knowledge files**:

   **LEARNINGS.md** — Append new entries:
   ```markdown
   ## [Date] — [Task Title]
   **Category**: [Pattern | Pitfall | Decision | Process]
   **Context**: [One sentence about the task]
   **Learning**: [What we learned]
   **Resolution**: [How it was resolved, if applicable]
   **Tags**: [searchable keywords]
   ```

   **known-pitfalls.md** — Add new pitfalls:
   ```markdown
   ### [Pitfall Name]
   **Area**: [e.g., authentication, database, API]
   **Description**: [What goes wrong]
   **Trigger**: [When/how this happens]
   **Prevention**: [How to avoid it]
   **Discovered**: [Date, task reference]
   ```

   **AGENTS.md / CLAUDE.md** — Update if a new project-level convention was established

4. **Rate the cycle** (for process improvement):
   - Plan quality (1-5): Did the plan accurately predict the work?
   - Execution quality (1-5): How smoothly did Work phase go?
   - Review quality (1-5): Did review catch real issues?
   - Discovery quality (1-5): Did research prevent problems?

5. **Produce Cycle Report**

**Cycle Report Format**:

```markdown
# Cycle Report: [Task Title]
Completed: [timestamp]

## Summary
[2-3 sentences on what was built and shipped]

## Cycle Scores
| Phase | Score | Notes |
|-------|-------|-------|
| Discovery | [1-5] | [Brief note] |
| Plan | [1-5] | [Brief note] |
| Execution | [1-5] | [Brief note] |
| Review | [1-5] | [Brief note] |

## Learnings Captured
- [Learning 1 — written to LEARNINGS.md]
- [Learning 2 — written to known-pitfalls.md]

## Knowledge Files Updated
- [x] LEARNINGS.md — [N] new entries
- [ ] AGENTS.md — no changes needed
- [x] known-pitfalls.md — [N] new pitfalls
- [ ] policy-overrides.md (if present) — [N] new rules, [N] hit_count increments

## Metrics
- Verification attempts (including failures): [N]
- Review findings: [N critical, N warning, N suggestion]
- Tests added: [N]
- Files changed: [N]
```
