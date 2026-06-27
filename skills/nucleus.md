---
name: nucleus
description: Irreducible-core extractor. Given any artifact (skill, idea, code, pipeline, system), find the minimum that keeps it functionally complete. Classify every component as NUCLEUS / SHELL / ACCIDENTAL and produce a priority removal order. Run before refactoring, simplifying, or pivoting.
version: 1.0.0
---

# Skill: nucleus

Find the smallest version of a thing that still does its job.

## When to use
Before a refactor, a simplification, or a rewrite — when something feels bloated
and you need to know what is load-bearing versus what is ceremony.

## How it works
1. **Inventory** every component of the target.
2. **Classify** each one:
   - **NUCLEUS** — remove it and the thing stops working.
   - **SHELL** — supports the nucleus; valuable but replaceable.
   - **ACCIDENTAL** — historical, redundant, or aspirational; safe to cut.
3. **Order** the ACCIDENTAL and weak-SHELL items by removal safety.

## Output
A NUCLEUS MAP (the three buckets) + a prioritized removal list. The deliverable
is the decision about what to keep, not new code.

## Principle
Less is more. This kit is itself a nucleus extract of a much larger system.
