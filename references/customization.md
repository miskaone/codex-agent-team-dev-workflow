---
title: Customization
description: Reference content for customization.
schema: skill-v1
related:
  - "[[agent-team-dev-workflow]]"
  - "[[_MOCs/dev-workflow]]"
last_updated: 2026-02-21
---
# Customization

How to adapt the workflow for different projects, teams, and task types.

---

## Phase Skipping

Users can abbreviate the workflow for simpler tasks:

| Task Type | Recommended Phases | Rationale |
|-----------|-------------------|-----------|
| New feature | All 6 phases | Full cycle for unknown territory |
| Bug fix (known cause) | Plan → Work → Test → Compound | Discovery already done by user |
| Refactor | Discover → Plan → Work → Test → Review → Compound | Full cycle, architecture review critical |
| One-line fix | Work → Test → Compound | Minimal ceremony, still capture learning |
| Documentation only | Work → Compound | No testing needed, still capture |
| Config change | Plan → Work → Test → Compound | Verify config doesn't break things |

**User opt-out**: The user must explicitly say "skip discovery" or "quick fix mode."
Never skip phases silently.

---

## Custom Reviewers

Add domain-specific reviewers for specialized projects:

### Accessibility Reviewer
```markdown
**Checklist**:
- ARIA labels on interactive elements
- Keyboard navigation support
- Color contrast ratios (WCAG 2.1 AA)
- Screen reader compatibility
- Focus management for dynamic content
- Alt text for images
```

### Compliance Reviewer (for regulated industries)
```markdown
**Checklist**:
- Data handling meets GDPR/HIPAA/SOC2 requirements
- Audit logging for sensitive operations
- Data retention policies implemented
- User consent flows present
- PII handling follows data classification rules
```

### Performance Reviewer
```markdown
**Checklist**:
- No N+1 query patterns
- Proper indexing for new queries
- Caching strategy for expensive operations
- Bundle size impact (for frontend changes)
- Memory leak potential
- Connection pool sizing
```

### AI/Agent Security Reviewer (FlowEvolve specific)
```markdown
**Checklist**:
- Prompt injection prevention
- Tool use authorization boundaries
- Output sanitization before rendering
- Rate limiting on agent endpoints
- Credential scope verification
- Oversharing via aggregation risks
- MCP server input validation
```

To add a custom reviewer:
1. Create `references/[name]-reviewer.md` following the reviewer template in phase-details.md
2. Add the reviewer to the Review phase parallelism map
3. Update the coordinator's spawn logic to include the new reviewer

## Work Parallelism

You can enable multi-engineer work in Agent Team Mode for larger tasks.

```markdown
# In AGENTS.md or a .workflow/config.md file:

## Workflow Configuration
- Enable multi-engineer Builder: true
- Max parallel engineers: 3
- Engineer shard strategy: task-boundary
```

Guidance:

- `Max parallel engineers` is the hard cap on concurrent engineer agents in Work.
- If the value is missing, the default is `1` (single engineer).
- Keep shard boundaries explicit in `{project-root}/.workflow/current/engineer_task_assignments.md`.
- Use `task-boundary` when tasks can be split by responsibility; use `file-boundary` only
  for large UI/codegen-heavy surfaces.

---

## Review Severity Configuration

Projects can adjust what constitutes Critical vs Warning vs Suggestion:

```markdown
# In AGENTS.md or a .workflow/config.md file:

## Review Severity Overrides
- Security findings about auth: always Critical (never downgrade)
- Performance: Warning unless latency > 2x (then Critical)
- Code style: always Suggestion (never block on style)
- Accessibility: Warning for A level, Critical for AA level
```

---

## Retry Limits

Default verification ladder depth: 4 levels (Level 1 → Level 2 → Level 3 → Level 4, then user escalation).

To change:
```markdown
# In AGENTS.md:
## Workflow Configuration
- Test retry limit: 5  (more patient for complex test suites)
- Review retry limit: 2 (critical fixes should be straightforward)
```

---

## Knowledge File Locations

By default, knowledge files live at the project root. To customize:

```markdown
# In AGENTS.md:
## Knowledge File Locations
- LEARNINGS.md: docs/engineering/learnings.md
- known-pitfalls.md: docs/engineering/pitfalls.md
- Cycle artifacts: .workflow/  (already the default)
```

---

## Integration with Existing Tools

### CI/CD Integration
If the project has CI scripts, the verifier should use them:
```markdown
# In AGENTS.md:
## CI Commands
- Test: `npm test`
- Lint: `npm run lint`
- Type check: `npm run typecheck`
- Build: `npm run build`
```

### Git Workflow Integration
Configure how the workflow interacts with git:
```markdown
# In AGENTS.md:
## Git Workflow
- Branch naming: feature/[task-slug]
- Use git worktrees: true (isolates work from main branch)
- Auto-commit after each task: false (let user decide)
- Commit message format: conventional commits
```

### PR Integration
If the project uses GitHub/GitLab:
```markdown
# In AGENTS.md:
## PR Configuration
- Auto-create PR after Work phase: true
- Include review findings in PR description: true
- Include cycle report in PR description: false
- Label PRs with review severity: true
```
