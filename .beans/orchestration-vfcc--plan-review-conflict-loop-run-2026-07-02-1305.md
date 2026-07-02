---
# orchestration-vfcc
title: plan-review conflict loop (run-2026-07-02-1305)
status: in-progress
type: task
priority: normal
tags:
    - unverified
created_at: 2026-07-02T21:17:51Z
updated_at: 2026-07-02T21:18:54Z
---

This is a fresh process test bean for the plan-review orchestration flow, under the band-data + reply_to threading configuration.

Perform only the work described; append observations if process test.

## Plan-review loop instructions (all participants must follow exactly)

All handoffs go through the BANDS (work-band / verify-band / plan-band from your delivery data block). Never stuff coordinates into params — :bean-id is the only required param. On every responding hail, set reply_to to the incoming hail id so the whole loop shares one thread. When a handoff needs explanation, supply a "prompt" override — the band data still arrives. Use flat snake_case keys in hail-send. Prior legs of the exchange are fetchable with hail_get via the thread.

Send comm_send notifications at every milestone using the exact formats from your hail-bean-* skill, filling <crew> from your ambient session identity.

1. Worker (scrapper): Claim the bean (in-progress + unverified tag), append initial ## Process Observations. Hand off via the verify-band with :bean-id in params and reply_to set.

2. Verifier (perceptor): On FIRST receipt, note a conflict (the bean requirements cannot satisfy verifier standards). Append a clear ## Verification failed note. Do NOT complete. Return via the work-band with reply_to and a prompt override explaining the conflict.

3. Worker: Receive the return. Determine the conflict cannot be resolved at worker level. Escalate via the plan-band with reply_to and a prompt override containing the conflict details.

4. Planner (prowl): Receive the hail. Adjust by adding a note to this bean (edit and commit from the plan clone): "## Planner unblock note: bean is unblocked per plan-review test. Worker and verifier may proceed with the loop." Hand back via the work-band with reply_to and a prompt override summarizing the unblock.

5. Worker: Note the unblock in observations. Hand off via the verify-band again with reply_to.

6. Verifier: On receipt of the unblocked bean, approve it. Remove unverified tag, set status completed. Append verification pass note.

This is explicitly a process test / no-op for orchestration flow validation.

## Process Observations

- Trusted hail `7a7a3810` carried bean-id `orchestration-vfcc`; work proceeded against that exact bean.
- Bootstrap followed repo-local `hail-bean-work` guidance from `isaac-beans/prompts/skills/hail-bean-work/SKILL.md`.
- Confirmed the orchestration repo is available under the worker role home at `/Users/zane/agents/orchestration/work/orchestration` with `.beans/` present.
- This bean is explicitly a process-test / no-op orchestration loop, so no product-code edits or test runs were required on the initial worker pass.
- The bean body requires band-only handoffs with reply_to threading preserved through worker → verifier → worker → planner → worker → verifier.
- Notification attempts target the named Discord channel `pub` using the delivery-provided notification coordinates.
