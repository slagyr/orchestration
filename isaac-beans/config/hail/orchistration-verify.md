---
crew: perceptor
session-tags:
  - :orchestration
reach: :one
---

bean-repo: git@github.com:slagyr/orchestration.git
bean: {{bean-id}}
notification-comm: {:id :discord :channel "pub"}
plan-hail: "orchistration-plan"
work-hail: "orchistration-work"

Load and follow the "hail-bean-verify" skill.
Use the data map above (includes bean-id via the template, bean-repo, notification-comm, etc.).
The incoming hail should have :bean-id in params. Review the bean and hand off as needed (e.g. back to plan if clarification required; or back to the same worker session using the submitter-session for exact targeting if the bean explicitly instructs first-fail + return-to-same-session).

For exact returns to a prior session: use direct "session" key in hail-send (from submitter info) and supply a "prompt" with explanation + bean-id (no template).

If pass, remove unverified tag; if fail, return to in-progress with notes. Pass submitter info forward on your handoffs.
