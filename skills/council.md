---
name: council
description: Multi-role debate that surfaces trade-offs across perspectives before a decision is finalized. Default roles — Architect, Pragmatist, Skeptic, Visionary, Accountant. A fast adversarial mode (--critic) runs a single sharp challenge. Outputs a decision record.
version: 1.0.0
---

# Skill: council

Stress-test a decision from several expert viewpoints before committing.

## When to use
Before any non-trivial or hard-to-reverse decision (a new build, an architecture
choice, a pivot). Skip for routine fixes.

## How it works
Each role argues from its own incentive, then the tensions are reconciled:
- **Architect** — long-term structure, coupling, blast radius.
- **Pragmatist** — shipping cost, simplest thing that works.
- **Skeptic** — failure modes, what the proposal is hiding.
- **Visionary** — where this leads if it succeeds.
- **Accountant** — real cost (time, tokens, maintenance).

`--critic` runs only the Skeptic for a quick adversarial pass.

## Output
A decision record: the options, each role's verdict, the reconciled decision, and
the honest trade-offs accepted.
