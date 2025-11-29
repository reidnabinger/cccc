# C Security Agents - Quick Start

## What You Have Now

8 specialized security agents for C development:

```
Architecture:
  c-security-architect        Design secure implementations before coding

Implementation:
  c-security-coder           Implement following architecture specs

Automated Analysis:
  c-static-analyzer          Run clang-analyzer, cppcheck, GCC warnings

Specialized Auditors (run in parallel):
  c-memory-safety-auditor    Buffer overflows, use-after-free, integer overflow
  c-privilege-auditor        Setuid/setgid, privilege escalation, capabilities
  c-race-condition-auditor   TOCTOU, signal races, FD races

Synthesis:
  c-security-reviewer        Comprehensive review + remediation plan

Testing:
  c-security-tester          Write security tests + fuzzing strategy
```

## Your First Workflow

**Create a new setuid wrapper:**

1. **Design first:**
   ```
   "Use c-security-architect to design a setuid wrapper that allows 
    koshee group members to execute /usr/bin/mpv as user koshee"
   ```

2. **Implement:**
   ```
   "Use c-security-coder to implement src/mpv_wrapper.c following the 
    architecture specification"
   ```

3. **Quick automated scan:**
   ```
   "Use c-static-analyzer to scan src/mpv_wrapper.c"
   ```

4. **Deep parallel analysis:**
   ```
   "Launch c-memory-safety-auditor, c-privilege-auditor, and 
    c-race-condition-auditor in parallel to review src/mpv_wrapper.c"
   ```

5. **Comprehensive review:**
   ```
   "Use c-security-reviewer to synthesize findings and make deployment 
    recommendation"
   ```

6. **Write tests:**
   ```
   "Use c-security-tester to write security tests"
   ```

## Audit Existing Code

**Quick audit:**
```
"Use c-security-reviewer to audit src/protect_wrapper.c"
```

The reviewer will automatically delegate to specialized auditors and synthesize findings.

## Key Principles

1. **Always design before coding** (use architect first)
2. **Run auditors in parallel** (faster, same cost)
3. **Fix P0 issues immediately** (deployment blockers)
4. **Let reviewer synthesize** (don't manually combine findings)
5. **Write tests before deploying** (validate security properties)

## Read More

- `C-SECURITY-AGENTS-GUIDE.md` - Complete workflow guide
- Individual agent files - Detailed agent capabilities

## File Locations

Your agents create:
- `~/.claude/architecture/[component].md` - Design specs
- `~/.claude/reviews/[component]/` - Audit findings
- `~/.claude/tests/[component]/` - Security tests
- `src/[component].c` - Implementation
