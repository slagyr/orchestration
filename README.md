# orchestration

Test harness and custom Isaac configuration for exercising the orchestration (hail-driven bean) flow.

## Layout

- `isaac-beans/` — the payload that gets installed into an Isaac root. Matches the directory structure expected under `~/.isaac/`:
  - `config/hail/` — band definitions (`orchistration-plan`, `orchistration-work`, `orchistration-verify`)
  - `prompts/commands/` and `prompts/skills/` — the `plan`/`work`/`verify` commands and the `hail-bean-*` skills
  - `install.sh` — the installer (see below)
- `test/shared.md` — common sections used by all tests (Remote Access, Installation, Given, Pre-When checklist skeleton)
- `test/happy-path.md` — the executable happy-path test specification (Given/When/Then + agent verification checklist)
- `test/verify-fail.md` — the verify-fail scenario: first verification fails and returns to the *same* worker session; worker re-tags unverified; second verification passes and completes the bean.
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

See `isaac-beans/test/shared.md` (common setup) + `isaac-beans/test/happy-path.md` (happy path) and `isaac-beans/test/verify-fail.md` (failure + retry on same worker session).

**Important:** Every run of these tests must create a *brand new* bean (with a unique ID and run timestamp in the title). Never reuse old test beans.

All verification commands run against the remote (or local) target using the host/user from `.env`. The checklists tell the agent exactly how to construct the ssh target and what evidence to collect.

## Notes

- The real hostname lives only in the git-ignored `.env`.
- This setup deliberately uses `prompts/` (instead of the legacy `.toolbox/`) at the global Isaac level.
- The three dedicated sessions (orchistration-plan / work / verify) with crews prowl / scrapper / perceptor are assumed to exist with the correct cwds and `:orchestration` tag.
- After file changes, sessions typically need to be restarted or reloaded to pick up updated skills/commands/bands.

## Related

- The hail bands and skills are intentionally project-agnostic so they can be reused for orchestration of any bean-hosting project.
