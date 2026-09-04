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
7a. **Land it on main BEFORE marking completed.** `completed` means "on main", not "green on a branch". For every repo the bean's acceptance names, from that repo's sibling checkout:
    1. `git fetch origin && git checkout main && git pull --ff-only origin main`
    2. If the bean's work is already on `origin/main` (the worker pushed to main): confirm the acceptance SHA is an ancestor (`git merge-base --is-ancestor <sha> origin/main`) and skip to step 5.
    3. `git merge --no-edit bean/<id>` (a fast-forward is fine). **A conflict is a FAIL**, not something to resolve here: `git merge --abort`, then fail per step 8 with reason `branch conflicts with origin/main — rebase onto main and re-hand off`.
    4. If the merge was NOT a fast-forward, re-run the bean's targeted acceptance gate on the merged head (main moved under the branch). Red → `git reset --hard origin/main` and FAIL with the reason. Green → `git push origin main`.
    5. Append to the bean body (commit with the trailer):
       `## Landed on main (<YYYY-MM-DD>)` followed by one `main-sha: <repo> <sha>` line per repo.
    **A bean without a `main-sha:` line cannot be marked completed.** Do not pin, release, or deploy from this step — the train does that; your job ends at "it is on main and the gate is green there".
7b. **If pass:** `beans update <id> --status=completed --remove-tag=unverified`, then
    **data-driven next step** (do not hardcode a product pipeline):
    - If the delivery data block includes **`harden-band`** (non-blank string):
      1. `beans update <id> --tag=unhardened`
      2. Commit + push beans (`Isaac-Session` trailer).
      3. Hail the **harden-band** exactly as named in data, via `hail__send`:
         `{"band": "<harden-band value>", "params": {"bean-id": "<id>"}, "reply_to": "<incoming-id>"}`
      4. Notify verify pass (and that harden was queued). Do **not** treat the
         pipeline as finished until harden completes.
    - If **`harden-band` is absent**: pipeline is **terminal** after verify.
      Commit + push if needed; notify pass. (Projects without a harden stage —
      e.g. some Isaac installs — stay on work → verify only.)
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
     (e.g. "isaac-work-1" or "orchestration-work") via `hail__get` on the
     thread (look for the worker's originating hail).
   - **Never** use the band name itself (e.g. "isaac-work", "orchestration-work")
     as a `:session` value. Band names are selectors, not session names.
     Projects with parallel workers use names like `<project>-work-1`,
     `<project>-work-2`.
   - If the incoming hail to you had no submitter/worker session (e.g. arrived
     via band/CLI), just use the band — do not invent a session.

## Never end a turn in limbo

Every verification turn must end in exactly one of these states: **pass
terminal** (landed on main with `main-sha:` recorded, completed, no unverified, no harden-band, notify), **pass handed
to harden** (landed on main with `main-sha:` recorded, completed + unhardened, harden-band hail sent, notify), **fail**
(fail note + return/escalation hail sent), or **stuck** (plan-band hail sent
asking for what you need). **Do not hail yourself to continue.** No
session-direct continuation hails, no "N of 5". Stay in this turn (tool-loop
default 500). A turn that ends with only analysis strands the bean silently.

**If you do escalate to a human** (normally you route human escalation through
the planner instead — see "When you're stuck, ask the planner"), that
escalation is **terminal**: once the 🆘 comms are sent, do not re-hail, hand
off, or continue. Mark the bean held so it is visibly waiting, not silently
stranded — append a held note and commit/push it (`Isaac-Session` trailer):

```
## Held (awaiting human, <date>)

Escalated to human by **<crew>**@<session>. Blocking: <one-line synopsis>.
Resumes only on explicit human action. No crew re-picks this until then.
```

Nothing auto-resumes; a human resumes explicitly.

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
the delivery's data block (bean-repo, plan-band, work-band, notification-comm,
optional **harden-band**) or lives in the bean itself (scope, acceptance
criteria, worker notes).

Use the bean id to look up the bean and review it against the acceptance criteria (including any explicit first-fail instructions in the bean body).

**Thread with reply_to.** Set "reply_to" to the incoming hail's id on every
responding hail; the thread id is inherited automatically. Prior hails in the
thread (the worker's handoff, earlier fails) — including their prompts and
data — are fetchable with `hail__get`.

Use `hail__get` to inspect the worker's prior hail if you need its exact
session id for a direct return (rare; usually the band is sufficient and safer).

## When you're stuck, ask the planner — never drop the bean

If you cannot verify — implementation not found, acceptance criteria
ambiguous, missing context of any kind — do NOT fail the bean and stop.
Hail the **plan-band** (name in your data block) with :bean-id in params,
reply_to, and a prompt explaining exactly what you need. The planner resolves
it (and owns human escalation if needed). A verification that cannot
proceed is a question for the planner, not a dead end.

## Notifications

Send updates using `comm__send` at key points. Coordinates come from the
delivery's data block: comm = notification-comm's :id, target = its :channel.

Fill `<crew>` and `<session>` from **your own identity** (both are in your
system prompt's session identity block). Use exactly these formats for content:

- On starting review: `<bean-id> 👁️ **<crew>**@<session> verification started`
- On pass (terminal, no harden-band): `<bean-id> 🟢 **<crew>**@<session> verification passed`
- On pass (handed to harden): `<bean-id> 🟢 **<crew>**@<session> verification passed → harden`
  (send AFTER the harden-band hail succeeds)
- On fail (1st, back to worker): `<bean-id> ❌ **<crew>**@<session> verification failed (reason...) → back to worker`
- On escalation (2nd+ fail → planner): `<bean-id> 🆙 **<crew>**@<session> escalated to planner (N verify-fails, no progress) → plan`
  (send either AFTER the return/escalation hail so the at-a-glance reflects whose court the bean is in)

ID first for recognition; emoji for quick good/bad scanning.
