# Fleet Memory (example)

> **Synthetic sample** — this is example data shipped with the kit so the guard
> suite has something to run against. No real entries. The real fleet's memory is
> private and never published. Format rules below are the ones the guards enforce.
>
> **Append-only.** Each entry is a `## [YYYY-MM-DD]` block. Entries are never
> edited or deleted in place — superseded facts get a new entry; capped entries
> get an `**[ARCHIVED ...]**` marker (see `memory-archive.py`). Every new entry
> must carry a *Command Anchor* (a commit hash, a `path/`, or a ✅/❌/⚠️ result)
> so memory records verified facts, not vibes.

## [2026-01-04]
**Decision:** Guard suite must stay zero-LLM.
**Why:** Determinism — a governance check that calls a model can hallucinate a
pass. All 24 checks are pure shell. ✅ verified: `guard.sh` makes no network call.

## [2026-01-09]
**Lesson:** codified ≠ enforced.
**Why:** A rule written in a doc decays; only a machine check holds. Moved the
memory-integrity rule from prose into `governance/hooks/pre-commit`. See
`governance/hooks/check-memory-integrity.sh`.

## [2026-01-15]
**Decision:** Edit the source, never the render.
**Why:** `KANBAN.md` is generated from `kanban.json`; hand-editing the render
silently diverges from the SSOT. Added `check-kanban-direct-edit.sh` as a commit
gate. ✅ blocks a staged `KANBAN.md` edit.

## [2026-01-21]
**Lesson:** A drift-detector must not itself drift.
**Why:** Three docs carried three different memory counts (96/92/93) while the
real count was 94. Fix: one emitter (`mem-count.sh`) owns the number; consumers
hold a token it rewrites. ⚠️ caught by the integrity guard.

## [2026-02-02]
**Decision:** Promotion to durable memory is human-gated.
**Why:** trust > volume. Auto-capture is automatic; only promotion to shared
memory passes a `prepare → approve → park` gate. See `promote-memory-check.sh`.

## [2026-02-11]
**Lesson:** Consolidate before you create.
**Why:** "Build X" usually means "X already exists" at maturity — inventory the
family and name the thin delta first. Cut three planned scripts to zero. ✅

## [2025-09-01]
**[ARCHIVED 2026-01-20 → archive/2025-Q3.md]**
**Decision:** (early) one flat notes file.
**Why:** Superseded by the multi-channel design. Kept as an archived marker so the
cap check excludes it from the live budget — archival is non-destructive.
