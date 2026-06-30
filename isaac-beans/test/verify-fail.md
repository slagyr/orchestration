# Verify-Fail Test for Orchestration

See `shared.md` for the common **Remote Access**, **Installation / Deployment**, **Given**, and shared Pre-When verification sections.

The sections below are specific to this test.

## When

- **Create a brand new bean** (never reuse IDs from previous runs). In the plan clone, run a `beans create` with a unique title including a run timestamp (e.g. "no-op verify-fail bean (run-YYYY-MM-DD-HHMM)"), and include the explicit first-fail instructions in the body:

  ```
  Fail the first verification. Append a clear failure note and send the bean back (hail to the work band) specifically to the same session 'orchistration-work' that performed the initial work. On the second verification, pass the bean and complete it (remove unverified tag, set status completed).
  ```

- A hail is sent to the orchistration work band with the id of the (just-created fresh) bean.

## Then

- A first turn on the orchistration-work session should have been run with the crew scrapper.
- The bean should be in-progress.
- The bean should be tagged `unverified`.
- The orchestration repo (bean host project) should be cloned at /Users/zane/agents/orchistration/work/orchestration.
- A first turn on the orchistration-verify session should have been run with crew perceptor.
- The verify turn fails (per bean instructions): the bean is set back to `in-progress` (unverified tag removed), a `## Verification failed` note is appended, and a hail is sent back to the work band targeting the *same* session 'orchistration-work'.
- A second turn on the *same* orchistration-work session (scrapper) receives the failed bean and tags it `unverified` again (staying in-progress or re-claiming as needed), then hands off to verify.
- A second turn on the orchistration-verify session (perceptor) passes the bean and completes it: `status=completed`, no `unverified` tag.
- The orchestration repo (bean host project) should be cloned at /Users/zane/agents/orchistration/plan/orchestration.

## How an Agent Should Verify This Test (Step-by-Step Checklist)

This section turns the abstract "Then" statements into a concrete, ordered list of actions an agent can execute to verify the verify-fail scenario on the live system.

**First** establish remote access using the instructions in the "Remote Access" section above (read `.env`, construct `$TARGET`). All commands below (`ls`, `beans`, `git`, transcript inspection, etc.) are executed on the remote target via `ssh "$TARGET" '...' ` (or equivalent).

**Important:** Every time you run this test, create a *completely new* bean with a fresh ID. Never reuse a bean ID or look up previous test beans. Use a unique run identifier in the title (see the When section).

It is **not** a test framework script (no Cucumber). It is a manual verification procedure the agent should follow using `beans`, `git`, session transcripts/logs, `ls`, and hail data as rendered inside transcripts.

Run the checks roughly in this order and report **pass/fail + specific evidence** (e.g. commit hash + message, `beans show` output, transcript excerpt with surrounding context, `ls` output) for each.

Terminology note (for all checks):
- Role homes / sessions / bands: `orchistration-*` and `/Users/zane/agents/orchistration/{plan,work,verify}`.
- Project / repo / clone leaf dir / .beans prefix: `orchestration` (bean-repo in bands is `git@github.com:slagyr/orchestration.git`).
- Session tag used: `:orchestration`.

See `shared.md` for the common Pre-When checks (adapted per test for the specific bean title/description and instructions).

### During/After first "When" (the hail to work band) and first verify fail
- Confirm the orchistration-work session (scrapper) received and processed the hail (first turn). Primary evidence is the session transcript/log for the relevant turn (hail data is injected into the prompt context):
  - A full turn ran (LLM + tools) after the hail arrived.
  - Crew was "scrapper".
  - Transcript shows the incoming data map / band context: references the `orchistration-work` band, `bean-repo: git@github.com:slagyr/orchestration.git`, `bean: <the-id>`, and the concrete bean-id value.
  - The bean-id (and other data) arrived via params (visible in the rendered hail data or how the agent used it). No reliance on a top-level "payload" field.
  - Evidence the hail-bean-work skill + work command were followed: bootstrap checklist steps (find beans repo containing `.beans/`, `git -C <clone> pull --rebase`, `beans show`, claim via `beans update --status=in-progress` + commit/push, etc.).
  - Turn explicitly recognized the bean as process test / no-op (from body) and followed the minimal path (no TDD / spec runs required). The first-fail instruction was noted for handoff.
- In the (first) work session transcript, confirm `comm_send` was used with the `notification-comm` (to #pub) for claim/observations/handoff announcements. Messages visible in Discord #pub.

- Verify the bean state changed after the first work turn (run from a clone of the orchestration repo that has done `git pull`):
  - `beans show <id>` reports status `in-progress` and includes the `unverified` tag.
  - Git history on the bean file (in the beans root clone): commit that set status `in-progress`, followed by a commit that added the `unverified` tag. Report short hash + commit message for each.

- Confirm the orchestration repo (bean host containing `.beans/` + `.beans.yml`) was cloned/used under the worker's role home:
  - `ls /Users/zane/agents/orchistration/work/orchestration`
  - Contains `.git/`, `.beans.yml`, `.beans/`, the specific bean file, etc.
  - (Optional) `git -C /Users/zane/agents/orchistration/work/orchestration remote -v` matches the expected bean-repo.

- Confirm process-test / no-op artifacts from the first work turn:
  - The bean body (via `beans show <id>` or direct file read in a clone) now contains an appended `## Process Observations` section with notes from the turn (including intent to hand off for first-fail verification).

- Confirm handoff hail from the first work turn to the orchistration-verify band (look in the *work session transcript* for the hail-send / handoff action):
  - Evidence of sending to the verify-hail band ("orchistration-verify" or the value from data).
  - The sent params contain at least `:bean-id` (plus any other project data as allowed).
  - Note any thread-id or correlation value for later matching.
  - Confirm notification sent to #pub announcing handoff (comm_send evidence + channel message).

- Confirm the first orchistration-verify session (perceptor) processed a turn:
  - Transcript shows a turn with crew "perceptor".
  - Evidence of hail-bean-verify skill bootstrap and execution: pull --rebase in the beans repo, `beans list --tag=unverified` or `beans show`, review of acceptance criteria (including the explicit first-fail instruction in the bean body), decision to fail, and state update.
  - The verify transcript's incoming hail context shows `:bean-id` (and other data) present in params.
  - The turn fails per bean instructions: bean updated to `in-progress` (unverified tag removed), `## Verification failed` note appended with reason (e.g. "per first-fail instruction in bean body"), committed.
  - Evidence of handoff back: hail sent to the work band specifically targeting session 'orchistration-work' (same session as initial work).
  - In the verify transcript, confirm `comm_send` to notification-comm (#pub) announcing the failure and return.

- Verify the bean state after first verify fail (via `beans show` and git history from appropriate clone):
  - `beans show <id>` reports status `in-progress` (no `unverified` tag).
  - Git commit from the verify phase: status set to `in-progress`, unverified tag removed, `## Verification failed` section added.
  - Handoff hail record to orchistration-work targeting the same session.

### During/After second work turn and second verify pass
- Confirm the *same* orchistration-work session (scrapper) received and processed the returned bean (second turn). Primary evidence is continuation in the same session transcript/log:
  - A second full turn ran on the *exact same session* 'orchistration-work' (evidence: session metadata, transcript continuity, same session id).
  - Crew was still "scrapper".
  - Transcript shows incoming data from the verify handoff (bean-id, failure note reference).
  - Evidence the hail-bean-work skill + work command were followed again: re-bootstrap, `beans show`, update to tag `unverified` again + commit/push.
  - Turn notes the first-fail result and re-tags for second verification pass.
- Confirm `comm_send` to #pub in this second work turn transcript (e.g. re-processing after failure).

- Verify the bean state after the second work turn:
  - `beans show <id>` reports status `in-progress` and includes the `unverified` tag (re-applied).
  - Git history on the bean file: additional commit that (re-)added the `unverified` tag after the failure note.
  - `## Process Observations` section now includes notes from the second work turn (re-processing the failed bean).

- Confirm handoff hail from the second work turn to the orchistration-verify band:
  - Evidence in the (same) work session transcript of sending to verify-hail with `:bean-id`.
  - Params include `:bean-id`.
  - Confirm notification to #pub for second handoff (via comm_send).

- Confirm the second orchistration-verify session (perceptor) processed a turn:
  - Transcript shows a (second) turn with crew "perceptor" (may be same or continued session context).
  - Evidence of hail-bean-verify skill: pull, review (now passes per bean instruction on second attempt), state update.
  - The verify transcript shows `:bean-id` and reference to prior failure note.
  - No early failure; proceeds to pass.
  - Confirm `comm_send` to #pub announcing verification pass and completion (in transcript and Discord #pub).

- Verify final bean state (via `beans show <id>` from any pulled clone of the orchestration repo + git history on the bean file):
  - `beans show <id>` reports status `completed` with no `unverified` tag.
  - Git commit(s) from the second verify phase: status to `completed`, unverified tag removed. Report hash + message.
  - Confirm the update was executed (from appropriate clone).

- Confirm the orchestration repo clone under the plan role home:
  - `ls /Users/zane/agents/orchistration/plan/orchestration`
  - Contains `.git/` (and `.beans/`).

- Double-check no "isaac" references leaked and correct names were used:
  - Grep the relevant recent session transcripts/logs and the final bean file (exclude any pre-existing historical notes) for "isaac" (case-insensitive). None in active context or data.
  - Active session-tags are `:orchestration`; bands referenced are the `orchistration-*` names; data maps reference the correct bean-repo and band names.
  - Evidence that the return handoff targeted the *same* 'orchistration-work' session (not a different worker or plan).

### Final overall checks
- The entire flow completed without errors visible in the work and verify session transcripts.
- The bean followed the exact status + tag progression for verify-fail: `todo` → (work1) `in-progress` + `unverified` → (verify1 fail) `in-progress` (no tag, + failure note) → (work2 same session) `in-progress` + `unverified` (re-tagged) → (verify2 pass) `completed` (untagged).
- All clones, turns (including second work turn on the *exact same session*), state changes, and the handoffs (including return to same session) are attributable to this specific bean-id (via transcript mentions of the id, data maps, commit messages on the bean file, or thread/correlation ids).
- Chronology is correct: first work → first verify fail + return hail → second work (same session) → second verify pass (observable via transcript ordering, log timestamps, or git commit dates on the bean file).
- Evidence of "same session" for the two worker turns (session id continuity in transcripts/metadata).
- The bean instructions were followed: explicit first-fail + targeted return to 'orchistration-work', then pass on second.
- Notifications: transcripts for both work turns and both verify turns show `comm_send` using notification-comm to #pub (e.g. claim, fail announcement, re-tag, pass); messages appear in Discord #pub.

Report the results for every checklist item above with concrete evidence (full `beans show` output excerpts, `git log --oneline -S status -- .beans/<id>--*.md` or `git show <hash>`, transcript excerpts with context around the hail data and actions, `ls` listings, same-session evidence from session ids, etc.). If any step cannot be verified with the available tools/logs/access, explicitly note what is missing and how the check was approximated.

This procedure lets an agent (or human) mechanically walk through the verify-fail scenario using only observable system artifacts. The key differentiator from happy-path is the explicit failure + return to the *same* worker session before the second (successful) verification.