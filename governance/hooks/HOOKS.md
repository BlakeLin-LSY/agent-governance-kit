# Hooks — wiring

Hooks are the structural enforcement layer: a rule wired here can't be skipped by
accident. The thesis of this kit is **codified ≠ enforced** — prose decays, a
machine check holds.

## Activate (one command, whole team)

```bash
git config core.hooksPath governance/hooks
```

This points git at `governance/hooks/` instead of the default `.git/hooks/`, so
the gate is version-controlled and every clone gets it with no install step.

## What runs at commit time (`pre-commit`)

| Check | Invariant |
|---|---|
| `check-memory-integrity.sh` | memory stays append-only, under cap; new entries carry a verification anchor |
| `check-kanban-direct-edit.sh` | the generated KANBAN render is read-only (edit the JSON source) |
| `check-skill-count.sh` | every stated skill count matches the number of files on disk |

Each check is independent and exit-code-driven; the first FAIL blocks the commit.

## The honest boundary

A local hook is the *fast dev-loop*, **not** absolute enforcement —
`git commit --no-verify` bypasses it. Real enforcement needs a trusted third
party that the committer doesn't control: the same checks run in
`.github/workflows/guard.yml` on every push/PR. Local = fast feedback; CI = the
gate that can't be skipped.

## Override (audited)

Bypasses exist for genuine emergencies and leave an audit trail, e.g.
`KANBAN_DIRECT_EDIT=1 git commit ...` or `MEMORY_TRIAGE=1` for an intentional
memory triage. The default is always the safe, gated path.
