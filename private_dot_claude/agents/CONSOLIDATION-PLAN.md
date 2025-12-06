# Agent Consolidation Plan

**Created:** 2025-12-05
**Target:** Reduce from 87 local agents to ~25-30

## Summary

| Category | Before | After | Action |
|----------|--------|-------|--------|
| Pipeline Core | 8 | 8 | KEEP |
| Bash | 7 | 3 | MERGE |
| C Security | 8 | 4 | MERGE |
| Nix | 5 | 3 | MERGE (packager, nixos, deployer) |
| Python | 6 | 3 | MERGE |
| Go | 2 | 2 | KEEP |
| Rust | 2 | 2 | KEEP |
| Infrastructure | 14 | 1 | MERGE → cloud-engineer |
| Networking | 5 | 1 | MERGE → network-engineer |
| GPU/Embedded | 7 | 0 | DELETE |
| Media | 3 | 1 | MERGE → media-specialist |
| Database | 3 | 1 | MERGE → database-specialist |
| Shell variants | 3 | 1 | MERGE → zsh-hacker (keep one) |
| Utility | 8 | 6 | PRUNE |
| Other | 6 | 4 | PRUNE |
| **TOTAL** | **87** | **~41** | **53% reduction** |

---

## Phase 1: Pipeline Core (KEEP ALL - 8 agents)

No changes needed:
- `task-classifier` - haiku, fast routing
- `context-gatherer` - sonnet, orchestrates sub-gatherers
- `context-refiner` - sonnet, distills context
- `strategic-orchestrator` - opus, plans execution
- `architecture-gatherer` - haiku, sub-gatherer
- `dependency-gatherer` - haiku, sub-gatherer
- `history-gatherer` - haiku, sub-gatherer
- `pattern-gatherer` - haiku, sub-gatherer

---

## Phase 2: Language Specialists (MERGE)

### Bash: 7 → 3

| Keep | Absorbs | New Description |
|------|---------|-----------------|
| `bash-architect` | - | Design phase (unchanged) |
| `bash-specialist` | debugger, error-handler, optimizer, tester | Implementation & debugging |
| `bash-reviewer` | security-reviewer, style-enforcer | Security & style review |

**DELETE:** bash-debugger, bash-error-handler, bash-optimizer, bash-tester, bash-security-reviewer, bash-style-enforcer

### C Security: 8 → 4

| Keep | Absorbs | New Description |
|------|---------|-----------------|
| `c-security-architect` | - | Design phase (unchanged) |
| `c-security-auditor` | memory-safety, privilege, race-condition, static-analyzer | All vulnerability auditing |
| `c-security-coder` | - | Implementation (unchanged) |
| `c-security-reviewer` | tester | Synthesis + testing |

**DELETE:** c-memory-safety-auditor, c-privilege-auditor, c-race-condition-auditor, c-static-analyzer, c-security-tester

### Nix: 5 → 3

Nix has distinct domains requiring specialized knowledge:

| New Agent | Focus | Absorbs From |
|-----------|-------|--------------|
| `nix-packager` | nixpkgs, derivations, overlays, build systems, patching | nix-package-builder + packaging aspects of others |
| `nixos-specialist` | System-level: modules/options, home-manager, disko, impermanence, hardware | nix-module-writer + system aspects of others |
| `nix-deployer` | Dev shells, flakes, deployment (colmena, nixos-anywhere, hydra, disnix), targets (cloud, containers, bare metal) | deployment aspects of others |

**DELETE:** nix-architect, nix-module-writer, nix-package-builder, nix-debugger, nix-reviewer
**CREATE:** nix-packager, nixos-specialist, nix-deployer

### Python: 6 → 3

| Keep | Absorbs | New Description |
|------|---------|-----------------|
| `python-architect` | - | Design phase (unchanged) |
| `python-specialist` | async-specialist, ml-specialist | Implementation |
| `python-reviewer` | security-reviewer, quality-enforcer, test-writer | Quality & security |

**DELETE:** python-async-specialist, python-ml-specialist, python-security-reviewer, python-quality-enforcer, python-test-writer

---

## Phase 3: Infrastructure (AGGRESSIVE MERGE)

### Infrastructure: 14 → 1 (cloud-engineer)

**NEW:** `cloud-engineer`

Absorbs ALL of:
- ansible-specialist
- api-design-architect
- artifact-management-specialist
- cicd-architect
- classic-sysadmin-specialist
- cloud-provider-specialist
- gitops-specialist
- immutable-infrastructure-architect
- infrastructure-monitoring-specialist
- kubernetes-architect
- log-management-specialist
- observability-architect
- secrets-management-specialist
- terraform-specialist

**Description:**
```
Full-stack infrastructure engineer. Covers cloud platforms (AWS/GCP/Azure),
container orchestration (K8s), IaC (Terraform, Ansible, Salt), CI/CD pipelines,
observability (metrics/logs/traces), secrets management, and traditional sysadmin.
Use for any infrastructure, DevOps, or platform engineering task.
```

### Networking: 5 → 1 (network-engineer)

**NEW:** `network-engineer`

Absorbs:
- mikrotik-routeros-specialist
- network-routing-specialist
- packet-capture-analyst
- qos-specialist
- zerotier-specialist

**Description:**
```
Network engineering specialist. Covers routing protocols (BGP, OSPF), switching
(VLANs, STP), MikroTik RouterOS, ZeroTier SDN, QoS/traffic shaping (tc, CAKE, HTB),
and packet analysis (tcpdump, Wireshark). Use for network design, troubleshooting,
or configuration tasks.
```

---

## Phase 4: DELETE (Unused Tech)

Remove entirely (no consolidation):
- `cuda-specialist` - No NVIDIA GPU work
- `rocm-specialist` - No AMD GPU work
- `opencl-specialist` - No cross-platform GPU
- `vulkan-specialist` - No graphics programming
- `embedded-systems-hacker` - No MCU/firmware work
- `fpga-specialist` - No HDL/FPGA work
- `linux-kernel-hacker` - Rare use case

**Total: 7 agents deleted**

---

## Phase 5: Consolidate Remaining

### Media: 3 → 1

**NEW:** `media-specialist`

Absorbs: ffmpeg-specialist, gstreamer-specialist, streaming-specialist

### Database: 3 → 1

**NEW:** `database-specialist`

Absorbs: postgresql-specialist, redis-specialist, sql-specialist

### Shell: 3 → 1

**KEEP:** `zsh-hacker` (most relevant)
**DELETE:** fish-hacker, powershell-hacker

---

## Phase 6: Utility (KEEP/PRUNE)

**KEEP:**
- `critical-code-reviewer` - Deep analysis
- `docs-reviewer` - Documentation
- `text-manipulator` - Regex/parsing
- `websearch-specialist` - Research
- `visualization` - Diagrams
- `latex` - Documents

**MERGE:**
- `codepath-culler` + `codepath-culler-contrarian` → `dead-code-analyzer`
- `feature-prototyper` + `prototype-polisher` → `prototyper`

**KEEP as-is:**
- `go-architect`, `go-concurrency-auditor`
- `rust-architect`, `rust-unsafe-auditor`
- `typescript-specialist`
- `graphql-specialist`
- `security-testing-specialist`

---

## Execution Order

1. [ ] Create new merged agents (cloud-engineer, network-engineer, etc.)
2. [ ] Update descriptions to be CONCISE (< 100 chars each)
3. [ ] Delete superseded agents
4. [ ] Update CLAUDE.md references if needed
5. [ ] Test pipeline still works

---

## Token Impact Estimate

**Before:** ~17.4k tokens (agent descriptions)
**After:** ~6-8k tokens (estimated 55-60% reduction)

Key optimizations:
1. Fewer agents = fewer description entries
2. Shorter descriptions (aggressive trimming)
3. Remove verbose examples from descriptions
