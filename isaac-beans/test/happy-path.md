# Happy Path Test for Orchestration

See `shared.md` for Remote Access, Installation, common Given and Pre-When checks.

See `verification-guide.md` for the verification approach, evidence collection patterns, and common checks.

## Given
- Standard orchestration sessions (orchistration-work, verify, plan) and installed prompts are active.

## When
- Create a brand new bean (never reuse IDs). In the plan clone:
  ```sh
  beans create "no-op that is a no operation bean (run-YYYY-MM-DD-HHMM)" \
    --type=task --priority=normal \
    --body "This is a fresh process test / no-op bean for verifying the orchestration happy path on this specific run. Perform only the work described; append observations if process test."
  ```
  Commit and push the bean file first.
- Send a hail:
  ```sh
  isaac hail send --band orchistration-work --params '{:bean-id "orchestration-abcd"}'
  ```

## Then
- A turn runs on the orchistration-work session (crew scrapper): claims the bean, appends observations, tags it `unverified`, hands off to verify.
- A turn runs on the orchistration-verify session (crew perceptor): reviews and completes the bean (status=`completed`, unverified tag removed).
- Correct at-a-glance notifications are sent to "pub" at claim, handoff, verification, and pass.
- The orchestration repo is cloned under the work and plan role homes.
- No errors in the relevant session transcripts.
