#!/usr/bin/env bash
#
# check-subagent-allowed.sh - Subagent pipeline enforcement
#
# Called by PreToolUse hook on Task tool
# Receives tool input via stdin (JSON with subagent_type field)
# Enforces state machine transitions for agent execution
#
# Exit codes:
#   0 - Agent approved
#   1 - Error (missing dependencies, invalid state)
#   2 - Agent blocked (policy violation)

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly STATE_DIR="${HOME}/.claude/state"
readonly STATE_FILE="${STATE_DIR}/pipeline-state.json"

# DEV-NOTE: Utility agents NO LONGER bypass pipeline restrictions
# They must go through context-gatherer first like all other agents
# See ~/.claude/CLAUDE.md for rationale
readonly UTILITY_AGENTS=(
  # INTENTIONALLY EMPTY - no agents bypass pipeline
  # Previously: "Explore", "Plan", "general-purpose"
)

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
# Read and parse tool input from stdin
# PreToolUse hook provides JSON with structure:
#   { "tool_input": { "subagent_type": "..." }, ... }
# Outputs:
#   Subagent type string to stdout
# Returns:
#   0 on success, 1 on failure
#######################################
function read_tool_input() {
  local tool_input

  # Read all stdin
  if ! tool_input="$(cat)"; then
    log_message "ERROR: Failed to read tool input from stdin"
    return 1
  fi

  if [[ -z "${tool_input}" ]]; then
    log_message "ERROR: Empty tool input received"
    return 1
  fi

  # DEV-NOTE: PreToolUse hook provides tool_input nested inside .tool_input
  # The structure is: { "tool_name": "Task", "tool_input": { "subagent_type": "..." } }
  local subagent_type
  if ! subagent_type="$(echo "${tool_input}" | jq -r '.tool_input.subagent_type // empty' 2>/dev/null)"; then
    log_message "ERROR: Failed to parse JSON tool input"
    return 1
  fi

  if [[ -z "${subagent_type}" ]]; then
    log_message "ERROR: No subagent_type found in tool input"
    return 1
  fi

  echo "${subagent_type}"
  return 0
}

#######################################
# Load current pipeline state
# Globals:
#   STATE_FILE
# Outputs:
#   State string to stdout
# Returns:
#   0 on success, 1 on failure
#######################################
function load_current_state() {
  if [[ ! -f "${STATE_FILE}" ]]; then
    log_message "WARN: State file not found, defaulting to IDLE"
    echo "IDLE"
    return 0
  fi
  
  local current_state
  if ! current_state="$(jq -r '.state' "${STATE_FILE}" 2>/dev/null)"; then
    log_message "ERROR: Failed to parse state file, defaulting to IDLE"
    echo "IDLE"
    return 0
  fi
  
  if [[ -z "${current_state}" ]]; then
    log_message "WARN: Empty state in file, defaulting to IDLE"
    echo "IDLE"
    return 0
  fi
  
  echo "${current_state}"
  return 0
}

#######################################
# Check if agent is a utility agent that bypasses restrictions
# Arguments:
#   $1 - Agent name
# Returns:
#   0 if utility agent, 1 otherwise
#######################################
function is_utility_agent() {
  local -r agent="$1"
  
  for utility_agent in "${UTILITY_AGENTS[@]}"; do
    if [[ "${agent}" == "${utility_agent}" ]]; then
      return 0
    fi
  done
  
  return 1
}

#######################################
# Approve agent execution
# Also tracks the agent as active for SubagentStop to retrieve
# Arguments:
#   $1 - Agent name
#   $2 - Current state
# Outputs:
#   Approval JSON to stdout
# Returns:
#   0 (success exit code)
#######################################
function approve_agent() {
  local -r agent="$1"
  local -r state="$2"

  log_message "APPROVED: ${agent} in state ${state}"

  # Track this agent as active so SubagentStop can identify it
  # DEV-NOTE: SubagentStop hook doesn't provide agent name, so we store it here
  if ! track_active_agent "${agent}"; then
    log_message "WARN: Failed to track active agent, proceeding anyway"
  fi

  echo '{"decision": "approve"}'
  return 0
}

#######################################
# Block agent execution
# Arguments:
#   $1 - Agent name
#   $2 - Current state
#   $3 - Reason for block
# Outputs:
#   Block JSON to stdout
# Returns:
#   2 (block exit code)
#######################################
function block_agent() {
  local -r agent="$1"
  local -r state="$2"
  local -r reason="$3"

  log_message "BLOCKED: ${agent} in state ${state} - ${reason}"

  local -r escaped_reason="$(echo "${reason}" | jq -Rs .)"
  cat <<EOF
{
  "decision": "block",
  "reason": ${escaped_reason}
}
EOF
  return 2
}

#######################################
# Track active agent in state file
# SubagentStop doesn't provide agent name, so we track it at approval time
# Arguments:
#   $1 - Agent name being approved
# Returns:
#   0 on success, 1 on failure
#######################################
function track_active_agent() {
  local -r agent="$1"
  local -r temp_file="${STATE_DIR}/.pipeline-state.tmp.$$"

  log_message "Tracking active agent: ${agent}"

  local new_state_json
  if ! new_state_json="$(jq \
    --arg agent "${agent}" \
    '.active_agent = $agent' "${STATE_FILE}")"; then
    log_message "ERROR: Failed to update active_agent"
    return 1
  fi

  if ! echo "${new_state_json}" > "${temp_file}"; then
    log_message "ERROR: Failed to write temp state file"
    rm -f "${temp_file}"
    return 1
  fi

  if ! mv "${temp_file}" "${STATE_FILE}"; then
    log_message "ERROR: Failed to move temp file"
    rm -f "${temp_file}"
    return 1
  fi

  return 0
}

#######################################
# Transition state immediately (for proactive transitions)
# Used when approving an agent should trigger immediate state change
# Arguments:
#   $1 - New state
#   $2 - Agent triggering the transition
#   $3 - Previous state
# Returns:
#   0 on success, 1 on failure
#######################################
function transition_state_immediate() {
  local -r new_state="$1"
  local -r agent="$2"
  local -r prev_state="$3"
  local -r timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local -r temp_file="${STATE_DIR}/.pipeline-state.tmp.$$"

  log_message "Immediate transition: ${prev_state} → ${new_state} (triggered by ${agent})"

  # Read current state and update
  local new_state_json
  if ! new_state_json="$(jq \
    --arg state "${new_state}" \
    --arg timestamp "${timestamp}" \
    --arg agent "${agent}" \
    --arg state_before "${prev_state}" \
    --arg state_after "${new_state}" \
    '
    .state = $state |
    .timestamp = $timestamp |
    .active_agent = $agent |
    .history += [{
      "agent": $agent,
      "timestamp": $timestamp,
      "state_before": $state_before,
      "state_after": $state_after,
      "trigger": "immediate_on_approval"
    }]
    ' "${STATE_FILE}")"; then
    log_message "ERROR: Failed to generate new state JSON"
    return 1
  fi

  # Write atomically
  if ! echo "${new_state_json}" > "${temp_file}"; then
    log_message "ERROR: Failed to write temp state file"
    rm -f "${temp_file}"
    return 1
  fi

  if ! mv "${temp_file}" "${STATE_FILE}"; then
    log_message "ERROR: Failed to move temp file to state file"
    rm -f "${temp_file}"
    return 1
  fi

  log_message "State transition complete: ${new_state}"
  return 0
}

#######################################
# Determine if agent is allowed in current state
# State machine enforcement logic
# Arguments:
#   $1 - Agent name
#   $2 - Current state
# Returns:
#   0 if allowed (via approve_agent), 2 if blocked (via block_agent)
#######################################
function is_agent_allowed() {
  local -r agent="$1"
  local -r state="$2"
  
  log_message "Checking agent: ${agent} in state: ${state}"
  
  # Utility agents bypass all restrictions
  if is_utility_agent "${agent}"; then
    approve_agent "${agent}" "${state}"
    return
  fi
  
  # DEV-NOTE: State machine enforcement
  # Each state allows only specific agents to ensure proper pipeline flow
  #
  # State machine:
  #   IDLE → only context-gatherer can start the pipeline
  #   GATHERING → context-refiner OR utility agents
  #   REFINING → strategic-orchestrator (triggers immediate → ORCHESTRATING_ACTIVE) OR utility agents
  #   ORCHESTRATING_ACTIVE → language-specific agents OR utility agents (orchestrator is running)
  #   EXECUTING → language-specific agents OR utility agents (orchestrator completed)
  #   COMPLETE → only context-gatherer to restart
  #
  # ORCHESTRATING_ACTIVE vs EXECUTING:
  #   - ORCHESTRATING_ACTIVE: strategic-orchestrator is actively running, may dispatch agents
  #   - EXECUTING: strategic-orchestrator completed, implementation agents are running
  #
  # Utility agents (Explore, Plan, general-purpose) are allowed AFTER
  # context-gatherer but NOT as a substitute for starting the pipeline

  # Check if this is a utility agent (allowed after IDLE state)
  local is_utility=false
  if [[ "${agent}" == "Explore" || "${agent}" == "Plan" || "${agent}" == "general-purpose" ]]; then
    is_utility=true
  fi

  case "${state}" in
    IDLE)
      if [[ "${agent}" == "context-gatherer" ]]; then
        approve_agent "${agent}" "${state}"
      else
        block_agent "${agent}" "${state}" "Must start pipeline with context-gatherer agent. Current state: IDLE. Run context-gatherer first, then you can use ${agent}."
      fi
      ;;

    GATHERING)
      if [[ "${agent}" == "context-refiner" || "${is_utility}" == "true" ]]; then
        approve_agent "${agent}" "${state}"
      else
        block_agent "${agent}" "${state}" "Must refine context with context-refiner agent (or use utility agents). Current state: GATHERING"
      fi
      ;;

    REFINING)
      if [[ "${agent}" == "strategic-orchestrator" ]]; then
        # DEV-NOTE: Immediate state transition to ORCHESTRATING_ACTIVE
        # This allows strategic-orchestrator to dispatch language agents
        # while it's still running (parallel agent deployment)
        if ! transition_state_immediate "ORCHESTRATING_ACTIVE" "${agent}" "${state}"; then
          log_message "WARN: Failed to transition state, approving anyway"
        fi
        approve_agent "${agent}" "ORCHESTRATING_ACTIVE"
      elif [[ "${is_utility}" == "true" ]]; then
        approve_agent "${agent}" "${state}"
      else
        block_agent "${agent}" "${state}" "Must plan with strategic-orchestrator agent (or use utility agents). Current state: REFINING"
      fi
      ;;

    ORCHESTRATING_ACTIVE)
      # strategic-orchestrator is running and may dispatch language agents
      if [[ "${agent}" =~ ^(bash-|nix-|c-) || "${is_utility}" == "true" ]]; then
        approve_agent "${agent}" "${state}"
      else
        block_agent "${agent}" "${state}" "Only language-specific agents (bash-*, nix-*, c-*) or utility agents allowed while orchestrator is active. Current state: ORCHESTRATING_ACTIVE"
      fi
      ;;

    EXECUTING)
      # strategic-orchestrator completed, language agents are executing
      if [[ "${agent}" =~ ^(bash-|nix-|c-) || "${is_utility}" == "true" ]]; then
        approve_agent "${agent}" "${state}"
      else
        block_agent "${agent}" "${state}" "Only language-specific agents (bash-*, nix-*, c-*) or utility agents allowed during execution. Current state: EXECUTING"
      fi
      ;;

    COMPLETE)
      # Pipeline complete, allow restart with context-gatherer
      if [[ "${agent}" == "context-gatherer" ]]; then
        approve_agent "${agent}" "${state}"
      else
        block_agent "${agent}" "${state}" "Pipeline complete. Start new pipeline with context-gatherer agent."
      fi
      ;;

    *)
      block_agent "${agent}" "${state}" "Unknown state: ${state}"
      ;;
  esac
}

#######################################
# Main entry point
# Reads stdin, checks state, enforces policy
# Returns:
#   0 if approved, 1 on error, 2 if blocked
#######################################
function main() {
  # Check for jq dependency
  if ! command -v jq >/dev/null 2>&1; then
    log_message "ERROR: jq is required but not installed"
    echo '{"decision": "block", "reason": "jq is required for pipeline enforcement"}' >&2
    return 1
  fi
  
  # Read tool input from stdin
  local subagent_type
  if ! subagent_type="$(read_tool_input)"; then
    log_message "ERROR: Failed to read tool input"
    # Fail-safe: allow on error to avoid blocking legitimate operations
    echo '{"decision": "approve"}'
    return 0
  fi
  
  # Load current state
  local current_state
  if ! current_state="$(load_current_state)"; then
    log_message "ERROR: Failed to load state"
    # Fail-safe: allow on error
    echo '{"decision": "approve"}'
    return 0
  fi
  
  # Check if agent allowed
  is_agent_allowed "${subagent_type}" "${current_state}"
  
  # DEV-NOTE: is_agent_allowed calls approve_agent or block_agent
  # which handle exit codes (0 for approve, 2 for block)
}

# Execute main
main
