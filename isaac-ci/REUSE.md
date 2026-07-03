# Reusing isaac-ci on Other Projects

`isaac-ci` is a small reusable package for waking Isaac when a GitHub Actions
workflow on `main` regresses from green to red.

It is intentionally narrower than `isaac-beans`:

- one hail band: `ci-failure`
- one wrapper workflow template: `ci-failure-hail.yml`
- one central reusable workflow in `slagyr/orchestration`
- one installer to deploy the band and copy the workflow into a repo checkout
- one GitHub setup script to install the repo variable/secret

## What to customize

Usually only these things need adaptation:

1. **Watched workflow name**
   - default: `CI Tests`
   - edit `github/workflows/ci-failure-hail.yml` if the target repo's main CI
     workflow uses a different name

   The installed wrapper delegates to:
   - `slagyr/orchestration/.github/workflows/ci-failure-hail-reusable.yml@main`

   If you want stricter pinning, change that ref to a tag or commit SHA.

2. **Band routing**
   - edit `config/hail/ci-failure.md`
   - defaults:
     - `session-tags: [:ci]`
     - `reach: :one`
     - `create: :never`
   - tag intended CI-repair fallback sessions with `:ci` on the Isaac host

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

To configure GitHub Actions settings for a repo:

```sh
./isaac-ci/configure-github.sh slagyr/your-repo
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

`configure-github.sh` sets these for you:

- `secrets.ISAAC_HAIL_URL`
- `secrets.ISAAC_SERVER_AUTH_TOKEN`

## Commit trailers (session + bean correlation)

Implementation commits should carry:

```text
Isaac-Session: glimmering-cardinal
Isaac-Bean: isaac-abcd
```

The workflow extracts trailers from the failing commit:

- `Isaac-Session` → `frequencies.session` (direct delivery to that session)
- `Isaac-Bean` → `params.bean_id` (correlate repair with active bean work)

The hail still sends when trailers are absent; the `:ci`-scoped band routes to
tagged fallback sessions (undeliverable if none exist).
