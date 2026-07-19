# Human-Needed Test for Orchestration

See `shared.md` for Remote Access, Installation, common Given and Pre-When checks.

See `verification-guide.md` for the verification approach, evidence collection patterns, and common checks.

## Given
- Standard orchestration sessions and installed prompts are active.

## When
- Create a brand new bean locally (commit + push first):
  ```sh
  beans create "human-needed test (run-YYYY-MM-DD-HHMM)" \
    --type=task --priority=normal \
    --body 'This is a fresh process test / no-op bean for the human-needed orchestration test.

Follow the sequence exactly:

1. Worker (scrapper): Claim the bean..., hand off to verifier...
2. Verifier: return to exact worker session...
3. Worker: hand off to planner...
4. Planner: You are unable to resolve the issue. Human intervention is required.
5-6. Send discord 🆘 and a visually spiced-up imessage (with emojis + structure) to micahmartin@mac.com.

... (full body as written in the test bean for g2zf)'
  ```

- Hail:
  ```sh
  isaac hail send --band orchestration-work --params '{:bean-id "orchestration-XXXX"}'
  ```

## Then
- Worker → verifier → worker → planner, all via bands with `reply_to`
  chaining (one thread-id for the whole loop; band reach `:one` pins each
  role's session).
- Planner cannot resolve, appends human note, commits/pushes (no return to worker).
- **Escalation is terminal**: after the 🆘 comms, the planner sends NO further
  hail — no work-band handback, no self-continuation, no re-hail. The bean is
  left held, not re-queued.
- **Held marker**: the planner appends a `## Held (awaiting human, <date>)` note
  to the bean body (naming the blocker and that it resumes only on explicit human
  action) and commits/pushes it, so the escalated bean is legibly distinct from a
  bean under active work.
- Human escalation uses the **coordinates from the band data block**
  (`notification-comm` for the at-a-glance channel, `human-help-comm` for
  the direct human contact) per the hail-bean-plan skill — nothing hardcoded.
- Discord receives: `orchestration-XXXX 🆘 **prowl** human help needed (short synopsis)`
- iMessage sent to the human-help-comm target with visually stimulating content, e.g.:
  ```
  🆘🚨 HUMAN HELP NEEDED 🚨🆘

  Bean: orchestration-XXXX
  From: **prowl**

  [short synopsis]

  👉 Check the notification channel for full details.
  ```
- Bean ends in-progress **and held** (the `## Held` note present); nothing
  auto-resumes it.
- `:bean-id` is the only param on every hail; at-a-glance comms at each
  milestone, crew signed from ambient identity.
