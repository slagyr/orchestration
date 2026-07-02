# Plan-Review Test for Orchestration

See `shared.md` for Remote Access, Installation, common Given and Pre-When checks.

See `verification-guide.md` for the verification approach, evidence collection patterns, and common checks.

## Given
- Standard orchestration sessions and installed prompts are active.

## When
- Create a brand new bean locally (commit + push first). The body contains the full loop instructions for exact-session handoffs and the planner unblock step (see the long `--body` in the original for the exact crew instructions that must be followed).

  Example:
  ```sh
  beans create "plan-review conflict loop (run-YYYY-MM-DD-HHMM)" \
    --type=task --priority=normal \
    --body '... (full loop instructions for workers/verifier/planner) ...'
  ```

- Hail to the work band:
  ```sh
  isaac hail send --band orchestration-work --params '{:bean-id "orchestration-abcd"}'
  ```

## Then
- Work (scrapper) claims, hands off via the verify band with `reply_to`.
- Verify notes the conflict and returns via the work band (`reply_to` + prompt
  override explaining the failure). Band reach `:one` pins each role to its
  dedicated session, so session continuity holds without direct targeting.
- Same worker session escalates via the plan band (`reply_to` + prompt override).
- Planner adjusts the bean (adds unblock note + commits from plan clone) and
  hands back via the work band (`reply_to` + prompt override).
- Worker hands off via the verify band again (`reply_to`).
- Verifier completes the bean.
- **Every hail in the loop carries the same thread-id** (inherited via
  `reply_to` from the original dispatch) — verify in the delivered hail records.
- `:bean-id` is the only param on every hail; band `data:` supplies coordinates.
- Correct at-a-glance notifications (formats from the hail-bean-* skills,
  crew filled from ambient identity).
- Bean ends completed with no unverified tag.

## Verification Notes

See verification-guide.md for detailed evidence collection steps (exact session targeting via "session" key, planner edit/commit, comms, chronology, etc.).
