# Demo output (captured 2026-06-27)

> Real, unedited output from a clean checkout. No LLM, no network, no secrets.
> Reproduce everything below with the commands shown.

## 1. The guard suite runs green — `bash governance/guard.sh`

```
agent-governance-kit · guard.sh · 2026-06-27
────────────────────────────────────────────────────────────
  ✓  Check 1  — memory integrity                   PASS
  ⚠  Check 2  — scope violations (7d git)          SKIP (kit)
  ⚠  Check 3  — stale open questions               SKIP (kit)
  ⚠  Check 4  — skill-invocation log               SKIP (kit)
  ⚠  Check 5  — stale active-edit claims           SKIP (kit)
  ✓  Check 6  — skill frontmatter                  PASS
  ⚠  Check 7  — L1 memory architecture             SKIP (kit)
  ⚠  Check 8  — PLAN.md deadline gate              SKIP (kit)
  ⚠  Check 9  — cross-hook contract drift          SKIP (kit)
  ✓  Check 10 — KANBAN SSOT (render=source)        PASS
  ⚠  Check 11 — token-proxy ground-truth guardrail SKIP (kit)
  ⚠  Check 12 — llm-wiki empty-output tripwire     SKIP (kit)
  ✓  Check 13 — skill-count (9)                    PASS
  ⚠  Check 14 — branch/worktree staleness          SKIP (kit)
  ⚠  Check 15 — stale open handoffs                SKIP (kit)
  ✓  Check 16 — folder-contract                    PASS
  ✓  Check 17 — reality audit (self-test)          PASS
  ⚠  Check 18 — skill telemetry/evolution          SKIP (kit)
  ⚠  Check 19 — improvement-queue staleness        SKIP (kit)
  ⚠  Check 20 — producer-orphan sweep              SKIP (kit)
  ⚠  Check 21 — worktree-model bypass              SKIP (kit)
  ⚠  Check 22 — openab tier-telemetry              SKIP (kit)
  ✓  Check 23 — producer content-gate              PASS
  ✓  Check 24 — index budget (6/50)                PASS
────────────────────────────────────────────────────────────
8 PASS / 16 SKIP / 0 FAIL  —  24 checks (8 runnable in portable kit)
```

## 2. ...and it actually FAILS when something breaks (negative test)

Tamper with the generated KANBAN render so it diverges from its JSON source:

```
$ grep -v T-004 governance/examples/KANBAN.example.md > /tmp/k && cp -f /tmp/k governance/examples/KANBAN.example.md
$ bash governance/guard.sh; echo "exit: $?"
  ✗  Check 10 — KANBAN SSOT (render=source)        FAIL — 1 id(s) in JSON missing from render
7 PASS / 16 SKIP / 1 FAIL  —  24 checks (8 runnable in portable kit)
exit: 1
```

Exit code 1 = CI fails the build. The checks are real, not decorative.

## 3. A structural hook blocks a bad commit

```
$ FIXTURE_STAGED=1 bash governance/hooks/check-kanban-direct-edit.sh; echo "exit: $?"

❌  COMMIT BLOCKED — governance/examples/KANBAN.example.md is a read-only render

    governance/examples/KANBAN.example.md is generated from governance/examples/kanban.example.json (T-COWORK-7).
    Use manage-kanban.sh to mutate state:
      manage-kanban.sh --update T-XXX --status done
      manage-kanban.sh --add --id T-NEW --title "..." [--priority High]
      manage-kanban.sh --render   # re-generate KANBAN.md from JSON

    Override (audit trail only): KANBAN_DIRECT_EDIT=1 git commit ...

exit: 1
```

## 4. Tool-derived metric (SSOT — cannot drift across files)

```
$ bash memory/mem-count.sh
6 live / 1 archived / 7 total
$ bash memory/mem-count.sh --check
✅  MEM-COUNT tokens consistent (6 live / 1 archived / 7 total)
```

## 5. Memory forgets safely (non-destructive archival, dry-run)

```
$ python3 memory/memory-archive.py --keep 4 --archive-file memory/archive.md --dry-run --memory-file memory/memory.example.md
  in-range entries marked     : 3
  skipped (already marked)    : 0
  out-of-range entries kept   : 4
(dry-run — no files written)
```
