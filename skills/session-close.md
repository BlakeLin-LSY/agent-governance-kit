---
name: session-close
description: Pre-clear session checklist. Verifies work is committed, memory is updated through the human-gated promotion step, and the session is recorded before context is cleared. The closing half of the session lifecycle (pairs with session-start).
version: 1.0.0
---

# Skill: session-close

End every session in a clean, recoverable state.

## When to use
Before clearing context or ending a working session.

## How it works
1. **Verify the work landed** — read the staged diff; confirm commits exist (a
   clean working tree is not proof on its own).
2. **Update memory through the gate** — capture is automatic, but promotion to
   durable memory is human-approved (`prepare → approve → park`).
3. **Record the session** — a short log entry of what changed and what's next.
4. **Leave a handoff** if work is unfinished.

## Output
Committed work, gated memory updates, and a session record the next start can pick
up from.

## Principle
"Clean working tree" is ambiguous — trace the landing commit, don't assume it.
