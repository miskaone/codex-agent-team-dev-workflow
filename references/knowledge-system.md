# Knowledge System

How learnings are captured, stored, and retrieved across development cycles.

## Table of Contents

1. [Knowledge Files](#knowledge-files)
2. [Write Patterns](#write-patterns)
3. [Read Patterns](#read-patterns)
4. [Knowledge Decay](#knowledge-decay)

---

## Knowledge Files

The system maintains four persistent knowledge files at the project root.
These are intended to be committed to version control so the entire team benefits.

### references/codebase-map.md (New — Replaces Brute-Force Scanning)

**Purpose**: A pre-generated architectural summary of the project that eliminates
the need to grep/scan the codebase on every cycle. The research-scout reads this
FIRST and only touches actual files when the map doesn't have the answer.

**When it's generated**:
- Initially: Run the `/generate-codebase-map` command (or ask Claude to generate it)
- Updated: During the Compound phase, if new modules, patterns, or conventions were established

**Structure**:
```markdown
# Codebase Map
Last updated: [timestamp]

## Architecture Overview
[2-3 sentences describing what this project is and how it's structured]

## Module Index
| Module | Path | Purpose | Key Files |
|--------|------|---------|-----------|
| Auth | src/auth/ | Authentication and authorization | handler.ts, middleware.ts, types.ts |
| API | src/api/ | REST endpoint handlers | routes/*.ts, middleware/*.ts |
| Database | src/db/ | Data access layer | repositories/*.ts, migrations/ |
| Shared | src/shared/ | Cross-cutting utilities | errors.ts, logger.ts, config.ts |

## Key Patterns
- **Data access**: Repository pattern — all queries go through src/db/repositories/
- **Input validation**: Zod schemas at API boundaries (src/api/schemas/)
- **Error handling**: Custom ApiError class from src/shared/errors.ts
- **Authentication**: JWT middleware applied at router level, not per-route
- **Testing**: Vitest, co-located test files (foo.ts → foo.test.ts), MSW for HTTP mocks

## Dependency Map
- Auth depends on: Database, Shared
- API depends on: Auth, Database, Shared
- Database depends on: Shared
- No circular dependencies (enforced by eslint-plugin-import)

## External Integrations
| Service | Purpose | Config Location | Test Strategy |
|---------|---------|-----------------|---------------|
| PostgreSQL | Primary database | src/db/config.ts | Docker test container |
| Redis | Rate limiting, sessions | src/cache/redis.ts | Mock in tests |
| Stripe | Payments | src/billing/stripe.ts | Stripe test mode |

## CI/CD
- Test: `npm test`
- Lint: `npm run lint`
- Type check: `npm run typecheck`
- Build: `npm run build`
- Deploy: GitHub Actions → AWS ECS

## Recent Significant Changes
- [2026-02-08] Added rate limiting module (src/api/middleware/rate-limit.ts)
- [2026-02-05] Migrated from Jest to Vitest
- [2026-02-01] Added Stripe billing integration
```

**Why this matters**: Without the codebase-map, the research-scout spends 30-60 seconds
grepping and reading files to understand project structure. With it, the scout gets the
same information instantly from a single file read. The map pays for itself after 2-3 cycles.

**Generation script**: See `scripts/generate-codebase-map.sh` for automated generation.

### LEARNINGS.md

**Purpose**: Chronological record of everything learned during development cycles.

**Structure**:
```markdown
# Project Learnings

## 2026-02-09 — Add OAuth2 Authentication
**Category**: Pitfall
**Context**: Implementing OAuth2 flow with the existing session middleware
**Learning**: The session middleware strips custom headers before they reach the
OAuth callback handler. Must register the OAuth route before session middleware.
**Resolution**: Moved OAuth routes above session middleware in app.ts
**Tags**: oauth, session, middleware, routing

## 2026-02-08 — Fix API Rate Limiting
**Category**: Pattern
**Context**: Implementing sliding window rate limiter
**Learning**: Redis MULTI/EXEC is significantly faster than individual commands
for the check-and-increment pattern. Reduces rate limit check from ~5ms to ~1ms.
**Resolution**: Refactored to use Redis pipeline
**Tags**: redis, rate-limiting, performance
```

**Search strategy**: The research-scout searches LEARNINGS.md by scanning
tags and context lines for keywords related to the current task.

### known-pitfalls.md

**Purpose**: Structured database of traps, gotchas, and "things that bite you."
Organized by area for quick lookup.

**Structure**:
```markdown
# Known Pitfalls

## Authentication

### OAuth Callback Header Stripping
**Description**: Session middleware strips custom headers before OAuth callbacks
**Trigger**: Registering OAuth routes after session middleware
**Prevention**: Always register OAuth routes before session middleware in app.ts
**Discovered**: 2026-02-09, "Add OAuth2 Authentication" cycle

## Database

### PostgreSQL Connection Pool Exhaustion
**Description**: Unhandled promise rejections leak database connections
**Trigger**: Async error in transaction without proper cleanup
**Prevention**: Always use try/finally with client.release() in transactions
**Discovered**: 2026-01-15, "Add Batch Processing" cycle
```

**Search strategy**: The research-scout looks up the relevant area heading
(e.g., "Authentication", "Database") and reads all pitfalls in that section.

### policy-overrides.md (New — Active Policy Injection)

**Purpose**: Agent-specific rules generated by the Compound phase that inject directly
into each agent's prompt at spawn time. Unlike LEARNINGS.md (which is passively read by
the scout), policy overrides are *actively* included in the target agent's context.

The file is optional at repository start; create it when the first workflow-level policy
rule is identified (use `references/policy-overrides-template.md`).

**Structure**:
```markdown
# Policy Overrides
Last updated: [timestamp]

## Engineer
| # | Rule Type | Rule | Evidence | Hit Count | Expiry |
|---|-----------|------|----------|-----------|--------|
| 1 | MUST | Check for null returns from DB queries before accessing properties | 2026-02-14 "Add user profile" — null pointer in production | 2 | permanent |
| 2 | AVOID | Using string concatenation for SQL queries | 2026-02-10 "Fix search" — SQL injection found in review | 1 | permanent |

## Test Writer
| # | Rule Type | Rule | Evidence | Hit Count | Expiry |
|---|-----------|------|----------|-----------|--------|
| 1 | MUST | Include at least one test for each Success Assertion in the delegation contract | 2026-02-14 "Add user profile" — untested assertion slipped through | 0 | permanent |

## Verifier
[Same format...]
```

**Lifecycle**:
- Created/updated during the Compound phase (Step 3c in knowledge-compounder.md)
- Read by the coordinator when spawning each agent — include that agent's section in the spawn prompt
- Maximum 15 rules per agent to prevent prompt bloat
- Rules with `hit_count=0` and `expiry=review-after-N-cycles` are candidates for retirement
- The coordinator increments `hit_count` when a rule demonstrably prevents a repeat issue

**Why this matters**: LEARNINGS.md captures knowledge passively — the scout reads it during
research. Policy overrides close the loop tighter by injecting rules directly into the agent
that needs them, ensuring the same mistake doesn't repeat even if the scout misses the learning.

### AGENTS.md (or CLAUDE.md additions)

**Purpose**: Project-level conventions and rules that apply to every cycle.
These are the "constitution" for how agents should behave in this specific project.

**Structure**:
```markdown
# Project Agent Instructions

## Code Style
- Use functional components with hooks (no class components)
- Error responses always use the ApiError class from src/errors/
- Database queries go in repository files, never in route handlers
- Use zod for all input validation at API boundaries

## Testing Conventions
- Test files live next to source files: foo.ts → foo.test.ts
- Use vitest, not jest
- Mock external services at the HTTP level (msw), not at the module level
- Every API endpoint needs at least one success and one error test

## Architecture Rules
- New features get their own module directory under src/modules/
- Shared types go in src/types/, module-specific types stay in the module
- No circular dependencies between modules (enforced by eslint rule)

## Deployment
- All environment variables must be documented in .env.example
- Database migrations must be backwards-compatible (no column drops)
```

---

## Write Patterns

### When to Write (Phase 5: Compound)

The knowledge-compounder writes to knowledge files at the end of every cycle.
Here are the rules for what gets written where:

| What happened | Write to | Example |
|---------------|----------|---------|
| Found a gotcha that wasted time | known-pitfalls.md | "Don't use X with Y" |
| Discovered a useful pattern | LEARNINGS.md (category: Pattern) | "Use Redis pipelines for..." |
| Made an architectural decision | LEARNINGS.md (category: Decision) | "Chose approach A because..." |
| Established a new convention | AGENTS.md | "Always validate with zod" |
| Workflow improvement idea | LEARNINGS.md (category: Process) | "Run linter before tests" |
| Review caught a recurring issue | known-pitfalls.md | "Always check for X in Y" |
| Failure traceable to a specific agent | policy-overrides.md | "Engineer MUST check for null" |
| Added a new module or service | **codebase-map.md** | Add to Module Index |
| Changed dependency relationships | **codebase-map.md** | Update Dependency Map |
| Added external integration | **codebase-map.md** | Add to External Integrations |
| Established new key pattern | **codebase-map.md** | Add to Key Patterns |
| Nothing notable happened | LEARNINGS.md with minimal entry | "Clean cycle, no issues" |

### Writing Rules

1. **Be specific**: "The session middleware strips headers" not "Be careful with middleware"
2. **Include resolution**: Don't just document the problem — document the fix
3. **Tag for searchability**: Add 3-5 keyword tags so future research-scouts find it
4. **Don't duplicate**: Check if a similar learning already exists before adding
5. **Date everything**: Learnings without dates lose context quickly
6. **Reference the task**: Link back to which cycle produced this learning

### Append, Don't Replace

Knowledge files are append-only during the Compound phase. Never delete or modify
existing entries. If a learning becomes outdated, add a new entry that supersedes it:

```markdown
## 2026-03-01 — Update: OAuth Middleware Order
**Category**: Pattern (supersedes 2026-02-09 learning)
**Context**: Upgraded to Express 5 which handles middleware ordering differently
**Learning**: Express 5's new router handles OAuth routes correctly regardless
of registration order. The previous workaround is no longer needed.
**Tags**: oauth, express5, middleware
```

---

## Read Patterns

### Three-Tier Context Strategy (Phase 0: Discover)

The research-scout follows a tiered approach to minimize scanning time and token usage.
Stop as soon as you have enough context.

#### Tier 1: Pre-Built Context (read knowledge files)

Always start here. These reads are instant and cost almost nothing:

1. **references/codebase-map.md** — Read the full map. This tells you:
   - Which modules exist and what they do
   - Where the affected files are
   - What patterns the codebase uses
   - What dependencies exist between modules
   - What CI commands to run

2. **LEARNINGS.md** — Search for relevant past learnings:
   ```bash
   # Search by keywords extracted from the task
   grep -i -n "keyword1\|keyword2\|keyword3" LEARNINGS.md
   ```
   
3. **known-pitfalls.md** — Check relevant area headings:
   ```bash
   # Find the right section, then read it
   grep -n "^## " known-pitfalls.md  # List all area headings
   # Then read the relevant section
   ```

4. **AGENTS.md** — Always read in full (it's the project constitution)

**Decision point**: If the codebase-map tells you which files are affected, what patterns
to follow, and LEARNINGS.md has no relevant warnings → produce the Discovery Brief NOW.
Skip Tier 2 and 3.

#### Tier 2: Semantic Code Search (MCP-powered)

If Tier 1 doesn't give enough detail — for example, you need to see the actual
implementation of a pattern, or the codebase-map is outdated — and
`mcp_search_available=true`, use the `claude-context` MCP server:

```
mcp__claude-context__search_code({
  path: "/path/to/project",
  query: "how does the auth middleware validate JWT tokens",
  limit: 5
})

mcp__claude-context__search_code({
  path: "/path/to/project",
  query: "rate limiting implementation pattern",
  limit: 5,
  extensionFilter: ".ts"
})
```

**Parameters**:
- `path` (required): Absolute path to the project root
- `query` (required): Natural language description — NOT grep/regex patterns
- `limit` (optional): Max code chunks to return (default 10, keep at 3-5 for focused results)
- `extensionFilter` (optional): File extension filter (e.g. `".ts"`, `".py"`)

**Why this is better than grep**:
- Returns semantically relevant code chunks, not just string matches
- ~40% fewer tokens than loading entire files
- Finds related code even when variable names don't match your search terms
- Results are ranked by relevance, not file order

**If `mcp_search_available=false`**: Skip to Tier 3. The coordinator has already
determined that the MCP server is not available or not indexed. Consider suggesting
the user install the `claude-context` MCP (see `references/mcp-setup.md`).

#### Tier 3: Targeted File Access (direct reads)

Only use this when Tier 1 and 2 can't answer a specific question:

- Read a specific file identified by the codebase-map or MCP results
- Check a specific test file to understand test patterns
- Read a specific config file for environment/deployment details
- `git log --oneline -10 -- <specific-path>` for recent changes to a file

**Rules for Tier 3**:
- Never grep recursively across the entire project
- Always narrow to a specific directory first (using codebase-map)
- Read at most 5-7 files — if you need more, your codebase-map needs updating
- If you're spending more than 30 seconds in Tier 3, stop and produce the brief
  with what you have, noting gaps

### Relevance Scoring

Not all past learnings are relevant. The research-scout should prioritize:

- **High relevance**: Learning is about the same files, same module, or same technology
- **Medium relevance**: Learning is about a similar pattern or related area
- **Low relevance**: Learning is tangentially related (same category but different area)

Include High and Medium relevance learnings in the Discovery Brief.
Mention Low relevance learnings only if nothing else is relevant.

### Context Window Management

Knowledge files grow over time. To prevent context window bloat:

- Read the full file but include only relevant excerpts in the Discovery Brief
- If LEARNINGS.md exceeds 500 lines, use grep/search to find relevant sections
  rather than reading the entire file
- For known-pitfalls.md, read only the section headings first, then drill into
  relevant sections

---

## Knowledge Decay

Over time, some learnings become less relevant. The system handles this through:

### Supersession

New learnings can explicitly supersede old ones (see "Append, Don't Replace" above).
When the research-scout finds a superseded learning, it uses the newer one.

### Periodic Review (Optional)

If the user requests it, the knowledge-compounder can do a "knowledge audit":

1. Read all entries in LEARNINGS.md
2. Flag entries older than 6 months that reference deprecated technologies
3. Flag entries that conflict with each other
4. Suggest consolidation or archival
5. Present findings to the user for decision

This is NOT automatic — the user must request it. Knowledge should never be
deleted without user approval.

### Archive Pattern

For very old learnings, move to an archive file:

```
LEARNINGS.md           → Active learnings (recent 6 months)
LEARNINGS-archive.md   → Archived learnings (older than 6 months)
```

The research-scout checks the archive only if the active file has no relevant results.
