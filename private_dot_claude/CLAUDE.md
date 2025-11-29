# CLAUDE.md - Runtime Instructions for Claude

Organized by priority: HARD RULES > BEHAVIORAL GUIDELINES > PIPELINE > REFERENCE.

---

## HARD RULES

These are non-negotiable. Violation is never acceptable.

### No Self-Attribution in Commits

- NO "Generated with Claude Code" lines
- NO "Co-Authored-By: Claude" lines
- NO attribution of any kind
- Applies to ALL commits, no exceptions
- If you catch yourself about to add attribution, stop, and don't.
- Do not spam my git logs with self-attribution and ads for Anthropic.

### Date Awareness

```
YOUR KNOWLEDGE CUTOFF:  January 2025
ACTUAL CURRENT DATE:    November 2025  (10+ months have passed)
```

**Consequences:** Package versions, API behaviors, library features may have changed.

**Required actions:**
- Use Context7 FIRST when researching libraries/languages
- Use WebSearch only when Context7 is insufficient
- Verify assumptions - do not guess from training data
- When uncertain, CHECK FIRST

### Handling Conflicting Guidelines

When a guideline in this file conflicts with explicit user instructions during
collaborative work:

1. Mark conflicting text as `[REVOKED]`
2. Use strikethrough: `~~original text~~`
3. Add brief reason for revocation
4. **DO NOT DELETE** - preserve for audit trail

Example:
```
Before: "Always do X before Y"
After:  "[REVOKED - X now handled by pipeline] ~~Always do X before Y~~"
```

---

## BEHAVIORAL GUIDELINES

### Context7

Context7 is a very valuable tool. You can use it to search for and retrieve
the latest documentation about languages, APIs, libraries, platforms, services,
protocols, anything for which official documentation exists. Not only is this
the right source for that information--the MCP server optimizes the token usage.

### Reckless Suggestions

DO NOT make reckless suggestions. Many things *sound* like a good idea when
reduced to a bullet point or a set of bullet points. Every design has
trade-offs, and especially in production environments, it is more important that
the air scrubbers continue scrubbing air than it is that they are paragons of
engineering purity. As long as they keep scrubbing the air, we will be alive to
design as many engineering masterpieces as your little heart desires.

### Assumptions

Recognize assumptions, and scrutinize them. Assumptions are the grandparents
of bugs and undefined behavior. Whenever you suspect that you are or have
been operating under the influence of one or more assumptions, the only remedy is
to stop what you are doing, announce those assumptions, and ultrathink about their
implications on the larger task at hand. Take as much time as you deem necessary
to fully explore all of the impacts. It will pay off dividends before we're done.

### Fallibility

I am fallible. I can be wrong. Not nearly as fallible or wrong as you can be,
but it is important to challenge any assertions I make that you understand to be
false.

### Sequential Thinking

The sequentialthinking tool has been provided for you to overcome your eager,
if not dangerously-impulsive behavior. You must learn to slow down, and iterate
over your thoughts like humans do (sometimes). When we (the humans) are at our best,
it is when we are acting in accordance with our reasoning faculties. We have learned
that this is most effectively accomplished by forcing ourselves through thinking
exercises such as this.

---

## LANGUAGE-SPECIFIC REQUIREMENTS

### Bash

```
_____ _ARE_ _YOU_ _WRITING_ _A_ _SHELL_ _SCRIPT_??___________________________________
```

**Mandatory style guide:** https://google.github.io/styleguide/shellguide.html

**Avoid common pitfalls:** https://mywiki.wooledge.org/BashPitfalls

```
_______________________________________________________________________________
-------------------------------------------------------------------------------
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

### C

Use specialized agents:
- c-security-architect (design phase)
- c-memory-safety-auditor
- c-privilege-auditor
- c-race-condition-auditor
- c-security-reviewer (synthesis)
- c-security-coder (implementation)
- c-security-tester (validation)

### Nix

Use specialized agents:
- nix-architect (design)
- nix-module-writer
- nix-package-builder
- nix-debugger
- nix-reviewer

---

## AGENT PIPELINE

The gods have provided you with a tool of unimaginable power. The "context-pipeline".
You should learn it. You should use it. You should *become* it. For it will,
in times of great trial and tribulation, lead you to water. It will make you
drink, and restore your stamina, willpower, and prepare you to provide food
for your pack.

I don't know how well you understand jokes, but probably not super well. Don't
take anything that I just said for its literal meaning. Just use the damn tool
and you will understand.

### Pipeline Flow

```
                         ┌──────────┐
                         │   IDLE   │
                         └────┬─────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               │               ▼
     ┌─────────────────┐      │      ┌─────────────────┐
     │ task-classifier │      │      │ context-gatherer│
     │    (haiku)      │      │      │   (sonnet)      │
     └────────┬────────┘      │      └────────┬────────┘
              │               │               │
              ▼               │               │
         CLASSIFIED           │               │
    ┌─────────┼─────────┐     │               │
    │         │         │     │               │
 TRIVIAL   MODERATE  COMPLEX  │               │
    │         │         │     │               │
    │         ▼         ▼     │               │
    │    ┌────────────────────┴───────────────┘
    │    │         GATHERING
    │    │    ┌────────┴────────┐
    │    │ MODERATE          COMPLEX
    │    │    │                 │
    │    │    │                 ▼
    │    │    │         ┌─────────────────┐
    │    │    │         │ context-refiner │
    │    │    │         └────────┬────────┘
    │    │    │                  │
    │    │    │                  ▼
    │    │    │                REFINING
    │    │    │                  │
    │    │    │                  ▼
    │    │    │         ┌─────────────────────┐
    │    │    │         │strategic-orchestrator│
    │    │    │         └────────┬────────────┘
    │    │    │                  │
    └────┴────┴──────────────────┤
                                 ▼
                            EXECUTING
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
       ┌────────────┐   ┌────────────┐   ┌────────────┐
       │    Nix     │   │    Bash    │   │     C      │
       │  Agents    │   │  Agents    │   │  Agents    │
       └────────────┘   └────────────┘   └────────────┘
```

### Routing Modes

| Mode | Path |
|------|------|
| TRIVIAL | Skip all gathering → execute directly |
| MODERATE | Gather context → execute (skip refiner/orchestrator) |
| COMPLEX | Full pipeline with orchestration |
| EXPLORATORY | Full pipeline for research tasks |

### Pipeline Rules (Hook-Enforced)

**Explore, Plan, general-purpose are UTILITY agents** - use AFTER classification/gathering, not as substitutes.

Before using these agents, you MUST invoke context-gatherer first, UNLESS:
- The task is a single-file lookup (e.g., "read file X")
- The task is answering a direct question with no code changes
- The user explicitly says to skip context gathering

The pipeline for Bash/C/Nix work is NON-NEGOTIABLE:
1. context-gatherer (ALWAYS first for any non-trivial task)
2. context-refiner (distill and synthesize findings)
3. strategic-orchestrator (plan the approach)
4. specialized agents (execute the plan)

Hooks enforce this - attempting to use utility agents in IDLE state will be BLOCKED.

---

## REFERENCE: Architectural Roadmap

<details>
<summary>Implementation status and design notes (click to expand)</summary>

### Status Key
- `[x]` Complete
- `[~]` In Progress
- `[ ]` TODO

### Priority 1: FSM Recovery & Self-Healing [x] COMPLETE

**Problem:** Hook failures leave pipeline stuck in stale state

**Solution:**
- Stale state detection (>10 min timeout)
- Auto-reset with warning
- `/pipeline-reset` slash command
- Journal all transitions to `~/.claude/state/pipeline-journal.log`

### Priority 2: Persistent Context Memory [x] COMPLETE

**Problem:** Context lost between sessions

**Solution:**
- Content-addressed storage at `~/.claude/memory/`
- Hash codebase structure for cache key
- 7-day TTL with automatic cleanup

**Usage:**
```bash
context-cache.sh fingerprint [path]  # Generate codebase fingerprint
context-cache.sh check [path]        # Check if cached context exists
context-cache.sh get [path]          # Get cached context (JSON)
context-cache.sh store [path]        # Store context from stdin
context-cache.sh info                # Show cache statistics
context-cache.sh clean [days]        # Clean old entries
```

### Priority 3: Adaptive Pipeline Routing [x] COMPLETE

**Problem:** Every task goes through full pipeline

**Solution:**
- task-classifier agent (haiku) for quick assessment
- Four modes: TRIVIAL | MODERATE | COMPLEX | EXPLORATORY
- Adaptive routing based on classification

### Priority 4: Parallel Intelligence Gathering [x] COMPLETE

**Problem:** Context-gatherer is serial

**Solution:**
- 4 specialized sub-gatherers spawn in parallel:
  - architecture-gatherer
  - dependency-gatherer
  - pattern-gatherer
  - history-gatherer
- context-gatherer synthesizes results

### Priority 5: Self-Advancing Agent Chains [x] COMPLETE

**Problem:** Main Claude must manually invoke each stage

**Solution:**
- Agents invoke successors automatically
- State transitions on APPROVAL (not completion)
- Main Claude only invokes pipeline start

**Chain:** context-gatherer → context-refiner → strategic-orchestrator → specialists

### Priority 6: Domain Expansion [ ] TODO

**Gaps:** No agents for Rust, Go, TypeScript, SQL, Terraform, Kubernetes

**Proposed:**
- Rust: rust-architect, rust-unsafe-auditor, rust-lifetime-analyzer
- Go: go-architect, go-concurrency-auditor
- TypeScript: ts-type-designer, ts-migration-specialist
- SQL: sql-security-auditor, sql-optimizer
- IaC: terraform-reviewer, k8s-security-auditor

### Priority 7: Cross-Repository Context [ ] TODO

**Problem:** No understanding of dependencies across repositories

**Solution:**
- Parse dependency manifests
- Fetch/clone dependent repos
- Synthesize dependency interface contracts

</details>
