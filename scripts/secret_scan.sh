#!/usr/bin/env bash
set -euo pipefail

OUT="secret-scan-findings.txt"
> "$OUT"

# Where to scan (exclude binary folders, build dirs)
SCAN_PATHS="."
EXCLUDES="(\.git|target|build|node_modules|\.venv|dist|out|\.idea)"

# common regex patterns (tweak to match your org)
declare -a patterns=(
  # AWS Access Key ID (AKIA...)
  "AKIA[0-9A-Z]{16}"
  # AWS Secret Access Key (40 base64-like chars)
  "([A-Za-z0-9/+=]{40})"
  # Generic-looking API keys (long base64 strings)
  "([A-Za-z0-9\-_]{20,})"
  # JWT-looking tokens (three base64 segments separated by dots)
  "[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+"
  # Private key header (PEM)
  "-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----"
  # RSA public/private key inlined
  "PRIVATE_KEY|PRIVATE-KEY|ssh-rsa|BEGIN RSA PRIVATE KEY"
  # common password properties
  "(password|passwd|pwd|secret|apikey|api_key)\s*[:=]\s*.+"
  # Google service account JSON (client_email and private_key)
  "\"private_key\"\\s*:\\s*\"-----BEGIN PRIVATE KEY-----"
  # Basic auth credentials in URL (http://user:pass@)
  "https?:\/\/[^\/:\s]+:[^\/@\s]+@"
)

# Grep command base
GREP_CMD="grep -RInP"

echo "Scanning codebase for potential hard-coded secrets..." | tee -a "$OUT"

# build the --exclude-dir args
EXCLUDE_ARGS=()
for ex in $(echo $EXCLUDES | tr '|' ' '); do
  EXCLUDE_ARGS+=(--exclude-dir="$ex")
done

# Scan by pattern
for pat in "${patterns[@]}"; do
  echo "Searching for pattern: $pat" >> "$OUT"
  # search text files only; ignore binary
  eval "$GREP_CMD \"${pat}\" $SCAN_PATHS ${EXCLUDE_ARGS[*]} --binary-files=without-match || true" >> "$OUT" || true
done

# Filter out obvious false positives (add more rules if needed)
# Example: skip matches in README badges or in test fixtures marked as safe
# (Adjust this section to your project's needs)
# sed -i '/some-safe-pattern/d' "$OUT"

# Count findings
FINDINGS=$(wc -l < "$OUT" | tr -d ' ')
if [ "$FINDINGS" -gt 0 ]; then
  echo "Hard-coded secret scanner found $FINDINGS matches. See $OUT for details."
  cat "$OUT" | sed -n '1,200p'
  # exit non-zero to fail the job (enforce fix)
  exit 2
else
  echo "No obvious hard-coded secrets found by custom scanner."
  rm -f "$OUT"
  exit 0
fi
