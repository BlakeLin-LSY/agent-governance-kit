# Architecture

## The spine: governance governs memory

```
        OPERATOR
           │  (sole merger of consequential changes)
           ▼
   ┌───────────────┐     plan / build mode barrier
   │  ORCHESTRATOR │ ◄─── (one model, not a fleet — see trade-off below)
   └──────┬────────┘
          │ invokes
          ▼
   ┌───────────────┐     9 composable skills (of 53): nucleus, reframe,
   │     SKILLS    │     council, step-back, grill, guard-weekly,
   └──────┬────────┘     session-start/close, evolve
          │ writes
          ▼
   ┌───────────────┐     multi-channel capture → human-gated promotion
   │    MEMORY     │     → cap/archive (forgetting-tax fix)
   └──────┬────────┘
          │ every write/commit passes through
          ▼
   ┌───────────────────────────────────────────────────┐
   │  GOVERNANCE                                         │
   │   • pre-commit hooks (structural, local dev-loop)   │
   │   • CI mirror (the gate that can't be --no-verify'd)│
   │   • guard.sh: 24 deterministic checks (zero-LLM)    │
   │   • SSOT: edit the source, render is read-only      │
   └───────────────────────────────────────────────────┘
```

The memory layer is what makes the agent useful; the governance layer is what
makes it *trustworthy*. The governance is the headline because it's the harder,
more transferable engineering — it's the same problem as keeping any autonomous
or multi-developer system honest.

## Enforcement has two tiers (and why)

| Tier | Where | Speed | Skippable? |
|---|---|---|---|
| Local hook | `git config core.hooksPath governance/hooks` | instant | yes (`--no-verify`) |
| CI | `.github/workflows/guard.yml` | per-push | no |

The local hook is the fast feedback loop; CI is the trusted third party. Claiming
local hooks alone are "enforcement" would be wrong — `--no-verify` exists. The
kit ships both so the claim is honest.

## SSOT discipline

A metric whose job is to detect drift must not itself drift. So:
- `KANBAN.md` is **generated** from `kanban.json`; the render is read-only and a
  hook blocks direct edits to it.
- The memory entry count has **one emitter** (`mem-count.sh`); consumer files
  hold a token it rewrites, and the integrity guard flags any stale token.

## The honest trade-off: designed as a fleet, runs as a monolith

The system was *designed* as a multi-agent peer fleet. It *operates* as a single
orchestrator driving skills + memory. This was a deliberate consolidation, not a
failure to build multi-agent:

- **Coordination/alignment tax** — agent-to-agent messaging adds protocol and
  failure surface.
- **Duplicated context tokens** — each agent re-loads overlapping context.
- **State-sync overhead** — concurrent writers to shared memory need merge/lock
  machinery.
- **Latency per hop** — every delegation adds a round-trip.

At single-operator scale none of that is justified, so multi-agent was deferred
until *proven needed* (consolidate before create). Hard token/latency deltas
would be the next thing to measure before reintroducing agents — they are not
claimed here because they aren't yet measured.

## What's NOT here (curation = the signal)

The live fleet has 53 skills, 60+ hooks, and a full task/palace/logs structure.
This kit ships the irreducible slice that demonstrates the mechanisms. Leaving the
rest out is the point: the senior signal is judgment about what to omit.
