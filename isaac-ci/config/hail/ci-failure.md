---
session-tags:
  - :orchestration
reach: :one
prefer: :recent
create: :if-missing
---

GitHub Actions reported a CI regression on the default branch.

Repository: {{full_repo}}
Workflow: {{workflow}}
Branch: {{branch}}
Commit: {{sha}}
Actor: {{actor}}
Summary: {{commit_subject}}
Run: {{run_url}}

Investigate the failing workflow, reproduce the failure locally, fix it, run the
relevant verification, and push the repair.

The hail metadata preamble may include an optional `session_id`. If present and
that session still exists, prefer resuming it for context.
