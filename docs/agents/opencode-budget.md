# OpenCode run budget

`.github/workflows/opencode.yml` limits how many times the agent model may be
called for one pull request. The default is **three** admitted runs; change
`OPENCODE_PR_RUN_LIMIT` at the top of the workflow to change it.

## What counts

Every admitted `/oc` or `/opencode` request by an owner, member or collaborator
in that pull request consumes one attempt. Within a pull request, only
conversation comments (`issue_comment`) are counted; inline review comments are
deliberately not a trigger. The command must start the comment (`startsWith`), so
quoting a command later in the body does not start a run. A cancelled run, a
timeout and a `Re-run` attempt from the Actions UI all consume an attempt as
well: a re-run increments `run_attempt` on the same workflow run.

A new pull request has a new title, so it starts with a new budget. Comments on
plain issues are not limited by this budget.

## Where the counter lives

The counter is the **Actions run history**, not a file, label or comment:

- `run-name` stamps each command run as `opencode-request pr-<number>` and each
  non-command run as `opencode-idle ...`;
- the gate sums `run_attempt` over the earlier completed command runs with that
  title, plus its own `github.run_attempt`;
- queued runs are ignored because they have not been admitted yet, and skipped
  runs are ignored because they never reached the agent;
- the gate token has `actions: read`, so the run history is append-only for it.
  Editing the PR report comment cannot change the budget either.

The limit therefore holds while the run history is retained and this workflow is
unchanged. An administrator can delete old runs, change the workflow, change the
retention policy or change the limit; those actions reset or weaken the limit.
The budget does not cap all spending on an issue, only the runs of one PR.

## When the budget is exhausted

The gate writes `allowed=false`, the model job is skipped, and a separate job
without the model publishes a PR comment with:

- reason `limit_exhausted`;
- the last PR head SHA;
- a link to the run logs;
- status **нужен человек** and the `ready-for-human` label.

## Other failure reasons

The same report job runs after the agent stops and publishes:

| Reason         | Meaning                                                            |
| -------------- | ------------------------------------------------------------------ |
| `timeout`      | the single agent step hit its step timeout                         |
| `infra`        | budget check failed, missing key, installer or CLI preparation     |
| `agent_failed` | any other agent failure                                            |

If a reason does not match what the logs show, inspect the failing job log: an
unknown cause is not guessed. The next action is chosen by a human; there is no
automatic fix loop for this repository.
