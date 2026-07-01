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

## Notifications

At key milestones, send a concise progress update using `comm_send`:

- comm: the :id from notification-comm (e.g. "discord")
- content: progress text with bean id
- discord.target: the :channel from notification-comm (e.g. "pub" -- it supports name or snowflake ID)

- After claiming the bean.
- After appending observations (include summary).
- Before/when handing off (include what was done).

Example: comm_send with comm="discord" content="Claimed bean {{bean-id}} for work (no-op process test)." "discord.target"="pub"

## Hand off to verify

- Worker: `in-progress` + `tag=unverified`, push the beans repo `.beans/` with any notes.
- Use the `hail-send` tool with flat snake_case top-level keys (no "frequencies" wrapper).
- For normal band handoff:
  - band: the verify band name from the incoming data (e.g. value of verify-hail)
  - params: include at minimum :bean-id, and to support exact returns later also include submitter-crew, submitter-session (this current session's id/name), thread_id, notification-comm, plan-hail, verify-hail, etc.
  Example:
    {"band": "orchistration-verify", "params": {"bean-id": "{{bean-id}}", "bean-repo": "...", "notification-comm": {...}, "submitter-session": "<your-current-session>", "submitter-crew": "scrapper", "thread_id": "<correlation>"}}
- Verifier pulls the beans repo root before reviewing.

## Hand off to planner (e.g. on requirements conflict)

- When the bean cannot satisfy verifier standards (per failure note or your judgement), or per explicit bean instructions:
  - Keep status in-progress (or as appropriate), append observations about the conflict.
  - Use hail-send (flat snake_case) to the plan-hail value from incoming data.
  - Include submitter info so planner (or subsequent steps) can return precisely to *this exact session*.
  - Provide "prompt" with full explanation if needed.
  Example:
    {"band": "orchistration-plan", "params": {"bean-id": "{{bean-id}}", ..., "submitter-session": "<this-session-id>", "thread_id": "..."}, "prompt": "Conflict detected on bean {{bean-id}}: [summary from verifier note and requirements]. Returning for planner adjustment. Previous context on this exact worker session."}
- The planner will adjust (e.g. add unblock note) and hand back to this exact session.

## Handoffs to exact sessions (returns / loops, preserving context)

To return a bean to the *same prior worker or verifier session* that has context:
- Prefer direct session targeting over band+tags: use top-level "session": "<exact-target-session-id>" (the id comes from "submitter-session" in the *incoming* hail data for that leg, or your current session context).
- Since no band template is used, you **must** supply a "prompt" field with a complete explanation: situation, bean-id, summary of prior work/notes/failure, what the recipient should do next, and any unblock notes.
- Always also pass key data in "params" (bean-id etc.) and thread_id for correlation.
- Example direct-to-session return:
  {"session": "<exact-orchistration-work-session-id-from-submitter>", "params": {"bean-id": "{{bean-id}}", "notification-comm": {...}}, "prompt": "Returning bean {{bean-id}} to you (exact same session) because [reason, e.g. planner unblocked it]. [Prior notes summary]. Please continue: [next step from instructions].", "thread_id": "<the-id>"}
- Use comm_send before/after.

The hail system provides incoming context (including submitter info when passed by previous step). For best results, the delivery should also inject your current session id directly into the prompt you receive.

The bean-specific information travels in params or the explicit prompt you supply. The details of what was done live in the bean body.
