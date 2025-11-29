#!/usr/bin/env bash
#
# reset-pipeline-state.sh - Reset pipeline state to IDLE
#
# Usage: reset-pipeline-state.sh [reason]
#
# Useful for manual intervention when pipeline gets stuck

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Source namespace utilities for namespace-aware paths
# shellcheck source=namespace-utils.sh
source "${HOME}/.claude/scripts/namespace-utils.sh"

# Get namespace-aware paths (supports CLAUDE_TASK_NAMESPACE env var)
STATE_DIR="$(get_state_dir)"
STATE_FILE="$(get_state_file)"
JOURNAL_FILE="$(get_journal_file)"

#######################################
# Write entry to journal file for debugging
#######################################
function journal_write() {
  local -r event_type="$1"
  local -r message="$2"
  local -r timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  mkdir -p "$(dirname "${JOURNAL_FILE}")"
  printf '%s\t%s\t%s\t%s\n' \
    "${timestamp}" "${event_type}" "${SCRIPT_NAME}" "${message}" \
    >> "${JOURNAL_FILE}" 2>/dev/null || true
}

function log_message() {
  local -r message="$1"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [${SCRIPT_NAME}] ${message}" >&2
}

function reset_state() {
  local -r reason="${1:-Manual reset}"
  local -r timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  
  if [[ ! -f "${STATE_FILE}" ]]; then
    log_message "No state file exists, nothing to reset"
    return 0
  fi
  
  # Read current state for history
  local current_state_json
  if ! current_state_json="$(cat "${STATE_FILE}")"; then
    log_message "ERROR: Failed to read state file"
    return 1
  fi
  
  local -r current_state="$(echo "${current_state_json}" | jq -r '.state // "UNKNOWN"')"
  
  # Create reset state with history entry
  local -r escaped_reason="$(echo "${reason}" | jq -Rs .)"
  local reset_state_json
  reset_state_json="$(echo "${current_state_json}" | jq \
    --arg timestamp "${timestamp}" \
    --argjson reason "${escaped_reason}" \
    --arg state_before "${current_state}" \
    '
    .state = "IDLE" |
    .timestamp = $timestamp |
    .context = {
      "gathered": "",
      "refined": "",
      "orchestration": ""
    } |
    .history += [{
      "agent": "reset",
      "timestamp": $timestamp,
      "state_before": $state_before,
      "state_after": "IDLE",
      "reason": $reason
    }]
    ')"
  
  # Write atomically
  local -r backup_file="${STATE_FILE}.backup"
  if ! cp "${STATE_FILE}" "${backup_file}"; then
    log_message "ERROR: Failed to create backup"
    return 1
  fi
  
  if ! echo "${reset_state_json}" > "${STATE_FILE}"; then
    log_message "ERROR: Failed to write reset state"
    return 1
  fi
  
  log_message "Pipeline state reset: ${current_state} → IDLE"
  journal_write "MANUAL_RESET" "from=${current_state} reason=${reason}"
  echo "Pipeline state reset to IDLE"
  echo "Backup saved to: ${backup_file}"
  return 0
}

function main() {
  if ! command -v jq >/dev/null 2>&1; then
    log_message "ERROR: jq is required but not installed"
    return 1
  fi

  # Migrate legacy state and ensure namespace directory exists
  migrate_legacy_state 2>/dev/null || true
  ensure_namespace_dir 2>/dev/null || true

  echo "Using namespace: $(get_namespace)"

  local -r reason="${1:-Manual reset}"
  reset_state "${reason}"
}

main "$@"
