#!/usr/bin/env bash
# mem-count.sh — single source of truth for memory.md entry counts (P2-3, 2026-06-26).
# Kills the hand-typed count-drift class: QUICK/BASELINE/STATUS carried 96/92/93 while
# the real count was 94. Now those files hold a <!--MEM-COUNT-->…<!--/MEM-COUNT--> token
# that this script (and only this script) rewrites; the existing integrity guard greps
# for staleness. Counting logic mirrors governance/hooks/check-memory-integrity.sh exactly.
#
# Usage:
#   mem-count.sh            # emit "<live> live / <archived> archived / <total> total"
#   mem-count.sh --refresh  # rewrite every MEM-COUNT token in the consumer files
#   mem-count.sh --check    # exit 1 if any token is stale (for the integrity guard)
set -euo pipefail

ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null)" || ROOT=""
[ -n "$ROOT" ] || ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MEMORY="$ROOT/memory/memory.example.md"
FILES=(
  "$ROOT/README.md"
  "$ROOT/memory/README.md"
)

total=$(grep -c '^## \[' "$MEMORY" 2>/dev/null || true);            total=${total:-0}
archived=$(grep -c '^\*\*\[ARCHIVED' "$MEMORY" 2>/dev/null || true); archived=${archived:-0}
live=$(( total - archived ))
export TOKEN="${live} live / ${archived} archived / ${total} total"

case "${1:-emit}" in
  emit)
    echo "$TOKEN"
    ;;
  --refresh)
    for f in "${FILES[@]}"; do
      [ -f "$f" ] || continue
      perl -0pi -e 's{<!--MEM-COUNT-->.*?<!--/MEM-COUNT-->}{<!--MEM-COUNT-->'"$TOKEN"'<!--/MEM-COUNT-->}gs' "$f"
    done
    echo "refreshed MEM-COUNT → $TOKEN"
    ;;
  --check)
    stale=0
    for f in "${FILES[@]}"; do
      [ -f "$f" ] || continue
      if grep -q '<!--MEM-COUNT-->' "$f" && ! grep -qF "<!--MEM-COUNT-->$TOKEN<!--/MEM-COUNT-->" "$f"; then
        echo "⚠️  stale MEM-COUNT token in ${f#$ROOT/} (SSOT: $TOKEN) — run: memory/mem-count.sh --refresh"
        stale=1
      fi
    done
    [ "$stale" -eq 0 ] && echo "✅  MEM-COUNT tokens consistent ($TOKEN)"
    exit "$stale"
    ;;
  *)
    echo "usage: mem-count.sh [emit|--refresh|--check]" >&2; exit 2
    ;;
esac
