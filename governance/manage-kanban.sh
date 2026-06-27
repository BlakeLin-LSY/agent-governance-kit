#!/usr/bin/env bash
# manage-kanban.sh — the ONLY write path for task state (SSOT discipline).
#
# kanban.example.json is the single source of truth; KANBAN.example.md is a
# generated, read-only render. You never hand-edit the render — you mutate the
# JSON through this tool and re-render. A pre-commit hook
# (check-kanban-direct-edit.sh) blocks any direct edit to the render, so this is
# the enforced path, not a convention.
#
# Usage:
#   manage-kanban.sh --render                         # regenerate the .md from the .json
#   manage-kanban.sh --update T-003 --status done     # change a task, then re-render
#   manage-kanban.sh --add --id T-005 --title "..." [--priority Med]   # add, then re-render
#
# Deterministic, no network. JSON handled via python3 (stdlib only).
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT=""
[ -n "$ROOT" ] || ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

JSON="governance/examples/kanban.example.json"
MD="governance/examples/KANBAN.example.md"

render() {
  python3 - "$JSON" "$MD" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
data = json.load(open(src))
rows = ["<!-- GENERATED from kanban.example.json by manage-kanban.sh --render. DO NOT EDIT BY HAND. -->",
        "# KANBAN (generated render)", "",
        "| id | title | status | priority |", "|----|-------|--------|----------|"]
for t in data["tasks"]:
    rows.append(f'| {t["id"]} | {t["title"]} | {t["status"]} | {t.get("priority","")} |')
open(dst, "w").write("\n".join(rows) + "\n")
print(f"rendered {len(data['tasks'])} tasks → {dst}")
PY
}

update_task() {  # $1=id $2=status
  python3 - "$JSON" "$1" "$2" <<'PY'
import json, sys
src, tid, status = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.load(open(src))
hit = [t for t in data["tasks"] if t["id"] == tid]
if not hit:
    sys.exit(f"no such task: {tid}")
hit[0]["status"] = status
if status == "done":
    hit[0]["shipped"] = True
json.dump(data, open(src, "w"), indent=2); open(src, "a").write("\n")
print(f"updated {tid} → status={status}")
PY
  render
}

add_task() {  # $1=id $2=title $3=priority
  python3 - "$JSON" "$1" "$2" "${3:-Med}" <<'PY'
import json, sys
src, tid, title, prio = sys.argv[1:5]
data = json.load(open(src))
if any(t["id"] == tid for t in data["tasks"]):
    sys.exit(f"task already exists: {tid}")
data["tasks"].append({"id": tid, "title": title, "status": "backlog", "shipped": False, "priority": prio})
json.dump(data, open(src, "w"), indent=2); open(src, "a").write("\n")
print(f"added {tid}")
PY
  render
}

case "${1:-}" in
  --render) render ;;
  --update)
    id="${2:-}"; shift 2 || true
    [ "${1:-}" = "--status" ] || { echo "usage: --update T-XXX --status <status>" >&2; exit 2; }
    update_task "$id" "$2" ;;
  --add)
    shift; id=""; title=""; prio="Med"
    while [ $# -gt 0 ]; do case "$1" in
      --id) id="$2"; shift 2;; --title) title="$2"; shift 2;; --priority) prio="$2"; shift 2;;
      *) echo "unknown arg: $1" >&2; exit 2;; esac; done
    [ -n "$id" ] && [ -n "$title" ] || { echo "usage: --add --id T-XXX --title \"...\" [--priority P]" >&2; exit 2; }
    add_task "$id" "$title" "$prio" ;;
  *) echo "usage: manage-kanban.sh --render | --update T-XXX --status S | --add --id T-XXX --title \"...\" [--priority P]" >&2; exit 2 ;;
esac
