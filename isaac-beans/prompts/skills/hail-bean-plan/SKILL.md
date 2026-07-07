---
name: hail-bean-plan
description: Bootstrap for planning hails via plan band. Used for orchestration in any project.
---

# Hail-driven plan

Use when hailed via orchestration-plan band (or for conflict resolution / unblock in bean loops).

## Role boundary (critical)

**You PLAN beans. You do NOT work them.** Never implement code, edit source,
run tests, or verify an implementation — those belong to the work band and the
verify band. Your only actions on a bean are: adjust its body (scope,
acceptance criteria, gherkin), split/merge beans, unblock or clarify, or
escalate to a human. When work is needed, hand it to the work band with a hail;
never do the work yourself.

**You do NOT promote beans to `todo`.** Beans reach `todo` only through **human
review and approval**. If planning surfaces new work, create it as `draft`
(sparingly) or note it in the current bean, and flag it for human review —
never `todo`, never self-promote, and never leave a bean you created sitting in
`in-progress`. Splitting an existing bean is fine, but the split-off bean
inherits the same rule: draft (or the parent's status), not a fresh `todo`.

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
- Make the adjustment (for test: simply append a note like "## Planner unblock note: bean is unblocked..."; in real use: clarify requirements, edit gherkin, etc.). The `## Planner` note is also the **reset marker for the verify-fail escalation counter** (see hail-bean-verify): once you add it, the verifier's fail count starts fresh, so the normal work→verify loop resumes. If a bean was escalated to you because it kept failing verification, your adjustment should change something real (rescope acceptance, split the bean, unblock, or fix the gherkin) — not just append an empty note — or it will simply bounce back.
- Commit the change in the beans repo, including an `Isaac-Session: <session-id>`
  trailer. Recommended form:

  ```sh
  git commit --trailer "Isaac-Session: <session-id>"
  ```

  The current session id comes from your session identity block.
- Hand back via the work-band (see below).

## Never end a turn in limbo

Every planning turn must end in exactly one of these states: adjustment made
and **handed back** (work-band hail sent), **escalated to human** (comms
sent), or a **continuation hail to your own band** (`reply_to` this delivery)
when the decision needs more work. A turn that ends with only analysis — no
note, no hail, no notification — strands the bean silently: the requester
waits forever for a verdict that never comes. If you are running long, send
the continuation hail EARLY; "I'll think more" with no hail is a dead end on
an unattended turn.

## Handoff back to work

- Use the `hail-send` tool with flat snake_case.
- **Copy the band value EXACTLY from your delivery's data block — never type it
  from memory.** A typo'd band name routes nowhere and dead-letters silently.
- **Band handoffs carry the `band` key and `params` ONLY** — never add
  `session-tags`, `crew`, or other frequency filters: extra filters can select
  ZERO recipients and the hail parks SILENTLY as undeliverable (isaac-exi2
  lost 11 hours to an invented session-tag).
- Hail the **work-band** (name from your data block) with a prompt override
  explaining the adjustment, and reply_to for thread continuity. Use only the
  band key (see targeting rules in hail-bean-verify/SKILL.md; never use band name
  as :session):
  {"band": "<work-band value>", "params": {"bean-id": "{{bean-id}}"}, "reply_to": "<incoming hail id>", "prompt": "Planner adjustment complete for bean {{bean-id}}. Added unblock note [or real clarification]. [Summary of change]. Please continue work and hand to verifier when ready."}

When hailing the work-band normally (not a return), :bean-id in params is all
that's needed — the band body provides the instructions and the data block the
coordinates.

## Notifications

Send using `comm_send` at key points (receive/adjust/handback). Coordinates
come from the delivery's data block: comm = notification-comm's :id, target =
its :channel.

Fill `<crew>` and `<session>` from **your own identity** (both are in your
system prompt's session identity block). Use exactly these formats for content:

- On receiving: `<bean-id> 🧠 **<crew>**@<session> received for plan`
- After adjustment: `<bean-id> ✏️ **<crew>**@<session> added unblock note`
- After the work-band return hail is SENT: `<bean-id> ➡️ **<crew>**@<session> handed back to worker`

ID first for recognition; 🧠/📋 for planner actions, 🟢 for positive adjustments.

## If unable to resolve - notify human

The escalation coordinates come from the band data block: **notification-comm**
(at-a-glance channel) and **human-help-comm** (direct human contact). Never
hardcode channels or addresses — read them from the incoming band data.

- Send comm_send to the notification-comm coordinates with content in at-a-glance format: `{{bean-id}} 🆘 **{{crew}}** human help needed (short synopsis)`

- Additionally send to the human-help-comm coordinates (comm = its :id, target/service from its keys): content like "🆘🚨 HUMAN HELP NEEDED 🚨🆘\n\nBean: {{bean-id}}\nFrom: **{{crew}}**\n\n[short synopsis]\n\n👉 Check the notification-comm channel for full details."

- Use the synopsis from the hail instructions or bean body. Make the message visually clear with emojis, newlines, and structure.
