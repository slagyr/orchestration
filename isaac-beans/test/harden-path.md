# Harden Path Test for Orchestration

See `shared.md` for Remote Access, Installation, common Given and Pre-When checks.

See `verification-guide.md` for the verification approach, evidence collection patterns, and common checks.

## How this fits the harness

Orchestration tests are **manual process checks against a live Isaac target**
(not Cucumber / automated CI of the hail flow). You install bands + prompts,
ensure role sessions exist, create a **fresh** bean, hail work, then collect
evidence from transcripts, `beans show`, and git.

The default `_orchestration-template` **includes** `harden-band`, so the full
pipeline is:

```text
work → verify → harden
```

Projects that omit `harden-band` keep the classic work → verify terminal
path (see `happy-path.md` notes).

## Given

- Standard orchestration sessions **plus harden**:
  - `orchestration-work` (scrapper, tags include `:orchestration`, ideally `:ci`)
  - `orchestration-verify` (perceptor, tags `[:orchestration :verify]`)
  - `orchestration-harden` (perceptor, tags `[:orchestration :harden]`)
  - `orchestration-plan` (prowl, `:orchestration`)
- Role homes exist: `.../work`, `.../verify`, `.../harden`, `.../plan`
- Installed prompts include `hail-bean-harden` and agent-lib `commands/harden.md`
  (toolbox fetch of agent-lib commands into `~/.isaac/prompts/commands/`)
- Band data includes `harden-band` → `"orchestration-harden"`

## When

- Create a brand new **process-test / no-op** bean (unique run timestamp in title).
  Body must clearly say process test / no-op so harden **skips** quality tools
  (full Cloverage is not required for process smoke).
  ```sh
  beans create "no-op harden path bean (run-YYYY-MM-DD-HHMM)" \
    --type=task --priority=normal \
    --body "Process test / no-op for work→verify→harden. Append observations only; no product code. Harden must skip quality steps for process tests and pass."
  ```
  Commit and push the bean first.
- Hail work:
  ```sh
  isaac hail send --band orchestration-work --params '{:bean-id "orchestration-xxxx"}'
  ```

## Then

1. **Work** (scrapper): claims, observations, `unverified`, hail → verify-band.
2. **Verify** (perceptor / verify tags): passes acceptance for process-test,
   sets `completed`, removes `unverified`, **adds `unhardened`**, hail →
   **harden-band** (not terminal).
3. **Harden** (perceptor / harden tags): starts, skips quality steps for
   process-test, removes `unhardened`, leaves `completed`.
4. Notifications at claim, handoff to verify, verify pass → harden, harden
   start, harden pass (formats from the skills).
5. Final bean: `status=completed`, **no** `unverified`, **no** `unhardened`.
6. No errors in work / verify / harden transcripts.

## Evidence checklist

- `beans show <id>` final tags/status
- Transcripts: verify hail to `orchestration-harden` band (exact name from data)
- Harden transcript loads `hail-bean-harden` / harden command; process-test skip
- `comm_send` lines for verify `→ harden` and harden passed
- Git log on `.beans/<id>--*.md` for tag transitions

## Negative / config note (advisory)

- If `harden-band` is **removed** from template data and re-installed, a
  process-test happy path should **end at verify** (no `unhardened`, no harden
  hail). That is the Isaac-without-harden configuration; re-add the key for
  this harden-path test.
