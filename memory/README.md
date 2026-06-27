# memory/

The exo-brain — the system the governance layer governs.

| File | Role |
|---|---|
| `memory.example.md` | synthetic sample memory (append-only format the guards enforce) |
| `memory-archive.py` | non-destructive cap/archive via `[ARCHIVED]` markers (the forgetting-tax fix) |
| `mem-count.sh` | tool-derived entry count — one emitter, so the number can't drift across files |
| `promote-memory-check.sh` | pre-close banner: surfaces unpromoted entries so promotion can't be silently skipped |

## The promotion pipeline

```
   capture (automatic)
        │
        ▼
   stage / prepare ──► human approves ──► durable shared memory
        │                   │
        │                   └─► park (defer)  ──► revisit later
        ▼
   cap reached ──► memory-archive.py marks oldest [ARCHIVED] (non-destructive)
```

**Capture is automatic; promotion to durable memory is human-gated.** The gate is
a deliberate quality/trust trade-off for a single-operator brain — *trust >
volume*. At 100× scale the same shape holds via batch/sampling review +
confidence-scored auto-promote with a human audit trail; the cap/archive buffer
bounds back-pressure if review lags.
