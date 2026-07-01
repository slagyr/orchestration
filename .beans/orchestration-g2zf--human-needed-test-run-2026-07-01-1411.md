---
# orchestration-g2zf
title: human-needed test (run-2026-07-01-1411)
status: todo
type: task
priority: normal
created_at: 2026-07-01T21:11:43Z
updated_at: 2026-07-01T21:11:43Z
---

This is a fresh process test / no-op bean for the human-needed orchestration test.

Follow the sequence exactly:

1. Worker (scrapper): Claim the bean (in-progress + unverified tag), append initial ## Process Observations. Hand off to verifier using direct session targeting if possible or the verify band, including submitter-crew, submitter-session (this session), thread_id, bean-id, etc.

2. Verifier (perceptor): Hand the bean back to the *exact worker session* that sent it (use submitter-session value from the incoming hail data to set frequencies to that session; include full explanation prompt + bean-id).

3. Same worker session (exact continuity): Receive return from verifier. Hand off to planner (use the plan band or direct if needed), passing submitter info so return can target this exact session. Include conflict details.

4. Planner (prowl): You are unable to resolve the issue. Human intervention is required. (The requirements conflict in a way that only human can decide - e.g. priority between feature A and B.)

5. Send discord notification to "pub" using the at-a-glance format: "orchestration-xxx 🆘 **prowl** human help needed (Requirements conflict on feature priority; needs human decision.)"

6. Send additional imessage: comm_send with comm="imessage" content="Human help needed on bean orchestration-xxx: Requirements conflict on feature priority; needs human decision. Check Discord #pub for details." imessage.target="micahmartin@mac.com" imessage.service="iMessage"

Use flat snake_case for hail-send, exact sessions for returns using "session" key, comm_send to "pub" at milestones using at-a-glance format.

This is explicitly a process test / no-op for human-needed flow validation.
