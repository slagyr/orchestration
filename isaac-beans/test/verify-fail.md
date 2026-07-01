# Verify-Fail Test for Orchestration

See `shared.md` for Remote Access, Installation, common Given and Pre-When checks.

See `verification-guide.md` for the verification approach, evidence collection patterns, and common checks.

## Given
- Standard orchestration sessions and installed prompts are active.

## When
- Create a brand new bean with explicit first-fail instructions in the body (e.g. "no-op verify-fail bean (run-YYYY-MM-DD-HHMM)"):
  ```
  Fail the first verification. Append a clear failure note and send the bean back (hail to the work band) specifically to the same session 'orchistration-work' that performed the initial work. On the second verification, pass the bean and complete it (remove unverified tag, set status completed).
  ```
  Commit and push.
- Hail to the work band.

## Then
- First work turn (scrapper) claims + hands off to verify.
- First verify turn (perceptor) follows the "fail first" body: appends `## Verification failed`, returns to the *exact same* worker session using direct `session` targeting.
- Same worker session receives the return, re-tags `unverified`, hands off again.
- Second verify turn passes and completes the bean (`status=completed`, no unverified tag).
- All steps use exact session continuity for the worker turns.
- Correct notifications and no errors.

## Verification Notes

See verification-guide.md for detailed evidence collection steps and full checklist patterns.