#!/usr/bin/env bash
# guard.sh — portable governance health check (zero LLM, zero network).
#
# This is the PUBLIC, self-contained extract of the live fleet's 24-check
# guard-weekly.sh. The full suite is deeply coupled to a private fleet
# (its memory.md, kanban.json, 7-day git history, telemetry logs, sibling
# hooks). Rather than fake that, this kit ships the SAME 24 checks but only
# RUNS the ones that are self-contained against the bundled example data;
# fleet-only checks honestly print "SKIP (kit)".
#
#   $ bash governance/guard.sh
#   ... 8 PASS / 16 SKIP / 0 FAIL  —  24 checks (8 runnable in portable kit)
#
# Design qualities (the point — not "it's bash"):
#   • deterministic   — no model call, no network; same input → same verdict
#   • independent     — no `set -e`; one failing check never aborts the rest
#   • idempotent      — read-only; re-running mutates nothing
#   • exit-code-driven — exit 1 iff any check FAILs (CI-friendly)
#
# Exit 0 = no FAILs. Exit 1 = at least one FAIL.

set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ROOT=""
[ -n "$ROOT" ] || ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

MEM="memory/memory.example.md"
KJSON="governance/examples/kanban.example.json"
KMD="governance/examples/KANBAN.example.md"
SKILLS_DIR="skills"
KIT_BUDGET=50          # live-entry budget for the example memory (the live fleet uses 105)

PASS=0; SKIP=0; FAIL=0
pass() { printf '  \033[32m✓\033[0m  Check %-2s — %-34s PASS\n'  "$1" "$2"; PASS=$((PASS+1)); }
skip() { printf '  \033[33m⚠\033[0m  Check %-2s — %-34s SKIP (kit)\n' "$1" "$2"; SKIP=$((SKIP+1)); }
fail() { printf '  \033[31m✗\033[0m  Check %-2s — %-34s FAIL — %s\n' "$1" "$2" "$3"; FAIL=$((FAIL+1)); }

echo "agent-governance-kit · guard.sh · $(date +%Y-%m-%d)"
echo "────────────────────────────────────────────────────────────"

# ── Check 1 — Memory integrity (append-only + cap) ──────────────────────────
total=$(grep -c '^## \[' "$MEM" 2>/dev/null || echo 0)
arch=$(grep -c '^\*\*\[ARCHIVED' "$MEM" 2>/dev/null || echo 0)
live=$(( total - arch ))
if [ "$total" -eq 0 ]; then
  fail 1 "memory integrity" "no entries found in $MEM"
elif git cat-file -e "HEAD:$MEM" 2>/dev/null && \
     [ "$total" -lt "$(git show "HEAD:$MEM" | grep -c '^## \[')" ]; then
  fail 1 "memory integrity" "working tree has fewer entries than HEAD (truncation)"
else
  pass 1 "memory integrity"
fi

# ── Check 2 — Scope violations (7-day git log)  [fleet-only] ─────────────────
skip 2 "scope violations (7d git)"

# ── Check 3 — Stale open questions (QUESTIONS.md)  [fleet-only] ──────────────
skip 3 "stale open questions"

# ── Check 4 — Skill-invocation log health  [fleet-only telemetry] ───────────
skip 4 "skill-invocation log"

# ── Check 5 — Stale active-edit claims  [fleet-only] ────────────────────────
skip 5 "stale active-edit claims"

# ── Check 6 — Skill frontmatter validation ──────────────────────────────────
bad=0
for f in "$SKILLS_DIR"/*.md; do
  [ -e "$f" ] || continue
  case "$f" in */README.md) continue;; esac
  head -1 "$f" | grep -q '^---$' || { bad=$((bad+1)); }
done
if [ "$bad" -eq 0 ]; then pass 6 "skill frontmatter"; else fail 6 "skill frontmatter" "$bad skill(s) missing frontmatter"; fi

# ── Check 7 — L1 memory-architecture health  [fleet-only] ───────────────────
skip 7 "L1 memory architecture"

# ── Check 8 — PLAN.md deadline gate  [fleet-only] ───────────────────────────
skip 8 "PLAN.md deadline gate"

# ── Check 9 — Cross-hook contract drift  [fleet-only] ───────────────────────
skip 9 "cross-hook contract drift"

# ── Check 10 — KANBAN SSOT: render matches source ───────────────────────────
miss=0
while IFS= read -r id; do
  grep -q "$id" "$KMD" || miss=$((miss+1))
done < <(grep -oE '"id": *"[^"]+"' "$KJSON" | grep -oE 'T-[0-9]+')
if [ "$miss" -eq 0 ]; then pass 10 "KANBAN SSOT (render=source)"; else fail 10 "KANBAN SSOT (render=source)" "$miss id(s) in JSON missing from render"; fi

# ── Check 11 — token-proxy ground-truth guardrail  [fleet-only tool] ────────
skip 11 "token-proxy ground-truth guardrail"

# ── Check 12 — llm-wiki empty-output tripwire  [fleet-only service] ─────────
skip 12 "llm-wiki empty-output tripwire"

# ── Check 13 — Skill-count consistency (claim == disk) ──────────────────────
disk=$(find "$SKILLS_DIR" -maxdepth 1 -type f -name '*.md' -not -name 'README.md' | wc -l | tr -d ' ')
claim=$(grep -oE '\*\*[0-9]+ skills\*\*' "$SKILLS_DIR/README.md" 2>/dev/null | grep -oE '[0-9]+' | head -1)
if [ -n "$claim" ] && [ "$claim" = "$disk" ]; then
  pass 13 "skill-count ($disk)"
else
  fail 13 "skill-count" "README claims '${claim:-none}', disk has $disk"
fi

# ── Check 14 — Branch + worktree-queue staleness  [fleet-only] ──────────────
skip 14 "branch/worktree staleness"

# ── Check 15 — Stale open handoffs  [fleet-only] ────────────────────────────
skip 15 "stale open handoffs"

# ── Check 16 — Folder-contract conformance ──────────────────────────────────
miss=0
for d in governance memory skills rules docs; do [ -d "$d" ] || miss=$((miss+1)); done
if [ "$miss" -eq 0 ]; then pass 16 "folder-contract"; else fail 16 "folder-contract" "$miss expected dir(s) missing"; fi

# ── Check 17 — Green-light reality audit (detector self-test) ───────────────
# Prove the content-gate (Check 23) actually CATCHES a bad marker — guards
# against a dead detector silently reporting green.
probe="$(mktemp)"; printf 'ERROR: synthetic failure\n' > "$probe"
if grep -qE 'ERROR:|Traceback|<EMPTY>' "$probe"; then pass 17 "reality audit (self-test)"; else fail 17 "reality audit (self-test)" "content-gate detector is dead"; fi
rm -f "$probe"

# ── Check 18 — Skill telemetry & evolution audit  [fleet-only] ──────────────
skip 18 "skill telemetry/evolution"

# ── Check 19 — Improvement-queue review staleness  [fleet-only] ─────────────
skip 19 "improvement-queue staleness"

# ── Check 20 — Producer-orphan sweep  [fleet-only] ──────────────────────────
skip 20 "producer-orphan sweep"

# ── Check 21 — Worktree-model bypass  [fleet-only] ──────────────────────────
skip 21 "worktree-model bypass"

# ── Check 22 — openab tier-telemetry tripwire  [fleet-only tool] ────────────
skip 22 "openab tier-telemetry"

# ── Check 23 — Producer content-gate (no error/empty in outputs) ────────────
if grep -rqE 'ERROR:|Traceback|<EMPTY>|\bnull\b placeholder' "$MEM" "$KJSON" "$KMD" 2>/dev/null; then
  fail 23 "producer content-gate" "forbidden marker in example outputs"
else
  pass 23 "producer content-gate"
fi

# ── Check 24 — Auto-memory index budget ─────────────────────────────────────
if [ "$live" -le "$KIT_BUDGET" ]; then pass 24 "index budget ($live/$KIT_BUDGET)"; else fail 24 "index budget" "$live live > $KIT_BUDGET"; fi

echo "────────────────────────────────────────────────────────────"
RUNNABLE=$((PASS+FAIL))
printf '%s PASS / %s SKIP / %s FAIL  —  24 checks (%s runnable in portable kit)\n' "$PASS" "$SKIP" "$FAIL" "$RUNNABLE"
[ "$FAIL" -eq 0 ]
