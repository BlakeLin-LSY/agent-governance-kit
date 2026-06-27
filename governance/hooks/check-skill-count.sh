#!/usr/bin/env bash
# check-skill-count.sh — assert every stated skill count matches the canonical
# invocable-skill count.
#
# CANONICAL = number of *.md files in skills/ MINUS non-invocable
# reference docs (DENYLIST). SYNC-SKILLS-MAP.md lives in the skills dir but is a
# reference map, explicitly "Reference only (not invoked)" in the skills map —
# it is NOT a skill. So:  invocable skills = .md files − reference docs.
#
# Why this exists (recurring "L-status drift"): 
# the docs each state a skill count that drifts independently of reality
# whenever a skill is added/retired and only some call sites get updated. The two
# numbers also track DIFFERENT definitions (file count 53 vs invocable 52), so
# writers conflate them. This binds every authoritative claim to ONE computed
# number. Principle: bind every count claim to a computed number.
#
# Distinct from check-skill-drift.sh: that verifies file SYNC (canonical dir vs
# the synced skills dir, counts all files). This verifies the stated
# COUNT (invocable skills) matches across the docs that claim it.
#
# Exit 0 = all claims match canonical. Exit 1 = mismatch(es) listed.
# Usage:  bash governance/hooks/check-skill-count.sh
#
# Wired into: the guard suite + pre-commit. Reusable in pre-commit
# (scope to when docs that claim the count are staged).

set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

SKILLS_DIR="skills"
# Non-invocable reference docs that live in the skills dir but are not skills.
# Add here if another reference-only doc is ever placed under skills/.
DENYLIST=(README.md)

# ── Canonical count ────────────────────────────────────────────────────────
# Exclude hidden files (-not -name '.*'): a skill is never a dotfile, and audit
# artifacts like .solid-audit.md live here. This matches the shell-glob semantics
# of check-skill-drift.sh (`for src in "$CANONICAL"/*.md`), which skips dotfiles.
FILE_COUNT=$(find "$SKILLS_DIR" -maxdepth 1 -type f -name '*.md' -not -name '.*' 2>/dev/null | wc -l | tr -d ' ')
DENY_PRESENT=0
for d in "${DENYLIST[@]}"; do
  [ -f "$SKILLS_DIR/$d" ] && DENY_PRESENT=$((DENY_PRESENT + 1))
done
CANON=$((FILE_COUNT - DENY_PRESENT))

# ── Authoritative claim sources: file | ERE | label ───────────────────────
# Each regex must contain exactly one integer = the claimed skill count.
# Patterns are scoped to the AUTHORITATIVE count phrases so file-count notes
# (e.g. "53 .md files") and history rows (e.g. "53→52") never false-positive.
CLAIMS=(
  "skills/README.md|\*\*[0-9]+ skills\*\*|skills/README 'N skills'"
  "README.md|[0-9]+ curated skills|README 'N curated skills'"
)

MISMATCH=0
NOTFOUND=0
echo "Canonical invocable skill count: $CANON  (${FILE_COUNT} .md files − ${DENY_PRESENT} reference doc: ${DENYLIST[*]})"

for entry in "${CLAIMS[@]}"; do
  IFS='|' read -r file regex label <<< "$entry"
  [ -f "$file" ] || { echo "⚠️   $file — not found"; NOTFOUND=$((NOTFOUND + 1)); continue; }
  found=0
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    found=1
    lineno=${hit%%:*}
    num=$(printf '%s' "$hit" | grep -oE "$regex" | grep -oE '[0-9]+' | head -1)
    if [ "$num" != "$CANON" ]; then
      echo "❌  $file:$lineno — $label claims $num, canonical is $CANON"
      MISMATCH=$((MISMATCH + 1))
    fi
  done < <(grep -nE "$regex" "$file" 2>/dev/null)
  if [ "$found" -eq 0 ]; then
    echo "⚠️   $file — no \"$label\" claim found (authoritative anchor may have drifted)"
    NOTFOUND=$((NOTFOUND + 1))
  fi
done

echo ""
if [ "$MISMATCH" -eq 0 ]; then
  echo "✅  All skill-count claims match canonical ($CANON). Summary: 0 drift(s), ${NOTFOUND} missing-anchor warning(s)"
  exit 0
fi
echo "Summary: $MISMATCH skill-count claim(s) drift from canonical $CANON"
echo "    Fix: reconcile the flagged line(s) to $CANON, or update DENYLIST if a non-skill was added to $SKILLS_DIR"
exit 1
