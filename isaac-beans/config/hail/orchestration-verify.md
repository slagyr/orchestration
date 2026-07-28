---
base: _orchestration-template
crew: perceptor
# Isolate from harden band (same crew; distinct tag for routing).
session-tags: [:orchestration :verify]
---

Load and follow the "hail-bean-verify" skill.
Coordinates (bean-repo, notification-comm, sibling bands) arrive in this
delivery's data block; the bean id arrives in params.

Review the bean and hand off as needed: on fail, hail the work-band with
:bean-id, reply_to, and a --prompt override explaining the failure; if
clarification is required, hail the plan-band the same way. Prior context is
fetchable with hail_get via the thread.

If pass, remove unverified tag and set completed. If the delivery data includes
harden-band, also tag unhardened and hail that band; otherwise the pipeline
ends at verify. If fail, return to in-progress with notes.

Notification formats are defined in the skill; use the notification-comm
coordinates from the data block.
