---
name: guard-weekly
description: Run the deterministic health suite — 24 zero-LLM checks covering memory integrity, scope, skill/KANBAN drift, content-gate, index budget, and a green-light reality audit. No model call, no network. Produces a structured report and a non-zero exit on any failure.
version: 1.0.0
---

# Skill: guard-weekly

The recurring health check that keeps the system honest.

## When to use
On a schedule (weekly), in CI on every push, and any time system health seems
off. Cheap enough to run often — it makes no model or network calls.

## How it works
Runs the 24 checks implemented in `governance/guard.sh`. Each check is:
- **deterministic** — same input, same verdict;
- **independent** — one failing check never aborts the rest;
- **idempotent** — read-only; re-running mutates nothing;
- **exit-code-driven** — exit 1 if any check FAILs.

```bash
bash governance/guard.sh
```

In this portable kit, 8 checks run against the bundled example data and the 16
fleet-coupled ones report `SKIP (kit)` — no faked greens.

## Output
A pass/skip/fail report and an exit code suitable for a CI gate.
