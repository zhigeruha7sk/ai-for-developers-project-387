# Triage Labels

The skills speak in terms of five canonical triage roles. This file maps those roles to the actual label strings used in this repo's issue tracker.

| Label in mattpocock/skills | Label in our tracker | Meaning                                  |
| -------------------------- | -------------------- | ---------------------------------------- |
| `needs-triage`             | `needs-triage`       | Maintainer needs to evaluate this issue  |
| `needs-info`               | `needs-info`         | Waiting on reporter for more information |
| `ready-for-agent`          | `ready-for-agent`    | Fully specified, ready for an AFK agent  |
| `ready-for-human`          | `ready-for-human`    | Requires human implementation            |
| `wontfix`                  | `wontfix`            | Will not be actioned                     |
| —                          | `skip-triage`        | Opt out of automatic triage              |

When a skill mentions a role (e.g. "apply the AFK-ready triage label"), use the corresponding label string from this table.

Edit the "Label in our tracker" column to match whatever vocabulary you actually use.

## Automatic triage

`.github/workflows/opencode-triage.yml` runs on `issues: opened` only (never on comments or PRs).

**Who is triaged.** Human-authored issues only. Bots are ignored. An issue is skipped when it
already carries `skip-triage`, `needs-info`, `ready-for-agent`, `ready-for-human` or `wontfix`.
Add `skip-triage` when a new issue must not be triaged automatically.

**What happens.** The workflow adds `needs-triage` and posts a comment starting with
`/oc <!-- opencode-auto-triage -->`. `opencode.yml` sees the marker and runs the dedicated
`triage` agent instead of the normal agent used for manual `/oc` commands.

**Permissions.** The triage job runs with `permissions: {}` and writes through
`secrets.AGENT_PUSH_TOKEN` only. A comment authored by `github-actions[bot]` does not trigger
`opencode.yml`, so the PAT is required. The job times out after 5 minutes and uses
`concurrency` keyed by the issue number without cancelling an in-flight run.

**Agent limits.** The `triage` agent is defined in `opencode.json` and is read-only:
`edit`, `write`, sub-agents (`task`) and questions are denied, and the shell is limited to
`gh issue view|list|comment|edit|close|reopen`, `gh label list` and read-only
`git`/`ls`/`rg` commands. It must not change code, create branches, commits or pull requests.
