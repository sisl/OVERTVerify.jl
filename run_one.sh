#!/usr/bin/env bash
set -u  # don't use -e here, because we want this script to return failure codes cleanly

CONFIG="${1:?Usage: $0 path/to/config.toml}"
CONFIG_DIR="$(cd "$(dirname "$CONFIG")" && pwd)"
REPO_ROOT="$(cd "$CONFIG_DIR/.." && pwd)"   # if configs/ is directly under repo root; adjust if not
CONFIG_ABS="$(cd "$(dirname "$CONFIG")" && pwd)/$(basename "$CONFIG")"


cd "$REPO_ROOT"


# Extract run_id for naming (simple grep/sed; assumes run_id is on its own line)
RUN_ID="$(sed -n 's/^[[:space:]]*run_id[[:space:]]*=[[:space:]]*"\(.*\)".*/\1/p' "$CONFIG_ABS" | head -n 1)"
if [[ -z "${RUN_ID}" ]]; then
  echo "ERROR: run_id not found in $CONFIG" >&2
  exit 2
fi

SCRIPT="$(sed -n 's/^[[:space:]]*script[[:space:]]*=[[:space:]]*"\(.*\)".*/\1/p' "$CONFIG_ABS" | head -n 1)"
PROJECT="$(sed -n 's/^[[:space:]]*project[[:space:]]*=[[:space:]]*"\(.*\)".*/\1/p' "$CONFIG_ABS" | head -n 1)"

if [[ -z "${SCRIPT}" ]]; then
  echo "ERROR: script not found in $CONFIG" >&2
  exit 2
fi

# Default project if omitted
if [[ -z "${PROJECT}" ]]; then
  PROJECT="."
fi


mkdir -p logs/transcripts logs/status logs/metrics

STAMP="$(date -u -Is | tr ':' '-')"
EXEC_ID="${RUN_ID}__${STAMP}"


LOG="logs/transcripts/${EXEC_ID}.log"
STATUS="logs/status/${EXEC_ID}.status"


{
  echo "=== RUN START $(date -Is) ==="
  echo "run_id: ${RUN_ID}"
  echo "config: ${CONFIG}"
  echo "Absolute config path: ${CONFIG_ABS}"
  echo "--- config contents ---"
  cat "$CONFIG_ABS"
  echo "--- end config ---"
  echo "script: ${SCRIPT}"
  echo "project: ${PROJECT}"
  echo
} | tee -a "$LOG"

# Run the Julia experiment; pass both RUN_ID and CONFIG to Julia
# pipefail ensures Julia's exit code is preserved through tee.
set -o pipefail
julia --project="${PROJECT}" "${SCRIPT}" "$EXEC_ID" "$CONFIG_ABS" 2>&1 | tee -a "$LOG"
EXIT_CODE=${PIPESTATUS[0]}


# Record status in a machine-readable way
{
  echo "exec_id=${EXEC_ID}"
  echo "run_id=${RUN_ID}"
  echo "config=${CONFIG_ABS}"
  echo "log=${LOG}"
  echo "exit_code=${EXIT_CODE}"
  echo "finished_at=$(date -Is)"
} > "$STATUS"

if [[ $EXIT_CODE -eq 0 ]]; then
  echo "=== RUN OK $(date -Is) ===" | tee -a "$LOG"
else
  echo "=== RUN FAIL exit_code=${EXIT_CODE} $(date -Is) ===" | tee -a "$LOG"
fi

exit "$EXIT_CODE"