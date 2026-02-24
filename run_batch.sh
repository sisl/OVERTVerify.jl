#!/usr/bin/env bash
set -u  # do not set -e; we want to continue on failures

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 configs/a.toml [configs/b.toml ...]" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_ONE="${SCRIPT_DIR}/run_one.sh"

if [[ ! -x "$RUN_ONE" ]]; then
  echo "ERROR: run_one.sh not found or not executable at: $RUN_ONE" >&2
  exit 2
fi


CONFIGS=()

if [[ $# -eq 1 && -d "$1" ]]; then
  CONFIG_DIR_ABS="$(cd "$1" && pwd)"

  while IFS= read -r f; do
    CONFIGS+=("$f")
  done < <(find "$CONFIG_DIR_ABS" -maxdepth 1 -type f -name "*.toml" | LC_ALL=C sort)

  if [[ ${#CONFIGS[@]} -eq 0 ]]; then
    echo "ERROR: No .toml config files found in directory: $CONFIG_DIR_ABS" >&2
    exit 2
  fi
else
  # Explicit file list: convert each to absolute path immediately
  for f in "$@"; do
    f_abs="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
    CONFIGS+=("$f_abs")
  done
fi


# Helpers
csv_escape() {
  # Escapes a value for CSV: wrap in quotes, double internal quotes
  local s="${1:-}"
  s="${s//\"/\"\"}"
  printf "\"%s\"" "$s"
}

# Establish repo root based on first config path (assumes configs/ is under repo root)
FIRST_CONFIG="${CONFIGS[0]}"
FIRST_CONFIG_DIR="$(cd "$(dirname "$FIRST_CONFIG")" && pwd)"
REPO_ROOT="$(cd "$FIRST_CONFIG_DIR/.." && pwd)"
cd "$REPO_ROOT"

mkdir -p logs/status logs/transcripts

BATCH_ID="batch_$(date -u -Is | tr ':' '-')"
SUMMARY="logs/status/${BATCH_ID}_summary.csv"

# Header (include pointers to artifacts)
echo "exec_id,run_id,config,exit_code,started_at,finished_at,log,status" > "$SUMMARY"

# Validate inputs up front (optional but helpful)
for CONFIG_ABS in "${CONFIGS[@]}"; do
  if [[ ! -f "$CONFIG_ABS" ]]; then
    echo "ERROR: Config not found: $CONFIG_ABS" >&2
    exit 2
  fi
done

for CONFIG_ABS in "${CONFIGS[@]}"; do
  STARTED_AT="$(date -u -Is)"

  # Marker to deterministically locate the status file created by this run
  MARKER="logs/status/.${BATCH_ID}_marker_$(date -u +%s%N)"
  : > "$MARKER"

  # Run one experiment; do not stop the batch on failure
  "$RUN_ONE" "$CONFIG_ABS"
  RUN_ONE_EXIT_CODE=$?

  # Find the status file created after the marker
  # Expected: exactly one .status file per run.
  STATUS_FILE="$(
    find logs/status -maxdepth 1 -type f -name "*.status" -newer "$MARKER" -printf "%T@ %p\n" \
      | sort -n \
      | tail -n 1 \
      | awk '{print $2}'
  )"

  rm -f "$MARKER"

  if [[ -z "${STATUS_FILE:-}" || ! -f "$STATUS_FILE" ]]; then
    # If this happens, something broke in run_one or multiple jobs are writing status concurrently.
    # Still record a row with minimal info.
    echo "$(csv_escape "")","$(csv_escape "")","$(csv_escape "$CONFIG_ABS")","$(csv_escape "$RUN_ONE_EXIT_CODE")","$(csv_escape "$STARTED_AT")","$(csv_escape "")","$(csv_escape "")","$(csv_escape "")" >> "$SUMMARY"
    echo "WARN: Could not locate status file for config: $CONFIG_ABS" >&2
    continue
  fi

  # Parse key=value lines from the status file
  exec_id="$(grep -E '^exec_id=' "$STATUS_FILE" | head -n 1 | cut -d= -f2-)"
  run_id="$(grep -E '^run_id='  "$STATUS_FILE" | head -n 1 | cut -d= -f2-)"
  cfg_in_status="$(grep -E '^config=' "$STATUS_FILE" | head -n 1 | cut -d= -f2-)"
  log_path="$(grep -E '^log='    "$STATUS_FILE" | head -n 1 | cut -d= -f2-)"
  exit_code="$(grep -E '^exit_code=' "$STATUS_FILE" | head -n 1 | cut -d= -f2-)"
  finished_at="$(grep -E '^finished_at=' "$STATUS_FILE" | head -n 1 | cut -d= -f2-)"

  # Prefer the exit_code recorded by run_one/status (source of truth),
  # but fall back to run_one.sh process exit if missing.
  if [[ -z "${exit_code:-}" ]]; then
    exit_code="$RUN_ONE_EXIT_CODE"
  fi

  # Write a row to the batch summary
  echo \
    "$(csv_escape "$exec_id"),$(csv_escape "$run_id"),$(csv_escape "${cfg_in_status:-$CONFIG_ABS}"),$(csv_escape "$exit_code"),$(csv_escape "$STARTED_AT"),$(csv_escape "$finished_at"),$(csv_escape "$log_path"),$(csv_escape "$STATUS_FILE")" \
    >> "$SUMMARY"
done

echo "Batch complete."
echo "Summary: $SUMMARY"
