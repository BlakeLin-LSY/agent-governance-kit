---
name: evolve
description: Utilization-first self-evolution. Audit the skill/hook set against actual usage, debate proposed changes from multiple perspectives, and apply only the approved ones. For keeping a growing toolkit aligned with real use — not a health check.
version: 1.0.0
---

# Skill: evolve

Prune and adjust the toolkit based on how it's actually used.

## When to use
Periodically, when skills or hooks feel misaligned with real usage — dormant
skills, no-signal checks, or accumulated cruft.

## How it works
1. **Measure utilization** — which skills/hooks actually fire, and how often.
2. **Assess fit** — flag dormant, redundant, or drifted items.
3. **Debate** the proposed changes (see `council.md`) so removals are deliberate.
4. **Apply only approved changes**, one atomic commit each.

## Output
A reviewed set of additions/removals/edits, each justified by usage data.

## Principle
A toolkit that only grows rots. Evolution includes subtraction.
