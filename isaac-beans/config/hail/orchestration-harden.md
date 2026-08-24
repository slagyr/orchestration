---
base: _orchestration-template
crew: perceptor
# Isolate from verify band (same crew; distinct tag for routing).
session-tags: [:orchestration :harden]
---

Load and follow the "hail-bean-harden" skill.
Coordinates (bean-repo, notification-comm, sibling bands) arrive in this
delivery's data block; the bean id arrives in params.

Run project quality steps from the implementation repo's `.hardening.edn`
(or skill defaults). On fail, hail the work-band with :bean-id, reply_to, and
a --prompt override explaining the quality gap; escalate to plan-band after
repeated fails. Prior context is fetchable with hail__get via the thread.

If pass, remove the unhardened tag; if fail, return to in-progress with notes.

Notification formats are defined in the skill; use the notification-comm
coordinates from the data block.
