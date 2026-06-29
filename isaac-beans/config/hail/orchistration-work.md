---
crew: scrapper
session-tags:
  - :isaac
reach: :one
---

bean-repo: git@github.com:slagyr/orchestration.git
bean: {{bean-id}}
notification-comm: {:id :discord :channel "isaac"}
plan-hail: "orchistration-plan"
verify-hail: "orchistration-verify"

Load and follow the "hail-bean-work" skill.
Use the data map above (includes bean-id via the template, bean-repo, notification-comm, etc.).
When handing off to verify, send a hail to the verify-hail band with :bean-id in the params (along with any other project-specific data from this hail).
Perform only the work described; append observations if process test.
