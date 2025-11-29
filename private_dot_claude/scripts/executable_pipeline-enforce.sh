#!/usr/bin/env bash
#
# pipeline-enforce.sh - Enforce pipeline advancement
#
# Called by PreToolUse hook for non-Bash tools
# Blocks tool use when pipeline requires advancement before other actions
#
# Exit codes:
#   0 - Tool allowed
#   2 - Tool blocked (pipeline advancement required)

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly STATE_FILE="${HOME}/.claude/state/pipeline-state.json"
readonly JOURNAL_FILE="${HOME}/.claude/state/pipeline-journal.log"

#######################################
# Log message to stderr with timestamp
#######################################
function log_message() {
  local -r message="$1"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [${SCRIPT_NAME}] ${message}" >&2
}

#######################################
# Write entry to journal file
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

#######################################
# Block tool with message
#######################################
function block_tool() {
  local -r reason="$1"
  log_message "BLOCKED: ${reason}"
  journal_write "ENFORCE_BLOCK" "${reason}"

  local -r escaped_reason="$(echo "${reason}" | jq -Rs .)"
  cat <<EOF
{
  "decision": "block",
  "reason": ${escaped_reason}
}
EOF
  exit 2
}

#######################################
# Allow tool
#######################################
function allow_tool() {
  echo '{"decision": "approve"}'
  exit 0
}

#######################################
# Main entry point
#######################################
function main() {
  # Check for jq
  if ! command -v jq >/dev/null 2>&1; then
    allow_tool  # Fail open if jq not available
  fi

  # Check if state file exists
  if [[ ! -f "${STATE_FILE}" ]]; then
    allow_tool  # No state = no enforcement
  fi

  # Read current state
  local state pipeline_mode
  state="$(jq -r '.state // "IDLE"' "${STATE_FILE}" 2>/dev/null)" || state="IDLE"
  pipeline_mode="$(jq -r '.pipeline_mode // ""' "${STATE_FILE}" 2>/dev/null)" || pipeline_mode=""

  # ENFORCEMENT RULE 1: pipeline_mode=PENDING requires mode to be set
  if [[ "${state}" == "CLASSIFIED" && "${pipeline_mode}" == "PENDING" ]]; then
    block_tool "Pipeline mode not set. Parse classifier output and run: jq '.pipeline_mode = \"MODE\"' ~/.claude/state/pipeline-state.json (where MODE is TRIVIAL, MODERATE, COMPLEX, or EXPLORATORY)"
  fi

  # ENFORCEMENT RULE 2: GATHERING in COMPLEX/EXPLORATORY requires context-refiner
  if [[ "${state}" == "GATHERING" ]]; then
    if [[ "${pipeline_mode}" == "COMPLEX" || "${pipeline_mode}" == "EXPLORATORY" ]]; then
      block_tool "Pipeline requires context-refiner next. Invoke Task(context-refiner) before other actions."
    fi
  fi

  # ENFORCEMENT RULE 3: REFINING requires strategic-orchestrator
  if [[ "${state}" == "REFINING" ]]; then
    block_tool "Pipeline requires strategic-orchestrator next. Invoke Task(strategic-orchestrator) before other actions."
  fi

  # All checks passed
  allow_tool
}

main
