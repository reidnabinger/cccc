#!/usr/bin/env bash
#
# update-pipeline-state.sh - Pipeline state transitions after agent completion
#
# Called by SubagentStop hook
# Receives agent output/context via stdin or environment
# Advances state machine based on completed agent
#
# State transitions:
#   context-gatherer completed → IDLE → GATHERING
#   context-refiner completed → GATHERING → REFINING
#   strategic-orchestrator approved → REFINING → ORCHESTRATING_ACTIVE (immediate, in check-subagent-allowed.sh)
#   strategic-orchestrator completed → ORCHESTRATING_ACTIVE → EXECUTING
#   language agents completed → EXECUTING (stays in EXECUTING until COMPLETE)

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly STATE_DIR="${HOME}/.claude/state"
readonly STATE_FILE="${STATE_DIR}/pipeline-state.json"

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
# Read SubagentStop hook data from stdin
# SubagentStop provides: session_id, transcript_path, permission_mode,
# hook_event_name, stop_hook_active
# Outputs:
#   JSON string to stdout
# Returns:
#   0 on success, 1 on failure
#######################################
function read_hook_input() {
  local hook_input

  if ! hook_input="$(cat)"; then
    log_message "ERROR: Failed to read hook input from stdin"
    return 1
  fi

  if [[ -z "${hook_input}" ]]; then
    log_message "WARN: Empty hook input received"
    echo "{}"
    return 0
  fi

  # Validate JSON
  if ! echo "${hook_input}" | jq empty 2>/dev/null; then
    log_message "WARN: Hook input is not valid JSON"
    echo "{}"
    return 0
  fi

  echo "${hook_input}"
  return 0
}

#######################################
# Extract agent name from transcript file
# SubagentStop hook doesn't include agent name directly, so we parse
# the transcript to find the most recent Task tool invocation
# Arguments:
#   $1 - Transcript file path
# Outputs:
#   Agent name to stdout
# Returns:
#   0 on success, 1 on failure
#######################################
function extract_agent_from_transcript() {
  local -r transcript_path="$1"

  # Expand ~ in path
  local -r expanded_path="${transcript_path/#\~/$HOME}"

  if [[ ! -f "${expanded_path}" ]]; then
    log_message "ERROR: Transcript file not found: ${expanded_path}"
    return 1
  fi

  # DEV-NOTE: The transcript is JSONL format. We need to find the most recent
  # Task tool call and extract its subagent_type parameter.
  # The structure varies, but we look for tool_use with name="Task" and
  # extract subagent_type from its input.
  local agent_name
  agent_name="$(tac "${expanded_path}" | \
    jq -r 'select(.type == "tool_use" and .name == "Task") | .input.subagent_type // empty' 2>/dev/null | \
    head -1)"

  if [[ -z "${agent_name}" ]]; then
    # Try alternative structure (assistant message with tool_use content)
    agent_name="$(tac "${expanded_path}" | \
      jq -r '.content[]? | select(.type == "tool_use" and .name == "Task") | .input.subagent_type // empty' 2>/dev/null | \
      head -1)"
  fi

  if [[ -z "${agent_name}" ]]; then
    log_message "WARN: Could not extract agent name from transcript"
    return 1
  fi

  log_message "Extracted agent name from transcript: ${agent_name}"
  echo "${agent_name}"
  return 0
}

#######################################
# Load current pipeline state
# Globals:
#   STATE_FILE
# Outputs:
#   Full state JSON to stdout
# Returns:
#   0 on success, 1 on failure
#######################################
function load_current_state() {
  if [[ ! -f "${STATE_FILE}" ]]; then
    log_message "ERROR: State file not found: ${STATE_FILE}"
    return 1
  fi
  
  local state_content
  if ! state_content="$(cat "${STATE_FILE}")"; then
    log_message "ERROR: Failed to read state file"
    return 1
  fi
  
  if ! echo "${state_content}" | jq empty 2>/dev/null; then
    log_message "ERROR: State file contains invalid JSON"
    return 1
  fi
  
  echo "${state_content}"
  return 0
}

#######################################
# Extract context data from agent output
# Arguments:
#   $1 - Agent output JSON
#   $2 - Agent name
# Outputs:
#   Context string to stdout
#######################################
function extract_context_from_agent() {
  local -r agent_output="$1"
  local -r agent_name="$2"
  
  # Try to extract meaningful context from agent output
  # DEV-NOTE: This is a simple extraction; may need enhancement
  # based on actual agent output formats
  
  local context
  context="$(echo "${agent_output}" | jq -r '.context // .summary // .output // .raw_output // ""' 2>/dev/null)"
  
  if [[ -z "${context}" ]]; then
    log_message "WARN: No extractable context from ${agent_name}"
    context="Agent ${agent_name} completed successfully"
  fi
  
  echo "${context}"
}

#######################################
# Determine next state based on completed agent
# Arguments:
#   $1 - Agent name
#   $2 - Current state
# Outputs:
#   Next state string to stdout
# Returns:
#   0 on success, 1 if no transition needed
#######################################
function determine_next_state() {
  local -r agent="$1"
  local -r current_state="$2"
  
  log_message "Determining next state for agent: ${agent}, current: ${current_state}"
  
  # DEV-NOTE: State transitions based on agent completion
  # context-gatherer → GATHERING (context gathered, ready for refinement)
  # context-refiner → REFINING (context refined, ready for planning)
  # strategic-orchestrator → EXECUTING (orchestrator finished, was in ORCHESTRATING_ACTIVE)
  # language agents → remain in EXECUTING (until explicitly marked COMPLETE)
  #
  # Note: REFINING → ORCHESTRATING_ACTIVE happens immediately when strategic-orchestrator
  # is approved (in check-subagent-allowed.sh), not here

  case "${agent}" in
    context-gatherer)
      if [[ "${current_state}" == "IDLE" ]]; then
        echo "GATHERING"
        return 0
      fi
      ;;

    context-refiner)
      if [[ "${current_state}" == "GATHERING" ]]; then
        echo "REFINING"
        return 0
      fi
      ;;

    strategic-orchestrator)
      # DEV-NOTE: When strategic-orchestrator completes, transition from
      # ORCHESTRATING_ACTIVE to EXECUTING. The ORCHESTRATING_ACTIVE state
      # was set when the orchestrator was approved (immediate transition).
      if [[ "${current_state}" == "ORCHESTRATING_ACTIVE" ]]; then
        echo "EXECUTING"
        return 0
      fi
      # Handle legacy case where state might still be REFINING (shouldn't happen
      # with new code, but provides backwards compatibility)
      if [[ "${current_state}" == "REFINING" ]]; then
        log_message "WARN: strategic-orchestrator completed in REFINING state (expected ORCHESTRATING_ACTIVE)"
        echo "EXECUTING"
        return 0
      fi
      ;;

    bash-*|nix-*|c-*)
      # Language agents don't auto-transition
      # Stay in EXECUTING state until manually marked COMPLETE
      if [[ "${current_state}" == "EXECUTING" || "${current_state}" == "ORCHESTRATING_ACTIVE" ]]; then
        echo "EXECUTING"
        return 0
      fi
      ;;
  esac
  
  # No state transition needed
  log_message "No state transition for ${agent} in ${current_state}"
  return 1
}

#######################################
# Update state file with new state and history
# Arguments:
#   $1 - Current state JSON
#   $2 - Agent name
#   $3 - Next state
#   $4 - Agent context/output
# Globals:
#   STATE_FILE
#   STATE_DIR
# Returns:
#   0 on success, 1 on failure
#######################################
function update_state_file() {
  local -r current_state_json="$1"
  local -r agent_name="$2"
  local -r next_state="$3"
  local -r agent_context="$4"
  
  local -r timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local -r current_state="$(echo "${current_state_json}" | jq -r '.state')"
  
  # Determine which context field to update
  local context_field=""
  case "${agent_name}" in
    context-gatherer)
      context_field="gathered"
      ;;
    context-refiner)
      context_field="refined"
      ;;
    strategic-orchestrator)
      context_field="orchestration"
      ;;
  esac
  
  # Build new state JSON
  local new_state_json
  if [[ -n "${context_field}" ]]; then
    # Update specific context field
    local -r escaped_context="$(echo "${agent_context}" | jq -Rs .)"
    new_state_json="$(echo "${current_state_json}" | jq \
      --arg state "${next_state}" \
      --arg timestamp "${timestamp}" \
      --arg field "${context_field}" \
      --argjson context "${escaped_context}" \
      --arg agent "${agent_name}" \
      --arg state_before "${current_state}" \
      --arg state_after "${next_state}" \
      '
      .state = $state |
      .timestamp = $timestamp |
      .context[$field] = $context |
      .history += [{
        "agent": $agent,
        "timestamp": $timestamp,
        "state_before": $state_before,
        "state_after": $state_after
      }]
      ')"
  else
    # Just update state and history (for language agents)
    new_state_json="$(echo "${current_state_json}" | jq \
      --arg state "${next_state}" \
      --arg timestamp "${timestamp}" \
      --arg agent "${agent_name}" \
      --arg state_before "${current_state}" \
      --arg state_after "${next_state}" \
      '
      .state = $state |
      .timestamp = $timestamp |
      .history += [{
        "agent": $agent,
        "timestamp": $timestamp,
        "state_before": $state_before,
        "state_after": $state_after
      }]
      ')"
  fi
  
  # Write atomically
  local -r temp_file="${STATE_DIR}/.pipeline-state.tmp.$$"
  
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
  
  log_message "State updated: ${current_state} → ${next_state}"
  return 0
}

#######################################
# Main entry point
# Reads SubagentStop hook data, extracts agent name from transcript, updates state
# Environment variables:
#   AGENT_NAME - Name of completed agent (optional override)
# Returns:
#   0 on success, 1 on failure
#######################################
function main() {
  # Check for jq dependency
  if ! command -v jq >/dev/null 2>&1; then
    log_message "ERROR: jq is required but not installed"
    return 1
  fi

  # Get agent name from environment (override) if set
  local agent_name="${AGENT_NAME:-}"

  # Read SubagentStop hook input (contains transcript_path)
  local hook_input
  if ! hook_input="$(read_hook_input)"; then
    log_message "ERROR: Failed to read hook input"
    return 1
  fi

  # Extract agent name from state file (tracked by PreToolUse hook)
  # DEV-NOTE: SubagentStop doesn't provide agent name in hook data,
  # so check-subagent-allowed.sh tracks it as "active_agent" when approved
  if [[ -z "${agent_name}" ]]; then
    # Primary method: read from state file (set by check-subagent-allowed.sh)
    agent_name="$(jq -r '.active_agent // empty' "${STATE_FILE}" 2>/dev/null)"

    # Fallback: try hook input directly (future-proofing if Claude Code adds it)
    if [[ -z "${agent_name}" ]]; then
      agent_name="$(echo "${hook_input}" | jq -r '.subagent_type // .agent_name // .agent // empty' 2>/dev/null)"
    fi

    if [[ -z "${agent_name}" ]]; then
      log_message "ERROR: Could not determine agent name (not in state or hook input)"
      return 1
    fi
  fi

  log_message "Processing completion for agent: ${agent_name}"
  
  # Load current state
  local current_state_json
  if ! current_state_json="$(load_current_state)"; then
    log_message "ERROR: Failed to load current state"
    return 1
  fi
  
  local -r current_state="$(echo "${current_state_json}" | jq -r '.state')"
  log_message "Current state: ${current_state}"
  
  # Determine next state
  local next_state
  if ! next_state="$(determine_next_state "${agent_name}" "${current_state}")"; then
    log_message "No state transition needed for ${agent_name}"
    return 0
  fi
  
  # DEV-NOTE: SubagentStop hook doesn't provide agent output, only transcript path
  # Context extraction from transcript would be expensive, so we use a simple marker
  local agent_context="Agent ${agent_name} completed successfully"
  
  # Update state file
  if ! update_state_file "${current_state_json}" "${agent_name}" "${next_state}" "${agent_context}"; then
    log_message "ERROR: Failed to update state file"
    return 1
  fi
  
  log_message "Pipeline state updated successfully"
  return 0
}

# Execute main
main
