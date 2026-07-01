## Remote Access

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
     - `isaac-beans/config/` → `~/.isaac/config/`   (includes hail bands + `discord-channels.example.edn` reference)
     - `isaac-beans/prompts/` → `~/.isaac/prompts/`

3. After install, restart/reload the relevant sessions or daemons on the target so new skills, commands, and hail bands are loaded.

See `isaac-beans/install.sh` for details and the exact remote commands.

## Given

- All of the config files and prompts have been installed in the Isaac root.
- The directory /Users/zane/agents/orchistration/plan exists.
- The directory /Users/zane/agents/orchistration/work exists.
- The directory /Users/zane/agents/orchistration/verify exists.
- An orchistration-plan session exists with crew prowl and cwd /Users/zane/agents/orchistration/plan.
- An orchistration-work session exists with crew scrapper and cwd /Users/zane/agents/orchistration/work.
- An orchistration-verify session exists with crew perceptor and cwd /Users/zane/agents/orchistration/verify.

## Verification Procedure Intro (common)

**First** establish remote access using the instructions in the "Remote Access" section above (read `.env`, construct `$TARGET`). All commands below (`ls`, `beans`, `git`, transcript inspection, etc.) are executed on the remote target via `ssh "$TARGET" '...' ` (or equivalent).

It is **not** a test framework script (no Cucumber). It is a manual verification procedure the agent should follow using `beans`, `git`, session transcripts/logs, `ls`, and hail data as rendered inside transcripts.

Run the checks roughly in this order and report **pass/fail + specific evidence** (e.g. commit hash + message, `beans show` output, transcript excerpt with surrounding context, `ls` output) for each.

**Critical for repeated runs of any test:** Always create a *brand new* bean with a unique ID for this execution of the test. Do not reuse old bean IDs (e.g. orchestration-lrlu) or inspect prior test data. Include a run timestamp or unique suffix in the bean title. Verify freshness in the Pre-When checks below.

Terminology note (for all checks):
- Role homes / sessions / bands: `orchistration-*` and `/Users/zane/agents/orchistration/{plan,work,verify}`.
- Project / repo / clone leaf dir / .beans prefix: `orchestration` (bean-repo in bands is `git@github.com:slagyr/orchestration.git`).
- Session tag used: `:orchestration`.

### Pre-When checks (confirm setup before the hail to work)

- Confirm the three role home directories exist on the target machine:
  - `ls /Users/zane/agents/orchistration/plan`
  - `ls /Users/zane/agents/orchistration/work`
  - `ls /Users/zane/agents/orchistration/verify`

- Confirm the three sessions exist with correct crew and cwd (via session listing tools, transcript listings, or inspecting the relevant Isaac session metadata):
  - orchistration-plan → crew=prowl, cwd=/Users/zane/agents/orchistration/plan
  - orchistration-work → crew=scrapper, cwd=/Users/zane/agents/orchistration/work
  - orchistration-verify → crew=perceptor, cwd=/Users/zane/agents/orchistration/verify

- (Required) Confirm session tags and naming isolation:
  - Sessions carry the `:orchestration` tag (from band frontmatter).
  - Bands in use are `orchistration-plan` / `orchistration-work` / `orchistration-verify` (not any `isaac-*`).
  - Grep session metadata or early transcript lines for confirmation.

- Confirm a *brand new* bean was created specifically for *this run of the test* (do not reuse any previous bean ID such as orchestration-lrlu, orchestration-43d1, etc. — check `beans list` or git before creation to ensure the ID is fresh):
  - In the plan clone, explicitly run `beans create` with a unique title (e.g. including "run-YYYY-MM-DD-HHMM" or a one-time ID). Record the new ID.
  - `beans show <fresh-bean-id>` (after creation) shows status `todo` and the title/body contains the run-specific description.
  - `git log --oneline -- .beans/<fresh-bean-id>--*.md` (or `git log --oneline -S <id> -- .beans/`) shows a fresh creation commit with *no prior history* for this ID.
  - `ls /Users/zane/agents/orchistration/plan/orchestration` contains at least `.git/`, `.beans.yml`, and `.beans/`.

- Confirm the orchestration-specific prompts/config are the ones active for these sessions (evidence will appear in transcripts; optionally inspect the Isaac root used by the crews):
  - `prompts/skills/hail-bean-*/SKILL.md` and `config/hail/orchistration-*.md` (the versions from the isaac-beans deployment) are the ones referenced/loaded.

- **Discord comm channels for name-based notifications** (required so `comm_send` with `notification-comm` "pub" succeeds via reverse lookup to snowflake):
  - `ssh "$TARGET" 'grep -A 30 ":discord/channels" ~/.isaac/config/isaac.edn'`
  - Must include an entry for "pub" (e.g. `"SNOWFLAKE" {:name "pub" ...}`) plus the known ones:
    - "1491164414794272848" name "tempest"
    - "1520092609312194772" name "isaac"
  - If "pub" is absent, name resolution will fail with snowflake coercion errors even though the code supports names. Add it to `~/.isaac/config/isaac.edn` on the target (then reload relevant sessions).