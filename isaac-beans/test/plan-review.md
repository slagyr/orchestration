# Plan-Review Test for Orchestration

See `shared.md` for the common **Remote Access**, **Installation / Deployment**, **Given**, and shared Pre-When verification sections.

## When

All verification steps execute against the live remote target system (zanebot).

- Real connection details are in the git-ignored `.env` at the root of the orchestration checkout (the directory containing `isaac-beans/` and `.beans.yml`). See `.env.example` (committed) for the expected format:

  ```
  host: <tailnet or hostname>
  user: zane
  ```

- **Never commit the real hostname (or the `.env` file itself) to git / github.**

- `cd` to the root of your local orchestration checkout (the dir with `.env`, `.beans.yml`, and `isaac-beans/`) before starting.

- The agent (or human) running the verification reads `.env` locally to reach the target.

- Construct the target (example parsing, adjust for your shell):

  ```sh
  HOST=$(grep '^host:' .env | cut -d: -f2 | xargs)
  USER=$(grep '^user:' .env | cut -d: -f2 | xargs)
  TARGET="$USER@$HOST"
  ```

- Execute the checks on the remote. All `ls`, `beans`, `git`, transcript inspection, etc. below are performed via SSH (or equivalent):

  ```sh
  ssh "$TARGET" 'ls /Users/zane/agents/orchistration/plan'
  ssh "$TARGET" 'cd /Users/zane/agents/orchistration/work/orchestration && beans show <id> && git log --oneline .beans/<id>--*.md'
  ```

  (For long-running or complex inspection, you may scp files or use other remote tools, but ssh + quoted command is the baseline.)

- In any committed examples, comments, or public discussion, use placeholder hosts such as `zane@orchestration-test.example.com`.

## Installation / Deployment

Before the Given state can be true, the custom hail bands and prompts must be installed into the Isaac root on the target.

1. Ensure `.env` exists at the orchestration checkout root (see `.env.example`).
2. Run the installer (it uses the same `.env`):

   ```sh
   cd /path/to/orchestration
   ./isaac-beans/install.sh
   ```

   - Use `./isaac-beans/install.sh --dry-run` (or `-n`) to preview.
   - The script supports local installs (when `host: localhost` or similar) and remote via ssh using the same `$TARGET` pattern as verification.
   - It copies the directories (overwriting existing files, but never deleting anything else):
     - `isaac-beans/config/` → `~/.isaac/config/`
     - `isaac-beans/prompts/` → `~/.isaac/prompts/`

3. After install, restart/reload the relevant sessions or daemons on the target so new skills, commands, and hail bands are loaded.

## When

- **Create a brand new bean** (never reuse IDs from previous runs). In the plan clone (`cd /Users/zane/agents/orchistration/plan/orchestration`), run:

  ```sh
  beans create "plan-review conflict loop (run-YYYY-MM-DD-HHMM)" \
    --type=task --priority=normal \
    --body 'This is a fresh process test bean for the plan-review orchestration flow.

Perform only the work described; append observations if process test.

## Plan-review loop instructions (all participants must follow exactly)

Use exact same sessions for returns so context is preserved. For handoffs back to a previous participant, target the exact session using the "session" key in hail-send (the session id is provided via submitter-session in incoming data or your current session context; example value is the "orchistration-work" session that already touched this bean). Do NOT use only band+tags for returns; use direct session frequencies.

When hailing directly to a session (no band template), you must provide a "prompt" that fully explains the situation, includes the bean-id, summarizes prior work/notes on this bean, and tells the recipient what to do next. Also pass bean-id (and other data) in "params".

Always use flat snake_case keys for hail-send (no "frequencies" wrapper). Pass notification-comm for pub updates. Use thread_id for correlation where available. Send comm_send to "pub" at every milestone using the at-a-glance format from the hail-bean-* skills: `{{bean-id}} {{emoji}} **{{crew}}** {{action}} ({{short-slug}})` for quick recognition (ID first, emoji status, bold crew/stage, context slug).

1. Worker (scrapper): Claim the bean (in-progress + unverified tag), append initial ## Process Observations. Hand off to verifier using direct session targeting if possible or the verify band, including submitter-crew, submitter-session (this session), thread_id, bean-id, etc.

2. Verifier (perceptor): On first receipt, note a conflict (the bean requirements cannot satisfy verifier standards). Append a clear ## Verification failed note. Do NOT complete. Hand the bean back to the *exact worker session* that sent it (use submitter-session value from the incoming hail data to set frequencies to that session; include full explanation prompt + bean-id).

3. Same worker session (exact continuity): Receive return from verifier. Determine there is a conflict that the current bean cannot satisfy the standards. Hand off to planner (use the plan band or direct if needed), passing submitter info so return can target this exact session. Include conflict details.

4. Planner (prowl): Receive the hail. Adjust by adding a note to this bean (edit and commit): "## Planner unblock note: bean is unblocked per plan-review test. Worker and verifier may proceed with the loop." Hand back to the *exact worker session* (use the submitter/work session info from incoming; direct session hail with explanatory prompt containing bean-id and the unblock note).

5. Same worker session: Receive from planner. Note the unblock in observations. Re-work/prepare the bean as needed. Hand off to the *exact verifier session* (target precisely using correlation info + explanatory prompt + bean id in params).

6. Verifier: On receipt of the unblocked bean, approve it. Remove unverified tag, set status completed. Append verification pass note.

This is explicitly a process test / no-op for orchestration flow validation.'
  ```

  Record the new bean ID (e.g. orchestration-abcd). Confirm it did not exist before by checking `beans list` or git history for the ID.

- A hail is sent to the orchistration work band with the id of the (just-created) bean. Example (use exact map for --params to avoid parse issues):

  ```sh
  isaac hail send --band orchistration-work --params '{:bean-id "orchestration-abcd"}'
  ```

## Then

- A turn on the orchistration-work session (scrapper) processes the initial hail.
- The bean is claimed (in-progress + unverified).
- Worker hands off to orchistration-verify (with submitter info + thread correlation).
- A turn on the orchistration-verify session (perceptor) receives it, "fails" per instructions (notes conflict), appends failure note, hands back **directly to the exact same worker session** using session frequencies (no band, or with targeting).
- (Continuation on the exact same worker session) Worker receives return, identifies conflict, hands off to planner (with submitter/work session info for exact return).
- A turn on the orchistration-plan session (prowl) receives the conflict hail, adjusts the bean by adding the unblock note (visible git commit + note in body from plan crew), hands back **directly to the exact worker session**.
- (Continuation on the exact same worker session) Worker receives planner adjustment (unblock note), incorporates it, hands off to the *exact* verifier session.
- A (subsequent) turn on the orchistration-verify session receives the unblocked bean, approves, completes it (status=completed, unverified tag removed).
- Correct clones appear under the appropriate role homes (/work for scrapper turns, /verify for perceptor, /plan for prowl).
- All relevant transcripts show the correct crew for each band turn.
- comm_send notifications to "pub" at each key step (visible in transcripts and Discord).
- Full chronology and exact-session continuity verifiable in transcripts + hail records + git history on the bean.
- No unverified tag at end; bean completed.

## How an Agent Should Verify This Test (Step-by-Step Checklist)

This section turns the abstract "Then" statements into a concrete, ordered list of actions an agent can execute to verify the plan-review flow on the live system.

**First** establish remote access using the instructions in the "Remote Access" section above (read `.env`, construct `$TARGET`). All commands below (`ls`, `beans`, `git`, transcript inspection, etc.) are executed on the remote target via `ssh "$TARGET" '...' ` (or equivalent).

**Important:** Every time you run this test, create a *completely new* bean with a fresh ID. Never reuse a bean ID or look up previous test beans. Use a unique run identifier in the title (see the When section for the exact creation command).

It is **not** a test framework script (no Cucumber). It is a manual verification procedure the agent should follow using `beans`, `git`, session transcripts/logs, `ls`, and hail data as rendered inside transcripts.

Run the checks roughly in this order and report **pass/fail + specific evidence** (e.g. commit hash + message, `beans show` output, transcript excerpt with surrounding context, `ls` output, session id continuity) for each.

Terminology note (for all checks):
- Role homes / sessions / bands: `orchistration-*` and `/Users/zane/agents/orchistration/{plan,work,verify}`.
- Project / repo / clone leaf dir / .beans prefix: `orchestration` (bean-repo in bands is `git@github.com:slagyr/orchestration.git`).
- Session tag used: `:orchestration`.

See `shared.md` for the common Pre-When checks (adapted per test for the specific bean title/description).

### Step 1-2: Initial work + first handoff to verifier
- Confirm the orchistration-work session (scrapper) received and processed the initial hail.
  - Full turn with crew scrapper.
  - Transcript shows incoming hail data with `orchistration-work`, bean-id value via params.
  - Followed hail-bean-work: pull, beans show, claim `in-progress` + `unverified`, append observations, comm_send to pub.
- Evidence of handoff to verify:
  - In work transcript: hail-send tool call (flat snake_case) to the verify-hail value, params include `:bean-id`, `submitter-crew`, `submitter-session` (or equivalent for exact targeting), `thread_id`, notification-comm, etc.
  - comm_send announcing handoff to pub.
- Bean state: in-progress + unverified. Git commits visible.

- Confirm orchistration-verify (perceptor) receives the first handoff.
  - Turn with crew perceptor on verify session.
  - Incoming context has the submitter info and bean-id.
  - hail-bean-verify followed.
  - Decides "fail" per bean instructions (conflict with standards), appends `## Verification failed` note, updates bean to in-progress (remove unverified temporarily per flow), commits.
  - Handoff back: hail-send to work-hail targeting the *exact original worker session* (using submitter-session/thread from incoming or explicit name 'orchistration-work').
  - comm_send for the failure/return.

### Step 3: Return to exact worker + handoff to planner
- Confirm the *exact same* orchistration-work session receives the return from verifier (transcript continuity, same session id/key in metadata, turns in the same .jsonl file).
  - Second (or continuation) turn on that specific scrapper session.
  - Transcript references the failure note and conflict.
  - Worker "determines conflict", follows instructions.
  - Appends observations about conflict.
  - Handoff to plan band (orchistration-plan), including submitter/worker session info, thread correlation, conflict details in params.
  - comm_send to pub.
- Bean state updates reflected in git (from the work clone).

### Step 4-5: Planner receives, adjusts, returns to exact worker
- Confirm orchistration-plan session (prowl) processes a turn.
  - Crew prowl.
  - Incoming hail data shows the conflict details + submitter worker session info from the worker.
  - Followed hail-bean-plan.
  - Adjusts the bean by editing/committing a note (e.g. adds "## Planner unblock note: bean is unblocked per plan-review test. Worker and verifier may proceed with the loop."). This is the observable change from the plan crew. Git commit from /plan clone.
  - comm_send announcing adjustment.
  - Handoff back **directly to the exact worker session** (frequencies set to the session-id from submitter info; use "session" key, provide full "prompt" explaining the unblock + bean-id + situation, include params and thread_id). No band template for the return.
- Confirm the *exact same* worker session receives the return from planner (same session evidence).
  - Turn on that scrapper session sees the planner unblock note.
  - Incorporates (observations), hands off to the *exact verifier session* (direct session targeting + explanatory prompt + bean id in params).
  - comm_send.

### Step 6-7: Final handoff to verifier + completion
- Confirm the orchistration-verify session (perceptor) receives the handoff from (the same) worker.
  - Turn with perceptor.
  - Sees the planner-adjusted bean + prior notes.
  - Approves per instructions.
  - `beans update` to remove unverified + completed status.
  - comm_send announcing approval and completion (to pub).
- Final bean state (from appropriate clones + git):
  - `beans show <id>` : completed, no unverified tag.
  - Git history shows the planner adjustment commit(s), worker re-handoff, final verify completion commit.
- Clones present:
  - Work clone(s) under /work (used by scrapper turns).
  - Verify clone under /verify.
  - Plan clone under /plan (at minimum for planner turn; may have been used earlier).

### Exact session targeting evidence (critical for this test)
- Transcript metadata / session ids prove:
  - The worker turns (initial + after verify return + after planner return) happened on the *exact same* 'orchistration-work' session instance (continuity in one .jsonl).
  - Verifier return and planner return targeted (and arrived at) that specific session using direct "session" in frequencies (the session-id from submitter info), not just band+tags.
  - Final handoff targeted the correct verifier session.
- Hail records / tool calls show "session": "<exact-id>" (direct to session, no band), the custom "prompt" field (full explanation of situation + bean-id, since no template), thread_id, and submitter data.
- All attributions link back to the single bean-id.
- The planner adjustment is exactly the unblock note added to the bean body (grep git history for the note text from the plan crew).

### Final overall checks
- Entire flow completed without (new) errors in the relevant session transcripts or server logs.
- Bean status/tag progression matches the 7-step loop exactly.
- All handoffs used the documented flat snake_case hail-send form.
- comm_send calls (with notification-comm "pub") at claim, each handoff, planner adjustment, returns, and final pass. Messages visible in Discord #pub.
- Chronology correct across timestamps, git commits, and transcript ordering.
- No "isaac" leakage; correct orchistration-* names, :orchestration tags, bean-repo, band names used throughout.
- The bean body instructions were followed for the conflict + exact-session loop.
- Planner adjustment is the specific unblock note (visible in bean body and the commit from plan session).
- For returns, direct session hails (with "session" frequencies + explanatory "prompt") were used to preserve context on the exact prior session.

Report every checklist item with concrete evidence (transcript excerpts with session ids and timestamps, exact hail-send argument blocks, `git log --oneline -S <id> -- .beans/...`, `beans show`, ls of clones, comm_send calls, pub messages if verifiable, etc.).

This test verifies the full round-trip planning + exact-session handback loop for bean orchestration.
