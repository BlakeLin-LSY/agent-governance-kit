#!/usr/bin/env bash
# check-memory-integrity.sh — write-time guard for memory.md
#
# Run this after an agent writes memory directly, before git add memory/memory.example.md.
# The pre-commit hook catches violations at commit time, but agents write
# files directly — this script catches violations before staging.
#
# Usage:  bash governance/hooks/check-memory-integrity.sh
# Exit 0: clean — current file has >= HEAD entry count + new entries have anchors
# Exit 1: violation — truncation detected OR new entries missing Command Anchor
#
# MEMORY_TRIAGE=1: bypass all checks (intentional L0 triage commits only)

set -uo pipefail
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || true

# MEMORY path is overridable for smoke-testing (T-GUARD-2). Defaults to the
# bundled example memory.
MEMORY="${MEMORY_PATH:-memory/memory.example.md}"

# Bypass for intentional triage
if [ "${MEMORY_TRIAGE:-0}" = "1" ]; then
  echo "⚠️  MEMORY_TRIAGE=1: skipping integrity checks (intentional triage)"
  exit 0
fi

# HEAD comparison only when a git HEAD version exists. The cap check below
# runs regardless so fixture-based smoke tests work.
HEAD_COUNT=0
HAVE_HEAD=0
if git cat-file -e "HEAD:${MEMORY}" 2>/dev/null; then
  HAVE_HEAD=1
  HEAD_COUNT=$(git show "HEAD:${MEMORY}" | grep -c '^## \[' || true)
  HEAD_COUNT=${HEAD_COUNT:-0}
fi

CURR_COUNT=$(grep -c '^## \[' "${MEMORY}" 2>/dev/null || true)
CURR_COUNT=${CURR_COUNT:-0}

# Live entries = total headers minus headers bearing an [ARCHIVED] marker.
# memory-archive.py adds exactly one `**[ARCHIVED ...]**` line per archived
# entry, so the marker count is a faithful proxy for archived-entry count.
# T-MEM-2 (2026-05-19): cap check below uses LIVE_COUNT not CURR_COUNT so
# marker-archived entries no longer consume budget against the 105 cap.
ARCHIVED_COUNT=$(grep -c '^\*\*\[ARCHIVED' "${MEMORY}" 2>/dev/null || true)
ARCHIVED_COUNT=${ARCHIVED_COUNT:-0}
LIVE_COUNT=$(( CURR_COUNT - ARCHIVED_COUNT ))

if [ "${HAVE_HEAD}" -eq 1 ] && [ "${CURR_COUNT}" -lt "${HEAD_COUNT}" ]; then
  echo ""
  echo "❌  INTEGRITY VIOLATION — memory.md has been overwritten"
  echo ""
  echo "    HEAD:    ${HEAD_COUNT} entries"
  echo "    Current: ${CURR_COUNT} entries"
  echo "    Missing: $((HEAD_COUNT - CURR_COUNT)) entry/entries"
  echo ""
  echo "    Fix: git checkout -- ${MEMORY}"
  echo "    Then append new entries manually at the bottom."
  echo ""
  echo "    Deleted headers:"
  diff <(git show "HEAD:${MEMORY}" | grep '^## \[') \
       <(grep '^## \[' "${MEMORY}" || true) \
    | grep '^<' | sed 's/^< /      /' | head -10
  echo ""
  exit 1
fi

if [ "${LIVE_COUNT}" -gt 105 ]; then
  echo ""
  echo "❌  INTEGRITY VIOLATION — memory.md live entries exceed the 105 cap"
  echo ""
  echo "    Live:     ${LIVE_COUNT} entries (total ${CURR_COUNT} − archived ${ARCHIVED_COUNT})"
  echo "    Limit:    105 entries"
  echo ""
  echo "    Fix: Run bash memory/memory-archive.py to mark older entries [ARCHIVED]."
  echo ""
  exit 1
fi

echo "✅  memory.md intact — ${LIVE_COUNT} live + ${ARCHIVED_COUNT} archived (total ${CURR_COUNT}, HEAD: ${HEAD_COUNT})"

# === MEM-COUNT token consistency — warn if any consumer's count drifted ===
if [ -f memory/mem-count.sh ]; then
  bash memory/mem-count.sh --check || true   # warn-only; never block the critical path
fi

# === Action-Verified Gate ===
# New entries (in current but not in HEAD) must contain a Command Anchor.
# Anchor types: git commit hash (7-40 hex), file path (governance/|memory/|skills/|rules/|docs/),
#               or verified output symbol (✅|❌|⚠️) with surrounding context.

# Skip the gate when no HEAD baseline exists — cannot define "new" vs "baseline".
# This is the smoke-test path (fixtures not in git).
if [ "${HAVE_HEAD}" -eq 0 ]; then
  exit 0
fi

NEW_HEADERS=$(diff \
  <(git show "HEAD:${MEMORY}" | grep '^## \[' || true) \
  <(grep '^## \[' "${MEMORY}" || true) \
  | grep '^>' | sed 's/^> //' || true)

if [ -z "${NEW_HEADERS}" ]; then
  exit 0
fi

GATE_FAILURES=0
while IFS= read -r header; do
  [ -z "${header}" ] && continue
  START=$(grep -nF "${header}" "${MEMORY}" | head -1 | cut -d: -f1)
  if [ -n "${START}" ]; then
    BODY=$(sed -n "$((START+1)),$((START+30))p" "${MEMORY}")
    if ! echo "${BODY}" | grep -qE '([0-9a-f]{7,40}|governance/|memory/|skills/|rules/|docs/|✅|❌|⚠️)'; then
      echo "⚠️  No Command Anchor in new entry: ${header}"
      GATE_FAILURES=$((GATE_FAILURES + 1))
    fi
  fi
done <<< "${NEW_HEADERS}"

if [ "${GATE_FAILURES}" -gt 0 ]; then
  echo ""
  echo "❌  ACTION-VERIFIED GATE: ${GATE_FAILURES} new entry/entries missing Command Anchor"
  echo "    Each new memory entry must contain one of:"
  echo "    • git commit hash (7-40 hex chars)"
  echo "    • file path (governance/|memory/|skills/|rules/|docs/)"
  echo "    • verified output symbol (✅ ❌ ⚠️) with context"
  echo ""
  exit 1
fi

exit 0
