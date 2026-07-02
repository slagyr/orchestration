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

At key milestones (claim, observations, handoff), send a concise progress
update using `comm_send`. Coordinates come from the delivery's data block:
comm = notification-comm's :id, target = its :channel (name or snowflake).

Fill `<crew>` with **your own crew name** (it's in your system prompt's
session identity block); `<short-slug>` comes from the bean title. Use exactly these
formats for content:

- After claim: `<bean-id> 🟢 **<crew>** claimed (<short-slug>)`
- After observations: `<bean-id> 📝 **<crew>** appended observations (<short-slug>)`
- Before handoff to verify: `<bean-id> ➡️ **<crew>** handed off to verify`
- Before handoff to planner: `<bean-id> ➡️ **<crew>** handed off to planner (plan-review-loop)`

ID first for recognition; emoji for quick status scanning (🟢 claim/positive,
📝 observations, ➡️ handoff).

Example: comm_send with comm="discord" content="orchestration-nj8a 🟢 **scrapper** claimed (no-op-process-test-run-...)" "discord.target"="pub"

## Band data, prompts, and threading

- **All handoffs go through the bands.** Band deliveries always carry the band's
  `data:` (bean-repo, notification-comm, sibling band names) in the delivery's
  data block — even when the sender overrides the prompt. Never stuff
  coordinates into prompts or params.
- **:bean-id is the only required param.**
- **Override the prompt when explanation is needed** — a "prompt" field replaces
  the band's default instructions but the data still arrives.
- **Thread with reply_to.** Set "reply_to" to the incoming hail's id on every
  responding hail; the thread id is inherited automatically. Prior hails in the
  thread (including their prompts and data) are fetchable with `hail_get`.

## Hand off to verify

- Worker: `in-progress` + `tag=unverified`, push the beans repo `.beans/` with any notes.
- Use the `hail-send` tool with flat snake_case top-level keys (no "frequencies" wrapper).
- Hail the **verify-band** (name from the incoming data block):
    {"band": "<verify-band value>", "params": {"bean-id": "{{bean-id}}"}, "reply_to": "<incoming hail id>"}
- Verifier pulls the beans repo root before reviewing.

## Hand off to planner (e.g. on requirements conflict)

- When the bean cannot satisfy verifier standards (per failure note or your judgement), or per explicit bean instructions:
  - Keep status in-progress (or as appropriate), append observations about the conflict.
  - Send comm_send with content exactly: "orchestration-xxx ➡️ **scrapper** handed off to planner (plan-review-loop)"
  - Hail the **plan-band** with a prompt override explaining the conflict:
    {"band": "<plan-band value>", "params": {"bean-id": "{{bean-id}}"}, "reply_to": "<incoming hail id>", "prompt": "Conflict detected on bean {{bean-id}}: [summary from verifier note and requirements]. Returning for planner adjustment."}
- The planner will adjust (e.g. add unblock note) and hand back via the work-band.

The bean id travels in params; explanations travel in the prompt override; the
details of what was done live in the bean body; earlier context lives in the
thread (`hail_get`).
