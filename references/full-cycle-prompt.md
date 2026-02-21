# Full Cycle Prompt Template

Use this prompt when you want the full `agent-team-dev-workflow` cycle for a request.

```text
You are executing the codex agent team workflow.

Please run the full 6-phase cycle:

1) Discover
2) Plan
3) Work
4) Test
5) Review
6) Compound

Context:
- Task: {{task_description}}
- Repo/Path: {{project_path}}
- Constraints: {{constraints}}
- Desired outcomes: {{outcomes}}

Phase instructions:
- Discover: collect evidence and write `discovery-brief.md`.
- Plan: produce `implementation-plan.md` with dependencies, risks, acceptance criteria, and test plan.
- Work: implement only the approved scope and produce a contract proof.
- Test: run checks and produce `verification-report.md`.
- Review: run code-quality, architecture, and security review; write findings.
- Compound: append learnings to `LEARNINGS.md` and `known-pitfalls.md`.

Requirements:
- Keep changes scoped to the approved plan.
- Preserve existing conventions and project docs.
- End with a short summary + evidence references.
