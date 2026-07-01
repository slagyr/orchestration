---
# orchestration-q445
title: plan-review conflict loop (run-2026-07-01-1351)
status: todo
type: task
priority: normal
created_at: 2026-07-01T20:51:56Z
updated_at: 2026-07-01T20:51:56Z
---

This is a fresh process test bean for the plan-review orchestration flow.

Perform only the work described; append observations if process test.

## Plan-review loop instructions (all participants must follow exactly)

Use exact same sessions for returns so context is preserved. For handoffs back to a previous participant, target the exact session using the "session" key in hail-send (the session id is provided via submitter-session in incoming data or your current session context; example value is the "orchistration-work" session that already touched this bean). Do NOT use only band+tags for returns; use direct session frequencies.

When hailing directly to a session (no band template), you must provide a "prompt" that fully explains the situation, includes the bean-id, summarizes prior work/notes on this bean, and tells the recipient what to do next. Also pass bean-id (and other data) in "params".

Always use flat snake_case keys for hail-send (no "frequencies" wrapper). Pass notification-comm for pub updates. Use thread_id for correlation where available. Send comm_send to "pub" at every milestone using the at-a-glance format from the hail-bean-* skills: `{{bean-id}} {{emoji}} **{{crew}}** {{action}} ({{short-slug}})` for quick recognition (ID first, emoji status, bold crew/stage, context slug).

1. Worker (scrapper): Claim the bean (in-progress + unverified tag), append initial ## Process Observations. Hand off to verifier using direct session targeting if possible or the verify band, including submitter-crew, submitter-session (this session), thread_id, bean-id, etc.

2. Verifier (perceptor): On first receipt, note a conflict (the bean requirements cannot satisfy verifier standards). Append a clear ## Verification failed note. Do NOT complete. Hand the bean back to the *exact worker session* that sent it (use submitter-session value from the incoming hail data to set frequencies to that session; include full explanation prompt + bean-id).

3. Same worker session (exact continuity): Receive return from verifier. Determine there is a conflict that the current bean cannot satisfy the standards. Hand off to planner (use the plan band or direct if needed), passing submitter info so return can target this exact session. Include conflict details.

4. Planner (prowl): Receive the hail. Adjust by adding a note to this bean (edit and commit): "## Planner unblock note: bean is unblocked per plan-review test. Worker and verifier may proceed with the loop." Hand back to the *exact worker session* (use the submitter/work session info from incoming; direct session hail with explanatory prompt containing bean-id and the unblock note).

5. Same worker session: Receive from planner. Note the unblock in observations. Re-work/prepare the bean as needed. Hand off to the *exact verifier session* (target precisely using correlation info + explanatory prompt + bean id in params).

6. Verifier: On receipt of the unblocked bean, approve it. Remove unverified tag, set status completed. Append verification pass note.

This is explicitly a process test / no-op for orchestration flow validation.
