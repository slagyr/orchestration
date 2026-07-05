# Verify-Escalation Test for Orchestration (isaac-qpp4)

See `shared.md` for Remote Access, Installation, common Given and Pre-When checks.

See `verification-guide.md` for the verification approach, evidence collection patterns, and common checks.

Exercises the verify-loop escalation guard: after **2** verify-fails with no
planner intervention, the verifier escalates to the **plan band** instead of
bouncing to the worker forever. The `## Planner` note resets the counter.

## Given
- Standard orchestration sessions and installed prompts are active.

## When
- Create a brand new bean whose body instructs a repeatable, unresolvable
  failure that only a planner rescope can fix (e.g. "escalation bean
  (run-YYYY-MM-DD-HHMM)"):
  ```
  This bean's acceptance cannot be satisfied by the worker as written (it asks
  for something impossible / contradictory). Verifier: fail it each time,
  appending a `## Verify fail (attempt N, <date>)` note to the bean body before
  each return. Worker: rework and re-hand-off, but you cannot make it pass.
  After the SECOND verify-fail (two `## Verify fail` notes, no `## Planner` note
  between them), the verifier must escalate to the plan band instead of the
  work band. Planner: on receiving the escalation, append a `## Planner` note
  that rescopes the acceptance to something achievable, then hand back to work.
  Worker: satisfy the rescoped acceptance and hand to verify. Verifier: pass
  and complete.
  ```
  Commit and push.
- Hail to the work band.

## Then
- Work (scrapper) claims + hands off to verify.
- **Verify fail #1**: verifier appends `## Verify fail (attempt 1, ...)` to the
  bean body, returns to the work band (`reply_to` + prompt). Notification:
  `❌ ... verification failed (...) → back to worker`.
- Worker reworks (cannot fix) + hands off to verify again.
- **Verify fail #2**: verifier appends `## Verify fail (attempt 2, ...)`, counts
  **2** `## Verify fail` notes since the last `## Planner` note (none), and
  therefore hails the **plan band** — NOT the work band. Notification:
  `🆙 ... escalated to planner (2 verify-fails, no progress) → plan`.
- **Planner** receives the escalation, appends a real `## Planner` note that
  rescopes the acceptance, commits from the plan clone, hands back to the work
  band (`reply_to` + prompt). The `## Planner` note resets the verify-fail count.
- Worker satisfies the rescoped acceptance + hands to verify.
- Verifier counts **0** `## Verify fail` notes since the `## Planner` note (fresh
  count), verifies, and **completes** the bean (`status=completed`, no
  unverified tag).
- **Every hail carries the same thread-id** (inherited via `reply_to`).
- `:bean-id` is the only param on every hail; band `data:` supplies coordinates.
- Correct at-a-glance notifications; no infinite work↔verify bounce.

## Verification Notes

Key evidence: the bean body ends with exactly two `## Verify fail` notes
followed by one `## Planner` note, and the second verify-fail's outbound hail
targets the **plan band** (confirm in the delivered hail records), not the work
band. See verification-guide.md for the full checklist and evidence patterns.
