#!/usr/bin/env python3
"""
hook-enforcer.py - Native hook enforcement for Claude Code

This script is called by Claude Code hooks to enforce rules defined in the
hookify system, converted to native hooks. It uses activity-tracker.py for
session state management.

Usage:
    hook-enforcer.py pre-tool <tool_name>   - PreToolUse enforcement
    hook-enforcer.py post-tool <tool_name>  - PostToolUse tracking
    hook-enforcer.py stop                   - Stop hook enforcement
    hook-enforcer.py session-start          - SessionStart initialization

The script reads tool input from stdin (JSON) and outputs a JSON response.

Exit codes:
    0 - Allow (or warn)
    2 - Block

Environment:
    HOOK_ENFORCER_DEBUG - Enable debug logging to stderr
"""

from __future__ import annotations

import json
import logging
import os
import subprocess
import sys
from pathlib import Path
from typing import Any

# Configure logging
if os.environ.get("HOOK_ENFORCER_DEBUG"):
    logging.basicConfig(
        level=logging.DEBUG,
        format="%(asctime)s [hook-enforcer] %(message)s",
        stream=sys.stderr,
    )
else:
    logging.basicConfig(level=logging.WARNING, stream=sys.stderr)

logger = logging.getLogger(__name__)

# Path to activity tracker
ACTIVITY_TRACKER = Path(__file__).parent / "activity-tracker.py"

# Tool-agents that should be tracked
TOOL_AGENTS = frozenset({
    "serena-agent",
    "context7-agent",
    "websearch-agent",
    "webfetch-agent",
    "sequential-thinking-agent",
    "github-search-agent",
    "claude-docs-agent",
    "git-agent",
    "Explore",
    "Plan",
    "general-purpose",
})

# Advisors that should be tracked
ADVISORS = frozenset({
    "bash-advisor",
    "c-advisor",
    "nix-advisor",
    "python-advisor",
    "architecture-analyst",
    "conventions-analyst",
    "critical-code-reviewer",
    "lint-interpreter",
    "test-interpreter",
})

# Tools that constitute "file editing"
FILE_EDIT_TOOLS = frozenset({"Edit", "Write", "NotebookEdit"})


def _get_session_gppid() -> int:
    """Get the GPPID for this session.

    DEV-NOTE: This is calculated once at module load and passed to
    activity-tracker.py via environment variable. This ensures all
    subprocess calls use the same session ID regardless of process
    tree depth.
    """
    ppid = os.getppid()
    try:
        with open(f"/proc/{ppid}/stat", "r") as f:
            content = f.read()
        last_paren = content.rfind(")")
        if last_paren != -1:
            fields_after_name = content[last_paren + 1 :].split()
            return int(fields_after_name[1])
    except (FileNotFoundError, IndexError, ValueError, OSError):
        pass
    return ppid


# Session GPPID - calculated once at startup
SESSION_GPPID = _get_session_gppid()


def run_tracker(args: list[str]) -> tuple[int, str]:
    """Run activity-tracker.py with given arguments.

    Returns:
        Tuple of (exit_code, stdout)
    """
    cmd = ["python3", str(ACTIVITY_TRACKER)] + args
    logger.debug(f"Running tracker: {cmd}")

    # Pass our GPPID to activity-tracker via environment
    env = os.environ.copy()
    env["CLAUDE_SESSION_GPPID"] = str(SESSION_GPPID)

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=10,
            env=env,
        )
        logger.debug(f"Tracker result: exit={result.returncode}, out={result.stdout[:200]}")
        return result.returncode, result.stdout
    except subprocess.TimeoutExpired:
        logger.error("Activity tracker timed out")
        return 1, '{"error": "tracker timeout"}'
    except Exception as e:
        logger.error(f"Failed to run tracker: {e}")
        return 1, f'{{"error": "{e}"}}'


def track(track_type: str, data: str = "") -> None:
    """Track an activity."""
    args = ["track", track_type]
    if data:
        args.append(data)
    run_tracker(args)


def check_rule(rule: str, extra: str = "") -> tuple[bool, dict]:
    """Check if a rule passes.

    Returns:
        Tuple of (passed, result_dict)
    """
    args = ["check", rule]
    if extra:
        args.append(extra)
    exit_code, stdout = run_tracker(args)

    try:
        result = json.loads(stdout)
    except json.JSONDecodeError:
        result = {"passed": False, "reason": "Failed to parse tracker output"}

    return exit_code == 0, result


def read_stdin_json() -> dict[str, Any]:
    """Read JSON from stdin (tool input from Claude Code)."""
    try:
        content = sys.stdin.read()
        if content.strip():
            return json.loads(content)
    except json.JSONDecodeError as e:
        logger.warning(f"Failed to parse stdin JSON: {e}")
    return {}


def output_block(reason: str) -> None:
    """Output a block decision and exit."""
    print(json.dumps({"decision": "block", "reason": reason}))
    sys.exit(2)


def output_allow() -> None:
    """Output an allow decision and exit."""
    print(json.dumps({"decision": "approve"}))
    sys.exit(0)


def output_warn(message: str) -> None:
    """Output a warning (allow but with message) and exit."""
    # Warnings still allow the operation but include context
    print(json.dumps({"decision": "approve", "warning": message}))
    sys.exit(0)


# --- Rule messages (from hookify files) ---

MSG_TODO_BEFORE_EDIT = """
# BLOCKED: To-Do List Required Before Editing

You are attempting to edit files without having created a To-Do list first.

## The Pipeline Requires:

1. Tool-agents gather intelligence
2. Sequential-thinking plans approach
3. TodoWrite creates actionable plan ← MUST HAPPEN FIRST
4. THEN Edit/Write files

## Why This Matters:

- Editing without a plan is impulsive
- The To-Do list is your contract with yourself
- If you can't write down what you're doing, you don't know what you're doing

**No plan, no edit. Use TodoWrite first.**
"""

MSG_TOOL_AGENTS_BEFORE_EDIT = """
# BLOCKED: Tool-Agent Intelligence Required Before Implementation

You are attempting to edit files without first gathering intelligence from tool-agents.

## Your Pipeline Requires:

### For Simple Tasks (minimum):
- [ ] **git-agent** - Check history, recent changes, developer context

### For Complex Tasks (all applicable):
- [ ] **git-agent** - History, blame, evolution (MANDATORY)
- [ ] **serena-agent** - Code structure, symbols, references
- [ ] **context7-agent** - Library/API documentation
- [ ] **websearch-agent** - Best practices, external knowledge
- [ ] **webfetch-agent** - Fetch full pages from websearch-agent
- [ ] **claude-docs-agent** - Learn about Claude Code direct from the creators!
- [ ] **github-search-agent** - How did other people solve similar problems?

**Invoke tool-agents first, THEN implement.**
"""

MSG_SEQUENTIAL_BEFORE_TODO = """
# BLOCKED: Sequential Thinking Required Before To-Do Creation

You are attempting to write a To-Do list without first using sequential-thinking.

## Before Writing To-Do, Use Sequential Thinking To:

- [ ] **Evaluate gathered intelligence** - What did tool-agents reveal?
- [ ] **Identify gaps** - Is more context needed?
- [ ] **Plan the approach** - What's the right order of operations?
- [ ] **Consider risks** - What could go wrong?
- [ ] **Should I get more context?**
- [ ] **Do I fully understand the INTENT here?**
- [ ] **Are there any DEV-NOTEs in the files?**

Use `mcp__sequential-thinking__sequentialthinking` to think through the task.

**Think first. To-Do second.**
"""

MSG_ADVISORS_BEFORE_STOP = """
# BLOCKED: Adversarial Review Required Before Completion

You are attempting to complete a task without adversarial review.

## Your Pipeline Requires Review By:

### Domain Advisor (based on language used):
- [ ] **bash-advisor** - If you wrote shell scripts
- [ ] **c-advisor** - If you wrote C code
- [ ] **nix-advisor** - If you wrote Nix expressions
- [ ] **python-advisor** - If you wrote Python code

### Critical Review:
- [ ] **critical-code-reviewer** - For ANY significant code implementation
- [ ] **docs-reviewer** - Did you update the docs while you know what is going on?
- [ ] **sequential-thinking-agent** - Ask him if he can ultrathink about your solution

### Verifiers:
- [ ] **test-interpreter** - Run tests, interpret failures
- [ ] **lint-interpreter** - Run linters, interpret results

**Your code must survive adversarial review before the task is complete.**
"""

MSG_REFLECTION_BEFORE_STOP = """
# BLOCKED: Critical Reflection Required Before Completion

You are attempting to complete the task without using sequential-thinking to
critically evaluate the reviews and your work.

## Before Stopping, Use Sequential Thinking To:

### 1. Process Review Feedback
- [ ] What did the domain advisors say?
- [ ] What did the critical-code-reviewer find?
- [ ] Have ALL issues been addressed?

### 2. Evaluate Completion
- [ ] Does the implementation match the original request?
- [ ] Did you miss any edge cases?
- [ ] Would YOU be satisfied receiving this work?

### 3. Question Your Confidence
- [ ] Why do you think this is done?
- [ ] What could you have missed?
- [ ] Is your confidence justified?
- [ ] Are there still any gaps in your understanding of the problem/solution?

Use `mcp__sequential-thinking__sequentialthinking` to reflect.
Give yourself a rating out of 100.

**Receive reviews. Reflect critically. Only then complete.**
"""

MSG_WARN_LARGE_EDIT = """
# ⚠️ Large Edit Warning

You are making a substantial edit. Large changes are riskier than small, verified steps.

## Better Approach:

1. **Break it into chunks** - Edit one function/component at a time
2. **Incremental verification** - Run tests after each meaningful change
3. **Commit points** - Each chunk should leave the code working

**Smaller is safer. Incremental is intelligent.**
"""

MSG_WARN_REPEATED_EDIT = """
# ⚠️ Repeated Edit Warning

You are editing a file again. This might indicate:

1. **Thrashing** - Making changes without a clear plan
2. **Incomplete thinking** - Not fully reasoning through the change
3. **Fixing your own mistakes** - The previous edit was wrong
4. **Scope creep** - Adding things you didn't plan for

## If You're Thrashing:

1. STOP editing
2. Use sequential-thinking to reassess
3. Request more focused intelligence from tool-agents
4. Ask for feedback from an adversarial reviewer.
5. Update your To-Do if the plan was wrong
6. Then continue with clarity

**Repeated edits are a smell. Pay attention.**
"""

MSG_WARN_SCOPE_CREEP = """
# ⚠️ Scope Creep Warning

You are editing a file. Check whether this edit is part of your plan.

## Questions To Ask:

1. **Is this file in your To-Do list?** If no → WHY are you editing it?
2. **Is this edit necessary for the task?** Or are you "improving" unrelated things?
3. **Are you gold-plating?** Adding features that weren't asked for?
4. **Are you aware of all of the code that depends on this code's _EXACT_ behavior?**
5. **Do you understand why it was written this way in the first place? (git-agent)**

## Signs of Scope Creep:

- "While I'm here, I'll also..."
- "This would be better if..."
- "Let me just clean up..."

**Do what was asked. Nothing more.**
"""

MSG_BLOCK_CCCC_PROJECT_CONFIG = """
# BLOCKED: Project-Level Configuration Denied in cccc

You are attempting to create project-level Claude Code configuration in the cccc repository.

**This is categorically forbidden.**

## Why No Project-Level Config Here

The cccc repository IS the chezmoi source for `~/.claude`. It defines the GLOBAL
configuration. Any config for cccc should BE global config - just edit the source files.

## The Correct Pattern

| You want to... | Write to... |
|----------------|-------------|
| Add a hookify rule | `private_dot_claude/hookify.*.local.md` |
| Change settings | `private_dot_claude/settings.json` |
| Add an agent | `private_dot_claude/agents/*.md` |

Then run `chezmoi apply` to deploy globally.

**Edit the source in private_dot_claude/, then chezmoi apply.**
"""


# --- Hook handlers ---


def handle_pre_tool(tool_name: str, tool_input: dict[str, Any]) -> None:
    """Handle PreToolUse hook."""
    # DEV-NOTE: Claude Code wraps tool input as {"tool_input": {...actual fields...}}
    # Unwrap if nested
    if "tool_input" in tool_input and isinstance(tool_input["tool_input"], dict):
        tool_input = tool_input["tool_input"]
    logger.debug(f"PreToolUse: {tool_name}, input keys: {list(tool_input.keys())}")

    # --- TodoWrite checks ---
    if tool_name == "TodoWrite":
        passed, result = check_rule("sequential_before_todo")
        if not passed:
            output_block(MSG_SEQUENTIAL_BEFORE_TODO)
        # Track that todo was created (will be done in post-tool)
        output_allow()

    # --- File edit checks ---
    if tool_name in FILE_EDIT_TOOLS:
        # Extract file path from tool input
        file_path = tool_input.get("file_path", "")

        # Block: cccc project config
        if file_path and "gh/cccc/.claude" in file_path:
            output_block(MSG_BLOCK_CCCC_PROJECT_CONFIG)

        # Block: No todo created
        passed, result = check_rule("todo_before_edit")
        if not passed:
            output_block(MSG_TODO_BEFORE_EDIT)

        # Block: No tool-agents invoked
        passed, result = check_rule("tool_agents_before_edit")
        if not passed:
            output_block(MSG_TOOL_AGENTS_BEFORE_EDIT)

        # Warn: Repeated edit
        if file_path:
            passed, _ = check_rule("file_already_edited", file_path)
            if passed:  # File WAS already edited
                output_warn(MSG_WARN_REPEATED_EDIT)

        # Warn: Large edit (check old_string length for Edit tool)
        if tool_name == "Edit":
            old_string = tool_input.get("old_string", "")
            new_string = tool_input.get("new_string", "")
            if len(old_string) > 500 or len(new_string) > 500:
                output_warn(MSG_WARN_LARGE_EDIT)

        # Warn: Write tool creating large file
        if tool_name == "Write":
            content = tool_input.get("content", "")
            if len(content) > 2000:
                output_warn(MSG_WARN_LARGE_EDIT)

        output_allow()

    # --- Task tool (subagent) checks ---
    if tool_name == "Task":
        subagent_type = tool_input.get("subagent_type", "")

        # Track tool-agents and advisors
        if subagent_type in TOOL_AGENTS:
            track("tool_agent", subagent_type)
        elif subagent_type in ADVISORS:
            track("advisor", subagent_type)

        # Track sequential-thinking
        if subagent_type == "sequential-thinking-agent":
            track("sequential_thinking")

        output_allow()

    # --- MCP sequential thinking ---
    if tool_name.startswith("mcp__sequential-thinking"):
        track("sequential_thinking")
        output_allow()

    # Default: allow
    output_allow()


def handle_post_tool(tool_name: str, tool_input: dict[str, Any]) -> None:
    """Handle PostToolUse hook."""
    # DEV-NOTE: Claude Code wraps tool input as {"tool_input": {...actual fields...}}
    # Unwrap if nested
    if "tool_input" in tool_input and isinstance(tool_input["tool_input"], dict):
        tool_input = tool_input["tool_input"]
    logger.debug(f"PostToolUse: {tool_name}")

    # Track file edits
    if tool_name in FILE_EDIT_TOOLS:
        file_path = tool_input.get("file_path", "")
        if file_path:
            track("file_edit", file_path)

    # Track todo creation
    if tool_name == "TodoWrite":
        track("todo_created")

    # PostToolUse always succeeds (just tracking)
    print(json.dumps({"status": "tracked"}))
    sys.exit(0)


def handle_stop() -> None:
    """Handle Stop hook."""
    logger.debug("Stop hook triggered")

    # DEV-NOTE: Only require adversarial review if code was actually written.
    # This prevents blocking on pure information-gathering sessions.
    _, state_output = run_tracker(["get"])
    try:
        state = json.loads(state_output)
        files_edited = state.get("files_edited", [])
    except json.JSONDecodeError:
        # Fail-safe: if we can't parse state, require review
        files_edited = ["unknown"]

    if not files_edited:
        logger.debug("No files edited this session, skipping adversarial review")
        output_allow()
        return

    # Check advisors were invoked
    passed, result = check_rule("advisors_before_stop")
    if not passed:
        output_block(MSG_ADVISORS_BEFORE_STOP)

    # Check reflection after advisors
    passed, result = check_rule("reflection_before_stop")
    if not passed:
        output_block(MSG_REFLECTION_BEFORE_STOP)

    output_allow()


def handle_session_start() -> None:
    """Handle SessionStart hook."""
    logger.debug("SessionStart hook triggered")

    # Initialize activity tracker state
    run_tracker(["init"])

    # Clean up stale state files
    run_tracker(["cleanup"])

    print(json.dumps({"status": "initialized"}))
    sys.exit(0)


def main() -> None:
    """Main entry point."""
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd in ("--help", "-h", "help"):
        print(__doc__)
        sys.exit(0)

    # Read tool input from stdin
    tool_input = read_stdin_json()

    if cmd == "pre-tool":
        if len(sys.argv) < 3:
            print(json.dumps({"error": "pre-tool requires tool_name argument"}))
            sys.exit(1)
        tool_name = sys.argv[2]
        handle_pre_tool(tool_name, tool_input)

    elif cmd == "post-tool":
        if len(sys.argv) < 3:
            print(json.dumps({"error": "post-tool requires tool_name argument"}))
            sys.exit(1)
        tool_name = sys.argv[2]
        handle_post_tool(tool_name, tool_input)

    elif cmd == "stop":
        handle_stop()

    elif cmd == "session-start":
        handle_session_start()

    else:
        print(json.dumps({"error": f"Unknown command: {cmd}"}))
        sys.exit(1)


if __name__ == "__main__":
    main()
