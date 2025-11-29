#!/usr/bin/env bash
#
# pipeline-gate.sh - Pipeline state initialization and prompt injection
#
# Called by SessionStart hook with "init" argument
# Called by UserPromptSubmit hook with "check-prompt" argument
#
# Manages state file at ~/.claude/state/pipeline-state.json
# State machine: IDLE → GATHERING → REFINING → ORCHESTRATING_ACTIVE → EXECUTING → COMPLETE
#
# Note: REFINING → ORCHESTRATING_ACTIVE transition happens immediately when
# strategic-orchestrator is approved (in check-subagent-allowed.sh)

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly STATE_DIR="${HOME}/.claude/state"
readonly STATE_FILE="${STATE_DIR}/pipeline-state.json"
readonly WORKFLOW_INSTRUCTIONS='
CRITICAL: You must follow this agent workflow for all Bash, C, and Nix tasks:

1. FIRST: Invoke context-gatherer agent to exhaustively collect context
2. THEN: Invoke context-refiner agent to distill and analyze the gathered context
3. THEN: Invoke strategic-orchestrator agent to plan the implementation approach
4. FINALLY: Invoke language-specific agents (bash-architect, nix-architect, c-security-architect, etc.)

IMPORTANT: Explore, Plan, and general-purpose agents are NOT exempt from this workflow!
- They may ONLY be used AFTER context-gatherer has been invoked
- They are for narrow follow-up queries, NOT as substitutes for proper context gathering
- Attempting to use them before context-gatherer will be BLOCKED by PreToolUse hooks

This workflow ensures you have comprehensive context before making any decisions.
'

#######################################
# Log message to stderr with timestamp
# Globals:
#   SCRIPT_NAME
# Arguments:
#   Message string
#######################################
function log_message() {
  local -r message="$1"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [${SCRIPT_NAME}] ${message}" >&2
}

#######################################
# Create initial IDLE state JSON
# Outputs:
#   JSON string to stdout
#######################################
function create_initial_state() {
  local -r timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  
  cat <<EOF
{
  "version": "1.0",
  "state": "IDLE",
  "timestamp": "${timestamp}",
  "session_id": "",
  "context": {
    "gathered": "",
    "refined": "",
    "orchestration": ""
  },
  "history": []
}
EOF
}

#######################################
# Write state atomically using temp file + mv
# Globals:
#   STATE_FILE
#   STATE_DIR
# Arguments:
#   JSON content string
# Returns:
#   0 on success, 1 on failure
#######################################
function write_state_atomic() {
  local -r content="$1"
  local -r temp_file="${STATE_DIR}/.pipeline-state.tmp.$$"
  
  # DEV-NOTE: Using temp file + mv ensures atomic write
  # This prevents corruption if multiple processes write simultaneously
  if ! echo "${content}" > "${temp_file}"; then
    log_message "ERROR: Failed to write temp state file: ${temp_file}"
    rm -f "${temp_file}"
    return 1
  fi
  
  # Validate JSON before committing
  if ! jq empty "${temp_file}" 2>/dev/null; then
    log_message "ERROR: Generated invalid JSON, not updating state"
    rm -f "${temp_file}"
    return 1
  fi
  
  if ! mv "${temp_file}" "${STATE_FILE}"; then
    log_message "ERROR: Failed to move temp file to state file"
    rm -f "${temp_file}"
    return 1
  fi
  
  log_message "State written successfully"
  return 0
}

#######################################
# Initialize pipeline state
# Creates state directory and initial state file
# Globals:
#   STATE_DIR
#   STATE_FILE
# Outputs:
#   Confirmation message to stdout
# Returns:
#   0 on success, 1 on failure
#######################################
function initialize_state() {
  log_message "Initializing pipeline state"
  
  # Create state directory if needed
  if [[ ! -d "${STATE_DIR}" ]]; then
    if ! mkdir -p "${STATE_DIR}"; then
      log_message "ERROR: Failed to create state directory: ${STATE_DIR}"
      return 1
    fi
    log_message "Created state directory: ${STATE_DIR}"
  fi
  
  # Create initial state file
  local -r initial_state="$(create_initial_state)"
  if ! write_state_atomic "${initial_state}"; then
    log_message "ERROR: Failed to initialize state file"
    return 1
  fi
  
  echo "Pipeline state initialized at ${STATE_FILE}"
  log_message "Pipeline state initialized successfully"
  return 0
}

#######################################
# Check prompt and inject workflow if needed
# Reads current state and determines if workflow instructions needed
# Globals:
#   STATE_FILE
#   WORKFLOW_INSTRUCTIONS
# Outputs:
#   JSON response to stdout
# Returns:
#   0 on success, 1 on failure
#######################################
function check_prompt() {
  log_message "Checking prompt for workflow injection"
  
  # If state file doesn't exist, initialize it
  if [[ ! -f "${STATE_FILE}" ]]; then
    log_message "State file missing, initializing"
    if ! initialize_state >/dev/null; then
      log_message "ERROR: Failed to initialize state during check"
      # Fail-safe: allow continuation without injection
      echo '{"continue": true}'
      return 0
    fi
  fi
  
  # Read current state
  local current_state
  if ! current_state="$(jq -r '.state' "${STATE_FILE}" 2>/dev/null)"; then
    log_message "ERROR: Failed to read state, defaulting to IDLE"
    current_state="IDLE"
  fi
  
  log_message "Current state: ${current_state}"
  
  # DEV-NOTE: Only inject workflow instructions when in IDLE state
  # This ensures the workflow is reinforced at the start of each new task
  # but doesn't spam instructions during mid-workflow interactions
  if [[ "${current_state}" == "IDLE" ]]; then
    log_message "IDLE state detected, injecting workflow instructions"
    
    # Escape workflow instructions for JSON
    local -r escaped_instructions="$(echo "${WORKFLOW_INSTRUCTIONS}" | jq -Rs .)"
    
    cat <<EOF
{
  "continue": true,
  "additional_context": ${escaped_instructions}
}
EOF
  else
    log_message "Non-IDLE state, allowing continuation without injection"
    echo '{"continue": true}'
  fi
  
  return 0
}

#######################################
# Main entry point
# Routes to appropriate function based on argument
# Arguments:
#   $1 - Command: "init" or "check-prompt"
# Returns:
#   0 on success, 1 on failure
#######################################
function main() {
  # Check for jq dependency
  if ! command -v jq >/dev/null 2>&1; then
    log_message "ERROR: jq is required but not installed"
    echo "ERROR: jq is required for pipeline-gate.sh" >&2
    return 1
  fi
  
  local -r command="${1:-}"
  
  case "${command}" in
    init)
      initialize_state
      ;;
    check-prompt)
      check_prompt
      ;;
    *)
      log_message "ERROR: Invalid command: ${command}"
      echo "Usage: ${SCRIPT_NAME} {init|check-prompt}" >&2
      return 1
      ;;
  esac
}

# Execute main with all arguments
main "$@"
