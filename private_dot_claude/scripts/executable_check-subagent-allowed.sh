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
readonly JOURNAL_FILE="${STATE_DIR}/pipeline-journal.log"

# Stale state timeout in seconds (10 minutes)
readonly STALE_TIMEOUT_SECONDS=600

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
# Write entry to journal file for debugging
# Globals:
#   JOURNAL_FILE
# Arguments:
#   Event type (CHECK, APPROVE, BLOCK, RESET, ERROR)
#   Message/details
#######################################
function journal_write() {
  local -r event_type="$1"
  local -r message="$2"
  local -r timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # Ensure journal directory exists
  mkdir -p "$(dirname "${JOURNAL_FILE}")"

  # Append to journal (one line per entry for easy parsing)
  printf '%s\t%s\t%s\t%s\n' \
    "${timestamp}" "${event_type}" "${SCRIPT_NAME}" "${message}" \
    >> "${JOURNAL_FILE}" 2>/dev/null || true
}

#######################################
# Check if state is stale and auto-reset if needed
# Globals:
#   STATE_FILE
#   STALE_TIMEOUT_SECONDS
# Returns:
#   0 if state was reset (or no reset needed), 1 on error
#######################################
function check_and_reset_stale_state() {
  if [[ ! -f "${STATE_FILE}" ]]; then
    return 0
  fi

  local state_timestamp
  state_timestamp="$(jq -r '.timestamp // empty' "${STATE_FILE}" 2>/dev/null)"

  if [[ -z "${state_timestamp}" ]]; then
    log_message "WARN: No timestamp in state file"
    return 0
  fi

  local current_state
  current_state="$(jq -r '.state // "IDLE"' "${STATE_FILE}" 2>/dev/null)"

  # IDLE and COMPLETE states don't go stale
  if [[ "${current_state}" == "IDLE" || "${current_state}" == "COMPLETE" ]]; then
    return 0
  fi

  # Calculate age of state
  local state_epoch
  local current_epoch

  # Convert ISO8601 to epoch (portable approach)
  if ! state_epoch="$(date -d "${state_timestamp}" +%s 2>/dev/null)"; then
    # Fallback for systems without GNU date
    log_message "WARN: Could not parse state timestamp"
    return 0
  fi

  current_epoch="$(date +%s)"
  local age=$((current_epoch - state_epoch))

  if [[ ${age} -gt ${STALE_TIMEOUT_SECONDS} ]]; then
    local minutes=$((age / 60))
    log_message "WARN: Stale state detected! State '${current_state}' is ${minutes} minutes old (threshold: $((STALE_TIMEOUT_SECONDS / 60)) min)"
    journal_write "STALE_RESET" "Auto-reset from ${current_state} after ${minutes} minutes"

    # Reset to IDLE
    local -r reset_timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    local reset_json
    reset_json="$(jq \
      --arg timestamp "${reset_timestamp}" \
      --arg prev_state "${current_state}" \
      --arg age "${minutes}" \
      '
      .state = "IDLE" |
      .timestamp = $timestamp |
      .context = {"gathered": "", "refined": "", "orchestration": ""} |
      .history += [{
        "agent": "auto-reset",
        "timestamp": $timestamp,
        "state_before": $prev_state,
        "state_after": "IDLE",
        "reason": ("Stale state auto-reset after " + $age + " minutes")
      }]
      ' "${STATE_FILE}")"

    # Write atomically
    local -r temp_file="${STATE_DIR}/.pipeline-state.tmp.$$"
    if echo "${reset_json}" > "${temp_file}" && mv "${temp_file}" "${STATE_FILE}"; then
      log_message "Auto-reset complete: ${current_state} → IDLE"
      # Output warning message that will be shown to user
      echo "⚠️  Pipeline state was stale (${minutes} min). Auto-reset to IDLE." >&2
    else
      log_message "ERROR: Failed to write auto-reset state"
      rm -f "${temp_file}"
      return 1
    fi
  fi

  return 0
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
# Load pipeline mode (TRIVIAL, MODERATE, COMPLEX, EXPLORATORY)
# Set by task-classifier agent
# Globals:
#   STATE_FILE
# Outputs:
#   Pipeline mode to stdout (default: COMPLEX)
#######################################
function load_pipeline_mode() {
  if [[ ! -f "${STATE_FILE}" ]]; then
    echo "COMPLEX"
    return 0
  fi

  local mode
  mode="$(jq -r '.pipeline_mode // "COMPLEX"' "${STATE_FILE}" 2>/dev/null)"

  if [[ -z "${mode}" || "${mode}" == "null" ]]; then
    mode="COMPLEX"
  fi

  echo "${mode}"
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
  journal_write "APPROVE" "agent=${agent} state=${state}"

  # Track this agent as active so SubagentStop can identify it
  # DEV-NOTE: SubagentStop hook doesn't provide agent name, so we store it here
  if ! track_active_agent "${agent}"; then
    log_message "WARN: Failed to track active agent, proceeding anyway"
    journal_write "WARN" "Failed to track active agent: ${agent}"
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
  journal_write "BLOCK" "agent=${agent} state=${state} reason=${reason}"

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
  
  # DEV-NOTE: State machine enforcement with adaptive routing
  # Each state allows only specific agents to ensure proper pipeline flow
  #
  # State machine (adaptive):
  #   IDLE → task-classifier OR context-gatherer can start the pipeline
  #   CLASSIFIED → based on pipeline_mode:
  #     - TRIVIAL: any execution agent (skip gathering/refining)
  #     - MODERATE: context-gatherer only (then skip to EXECUTING)
  #     - COMPLEX/EXPLORATORY: context-gatherer (full pipeline)
  #   GATHERING → based on pipeline_mode:
  #     - MODERATE: execution agents OR utility agents (skip refiner)
  #     - COMPLEX/EXPLORATORY: context-refiner OR utility agents
  #   REFINING → strategic-orchestrator (triggers → ORCHESTRATING_ACTIVE)
  #   ORCHESTRATING_ACTIVE → language-specific agents (orchestrator running)
  #   EXECUTING → language-specific agents (final execution phase)
  #   COMPLETE → task-classifier or context-gatherer to restart
  #
  # Pipeline modes (set by task-classifier):
  #   TRIVIAL: Simple single-file changes, skip all gathering
  #   MODERATE: Focused changes, gather context then execute
  #   COMPLEX: Full pipeline with orchestration
  #   EXPLORATORY: Full pipeline for research/understanding tasks
  #
  # Utility agents (Explore, Plan, general-purpose) are allowed AFTER
  # context-gatherer but NOT as a substitute for starting the pipeline

  # Check if this is a utility agent (allowed after initial classification)
  local is_utility=false
  if [[ "${agent}" == "Explore" || "${agent}" == "Plan" || "${agent}" == "general-purpose" ]]; then
    is_utility=true
  fi

  # Check if this is an execution agent (language-specific or general)
  local is_execution_agent=false
  if [[ "${agent}" =~ ^(bash-|nix-|c-|python-|critical-code-reviewer|docs-reviewer) ]]; then
    is_execution_agent=true
  fi

  # Check if this is a parallel sub-gatherer (used by context-gatherer)
  local is_sub_gatherer=false
  if [[ "${agent}" =~ ^(architecture-gatherer|dependency-gatherer|pattern-gatherer|history-gatherer)$ ]]; then
    is_sub_gatherer=true
  fi

  # Load pipeline mode for routing decisions
  local pipeline_mode
  pipeline_mode=$(load_pipeline_mode)

  case "${state}" in
    IDLE)
      # Allow task-classifier OR context-gatherer to start
      if [[ "${agent}" == "task-classifier" ]]; then
        approve_agent "${agent}" "${state}"
      elif [[ "${agent}" == "context-gatherer" ]]; then
        # DEV-NOTE: Immediate transition to GATHERING allows context-gatherer
        # to invoke context-refiner before completing (self-advancing chain)
        if ! transition_state_immediate "GATHERING" "${agent}" "${state}"; then
          log_message "WARN: Failed to transition to GATHERING, approving anyway"
        fi
        approve_agent "${agent}" "GATHERING"
      else
        block_agent "${agent}" "${state}" "Must start pipeline with task-classifier or context-gatherer. Current state: IDLE."
      fi
      ;;

    CLASSIFIED)
      # After classification, routing depends on pipeline_mode
      case "${pipeline_mode}" in
        TRIVIAL)
          # Skip all gathering, allow direct execution
          if [[ "${is_execution_agent}" == "true" || "${is_utility}" == "true" ]]; then
            approve_agent "${agent}" "${state}"
          else
            block_agent "${agent}" "${state}" "TRIVIAL mode: Only execution agents allowed. Use bash-*, nix-*, c-*, python-*, or utility agents."
          fi
          ;;
        MODERATE|COMPLEX|EXPLORATORY)
          # Require context-gatherer with immediate state transition
          if [[ "${agent}" == "context-gatherer" ]]; then
            # DEV-NOTE: Immediate transition to GATHERING for self-advancing
            if ! transition_state_immediate "GATHERING" "${agent}" "${state}"; then
              log_message "WARN: Failed to transition to GATHERING, approving anyway"
            fi
            approve_agent "${agent}" "GATHERING"
          else
            block_agent "${agent}" "${state}" "${pipeline_mode} mode: Must run context-gatherer first."
          fi
          ;;
        *)
          # Unknown mode, default to requiring context-gatherer
          if [[ "${agent}" == "context-gatherer" ]]; then
            if ! transition_state_immediate "GATHERING" "${agent}" "${state}"; then
              log_message "WARN: Failed to transition to GATHERING, approving anyway"
            fi
            approve_agent "${agent}" "GATHERING"
          else
            block_agent "${agent}" "${state}" "Unknown pipeline mode. Run context-gatherer."
          fi
          ;;
      esac
      ;;

    GATHERING)
      # Sub-gatherers are always allowed during GATHERING (parallel execution)
      if [[ "${is_sub_gatherer}" == "true" ]]; then
        approve_agent "${agent}" "${state}"
        return
      fi

      # After gathering, routing depends on pipeline_mode
      case "${pipeline_mode}" in
        MODERATE)
          # MODERATE: Skip refiner/orchestrator, go straight to execution
          if [[ "${is_execution_agent}" == "true" || "${is_utility}" == "true" ]]; then
            approve_agent "${agent}" "${state}"
          elif [[ "${agent}" == "context-refiner" ]]; then
            # Allow refiner even in MODERATE if user wants deeper analysis
            # DEV-NOTE: Immediate transition to REFINING for self-advancing
            if ! transition_state_immediate "REFINING" "${agent}" "${state}"; then
              log_message "WARN: Failed to transition to REFINING, approving anyway"
            fi
            approve_agent "${agent}" "REFINING"
          else
            block_agent "${agent}" "${state}" "MODERATE mode: Use execution agents or context-refiner. Current state: GATHERING"
          fi
          ;;
        COMPLEX|EXPLORATORY|*)
          # COMPLEX/EXPLORATORY: Require context-refiner before execution
          if [[ "${agent}" == "context-refiner" ]]; then
            # DEV-NOTE: Immediate transition to REFINING for self-advancing
            if ! transition_state_immediate "REFINING" "${agent}" "${state}"; then
              log_message "WARN: Failed to transition to REFINING, approving anyway"
            fi
            approve_agent "${agent}" "REFINING"
          elif [[ "${is_utility}" == "true" ]]; then
            approve_agent "${agent}" "${state}"
          else
            block_agent "${agent}" "${state}" "Must refine context with context-refiner agent. Current state: GATHERING"
          fi
          ;;
      esac
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
      # Pipeline complete, allow restart with task-classifier or context-gatherer
      if [[ "${agent}" == "task-classifier" ]]; then
        approve_agent "${agent}" "${state}"
      elif [[ "${agent}" == "context-gatherer" ]]; then
        # DEV-NOTE: Immediate transition to GATHERING for self-advancing
        if ! transition_state_immediate "GATHERING" "${agent}" "${state}"; then
          log_message "WARN: Failed to transition to GATHERING, approving anyway"
        fi
        approve_agent "${agent}" "GATHERING"
      else
        block_agent "${agent}" "${state}" "Pipeline complete. Start new pipeline with task-classifier or context-gatherer."
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
    journal_write "ERROR" "jq not installed"
    echo '{"decision": "block", "reason": "jq is required for pipeline enforcement"}' >&2
    return 1
  fi

  # Check for stale state and auto-reset if needed
  # This prevents pipeline from getting permanently stuck
  if ! check_and_reset_stale_state; then
    log_message "WARN: Stale state check failed, proceeding anyway"
    journal_write "WARN" "Stale state check failed"
  fi

  # Read tool input from stdin
  local subagent_type
  if ! subagent_type="$(read_tool_input)"; then
    log_message "ERROR: Failed to read tool input"
    journal_write "ERROR" "Failed to read tool input"
    # Fail-safe: allow on error to avoid blocking legitimate operations
    echo '{"decision": "approve"}'
    return 0
  fi

  journal_write "CHECK" "agent=${subagent_type}"

  # Load current state
  local current_state
  if ! current_state="$(load_current_state)"; then
    log_message "ERROR: Failed to load state"
    journal_write "ERROR" "Failed to load state"
    # Fail-safe: allow on error
    echo '{"decision": "approve"}'
    return 0
  fi

  # ENFORCEMENT: Block all agents when pipeline_mode is PENDING
  # Main Claude must set the mode based on classifier output before proceeding
  local pipeline_mode
  pipeline_mode="$(load_pipeline_mode)"
  if [[ "${pipeline_mode}" == "PENDING" ]]; then
    log_message "BLOCKED: pipeline_mode is PENDING - must be set before invoking agents"
    journal_write "ENFORCE_BLOCK" "agent=${subagent_type} reason=pipeline_mode_pending"
    block_agent "${subagent_type}" "${current_state}" "Pipeline mode not set. Parse classifier output and set pipeline_mode (TRIVIAL, MODERATE, COMPLEX, or EXPLORATORY) before invoking agents."
    return
  fi

  # Check if agent allowed
  is_agent_allowed "${subagent_type}" "${current_state}"

  # DEV-NOTE: is_agent_allowed calls approve_agent or block_agent
  # which handle exit codes (0 for approve, 2 for block)
}

# Execute main
main
