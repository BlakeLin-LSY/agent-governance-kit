#!/usr/bin/env bash
# promote-memory-check.sh — Q-MP freshness banner before /session-close.
#
# PreToolUse:Skill hook. Self-filters to tool_input.skill == "session-close".
# Inform-only (exits 0). Counts Claude auto-memory files whose mtime is newer
# than the last commit that touched memory/memory.example.md, and prints a
# banner so Step 5.6 cannot silently skip.
#
# Pattern mirrors the other PreToolUse:Skill hooks (stdin JSON self-filter) and
# governance/hooks/check-session-close-freshness.sh (T-FM-3).

set -euo pipefail

INPUT=$(cat 2>/dev/null || true)
SKILL=$(echo "${INPUT}" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("tool_input",{}).get("skill",""))
except Exception:
    print("")
' 2>/dev/null || echo "")

if [ "${SKILL}" != "session-close" ]; then
  exit 0
fi

REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MEMORY="${REPO}/memory/memory.example.md"
# In the live fleet this is the agent harness's per-project auto-memory store
# (e.g. ~/.claude/projects/<project-slug>/memory). It is not part of this kit, so
# the guard below makes the check no-op gracefully here — it's shipped as an
# illustrative artifact of the human-gated promotion mechanism.
AUTO_DIR="${HOME}/.claude/projects/<project-slug>/memory"

if [ ! -d "${AUTO_DIR}" ]; then
  exit 0
fi

# Reference epoch: last commit that touched memory. Fall back to its mtime if not
# in a repo, then to "0" so every file looks newer.
REF_EPOCH=$(git -C "${REPO}" log -1 --format=%ct -- "${MEMORY}" 2>/dev/null || echo "")
if [ -z "${REF_EPOCH}" ] && [ -f "${MEMORY}" ]; then
  REF_EPOCH=$(stat -c %Y "${MEMORY}" 2>/dev/null || echo 0)
fi
REF_EPOCH="${REF_EPOCH:-0}"

UNPROMOTED=0
NEW_FILES=""
while IFS= read -r -d '' f; do
  base=$(basename "$f")
  [ "$base" = "MEMORY.md" ] && continue
  mt=$(stat -c %Y "$f" 2>/dev/null || echo 0)
  if [ "$mt" -gt "$REF_EPOCH" ]; then
    UNPROMOTED=$((UNPROMOTED + 1))
    NEW_FILES="${NEW_FILES}    • ${base}
"
  fi
done < <(find "${AUTO_DIR}" -maxdepth 1 -type f -name '*.md' -print0 2>/dev/null)

if [ "${UNPROMOTED}" -gt 0 ]; then
  echo ""
  echo "⚠️  Q-MP: ${UNPROMOTED} unpromoted auto-memory entr$([ "$UNPROMOTED" -eq 1 ] && echo y || echo ies) since last memory.md commit"
  echo "    (Step 5.6 of /session-close will offer them for review.)"
  echo ""
  printf '%s' "${NEW_FILES}"
  echo ""
fi

exit 0
