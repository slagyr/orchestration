---
name: hail-bean-plan
description: Bootstrap for planning hails via plan band. Used for orchestration in any project.
---

# Hail-driven plan

Use when hailed via orchestration-plan band (or for conflict resolution / unblock in bean loops).

## Bootstrap

1. Pull in the beans repo root (directory containing `.beans/`).
2. Use `beans list --ready` etc. or `beans show <id>`.
3. Follow `prompts/commands/plan.md` for planning and bean updates.
4. When receiving a bean from work (e.g. conflict), adjust as instructed in the hail / bean body, then hand back.

## Receiving conflict / return hails from worker or verifier

- Incoming hail has :bean-id in params; the situation arrives in the prompt
  override. Coordinates (bean-repo, notification-comm, work-band, ...) are in
  the delivery's data block. Earlier legs of the exchange are fetchable with
  `hail_get` via the thread.
- Pull latest, review the bean.
- Make the adjustment (for test: simply append a note like "## Planner unblock note: bean is unblocked..."; in real use: clarify requirements, edit gherkin, etc.).
- Commit the change in the beans repo.
- Hand back via the work-band (see below).

## Handoff back to work

- Use the `hail-send` tool with flat snake_case.
- Hail the **work-band** (name from your data block) with a prompt override
  explaining the adjustment, and reply_to for thread continuity:
  {"band": "<work-band value>", "params": {"bean-id": "{{bean-id}}"}, "reply_to": "<incoming hail id>", "prompt": "Planner adjustment complete for bean {{bean-id}}. Added unblock note [or real clarification]. [Summary of change]. Please continue work and hand to verifier when ready."}

When hailing the work-band normally (not a return), :bean-id in params is all
that's needed — the band body provides the instructions and the data block the
coordinates.

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

The escalation coordinates come from the band data block: **notification-comm**
(at-a-glance channel) and **human-help-comm** (direct human contact). Never
hardcode channels or addresses — read them from the incoming band data.

- Send comm_send to the notification-comm coordinates with content in at-a-glance format: `{{bean-id}} 🆘 **{{crew}}** human help needed (short synopsis)`

- Additionally send to the human-help-comm coordinates (comm = its :id, target/service from its keys): content like "🆘🚨 HUMAN HELP NEEDED 🚨🆘\n\nBean: {{bean-id}}\nFrom: **{{crew}}**\n\n[short synopsis]\n\n👉 Check the notification-comm channel for full details."

- Use the synopsis from the hail instructions or bean body. Make the message visually clear with emojis, newlines, and structure.
