# Reusing isaac-ci on Other Projects

`isaac-ci` is a small reusable package for waking Isaac when a GitHub Actions
workflow on `main` regresses from green to red.

It is intentionally narrower than `isaac-beans`:

- one hail band: `ci-failure`
- one workflow template: `ci-failure-hail.yml`
- one installer to deploy the band and copy the workflow into a repo checkout

## What to customize

Usually only these things need adaptation:

1. **Watched workflow name**
   - default: `CI Tests`
   - edit `github/workflows/ci-failure-hail.yml` if the target repo's main CI
     workflow uses a different name

2. **Band routing**
   - edit `config/hail/ci-failure.md`
   - defaults:
     - `session-tags: [:orchestration]`
     - `reach: :one`
     - `prefer: :recent`
     - `create: :if-missing`

3. **Prompt body**
   - update the markdown body in `config/hail/ci-failure.md` if the target
     worker pool should follow a different triage procedure

## Installer inputs

`install.sh` reads `../.env` and expects:

- `HOST=`
- `USER=`
- optional `ISAAC_ROOT=`
- optional `CI_REPO_DIR=`

You can also pass the repo checkout explicitly:

```sh
./isaac-ci/install.sh --repo /path/to/project
```

## What the installer does

1. Copies:
   - `config/hail/ci-failure.md`
   into:
   - `<isaac-root>/config/hail/`

2. Copies:
   - `github/workflows/ci-failure-hail.yml`
   into:
   - `<repo>/.github/workflows/`

It never deletes files on the target.

## Required GitHub settings per repo

- `vars.ISAAC_HAIL_URL`
  - e.g. `https://zanebot.tail66e5f8.ts.net/hail/send`
- `secrets.ISAAC_SERVER_AUTH_TOKEN`

## Optional session affinity

If you want CI failures to prefer the original Isaac session, have orchestration
commits include this trailer:

```text
Isaac-Session: glimmering-cardinal
```

The workflow extracts it from the failing commit and includes:

```json
{"params": {"session_id": "glimmering-cardinal"}}
```

The hail still sends if the trailer is absent. Keep that behavior in workflow or
worker logic, not in the hail band prompt.
