# isaac-ci

Reusable CI-to-Isaac hail wiring for GitHub Actions.

This package is meant to be copied into an Isaac-hosting project when you want
CI failures on `main` to hail `zanebot` and wake the worker pool.

## Design

- CI hails only on a **green -> red** transition.
- Repeated red runs do **not** send repeated hails.
- Only `push` runs on `main` are considered.
- The hail is sent to the existing authenticated Isaac HTTP endpoint:
  `POST /hail/send`
- The notifier uses a hail band (`ci-failure`) so the CI side stays simple.
- **No prompt override** — params only; the band body template is the single
  source of instruction text.
- Session affinity: when the failing commit includes an `Isaac-Session:` trailer,
  the workflow sets `frequencies.session` so the hail is directed at that session
  (explicit session trumps band selectors). Without a trailer, the `:ci`-tagged
  band routes to a fallback session.
- Bean correlation: when the commit includes `Isaac-Bean:`, the workflow passes
  `bean_id` in params for thread/owner correlation.

## Required GitHub configuration

Per repository:

- `secrets.ISAAC_HAIL_URL`
- `secrets.ISAAC_SERVER_AUTH_TOKEN`
  - The same bearer token configured on the Isaac server

## Commit trailer convention

Implementation commits from Isaac sessions should carry:

```text
Isaac-Session: glimmering-cardinal
Isaac-Bean: isaac-abcd
```

`Isaac-Session` is required for direct session routing. `Isaac-Bean` is
recommended while bean work is in flight. The hail still sends when trailers are
absent (band `:ci` tag routing applies).

## Hail payload

The workflow posts JSON like:

```json
{
  "frequencies": {
    "band": "ci-failure",
    "session": ["glimmering-cardinal"]
  },
  "params": {
    "repo": "isaac-hail",
    "full_repo": "slagyr/isaac-hail",
    "workflow": "CI Tests",
    "run_id": "123456789",
    "run_url": "https://github.com/slagyr/isaac-hail/actions/runs/123456789",
    "sha": "abc1234",
    "branch": "main",
    "actor": "micahmartin",
    "commit_subject": "Fix hail router",
    "failing_jobs": "CI Tests",
    "failing_steps": "CI Tests: bb spec",
    "bean_id": "isaac-abcd"
  }
}
```

`frequencies.session` is omitted when no `Isaac-Session:` trailer is present.
`bean_id` is omitted when no `Isaac-Bean:` trailer is present. Failed job and
step names come from the GitHub Actions jobs API for the failing run.

## Layout

- `config/hail/ci-failure.md`
  - single-file hail band with YAML frontmatter + prompt body
- `github/workflows/ci-failure-hail.yml`
  - tiny GitHub Actions wrapper template
- `../.github/workflows/ci-failure-hail-reusable.yml`
  - reusable notifier implementation in the `orchestration` repo
- `install.sh`
  - deploys the hail band to an Isaac root and copies the workflow into a repo
    checkout
- `configure-github.sh`
  - sets the required GitHub Actions repo secrets from `../.env`
- `REUSE.md`
  - how to adapt this package for another project

## Apply to a repo

1. Run:
   - `./isaac-ci/install.sh --repo /path/to/project`
2. Adjust the watched workflow name if needed:
   - default is `CI Tests`
3. Configure GitHub:
   - `./isaac-ci/configure-github.sh slagyr/<repo>`
4. Reload or restart the relevant Isaac sessions on `zanebot`
5. Tag intended CI-repair fallback sessions with `:ci` on zanebot

The installed workflow is intentionally small. It delegates the real notifier
logic to the reusable workflow in `slagyr/orchestration`, so later fixes land in
one place.

## Notes

- The notifier intentionally does **not** hail on the first-ever failed run for
  a workflow. It only hails when the immediately previous completed `main` push
  run concluded `success`.
- If you want a different policy later, change the `gate` step in the workflow
  template.