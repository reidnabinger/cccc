---
description: Structured bug investigation with tool-agents and root cause analysis
---

# Bug Investigation: $ARGUMENTS

You are investigating a bug or issue. Follow this structured approach.

## Phase 1: Understand the Problem

Before touching any code, gather context:

1. **Clarify the symptom** - What exactly is happening vs. what should happen?
2. **Reproduce mentally** - What steps trigger this?
3. **Scope the blast radius** - What areas of code could be involved?

## Phase 2: Gather Intelligence (MANDATORY)

Invoke these tool-agents to gather context:

### Required Agents:

```
1. git-agent - Find recent changes, who touched relevant code, any related commits
2. serena-agent - Map the code structure, find references, understand call paths
```

### If the bug involves external libraries:
```
3. context7-agent - Check library documentation for relevant behavior
4. websearch-agent - Search for known issues, similar bug reports
```

## Phase 3: Form Hypotheses

After gathering intelligence, use **sequential-thinking** to:

1. List all possible causes (minimum 3 hypotheses)
2. Rank by likelihood based on evidence
3. Identify what would confirm/refute each hypothesis
4. Plan investigation order (most likely first)

Use the MCP tool:
```
mcp__sequential-thinking__sequentialthinking
```

## Phase 4: Investigate Systematically

For each hypothesis:

1. **Predict** - What would I see if this hypothesis is correct?
2. **Test** - Check the code/logs/behavior
3. **Conclude** - Confirmed, refuted, or need more data?

**DO NOT** start fixing until you've confirmed the root cause.

## Phase 5: Confirm Root Cause

Before any fix, verify:

- [ ] You can explain WHY the bug occurs (not just WHERE)
- [ ] You can predict what the fix should change
- [ ] You understand any side effects of the fix

## Phase 6: Plan the Fix

Create a TodoWrite with:

1. The specific change(s) needed
2. Files to modify
3. Tests to verify the fix
4. Regression tests to prevent recurrence

## Output Format

Provide a structured investigation report:

```markdown
## Investigation: [Bug Description]

### Symptom
[What's happening]

### Intelligence Gathered
- git-agent: [Key findings]
- serena-agent: [Code structure insights]

### Hypotheses (Ranked)
1. [Most likely] - Evidence: [...]
2. [Second] - Evidence: [...]
3. [Third] - Evidence: [...]

### Investigation Results
- Hypothesis 1: [Confirmed/Refuted] - [Evidence]
- Hypothesis 2: [Confirmed/Refuted] - [Evidence]

### Root Cause
[Clear explanation of WHY the bug occurs]

### Recommended Fix
[What needs to change and why]

### Verification Plan
[How to confirm the fix works]
```

## Anti-Patterns to Avoid

- ❌ Jumping to the first plausible fix
- ❌ Fixing symptoms instead of root cause
- ❌ Skipping the hypothesis phase
- ❌ Not checking git history for context
- ❌ Assuming you know the cause before investigating

**Investigate thoroughly. Fix confidently.**
