---
name: hail-bean-verify
description: Bootstrap and run bean verification from a hail delivery via verify band. Use for orchestration and process-test beans in any project.
---

# Hail-driven bean verify

Use when a hail (or band prompt) assigns bean verification.

## Bootstrap checklist

1. **Find the beans repo** — the directory containing `.beans/`.
2. **`git -C <beans-repo>` pull --rebase** — sync state.
3. **`beans list --tag=unverified`** or `beans show <id>`.
4. **Find the implementation repo** — bean scope / title / body names the repo
   (a module sibling or the beans repo itself). Locate the work commits there:
   `git log --grep=<bean-id>` in the sibling checkout (pull first; clone on
   demand if missing). Do NOT assume the beans-repo HEAD holds the
   implementation — the bean handoff commit usually touches only `.beans/`.
5. **Skills fallback** — read this file and `prompts/commands/verify.md` if `list_skills` fails.
6. Verify the bean per `prompts/commands/verify.md`.
7. If pass: `beans update <id> --remove-tag=unverified`
8. If fail: return to `in-progress` and hail the **work-band** with :bean-id,
   reply_to (the incoming hail id), and a prompt override explaining the
   failure. On subsequent passes, complete.

## Commit trailer

Any verification-side commit in the beans repo should include the current
session id as a trailer:

```text
Isaac-Session: <session-id>
```

Recommended form:

```sh
git commit --trailer "Isaac-Session: <session-id>"
```

The current session id comes from your session identity block.

## Incoming hail data

**:bean-id is the only required param.** Everything else you need arrives in
the delivery's data block (bean-repo, plan-band, work-band, notification-comm)
or lives in the bean itself (scope, acceptance criteria, worker notes).

Use the bean id to look up the bean and review it against the acceptance criteria (including any explicit first-fail instructions in the bean body).

**Thread with reply_to.** Set "reply_to" to the incoming hail's id on every
responding hail; the thread id is inherited automatically. Prior hails in the
thread (the worker's handoff, earlier fails) — including their prompts and
data — are fetchable with `hail_get`.

## When you're stuck, ask the planner — never drop the bean

If you cannot verify — implementation not found, acceptance criteria
ambiguous, missing context of any kind — do NOT fail the bean and stop.
Hail the **plan-band** (name in your data block) with :bean-id in params,
reply_to, and a prompt explaining exactly what you need. The planner resolves
it (and owns human escalation if needed). A verification that cannot
proceed is a question for the planner, not a dead end.

## Notifications

Send updates using `comm_send` at key points. Coordinates come from the
delivery's data block: comm = notification-comm's :id, target = its :channel.

Fill `<crew>` with **your own crew name** (it's in your system prompt's
session identity block). Use exactly these formats for content:

- On starting review: `<bean-id> 👁️ **<crew>** verification started`
- On pass: `<bean-id> 🟢 **<crew>** verification passed`
- On fail: `<bean-id> ❌ **<crew>** verification failed (reason...)`

ID first for recognition; emoji for quick good/bad scanning.
