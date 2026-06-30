---
crew: perceptor
session-tags:
  - :orchestration
reach: :one
---

bean-repo: git@github.com:slagyr/orchestration.git
bean: {{bean-id}}
notification-comm: {:id :discord :channel "isaac"}
plan-hail: "orchistration-plan"
work-hail: "orchistration-work"

Load and follow the "hail-bean-verify" skill.
Use the data map above (includes bean-id via the template, bean-repo, notification-comm, etc.).
The incoming hail should have :bean-id in params. Review the bean and hand off as needed (e.g. back to plan if clarification required).
If pass, remove unverified tag; if fail, return to in-progress with notes.
