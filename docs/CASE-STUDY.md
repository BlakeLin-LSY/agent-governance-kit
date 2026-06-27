# Case study — six stories, each with a proof you can run

> This repo is a sanitized, runnable extract of a private ~3,700-file self-governing
> AI system. Every claim below is anchored to a file on disk and a command you can
> run in under a minute. No screenshots required — the evidence is executable.
> Captured output: [`demo-output.md`](demo-output.md).

---

## Story 1 — "An autonomous agent that can't silently lie, lose your data, or bloat"

**The idea.** The hard part of an agentic system isn't the model call — it's
keeping an autonomous, self-writing memory *honest*. I built a **24-check
governance suite with zero LLM and zero network calls**: same input, same verdict,
every time.

**Proof (run it):**
```bash
bash governance/guard.sh        # → 8 PASS / 16 SKIP / 0 FAIL
```
**...and it actually fails when something breaks** — the test that matters:
```bash
# corrupt the generated KANBAN render so it diverges from its JSON source:
grep -v T-004 governance/examples/KANBAN.example.md > /tmp/k && cp -f /tmp/k governance/examples/KANBAN.example.md
bash governance/guard.sh; echo $?     # → Check 10 FAIL · exit 1
git checkout -- governance/examples/KANBAN.example.md   # restore
```

**Evidence on disk:** [`governance/guard.sh`](../governance/guard.sh) ·
captured run in [`demo-output.md`](demo-output.md) §1–2.

**Why it matters to you:** I think in *invariants and exit codes*, not demos. The
suite is deterministic, idempotent (read-only), and CI-portable — it would catch a
regression on a teammate's branch at 3am with no human watching.

---

## Story 2 — "codified ≠ enforced": a rule that physically blocks a bad commit

**The idea.** A rule written in a doc decays. So I move recurring rules out of
prose and into **structural enforcement** — a pre-commit hook that makes the
violation impossible-by-default.

**Proof (run it):**
```bash
FIXTURE_STAGED=1 bash governance/hooks/check-kanban-direct-edit.sh; echo $?
# → "COMMIT BLOCKED — KANBAN render is read-only" · exit 1
git config core.hooksPath governance/hooks   # wire the whole gate, no per-clone install
```

**The honest part (this is the senior signal).** A local hook is the fast
dev-loop, **not** absolute enforcement — `git commit --no-verify` bypasses it. So
the *same* checks run in CI as the trusted third party the committer doesn't
control.

**Evidence on disk:** [`governance/hooks/pre-commit`](../governance/hooks/pre-commit) ·
[`check-kanban-direct-edit.sh`](../governance/hooks/check-kanban-direct-edit.sh) ·
[`.github/workflows/guard.yml`](../.github/workflows/guard.yml).

**Why it matters to you:** I turn engineering philosophy into machine-checked
invariants — *and* I can tell you exactly where the enforcement boundary is
instead of overselling it.

---

## Story 3 — "A system that audits its own auditors"

**The idea.** The scariest failure in a monitoring system is a *dead detector*
that silently reports green. So one check's only job is to prove the other
detectors still fire.

**Proof (read it — it runs every time):**
```bash
sed -n '118,122p' governance/guard.sh
# Check 17 plants a synthetic "ERROR:" marker, then asserts the content-gate
# CATCHES it. If the detector were dead, Check 17 itself FAILs.
```

**Evidence on disk:** [`governance/guard.sh`](../governance/guard.sh) lines
118–122 (Check 17 — "green-light reality audit").

**Why it matters to you:** false-green is how real monitoring rots. Designing a
detector to test its own detectors is the kind of systems instinct that separates
"wrote some checks" from "owns reliability."

---

## Story 4 — "I designed a multi-agent fleet — and had the judgment NOT to build it"

**The idea.** The original design was a 12-agent peer fleet. It runs as a single
orchestrator. That was a *decision*, grounded in mechanism, not a failure to ship
multi-agent:

- coordination/alignment tax of agent-to-agent messaging
- duplicated context tokens per agent
- state-sync overhead on shared memory
- latency per delegation hop

None of it is justified at single-operator scale, so multi-agent was deferred
until *proven needed* — consolidate before create.

**Evidence on disk:** [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) → "The honest
trade-off."

**Why it matters to you:** seniority is knowing what *not* to build. And note what
I did **not** do: I didn't claim token/latency numbers I haven't measured — those
are flagged as the next thing to measure. Calibrated honesty under scrutiny.

---

## Story 5 — "Memory that forgets on purpose, safely — with a human in the loop"

**The idea.** An ever-growing context has a "forgetting-tax." My fix: capture is
automatic, but **promotion to durable memory is human-gated** (prepare → approve →
park), and the cap is enforced by **non-destructive archival** — entries are
*marked* `[ARCHIVED]`, never deleted, idempotently.

**Proof (run it — nothing is mutated):**
```bash
python3 memory/memory-archive.py --keep 4 --dry-run \
  --archive-file memory/archive.md --memory-file memory/memory.example.md
# → "in-range entries marked: 3 · out-of-range kept: 4 · (dry-run — no files written)"

bash memory/mem-count.sh --check   # the count has ONE emitter, so it can't drift
```

**Evidence on disk:** [`memory/memory-archive.py`](../memory/memory-archive.py) ·
[`memory/mem-count.sh`](../memory/mem-count.sh) ·
[`memory/README.md`](../memory/README.md) (the pipeline diagram).

**Why it matters to you:** I solve the real, unglamorous problem (bounded state,
safe forgetting, a metric that can't lie) with reversible, auditable operations —
the trait that makes a system survivable in production.

---

## Story 6 — "A number that can't drift, and a render you can't hand-edit"

**The idea.** Most state bugs are *two copies of the truth disagreeing*. So the
system has one rule: **there is a single source of truth, and everything else is
generated from it.** Two applications:

- **Generated renders.** `KANBAN.md` is *generated* from `kanban.json` by
  `manage-kanban.sh` (the only write path). Hand-editing the render is structurally
  blocked — you must change the source and re-render.
- **Tool-derived metrics.** The memory entry count has exactly **one emitter**
  (`mem-count.sh`); consumer docs hold a token it rewrites, and the guard flags any
  stale token. A drift-detector that can't itself drift.

**Proof (run it):**
```bash
bash governance/manage-kanban.sh --update T-003 --status done  # mutate source → auto re-render
bash memory/mem-count.sh           # → 6 live / 1 archived / 7 total  (the one emitter)
bash memory/mem-count.sh --check   # → exit 0: every consumer token matches the source
```
This wasn't theoretical. The example memory records the real bug that motivated it:
```bash
sed -n '/2026-01-21/,/caught by the integrity guard/p' memory/memory.example.md
# "Three docs carried three different memory counts (96/92/93) while the real
#  count was 94. Fix: one emitter owns the number; consumers hold a token."
```

**Evidence on disk:** [`memory/mem-count.sh`](../memory/mem-count.sh) ·
[`governance/hooks/check-kanban-direct-edit.sh`](../governance/hooks/check-kanban-direct-edit.sh) ·
[`memory/memory.example.md`](../memory/memory.example.md) (the [2026-01-21] entry).

**Why it matters to you:** SSOT discipline is the difference between "the dashboard
says 94" and "the dashboard *can't* say anything but the truth." It's the same
instinct behind infra-as-code and generated clients — I apply it reflexively.

---

## The meta-story — curation *is* the deliverable

This repo is **35 files / ~2,000 lines**, extracted from a private system of
~3,700 files and 53 skills (you're seeing **9**). Leaving 98% out was the work.
The system's own core lesson — *trust > volume, consolidate before create* — is
the same instinct a hiring manager is buying: judgment about what to leave out.

```bash
git ls-files | wc -l        # 35
ls skills/*.md | wc -l      # 10  (9 skills + a README)
```

> **One-line pitch:** *I make autonomous AI systems you can trust — and I can prove
> each guarantee with a command, including the ones I deliberately scoped down.*
