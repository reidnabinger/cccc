#!/usr/bin/env bash
#
# namespace-utils.sh - Shared utilities for PWD-based namespace support
#
# Source this file in other scripts to get namespace-aware paths:
#   source "${HOME}/.claude/scripts/namespace-utils.sh"
#
# Namespace = basename of current working directory
# This provides natural parallel work support via git worktrees:
#   - /home/user/project        → namespace "project"
#   - /home/user/project-worktree → namespace "project-worktree"
#
# Provides:
#   get_namespace()    - Returns current namespace (basename of PWD)
#   get_state_file()   - Returns namespace-specific pipeline state file path

# Prevent multiple sourcing
if [[ -n "${_NAMESPACE_UTILS_LOADED:-}" ]]; then
  return 0
fi
readonly _NAMESPACE_UTILS_LOADED=1

# Base state directory
readonly STATE_DIR="${HOME}/.claude/state"

#######################################
# Get current namespace from working directory
# Outputs:
#   Namespace name (basename of PWD) to stdout
#######################################
function get_namespace() {
  basename "$(pwd)"
}

#######################################
# Get namespace-specific pipeline state file path
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
# Outputs:
#   File path to stdout
#######################################
function get_state_file() {
  local -r namespace="${1:-$(get_namespace)}"
  echo "${STATE_DIR}/pipeline-state-${namespace}.json"
}

#######################################
# Get current pipeline state
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
# Outputs:
#   State name to stdout ("IDLE", "GATHERING", etc.)
#######################################
function get_pipeline_state() {
  local -r namespace="${1:-$(get_namespace)}"
  local -r state_file="$(get_state_file "${namespace}")"

  if [[ ! -f "${state_file}" ]]; then
    echo "IDLE"
    return 0
  fi

  jq -r '.state // "IDLE"' "${state_file}" 2>/dev/null || echo "IDLE"
}

#######################################
# Check if pipeline is active (non-IDLE, non-COMPLETE)
# Arguments:
#   $1 - Namespace (optional, uses current if not provided)
# Returns:
#   0 if active, 1 if idle/complete
#######################################
function is_pipeline_active() {
  local -r state="$(get_pipeline_state "$1")"
  [[ "${state}" != "IDLE" && "${state}" != "COMPLETE" ]]
}
