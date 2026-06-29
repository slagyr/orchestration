---
name: hail-bean-work
description: Bootstrap and run bean work from a hail delivery when session cwd, skills catalog, or checkout layout are ambiguous. Use for hail-driven bean work in any project, including orchestration and process-test beans, or when list_skills returns empty.
---

# Hail-driven bean work

Use when a hail (or band prompt) assigns bean work and you need a reliable start
path without guessing checkout locations or waiting on `load_skill`.

## Bootstrap checklist

Run in order before claiming or editing anything.

1. **Find the beans repo** — directory with `.beans/`. From session cwd, check relative to your role home or use the path named in the hail (or discover it). If the named path does not exist, ignore the label and use the discovered clone containing `.beans/`.
2. **`git -C <beans-repo>` pull --rebase** — beans and source sync together.
3. **`beans show <id>`** (or `beans list --ready`) — read full body + acceptance.
4. **Find the implementation repo** — bean scope / title names the repo (e.g. the module or project being worked on). Work in the sibling checkout under your role home.
5. **Skills** — try `list_skills` / `load_skill` if available. If empty or missing, read directly:
   - `AGENTS.md` (shared boot if present)
   - `prompts/commands/work.md`
   - this file
6. **Claim** — `beans update <id> --status=in-progress`, commit + push `.beans/` from the isaac-beans.

All `beans` commands and bean markdown commits happen in the **beans repo** root even when implementation edits happen in a module sibling.

## Session cwd vs worktree

| Surface | Typical path | Holds |
|---------|--------------|--------|
| Role home | `~/agents/work-N/` | Session cwd, hail landing |
| Beans + prompts | `~/agents/work-N/<project-root>/` | `.beans/`, `prompts/` |
| Module checkout | sibling | Split-repo source |

Hail init text ("checkout in quarters") describes intent, not a guaranteed path.
Authoritative rule: **the directory that contains `.beans/` is the beans repo (project root for this orchestration).**

## Normal implementation bean

Follow `prompts/commands/work.md`:

- TDD + `bb spec` / `bb features` per bean acceptance
- Hand off: `beans update <id> --tag=unverified` (stay `in-progress`)
- Push beans + code

## Process-test / no-op beans

When the bean body says **process test**, **no-op**, or **orchestration smoke**
(e.g. `example-process-test-bean`):

- **No product code or tests required** unless the bean explicitly asks for them.
- TDD rules are **suspended** for that bean.
- Minimum deliverable:
  1. Claim the bean.
  2. Append observations under `## Process Observations` in the bean body.
  3. Create follow-up beans for gaps found.
  4. `beans update <id> --tag=unverified` + push.

## Hand off to verify

- Worker: `in-progress` + `tag=unverified`, push the beans repo `.beans/` with any notes.
- Use the `hail-send` tool to target the verify band (specified in the incoming hail data).
- Pass at least :bean-id in the params (the project-specific data from this hail can be included as needed).
- Verifier pulls the beans repo root before reviewing.

The bean-specific information (like the id) travels in the hail parameters to the next band. The details of what was done live in the bean body and the prompt context.
