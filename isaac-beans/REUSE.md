# Reusing Orchestration on Other Projects

This setup (sometimes called "orchestration") allows hail-driven bean workflows across multiple roles (planner, worker, verifier, optional hardener) with exact session handoffs, at-a-glance notifications, and support for conflict loops or human escalation.

The core skills and commands are designed to be **project-agnostic**. Only the hail band configs are project-specific. **Quality thresholds** live in the product repo’s `.hardening.edn`, not in these skills.

## 1. Role Home Directories

On the target machine (e.g. zanebot) create:

```
/Users/zane/agents/<project-name>/
├── plan/
├── work/
├── verify/
└── harden/    # optional — only if you configure harden-band
```

**Role boundaries (enforced by the hail-bean-* skills):**
- **Planner** — plans only. Adjusts / splits / unblocks / clarifies beans; does **not** implement, run tests, verify, or promote beans to `todo`. Only a human promotes a bean to `todo`.
- **Worker** — implements a claimed (`todo` → `in-progress`) bean, then hands to the verifier.
- **Verifier** — verifies against acceptance; on pass, either completes the pipeline or hands to harden when `harden-band` is set; never implements.
- **Hardener** (optional) — enforces project quality bars (`.hardening.edn`); never implements acceptance.

## 2. Clone the Beans Repo in Each Role Home

In **each** role directory, clone the project's beans repository (the repo containing `.beans.yml` and `.beans/`):

```sh
cd /Users/zane/agents/myproject/plan
git clone git@github.com:you/myproject.git
```

Do the same under `work/` and `verify/`.

The bootstrap logic discovers the directory containing `.beans/` (it does not require the session cwd to point directly at the clone).

## 3. Create Dedicated Isaac Sessions

Create and run these sessions:

| Session Name      | Crew        | cwd                                       | Tags                         |
|-------------------|-------------|-------------------------------------------|------------------------------|
| `<project>-plan`  | `prowl`     | `/Users/zane/agents/<project>/plan`       | `[:<project>]`               |
| `<project>-work`  | `scrapper`  | `/Users/zane/agents/<project>/work`       | `[:<project> :ci]`           |
| `<project>-verify`| `perceptor` | `/Users/zane/agents/<project>/verify`     | `[:<project> :verify]`       |
| `<project>-harden`| `perceptor` | `/Users/zane/agents/<project>/harden`     | `[:<project> :harden]` *(opt)* |

The session names and tags are used for hail routing and isolation. Give
verify and harden **distinct tags** so they do not share one session pool
when both use crew `perceptor`.

**Important targeting rules (see hail-bean-verify/SKILL.md for full details):**
- Hail using the band (e.g. `{"band": "<project>-work"}`) — the band config's `session-tags`, crew, prefer, reach etc. select the session(s).
- Use explicit `session` key **only** for exact continuity to a concrete id you retrieved (e.g. "myproject-work-1"). Never use the bare band name (e.g. "myproject-work") as a session value.
- Projects commonly use suffixed names (`<project>-work-1`, `<project>-work-2`, ...) for parallel workers under one band.

**Worker sessions (`<project>-work`) must also carry the `:ci` tag.** This allows the `ci-failure` hail band to route GitHub Actions regressions to the repair workers when no `Isaac-Session:` trailer is present in the failing commit.

## 4. Project-Specific Hail Band Configs

Create files under `~/.isaac/config/hail/` on the target:

- `_<project>-template` (edn or md) — shared frontmatter + `data:`
- `<project>-plan.md`
- `<project>-work.md`
- `<project>-verify.md`
- `<project>-harden.md` — **only if** you enable the harden stage

**Start by copying** the templates from this repo:

```
orchestration/isaac-beans/config/hail/
```

### The base template (`_<project>-template.md`)

All shared coordinates live once, in the template's frontmatter. The three
band files declare `base: _<project>-template` and add only their `crew:` and
body instructions. Leading `_` marks the template as non-addressable.

Customize in the template:

- `session-tags: [ :<project> ]`
- `prefer: :oldest`
- `data:` — the coordinate map the skills contract on:
  - `bean-repo:` (full git URL of the beans repo)
  - `notification-comm:` (typically `{:id :discord :channel "pub"}`)
  - `human-help-comm:` (e.g. `{:id :imessage :target "<address>"}`)
  - `plan-band`, `work-band`, `verify-band` (matching your band names)
  - **`harden-band` (optional)** — if present, verify pass tags `unhardened`
    and hails this band; if **omitted**, verify is terminal (work → verify only)

Customize per band file:

- `crew:` and role-specific `session-tags:` when two roles share a crew
- Notification text expectations (update examples/slugs as desired)
- Load the correct reusable skill (`hail-bean-plan`, `hail-bean-work`,
  `hail-bean-verify`, or `hail-bean-harden`)

The band `data:` is delivered with every hail — including hails that override
the prompt — so crews can hail each other with explanatory prompts without
losing coordinates.

**Pipeline coupling is data-only:** skills hand off to band names from the
data block; they do not hardcode a product-specific next step.

Use `prefer: :oldest` for pooled work sessions. The router defaults to
`recent` when no preference is set, which concentrates all `reach :one` work on
the hottest matching session and leaves sibling work sessions idle.

See the existing `_orchestration-template.md` + `orchestration-*.md` files for
the full structure and examples.

## 5. Install Reusable Prompts + Your Bands

The reusable logic lives in:

- `prompts/skills/hail-bean-{work,verify,plan,harden}/` — orchestration-owned skills (this repo)
- Commands (`plan`, `work`, `verify`, `harden`, `plan-with-features`) and
  skill `hardening` — canonical in
  [agent-lib](https://github.com/slagyr/agent-lib); **never copy them into this
  repo**. Fetch them from agent-lib raw URLs per the
  [toolbox](https://github.com/slagyr/toolbox) procedure.

You must deploy:

1. Your project-specific band files → `~/.isaac/config/hail/`
2. The `prompts/skills/` tree → `~/.isaac/prompts/skills/`
3. The agent-lib commands + hardening skill → `~/.isaac/prompts/` (toolbox fetch, not repo copy)

### Project quality config (product repo, not hail)

In the **implementation** repository (not necessarily the beans repo):

```text
.hardening.edn    # which steps run + thresholds (optional; skill defaults apply)
```

Workers and hardener both read it. See agent-lib `commands/harden.md`.

On the target, maintain a deployment manifest skill (see zanebot's
`zane-toolbox`) listing every deployed component and its canonical source.

You can adapt the installer from this repo:

```
orchestration/isaac-beans/install.sh
```

The installer only does a targeted rsync of `config/` and `prompts/`. It never deletes files.

After installing, **reload or restart** the three `<project>-*` sessions so the new bands, skills, and commands are picked up.

## 6. Discord "pub" Channel Configuration

The bands use `notification-comm: {:id :discord :channel "pub"}`.

In `~/.isaac/config/isaac.edn` you **must** have a name resolution entry:

```edn
:comms {:discord {:discord/channels {"SNOWFLAKE_FOR_PUB" {:name "pub"}
                                      ...}}}
```

Without the `"pub"` name entry, `comm_send` to the public channel will fail (even if the skills always target it).

## 7. Additional Requirements & Gotchas

- **Beans repo prefix**: Your `.beans.yml` defines the bean ID prefix (e.g. `myproject-`).
- **Implementation clones** (for split-repo projects): If your beans drive work in separate repos, ensure the relevant clones exist as siblings under the role homes. The work skill looks for them.
- **Hail params**: `:bean-id` is the only required param on every hail. Coordinates travel in the band `data:`; explanations travel in prompt overrides; thread continuity comes from `reply_to` (prior hails fetchable with `hail_get`).
- **Notification strings**: The skills contain "ALWAYS use exactly this format" lists for at-a-glance messages. Customize the expected strings in your bands/skills for the new project.
- **Human escalation**: The procedure lives in the `hail-bean-plan` skill; the coordinates (`notification-comm`, `human-help-comm`) live in your base template's `data:`.
- **Git access**: The remote clones (plan/work/verify) perform `beans update` + commit + push. They need appropriate permissions.
- **Commit provenance**: Every orchestration-created commit should include
  `Isaac-Session: <session-id>` (and `Isaac-Bean: <bean-id>` on implementation
  commits while bean work is in flight) so CI-failure hails route to the
  offending session and correlate with the active bean. Recommended form:
  `git commit --trailer "Isaac-Session: <session-id>" --trailer "Isaac-Bean: <bean-id>"`
- **No legacy .toolbox**: This system uses the `prompts/` layout.
- **Session reloads**: Changes to bands or prompts require reloading the affected sessions.
- **Fresh beans for testing**: Every test run (or real workflow validation) should use a brand new bean with a unique ID.

## Recommended Layout for Reusability

```
<project>-isaac-beans/
├── config/
│   └── hail/
│       ├── <project>-plan.md
│       ├── <project>-work.md
│       ├── <project>-verify.md
│       └── <project>-harden.md   # optional
├── prompts/          # (copy or symlink the reusable tree)
│   ├── commands/
│   └── skills/
│       └── hail-bean-*/
├── install.sh        # (thin wrapper around the one in this repo)
└── README.md
```

The prompts can be shared across all projects using this style. Only the band
files + any project-specific notification text need to be maintained per
project. Thresholds stay in each product’s `.hardening.edn`.

## Verification

After setup, you should be able to:

- Hail a bean using one of the `<project>-*` bands.
- See the roles correctly discover the beans repo.
- Observe exact `session` targeting for handoffs.
- Receive at-a-glance notifications in your configured "pub" channel.

See `test/shared.md` and `test/verification-guide.md` for the detailed "Given" state and evidence patterns used when validating the current implementation. You can adapt those checklists for your project.

## Related Files

- `config/hail/` — band templates
- `prompts/skills/hail-bean-*/SKILL.md` — reusable logic
- `install.sh` — deployment helper
- `test/` — current working examples and verification procedures

This mechanism was extracted from the `orchestration` project so the same hail + exact-session + notification patterns can be used anywhere.
