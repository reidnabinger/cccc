---
name: context-pipeline
description: Orchestrated agent pipeline for complex development tasks. Ensures proper context flow through context-gatherer, context-refiner, strategic-orchestrator, then domain-specific agents. Use when implementing features, fixing bugs, or making architectural changes that benefit from specialized expertise.
---

# Context Pipeline - Action Required

This skill initiates the context pipeline for complex development work requiring specialized agents.

## IMMEDIATE ACTION

You must now invoke the pipeline. Choose ONE approach based on task complexity:

### Option A: Quick Classification (Recommended)

If you can assess complexity from the user's request, use the task-classifier first:

```
Task(
  subagent_type="task-classifier",
  model="haiku",
  description="Classify task complexity",
  prompt="Classify this task: [USER'S ORIGINAL REQUEST]"
)
```

The classifier returns JSON with `classification` (TRIVIAL/MODERATE/COMPLEX/EXPLORATORY) that determines the pipeline path.

### Option B: Full Pipeline (For Complex/Uncertain Tasks)

If the task is clearly complex or you're unsure, skip classification and go straight to full context gathering:

```
Task(
  subagent_type="context-gatherer",
  description="Gather context for task",
  prompt="Gather all relevant context for: [USER'S ORIGINAL REQUEST]"
)
```

## Pipeline Flow (Automatic After Start)

Once you invoke the starting agent, the **self-advancing chain** handles the rest:

```
You invoke context-gatherer
        ↓ (auto-advances)
context-refiner runs
        ↓ (auto-advances)
strategic-orchestrator runs
        ↓ (deploys domain specialists)
Specialized agents execute
        ↓
Final result returned to you
```

**You only need to start the pipeline.** The agents advance themselves.

## After Classification (If Using Option A)

Based on the classifier's response:

| Classification | Next Action |
|----------------|-------------|
| **TRIVIAL** | Proceed directly with appropriate specialized agents |
| **MODERATE** | Invoke context-gatherer, then execute (skips refiner/orchestrator) |
| **COMPLEX** | Invoke context-gatherer (full pipeline with orchestration) |
| **EXPLORATORY** | Invoke context-gatherer (full pipeline for research) |

## Available Domain Specialists

The strategic-orchestrator will deploy appropriate specialists based on the task:

**Bash**: bash-architect, bash-error-handler, bash-style-enforcer, bash-security-reviewer, bash-tester, bash-optimizer, bash-debugger

**Nix**: nix-architect, nix-module-writer, nix-package-builder, nix-reviewer, nix-debugger

**C**: c-security-architect, c-security-coder, c-memory-safety-auditor, c-privilege-auditor, c-race-condition-auditor, c-static-analyzer, c-security-reviewer, c-security-tester

**Python**: python-architect, python-security-reviewer, python-ml-specialist, python-test-writer, python-quality-enforcer, python-async-specialist

**General**: critical-code-reviewer, docs-reviewer

**Future**: Rust, Go, TypeScript, SQL, Terraform, Kubernetes specialists (per Priority 6)

## Important Rules

1. **Tasks requiring specialized expertise benefit from full pipeline** - Context gathering ensures agents have what they need
2. **Security-sensitive tasks are ALWAYS COMPLEX** - Auth, permissions, encryption need full pipeline
3. **When uncertain, go COMPLEX** - Better to over-prepare than under-prepare
4. **Pass the user's full request** - Agents need the original context to work effectively

## DO THIS NOW

1. Look at the user's request that led to this skill being invoked
2. Decide: Is complexity obvious? Use Option B (context-gatherer). Otherwise use Option A (task-classifier).
3. Invoke the appropriate Task with the user's original request
4. Report the pipeline's final results back to the user

**START THE PIPELINE NOW** by invoking task-classifier or context-gatherer with the user's request.
