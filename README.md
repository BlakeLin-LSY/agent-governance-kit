# agent-governance-kit

[![governance-guard](https://github.com/BlakeLin-LSY/agent-governance-kit/actions/workflows/guard.yml/badge.svg)](https://github.com/BlakeLin-LSY/agent-governance-kit/actions/workflows/guard.yml)
&nbsp;·&nbsp; zero-LLM · zero-network · MIT

**A self-governing personal AI exo-brain — extracted to its irreducible core.**

> **Start here:** [`docs/CASE-STUDY.md`](docs/CASE-STUDY.md) — six stories, each
> with a proof you can run in a minute · Proof it runs:
> [`docs/demo-output.md`](docs/demo-output.md) (real captured output) ·
> walkthrough: [`docs/DEMO.md`](docs/DEMO.md)

**▶ 20-second demo** — the gate goes green, then **red (exit 1)** when a render drifts, then
recovers: [![guard.sh red→green demo](https://asciinema.org/a/7sZB67Hd9MPdyL2r.svg)](https://asciinema.org/a/7sZB67Hd9MPdyL2r)

The interesting engineering in an autonomous agent system isn't the LLM calls.
It's the **governance**: how do you make a multi-channel memory system that
**doesn't lie to you, doesn't lose your data, and stays lean** — without a human
babysitting every write?

This repo is a curated, runnable extract of a larger private system (~3,700 files,
53 skills). It ships the parts that generalize: a **zero-LLM guard suite**, a
**human-gated memory-promotion pipeline**, and **structural enforcement** of the
principle that *codified ≠ enforced*.

> 9 curated skills · run `bash governance/guard.sh` → `8 PASS / 16 SKIP / 0 FAIL`

```
  ┌─────────────────────────────────────────────────────────────┐
  │  GOVERNANCE  (the headline — keeps the agent honest)          │
  │  24 deterministic checks · structural hooks · SSOT discipline │
  └───────────────────────────────┬─────────────────────────────┘
                                   │ governs
                                   ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  MEMORY  (the system being governed — the exo-brain)          │
  │  multi-channel capture · human-gated promotion · cap/archive  │
  └─────────────────────────────────────────────────────────────┘
```

---

## Why this exists (two audiences, one spine)

- **For AI / agent-systems engineers:** a memory architecture with a
  human-gated promotion pipeline and a forgetting-tax fix — the "agent that
  remembers" problem solved with *trust > volume*.
- **For platform / dev-productivity engineers:** governance-as-reliability —
  deterministic, idempotent, exit-code-driven checks; structural enforcement at
  commit-time and in CI; SSOT discipline where a metric can't drift from reality.

Both land on the same idea: **tether autonomous behavior to traditional
software-engineering constraints.**

---

## The 3 mechanisms (run them)

### 1. The deterministic guard suite — `governance/guard.sh`
24 health checks with **zero LLM and zero network**. The design qualities are the
point, not the language: *deterministic* (same input → same verdict),
*independent* (no `set -e` — one failing check never aborts the rest),
*idempotent* (read-only; re-running mutates nothing), *exit-code-driven* (exit 1
iff any check FAILs — CI-friendly).

```bash
bash governance/guard.sh
```

> The live fleet runs all 24 against its full structure. This portable kit runs
> the **8 self-contained checks** against bundled example data and honestly marks
> the 16 fleet-coupled ones `SKIP (kit)`. No faked greens.

### 2. Human-gated memory promotion — `memory/`
Capture is automatic; **promotion to durable shared memory is gated**
(`prepare → approve → park`). The gate is a deliberate quality/trust trade-off
for a single-operator brain — not a throughput design. `memory-archive.py` caps
and archives non-destructively (the "forgetting-tax" fix), and `mem-count.sh` is
a **tool-derived metric** so the count can't drift across files.

### 3. "codified ≠ enforced" → structural hooks — `governance/hooks/`
A rule in a doc decays; a rule wired into a hook can't be skipped by accident.

```bash
git config core.hooksPath governance/hooks   # whole team, no per-clone install
```

```bash
# the gate actually blocks a bad commit:
FIXTURE_STAGED=1 bash governance/hooks/check-kanban-direct-edit.sh   # → exit 1, COMMIT BLOCKED
```

**Honest boundary:** a local hook is the *fast dev-loop*, not absolute
enforcement — `git commit --no-verify` bypasses it. Real enforcement needs a
trusted third party, so the same checks run in CI
(`.github/workflows/guard.yml`). Local hook = fast feedback; CI = the gate that
can't be skipped.

---

## Honest trade-offs (the senior signal — see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md))

- **Designed as a multi-agent fleet → runs as a single-orchestrator monolith.**
  A judgment call grounded in mechanism (coordination tax, duplicated context
  tokens, state-sync overhead), not "it was easier." Multi-agent deferred until
  *proven needed* — consolidate before create.
- **The governance is heavy**, and some of it was over-built. The counter-habit
  is a `step-back` pruning discipline — *"I built guardrails and a habit of
  pruning them"* beats *"I built a lot."*

---

## Layout

| Dir | What |
|---|---|
| `governance/` | the 24-check `guard.sh`, structural `hooks/`, example data |
| `memory/` | promotion + cap/archive scripts, synthetic example memory |
| `skills/` | 9 curated skills (of 53 composable skills in the live fleet) |
| `rules/` | the engineering-rules excerpt + cron design |
| `docs/` | architecture + the runnable demo walkthrough |

## Run it

```bash
git clone <this-repo> && cd agent-governance-kit
bash governance/guard.sh          # → 8 PASS / 16 SKIP / 0 FAIL
```

See [`docs/DEMO.md`](docs/DEMO.md) for the full walkthrough. MIT licensed.
