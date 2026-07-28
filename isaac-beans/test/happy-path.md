# Happy Path Test for Orchestration

See `shared.md` for Remote Access, Installation, common Given and Pre-When checks.

See `verification-guide.md` for the verification approach, evidence collection patterns, and common checks.

## Given
- Standard orchestration sessions and installed prompts are active.
- **Note on harden:** the stock `_orchestration-template` includes
  `harden-band`. With that key present, a full happy path is
  work → verify → harden (see `harden-path.md`). If you temporarily
  **omit** `harden-band` from data (Isaac-style), verify is terminal as
  below.

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
  isaac hail send --band orchestration-work --params '{:bean-id "orchestration-abcd"}'
  ```

## Then (when `harden-band` is **absent**)
- A turn runs on the orchestration-work session (crew scrapper): claims the bean, appends observations, tags it `unverified`, hands off to verify.
- A turn runs on the orchestration-verify session (crew perceptor): reviews and completes the bean (status=`completed`, unverified tag removed; **no** `unhardened` tag, **no** hail to harden).
- Correct at-a-glance notifications are sent to "pub" at claim, handoff, verification, and pass.
- The orchestration repo is cloned under the work and plan role homes.
- No errors in the relevant session transcripts.

## Then (when `harden-band` is **present** — stock template)

Follow **`harden-path.md`** (work → verify → harden, process-test skips quality tools).
