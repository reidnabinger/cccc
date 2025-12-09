# Quick Start - Role-Reversed Agent Pipeline

## The Core Idea

**YOU write all code.** Agents gather intelligence and review your work.

## Important: Session Reload

Custom agents are discovered at **session startup**. After adding or modifying agents:
1. Exit current Claude Code session
2. Start a new session: `claude`
3. Verify with `/agents` command

## Quick Reference

### Before Implementing

```
# For complex tasks, ALWAYS start with git history
Task(subagent_type="git-agent", prompt="Analyze recent history for [AREA]")

# Gather intelligence as needed
Task(subagent_type="context7-agent", prompt="Look up docs for [LIBRARY]")
Task(subagent_type="architecture-analyst", prompt="Analyze structure of [AREA]")
Task(subagent_type="conventions-analyst", prompt="Identify patterns in [AREA]")
```

### After Implementing

```
# Get brutal review from domain advisor
Task(subagent_type="bash-advisor", prompt="Review [FILE]")  # for Bash
Task(subagent_type="c-advisor", prompt="Review [FILE]")     # for C
Task(subagent_type="nix-advisor", prompt="Review [FILE]")   # for Nix
Task(subagent_type="python-advisor", prompt="Review [FILE]") # for Python

# Verify
Task(subagent_type="test-interpreter", prompt="Run tests for [AREA]")
Task(subagent_type="lint-interpreter", prompt="Run linters for [AREA]")
```

## Agent Cheat Sheet

| Need | Agent | Tool |
|------|-------|------|
| Library docs | context7-agent | Context7 MCP |
| Code structure | serena-agent | Serena MCP |
| Best practices | websearch-agent | WebSearch |
| Git history | git-agent | Git commands |
| Complex reasoning | sequential-thinking-agent | SequentialThinking |
| GitHub examples | github-search-agent | WebSearch + WebFetch |
| Claude Code docs | claude-docs-agent | claude-code-guide |
| URL content | webfetch-agent | WebFetch |
| Project patterns | conventions-analyst | Read/Grep/Glob |
| Architecture review | architecture-analyst | Read/Grep/Glob |
| Bash review | bash-advisor | Read/Grep/Glob |
| C review | c-advisor | Read/Grep/Glob |
| Nix review | nix-advisor | Read/Grep/Glob |
| Python review | python-advisor | Read/Grep/Glob |
| Test results | test-interpreter | Bash |
| Lint results | lint-interpreter | Bash |
| Multi-source synthesis | strategist | Task + SequentialThinking |

## Golden Rules

1. **git-agent is MANDATORY** for complex tasks - always check history first
2. **YOU write all code** - agents don't execute, they inform and review
3. **Advisors are brutal** - they will find your bugs, that's the point
4. **Always verify** - run tests and linters after implementing

## Example Workflows

### Simple Task (add a function)
```
1. Just do it - no agents needed for trivial work
```

### Moderate Task (fix a bug)
```
1. git-agent → understand recent changes
2. YOU implement the fix
3. domain-advisor → review your fix
4. test-interpreter → verify tests pass
```

### Complex Task (new feature)
```
1. git-agent → history context
2. architecture-analyst → understand structure
3. conventions-analyst → learn patterns
4. context7-agent → library docs
5. strategist → synthesize into plan
6. YOU implement
7. domain-advisor → brutal review
8. test-interpreter + lint-interpreter → verify
```

## What Changed from the Old Model

**Before (delegation model):**
- context-gatherer → context-refiner → strategic-orchestrator → execution agents
- Subagents wrote code

**Now (role-reversal model):**
- Tool-agents gather intelligence
- YOU write code
- Advisors brutally review

The key insight: centralized execution with distributed intelligence and review produces higher quality results.
