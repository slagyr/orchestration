---
# orchestration-5omv
title: human-needed test (run-2026-07-02-1330)
status: in-progress
type: task
priority: normal
tags:
    - unverified
created_at: 2026-07-02T21:27:14Z
updated_at: 2026-07-02T21:28:12Z
---

This is a fresh process test / no-op bean for the human-needed orchestration test, under the band-data + reply_to threading configuration.

Perform only the work described; append observations if process test.

## Human-needed loop instructions (all participants must follow exactly)

All handoffs go through the BANDS (work-band / verify-band / plan-band from your delivery data block). :bean-id is the only required param. Set reply_to to the incoming hail id on every responding hail so the loop shares one thread. Supply a prompt override when a handoff needs explanation. Use flat snake_case keys in hail-send. Send comm_send notifications at each milestone using the exact formats from your hail-bean-* skill, filling <crew> from your ambient session identity.

1. Worker (scrapper): Claim the bean (in-progress + unverified tag), append initial ## Process Observations. Hand off via the verify-band with :bean-id and reply_to.

2. Verifier (perceptor): Do not verify. Return via the work-band with reply_to and a prompt override: the bean has a requirements conflict that verification cannot resolve.

3. Worker: Receive the return. The conflict cannot be resolved at worker level. Escalate via the plan-band with reply_to and a prompt override containing the conflict details.

4. Planner (prowl): You are unable to resolve the issue. Human intervention is required. (The requirements conflict in a way only a human can decide - e.g. priority between feature A and B.) Append a "## Human intervention required" note to this bean, commit and push from the plan clone. Do NOT hand back to the worker.

5. Follow the human-help escalation in your hail-bean-plan skill, using the notification-comm and human-help-comm coordinates from your delivery data block: send the at-a-glance 🆘 to the notification channel, and send the visually clear escalation message (emojis, newlines, structure) to the human-help-comm target.

The bean ends in-progress. This is explicitly a process test / no-op for human-needed flow validation.

## Process Observations

- Trusted hail `80383678` carried bean-id `orchestration-5omv`; work proceeded against that exact bean.
- Bootstrap followed repo-local `hail-bean-work` guidance from `isaac-beans/prompts/skills/hail-bean-work/SKILL.md`.
- Confirmed the orchestration repo is available under the worker role home at `/Users/zane/agents/orchestration/work/orchestration` with `.beans/` present.
- This bean is explicitly a process-test / no-op human-needed loop, so no product-code edits or test runs were required on the initial worker pass.
- The bean body requires band-only handoffs with reply_to threading preserved through worker → verifier → worker → planner, after which planner escalates to human help and does not return the bean to worker.
- Notification attempts target the named Discord channel `pub` using the delivery-provided notification coordinates.
