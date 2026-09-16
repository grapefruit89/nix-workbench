#!/usr/bin/env bash
# repo-sanity — the single objective drift guard (Phase 3.6, 2026-09-16).
#
# Git is the ONLY change-truth (no snapshots, no second banlist, no deps).
# Chain: DECLARED SCOPE -> ACTUAL GIT DIFF -> CHANGE BUDGET -> PROTECTED PATHS.
# A global emergency ceiling is NOT implemented: without a declared scope the
# per-check budgets are N/A, and with a declared scope the budgets ARE the
# brake — a bare %-limit adds nothing the scope check doesn't already catch.
#
# PASS is only ever reported for a check that actually ran and passed.
# Anything unrunnable becomes UNVERIFIED -> overall RESULT BLOCKED, exit 1.
#
# Usage:
#   repo-sanity.sh                      # structural + banlist + existing scans
#   repo-sanity.sh <scope.yaml>         # + scope/change-budget/protected checks
#
# scope.yaml (minimal subset):
#   allowed:
#     - 51-ingress/511-caddy.nix
#   max_files: 3
#   max_added_lines: 80
#   max_deleted_lines: 40

set -u

CANONICAL="medinix-authoring medinix-debug medinix-discipline medinix-nix medinix-review medinix-verify"

# Banlist: executable form of THE binding list (mediNix review §6 — the list
# itself is defined THERE, not redefined here). The two LAN entries are
# written as full host IPs: RFC1918 CIDR notation (x.x.x.x/nn) is generic
# block notation, not a host value. mkOption `example =` lines are allowed
# by governance (generic example values) and are excluded.
BANLIST='q958|jarvis|moritz|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|10\.8\.[0-9]{1,3}\.[0-9]{1,3}|m7c5\.de|privado|/opt/data|Tower|hermes'
# Exemptions: governance-allowed mkOption example values, RFC1918 CIDR block
# notation (x.x.x.x/nn = generic block, not a host value), and structurally
# canonical per-skill files (SKILL.md/.gitkeep) in the duplicate scan.
EXEMPT='example[[:space:]]*=|192\.168\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]+|10\.8\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]+'
DUP_EXEMPT='\.gitkeep|/SKILL\.md'

# Protected: critical core (change = flagged as elevated intervention,
# needs explicit owner Go — complements permission edit=ask).
PROTECTED='lib/registry.nix|lib/service-factory.nix|lib/hardening-profiles.nix|lib/creds.nix|flake.nix|opencode.jsonc|56-agents/'

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "REPO-SANITY"
  echo "RESULT        BLOCKED"
  echo "REASON        not inside a git repository/worktree"
  exit 1
}

fail() { echo "RESULT        FAIL"; echo "REASON        $1"; exit 1; }
unverified() { echo "RESULT        BLOCKED"; echo "REASON        $1"; exit 1; }

out=()
result_ok=1

# ── A — repository structure ────────────────────────────────────────────────
found=$(find 56-agents -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
expected=$(echo "shared $CANONICAL" | tr ' ' '\n' | sort)
if [ "$found" = "$expected" ]; then
  out+=("STRUCTURE     PASS")
else
  out+=("STRUCTURE     FAIL (unexpected/missing: $(comm -13 <(echo "$expected") <(echo "$found") | tr '\n' ',' )$(comm -23 <(echo "$expected") <(echo "$found") | tr '\n' ','))")
  result_ok=0
fi

# ── B — portability banlist over tracked .nix files ────────────────────────
viol=$(git ls-files '*.nix' | xargs -r grep -n -E "$BANLIST" 2>/dev/null | grep -v -E "$EXEMPT")
if [ -z "$viol" ]; then
  out+=("BANLIST       PASS")
else
  out+=("BANLIST       FAIL ($viol)")
  result_ok=0
fi

# ── C — existing checks, invoked not duplicated ────────────────────────────
# NIXMETA + docs: medinix-meta check / check-docs (NOT rebuilt here — the
# agent runs them per VERIFY; they are listed for the caller, not re-run.)

# duplicates via the (now worktree-safe) existing scanner
if dup_out=$(python3 56-agents/shared/scripts/scan_duplicates.py 2>&1); then
  # detail lines only ("  name: [...]"); exempt canonical structural files
  dup_bad=$(echo "$dup_out" | grep -E "^  .+: " | grep -v -E "$DUP_EXEMPT" || true)
  if [ -z "$dup_bad" ]; then
    out+=("DUPLICATES    PASS")
  else
    out+=("DUPLICATES    FAIL ($dup_bad)")
    result_ok=0
  fi
else
  out+=("DUPLICATES    UNVERIFIED (scanner not runnable)")
  result_ok=0
fi

# inconsistencies via the existing scanner
if inc_out=$(python3 56-agents/shared/scripts/scan_inconsistencies.py 2>&1); then
  inc_bad=$(echo "$inc_out" | grep -E "unique issues: [1-9]" || true)
  if [ -z "$inc_bad" ]; then
    out+=("INCONSIST     PASS")
  else
    out+=("INCONSIST     FAIL ($inc_bad)")
    result_ok=0
  fi
else
  out+=("INCONSIST     UNVERIFIED (scanner not runnable)")
  result_ok=0
fi

# ── GIT-DIFF hygiene ───────────────────────────────────────────────────────
if git diff --check > /tmp/opencode/reposanity.diffcheck 2>&1; then
  out+=("GIT-DIFF      PASS")
else
  out+=("GIT-DIFF      FAIL ($(cat /tmp/opencode/reposanity.diffcheck | head -3))")
  result_ok=0
fi

# ── D/E — scope, change budget, protected paths (optional) ─────────────────
scope_file="${1:-}"
if [ -n "$scope_file" ]; then
  [ -f "$scope_file" ] || fail "scope file not found: $scope_file"
  allowed=$(sed -n '/^allowed:/,/^[a-z_]*:/p' "$scope_file" | grep -E '^\s+- ' | sed 's/^ *- *//')
  max_files=$(grep -E '^max_files:' "$scope_file" | sed 's/[^0-9]*//g')
  max_add=$(grep -E '^max_added_lines:' "$scope_file" | sed 's/[^0-9]*//g')
  max_del=$(grep -E '^max_deleted_lines:' "$scope_file" | sed 's/[^0-9]*//g')

  changed=$( { git diff --name-only HEAD; git status --porcelain | awk '$1 ~ /^\?\?/ {print $2}'; } | sort -u )
  n_changed=$(echo "$changed" | grep -c . || true)

  unexpected=$(comm -23 <(echo "$changed") <(echo "$allowed" | sort))
  n_unexpected=$(echo "$unexpected" | grep -c . || true)
  if [ "$n_unexpected" = 0 ]; then
    out+=("SCOPE         PASS")
  else
    out+=("SCOPE         FAIL ($n_unexpected unexpected: $(echo "$unexpected" | tr '\n' ','))")
    result_ok=0
  fi

  prot=$(echo "$changed" | grep -E "$PROTECTED" || true)
  if [ -z "$prot" ]; then
    out+=("PROTECTED     PASS")
  else
    out+=("PROTECTED     FAIL (elevated intervention, owner Go required: $prot)")
    result_ok=0
  fi

  n_add=$(git diff --numstat HEAD | awk '{a+=$1} END {print a+0}')
  n_del=$(git diff --numstat HEAD | awk '{d+=$2} END {print d+0}')
  budget_ok=1
  [ -n "$max_files" ] && [ "$n_changed" -gt "$max_files" ] && budget_ok=0
  [ -n "$max_add" ] && [ "${n_add:-0}" -gt "$max_add" ] && budget_ok=0
  [ -n "$max_del" ] && [ "${n_del:-0}" -gt "$max_del" ] && budget_ok=0
  if [ "$budget_ok" = 1 ]; then
    out+=("CHANGE-BUDGET PASS (files:$n_changed +$n_add -$n_del)")
  else
    out+=("CHANGE-BUDGET FAIL (planned max_files:$max_files max_added:$max_add max_deleted:$max_del — actual files:$n_changed +$n_add -$n_del)")
    result_ok=0
  fi
else
  out+=("SCOPE         N/A (no scope declared)")
  out+=("PROTECTED     N/A (no scope declared)")
  out+=("CHANGE-BUDGET N/A (no scope declared)")
fi

echo "REPO-SANITY"
printf '%s\n' "${out[@]}"
if [ "$result_ok" = 1 ]; then
  echo "RESULT        PASS"
  exit 0
fi
echo "RESULT        FAIL"
exit 1
