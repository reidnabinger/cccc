---
description: Security-focused code review targeting vulnerabilities
---

# Security Audit: $ARGUMENTS

You are conducting a security audit. This is adversarial analysis - assume attackers are looking at this code.

## Scope

Target: $ARGUMENTS (if empty, audit recent changes or prompt for scope)

## Phase 1: Identify Attack Surface

Use **serena-agent** to map:

1. Entry points (API endpoints, CLI args, file inputs, env vars)
2. Data flows (where does user input go?)
3. Trust boundaries (where does untrusted data become trusted?)
4. Privilege operations (auth, authz, file system, network, exec)

## Phase 2: OWASP Top 10 Check

Systematically check for:

### A01: Broken Access Control
- [ ] Authorization checks on all sensitive operations
- [ ] No IDOR (Insecure Direct Object References)
- [ ] Proper role/permission enforcement
- [ ] No privilege escalation paths

### A02: Cryptographic Failures
- [ ] No hardcoded secrets
- [ ] Proper encryption for sensitive data
- [ ] Secure random number generation
- [ ] No weak algorithms

### A03: Injection
- [ ] SQL injection (parameterized queries?)
- [ ] Command injection (safe subprocess usage?)
- [ ] XSS (proper HTML escaping?)
- [ ] Path traversal (user input in file paths?)

### A04: Insecure Design
- [ ] Threat modeling done?
- [ ] Security requirements defined?
- [ ] Defense in depth?

### A05: Security Misconfiguration
- [ ] Debug mode disabled in production?
- [ ] Secure defaults?
- [ ] Error messages don't leak info?

### A06: Vulnerable Components
- [ ] Dependencies up to date?
- [ ] Known CVEs in dependencies?
- [ ] Minimal dependency surface?

### A07: Authentication Failures
- [ ] Strong password requirements?
- [ ] Rate limiting on auth endpoints?
- [ ] Secure session management?

### A08: Data Integrity Failures
- [ ] Input validation?
- [ ] Safe deserialization? (use JSON, not unsafe formats)
- [ ] CI/CD pipeline secure?

### A09: Logging Failures
- [ ] Security events logged?
- [ ] No sensitive data in logs?

### A10: SSRF
- [ ] URL validation on user-provided URLs?
- [ ] No internal network access from user input?

## Phase 3: Language-Specific Checks

Invoke the appropriate advisor - they know the dangerous patterns for each language:

- **bash-advisor** - Shell script vulnerabilities
- **c-advisor** - Memory safety, buffer overflows
- **python-advisor** - Python-specific security issues
- **nix-advisor** - Nix expression security

The advisors have comprehensive checklists for language-specific vulnerabilities.

## Phase 4: Search for Red Flags

Use Grep to search for:
- Hardcoded credentials or secrets
- Unsafe function calls (advisors know the patterns)
- String interpolation in security-sensitive contexts
- Missing input validation

## Phase 5: Report

Produce a security report:

```markdown
## Security Audit Report

### Scope
[What was audited]

### Executive Summary
- **Critical**: [count]
- **High**: [count]
- **Medium**: [count]
- **Low**: [count]

### Critical Findings
1. **[Title]** - [Location]
   - **Vulnerability**: [Description]
   - **Exploitability**: [How an attacker could use this]
   - **Impact**: [What damage could be done]
   - **Remediation**: [How to fix]

### High/Medium/Low Findings
[Same format]

### Positive Observations
[Security controls that ARE working well]

### Recommendations
1. [Priority action 1]
2. [Priority action 2]
```

## Severity Ratings

- **Critical**: Remote code execution, auth bypass, data breach
- **High**: Privilege escalation, significant data exposure
- **Medium**: Limited impact, requires specific conditions
- **Low**: Defense in depth issue, informational

**Assume hostile intent. Find vulnerabilities before attackers do.**
