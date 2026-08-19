#!/usr/bin/env bash
# ============================================================
# Code Security Audit — Comprehensive SAST Scan
# Defensive-only. Scans source code owned by the user and
# produces machine-readable JSON reports for triage.
# ============================================================
set -uo pipefail

TARGET_DIR="${1:-.}"
OUT_DIR="${2:-./security-scan-results}"
mkdir -p "$OUT_DIR"

echo "=============================================="
echo " Code Security Audit"
echo " Target: $TARGET_DIR"
echo " Output: $OUT_DIR"
echo "=============================================="

run_if_available () {
  local tool_name="$1"
  shift
  if command -v "$tool_name" >/dev/null 2>&1; then
    echo "[*] Running $tool_name ..."
    "$@" || echo "[!] $tool_name finished with warnings/findings (non-zero exit is expected)"
  else
    echo "[skip] $tool_name not installed — skipping. (install instructions in references/tools-by-language.md)"
  fi
}

# ---- 1. Secrets detection (always run first, cheapest + highest signal) ----
run_if_available gitleaks gitleaks detect --source "$TARGET_DIR" \
  --report-format json --report-path "$OUT_DIR/gitleaks.json" --no-git

# ---- 2. Multi-language static analysis ----
run_if_available semgrep semgrep --config=auto --json \
  -o "$OUT_DIR/semgrep.json" "$TARGET_DIR"

# ---- 3. Python-specific ----
if find "$TARGET_DIR" -name "*.py" -print -quit | grep -q .; then
  run_if_available bandit bandit -r "$TARGET_DIR" -f json -o "$OUT_DIR/bandit.json"
  run_if_available pip-audit pip-audit -f json -o "$OUT_DIR/pip-audit.json" 2>/dev/null
fi

# ---- 4. Node/JS dependency audit ----
if [ -f "$TARGET_DIR/package.json" ]; then
  echo "[*] Running npm audit ..."
  (cd "$TARGET_DIR" && npm audit --json > "$OUT_DIR/npm-audit.json" 2>/dev/null) \
    || echo "[!] npm audit finished with findings"
fi

# ---- 5. Shell scripts ----
if find "$TARGET_DIR" -name "*.sh" -print -quit | grep -q .; then
  run_if_available shellcheck bash -c \
    "shellcheck -f json $(find "$TARGET_DIR" -name '*.sh') > '$OUT_DIR/shellcheck.json'"
fi

# ---- 6. Containers / IaC ----
if [ -f "$TARGET_DIR/Dockerfile" ] || find "$TARGET_DIR" -name "*.tf" -print -quit | grep -q .; then
  run_if_available trivy trivy fs --security-checks vuln,config,secret \
    --format json -o "$OUT_DIR/trivy.json" "$TARGET_DIR"
fi

echo "=============================================="
echo " Scan complete. Raw JSON reports in: $OUT_DIR"
echo " Next: parse + triage results, classify severity,"
echo " and remove false positives before reporting."
echo "=============================================="
