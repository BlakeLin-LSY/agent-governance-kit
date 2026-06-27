# Cron Tasks — Reference & Control (design)

> How the fleet runs its deterministic maintenance unattended. The live *schedule*
> is the user crontab (`crontab -l`); this file documents what each job does and
> how to change it. **After editing the crontab, update the table below** so the
> two never drift — the doc and the schedule are kept consistent on purpose.
>
> This is the generic design extract; the private fleet runs more jobs, but the
> pattern and the two core jobs below are the reusable part.

## Active jobs

| # | Schedule | When (human) | Command | Log |
|---|----------|--------------|---------|-----|
| 1 | `0 6 * * 1` | Mon 06:00 | `governance/guard.sh` | `logs/cron.log` |
| 2 | `0 3 * * *` | Daily 03:00 | `memory/memory-archive.py` (cap/archive sweep) | `logs/cron.log` |

### What each job does

1. **guard-weekly** — the deterministic health suite (memory integrity, scope,
   skill/KANBAN drift, content-gate, index budget, …). Appends a report to the
   log. No LLM call, no network.
2. **memory cap/archive** — marks the oldest live memory entries `[ARCHIVED]`
   (non-destructive) so the hot index stays under its budget. No LLM call.

## How to modify a job

```bash
crontab -e          # edit the schedule
crontab -l          # verify, then update the table above
```

### Examples

```bash
# Move guard from Mon 06:00 to Sun 20:00:
#   0 6 * * 1   →   0 20 * * 0

# Run the archive sweep twice a day (02:00 and 14:00):
#   0 2,14 * * *  python3 <REPO_ROOT>/memory/memory-archive.py >> <REPO_ROOT>/logs/cron.log 2>&1

# Disable a job without deleting it: comment the line out with a leading '#'.
```

### Principles

- **Deterministic jobs only on a schedule.** Anything that calls a model is
  gated/opt-in, never silently unattended.
- **Doc-and-schedule consistency is a rule, not a hope** — the table is updated in
  the same change as the crontab edit.
- **Jobs log to a file**, so a failed run is visible after the fact.
