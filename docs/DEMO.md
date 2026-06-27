# Demo — clone, run, see it work

No secrets, no LLM key, no network. Everything runs against bundled example data.

## 1. The guard suite (mechanism #1)

```bash
bash governance/guard.sh
```

Expected:

```
8 PASS / 16 SKIP / 0 FAIL  —  24 checks (8 runnable in portable kit)
```

The 8 runnable checks (memory integrity, skill frontmatter, KANBAN SSOT,
skill-count, folder-contract, reality-audit self-test, content-gate, index
budget) execute for real. The 16 `SKIP (kit)` checks are fleet-coupled (they need
7-day git history, telemetry logs, or private fleet files) and are honestly not
faked.

## 2. Structural enforcement blocks a bad commit (mechanism #3)

The KANBAN render is generated from JSON and must never be hand-edited. The hook
proves it:

```bash
FIXTURE_STAGED=1 bash governance/hooks/check-kanban-direct-edit.sh
echo "exit: $?"   # → 1  (COMMIT BLOCKED)
```

Wire the whole gate into git:

```bash
git config core.hooksPath governance/hooks
# now `git commit` runs memory-integrity + kanban + skill-count checks first
```

## 3. The tool-derived metric can't drift (SSOT)

```bash
bash memory/mem-count.sh            # emits: 6 live / 1 archived / 7 total
bash memory/mem-count.sh --check    # exit 0 = all consumer tokens consistent
```

## 4. Human-gated promotion + cap/archive (mechanism #2)

```bash
python3 memory/memory-archive.py --help    # non-destructive [ARCHIVED] markers
```

`promote-memory-check.sh` is the pre-close banner that surfaces unpromoted
entries so promotion can't be silently skipped — capture is automatic, promotion
is gated.

## What "green" proves

Running this on a fresh clone proves the extract is **decoupled** from its origin
(no personal paths, no private fleet files) and that the governance mechanisms are
real, not described. That decoupling was itself gated by a `grep` probe + a
6-step secret scan before this repo was ever committed.
