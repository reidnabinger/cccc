#!/usr/bin/env zsh
# nix-run.zsh - Automatically run commands from nixpkgs
#
# Usage:
#   Source this file in your .zshrc:
#     source /path/to/nix-run.zsh
#
#   Then use one of:
#     , cowsay "Hello"           # Explicit: run cowsay from nixpkgs
#     nxr cowsay "Hello"         # Alternative explicit form
#     cowsay "Hello"             # Auto mode: if command_not_found_handler enabled
#
# Configuration (set before sourcing):
#   NIX_RUN_AUTO=1              # Enable command_not_found_handler (default: 0)
#   NIX_RUN_CONFIRM=1           # Ask before running (default: 0)
#   NIX_RUN_CACHE_DIR           # Cache directory (default: ~/.cache/nix-run)

# DEV-NOTE: The comma prefix convention (`, cmd`) is borrowed from the nix community.
# It's short, unlikely to conflict, and visually distinct.

# --- Configuration defaults ---
: "${NIX_RUN_AUTO:=0}"
: "${NIX_RUN_CONFIRM:=0}"
: "${NIX_RUN_CACHE_DIR:=${XDG_CACHE_HOME:-$HOME/.cache}/nix-run}"

# --- Flakes validation ---
# DEV-NOTE: Modern nix commands require experimental features. We validate once
# at load time and bail early with a helpful message rather than failing cryptically.
_NIX_RUN_FLAKES_ENABLED=0

_nix_run_check_flakes() {
  # Check if nix command with flakes works
  if nix eval --expr "true" &>/dev/null; then
    _NIX_RUN_FLAKES_ENABLED=1
    return 0
  fi

  # Try with explicit experimental features
  if nix --experimental-features "nix-command flakes" eval --expr "true" &>/dev/null; then
    _NIX_RUN_FLAKES_ENABLED=2  # Works but needs explicit flag
    return 0
  fi

  return 1
}

# DEV-NOTE: Helper to add experimental features flag when needed
_nix_cmd() {
  if (( _NIX_RUN_FLAKES_ENABLED == 2 )); then
    nix --experimental-features "nix-command flakes" "$@"
  else
    nix "$@"
  fi
}

if ! _nix_run_check_flakes; then
  print -P "%F{red}nix-run.zsh: Error: Nix flakes not available.%f" >&2
  print "Enable flakes by adding to ~/.config/nix/nix.conf:" >&2
  print "  experimental-features = nix-command flakes" >&2
  return 1
fi

# --- Internal state ---
typeset -gA _NIX_RUN_PACKAGE_CACHE

# DEV-NOTE: Package name doesn't always match command name. This map handles
# common cases. Users can extend _NIX_RUN_PACKAGE_MAP in their .zshrc.
typeset -gA _NIX_RUN_PACKAGE_MAP
_NIX_RUN_PACKAGE_MAP=(
  # Command -> Package mappings where they differ
  [python]="python3"
  [python2]="python2"
  [cc]="gcc"
  [c++]="gcc"
  [g++]="gcc"
  [clang++]="clang"
  [node]="nodejs"
  [npm]="nodejs"
  [npx]="nodejs"
  [cargo]="rustc"
  [rustc]="rustc"
  [rustup]="rustup"
  [go]="go"
  [javac]="openjdk"
  [java]="openjdk"
  [convert]="imagemagick"
  [identify]="imagemagick"
  [mogrify]="imagemagick"
  [ffprobe]="ffmpeg"
  [rg]="ripgrep"
  [fd]="fd"
  [bat]="bat"
  [delta]="delta"
  [tree]="tree"
  [jq]="jq"
  [yq]="yq"
  [fzf]="fzf"
  [htop]="htop"
  [btop]="btop"
  [neofetch]="neofetch"
  [cowsay]="cowsay"
  [figlet]="figlet"
  [toilet]="toilet"
  [lolcat]="lolcat"
  [sl]="sl"
  [cmatrix]="cmatrix"
  [nyancat]="nyancat"
)

# --- Helper functions ---

# Resolve command to nixpkgs package name
_nix_run_resolve_package() {
  local cmd="$1"

  # Check explicit mapping first
  if [[ -n "${_NIX_RUN_PACKAGE_MAP[$cmd]}" ]]; then
    print "${_NIX_RUN_PACKAGE_MAP[$cmd]}"
    return 0
  fi

  # Default: assume package name matches command name
  print "$cmd"
}

# Check if package exists in nixpkgs (with caching)
_nix_run_package_exists() {
  local pkg="$1"
  local cache_file="${NIX_RUN_CACHE_DIR}/exists_${pkg}"

  # Check memory cache
  if [[ -n "${_NIX_RUN_PACKAGE_CACHE[$pkg]}" ]]; then
    [[ "${_NIX_RUN_PACKAGE_CACHE[$pkg]}" == "1" ]]
    return
  fi

  # Check file cache (valid for 24 hours)
  # DEV-NOTE: Using zsh's zstat module for portable file stat
  if [[ -f "$cache_file" ]]; then
    zmodload -F zsh/stat b:zstat 2>/dev/null
    local mtime
    if mtime=$(zstat +mtime "$cache_file" 2>/dev/null); then
      local cache_age=$(( $(date +%s) - mtime ))
      if (( cache_age < 86400 )); then
        local result=$(< "$cache_file")
        _NIX_RUN_PACKAGE_CACHE[$pkg]="$result"
        [[ "$result" == "1" ]]
        return
      fi
    fi
  fi

  # Query nixpkgs
  # DEV-NOTE: Using `nix eval` to check package existence. Capture stderr
  # to provide useful error messages for non-existence errors.
  local eval_output eval_stderr eval_status
  eval_stderr=$(_nix_cmd eval --raw "nixpkgs#${pkg}.outPath" 2>&1 >/dev/null)
  eval_status=$?

  if (( eval_status == 0 )); then
    mkdir -p "$NIX_RUN_CACHE_DIR" 2>/dev/null
    print "1" > "$cache_file"
    _NIX_RUN_PACKAGE_CACHE[$pkg]="1"
    return 0
  else
    # Check if it's a "not found" error vs other errors
    if [[ "$eval_stderr" == *"does not provide attribute"* ]] || \
       [[ "$eval_stderr" == *"attribute"*"missing"* ]]; then
      mkdir -p "$NIX_RUN_CACHE_DIR" 2>/dev/null
      print "0" > "$cache_file"
      _NIX_RUN_PACKAGE_CACHE[$pkg]="0"
      return 1
    else
      # Network or other error - don't cache, show error
      print -P "%F{yellow}Warning: nix eval failed: ${eval_stderr}%f" >&2
      return 1
    fi
  fi
}

# Run a command from nixpkgs
# DEV-NOTE: Using consistent modern nix commands (nix shell -c) throughout
# to avoid the legacy/modern command mixing issue.
_nix_run_exec() {
  local cmd="$1"
  shift
  local pkg="$(_nix_run_resolve_package "$cmd")"

  # Confirmation prompt if enabled
  if (( NIX_RUN_CONFIRM )); then
    print -P "%F{yellow}Run '$cmd' from nixpkgs#${pkg}? [y/N]%f " >&2
    read -q || { print >&2; return 1; }
    print >&2
  fi

  # DEV-NOTE: Using `nix shell -c` for all cases. This is the modern approach
  # and works consistently regardless of whether cmd matches pkg.
  # The -- separates nix args from the command to run.
  # Using "$@" properly preserves argument quoting.
  _nix_cmd shell "nixpkgs#${pkg}" -c "$cmd" "$@"
}

# --- Public functions ---

# Explicit runner: `, cowsay "Hello"`
# DEV-NOTE: The comma function is intentionally terse. It's meant to be a quick
# prefix that gets out of your way.
,() {
  if [[ $# -eq 0 ]]; then
    print "Usage: , <command> [args...]" >&2
    print "Run a command from nixpkgs without installing it." >&2
    return 1
  fi

  local cmd="$1"
  shift

  # Check if command already exists locally
  if command -v "$cmd" &>/dev/null; then
    print -P "%F{blue}Note: '$cmd' is already installed locally%f" >&2
  fi

  _nix_run_exec "$cmd" "$@"
}

# Alternative explicit runner with more descriptive name
nxr() {
  , "$@"
}

# Search nixpkgs for a package
nxs() {
  if [[ $# -eq 0 ]]; then
    print "Usage: nxs <search-term>" >&2
    print "Search nixpkgs for packages." >&2
    return 1
  fi
  _nix_cmd search nixpkgs "$@"
}

# --- Command not found handler ---

# DEV-NOTE: This handler is opt-in because automatic execution can be surprising
# and potentially dangerous. Users must explicitly set NIX_RUN_AUTO=1.
# The confirmation prompt also applies in auto mode when NIX_RUN_CONFIRM=1.
if (( NIX_RUN_AUTO )); then
  command_not_found_handler() {
    local cmd="$1"
    shift
    local pkg="$(_nix_run_resolve_package "$cmd")"

    # Check if package exists in nixpkgs
    if _nix_run_package_exists "$pkg"; then
      print -P "%F{yellow}Command '$cmd' not found locally, running from nixpkgs#${pkg}...%f" >&2
      _nix_run_exec "$cmd" "$@"
      return $?
    else
      # Fall back to default behavior
      print -P "%F{red}Command not found: $cmd%f" >&2
      print "Package '$pkg' not found in nixpkgs either." >&2
      return 127
    fi
  }
fi

# --- Completion ---

# DEV-NOTE: Basic completion for the comma function. Completes package names
# from the cache if available, otherwise falls back to command completion.
_nix_run_complete() {
  local -a pkgs

  # Add known mappings
  pkgs=(${(k)_NIX_RUN_PACKAGE_MAP})

  # Add cached packages
  if [[ -d "$NIX_RUN_CACHE_DIR" ]]; then
    for f in "$NIX_RUN_CACHE_DIR"/exists_*; do
      [[ -f "$f" ]] || continue
      [[ $(< "$f") == "1" ]] || continue
      pkgs+=(${f##*/exists_})
    done
  fi

  _describe 'nixpkgs command' pkgs
}

compdef _nix_run_complete , nxr

print -P "%F{green}nix-run.zsh loaded.%f Use '%F{cyan}, <cmd>%f' or '%F{cyan}nxr <cmd>%f' to run commands from nixpkgs."
