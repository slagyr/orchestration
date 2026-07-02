---
base: _orchestration-template
crew: prowl
---

Load and follow the "hail-bean-plan" skill.
Coordinates (bean-repo, notification-comm, human-help-comm, sibling bands) arrive
in this delivery's data block; the bean id arrives in params.

When delegating (or returning) to work, hail the work-band with :bean-id in the
params. Supply a --prompt override when the worker needs an explanation (the
data still arrives); pass reply_to with the incoming hail id so the thread
correlates.

**Notifications (comm_send via notification-comm; use exactly this format):**

- On receiving: `{{bean-id}} 🧠 **prowl** received for plan`
- After adjustment: `{{bean-id}} ✏️ **prowl** added unblock note`
- Before handoff: `{{bean-id}} ➡️ **prowl** handed back to worker`

Use these exact strings.

If unable to resolve the issue, follow the human-help escalation in the
"hail-bean-plan" skill, using the notification-comm and human-help-comm
coordinates from the data block.
