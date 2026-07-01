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
  isaac hail send --band orchistration-work --params '{:bean-id "orchestration-XXXX"}'
  ```

## Then
- Worker → verifier → exact worker → planner.
- Planner cannot resolve, appends human note, commits/pushes (no return to worker).
- Discord receives: `orchestration-XXXX 🆘 **prowl** human help needed (short synopsis)`
- iMessage sent to micahmartin@mac.com with visually stimulating content, e.g.:
  ```
  🆘🚨 HUMAN HELP NEEDED 🚨🆘

  Bean: orchestration-XXXX
  From: **prowl**

  [short synopsis]

  👉 Check Discord #pub for full details.
  ```
- Bean ends in-progress.
- Correct exact-session targeting and at-a-glance comms used throughout.
