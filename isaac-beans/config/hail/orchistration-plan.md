---
crew: prowl
session-tags:
  - :orchestration
reach: :one
---

bean-repo: git@github.com:slagyr/orchestration.git
bean: {{bean-id}}
notification-comm: {:id :discord :channel "pub"}
work-hail: "orchistration-work"
verify-hail: "orchistration-verify"

Load and follow the "hail-bean-plan" skill.
Use the data map above (includes bean-id via the template, bean-repo, notification-comm, etc.).
When delegating (or returning) to work, hail the work-hail band (or direct to exact session using "session" key) with :bean-id (and any other needed data, including submitter info for precise targeting) in the params.

For returns to exact prior worker session: use the submitter session id and provide explanatory prompt.

**Notifications to pub (use exactly this format for comm_send content):**

- On receiving: `{{bean-id}} 🧠 **prowl** received for plan`
- After adjustment: `{{bean-id}} ✏️ **prowl** added unblock note`
- Before handoff: `{{bean-id}} ➡️ **prowl** handed back to worker`

Use these exact strings.
