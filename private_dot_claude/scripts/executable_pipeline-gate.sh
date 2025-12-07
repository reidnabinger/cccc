#!/usr/bin/env bash
#
# pipeline-gate.sh - Pipeline state initialization and prompt injection
#
# Called by SessionStart hook with "init" argument
# Called by UserPromptSubmit hook with "check-prompt" argument
#
# Namespace = basename of PWD (e.g., "my-project" for /home/user/gh/my-project)
# State file: ~/.claude/state/pipeline-state-{namespace}.json
# State machine: IDLE → GATHERING → REFINING → ORCHESTRATING_ACTIVE → EXECUTING → COMPLETE
#
# If a pipeline is already running (non-IDLE) in current namespace, offers to
# create a git worktree for parallel work.

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly STATE_DIR="${HOME}/.claude/state"
readonly CACHE_SCRIPT="${HOME}/.claude/scripts/context-cache.sh"

# Namespace derived from current working directory (set by init_namespace)
CURRENT_NAMESPACE=""
STATE_FILE=""

readonly WORKFLOW_INSTRUCTIONS='
ADAPTIVE PIPELINE: The pipeline now supports fast-path routing for simple tasks.

OPTION A - Quick Classification (recommended for focused tasks):
1. FIRST: Invoke task-classifier agent to classify the task complexity
   - TRIVIAL: Single-file simple changes → skip directly to execution agents
   - MODERATE: Focused multi-file → context-gatherer then execution agents
   - COMPLEX: Large scope → full pipeline (gatherer → refiner → orchestrator)
   - EXPLORATORY: Research/understanding → full pipeline

OPTION B - Full Pipeline (for complex/uncertain tasks):
1. FIRST: Invoke context-gatherer agent to exhaustively collect context
2. THEN: Invoke context-refiner agent to distill and analyze the gathered context
3. THEN: Invoke strategic-orchestrator agent to plan the implementation approach
4. FINALLY: Invoke language-specific agents (bash-architect, nix-architect, c-security-architect, etc.)

ROUTING GUIDANCE:
- Use task-classifier when you can quickly assess complexity from the prompt
- Skip to context-gatherer for Bash/C/Nix work (always COMPLEX per project rules)
- TRIVIAL: "fix typo", "add log", "what does X do", single specific file
- MODERATE: "add function to", "fix bug in", "update tests for"
- COMPLEX: "implement", "refactor", "new feature", cross-cutting changes

IMPORTANT: Explore, Plan, and general-purpose agents are NOT exempt from this workflow!
- They may ONLY be used AFTER classification or context-gathering is complete
- Attempting to use them in IDLE state will be BLOCKED by PreToolUse hooks
'

#######################################
# Log message to stderr
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
# Get namespace from current working directory
# Sets global CURRENT_NAMESPACE and STATE_FILE
# Globals:
#   CURRENT_NAMESPACE (modified)
#   STATE_FILE (modified)
#   STATE_DIR
#######################################
function init_namespace() {
  CURRENT_NAMESPACE="$(basename "$(pwd)")"
  STATE_FILE="${STATE_DIR}/pipeline-state-${CURRENT_NAMESPACE}.json"
  log_message "Namespace: ${CURRENT_NAMESPACE}"
}

#######################################
# Check if namespace has an active pipeline
# Globals:
#   STATE_FILE
# Outputs:
#   State name to stdout ("IDLE", "GATHERING", etc.)
#######################################
function get_pipeline_state() {
  if [[ ! -f "${STATE_FILE}" ]]; then
    echo "IDLE"
    return 0
  fi
  jq -r '.state // "IDLE"' "${STATE_FILE}" 2>/dev/null || echo "IDLE"
}

#######################################
# Generate git worktree suggestion message
# Used when namespace has active pipeline and user may want parallel work
# Globals:
#   CURRENT_NAMESPACE
# Arguments:
#   $1 - Current state name
# Outputs:
#   Suggestion text to stdout
#######################################
function worktree_suggestion() {
  local -r state="$1"
  local -r branch_suffix="$(date +%Y%m%d-%H%M%S)"
  local -r suggested_branch="work/${CURRENT_NAMESPACE}-${branch_suffix}"

  cat <<EOF

⚠️  ACTIVE PIPELINE DETECTED in namespace '${CURRENT_NAMESPACE}' (state: ${state})

If you need to work on something else in parallel, create a git worktree:

  git worktree add ../${CURRENT_NAMESPACE}-worktree -b ${suggested_branch}
  cd ../${CURRENT_NAMESPACE}-worktree

Then start a new Claude session there. Each directory = separate namespace.

To continue with the current pipeline, just proceed normally.
EOF
}

#######################################
# Check for cached context for current directory
# Globals:
#   CACHE_SCRIPT
# Outputs:
#   Cached context JSON to stdout, or empty string if miss
#######################################
function get_cached_context() {
  if [[ ! -x "${CACHE_SCRIPT}" ]]; then
    return 0
  fi

  local cache_status
  cache_status=$("${CACHE_SCRIPT}" check "$(pwd)" 2>/dev/null) || true

  if [[ "${cache_status}" == "hit" ]]; then
    "${CACHE_SCRIPT}" get "$(pwd)" 2>/dev/null || true
  fi
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
# Creates state directory and initial state file for current namespace
# Globals:
#   STATE_DIR
#   STATE_FILE
#   CURRENT_NAMESPACE
# Outputs:
#   JSON with hookSpecificOutput (SessionStart format) to stdout
# Returns:
#   0 on success, 1 on failure
#######################################
function initialize_state() {
  log_message "Initializing pipeline state for namespace: ${CURRENT_NAMESPACE}"

  # Create state directory if needed
  if [[ ! -d "${STATE_DIR}" ]]; then
    if ! mkdir -p "${STATE_DIR}"; then
      log_message "ERROR: Failed to create state directory: ${STATE_DIR}"
      return 1
    fi
    log_message "Created state directory: ${STATE_DIR}"
  fi

  # Only create initial state if file doesn't exist or is in IDLE/COMPLETE state
  # This preserves in-progress pipelines across session restarts
  local current_state="IDLE"
  if [[ -f "${STATE_FILE}" ]]; then
    current_state="$(jq -r '.state // "IDLE"' "${STATE_FILE}" 2>/dev/null)" || current_state="IDLE"
  fi

  if [[ ! -f "${STATE_FILE}" ]] || [[ "${current_state}" == "IDLE" ]] || [[ "${current_state}" == "COMPLETE" ]]; then
    local -r initial_state="$(create_initial_state)"
    if ! write_state_atomic "${initial_state}"; then
      log_message "ERROR: Failed to initialize state file"
      return 1
    fi
    log_message "Pipeline state initialized successfully"
  else
    log_message "Preserving existing pipeline state: ${current_state}"
  fi

  # Output JSON for SessionStart hook response
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Namespace '${CURRENT_NAMESPACE}' ready (state: ${current_state})"
  }
}
EOF

  return 0
}

#######################################
# Check prompt and inject workflow if needed
# Reads current state and determines if workflow instructions needed
# Also checks for cached context and includes it if available
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

    # Check for cached context
    local cached_context=""
    cached_context=$(get_cached_context)

    local full_instructions="${WORKFLOW_INSTRUCTIONS}"

    if [[ -n "${cached_context}" ]]; then
      log_message "Cached context found, including in injection"
      # Extract the gathered and refined context from cache
      local gathered refined
      gathered=$(echo "${cached_context}" | jq -r '.gathered // .context.gathered // ""' 2>/dev/null)
      refined=$(echo "${cached_context}" | jq -r '.refined // .context.refined // ""' 2>/dev/null)
      local cache_time
      cache_time=$(echo "${cached_context}" | jq -r '._cache_metadata.cached_at // "unknown"' 2>/dev/null)

      if [[ -n "${gathered}" || -n "${refined}" ]]; then
        full_instructions="${WORKFLOW_INSTRUCTIONS}

--- CACHED CONTEXT (from ${cache_time}) ---

NOTE: Previous context-gathering for this codebase is available below.
You may use this to skip or accelerate context-gathering if still relevant.
The codebase fingerprint matched, meaning file structure hasn't changed significantly.

If the cached context is stale or the task requires fresh analysis, proceed with
normal context-gathering. Otherwise, you may reference this and potentially skip
directly to context-refiner or strategic-orchestrator.

GATHERED CONTEXT:
${gathered}

REFINED CONTEXT:
${refined}

--- END CACHED CONTEXT ---
"
      fi
    fi

    # Escape full instructions for JSON
    local -r escaped_instructions="$(echo "${full_instructions}" | jq -Rs .)"

    cat <<EOF
{
  "continue": true,
  "additional_context": ${escaped_instructions}
}
EOF
  elif [[ "${current_state}" == "COMPLETE" ]]; then
    # COMPLETE state - reset to IDLE for next task
    log_message "COMPLETE state, resetting to IDLE"
    local -r initial_state="$(create_initial_state)"
    write_state_atomic "${initial_state}" >/dev/null 2>&1 || true

    local -r escaped_instructions="$(echo "${WORKFLOW_INSTRUCTIONS}" | jq -Rs .)"
    cat <<EOF
{
  "continue": true,
  "additional_context": ${escaped_instructions}
}
EOF
  else
    # Active pipeline (GATHERING, REFINING, ORCHESTRATING_ACTIVE, EXECUTING)
    # Show worktree suggestion in case user wants parallel work
    log_message "Active pipeline (${current_state}), showing worktree suggestion"

    local -r suggestion="$(worktree_suggestion "${current_state}")"
    local -r escaped_suggestion="$(echo "${suggestion}" | jq -Rs .)"

    cat <<EOF
{
  "continue": true,
  "additional_context": ${escaped_suggestion}
}
EOF
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

  # Initialize namespace from current working directory
  # This sets CURRENT_NAMESPACE and STATE_FILE globals
  init_namespace

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
