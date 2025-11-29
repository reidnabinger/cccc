---
name: context-pipeline
description: Orchestrated agent pipeline for Bash, C, and Nix tasks. Ensures proper context flow through context-gatherer, context-refiner, strategic-orchestrator, then language-specific agents. Use when implementing features, fixing bugs, or making architectural changes in these languages.
---

# Context Pipeline Workflow

## Purpose

This skill defines the mandatory workflow for all Bash, C, and Nix development tasks. It ensures that:
1. All relevant context is gathered before implementation begins
2. Context is refined and distilled for actionable intelligence
3. A strategic plan is created before any code changes
4. The appropriate language-specific agents are invoked in sequence

## Workflow Stages

### Stage 1: Context Gathering (context-gatherer agent)
**State: IDLE -> GATHERING**

Invoke the `context-gatherer` agent to exhaustively collect:
- Related source files and their dependencies
- Configuration files and build system setup
- Documentation and inline comments
- Git history for relevant files
- Test files and their coverage
- Any external resources or references

The gathered context is stored in the pipeline state for downstream agents.

### Stage 2: Context Refining (context-refiner agent)
**State: GATHERING -> REFINING**

Invoke the `context-refiner` agent to:
- Distill the massive gathered context into clear, actionable intelligence
- Identify conflicts or ambiguities in the requirements
- Extract key patterns and conventions from the codebase
- Highlight potential risks or areas requiring special attention
- Create a condensed context summary for the orchestrator

### Stage 3: Strategic Orchestration (strategic-orchestrator agent)
**State: REFINING -> EXECUTING**

Invoke the `strategic-orchestrator` agent to:
- Analyze the refined context and task requirements
- Determine which language-specific agents are needed
- Create an execution plan with sequencing and dependencies
- Identify parallelization opportunities
- Assign specific responsibilities to each agent

### Stage 4: Language-Specific Execution
**State: EXECUTING**

Based on the orchestrator's plan, invoke the appropriate agents:

**For Bash tasks:**
- `bash-architect` - Design script structure and approach
- `bash-error-handler` - Add proper error handling
- `bash-style-enforcer` - Ensure Google Style Guide compliance
- `bash-security-reviewer` - Security audit
- `bash-tester` - Create bats tests
- `bash-optimizer` - Performance improvements (if needed)
- `bash-debugger` - Debug issues

**For Nix tasks:**
- `nix-architect` - Design module/package structure
- `nix-module-writer` - Implement NixOS modules
- `nix-package-builder` - Create package derivations
- `nix-reviewer` - Review for anti-patterns
- `nix-debugger` - Debug evaluation errors

**For C tasks:**
- `c-security-architect` - Design secure implementation
- `c-security-coder` - Implement security-critical code
- `c-memory-safety-auditor` - Audit memory safety
- `c-privilege-auditor` - Audit privilege escalation
- `c-race-condition-auditor` - Check for race conditions
- `c-static-analyzer` - Run automated analysis
- `c-security-reviewer` - Comprehensive review
- `c-security-tester` - Create security tests

## Pipeline Enforcement

The pipeline is enforced by hooks:
- **PreToolUse hook on Task**: Blocks language-specific agents until context pipeline completes
- **SubagentStop hook**: Advances state machine after each agent completes
- **UserPromptSubmit hook**: Injects workflow instructions when starting new tasks

## Utility Agents

These agents bypass pipeline restrictions and can be used at any time:
- `Explore` - Quick codebase exploration
- `Plan` - Fast planning and searching
- `general-purpose` - Multi-step research tasks

## State Machine Reference

| Current State | Allowed Agents | Next State |
|---------------|----------------|------------|
| IDLE | context-gatherer | GATHERING |
| GATHERING | context-refiner | REFINING |
| REFINING | strategic-orchestrator | EXECUTING |
| EXECUTING | bash-*, nix-*, c-* | EXECUTING |
| COMPLETE | context-gatherer | GATHERING |

## Manual Reset

If the pipeline gets stuck, reset with:
```bash
~/.claude/scripts/reset-pipeline-state.sh
```

## Example Usage

When a user asks to implement a feature:

1. Claude automatically invokes `context-gatherer` to understand the codebase
2. The gathered context is passed to `context-refiner` for distillation
3. The refined context goes to `strategic-orchestrator` for planning
4. The orchestrator decides: "This needs bash-architect, then bash-error-handler, then bash-tester"
5. Each language agent is invoked in sequence with full context

This ensures thorough, well-planned implementations that follow all project conventions.
