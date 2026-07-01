---
name: hail-bean-verify
description: Bootstrap and run bean verification from a hail delivery via verify band. Use for orchestration and process-test beans in any project.
---

# Hail-driven bean verify

Use when a hail (or band prompt) assigns bean verification.

## Bootstrap checklist

1. **Find the beans repo** — the directory containing `.beans/`.
2. **`git -C <beans-repo>` pull --rebase** — sync state.
3. **`beans list --tag=unverified`** or `beans show <id>`.
4. **Skills fallback** — read this file and `prompts/commands/verify.md` if `list_skills` fails.
5. Verify the bean per `prompts/commands/verify.md`.
6. If pass: `beans update <id> --remove-tag=unverified`
7. If fail: return to `in-progress`. If the bean body instructs to return to the original worker (e.g. "send back to the same session 'orchistration-work'"), hail to the work-hail band (targeting the submitter-session if available in incoming data or as instructed). On subsequent passes, complete.

## Handoff payload contract (for determinism)

When the worker hails this verify band, expect (and validate) at minimum in the params/payload:

- bean-id
- repo
- summary
- what-done (array)
- commit
- submitter-crew
- submitter-session
- thread_id (for correlation)

Use these to drive the verification without relying on free-text in the prompt. If the payload is missing required fields, fail early or request clarification via plan band. On fail, use submitter-session (or explicit instructions in bean) to target return hails to the original worker session when the bean specifies "same session".

When handing off yourself (to work or plan on fail/clarification), pass submitter info forward.

## Incoming hail data

The incoming hail should have :bean-id (and other project-specific data) in the params.

Use the bean id to look up the bean and review it against the acceptance criteria (including any explicit first-fail / return-to-same-session instructions in the bean body).

For returns to exact prior sessions (no band template), compose a full "prompt" in the hail-send that explains the situation + bean-id + notes, and target using "session": <the submitter-session id>.

Hail back to the plan band (if specified in data) if clarification from planner is needed. On fail per bean instructions, target the work session using direct "session" frequencies (or work-hail + submitter-session) + explanatory prompt.

## Notifications

Send updates using `comm_send` at key points:

- comm: the :id from notification-comm (e.g. "discord")
- content: progress with bean id
- discord.target: the :channel from notification-comm (e.g. "pub")

- On starting review.
- On pass: "Verification passed for bean <id>".
- On fail: the failure reason.

Include the bean-id.
