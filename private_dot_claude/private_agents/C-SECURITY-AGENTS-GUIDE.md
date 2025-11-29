# C Security Agent Team - Complete Guide

A specialized team of 8 agents for developing IP-critical C system utilities with security as the highest priority.

## Quick Start

**New setuid wrapper workflow:**
```
1. "Use c-security-architect to design a setuid wrapper for GPU access"
2. "Use c-security-coder to implement the wrapper following the architecture"
3. "Launch c-static-analyzer, c-memory-safety-auditor, c-privilege-auditor, and c-race-condition-auditor in parallel to review src/gpu_wrapper.c"
4. "Use c-security-reviewer to synthesize findings and create remediation plan"
5. "Use c-security-tester to write security tests"
```

**Security audit of existing code:**
```
1. "Use c-security-reviewer to audit src/protect_wrapper.c"
   (The reviewer will automatically delegate to specialized auditors)
```

## Agent Team Overview

### Tier 1: Architecture (Before Coding)

#### c-security-architect
**When**: Before writing any code
**Purpose**: Design secure architecture with defense-in-depth
**Input**: Requirements, threat description
**Output**: `~/.claude/architecture/[component].md`

**Example Usage:**
```
"Use c-security-architect to design a setuid wrapper that allows koshee group members to execute protect-python as protect-daemon user. Primary threats: privilege escalation, GPU resource theft."
```

**What It Produces:**
- Threat model analysis
- Attack surface identification
- Defense-in-depth strategy
- API specifications (which functions to use/avoid)
- Security guarantees
- Implementation specification

---

### Tier 2: Implementation

#### c-security-coder
**When**: After architect has created design
**Purpose**: Implement secure C code following spec
**Input**: `~/.claude/architecture/[component].md`
**Output**: `src/[component].c`

**Example Usage:**
```
"Use c-security-coder to implement src/gpu_wrapper.c following ~/.claude/architecture/gpu_wrapper.md"
```

**What It Does:**
- Reads architecture spec FIRST
- Implements with memory-safe patterns
- Adds privilege management code
- Includes security annotations (DEV-NOTE)
- Uses fail-closed error handling

---

### Tier 3: Automated Analysis (Fast)

#### c-static-analyzer
**When**: Immediately after coding (fast, cheap)
**Purpose**: Run automated tools for quick wins
**Input**: Source files
**Output**: `~/.claude/reviews/[component]/static-analysis.md`
**Model**: Haiku (cost-effective)

**Example Usage:**
```
"Use c-static-analyzer to scan src/gpu_wrapper.c"
```

**Tools Run:**
- clang-analyzer (scan-build)
- cppcheck
- GCC with strict warnings

---

### Tier 4: Specialized Auditors (Deep Analysis)

These can run in PARALLEL for efficiency:

#### c-memory-safety-auditor
**Focus**: Buffer overflows, use-after-free, integer overflows
**Output**: `~/.claude/reviews/[component]/memory-safety.md`

#### c-privilege-auditor  
**Focus**: Setuid/setgid security, privilege escalation
**Output**: `~/.claude/reviews/[component]/privilege.md`

#### c-race-condition-auditor
**Focus**: TOCTOU, signal handler races, FD races
**Output**: `~/.claude/reviews/[component]/race-conditions.md`

**Example Parallel Usage:**
```
"Launch c-memory-safety-auditor, c-privilege-auditor, and c-race-condition-auditor in parallel to review src/gpu_wrapper.c"
```

**Each Auditor:**
- Focuses on ONE vulnerability class
- Provides specific, actionable findings
- Rates severity (Critical/High/Medium/Low)
- Suggests concrete fixes

---

### Tier 5: Comprehensive Synthesis

#### c-security-reviewer
**When**: After specialized auditors complete
**Purpose**: Synthesize findings, identify exploit chains
**Input**: All audit reports
**Output**: `~/.claude/reviews/[component]/comprehensive.md`

**Example Usage:**
```
"Use c-security-reviewer to create comprehensive security assessment of src/gpu_wrapper.c"
```

**What It Does:**
- Reads ALL audit reports
- Identifies cross-cutting vulnerabilities
- Maps exploit chains
- Assesses defense-in-depth
- Prioritizes fixes (P0/P1/P2/P3)
- Makes deployment recommendation (BLOCK/CAUTION/APPROVE)

---

### Tier 6: Testing

#### c-security-tester
**When**: After review, before deployment
**Purpose**: Write security tests and fuzzing strategy
**Output**: `~/.claude/tests/[component]/test_*.c`
**Model**: Haiku (cost-effective)

**Example Usage:**
```
"Use c-security-tester to write security tests for src/gpu_wrapper.c covering authorization, input validation, and privilege dropping"
```

**Creates:**
- Authorization tests
- Input validation tests (boundary, malformed, injection)
- Privilege drop verification tests
- Memory safety tests
- Fuzzing strategy (AFL setup)

---

## Complete Workflows

### Workflow 1: New Setuid Wrapper (Full Process)

```
Step 1: Design
──────────────
User: "Use c-security-architect to design a setuid wrapper for launching 
       firefox as user 'koshee' from protect-daemon context. Primary threat: 
       privilege escalation."

Agent creates: ~/.claude/architecture/firefox_wrapper.md


Step 2: Implement
─────────────────
User: "Use c-security-coder to implement src/firefox_wrapper.c following 
       the architecture spec"

Agent creates: src/firefox_wrapper.c


Step 3: Quick Automated Scan
─────────────────────────────
User: "Use c-static-analyzer to scan src/firefox_wrapper.c"

Agent creates: ~/.claude/reviews/firefox_wrapper/static-analysis.md


Step 4: Specialized Audits (PARALLEL)
──────────────────────────────────────
User: "Launch c-memory-safety-auditor, c-privilege-auditor, and 
       c-race-condition-auditor in parallel to review src/firefox_wrapper.c"

Agents create:
- ~/.claude/reviews/firefox_wrapper/memory-safety.md
- ~/.claude/reviews/firefox_wrapper/privilege.md
- ~/.claude/reviews/firefox_wrapper/race-conditions.md


Step 5: Comprehensive Review
─────────────────────────────
User: "Use c-security-reviewer to synthesize findings and make deployment 
       recommendation"

Agent creates: ~/.claude/reviews/firefox_wrapper/comprehensive.md
Agent provides: BLOCK / DEPLOY WITH CAUTION / APPROVE


Step 6: Fix Issues (if needed)
───────────────────────────────
If P0 issues found:

User: "Fix the P0 issues identified in the comprehensive review"

Then re-run step 3-5 to verify fixes.


Step 7: Write Tests
────────────────────
User: "Use c-security-tester to write security tests for src/firefox_wrapper.c"

Agent creates: ~/.claude/tests/firefox_wrapper/test_*.c


Step 8: Deploy
──────────────
If comprehensive review shows APPROVE:

User: "Add src/firefox_wrapper.c to Makefile and deploy"
```

---

### Workflow 2: Security Audit (Existing Code)

```
Step 1: Automated Scan
──────────────────────
User: "Use c-static-analyzer to scan src/protect_wrapper.c"


Step 2: Parallel Audits
────────────────────────
User: "Launch all specialized auditors in parallel to review 
       src/protect_wrapper.c"


Step 3: Comprehensive Assessment
─────────────────────────────────
User: "Use c-security-reviewer to assess src/protect_wrapper.c and 
       identify vulnerabilities"


Step 4: Remediation
───────────────────
Follow P0/P1/P2/P3 priorities from comprehensive review.
```

---

### Workflow 3: Bug Fix (Security-Focused)

```
Step 1: Implement Fix
─────────────────────
User: "Fix the buffer overflow in src/text_wrapper.c line 45"


Step 2: Quick Verification
──────────────────────────
User: "Use c-memory-safety-auditor to verify the fix"


Step 3: Regression Test
───────────────────────
User: "Use c-security-tester to add regression test for the buffer 
       overflow fix"
```

---

## File Organization

The agent team creates this structure:

```
~/.claude/
├── architecture/
│   ├── firefox_wrapper.md          # Design specs
│   ├── protect_wrapper.md
│   └── text_wrapper.md
│
├── reviews/
│   ├── firefox_wrapper/
│   │   ├── static-analysis.md      # Automated tools
│   │   ├── memory-safety.md        # Memory audit
│   │   ├── privilege.md            # Privilege audit
│   │   ├── race-conditions.md      # Race audit
│   │   └── comprehensive.md        # Synthesis + recommendations
│   ├── protect_wrapper/
│   └── text_wrapper/
│
└── tests/
    ├── firefox_wrapper/
    │   ├── test_authorization.c
    │   ├── test_input_validation.c
    │   ├── test_privilege_drop.c
    │   └── FUZZING.md              # AFL fuzzing strategy
    ├── protect_wrapper/
    └── text_wrapper/
```

---

## Integration with Your Codebase

### DEV-NOTE Comments

Agents add security annotations using your existing DEV-NOTE pattern:

```c
/* DEV-NOTE: Privilege drop must succeed - abort on failure */
if (drop_privileges(TARGET_USER) != 0) {
    abort();
}

/* DEV-NOTE: Buffer size checked - cannot overflow */
snprintf(buf, sizeof(buf), "%s", input);

/* DEV-NOTE: TOCTOU prevented - using FD not path */
if (fstat(fd, &st) != 0) {
    close(fd);
    return -errno;
}
```

### Makefile Integration

Add to your existing Makefile:

```makefile
# Security analysis targets
.PHONY: security-scan security-test

security-scan: src/%.c
	@echo "Running static analysis..."
	clang-analyzer src/*.c
	cppcheck --enable=all src/*.c

security-test: tests/test_%.c
	@echo "Running security tests..."
	$(CC) -o tests/run_tests tests/test_*.c
	./tests/run_tests
```

---

## Best Practices

### 1. Always Start with Architecture

**DON'T:**
```
"Write a setuid wrapper for GPU access"
```

**DO:**
```
"Use c-security-architect to design a setuid wrapper for GPU access"
(then)
"Use c-security-coder to implement following the architecture"
```

### 2. Run Auditors in Parallel

**DON'T:**
```
"Use c-memory-safety-auditor to review src/wrapper.c"
(wait for completion)
"Use c-privilege-auditor to review src/wrapper.c"
(wait for completion)
```

**DO:**
```
"Launch c-memory-safety-auditor, c-privilege-auditor, and 
 c-race-condition-auditor in parallel to review src/wrapper.c"
```

### 3. Let the Reviewer Synthesize

**DON'T:**
```
Try to manually combine findings from 3 audit reports
```

**DO:**
```
"Use c-security-reviewer to synthesize findings and create 
 remediation plan"
```

### 4. Fix P0 Issues Immediately

If comprehensive review shows P0 (blocker) issues:
1. Stop everything else
2. Fix P0 issues
3. Re-run audits to verify
4. Don't deploy until APPROVE

---

## Agent Capabilities Summary

| Agent | Can Read | Can Write | Model | Speed | Cost |
|-------|----------|-----------|-------|-------|------|
| c-security-architect | ✓ | ✓ (specs) | Sonnet | Slow | High |
| c-security-coder | ✓ | ✓ (code) | Sonnet | Slow | High |
| c-static-analyzer | ✓ | ✓ (reports) | Haiku | Fast | Low |
| c-memory-safety-auditor | ✓ | ✓ (reports) | Sonnet | Medium | Medium |
| c-privilege-auditor | ✓ | ✓ (reports) | Sonnet | Medium | Medium |
| c-race-condition-auditor | ✓ | ✓ (reports) | Sonnet | Medium | Medium |
| c-security-reviewer | ✓ | ✓ (reports) | Sonnet | Medium | Medium |
| c-security-tester | ✓ | ✓ (tests) | Haiku | Fast | Low |

---

## Common Scenarios

### Scenario: "I need to create a new setuid wrapper"

1. Use c-security-architect to design
2. Use c-security-coder to implement
3. Use c-static-analyzer for quick scan
4. Launch all auditors in parallel
5. Use c-security-reviewer to synthesize
6. Use c-security-tester to write tests
7. Deploy if APPROVE

### Scenario: "I found a bug in existing wrapper"

1. Fix the bug
2. Use relevant auditor to verify fix (e.g., c-memory-safety-auditor for buffer overflow)
3. Use c-security-tester to add regression test

### Scenario: "I want to audit all existing wrappers"

For each wrapper:
1. Use c-security-reviewer (it will delegate to specialized auditors)
2. Follow remediation plan for any findings

### Scenario: "I'm not sure if my code is secure"

1. Use c-security-reviewer for comprehensive assessment
2. It will tell you: BLOCK / DEPLOY WITH CAUTION / APPROVE
3. Follow the prioritized remediation plan

---

## Security Principles Enforced

All agents enforce:

1. **Memory Safety First** - 70% of vulnerabilities are memory-related
2. **Least Privilege** - Drop privileges ASAP, never regain
3. **Defense in Depth** - Multiple security layers
4. **Secure by Default** - Safe APIs, safe defaults, fail closed
5. **Audit Everything** - All privileged operations logged
6. **Input Validation** - Strict allowlisting, no trust
7. **No Custom Crypto** - Use libsodium, not homegrown

---

## References

- OWASP Secure Coding Practices
- SEI CERT C Coding Standard
- CWE Top 25 Most Dangerous Weaknesses
- Linux Kernel Security Documentation
- Google Bash Style Guide (for scripts)
