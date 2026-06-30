---
name: hail-bean-plan
description: Bootstrap for planning hails via plan band. Used for orchestration in any project.
---

# Hail-driven plan

Use when hailed via orchistration-plan band.

## Bootstrap

1. Pull in the beans repo root (directory containing `.beans/`).
2. Use `beans list --ready` etc.
3. Follow `prompts/commands/plan.md` for creating beans.
4. For bean work delegation, hail the work band with appropriate structured params (see handoff contract below) including :bean-id.

## Typical flow

Receive plan hail → research → create/update beans → if ready for work, hail work band with structured params (see contract below).

When hailing the work band, pass the bean-id (and other relevant project data) in the params so the target band template can use {{bean-id}} and the worker skill gets the id.

## Notifications

Send a notification via `notification-comm` (using comm_send) when creating a bean or handing off to work, e.g. "Created bean <id> and hailing work."
