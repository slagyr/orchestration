---
crew: prowl
session-tags:
  - :orchestration
reach: :one
---

bean-repo: git@github.com:slagyr/orchestration.git
bean: {{bean-id}}
notification-comm: {:id :discord :channel "isaac"}
work-hail: "orchistration-work"
verify-hail: "orchistration-verify"

Load and follow the "hail-bean-plan" skill.
Use the data map above (includes bean-id via the template, bean-repo, notification-comm, etc.).
When delegating to work, hail the work-hail band with :bean-id (and any other needed data) in the params.
