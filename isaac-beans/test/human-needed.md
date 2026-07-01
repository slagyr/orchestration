# Human-Needed Test for Orchestration

See `shared.md` for the common **Remote Access**, **Installation / Deployment**, **Given**, and shared Pre-When verification sections.

## When

- **Create a brand new bean** (never reuse IDs). In the local orchestration checkout root (with .env), use the plan-side clone or the local .beans to create:

  ```sh
  cd /path/to/orchestration
  # create locally (not on remote), commit, push first per rules
  beans create "human-needed test (run-YYYY-MM-DD-HHMM)" \
    --type=task --priority=normal \
    --body 'This is a fresh process test / no-op bean for the human-needed orchestration test.

Follow the sequence exactly:

1. Worker (scrapper): Claim the bean (in-progress + unverified tag), append initial ## Process Observations. Hand off to verifier using direct session targeting if possible or the verify band, including submitter-crew, submitter-session (this session), thread_id, bean-id, etc.

2. Verifier (perceptor): Hand the bean back to the *exact worker session* that sent it (use submitter-session value from the incoming hail data to set frequencies to that session; include full explanation prompt + bean-id).

3. Same worker session (exact continuity): Receive return from verifier. Hand off to planner (use the plan band or direct if needed), passing submitter info so return can target this exact session. Include conflict details.

4. Planner (prowl): You are unable to resolve the issue.  Human intervention is required.

5. Send discord notification to "pub" using the at-a-glance format indicating human help is needed, with a short synopsis.

6. Send an additional imessage to micahmartin@mac.com stating help is needed on the bean, with a short synopsis.

Use flat snake_case for hail-send, exact sessions for returns using "session" key, comm_send to "pub" at milestones using at-a-glance format from the skills.

This is explicitly a process test / no-op for human-needed flow validation.'
  ```

  Record the ID. Commit + push the bean file from the local checkout.

- Hail to the orchistration-work band (example):

  ```sh
  isaac hail send --band orchistration-work --params '{:bean-id "orchestration-XXXX"}'
  ```

  (Hail may be issued locally or via SSH on target.)

## Then

- Worker claims, appends observations, hands off to verifier (exact session info passed).
- Verifier receives (using submitter info), follows body (returns to exact worker session without completing), sends appropriate comm.
- Same worker receives return, hands off to planner with submitter info + conflict details (using plan band + prompt).
- Planner receives on orchistration-plan, determines it is unable to resolve per body instructions.
- Planner appends human-needed note(s) to the bean, commits + pushes.
- Discord pub receives at-a-glance: `orchestration-XXXX 🆘 **prowl** human help needed (short synopsis)`
- iMessage sent to micahmartin@mac.com with "Human help needed on bean ...: short synopsis. Check Discord #pub."
- Bean ends in-progress (human intervention required); no handback to worker.
- All steps use correct orchistration-* names, :orchestration tags, flat hail-send, "session" targeting where specified, at-a-glance comms.
- Evidence in transcripts, git history on bean, beans show, and sent comms.

## How an Agent Should Verify This Test (Step-by-Step Checklist)

Follow shared.md remote access + pre-when first (use this bean title/description for freshness checks).

Use SSH to TARGET for all inspection.

### Flow steps 1-4 (worker -> verifier -> worker -> planner)
- Confirm initial work turn on orchistration-work (scrapper): claim, observations with slug "human-needed...", comm_send at-a-glance, handoff to verify with submitter-session/thread.
- Confirm verify turn on orchistration-verify (perceptor): receives with submitter info, sends start notif, hands back using direct "session" key to the exact orchistration-work session (with explanatory prompt referencing human-needed escalation to planner).
- Confirm second (continuation) turn on *exact same* work session: receives return, escalates to planner band with params (submitter info, thread, prompt summarizing), sends observations comm, commits "escalate ... to planner".
- Confirm planner turn on orchistration-plan: receives the escalation prompt with g2zf/human-needed details.

### Step 5: Planner unable
- Planner reads bean body + skill/band, decides unable to resolve.
- Appends note e.g. "## Human needed" + synopsis to bean body.
- Does *not* hand back to worker.

### Step 6-7: Notifications
- comm_send discord with exact: `orchestration-g2zf 🆘 **prowl** human help needed (Requirements conflict on feature priority; needs human decision.)` (or equivalent short synopsis from body).
- comm_send imessage: comm="imessage", target="micahmartin@mac.com", service="iMessage", content matching "Human help needed on bean orchestration-XXXX: [short synopsis]. Check Discord #pub."
- Evidence in plan transcript (toolCalls + results), git commit "plan: mark ... human needed", pushed.
- Bean on remote plan clone shows the ## Human needed section, status in-progress.

### Final checks
- Full chronology via git commits on bean (create, claim, handoff verify, return from verify, escalate to plan, human mark) + transcript timestamps.
- Exact session targeting used for verify -> worker return.
- No completion or unverified removal by verifier (per instructions).
- No errors in the three session transcripts.
- All at-a-glance comms sent to pub at milestones (claim/obs/handoffs/started/human).
- Correct terminology throughout (orchistration-*, no isaac leakage in active context).
- Clones present under /work, /verify, /plan on target with the bean visible after pulls.
- This validates the human escalation path from planner (discord + imessage) when unable to resolve.

Report with excerpts: transcript lines for each handoff/comm, `git log --oneline -S g2zf -- .beans/...`, `beans show`, full comm_send arg blocks, final bean body snippet.
