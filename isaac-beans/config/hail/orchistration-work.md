---
crew: scrapper
session-tags:
  - :orchestration
reach: :one
---

bean-repo: git@github.com:slagyr/orchestration.git
bean: {{bean-id}}
notification-comm: {:id :discord :channel "pub"}
plan-hail: "orchistration-plan"
verify-hail: "orchistration-verify"

Load and follow the "hail-bean-work" skill.
Use the data map above (includes bean-id via the template, bean-repo, notification-comm, etc.).
When handing off to verify, send a hail to the verify-hail band with :bean-id in the params (along with any other project-specific data from this hail, including submitter-session for exact returns).
If a conflict is found (bean cannot satisfy standards), hand off to the plan-hail band with details so planner can unblock/adjust and return to this exact session.
Perform only the work described; append observations if process test.

For exact-session returns (to preserve context): target the specific session id (from submitter info or your context) using the "session" key + provide a full prompt explaining the handoff + bean-id.

**Notifications to pub (use exactly this format for comm_send content, ID first, emoji, **crew**, short action + slug from title):**

- After claim: `{{bean-id}} 🟢 **scrapper** claimed (short-slug)`
- After observations: `{{bean-id}} 📝 **scrapper** appended observations (short-slug)`
- Before handoff to verify: `{{bean-id}} ➡️ **scrapper** handed off to verify`
- Before handoff to planner (on conflict): `{{bean-id}} ➡️ **scrapper** handed off to planner (plan-review-loop)`

Use these exact strings. (The model must choose based on which band it is hailing to.)
