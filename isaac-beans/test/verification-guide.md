# Verification Guide for Orchestration Tests

See `shared.md` for Remote Access, Installation / Deployment, common Given, and Pre-When checks.

## Verification Approach

**This is not a test framework script (no Cucumber).** It is a manual verification procedure. Use `beans`, `git`, session transcripts/logs (in `~/.isaac/sessions/`), `ls`, and the rendered hail data inside transcripts to verify behavior.

Run checks roughly in order and report **pass/fail + specific evidence** for each item (e.g. commit hash + message, `beans show` output, transcript excerpt with surrounding context and timestamp, `ls` output, exact hail-send arguments).

**Critical rule for every run:** Always create a *brand new* bean with a unique ID (include a run timestamp or suffix in the title). Never reuse old bean IDs. Confirm freshness before starting the test steps.

## Terminology (used across all tests)
- Role homes / sessions / bands: `orchistration-*` and `/Users/zane/agents/orchistration/{plan,work,verify}`.
- Project / repo / clone leaf dir / .beans prefix: `orchestration` (bean-repo in bands is `git@github.com:slagyr/orchestration.git`).
- Session tag used: `:orchestration`.

## Common Evidence Collection Patterns

All inspection happens on the remote target via SSH (after constructing `TARGET` from `.env` as described in shared.md).

Typical commands:
```sh
ssh "$TARGET" 'cd /Users/zane/agents/orchistration/plan/orchestration && beans show <id>'
ssh "$TARGET" 'cd /Users/zane/agents/orchistration/work/orchestration && git log --oneline -S <id> -- .beans/'
ssh "$TARGET" 'tail -c 50000 ~/.isaac/sessions/orchistration-work.jsonl | grep -E "<id>|hail|comm_send" | tail -20'
```

Look for:
- Full turns with correct crew in the relevant `.jsonl` file.
- Hail data arriving via `params` (flat snake_case keys like `:bean-id`, `submitter-session`, `thread_id`, `notification-comm`).
- Exact `hail-send` calls (flat top-level keys: `band`, `session`, `params`, `prompt`).
- `comm_send` calls with `notification-comm` to discord channel "pub" using the at-a-glance format.
- Git commits on the bean file with clear messages.
- Bean state via `beans show` (status + tags).
- Clones present with `.git/`, `.beans.yml`, `.beans/`.

**Always verify:**
- No "isaac" references leaked in active context (grep recent transcripts, bean body, and band files for "isaac" case-insensitive, excluding historical notes).
- Correct `orchistration-*` names, `:orchestration` tags, and bean-repo used.
- Fresh bean with no prior history for this ID.
- Notifications used the documented at-a-glance strings.

## Discord / Pub Notifications
- "pub" channel name resolution must be configured in the target's `~/.isaac/config/isaac.edn`.
- Confirm sent messages match the exact at-a-glance strings from the skills.

## iMessage Notifications (for human-needed)
- Look for the `comm_send` tool call in the plan transcript with `comm="imessage"`, `imessage.target="micahmartin@mac.com"`, and content that is visually stimulating (emojis like 🆘🚨, structure with newlines, bean ID, crew, synopsis, and call to action).
- The actual delivery is observed outside the system (e.g. received message).

---

## Happy Path Specific Checks

Follow shared.md remote access + pre-when first.

- Confirm orchistration-work (scrapper) turn: claim, observations, handoff to verify.
- Bean reaches `in-progress` + `unverified`.
- Verify clone established under work role home.
- orchistration-verify (perceptor) turn: receives, passes, completes bean (`status=completed`, no unverified tag).
- Plan clone visible under plan role home.
- comm_send calls at key milestones (claim, handoff, verify start, pass) with correct at-a-glance content.
- Git history shows the state changes.
- No errors in transcripts.

## Verify-Fail Specific Checks

Follow shared.md remote access + pre-when first.

**First cycle:**
- Work turn 1 (scrapper): claims, hands off to verify.
- Verify turn 1 (perceptor): follows bean body "fail first", appends `## Verification failed`, returns to exact same `orchistration-work` session using direct `session` key + explanatory prompt.
- Bean temporarily back to `in-progress` (unverified removed for the return).

**Second cycle (same work session):**
- Same work session receives return, re-tags `unverified`, hands off again.
- Verify turn 2: now passes, completes the bean.
- Final state: `completed`, no unverified tag.
- Evidence of exact same session for the two worker turns (transcript continuity + session id).
- All handoffs used submitter-session for targeting.

## Plan-Review Specific Checks

Follow shared.md remote access + pre-when first.

Key sequence evidence (use transcripts + git for chronology):

1. Initial work (scrapper) → hands off to verify (with submitter info + thread).
2. Verify (perceptor) → appends failure note → returns to *exact same worker session* using direct `session` target.
3. Same worker session → escalates to planner (plan band or direct), passes submitter/worker session info.
4. Planner (prowl) receives → edits bean (adds unblock note) + commits from plan clone → hands back to *exact worker session* using `session` key + full explanatory prompt.
5. Same worker → incorporates note → hands off to *exact verifier session*.
6. Verifier passes and completes.

Look for:
- Direct `"session"` key in hail-send (not just band) for returns.
- Planner edit/commit visible in plan clone git.
- Specific unblock note text in bean body and commit.
- comm_send at every handoff and planner action using documented format + slug (e.g. `(plan-review-loop)`).
- Exact session continuity in one `.jsonl` file for the worker turns.

## Human-Needed Specific Checks

Follow shared.md remote access + pre-when first.

Sequence:
1. Work (scrapper) claims + hands to verify (submitter info).
2. Verify returns to exact worker session (no completion).
3. Same worker escalates to planner.
4. Planner (prowl) determines it cannot resolve.
5. Planner appends `## Human needed` note + synopsis to bean, commits/pushes from plan clone.
6. No handback to worker.
7. Discord: `orchestration-XXXX 🆘 **prowl** human help needed (short synopsis)`
8. iMessage: comm_send with `comm="imessage"`, target `micahmartin@mac.com`, content like:
   ```
   🆘🚨 HUMAN HELP NEEDED 🚨🆘

   Bean: orchestration-g2zf
   From: **prowl**

   Requirements conflict on feature priority; needs human decision.

   👉 Check Discord #pub for full details.
   ```

Evidence:
- Planner transcript shows the two comm_send calls (discord + imessage) with exact format.
- Bean ends `in-progress` with human note.
- Exact `session` targeting used on verify → worker return.
- Fresh bean + all prior steps used flat snake_case + submitter info.

---

Use the patterns above together with the high-level Given/When/Then in each test file. Always capture concrete excerpts rather than summaries.