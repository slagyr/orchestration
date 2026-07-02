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

Notification formats and the human-help escalation are defined in the skill;
use the notification-comm and human-help-comm coordinates from the data block.
