---
session-tags:
  - :ci
reach: :one
create: :never
---

GitHub Actions reported a CI regression on the default branch.

Repository: {{full_repo}}
Workflow: {{workflow}}
Branch: {{branch}}
Commit: {{sha}}
Actor: {{actor}}
Summary: {{commit_subject}}
Run: {{run_url}}
Run ID: {{run_id}}
Failing jobs: {{failing_jobs}}
Failing steps: {{failing_steps}}
Bean: {{bean_id}}

**Correlation:** When `bean_id` is present, or an in-progress bean scopes this
repository, check that bean's state first. Reply into its thread or notify its
owner — do NOT commission an independent repair.

Investigate the failing workflow using the job/step detail above (open the run
URL only if you need more). Reproduce locally, fix it, run the relevant
verification, and push the repair.