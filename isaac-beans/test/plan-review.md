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
  isaac hail send --band orchistration-work --params '{:bean-id "orchestration-abcd"}'
  ```

## Then
- Work (scrapper) claims, hands off to verify (with submitter info).
- Verify returns to exact worker session after noting conflict.
- Same worker escalates to planner.
- Planner adjusts the bean (adds unblock note + commits from plan clone) and hands back to exact worker session.
- Worker hands off to exact verifier session.
- Verifier completes the bean.
- All handoffs use direct `session` targeting where returns occur.
- Correct at-a-glance notifications and exact session continuity.
- Bean ends completed with no unverified tag.

## Verification Notes

See verification-guide.md for detailed evidence collection steps (exact session targeting via "session" key, planner edit/commit, comms, chronology, etc.).
