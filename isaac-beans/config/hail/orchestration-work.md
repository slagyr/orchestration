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

Notification formats are defined in the skill; use the notification-comm
coordinates from the data block.

**Re-read the skill file at the start of EVERY turn** (`skill__load` / read `~/.isaac/prompts/skills/<skill>/SKILL.md`) — skills change between turns and the copy in your transcript may be stale. Since 2026-09-03 the verify skill lands a passing bean on main and records `main-sha:` BEFORE marking it completed (step 7a); the work skill rebases onto origin/main before handoff.
