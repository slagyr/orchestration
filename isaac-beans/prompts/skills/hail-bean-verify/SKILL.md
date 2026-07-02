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
4. **Find the implementation repo** — bean scope / title / body names the repo
   (a module sibling or the beans repo itself). Locate the work commits there:
   `git log --grep=<bean-id>` in the sibling checkout (pull first; clone on
   demand if missing). Do NOT assume the beans-repo HEAD holds the
   implementation — the bean handoff commit usually touches only `.beans/`.
5. **Skills fallback** — read this file and `prompts/commands/verify.md` if `list_skills` fails.
6. Verify the bean per `prompts/commands/verify.md`.
7. If pass: `beans update <id> --remove-tag=unverified`
8. If fail: return to `in-progress`. If the bean body instructs to return to the original worker (e.g. "send back to the same session 'orchistration-work'"), hail to the work-hail band (targeting the submitter-session if available in incoming data or as instructed). On subsequent passes, complete.

## Incoming hail data

**:bean-id is the only required param.** Everything else you need comes from
the band data map (bean-repo, plan-hail, work-hail, notification-comm) or from
the bean itself (scope, acceptance criteria, worker notes). Optional params
like submitter-session / thread_id, when present, enable exact-session
returns — use them, but never require them.

Use the bean id to look up the bean and review it against the acceptance criteria (including any explicit first-fail / return-to-same-session instructions in the bean body).

For returns to exact prior sessions (no band template), compose a full "prompt" in the hail-send that explains the situation + bean-id + notes, and target using "session": <the submitter-session id>.

## When you're stuck, ask the planner — never drop the bean

If you cannot verify — implementation not found, acceptance criteria
ambiguous, missing context of any kind — do NOT fail the bean and stop.
Hail the **plan-hail** band (it is in your band data) with :bean-id in
params and a prompt explaining exactly what you need. The planner resolves
it (and owns human escalation if needed). A verification that cannot
proceed is a question for the planner, not a dead end.

On fail per bean instructions, target the work session using direct "session" frequencies (or work-hail + submitter-session) + explanatory prompt. When handing off yourself (to work or plan), pass submitter info forward when you have it.

## Notifications

Send updates using `comm_send` at key points:

- comm: the :id from notification-comm (e.g. "discord")
- content: use the "at-a-glance" format below
- discord.target: the :channel from notification-comm (e.g. "pub")

**Recommended "at-a-glance" format** (ID first, emoji for status, bold crew, action):

```
{{bean-id}} {{emoji}} **{{crew}}** {{action}} ({{short-slug}})
```

Examples:
- `orchestration-25e4` 👁️ **perceptor** verification started
- `orchestration-25e4` 🟢 **perceptor** verification passed
- `orchestration-25e4` ❌ **perceptor** verification failed (reason...)

- On starting review.
- On pass: use the format above.
- On fail: use the format above with failure reason.

**ALWAYS use exactly this format for content:**

"orchestration-xxx 👁️ **perceptor** verification started"
"orchestration-xxx 🟢 **perceptor** verification passed"

Include the bean-id and use emojis for quick good/bad recognition.
