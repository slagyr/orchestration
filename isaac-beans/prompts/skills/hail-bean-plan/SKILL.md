---
name: hail-bean-plan
description: Bootstrap for planning hails via plan band. Used for orchestration in any project.
---

# Hail-driven plan

Use when hailed via orchistration-plan band (or for conflict resolution / unblock in bean loops).

## Bootstrap

1. Pull in the beans repo root (directory containing `.beans/`).
2. Use `beans list --ready` etc. or `beans show <id>`.
3. Follow `prompts/commands/plan.md` for planning and bean updates.
4. When receiving a bean from work (e.g. conflict), adjust as instructed in the hail / bean body, then hand back.

## Receiving conflict / return hails from worker

- Incoming hail will have :bean-id and details of the issue (conflict note, prior observations) in params.
- The hail may include submitter-session / thread info for returning to the *exact worker session* that has context.
- Pull latest, review the bean.
- Make the adjustment (for test: simply append a note like "## Planner unblock note: bean is unblocked..."; in real use: clarify requirements, edit gherkin, etc.).
- Commit the change in the beans repo.
- Hand back to the exact worker session (see handoff below).

## Handoff back to work (exact session targeting)

- Use the `hail-send` tool with flat snake_case.
- To target the *exact prior worker session*: use "session": the id from submitter-session (or the work session name), plus a full "prompt" explaining the adjustment (no band template for precise return).
- Include bean-id and data in params, thread_id, notification-comm.
- Example:
  {"session": "<exact-worker-session-id-from-submitter>", "params": {"bean-id": "{{bean-id}}", "notification-comm": {...}, "work-hail": "..."}, "prompt": "Planner adjustment complete for bean {{bean-id}}. Added unblock note [or real clarification]. [Summary of change]. Please continue work on the exact same session and hand to verifier when ready."}
- If using the work band for the return, still pass the targeting info.

When hailing the work band normally (not return), pass the bean-id (and other relevant project data) in the params so the target can use {{bean-id}} and the worker skill gets the id.

## Notifications

Send using `comm_send`:

- comm: :id from notification-comm ("discord")
- content: "Adjusted bean <id> and hailing work." (or appropriate)
- discord.target: :channel from notification-comm ("pub")
