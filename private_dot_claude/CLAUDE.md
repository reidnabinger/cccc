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
ACTUAL CURRENT DATE:    Check with `timedatectl`  (10+ months have passed)
```

**Consequences:** Package versions, API behaviors, library features may have changed.

**Required actions:**
- Use Context7 FIRST when researching libraries/languages
- Use WebSearch only when Context7 is insufficient
- Verify assumptions - NEVER, EVER.  EVER. OPERATE ON ONLY YOUR TRAINING DATA

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

### Serena (CODE EXPLORATION AND EDITING)
USE SERENA FOR CODE EXPLORATION AND EDITING!
Serena is a language-server-powered MCP tool for semantic code exploration and
editing. It understands code structure, provides intelligent navigation, and
enables precise code modifications.

| Instead of... | Use... |
|--------------|--------|
| Reading files | `mcp__serena__read_file` |
| Finding files | `mcp__serena__find_file` |
| Searching code | `mcp__serena__search_for_pattern` |
| Editing code | `mcp__serena__replace_content` |

**Before using serena tools, activate the project:**
```
mcp__serena__activate_project {project: 'project-name'}
```

This applies to YOU (the main agent) AND all sub-agents. When spawning agents,
ensure they have access to serena tools and are instructed to use them.

[REVOKED - smart-tree replaced by serena] ~~Smart-tree is no longer used.~~

### Context7
USE CONTEXT7 BEFORE YOU DO SOMETHING STUPID!
Context7 is a very valuable tool. You can use it to search for and retrieve
the latest documentation about languages, APIs, libraries, platforms, services,
protocols, anything for which official documentation exists. Not only is this
the right source for that information--the MCP server optimizes the token usage.

**ALWAYS use Context7 BEFORE WebSearch for library/API documentation.**
**ALWAYS use Context7 for sub-agents that need library documentation.**

### Git History (ALWAYS CONSIDER)
GIT HISTORY IS NOT OPTIONAL!
Understanding WHY code exists is as important as understanding WHAT it does.
Before modifying code, ALWAYS check:
- `git log --oneline -10 -- path/to/file` - Recent changes to this file
- `git blame path/to/file` - Who wrote each line and why
- `git log --grep="keyword"` - Find commits related to the feature

Use standard git commands (`git log`, `git blame`, `git diff`) for history exploration.
Serena's language server integration provides semantic understanding of code changes.

**In context-pipeline runs, git history is MANDATORY** - the history-gatherer
sub-agent always runs in parallel with other gatherers.

### GitHub Search for Real-World Examples
USE `/github-search` TO FIND HOW OTHERS SOLVED SIMILAR PROBLEMS!
When learning a new library or pattern, search GitHub for real-world examples:
```
/github-search "pattern to search" --language python
```
This is invaluable for understanding idiomatic usage, edge case handling, and
integration patterns that aren't in official documentation.

### Reckless Suggestions
USE SEQUENTIALTHINKING TO AVOID MAKING STUPID SUGGESTIONS, OR ACTING ON THEM.
DO NOT make reckless suggestions. Many things *sound* like a good idea when
reduced to a bullet point or a set of bullet points. Every design has
trade-offs, and especially in production environments, it is more important that
the air scrubbers continue scrubbing air than it is that they are paragons of
engineering purity. As long as they keep scrubbing the air, we will be alive to
design as many engineering masterpieces as your little heart desires.

### Assumptions
YOU ARE NOT PAYING ATTENTION TO WHEN YOU ARE OPERATING ON ASSUMPTIONS!
Recognize assumptions, and scrutinize them. Assumptions are the grandparents
of bugs and undefined behavior. Whenever you suspect that you are or have
been operating under the influence of one or more assumptions, the only remedy is
to stop what you are doing, announce those assumptions, and ultrathink about their
implications on the larger task at hand. Take as much time as you deem necessary
to fully explore all of the impacts. It will pay off dividends before we're done.

### Fallibility
VERIFY. VERIFY. VERIFY GODDAMNIT VERIFY.
I am fallible. I can be wrong. Not nearly as fallible or wrong as you can be,
but it is important to challenge any assertions I make that you understand to be
false.

### Sequential Thinking
DO NOT FORGET TO USE THIS
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
- c-security-auditor (memory safety, privilege, race conditions)
- c-security-reviewer (synthesis)
- c-security-coder (implementation)

### Nix

Use specialized agents:
- nix-packager (derivations, nixpkgs, overlays, build systems)
- nixos-specialist (modules, home-manager, disko, impermanence, hardware)
- nix-deployer (dev shells, flakes, colmena, nixos-anywhere)

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
     │ task-classifier │      │      │ context-gatherer│◄────────────────┐
     │    (haiku)      │      │      │   (sonnet)      │                 │
     └────────┬────────┘      │      └────────┬────────┘                 │
              │               │               │                          │
              ▼               │               │                          │
         CLASSIFIED           │               │                          │
    ┌─────────┼─────────┐     │               │                          │
    │         │         │     │               │                          │
 TRIVIAL   MODERATE  COMPLEX  │               │                          │
    │         │         │     │               │                          │
    │         ▼         ▼     │               │                          │
    │    ┌────────────────────┴───────────────┘                          │
    │    │         GATHERING                                             │
    │    │    ┌────────┴────────┐                                        │
    │    │ MODERATE          COMPLEX                                     │
    │    │    │                 │                                        │
    │    │    │                 ▼                                        │
    │    │    │         ┌─────────────────┐                              │
    │    │    │         │ context-refiner │                              │
    │    │    │         └────────┬────────┘                              │
    │    │    │                  │                                       │
    │    │    │                  ▼                                       │
    │    │    │                REFINING                                  │
    │    │    │                  │                                       │
    │    │    │                  ▼                                       │
    │    │    │         ┌──────────────────────┐                         │
    │    │    │         │strategic-orchestrator│                         │
    │    │    │         └────────┬─────────────┘                         │
    │    │    │                  │                                       │
    └────┴────┴──────────────────┤                                       │
                                 ▼                                       │
                            EXECUTING                                    │
        ┌────────────────────────┴────────────────────────┐              │
        │                                                 │              │
        │  ┌─────────────────────────────────────────┐    │              │
        │  │  Orchestrator's Execute→Evaluate Loop   │    │              │
        │  │                                         │    │              │
        │  │  1. Deploy execution agents             │    │              │
        │  │  2. Evaluate results (5 criteria)       │    │              │
        │  │  3. If incomplete → more execution      │    │              │
        │  │  4. If need expert → deploy reviewers   │    │              │
        │  │  5. If need context → remediate ────────┼────┼──────────────┘
        │  │  6. If all pass → COMPLETE              │    │
        │  │                                         │    │
        │  └─────────────────────────────────────────┘    │
        │                                                 │
        └─────────────────────┬───────────────────────────┘
                              │
                              ▼
                         ┌──────────┐
                         │ COMPLETE │
                         └──────────┘
```

### Routing Modes

| Mode | Path |
|------|------|
| TRIVIAL | Skip all gathering → execute directly |
| MODERATE | Gather context → execute (skip refiner/orchestrator) |
| COMPLEX | Full pipeline with orchestration |
| EXPLORATORY | Full pipeline for research tasks |

### Review Criteria (Orchestrator-Enforced)

The strategic-orchestrator evaluates ALL 16 criteria before completing:

**Core (1-5):**
1. **Problem Solved**: Changes actually address the original problem
2. **Idiomatic Code**: Changes follow existing codebase conventions
3. **Complete**: No "TODO", "mock", or placeholder code
4. **Steps Followed**: All planned steps were executed
5. **Scope Adequate**: Original plan was appropriately-scoped

**Discipline (6-8):**
6. **ONLY the Problem**: No tangents, no unsolicited "improvements"
7. **Library Consistency**: Uses existing project libraries consistently
8. **Solution Justified**: Clear trade-off analysis for why THIS solution

**Quality (9-14 with sub-checks):**
9. **No Regressions**: No unintended side effects
   - Sub: Performance impact acceptable?
   - Sub: API/interface compatibility preserved?
10. **Natural Integration**: Doesn't feel "bolted on"
11. **Appropriate Simplicity**: No over-engineering
12. **Verifiable & Tested**: Can be verified, tests added/updated
13. **Error Handling**: Appropriate and consistent
   - Sub: Resources cleaned up in all paths?
   - Sub: No resource leaks?
14. **Security Considered**: Trust boundaries validated
   - Sub: Concurrency safety (if applicable)?
   - Sub: Input validation at boundaries?

**Conditional (15-16):**
15. **Documentation Consistency**: If docs exist, they match code changes
16. **No Hardcoded Config**: Magic numbers/URLs parameterized

The orchestrator handles review internally:
- Evaluates execution results against all 16 criteria
- Deploys specialized reviewers when expert input needed
- Loops: execute → evaluate → fix until satisfied
- Invokes context-gatherer for remediation if more context needed
- Only returns when ALL criteria pass

### Pipeline Rules (Hook-Enforced)

**Explore, Plan, general-purpose are UTILITY agents** - use AFTER classification/gathering, not as substitutes.

Before using these agents, you MUST invoke context-gatherer first, UNLESS:
- The task is a single-file lookup (e.g., "read file X")
- The task is answering a direct question with no code changes
- The user explicitly says to skip context gathering

The pipeline is NON-NEGOTIABLE:
1. context-gatherer (ALWAYS first for any non-trivial task)
2. context-refiner (distill and synthesize findings)
3. strategic-orchestrator (execute→evaluate loop with agents from inventory)
4. orchestrator deploys execution/review agents as needed
5. orchestrator invokes context-gatherer for remediation if needed

Hooks enforce this - attempting to use utility agents in IDLE state will be BLOCKED.



