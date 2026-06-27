---
name: session-start
description: Cold-start orientation and task framing. Reads current state, surfaces open handoffs, and forces a verifiable "Done means X" before any code is written. The opening half of the session lifecycle (pairs with session-close).
version: 1.0.0
---

# Skill: session-start

Begin every working session aimed at a checkable goal.

## When to use
At the start of a session, before touching code or files.

## How it works
1. **Orient** — read current state and recent decisions; surface anything handed
   off from a previous session.
2. **Frame the task** in one sentence.
3. **Define "Done means X"** — a condition checkable without a human (a file
   exists, a test passes, a command emits specific output).
4. **Enter build mode** only once the goal is verifiable.

## Output
A one-line task + a machine-verifiable definition of done.

## Principle
You cannot finish what you cannot check. Define done first.
