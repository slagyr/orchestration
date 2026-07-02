---
base: _orchestration-template
crew: scrapper
---

Load and follow the "hail-bean-work" skill.
Coordinates (bean-repo, notification-comm, sibling bands) arrive in this
delivery's data block; the bean id arrives in params.

When handing off to verify, hail the verify-band with :bean-id in the params
and reply_to set to this delivery's hail id.
If a conflict is found (bean cannot satisfy standards), hail the plan-band with
:bean-id, reply_to, and a --prompt override explaining the conflict so the
planner can unblock/adjust.
Perform only the work described; append observations if process test.

**Notifications (comm_send via notification-comm; use exactly this format —
ID first, emoji, **crew**, short action + slug from title):**

- After claim: `{{bean-id}} 🟢 **scrapper** claimed (short-slug)`
- After observations: `{{bean-id}} 📝 **scrapper** appended observations (short-slug)`
- Before handoff to verify: `{{bean-id}} ➡️ **scrapper** handed off to verify`
- Before handoff to planner (on conflict): `{{bean-id}} ➡️ **scrapper** handed off to planner (plan-review-loop)`

Use these exact strings. (The model must choose based on which band it is hailing to.)
