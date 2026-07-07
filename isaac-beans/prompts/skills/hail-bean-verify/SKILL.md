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
7. **A bean CANNOT pass if its acceptance scenarios are still @wip or red, or if no implementation exists.** Before passing, confirm the acceptance scenarios have had @wip removed and the suite runs GREEN, and that real implementation commits exist (not just scenario/doc commits). If the acceptance is unmet, this is a FAIL, not a pass — return to the work-band. A verifier that passes unbuilt work is the worst failure mode.
7b. If pass: `beans update <id> --remove-tag=unverified`
8. **If fail:** first record a durable fail marker, then decide where to hand
   off based on how many times this bean has already failed.

   a. **Append to the bean body** a note of the form
      `## Verify fail (attempt N, <YYYY-MM-DD>): <one-line reason>` and commit it
      (with the session trailer). N = the number of existing `## Verify fail`
      notes since the last `## Planner` note, plus one. This marker is the
      escalation counter — it must go in the bean body, not just the hail.

   b. **Count `## Verify fail` notes since the last `## Planner` note** in the
      bean body (a planner adjustment resets the count):
      - **Fewer than 2** → set `in-progress` and hail the **work-band** (the
        value from your data block) with :bean-id, reply_to (the incoming hail
        id), and a prompt explaining the failure. This is the normal
        rework loop.
      - **2 or more** → the bean is bouncing with no progress. Do **NOT** return
        it to the worker again. Set `in-progress` and hail the **plan-band**
        (the value from your data block) with :bean-id, reply_to, and a prompt
        explaining the repeated failure and exactly what the worker could not
        resolve. The planner rescopes, splits, unblocks, or escalates to human.
        A subsequent `## Planner` note resets the counter so the normal
        work→verify loop can resume.

   **Hail format (flat snake_case, no nested frequencies) — same shape for the
   work-band (normal fail) or the plan-band (escalation), swap the band value:**
   `{"band": "<work-band | plan-band>", "params": {"bean-id": "<id>"}, "reply_to": "<incoming-id>", "prompt": "VERIFY FAIL for <id> (reply_to: <incoming>): ..."}`

   **Targeting rule (critical):**
   - **Copy the band value EXACTLY from your delivery's data block — never type
     it from memory.** A typo'd band name (e.g. "orchistration-verify") routes
     nowhere and dead-letters silently.
   - **Band handoffs carry the `band` key and `params` ONLY** — never add
     `session-tags`, `crew`, or other frequency filters: extra filters can
     select ZERO recipients and the hail parks SILENTLY as undeliverable.
   - Use *only* the `band` key for the handoff in normal cases. The band config
     (session-tags, crew, prefer, reach) will select an appropriate worker
     session.
   - Add a `session` key **only** if you have retrieved a *concrete* session id
     (e.g. "isaac-work-1" or "orchestration-work") via `hail_get` on the
     thread (look for the worker's originating hail).
   - **Never** use the band name itself (e.g. "isaac-work", "orchestration-work")
     as a `:session` value. Band names are selectors, not session names.
     Projects with parallel workers use names like `<project>-work-1`,
     `<project>-work-2`.
   - If the incoming hail to you had no submitter/worker session (e.g. arrived
     via band/CLI), just use the band — do not invent a session.

## Never end a turn in limbo

Every verification turn must end in exactly one of these states: **pass**
(bean completed, tag removed, notification sent), **fail** (fail note +
return/escalation hail sent), **stuck** (plan-band hail sent asking for what
you need), or a **continuation hail to your own band** when verification
needs another turn. A turn that ends with only analysis strands the bean
silently. If you are running long, send the continuation hail EARLY — "ask me
to continue" is a dead end on an unattended turn.

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

Use `hail_get` to inspect the worker's prior hail if you need its exact
session id for a direct return (rare; usually the band is sufficient and safer).

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

Fill `<crew>` and `<session>` from **your own identity** (both are in your
system prompt's session identity block). Use exactly these formats for content:

- On starting review: `<bean-id> 👁️ **<crew>**@<session> verification started`
- On pass: `<bean-id> 🟢 **<crew>**@<session> verification passed`
- On fail (1st, back to worker): `<bean-id> ❌ **<crew>**@<session> verification failed (reason...) → back to worker`
- On escalation (2nd+ fail → planner): `<bean-id> 🆙 **<crew>**@<session> escalated to planner (N verify-fails, no progress) → plan`
  (send either AFTER the return/escalation hail so the at-a-glance reflects whose court the bean is in)

ID first for recognition; emoji for quick good/bad scanning.
