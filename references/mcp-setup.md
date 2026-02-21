---
title: Mcp Setup
description: MCP search setup and compatibility notes.
schema: skill-v1
related:
  - "[[agent-team-dev-workflow]]"
  - "[[_MOCs/dev-workflow]]"
last_updated: 2026-02-21
---
# Code Search MCP Setup

Optional but recommended: adding a semantic code search MCP server dramatically
speeds up the Discover phase and reduces token usage by ~40%.

## Quick Comparison

| Option | Embedding | Storage | API Cost | Best For |
|--------|-----------|---------|----------|----------|
| Ollama + LanceDB (local) | Ollama (local) | LanceDB (local) | Free | Solo devs, privacy-first |
| OpenAI + LanceDB | OpenAI API | LanceDB (local) | Small (embedding calls) | Better retrieval quality |
| No MCP (codebase-map only) | — | — | Free | Minimal setup, smaller projects |

## Option 1: Ollama + LanceDB (Recommended — Fully Local)

Uses Ollama for local embeddings and LanceDB for vector storage. Your code never
leaves your machine.

**Prerequisites**: [Ollama](https://ollama.com) must be installed and running.

```bash
# Install the MCP server
claude mcp add claude-context \
  -- npx @dannyboy2042/claude-context-mcp@latest

# Pull an embedding model (one-time)
ollama pull nomic-embed-text
```

**Pros**: Zero cost, fully private, incremental indexing
**Cons**: Requires Ollama running, initial model download (~270MB)

## Option 2: OpenAI + LanceDB

Same MCP server, but uses OpenAI for embeddings instead of Ollama.

```bash
claude mcp add claude-context \
  -e OPENAI_API_KEY=your-key \
  -- npx @dannyboy2042/claude-context-mcp@latest
```

**Pros**: Better embedding quality, no local model required
**Cons**: Requires OpenAI API key (small cost), code chunks sent to OpenAI

## Option 3: No MCP (Codebase Map Only)

If you don't want to set up an MCP server, the codebase-map alone handles 80% of
the discovery speed problem. The research-scout will fall back to targeted file reads
for the remaining 20%.

```bash
# Generate the initial codebase map
./scripts/generate-codebase-map.sh . references/codebase-map.md

# Ask Claude to fill in the [TODO] sections
# The Compound phase keeps it updated from there
```

---

## Tool Reference

The `claude-context` MCP server exposes four tools. All other skill files reference
these exact names.

| Tool | Purpose | Key Parameters |
|------|---------|----------------|
| `mcp__claude-context__index_codebase(path)` | Index a directory for semantic search | `path` (project root) |
| `mcp__claude-context__search_code(path, query, limit?, extensionFilter?)` | Semantic code search | `path`, `query` (natural language), `limit` (default 10), `extensionFilter` (e.g. `".ts"`) |
| `mcp__claude-context__get_indexing_status(path)` | Check if a directory is indexed | `path` |
| `mcp__claude-context__clear_index(path)` | Remove an existing index | `path` |

### Parameter Details

- **path**: Absolute path to the project root (e.g. `/Users/you/dev/my-project`)
- **query**: Natural language description of what you're looking for — NOT grep patterns.
  Good: `"how JWT tokens are validated in auth middleware"`
  Bad: `"JWT.*validate.*middleware"`
- **limit**: Max number of code chunks to return (default 10, keep low for focused results)
- **extensionFilter**: File extension filter (e.g. `".ts"`, `".py"`). Use when you know the file type.

---

## How the Research-Scout Uses MCP Search

When MCP search is available, the research-scout replaces grep with semantic queries:

**Without MCP** (slow):
```bash
grep -r "authentication" src/ --include="*.ts" -l
# Returns 47 files. Scout reads 10+ to find the right pattern.
# Token cost: ~15,000 tokens for file reads
```

**With MCP** (fast):
```
mcp__claude-context__search_code({
  path: "/Users/you/dev/project",
  query: "JWT token validation middleware",
  limit: 5
})
# Returns 3-5 ranked code chunks with exact context needed.
# Token cost: ~2,000 tokens
```

---

## Indexing Lifecycle

### First Run (No Index Exists)

The coordinator checks indexing status before spawning the research-scout:

```
mcp__claude-context__get_indexing_status({ path: "/path/to/project" })
```

If not indexed, the coordinator triggers indexing:

```
mcp__claude-context__index_codebase({ path: "/path/to/project" })
```

Indexing takes ~30-90 seconds depending on project size. The coordinator informs
the user and waits for completion before proceeding.

### Subsequent Runs

If already indexed, search is available immediately. The index persists across
Claude Code sessions — no need to re-index unless the codebase structure changes
significantly.

### Re-Indexing (Stale Index)

The knowledge-compounder flags when re-indexing is needed (e.g., new modules added,
major restructuring). Re-indexing happens at the start of the next cycle — the
coordinator calls `index_codebase` again, which refreshes the existing index.

To fully reset and rebuild:
```
mcp__claude-context__clear_index({ path: "/path/to/project" })
mcp__claude-context__index_codebase({ path: "/path/to/project" })
```

---

## Graceful Degradation

| Scenario | Behavior |
|----------|----------|
| No MCP configured | Tool call fails → `mcp_search_available=false` → scout skips Tier 2 |
| Ollama not running | Indexing/search fails → same as above |
| First run (not indexed) | Coordinator indexes (~60s), informs user, then proceeds |
| Index stale | Compound flags it → next cycle re-indexes |
| Search returns empty | Scout falls to Tier 3 → notes in brief for Compound |
