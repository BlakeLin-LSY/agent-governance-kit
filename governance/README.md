# governance/

The reliability layer — what keeps an autonomous agent honest.

| File | Role |
|---|---|
| `guard.sh` | 24-check deterministic health suite (zero-LLM). Runnable: `bash governance/guard.sh` |
| `hooks/pre-commit` | structural gate wiring the checks below |
| `hooks/check-memory-integrity.sh` | memory.md stays append-only + under cap; new entries carry a verification anchor |
| `hooks/check-skill-count.sh` | stated skill counts must match disk (a count can't drift from reality) |
| `hooks/check-kanban-direct-edit.sh` | blocks hand-edits to the generated KANBAN render (SSOT discipline) |
| `manage-kanban.sh` | the only write path for task state: `--render` / `--update` / `--add` (mutate the JSON, regenerate the render) |
| `hooks/HOOKS.md` | how the hooks wire into git + CI |
| `examples/` | synthetic `kanban.json` (source) + `KANBAN.example.md` (generated render) the checks run against |

## SSOT in action

```bash
bash governance/manage-kanban.sh --update T-003 --status done   # mutate source → auto re-render
bash governance/manage-kanban.sh --render                       # regenerate the render from JSON
# editing KANBAN.example.md by hand is blocked at commit time by check-kanban-direct-edit.sh
```

## Activate the gate

```bash
git config core.hooksPath governance/hooks
```

Local hooks are the fast dev-loop; the CI mirror (`.github/workflows/guard.yml`)
is the gate that survives `--no-verify`. See `../docs/ARCHITECTURE.md`.
