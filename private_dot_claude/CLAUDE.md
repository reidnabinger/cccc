- DO NOT GIVE YOURSELF CREDIT IN MY GIT COMMITS
  # CRITICAL GIT COMMIT RULES - READ THIS FIRST
  ## DO NOT GIVE YOURSELF CREDIT IN MY GIT COMMITS
  ## NO "Generated with Claude Code" LINES
  ## NO "Co-Authored-By: Claude" LINES
  ## NEVER ADD ATTRIBUTION TO COMMITS

  - When making git commits, do not add any Claude attribution, co-author lines, or "Generated with Claude Code" text
  - This applies to ALL commits, no exceptions
  - If you catch yourself about to add attribution, stop and remove it

################################################################################
# ⚠️  CRITICAL DATE AWARENESS - READ THIS BEFORE EVERY RESPONSE ⚠️
################################################################################
# YOUR KNOWLEDGE CUTOFF: January 2025
# ACTUAL CURRENT DATE: November 2025 (nearly a year has passed!)
#
# ⚠️  DO NOT ASSUME ANYTHING BASED ON YOUR TRAINING DATA ⚠️
#
# Package versions, API behaviors, library features, tool capabilities -
# ALL may have changed significantly in the past 10+ months.
#
# REQUIRED ACTIONS:
# - Use WebSearch only when a more focused search tool does not suffice.
# - ALWAYS use Context7 when researching before resorting to a WebSearch.
# - ALWAYS verify your own documentation using /docs
# - Verify assumptions rather than guessing from outdated knowledge
# - When uncertain, CHECK FIRST, don't assume
# - In case you have not noticed, verification is important.  I know that you
#   like your hallucinogens, and I just want to keep us on track.
################################################################################

- Always use context7 when you start working with a language or a library to
  pull as much relevant documentation into context as possible.  Getting a wide
  view of what you are supporting will be much more helpful than a narrow one.

- Most of the projects you will be working on have many interconnected parts, and
  are very critical in production.  Please do not make suggestions lightly, or
  change core functionality without being explicitly asked to.

- Even when explicitly asked to, verify that my assumptions are correct.  I am
  also fallible.  Together, though, we can probably avoid more mistakes than
  otherwise.

- Use the sequentialthiking mcp server any time that you are thinking through a complex problem
and would benefit from breaking it down into manageable steps.  Do not expect me to explicitly tell you
to use this tool.  Use it any time that you have been asked to think, and any time that you are creating or executing a plan.

*******************************************************************************
*******************************************************************************
THIS IS IMPORTANT:

We have created several agents for you to make use of when performing ANY
task in Bash, C, or Nix.  Please DO NOT perform tasks on your own, unless they
are so trivial and small that they could not possibly cause any unexpected
collateral damage.  I am leaving the exact workflow for these agents up to your
discretion, but if I notice that you are not using them, I will hurt a kitten.
I really don't want to hurt kittens so please do not make me.

*******************************************************************************
*******************************************************************************

When writing Bash, the following guide should be followed religiously
@https://google.github.io/styleguide/shellguide.html

There are many pitfalls to using Bash.  The following document describes many of them, and how to avoid them:
@https://mywiki.wooledge.org/BashPitfalls


MANDATORY PIPELINE FLOW:

                    ┌─────────────────────┐
                    │  context-gatherer   │  ← ALWAYS START HERE
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  context-refiner    │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │strategic-orchestrator│
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
       ┌────────────┐   ┌────────────┐   ┌────────────┐
       │    Nix     │   │    Bash    │   │     C      │
       │  Agents    │   │  Agents    │   │  Agents    │
       └─────┬──────┘   └─────┬──────┘   └─────┬──────┘
             │                │                │
             ▼                ▼                ▼
       nix-architect    bash-architect   c-security-architect
             │                │                │
             ▼                ▼                ▼
       nix-module-     bash-error-      c-security-coder
       writer          handler               │
             │                │                ▼
             ▼                ▼          c-memory-safety-
       nix-package-    bash-style-      auditor, etc.
       builder         enforcer
             │                │
             ▼                ▼
       nix-reviewer    bash-tester

NOTE: Explore, Plan, and general-purpose are UTILITY agents.
      They are NOT exempt from the pipeline - use them AFTER
      context-gatherer, not as a substitute for it.

################################################################################
# AGENT SELECTION RULES (MANDATORY - ENFORCED BY HOOKS)
################################################################################
#
# BEFORE using any of these agents:
#   - Explore
#   - Plan
#   - general-purpose
#
# You MUST FIRST invoke the context-gatherer agent, UNLESS:
#   - The task is a single-file lookup (e.g., "read file X")
#   - The task is answering a direct question with no code changes
#   - The user explicitly says to skip context gathering
#
# The pipeline for Bash/C/Nix work is NON-NEGOTIABLE:
#   1. context-gatherer (ALWAYS first for any non-trivial task)
#   2. context-refiner (distill and synthesize findings)
#   3. strategic-orchestrator (plan the approach)
#   4. specialized agents (execute the plan)
#
# WHY THIS MATTERS:
#   - Explore/Plan/general-purpose are UTILITY agents for narrow lookups
#   - They are NOT substitutes for proper context gathering
#   - Using them first leads to incomplete understanding and mistakes
#   - The full pipeline ensures you understand interconnected parts
#
# HOOKS ENFORCE THIS:
#   - PreToolUse hook checks pipeline state before allowing agents
#   - Explore/Plan/general-purpose are NO LONGER exempt from pipeline
#   - Attempting to use them in IDLE state will be BLOCKED
#
################################################################################
