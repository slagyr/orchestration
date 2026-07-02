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
- Session affinity is **optional**. If the failing commit includes an
  `Isaac-Session:` trailer, the workflow includes that session id in the hail
  params. The band prompt does not mention this; it is orchestration metadata.

## Required GitHub configuration

Per repository:

- `vars.ISAAC_HAIL_URL`
  - Example: `https://zanebot.tail66e5f8.ts.net/hail/send`
- `secrets.ISAAC_SERVER_AUTH_TOKEN`
  - The same bearer token configured on the Isaac server

## Session trailer convention

If a commit came from an Isaac session, add this trailer to the commit message:

```text
Isaac-Session: glimmering-cardinal
```

The notifier extracts that trailer and includes it in the hail payload as
`params.session_id`.

This is optional orchestration metadata. The hail still sends if no trailer is
present.

## Hail payload

The workflow posts JSON like:

```json
{
  "frequencies": { "band": "ci-failure" },
  "params": {
    "repo": "isaac-hail",
    "full_repo": "slagyr/isaac-hail",
    "workflow": "CI Tests",
    "run_url": "https://github.com/slagyr/isaac-hail/actions/runs/123456789",
    "sha": "abc1234",
    "branch": "main",
    "actor": "micahmartin",
    "commit_subject": "Fix hail router",
    "session_id": "glimmering-cardinal"
  }
}
```

`session_id` is omitted when no `Isaac-Session:` trailer is present.

## Layout

- `config/hail/ci-failure.md`
  - single-file hail band with YAML frontmatter + prompt body
- `github/workflows/ci-failure-hail.yml`
  - GitHub Actions notifier template
- `install.sh`
  - deploys the hail band to an Isaac root and copies the workflow into a repo
    checkout
- `REUSE.md`
  - how to adapt this package for another project

## Apply to a repo

1. Run:
   - `./isaac-ci/install.sh --repo /path/to/project`
2. Adjust the watched workflow name if needed:
   - default is `CI Tests`
3. Set:
   - `vars.ISAAC_HAIL_URL`
   - `secrets.ISAAC_SERVER_AUTH_TOKEN`
4. Reload or restart the relevant Isaac sessions on `zanebot`

## Notes

- The notifier intentionally does **not** hail on the first-ever failed run for
  a workflow. It only hails when the immediately previous completed `main` push
  run concluded `success`.
- If you want a different policy later, change the `gate` step in the workflow
  template.
