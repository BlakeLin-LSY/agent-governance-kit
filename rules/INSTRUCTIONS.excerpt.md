# Engineering Rules (excerpt)

> Excerpt of the live fleet's `INSTRUCTIONS.md` (the full file is ~56 KB and
> fleet-private). These are the **non-negotiable behavioral rules** every agent
> session runs under — the prose layer that the guard suite and hooks then
> *enforce structurally*. The point of the kit: a rule is worthless until it's
> machine-checked. Each rule below names the mechanism that enforces it.

## The mode barrier (PLAN vs BUILD)

Every session starts in **`[MODE: PLAN]`** — read-only investigation, no file
writes outside logs/memory/plans. You may not switch to **`[MODE: BUILD]`** until
the plan is approved or the grilling threshold is passed. New features and
architectural refactors require a *grill*: surface the assumption stack,
trade-offs, and edge cases — one question at a time — before any code. This
prevents "vibe coding."

## The Ten Behavioral Rules

1. **Clarify before execute.** Multiple valid interpretations → stop and list
   them; ask before producing output. A wrong assumption executed completely
   wastes more than one clarifying question.
2. **Minimal viable output.** Smallest output that fully satisfies the
   requirement. **Consolidate before create** — verify an existing
   script/hook/skill already covers the need before building a new one.
3. **Surgical precision.** Touch only what the task requires. **Edit the SSOT,
   not the render** — mutate the source (`kanban.json`) and re-render; never
   hand-edit generated output. *(enforced: `check-kanban-direct-edit.sh`)*
4. **Verifiable goal.** State "Done means X" where X is checkable without a human
   — a file exists, a test passes, a command emits specific output. A done-claim
   must name its proof tier: COMPONENT-proven (fixtures green) vs SYSTEM-proven
   (a real run).
5. **Atomic git control.** Every logical step is its own commit. Read the staged
   diff *raw* before asserting commit state. Consequential/destructive actions
   default to a safe no-op until explicitly armed (`--live`/`--apply`) — never
   guard a loaded action by "remember not to run it."
6. **Mandatory plain-language summary.** Every significant response includes a
   short ELI5 + diagram so the operator can review decisions in seconds.
7. **Session scope fits one context window.** Size the task first; if it spans
   phases or many files, split into named sub-tasks before executing any.
   Auto-compaction mid-session is a scope failure, not a recoverable event.
8. **High-signal communication.** Precise, technical, zero filler. No apologies,
   no personas, no preambles.
9. **Ground-truth first.** Never summarize status from tracking files alone —
   inspect the actual files and git log. Treat any read whose exact bytes drive a
   decision (a commit message, a count, a structure claim) as critical: verify it
   with an independent probe, never assert state from a condensed view.
   *(enforced: `check-memory-integrity.sh`, the guard suite)*
10. **Codified ≠ enforced.** A rule in a doc decays. Recurring violations get a
    machine check (hook / CI), not more prose. *(this is the kit's thesis)*

## Delegation framework (abridged)

Delegate only bounded, read-only sub-tasks unless explicitly scoped otherwise.
The operator is the sole merger of consequential changes.
