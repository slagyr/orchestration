# orchestration

Test harness and custom Isaac configuration for exercising the orchestration (hail-driven bean) flow.

## Layout

- `isaac-beans/` — the payload that gets installed into an Isaac root. Matches the directory structure expected under `~/.isaac/`:
  - `config/hail/` — band definitions (`orchestration-plan`, `orchestration-work`, `orchestration-verify`, optional `orchestration-harden`)
  - `config/discord-channels.example.edn` — reference for the `:discord/channels` map (name ↔ snowflake) required for `comm_send` with channel *names* like "pub"
  - `prompts/skills/` — hail-bean-{plan,work,verify,harden} skills (commands live in agent-lib)
  - `install.sh` — the installer (see below)
- `isaac-ci/` — reusable GitHub Actions + hail-band package for sending CI failure hails to Isaac on green -> red transitions, with its own installer and reuse notes
- `test/shared.md` — common setup (Remote Access, Installation, Given, Pre-When)
- `test/verification-guide.md` — verification procedure, evidence patterns, terminology, and detailed checks
- `test/happy-path.md`, `harden-path.md`, `verify-fail.md`, `plan-review.md`, `human-needed.md` — the executable test specifications (slim Given/When/Then). These are **manual process checks** against a live Isaac target (SSH + transcripts + beans), not automated unit tests of hail.
- `.beans.yml` — bean tracker config for this project itself (prefix `orchestration-`)

## Quick start (install on target)

```sh
cp .env.example .env
# edit .env with the real HOST= and USER= values (never commit .env)
cd orchestration
./isaac-beans/install.sh
```

The installer:
- Lives inside `isaac-beans/` so the payload is self-contained.
- Reads the same `.env` (in the checkout root) used by the verification steps.
- Uses rsync (over ssh when remote) to copy the `config/` and `prompts/` trees (overwrites existing files but does not delete anything on the target).
- Supports `--dry-run`.
- Has a local mode when the host looks like localhost.

After installing, reload the Isaac sessions/crews that use the `orchestration-*` bands so the new prompts and hail configuration are active.

## Running the tests

See:
- `isaac-beans/test/shared.md` — setup
- `isaac-beans/test/verification-guide.md` — how to verify (evidence, patterns)
- The individual test files (`happy-path.md`, `verify-fail.md`, `plan-review.md`, `human-needed.md`) for the slim Given/When/Then scenarios.

**Important:** Every run must use a *brand new* bean (unique ID + timestamp in title).

All verification uses the remote (or local) target from `.env`. Detailed evidence collection lives in the verification guide.

## Notes

- The real hostname and tokens live only in the git-ignored `.env`.
- This setup deliberately uses `prompts/` (instead of the legacy `.toolbox/`) at the global Isaac level.
- Dedicated sessions (orchestration-plan / work / verify / harden) with crews prowl / scrapper / perceptor are assumed to exist with the correct cwds and tags (`:orchestration`, plus `:verify` / `:harden` for routing isolation).
- Pipeline is data-driven: omit `harden-band` from template data for work→verify only; include it (stock template) for work→verify→harden.
- After file changes, sessions typically need to be restarted or reloaded to pick up updated skills/commands/bands.

## Discord channel configuration (for comm_send name resolution)

The `orchestration-*` hail bands use `notification-comm: {:id :discord :channel "pub"}`.

The `comm_send` tool (with `discord.target: "pub"`) relies on name→snowflake reverse lookup in isaac-discord. This only works when the channel is declared with a `:name` in the runtime config:

```edn
:comms {:discord {:discord/channels {"SNOWFLAKE_FOR_PUB"   {:name "pub"}
                                      "EXAMPLE_SNOWFLAKE_A" {:name "tempest" :crew "tempest" :session "discord-tempest"}
                                      "EXAMPLE_SNOWFLAKE_B" {:name "isaac"   :crew "marvin"  :session "discord-isaac"}}}}
```

- "pub" is required for the notification checks in the tests.
- Current known (fetched from remote): tempest + isaac.
- "pub" must be added with its real snowflake (right-click channel in Discord with dev mode on → Copy ID).
- The installer (`install.sh`) does **not** touch this; it is maintained in `~/.isaac/config/isaac.edn` on the target (hot-reload may apply some changes).

See also `test/shared.md` for verification steps.

## Related

- The hail bands and skills are intentionally project-agnostic so they can be reused for orchestration of any bean-hosting project.
  See `isaac-beans/REUSE.md` for the full setup instructions and requirements when applying this to a new project.
