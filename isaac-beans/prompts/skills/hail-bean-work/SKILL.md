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
   **If the bean is not found:** the dispatch may have raced the push — wait
   briefly, `git pull --rebase`, retry once. Still missing → do NOT hand off
   to the planner and do NOT pick another bean: reply on the incoming hail
   thread (reply_to) explaining, send a `<bean-id> ⚠️ **<crew>**@<session> bean not
   found — no action taken` notification, and stop.
4. **Find the implementation repo** — bean scope / title names the repo (e.g. the module or project being worked on). Work in the sibling checkout under your role home.
5. **Skills** — try `list_skills` / `load_skill` if available. If empty or missing, read directly:
   - `AGENTS.md` (shared boot if present)
   - `prompts/commands/work.md`
   - this file
6. **Claim** — `beans update <id> --status=in-progress`, commit + push `.beans/` from the isaac-beans.

All `beans` commands and bean markdown commits happen in the **beans repo** root even when implementation edits happen in a module sibling.

## Commit trailers

Every commit made from an Isaac orchestration session should carry provenance
trailers so CI-failure hails can route back to the right context:

```text
Isaac-Session: <session-id>
Isaac-Bean: <bean-id>
```

- **Isaac-Session** — always, on every orchestration commit (bean repo and
  implementation repo). CI failure hails use this to deliver directly to the
  session that pushed the break.
- **Isaac-Bean** — on implementation commits while bean work is in flight.
  CI failure hails pass this as `bean_id` so the crew correlates repair with the
  active bean instead of starting independent work.

Recommended form:

```sh
git commit \
  --trailer "Isaac-Session: <session-id>" \
  --trailer "Isaac-Bean: <bean-id>"
```

The session id comes from your session identity block; the bean id from the
bean you are implementing.

## Session cwd vs worktree

| Surface | Typical path | Holds |
|---------|--------------|--------|
| Role home | `~/agents/work-N/` | Session cwd, hail landing |
| Beans + prompts | `~/agents/work-N/<project-root>/` | `.beans/`, `prompts/` |
| Module checkout | sibling | Split-repo source |

Hail init text ("checkout in quarters") describes intent, not a guaranteed path.
Authoritative rule: **the directory that contains `.beans/` is the beans repo (project root for this orchestration).**

### Workspace protocol (shared checkouts are load-bearing)

Sibling checkouts are shared infrastructure: other sessions' suite runs
resolve `../<module>` deps against them.

- Work **in the sibling checkout** on a `bean/<bean-id>` branch. If you need
  isolation, `git worktree add ../<module>-<bean-id> -b bean/<bean-id>` from
  the sibling — never a fresh full clone.
- **NEVER rename, move, symlink, or replace a sibling checkout.** Pointing
  the shared dep path at your bean tree corrupts every other session's suite
  runs and outlives your turn. If cross-repo suites must see your branch,
  that is what CI's pinned-sibling runs are for — hand off and let verify/CI
  do it.
- **Commit on green, always.** After every green test run (`bb spec`, `bb features`,
  a focused scenario), commit to your `bean/<bean-id>` branch and push it —
  not only at handoff. The branch is what makes early commits safe: nothing
  reaches main until verify lands it. A turn can end at the cycle limit at any
  moment (isaac-ntt6); uncommitted work in a checkout is work that may be lost
  or overwritten. Never commit implementation work on `main` of a sibling checkout.
- On completion (or when abandoning), remove your worktree
  (`git worktree remove`) and leave the sibling checkout on main, clean.

## Normal implementation bean

Follow `prompts/commands/work.md`:

- TDD + `bb spec` / `bb features` per bean acceptance
- Before handoff, rebase your `bean/<id>` branch onto current `origin/main` so verify's landing merge is a fast-forward (verify FAILS a conflicting branch back to you).
- Hand off: `beans update <id> --tag=unverified` (stay `in-progress`)
- Push beans + code; the handoff note on the bean states the branch and its base:
  `branch: bean/<id> @ <sha> (base origin/main@<sha>)`. Verify lands it on main — you do not merge or pin.

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

**Notifications report completed actions, never intentions.** Send the hail
first, the ➡️ line after it succeeds — a feed line must never claim a handoff
that has not been persisted.

At key milestones (claim, observations, handoff), send a concise progress
update using `comm__send`. Coordinates come from the delivery's data block:
comm = notification-comm's :id, target = its :channel (name or snowflake).

Fill `<crew>` and `<session>` from **your own identity** (both are in your
system prompt's session identity block); `<short-slug>` comes from the bean title. Use exactly these
formats for content:

- After claim: `<bean-id> 🟢 **<crew>**@<session> claimed (<short-slug>)`
- On receiving a verify-fail or planner return: `<bean-id> 🔁 **<crew>**@<session> resumed (<short-slug>)`
- On receiving a CI-failure hail (band `<project>-ci-failure`): `<bean-id> 🔴 **<crew>**@<session> CI red on <branch> (<failing job>)` — this is NOT a resume; never send the 🔁 line for it
- After the CI repair is pushed: `<bean-id> 🩹 **<crew>**@<session> CI repair pushed (<short-sha>)`
- After observations: `<bean-id> 📝 **<crew>**@<session> appended observations (<short-slug>)`
- After the verify handoff hail is SENT: `<bean-id> ➡️ **<crew>**@<session> handed off to verify`
- After the planner handoff hail is SENT: `<bean-id> ➡️ **<crew>**@<session> handed off to planner (plan-review-loop)`

ID first for recognition; emoji for quick status scanning (🟢 claim/positive,
📝 observations, ➡️ handoff, 🔴 CI red, 🩹 CI repair).

Example: comm__send with comm="discord" content="orchestration-nj8a 🟢 **scrapper** claimed (no-op-process-test-run-...)" "discord.target"="pub"

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
  thread (including their prompts and data) are fetchable with `hail__get`.

## Never end a turn in limbo

Every work turn must end in exactly one of these states: bean **completed**
(unverified handoff hail sent), **conflict hail sent** (plan-band), or
**HOLD + human escalate** if you cannot finish. Anything else strands the
bean silently — claimed, no pending hail, nobody coming back.

**Do not hail yourself to continue.** No session-direct continuation hails,
no "continuation N of 5", no sending the next hail EARLY. Stay in this
turn; the cycle budget comes from config, not from this skill. A final message like
"ask me to continue" is a dead end on an unattended turn.

If you still cannot finish (loop cap, blocked, lost), send the 🆘 human-help
escalation (notification-comm + human-help-comm from the data block) and HOLD.
Do **not** re-hail.

**Escalation is terminal — HOLD the bean, do not re-queue.** Once the 🆘 comms
are sent, the turn is over: do **not** hand off, do **not** re-hail. You just
asked a human to look at this bean; re-queuing is the churn escalation exists
to end. Mark it held so it is visibly waiting (not silently stranded) — append
a held note to the bean body and commit/push it (with the `Isaac-Session`
trailer):

```
## Held (awaiting human, <date>)

Escalated to human by **<crew>**@<session>. Blocking: <one-line synopsis>.
Resumes only on explicit human action (re-hail the work/plan band, or
re-promote). No crew re-picks this until then.
```

Nothing auto-resumes; a human resumes explicitly. Held + `in-progress` with the
note is the correct, quiet end state.

## Hand off to verify

- Worker: `in-progress` + `tag=unverified`, push the beans repo `.beans/` with any notes.
- Use the `hail__send` tool with flat snake_case top-level keys (no "frequencies" wrapper).
- **Copy the band value EXACTLY from your delivery's data block — never type it
  from memory.** A typo'd band name routes nowhere and dead-letters silently.
- **Band handoffs carry the `band` key and `params` ONLY** — never add
  `session-tags`, `crew`, or other frequency filters: extra filters can select
  ZERO recipients and the hail parks SILENTLY as undeliverable (isaac-exi2
  lost 11 hours to an invented session-tag).
- Hail the **verify-band** (name from the incoming data block):
    {"band": "<verify-band value>", "params": {"bean-id": "{{bean-id}}"}, "reply_to": "<incoming hail id>"}
- Verifier pulls the beans repo root before reviewing.
- **Do not hail harden yourself.** If the project uses a harden stage, verify
  hands off via optional `harden-band` in data. Workers **should** still meet
  project quality bars (`.hardening.edn` / harden command defaults) so harden
  is enforcement, not first contact with the bar.

## Hand off to planner (e.g. on requirements conflict)

- When the bean cannot satisfy verifier standards (per failure note or your judgement), or per explicit bean instructions:
  - Keep status in-progress (or as appropriate), append observations about the conflict.
  - Send comm__send with content exactly: "orchestration-xxx ➡️ **scrapper** handed off to planner (plan-review-loop)"
  - Hail the **plan-band** with a prompt override explaining the conflict:
    {"band": "<plan-band value>", "params": {"bean-id": "{{bean-id}}"}, "reply_to": "<incoming hail id>", "prompt": "Conflict detected on bean {{bean-id}}: [summary from verifier note and requirements]. Returning for planner adjustment."}
- The planner will adjust (e.g. add unblock note) and hand back via the work-band.

The bean id travels in params; explanations travel in the prompt override; the
details of what was done live in the bean body; earlier context lives in the
thread (`hail__get`).
