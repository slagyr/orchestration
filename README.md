# orchestration

Test harness and custom Isaac configuration for exercising the orchestration (hail-driven bean) flow.

## Layout

- `isaac-beans/` — the payload that gets installed into an Isaac root. Matches the directory structure expected under `~/.isaac/`:
  - `config/hail/` — band definitions (`orchistration-plan`, `orchistration-work`, `orchistration-verify`)
  - `config/discord-channels.example.edn` — reference for the `:discord/channels` map (name ↔ snowflake) required for `comm_send` with channel *names* like "pub"
  - `prompts/commands/` and `prompts/skills/` — the `plan`/`work`/`verify` commands and the `hail-bean-*` skills
  - `install.sh` — the installer (see below)
- `test/shared.md` — common setup (Remote Access, Installation, Given, Pre-When)
- `test/verification-guide.md` — verification procedure, evidence patterns, terminology, and detailed checks
- `test/happy-path.md`, `verify-fail.md`, `plan-review.md`, `human-needed.md` — the executable test specifications (slim Given/When/Then)
- `.beans.yml` — bean tracker config for this project itself (prefix `orchestration-`)

## Quick start (install on target)

```sh
cp .env.example .env
# edit .env with the real host + user (never commit .env)
cd orchestration
./isaac-beans/install.sh
```

The installer:
- Lives inside `isaac-beans/` so the payload is self-contained.
- Reads the same `.env` (in the checkout root) used by the verification steps.
- Uses rsync (over ssh when remote) to copy the `config/` and `prompts/` trees (overwrites existing files but does not delete anything on the target).
- Supports `--dry-run`.
- Has a local mode when the host looks like localhost.

After installing, reload the Isaac sessions/crews that use the `orchistration-*` bands so the new prompts and hail configuration are active.

## Running the tests

See:
- `isaac-beans/test/shared.md` — setup
- `isaac-beans/test/verification-guide.md` — how to verify (evidence, patterns)
- The individual test files (`happy-path.md`, `verify-fail.md`, `plan-review.md`, `human-needed.md`) for the slim Given/When/Then scenarios.

**Important:** Every run must use a *brand new* bean (unique ID + timestamp in title).

All verification uses the remote (or local) target from `.env`. Detailed evidence collection lives in the verification guide.

## Notes

- The real hostname lives only in the git-ignored `.env`.
- This setup deliberately uses `prompts/` (instead of the legacy `.toolbox/`) at the global Isaac level.
- The three dedicated sessions (orchistration-plan / work / verify) with crews prowl / scrapper / perceptor are assumed to exist with the correct cwds and `:orchestration` tag.
- After file changes, sessions typically need to be restarted or reloaded to pick up updated skills/commands/bands.

## Discord channel configuration (for comm_send name resolution)

The `orchistration-*` hail bands use `notification-comm: {:id :discord :channel "pub"}`.

The `comm_send` tool (with `discord.target: "pub"`) relies on name→snowflake reverse lookup in isaac-discord. This only works when the channel is declared with a `:name` in the runtime config:

```edn
:comms {:discord {:discord/channels {"SNOWFLAKE_FOR_PUB"   {:name "pub"}
                                      "1491164414794272848" {:name "tempest" :crew "tempest" :session "discord-tempest"}
                                      "1520092609312194772" {:name "isaac"   :crew "marvin"  :session "discord-isaac"}}}}
```

- "pub" is required for the notification checks in the tests.
- Current known (fetched from remote): tempest + isaac.
- "pub" must be added with its real snowflake (right-click channel in Discord with dev mode on → Copy ID).
- The installer (`install.sh`) does **not** touch this; it is maintained in `~/.isaac/config/isaac.edn` on the target (hot-reload may apply some changes).

See also `test/shared.md` for verification steps.

## Related

- The hail bands and skills are intentionally project-agnostic so they can be reused for orchestration of any bean-hosting project.
