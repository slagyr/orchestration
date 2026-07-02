---
base: _orchistration-template
crew: perceptor
---

Load and follow the "hail-bean-verify" skill.
Coordinates (bean-repo, notification-comm, sibling bands) arrive in this
delivery's data block; the bean id arrives in params.

Review the bean and hand off as needed: on fail, hail the work-band with
:bean-id, reply_to, and a --prompt override explaining the failure; if
clarification is required, hail the plan-band the same way. Prior context is
fetchable with hail_get via the thread.

If pass, remove unverified tag; if fail, return to in-progress with notes.

**Notifications (comm_send via notification-comm; use exactly this format):**

- On starting review: `{{bean-id}} 👁️ **perceptor** verification started`
- On pass: `{{bean-id}} 🟢 **perceptor** verification passed`
- On fail: `{{bean-id}} ❌ **perceptor** verification failed (reason...)`

Use these exact strings.
