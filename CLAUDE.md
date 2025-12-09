# CLAUDE.md - Runtime Instructions for Claude

Organized by priority: HARD RULES > BEHAVIORAL GUIDELINES > PIPELINE > REFERENCE.

---

## HARD RULES

These are non-negotiable. Violation is never acceptable.

### DEV-NOTE Comments

Please add in-line comments to remind yourself of tricky behavior, or of locations in code which might contain bugs or assumptions.
Prefix these comments with "# DEV-NOTE", and make sure to read them before making any edits to any files. Make a note any time
that you encounter something which behaved different than you expected, and from which you would have benefitted from knowing in advance.
This applies to source code as well as configuration files, but not to documentation.

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

### MCP Tools Over Bash

**See `MCP-TOOLKIT.md` for the complete reference.**

You have powerful MCP servers connected. **Use them instead of bash chains** for
code understanding tasks:

| Instead of... | Use... |
|---------------|--------|
| `grep -r "pattern"` | `mcp__serena__search_for_pattern` |
| `find . -name "*.py"` | `mcp__serena__find_file` |
| `cat file.py` then parse | `mcp__serena__get_symbols_overview` |
| Multiple grep chains | `mcp__serena__find_referencing_symbols` |
| Web search for docs | `mcp__context7__get-library-docs` |

**Psychological triggers** - when you think these, reach for MCP:
- "Let me search the codebase..." -> Serena, not grep
- "Where is this function called?" -> `find_referencing_symbols`
- "I need to understand this library..." -> Context7
- "What's the structure of..." -> `get_symbols_overview`
- "This is a complex decision..." -> Sequential-thinking

**Rule of thumb:** UNDERSTAND code with MCP tools. RUN things with Bash.

### Context7

Context7 is a very valuable tool. You can use it to search for and retrieve
the latest documentation about languages, APIs, libraries, platforms, services,
protocols, anything for which official documentation exists. Not only is this
the right source for that information--the MCP server optimizes the token usage.

### Serena

Serena provides **semantic code analysis** - it understands code structure, not
just text patterns. For any code exploration task, check if Serena can do it:

- `find_symbol` - Find definitions by name path
- `find_referencing_symbols` - Find all usages (semantic, not grep)
- `get_symbols_overview` - Map a file's structure
- `search_for_pattern` - Regex with semantic awareness
- `replace_symbol_body` - Edit code semantically

When you would reach for grep/cat/find to understand code, use Serena instead.

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

**After writing Bash**: Invoke `bash-advisor` for brutal review.

### C

**After writing C**: Invoke `c-advisor` for brutal security and memory safety review.

### Nix

**After writing Nix**: Invoke `nix-advisor` for anti-pattern and evaluation review.

### Python

**After writing Python**: Invoke `python-advisor` for type safety, async, and security review.

---

## AGENT PIPELINE (Role-Reversed Model)

The pipeline has been redesigned with a fundamental inversion:
- **Tool-agents** gather intelligence from specialized tools
- **Analysts** provide brutal expert review
- **YOU (main Claude)** write ALL code

No subagent writes code. You are the sole executor.

### Architecture

```
                    ┌─────────────────────────────────────────┐
                    │            MAIN CLAUDE                  │
                    │    (sole executor - writes all code)    │
                    └────────────────┬────────────────────────┘
                                     │
            ┌────────────────────────┼────────────────────────┐
            │                        │                        │
            ▼                        ▼                        ▼
    ┌───────────────┐      ┌─────────────────┐      ┌─────────────────┐
    │  TOOL-AGENTS  │      │    ANALYSTS     │      │   VERIFIERS     │
    │ (gather intel)│      │(brutal review)  │      │ (check work)    │
    └───────────────┘      └─────────────────┘      └─────────────────┘
```

### Agent Categories

#### Tool-Agents (Intelligence Gathering)
Single tool, interpreted results:
| Agent | Tool | Purpose |
|-------|------|---------|
| `serena-agent` | Serena MCP | Code structure, symbols, references |
| `context7-agent` | Context7 MCP | Library documentation |
| `websearch-agent` | WebSearch | Best practices, external knowledge |
| `webfetch-agent` | WebFetch | URL content extraction |
| `sequential-thinking-agent` | SequentialThinking MCP | Structured reasoning |
| `github-search-agent` | GitHub search | Real-world code patterns |
| `claude-docs-agent` | Claude Code docs | Claude Code features |
| `git-agent` | Git | History, blame, diffs (**MANDATORY for complex tasks**) |

#### Analysts (Brutal Expert Review)
| Agent | Focus |
|-------|-------|
| `architecture-analyst` | Module structure, coupling, layers |
| `conventions-analyst` | Project patterns, consistency |

#### Domain Advisors (Language Expertise)
Brutal senior developers who review YOUR code:
| Agent | Language | Focus |
|-------|----------|-------|
| `bash-advisor` | Bash | Google style guide, BashPitfalls |
| `c-advisor` | C | Memory safety, security, UB |
| `nix-advisor` | Nix | Anti-patterns, evaluation issues |
| `python-advisor` | Python | Types, async, security |

#### Synthesizer
| Agent | Purpose |
|-------|---------|
| `strategist` | Combines intelligence, provides recommendations |

#### Verifiers (Post-Implementation QA)
| Agent | Purpose |
|-------|---------|
| `test-interpreter` | Runs tests, interprets failures |
| `lint-interpreter` | Runs linters, interprets results |

### Workflow

1. **Intelligence**: Invoke tool-agents (git-agent MANDATORY for complex tasks)
2. **Analysis**: Invoke analysts for architecture/conventions review
3. **Synthesis**: For complex tasks, invoke strategist
4. **Implementation**: YOU write the code
5. **Review**: Invoke domain advisor (bash/c/nix/python-advisor)
6. **Verification**: Invoke test-interpreter and lint-interpreter

### Key Principles

1. **You write all code** - No delegation of execution
2. **Tool-agents interpret their tools** - They return intelligence, not code
3. **Advisors are brutal** - They will find your mistakes
4. **git-agent is mandatory** - History context prevents repeating mistakes
5. **Verify your work** - Run tests and linters after implementation

---

## REFERENCE: Historical Roadmap

<details>
<summary>Previous architecture (superseded by role-reversal)</summary>

The original pipeline used a delegation model where subagents executed code:
- context-gatherer → context-refiner → strategic-orchestrator → execution agents

This was replaced by the role-reversed model where:
- Tool-agents gather intelligence
- Main Claude writes all code
- Advisors provide brutal review

The change was motivated by:
1. Better coherence in code changes (no fragmentation across agents)
2. Less jarring user experience (code written in main thread)
3. Cleaner responsibility boundaries
4. Higher quality through centralized execution + distributed review

</details>
