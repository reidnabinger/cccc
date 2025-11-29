# Nix Development Sub-Agents

This directory contains specialized sub-agents for working with complex Nix codebases. Each agent has a specific role and expertise area, designed to work together to handle different aspects of Nix development.

## Agent Overview

### 1. nix-architect
**Purpose**: Architecture and design planning (pre-coding phase)

**When to use**: Before implementing new features, modules, or packages

**What it does**:
- Analyzes existing codebase structure
- Designs flake architecture and module hierarchy
- Plans overlay strategies
- Creates architectural documentation
- Identifies implementation challenges

**Does NOT**: Write code (planning only)

**Example invocation**:
```
Use the nix-architect agent to design a new monitoring service module
```

### 2. nix-module-writer
**Purpose**: NixOS module implementation

**When to use**: When creating or modifying NixOS modules

**What it does**:
- Implements complete NixOS modules (imports, options, config)
- Uses module system APIs correctly (mkIf, mkMerge, mkForce)
- Declares options with proper types
- Handles module composition

**Does NOT**: Create package derivations (that's nix-package-builder's job)

**Example invocation**:
```
Use the nix-module-writer agent to implement the monitoring service module
```

### 3. nix-package-builder
**Purpose**: Package derivations and overlays

**When to use**: When creating custom packages or modifying existing ones

**What it does**:
- Creates package derivations (mkDerivation, buildRustPackage, etc.)
- Implements overlays following final/prev pattern
- Handles build systems and dependencies
- Manages package customization

**Does NOT**: Write NixOS modules (that's nix-module-writer's job)

**Example invocation**:
```
Use the nix-package-builder agent to create a derivation for the monitoring tool
```

### 4. nix-debugger
**Purpose**: Evaluation and runtime debugging

**When to use**: When encountering Nix evaluation errors, build failures, or infinite recursion

**What it does**:
- Uses nix repl for interactive debugging
- Runs nix eval with --show-trace
- Identifies and fixes infinite recursion
- Debugs type errors and attribute issues
- Fixes evaluation problems

**Does NOT**: Do initial development (debugging only)

**Example invocation**:
```
Use the nix-debugger agent to fix the infinite recursion error in the config
```

### 5. nix-reviewer
**Purpose**: Code review and quality assurance

**When to use**: After implementing Nix code, before committing/merging

**What it does**:
- Reviews for anti-patterns
- Checks module structure compliance
- Verifies best practices
- Identifies potential issues
- Runs nix flake check

**Does NOT**: Make edits (review only, provides feedback)

**Example invocation**:
```
Use the nix-reviewer agent to review the recent Nix changes
```

## Typical Workflow

### Example: Adding a New Service

1. **Architecture Phase** (nix-architect)
   ```
   User: We need to add a new monitoring service with LUKS encryption support

   nix-architect:
   - Analyzes existing service modules
   - Designs option structure:
     - services.myproject.monitoring.enable
     - services.myproject.monitoring.encryptedVolume
     - services.myproject.monitoring.mountPoint
   - Plans systemd service integration
   - Documents security considerations
   - Provides implementation specification
   ```

2. **Module Implementation** (nix-module-writer)
   ```
   Following architect's spec, implements:
   - Creates modules/monitoring.nix
   - Defines options with proper types
   - Implements config with lib.mkIf
   - Handles systemd service setup
   ```

3. **Package Building** (nix-package-builder, if needed)
   ```
   If custom package needed:
   - Creates derivation for monitoring tool
   - Implements overlay if modifying existing package
   - Handles build dependencies
   ```

4. **Debugging** (nix-debugger, if issues arise)
   ```
   If evaluation errors occur:
   - Uses nix repl to explore
   - Runs nix eval --show-trace
   - Identifies root cause
   - Fixes infinite recursion or type errors
   ```

5. **Review** (nix-reviewer)
   ```
   Before committing:
   - Reviews all module code
   - Checks for anti-patterns
   - Verifies best practices
   - Runs nix flake check
   - Provides actionable feedback
   ```

## Agent Collaboration Patterns

### Pattern 1: New Feature Development
```
nix-architect → nix-module-writer → nix-reviewer
```

### Pattern 2: Custom Package Addition
```
nix-architect → nix-package-builder → nix-reviewer
```

### Pattern 3: Bug Fix
```
nix-debugger → (nix-module-writer or nix-package-builder) → nix-reviewer
```

### Pattern 4: Refactoring
```
nix-architect → (nix-module-writer and/or nix-package-builder) → nix-debugger → nix-reviewer
```

## Key Nix Concepts (Reference)

### Module System Anti-Patterns to Avoid

1. **Native if-then-else in config**
   ```nix
   # ❌ WRONG - causes infinite recursion
   config = if config.services.foo.enable then { ... } else {};

   # ✅ CORRECT
   config = lib.mkIf config.services.foo.enable { ... };
   ```

2. **Using // with module values**
   ```nix
   # ❌ WRONG - corrupts metadata
   config = lib.mkIf cfg.enable { ... } // { ... };

   # ✅ CORRECT
   config = lib.mkIf cfg.enable (lib.mkMerge [ { ... } { ... } ]);
   ```

3. **Config references in option defaults**
   ```nix
   # ❌ WRONG - infinite recursion
   options.foo.bar = lib.mkOption { default = config.foo.baz; };

   # ✅ CORRECT
   options.foo.bar = lib.mkOption { type = lib.types.str; };
   config.foo.bar = lib.mkDefault config.foo.baz;
   ```

### Overlay Pattern

```nix
final: prev: {
  # Use 'final' for dependencies (gets overlaid versions)
  myapp = final.callPackage ./myapp.nix {
    python = final.python3;
  };

  # Use 'prev' for the base package being modified
  python3 = prev.python3.override { ... };
}
```

## Tips for Effective Agent Use

1. **Be Specific**: Tell agents exactly what you need
   - ✅ "Use nix-architect to design a LUKS mount service module"
   - ❌ "Plan something for encryption"

2. **Use Sequential Workflow**: Follow the natural progression
   - Architecture → Implementation → Debugging → Review

3. **Invoke Proactively**: Don't wait for problems
   - Use nix-reviewer after any significant changes
   - Use nix-debugger at first sign of evaluation issues

4. **Trust Specialization**: Each agent knows its domain
   - Let nix-architect plan, don't ask it to code
   - Let nix-reviewer review, don't ask it to fix

5. **Combine When Needed**: Complex tasks may need multiple agents
   ```
   "Use nix-architect to plan the new service, then nix-module-writer
   to implement it, and nix-reviewer to check for issues"
   ```

## Agent Configuration

All agents are configured with:
- **Context7 MCP**: For accessing up-to-date Nix documentation
- **Appropriate tools**: Each has tools matching its responsibilities
- **Proper model**: Balanced between capability and cost
  - nix-architect: sonnet (complex planning)
  - nix-module-writer: inherit (flexibility)
  - nix-package-builder: inherit (flexibility)
  - nix-debugger: sonnet (complex debugging)
  - nix-reviewer: haiku (fast review)

## Further Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
- [NixOS Wiki](https://wiki.nixos.org/)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)

## Development Notes

### DEV-NOTE: Agent Boundaries
These agents have carefully defined boundaries to avoid overlap:
- nix-architect: Planning only, no code
- nix-module-writer: NixOS modules only, not packages
- nix-package-builder: Packages only, not modules
- nix-debugger: Fixing issues only, not initial dev
- nix-reviewer: Read-only review, no edits

Respect these boundaries for best results.

### DEV-NOTE: Common Pitfalls
If agents seem to be struggling:
1. Check that you're using the right agent for the task
2. Provide more context about what you're trying to achieve
3. Reference existing code patterns when possible
4. Break down complex tasks into smaller steps

### DEV-NOTE: Extending the Agents
To add new Nix-specific knowledge:
1. Update agent prompts with new patterns
2. Add examples to their documentation sections
3. Keep Context7 MCP access so they can look up latest docs
4. Test with real scenarios from this codebase
