# Happy Path Test for Orchestration

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
- **Create a brand new bean** (never reuse IDs from previous runs such as orchestration-lrlu or orchestration-43d1). In the plan clone (`cd /Users/zane/agents/orchistration/plan/orchestration`), run:
  ```sh
  beans create "no-op that is a no operation bean (run-YYYY-MM-DD-HHMM)" \
    --type=task --priority=normal \
    --body "This is a fresh process test / no-op bean for verifying the orchestration happy path on this specific run. Perform only the work described; append observations if process test."
  ```
  Record the new bean ID (e.g. orchestration-abcd). Confirm it did not exist before by checking `beans list` or git history for the ID.
- A hail is sent to the orchistration work band with the id of the (just-created) bean. Example (use exact map for --params to avoid parse issues):
  ```sh
  isaac hail send --band orchistration-work --params '{:bean-id "orchestration-abcd"}'
  ```

## Then
- A turn on the orchistration-work session should have been run with the crew scrapper.
- The bean should be in-progress.
- The bean should be tagged `unverified`. (Both of these can be verified by `beans show <id>` and looking at the commits on the bean file.)
- The orchestration repo (bean host project) should be cloned at /Users/zane/agents/orchistration/work/orchestration.
- A turn on the orchistration-verify session should have been run with crew perceptor.
- The bean should be completed and untagged (no `unverified` tag).
- The orchestration repo (bean host project) should be cloned at /Users/zane/agents/orchistration/plan/orchestration.

## How an Agent Should Verify This Test (Step-by-Step Checklist)

This section turns the abstract "Then" statements into a concrete, ordered list of actions an agent can execute to verify the happy path on the live system.

**First** establish remote access using the instructions in the "Remote Access" section above (read `.env`, construct `$TARGET`). All commands below (`ls`, `beans`, `git`, transcript inspection, etc.) are executed on the remote target via `ssh "$TARGET" '...' ` (or equivalent).

**Important:** Every time you run this test, create a *completely new* bean with a fresh ID. Never reuse a bean ID or look up previous test beans. Use a unique run identifier in the title (see the When section for the exact creation command).

It is **not** a test framework script (no Cucumber). It is a manual verification procedure the agent should follow using `beans`, `git`, session transcripts/logs, `ls`, and hail data as rendered inside transcripts.

Run the checks roughly in this order and report **pass/fail + specific evidence** (e.g. commit hash + message, `beans show` output, transcript excerpt with surrounding context, `ls` output) for each.

Terminology note (for all checks):
- Role homes / sessions / bands: `orchistration-*` and `/Users/zane/agents/orchistration/{plan,work,verify}`.
- Project / repo / clone leaf dir / .beans prefix: `orchestration` (bean-repo in bands is `git@github.com:slagyr/orchestration.git`).
- Session tag used: `:orchestration`.

See `shared.md` for the common Pre-When checks (adapted per test for the specific bean title/description).

### During/After "When" (the hail to orchistration-work band)
- Confirm the orchistration-work session (scrapper) received and processed the hail. Primary evidence is the session transcript/log for the relevant turn (hail data is injected into the prompt context):
  - A full turn ran (LLM + tools) after the hail arrived.
  - Crew was "scrapper".
  - Transcript shows the incoming data map / band context: references the `orchistration-work` band, `bean-repo: git@github.com:slagyr/orchestration.git`, `bean: <the-id>`, and the concrete bean-id value.
  - The bean-id (and other data) arrived via params (visible in the rendered hail data or how the agent used it). No reliance on a top-level "payload" field.
  - Evidence the hail-bean-work skill + work command were followed: bootstrap checklist steps (find beans repo containing `.beans/`, `git -C <clone> pull --rebase`, `beans show`, claim via `beans update --status=in-progress` + commit/push, etc.).
  - Turn explicitly recognized the bean as process test / no-op (from body) and followed the minimal path (no TDD / spec runs required).
- In the work session transcript, confirm the `comm_send` tool was used (with the `notification-comm` data, targeting discord channel "pub") to announce progress such as claim, observations appended, or upcoming handoff. Verify the corresponding message(s) appeared in the Discord #pub channel.

- Verify the bean state changed after the work turn (run from a clone of the orchestration repo that has done `git pull`):
  - `beans show <id>` reports status `in-progress` and includes the `unverified` tag.
  - Git history on the bean file (in the beans root clone): commit that set status `in-progress`, followed by a commit that added the `unverified` tag. Report short hash + commit message for each.

- Confirm the orchestration repo (bean host containing `.beans/` + `.beans.yml`) was cloned/used under the worker's role home:
  - `ls /Users/zane/agents/orchistration/work/orchestration`
  - Contains `.git/`, `.beans.yml`, `.beans/`, the specific bean file, etc.
  - (Optional) `git -C /Users/zane/agents/orchistration/work/orchestration remote -v` matches the expected bean-repo.

- Confirm process-test / no-op artifacts from the work turn:
  - The bean body (via `beans show <id>` or direct file read in a clone) now contains an appended `## Process Observations` section with notes from the turn.

### After handoff to verify
- Confirm handoff hail from the work turn to the orchistration-verify band (look in the *work session transcript* for the hail-send / handoff action):
  - Evidence of sending to the verify-hail band ("orchistration-verify" or the value from data).
  - The sent params contain at least `:bean-id` (plus any other project data as allowed).
  - Note any thread-id or correlation value for later matching.
  - Confirm a notification was sent to discord#pub announcing the handoff (via comm_send in transcript, and visible in #pub).

- Confirm the orchistration-verify session (perceptor) processed a turn:
  - Transcript shows a turn with crew "perceptor".
  - Evidence of hail-bean-verify skill bootstrap and execution: pull --rebase in the beans repo, `beans list --tag=unverified` or `beans show`, review of acceptance criteria, decision, and state update.
  - The verify transcript's incoming hail context shows `:bean-id` (and other data) present in params.
  - No early failure due to missing handoff fields (verifier proceeded with the bean).
  - In the verify session transcript, confirm `comm_send` was used with notification-comm to announce start of review and/or pass result (message visible in Discord #pub).

- Verify final bean state (via `beans show <id>` from any pulled clone of the orchestration repo + git history on the bean file):
  - `beans show <id>` reports status `completed` with no `unverified` tag.
  - Git commit(s) from the verify phase: at minimum the commit removing the `unverified` tag (and setting status `completed` if performed during this turn). Report hash + message.
  - Confirm the update was executed from the verify role home's clone.

- Confirm the orchestration repo clone under the plan role home (may have been established during initial bean creation by prowl rather than during verify):
  - `ls /Users/zane/agents/orchistration/plan/orchestration`
  - Contains `.git/` (and `.beans/`).

- Double-check no "isaac" references leaked and correct names were used:
  - Grep the relevant recent session transcripts/logs and the final bean file (exclude any pre-existing historical notes) for "isaac" (case-insensitive). None in active context or data.
  - Active session-tags are `:orchestration`; bands referenced are the `orchistration-*` names; data maps reference the correct bean-repo and band names.

### Final overall checks
- The entire flow completed without errors visible in the work and verify session transcripts.
- The bean followed the exact status + tag progression: `todo` → (work) `in-progress` + `unverified` → (verify) `completed` (untagged).
- All clones, turns, state changes, and the handoff are attributable to this specific bean-id (via transcript mentions of the id, data maps, commit messages on the bean file, or thread/correlation ids).
- Chronology is correct: work turn activity precedes the verify turn (observable via transcript ordering, log timestamps, or git commit dates on the bean file).
- Notifications: transcripts show `comm_send` calls using the `notification-comm` (discord #pub) at key points (claim, observations, handoff, review, pass); corresponding messages visible in Discord #pub channel.

Report the results for every checklist item above with concrete evidence (full `beans show` output excerpts, `git log --oneline -S status -- .beans/<id>--*.md` or `git show <hash>`, transcript excerpts with context around the hail data and actions, `ls` listings, etc.). If any step cannot be verified with the available tools/logs/access, explicitly note what is missing and how the check was approximated.

This procedure lets an agent (or human) mechanically walk through the happy path using only observable system artifacts.
