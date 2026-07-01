# Reusing Orchestration on Other Projects

This setup (sometimes called "orchistration") allows hail-driven bean workflows across multiple roles (planner, worker, verifier) with exact session handoffs, at-a-glance notifications, and support for conflict loops or human escalation.

The core skills and commands are designed to be **project-agnostic**. Only the hail band configs are project-specific.

## 1. Role Home Directories

On the target machine (e.g. zanebot) create:

```
/Users/zane/agents/<project-name>/
├── plan/
├── work/
└── verify/
```

## 2. Clone the Beans Repo in Each Role Home

In **each** role directory, clone the project's beans repository (the repo containing `.beans.yml` and `.beans/`):

```sh
cd /Users/zane/agents/myproject/plan
git clone git@github.com:you/myproject.git
```

Do the same under `work/` and `verify/`.

The bootstrap logic discovers the directory containing `.beans/` (it does not require the session cwd to point directly at the clone).

## 3. Create Three Dedicated Isaac Sessions

Create and run these sessions:

| Session Name     | Crew      | cwd                                      | Tags          |
|------------------|-----------|------------------------------------------|---------------|
| `<project>-plan` | `prowl`   | `/Users/zane/agents/<project>/plan`      | `[:<project>]` |
| `<project>-work` | `scrapper`| `/Users/zane/agents/<project>/work`      | `[:<project>]` |
| `<project>-verify`| `perceptor` | `/Users/zane/agents/<project>/verify`  | `[:<project>]` |

The session names and tags are used for hail routing and isolation.

## 4. Project-Specific Hail Band Configs

Create three files under `~/.isaac/config/hail/` on the target:

- `<project>-plan.md`
- `<project>-work.md`
- `<project>-verify.md`

**Start by copying** the templates from this repo:

```
orchestration/isaac-beans/config/hail/
```

### Required customizations in each band file

- `crew:`
- `session-tags: [ :<project> ]`
- `bean-repo:` (full git URL of the beans repo)
- `notification-comm:` (typically `{:id :discord :channel "pub"}`)
- Cross-hail names:
  - `plan-hail`, `work-hail`, `verify-hail` (matching your band names)
- Notification text expectations (update examples/slugs as desired)
- Load the correct reusable skill (`hail-bean-plan`, `hail-bean-work`, or `hail-bean-verify`)

See the existing `orchistration-*.md` files for the full structure and examples.

## 5. Install Reusable Prompts + Your Bands

The reusable logic lives in:

- `prompts/skills/hail-bean-{work,verify,plan}/`
- `prompts/commands/{plan,work,verify}.md`

You must deploy:

1. Your three project-specific band files → `~/.isaac/config/hail/`
2. The reusable `prompts/` tree → `~/.isaac/prompts/`

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
- **Hail payload keys**: Workers and verifiers pass `submitter-session`, `submitter-crew`, `thread_id`, `notification-comm`, and the various `*-hail` names. These are required for exact-session returns and loops.
- **Notification strings**: The skills contain "ALWAYS use exactly this format" lists for at-a-glance messages. Customize the expected strings in your bands/skills for the new project.
- **Human escalation**: The iMessage target (`micahmartin@mac.com`) and some wording are currently hardcoded in the plan band and `hail-bean-plan` skill. Update them for your project.
- **Git access**: The remote clones (plan/work/verify) perform `beans update` + commit + push. They need appropriate permissions.
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
│       └── <project>-verify.md
├── prompts/          # (copy or symlink the reusable tree)
│   ├── commands/
│   └── skills/
│       └── hail-bean-*/
├── install.sh        # (thin wrapper around the one in this repo)
└── README.md
```

The prompts can be shared across all projects using this style. Only the three band files + any project-specific notification text need to be maintained per project.

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