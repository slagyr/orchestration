---
name: verify
description: Verify recently completed beans meet their acceptance criteria. Use when the user says "/verify".
user-invocable: true
---

# Verify Completed Beans

Review beans marked `completed` + `tag=unverified` by workers. Check that the work actually meets the acceptance criteria. Remove the `unverified` tag if good, reopen to `in-progress` if not.

You are a **reviewer**, not the implementer. You have fresh eyes. Be thorough but fair.

## The verify gate

Beans has no first-class `unverified` status (the enum is `todo / in-progress / draft / completed / scrapped`). Project convention models the gate as `status=completed` + `tag=unverified`:

- **Implementer** closes with `beans update <id> --status=completed --tag=unverified`.
- **Reviewer** (you) finds the queue with `beans list --tag=unverified`.
- **Pass:** `beans update <id> --remove-tag=unverified` (status stays `completed`).
- **Fail:** `beans update <id> --status=in-progress --remove-tag=unverified --body-append "..."` to send it back with notes.

## Steps

1. Pull the latest code with `git pull`. Beans live alongside the code, so this also syncs the latest bean state. **Run this alone.** Do not parallelize `git pull` with `beans show` / `beans list` or any other state-dependent read — the bean read can race the pull and return stale data. Sequence: pull, wait, then read.
2. **Sanity-check the worktree.** Run `git status --porcelain`. If non-empty, abort and report to the user — verification cannot be trusted on a dirty tree. Do not auto-clean: an unexpected modification may be the user's in-progress work.
3. Run `beans list --tag=unverified` to find beans awaiting verification.
4. If none found, inform the user and stop.
5. For each unverified bean (highest priority first):
   a. Run `beans show <id>` to read the **entire** description and acceptance criteria. Read the full body — do not stop parsing at the first `## Verification failed` heading. Bean fields like `## Exceptions` may appear below historical failure log entries.
   b. Identify any feature files or test references in the bean.
   c. Run the acceptance checks (see below).
   d. Make a pass/fail judgment.
   e. If **pass**: `beans update <id> --remove-tag=unverified`. Commit and push: `git add .beans/<id>--*.md && git commit -m "verify pass: <id>" && git push`.
   f. If **fail**: `beans update <id> --status=in-progress --remove-tag=unverified --body-append $'\n\n## Verification failed\n\nHEAD: <git rev-parse HEAD>\nWorking tree: <clean | dirty: ...>\n\n<reason>'`. Always include the `HEAD` line and a working-tree summary at the top of the note — workers need that to reproduce. Commit and push.
6. Report a summary of results to the user.

## Acceptance Checks

Run these in order. Stop on first failure.

### 1. Feature files not tampered with
- Before evaluating tampering, scan the bean body for a top-level `## Exceptions` section. Grep for `^## Exceptions` anywhere in the body — including below `## Verification failed` blocks. Parse all entries under it. Each entry names a feature file path and authorizes specific edits; treat those edits as permitted for step 1.
- For each feature file referenced in the bean, run `git log --oneline -- <feature-file>` to find commits that touched it.
- For each such commit, diff the file: `git show <commit> -- <feature-file>`.
- Permitted changes: `@wip` tag removal, OR changes authorized by an entry in the bean's `## Exceptions` section.
- Flag and fail if you find: reworded steps, weakened assertions, removed scenarios, or any other edit not covered by `## Exceptions`.
- If flagged, do not proceed with remaining checks — fail the bean with a clear description of what was changed AND quote the `## Exceptions` content you considered (or note its absence). This makes it auditable when the verifier and the bean disagree.

### 2. Tests pass
- If the project uses gherclj, clear stale generated specs first: `rm -rf target/gherclj/generated/`. Stale generated files from prior runs can cause failures that don't reproduce on a clean tree.
- Run the project's unit test suite — all tests must pass.
- If the bean references feature files, run those scenarios too.
- If the project uses gherclj, use `file:line` selectors to run only the relevant scenarios.
- If a scenario fails, before flagging it: re-run it in isolation on a clean tree (`rm -rf target/gherclj/generated/` then the targeted feature command). Report what reproduces and what doesn't in the failure note.

### 3. Clean test output
Scan the test runner's stdout/stderr from the run above. The output should contain only the framework's own chatter: dots, progress markers, summaries (`"Finished in X.Xs"`, `"N examples, M failures"`), and scenario titles for documentation reporters. Anything else is suspect — usually a `println` that snuck into production code.

If stray output appears, identify the source file from the bean's diff and fail the bean with the offending text quoted: *"Stray output in test run: `<text>`. Likely from `<file>`. Remove or log it."*

CLI tools that intentionally write to stdout are the legitimate exception — flag for confirmation rather than auto-failing.

### 4. Test-quality smell review
Run this in TWO passes:

**Pass A — diff scope (blocking):** For each new or substantially modified test file in the bean's diff, scan for the patterns below. Any match without a documented exception (see "Allowed overrides") **fails verification**.

**Pass B — tree scope (informational):** Run `grep -rn "Thread/sleep" spec/` (and equivalents for the other patterns) across the entire spec tree. Anything found is reported as a smell summary — file:line plus the matched pattern — even if outside the bean's diff. This catches historical smells that escaped earlier review. It does NOT fail the bean by default, but the reviewer should surface the list to the user with a recommendation to file follow-up beans.

The pattern set is the same for both passes:

1. **`Thread/sleep`** — synchronization missing. The test should poll a condition, await a promise, or inject timing control.
2. **Real network** — un-stubbed HTTP, WebSocket, or raw socket calls. Tests should mock the transport.
3. **Real filesystem outside the test dir** — `slurp`, `spit`, `io/file` on paths not clearly test-scoped (under `target/`, `/tmp/`, or a dir created in setup).
4. **Real database** — un-mocked connections. Use in-memory implementations or repository stubs.
5. **No-assertion tests** — an `it` block (or gherclj `defthen` helper) whose body doesn't call `should=`/`should`/`should-fail`/etc. and silently passes with zero assertions.
6. **Hidden time dependence** — `(System/currentTimeMillis)`, `(java.util.Date.)`, `(java.time/now)` read inside production code under test without an injection seam.
7. **Cross-test mutable state** — top-level `def` atoms or files that persist between tests, relying on test execution order.

#### Allowed overrides
- Documented in the bean's `## Exceptions` section.
- Explicitly approved in the bean body.

## Common Traps

- **Stale state**: Always pull first.
- **Dirty tree**: Fail early on `git status --porcelain`.
- **Incomplete verification**: Always run the full acceptance checks in order.
