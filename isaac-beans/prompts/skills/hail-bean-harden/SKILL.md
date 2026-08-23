---
name: hail-bean-harden
description: >-
  Bootstrap and run bean hardening from a hail delivery via harden band.
  Project-agnostic; thresholds and steps come from the implementation repo's
  .hardening.edn (or skill defaults). Use only when harden-band is configured.
---

# Hail-driven bean harden

Use when a hail (or band prompt) assigns bean hardening — **after** verify
has passed and tagged the bean `unhardened`.

This stage is **optional** in the pipeline: it only runs when the project's
hail **data** includes `harden-band`. Skills never invent this band.

## Bootstrap checklist

1. **Find the beans repo** — directory containing `.beans/`.
2. **`git -C <beans-repo>` pull --rebase** — sync state.
3. **`beans list --tag=unhardened`** or `beans show <id>`.
4. **Find the implementation repo** — bean scope / title / body (sibling
   checkout). Pull first. Do not assume beans-repo HEAD holds product code.
5. **Skills / command fallback** — load or read:
   - this file
   - `prompts/commands/harden.md` (agent-lib harden command; also
     `skills/hardening` if present)
6. **Harden** per `harden.md` (config, steps, process-test skip, coverage).
7. **A bean CANNOT pass harden by weakening acceptance or deleting tests.**
   If the bar is unmet, this is a FAIL — return to the work-band.

### On pass

1. `beans update <id> --remove-tag=unhardened` (status stays `completed`).
2. Commit + push beans (with `Isaac-Session` trailer).
3. Notify pass (format below). Terminal for the pipeline (no next band).

### On fail

1. Append a durable note:
   `## Harden fail (attempt N, <YYYY-MM-DD>): <one-line reason>`
   N = count of `## Harden fail` notes since the last `## Planner` note, plus one.
2. `beans update <id> --status=in-progress --remove-tag=unhardened`.
3. Commit + push.
4. Route:
   - **Fewer than 2** harden fails since last Planner note → hail **work-band**
     with :bean-id, reply_to, prompt explaining the quality gap.
   - **2 or more** → hail **plan-band** (same shape) for rescope / split /
     unblock — do not bounce the worker forever.

**Hail format (flat snake_case):**
```json
{"band": "<work-band | plan-band>", "params": {"bean-id": "<id>"}, "reply_to": "<incoming-id>", "prompt": "HARDEN FAIL for <id> (reply_to: <incoming>): ..."}
```

**Targeting rule (critical):** copy band values **exactly** from the delivery
data block — never from memory. Band handoffs carry `band` + `params` only
(no invented session-tags/crew filters). Use `session` only for a concrete
session id retrieved via `hail_get`.

## Never end a turn in limbo

Every harden turn ends in exactly one of: **pass** (tag removed, notify),
**fail** (note + work/plan hail), or **stuck** (plan-band hail asking for
what you need). **Do not hail yourself to continue.** Stay in this turn
(tool-loop default 500); HOLD + human escalate if you cannot finish.

## Commit trailer

```text
Isaac-Session: <session-id>
```

## Incoming hail data

**:bean-id is the only required param.** Coordinates arrive in the delivery
data block (`bean-repo`, `work-band`, `plan-band`, `notification-comm`, …).
`harden-band` is how *you* were addressed; you do not re-hail it on pass.

## Notifications

Use `comm_send` with notification-comm from data. Fill crew/session from
**your** identity:

- Start: `<bean-id> 🔨 **<crew>**@<session> hardening started`
- Pass: `<bean-id> 🟢 **<crew>**@<session> hardening passed`
- Fail → worker: `<bean-id> ❌ **<crew>**@<session> hardening failed (reason...) → back to worker`
- Escalation → plan: `<bean-id> 🆙 **<crew>**@<session> escalated to planner (N harden-fails) → plan`
