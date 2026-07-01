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

Send using `comm_send` at key points (claim/adjust/handoff):

- comm: :id from notification-comm ("discord")
- content: use the "at-a-glance" format
- discord.target: :channel from notification-comm ("pub")

**Recommended format** (ID first for recognition, emoji, bold crew, action + slug):

```
{{bean-id}} {{emoji}} **{{crew}}** {{action}} ({{short-slug}})
```

Examples:
- `orchestration-25e4` 🧠 **prowl** received conflict
- `orchestration-25e4` ✏️ **prowl** added unblock note
- `orchestration-25e4` ➡️ **prowl** handed back to worker

Use 🧠/📋 for planner actions, 🟢 for positive adjustments.

## If unable to resolve - notify human

- Send comm_send to the notification-comm (discord "pub") with content in at-a-glance format: `{{bean-id}} 🆘 **prowl** human help needed (short synopsis)`

- Additionally send imessage: comm_send with comm="imessage" content="Human help needed on bean {{bean-id}}: [short synopsis]. Check Discord #pub." imessage.target="micahmartin@mac.com" imessage.service="iMessage"

- Use the synopsis from the hail instructions or bean body.
