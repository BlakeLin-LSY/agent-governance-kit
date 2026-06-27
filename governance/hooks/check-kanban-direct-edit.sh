#!/usr/bin/env bash
# check-kanban-direct-edit.sh — blocks direct staged edits to governance/examples/KANBAN.example.md
# Called by: governance/hooks/pre-commit
#
# The render is generated; the JSON is the source of truth. This hook makes the
# rule structural instead of advisory.
#   FIXTURE_STAGED=1     simulate the render staged (for testing)
#   KANBAN_DIRECT_EDIT=1 bypass (audit trail)
set -euo pipefail

staged=0
if [[ -n "${FIXTURE_STAGED:-}" ]]; then
  staged=1
elif git diff --cached --name-only 2>/dev/null | grep -q "^governance/examples/KANBAN.example.md$"; then
  staged=1
fi

[[ "$staged" -eq 0 ]] && exit 0

if [[ -n "${KANBAN_DIRECT_EDIT:-}" ]]; then
  printf '\n⚠️  KANBAN_DIRECT_EDIT=1 — direct edit of governance/examples/KANBAN.example.md allowed (audit trail)\n\n'
  exit 0
fi

printf '\n'
printf '❌  COMMIT BLOCKED — governance/examples/KANBAN.example.md is a read-only render\n'
printf '\n'
printf '    It is generated from governance/examples/kanban.example.json.\n'
printf '    Use governance/manage-kanban.sh to mutate state:\n'
printf '      governance/manage-kanban.sh --update T-XXX --status done\n'
printf '      governance/manage-kanban.sh --add --id T-NEW --title "..." [--priority High]\n'
printf '      governance/manage-kanban.sh --render   # re-generate the render from JSON\n'
printf '\n'
printf '    Override (audit trail only): KANBAN_DIRECT_EDIT=1 git commit ...\n'
printf '\n'
exit 1
