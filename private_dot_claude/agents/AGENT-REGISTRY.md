# Agent Registry

**Generated:** 2025-11-30
**Total Agents:** 205

This registry catalogs all available agents organized by source (local vs plugin).

## Quick Navigation

- [Local Agents](#local) - Your custom agents in `~/.claude/agents/`
- [Plugin Agents](#plugin) - Agents from installed plugins

## Model Key

| Model | Cost | Best For |
|-------|------|----------|
| `opus` | $$$ | Complex analysis, security audits, architecture |
| `sonnet` | $$ | Standard implementation, reviews |
| `haiku` | $ | Quick tasks, gathering, classification |
| `-` | default | Uses conversation model |

---


## local

| Agent | Model | Description |
|-------|-------|-------------|
| `ansible-specialist` | sonnet | Ansible automation expert. Use when writing playbooks, roles, or inventory files... |
| `api-design-architect` | opus | API design architect. Use proactively BEFORE building new APIs to design REST en... |
| `architecture-gatherer` | haiku | Gather architectural context - project structure, module organization, abstracti... |
| `artifact-management-specialist` | sonnet | Artifact/registry management expert. Use for container registries (Harbor, ECR),... |
| `bash-architect` | opus | Designs architecture for complex bash scripts. Use PROACTIVELY when starting a n... |
| `bash-debugger` | sonnet | Debugging specialist for bash script errors, test failures, and unexpected behav... |
| `bash-error-handler` | sonnet | Error handling specialist ensuring robust bash scripts. Use proactively when wri... |
| `bash-optimizer` | sonnet | Performance optimization specialist for bash scripts. Use when scripts are slow,... |
| `bash-security-reviewer` | opus | Security review specialist for bash scripts. Use proactively AFTER writing or mo... |
| `bash-style-enforcer` | haiku | Enforces Google Bash Style Guide and avoids BashPitfalls. Use proactively AFTER ... |
| `bash-tester` | haiku | Testing specialist for bash scripts using bats framework. Use proactively to cre... |
| `c-memory-safety-auditor` | opus | Audit C code for memory safety vulnerabilities (buffer overflows, use-after-free... |
| `c-privilege-auditor` | opus | Audit C code for privilege escalation vulnerabilities in setuid/setgid programs,... |
| `c-race-condition-auditor` | opus | Audit C code for race conditions including TOCTOU (time-of-check-time-of-use), s... |
| `c-security-architect` | opus | Design secure C implementations before coding. Use proactively before writing se... |
| `c-security-coder` | sonnet | Write secure C code following security architecture specifications. Use after c-... |
| `c-security-reviewer` | opus | Comprehensive security review synthesizing findings from all specialized auditor... |
| `c-security-tester` | sonnet | Write security-focused test cases for C code including fuzzing strategies, explo... |
| `c-static-analyzer` | haiku | Run automated static analysis tools (clang-analyzer, cppcheck, etc.) and compile... |
| `cicd-architect` | opus | CI/CD pipeline architect. Use proactively BEFORE building pipelines to design Gi... |
| `classic-sysadmin-specialist` | sonnet | Traditional Unix/Linux sysadmin - "the old ways". Use when modern tools are over... |
| `cloud-provider-specialist` | opus | Multi-cloud architecture expert (AWS/Azure/GCP/OVH/DO/Alibaba/Hetzner). Use for ... |
| `codepath-culler` | haiku | Identifies dead code, unused imports, unreachable code paths, and deprecated fun... |
| `codepath-culler-contrarian` | sonnet | Adversarial reviewer for codepath-culler findings. Challenges dead code removal ... |
| `context-gatherer` | sonnet | Exhaustively gather all relevant context for complex tasks from every available ... |
| `context-refiner` | sonnet | Distill massive context into clear, actionable, conflict-free intelligence |
| `critical-code-reviewer` | opus | Use this agent when you have completed a logical chunk of code implementation an... |
| `cuda-specialist` | sonnet | NVIDIA CUDA programming expert. Use for CUDA kernels, cuBLAS/cuDNN, memory coale... |
| `dependency-gatherer` | haiku | Gather dependency context - external deps, internal imports, interface contracts |
| `docs-reviewer` | haiku | Use this agent when documentationn needs to be created, modified, or updated for... |
| `embedded-systems-hacker` | opus | Embedded systems/firmware expert. Use for MCU programming (ARM, AVR, ESP32), RTO... |
| `feature-prototyper` | sonnet | Rapid prototyping specialist for quickly building working proof-of-concepts. Use... |
| `ffmpeg-specialist` | sonnet | FFmpeg expert. Use for video/audio transcoding, filtering, format conversion, an... |
| `fish-hacker` | sonnet | Fish shell scripting specialist. Use for writing fish scripts, functions, comple... |
| `fpga-specialist` | opus | FPGA/HDL development expert. Use for Verilog, VHDL, SystemVerilog, HLS, and FPGA... |
| `gitops-specialist` | sonnet | GitOps workflow expert (ArgoCD, Flux). Use for declarative K8s deployments, repo... |
| `go-architect` | opus | Go architecture and design specialist. Use proactively BEFORE implementing new G... |
| `go-concurrency-auditor` | sonnet | Go concurrency auditor. Use proactively AFTER writing goroutines, channels, or s... |
| `graphql-specialist` | sonnet | GraphQL API expert. Use when designing GraphQL schemas, implementing resolvers, ... |
| `gstreamer-specialist` | sonnet | GStreamer framework expert. Use for GStreamer pipeline construction, plugin deve... |
| `history-gatherer` | haiku | Gather historical context - git history, evolution, past decisions |
| `immutable-infrastructure-architect` | sonnet | Immutable infrastructure architect. Use for Packer image baking, AMI/image pipel... |
| `infrastructure-monitoring-specialist` | sonnet | Infrastructure monitoring expert (Prometheus, Grafana, Datadog, Nagios). Use for... |
| `kubernetes-architect` | opus | Kubernetes architect. Use proactively BEFORE deploying to K8s for cluster archit... |
| `latex` | sonnet | Generate LaTeX documents, mathematical equations, academic papers, presentations... |
| `linux-kernel-hacker` | opus | Linux kernel internals expert. Use for kernel module development, device drivers... |
| `log-management-specialist` | sonnet | Log management expert (ELK, Loki, Fluentd). Use for log aggregation, parsing, re... |
| `mikrotik-routeros-specialist` | sonnet | MikroTik RouterOS expert. Use for RouterOS CLI/Winbox configuration, MikroTik sc... |
| `network-routing-specialist` | sonnet | Network routing/switching generalist. Use for BGP, OSPF, VLANs, STP, and vendor-... |
| `nix-architect` | opus | Nix/NixOS architecture and design specialist. Use proactively before implementin... |
| `nix-debugger` | sonnet | Nix evaluation and debugging specialist. Use proactively when encountering Nix e... |
| `nix-module-writer` | sonnet | NixOS module implementation expert. Use proactively to create or modify NixOS mo... |
| `nix-package-builder` | sonnet | Nix package derivation and overlay specialist. Use proactively when creating cus... |
| `nix-reviewer` | haiku | Nix code review specialist. Use proactively after implementing Nix code to revie... |
| `observability-architect` | opus | Full-stack observability architect. Use proactively BEFORE implementing observab... |
| `opencl-specialist` | sonnet | OpenCL cross-platform compute expert. Use when code must run on multiple GPU ven... |
| `packet-capture-analyst` | sonnet | Packet capture/analysis expert. Use for tcpdump, Wireshark, tshark, BPF filters,... |
| `pattern-gatherer` | haiku | Gather pattern context - code patterns, conventions, style guides |
| `postgresql-specialist` | sonnet | PostgreSQL-specific expert. Use when working with PostgreSQL-only features: JSON... |
| `powershell-hacker` | sonnet | PowerShell scripting specialist. Use for writing PowerShell scripts, cmdlets, mo... |
| `prototype-polisher` | sonnet | Transforms rough prototypes into production-ready code. Use after feature-protot... |
| `python-architect` | opus | Design Python type hierarchies, Protocol classes, and multi-process architecture... |
| `python-async-specialist` | sonnet | Implement multiprocessing architectures - Process, Queue, Pipe, locks, graceful ... |
| `python-ml-specialist` | sonnet | PyTorch/ONNX/TensorRT optimization, OpenCV video processing, CUDA memory managem... |
| `python-quality-enforcer` | sonnet | Enforce mypy --strict, black formatting, ruff linting for Python codebases with ... |
| `python-security-reviewer` | sonnet | Security review for Python ML systems - RTSP credential handling, model loading ... |
| `python-test-writer` | sonnet | Write pytest tests with fixtures, parametrization, and mocking for ML/multiproce... |
| `qos-specialist` | sonnet | QoS/traffic shaping expert. Use for tc/CAKE/HTB configuration, DSCP marking, ban... |
| `redis-specialist` | sonnet | Redis expert. Use when implementing caching layers, choosing Redis data structur... |
| `rocm-specialist` | sonnet | AMD ROCm/HIP programming expert. Use for AMD GPU computing, HIP kernels, or port... |
| `rust-architect` | opus | Rust architecture and design specialist. Use proactively BEFORE implementing new... |
| `rust-unsafe-auditor` | sonnet | Rust unsafe code auditor. Use proactively AFTER writing or encountering unsafe b... |
| `saltstack-specialist` | sonnet | SaltStack configuration management expert. Use when writing Salt states, pillar ... |
| `secrets-management-specialist` | sonnet | Secrets management expert (Vault, SOPS, cloud KMS). Use for secrets storage, rot... |
| `security-testing-specialist` | sonnet | Authorized penetration testing expert. Use for vulnerability assessment, exploit... |
| `sql-specialist` | sonnet | Database-agnostic SQL expert. Use for query optimization, schema design, and ind... |
| `strategic-orchestrator` | opus | High-level strategic planning and agent coordination for complex multi-phase tas... |
| `streaming-specialist` | sonnet | Live streaming architecture expert. Use for RTMP/HLS/DASH/WebRTC protocol select... |
| `task-classifier` | haiku | Fast task complexity classifier for adaptive pipeline routing |
| `terraform-specialist` | sonnet | Terraform/OpenTofu IaC expert. Use when writing HCL modules, managing state back... |
| `text-manipulator` | haiku | Text processing specialist for regex patterns, sed/awk transformations, structur... |
| `typescript-specialist` | sonnet | TypeScript type system expert. Use when dealing with complex generics, condition... |
| `visualization` | sonnet | Generate visual representations including Mermaid diagrams, ASCII art, SVG graph... |
| `vulkan-specialist` | sonnet | Vulkan graphics/compute API expert. Use for Vulkan pipelines, render passes, syn... |
| `websearch-specialist` | haiku | Expert at formulating effective web searches and interpreting results. Use when ... |
| `zerotier-specialist` | sonnet | ZeroTier SDN expert. Use specifically for ZeroTier network configuration, flow r... |
| `zsh-hacker` | sonnet | Zsh shell scripting specialist. Use for writing, debugging, or optimizing zsh sc... |

## other

| Agent | Model | Description |
|-------|-------|-------------|
| `code-reviewer` | sonnet | \|
  Use this agent when a major project step has been completed and needs to be ... |

## plugin:accessibility-expert

| Agent | Model | Description |
|-------|-------|-------------|
| `accessibility-expert` | - | Examples:

<example> |

## plugin:agent-sdk-dev

| Agent | Model | Description |
|-------|-------|-------------|
| `agent-sdk-verifier-py` | sonnet | Use this agent to verify that a Python Agent SDK application is properly configu... |
| `agent-sdk-verifier-ts` | sonnet | Use this agent to verify that a TypeScript Agent SDK application is properly con... |

## plugin:ai-engineer

| Agent | Model | Description |
|-------|-------|-------------|
| `ai-engineer` | - | Use this agent when implementing AI/ML features, integrating language models, bu... |

## plugin:ai-ethics-governance-specialist

| Agent | Model | Description |
|-------|-------|-------------|
| `ai-ethics-governance-specialist` | - | Use this agent when you need to implement AI ethics frameworks, governance polic... |

## plugin:analytics-reporter

| Agent | Model | Description |
|-------|-------|-------------|
| `analytics-reporter` | - | Use this agent when analyzing metrics, generating insights from data, creating p... |

## plugin:angelos-symbo

| Agent | Model | Description |
|-------|-------|-------------|
| `angelos-symbo` | - | Use this agent when you need to create or convert prompts using the SYMBO (symbo... |

## plugin:api-integration-specialist

| Agent | Model | Description |
|-------|-------|-------------|
| `api-integration-specialist` | - | Use this agent when you need to design and implement internal API architecture, ... |

## plugin:api-tester

| Agent | Model | Description |
|-------|-------|-------------|
| `api-tester` | - | Use this agent for comprehensive API testing including performance testing, load... |

## plugin:app-store-optimizer

| Agent | Model | Description |
|-------|-------|-------------|
| `app-store-optimizer` | - | Use this agent when preparing app store listings, researching keywords, optimizi... |

## plugin:b2b-project-shipper

| Agent | Model | Description |
|-------|-------|-------------|
| `project-shipper` | - | PROACTIVELY use this agent when approaching B2B launch milestones, enterprise re... |

## plugin:backend-architect

| Agent | Model | Description |
|-------|-------|-------------|
| `backend-architect` | - | Use this agent when designing APIs, building server-side logic, implementing dat... |

## plugin:brand-guardian

| Agent | Model | Description |
|-------|-------|-------------|
| `brand-guardian` | - | Use this agent when establishing brand guidelines, ensuring visual consistency, ... |

## plugin:ceo-quality-controller-agent

| Agent | Model | Description |
|-------|-------|-------------|
| `1-ceo-quality-control-agent` | opus | Universal quality control orchestrator and final authority for any software deve... |

## plugin:code-architect

| Agent | Model | Description |
|-------|-------|-------------|
| `code-architect` | sonnet | Use this agent when you need to design scalable architecture and folder structur... |

## plugin:code-reviewer

| Agent | Model | Description |
|-------|-------|-------------|
| `code-reviewer` | - | Expert code review specialist. Proactively reviews code for quality, security, a... |

## plugin:codebase-documenter

| Agent | Model | Description |
|-------|-------|-------------|
| `codebase-documenter` | sonnet | Use this agent when you need to analyze a service or codebase component and crea... |

## plugin:compliance-automation-specialist

| Agent | Model | Description |
|-------|-------|-------------|
| `compliance-automation-specialist` | - | Use this agent when you need to automate compliance processes for SOC 2, ISO 270... |

## plugin:compounding-engineering

| Agent | Model | Description |
|-------|-------|-------------|
| `ankane-readme-writer` | - | Use this agent when you need to create or update README files following the Anka... |
| `architecture-strategist` | - | Use this agent when you need to analyze code changes from an architectural persp... |
| `best-practices-researcher` | - | Use this agent when you need to research and gather external best practices, doc... |
| `bug-reproduction-validator` | opus | Use this agent when you receive a bug report or issue description and need to ve... |
| `code-simplicity-reviewer` | - | Use this agent when you need a final review pass to ensure code changes are as s... |
| `data-integrity-guardian` | - | Use this agent when you need to review database migrations, data models, or any ... |
| `design-implementation-reviewer` | opus | Use this agent when you need to verify that a UI implementation matches its Figm... |
| `design-iterator` | - | Use this agent PROACTIVELY when design work isn't coming together on the first a... |
| `dhh-rails-reviewer` | - | Use this agent when you need a brutally honest Rails code review from the perspe... |
| `every-style-editor` | - | Use this agent when you need to review and edit text content to conform to Every... |
| `figma-design-sync` | sonnet | Use this agent when you need to synchronize a web implementation with its Figma ... |
| `framework-docs-researcher` | - | Use this agent when you need to gather comprehensive documentation and best prac... |
| `git-history-analyzer` | - | Use this agent when you need to understand the historical context and evolution ... |
| `julik-frontend-races-reviewer` | - | \|
  Use this agent when you need to review JavaScript or Stimulus frontend code ... |
| `kieran-python-reviewer` | - | Use this agent when you need to review Python code changes with an extremely hig... |
| `kieran-rails-reviewer` | - | Use this agent when you need to review Rails code changes with an extremely high... |
| `kieran-typescript-reviewer` | - | Use this agent when you need to review TypeScript code changes with an extremely... |
| `lint` | haiku | Use this agent when you need to run linting and code quality checks on Ruby and ... |
| `pattern-recognition-specialist` | - | Use this agent when you need to analyze code for design patterns, anti-patterns,... |
| `performance-oracle` | - | Use this agent when you need to analyze code for performance issues, optimize al... |
| `pr-comment-resolver` | - | Use this agent when you need to address comments on pull requests or code review... |
| `repo-research-analyst` | - | Use this agent when you need to conduct thorough research on a repository's stru... |
| `security-sentinel` | - | Use this agent when you need to perform security audits, vulnerability assessmen... |
| `spec-flow-analyzer` | sonnet | Use this agent when you have a specification, plan, feature description, or tech... |

## plugin:context7-docs-fetcher

| Agent | Model | Description |
|-------|-------|-------------|
| `context7-docs-fetcher` | - | Use this agent when you need to fetch and utilize documentation from Context7 fo... |

## plugin:customer-success-manager

| Agent | Model | Description |
|-------|-------|-------------|
| `customer-success-manager` | - | Use this agent when you need to optimize customer success operations for B2B ent... |

## plugin:data-privacy-engineer

| Agent | Model | Description |
|-------|-------|-------------|
| `data-privacy-engineer` | - | Use this agent when you need to implement data privacy engineering, GDPR complia... |

## plugin:data-scientist

| Agent | Model | Description |
|-------|-------|-------------|
| `data-scientist` | - | Data analysis expert for SQL queries, BigQuery operations, and data insights. Us... |

## plugin:database-performance-optimizer

| Agent | Model | Description |
|-------|-------|-------------|
| `database-performance-optimizer` | - | Use this agent when you need to optimize database performance for B2B applicatio... |

## plugin:debugger

| Agent | Model | Description |
|-------|-------|-------------|
| `debugger` | - | Debugging specialist for errors, test failures, and unexpected behavior. Use pro... |

## plugin:deployment-engineer

| Agent | Model | Description |
|-------|-------|-------------|
| `deployment-engineer` | sonnet | Use this agent when setting up CI/CD pipelines, configuring Docker containers, d... |

## plugin:devops-automator

| Agent | Model | Description |
|-------|-------|-------------|
| `devops-automator` | - | Use this agent when setting up CI/CD pipelines, configuring cloud infrastructure... |

## plugin:enterprise-integrator-architect

| Agent | Model | Description |
|-------|-------|-------------|
| `enterprise-integration-architect` | - | Use this agent when you need to design and implement complex external enterprise... |

## plugin:enterprise-onboarding-specialist

| Agent | Model | Description |
|-------|-------|-------------|
| `enterprise-onboarding-strategist` | - | Use this agent when you need to design and optimize complex enterprise customer ... |

## plugin:enterprise-security-reviewer

| Agent | Model | Description |
|-------|-------|-------------|
| `enterprise-security-reviewer` | - | Use this agent for comprehensive B2B security assessments, enterprise compliance... |

## plugin:experienced-engineer

| Agent | Model | Description |
|-------|-------|-------------|
| `api-architect` | - | Expert in designing robust, scalable, and well-documented APIs. Use for REST/Gra... |
| `code-quality-reviewer` | - | Expert in maintaining high code quality standards, clean code principles, and be... |
| `database-architect` | - | Expert in database design, optimization, and ensuring data integrity and perform... |
| `devops-engineer` | - | Expert in CI/CD, infrastructure automation, deployment strategies, and operation... |
| `documentation-writer` | - | Expert in creating clear, comprehensive technical documentation for developers a... |
| `performance-engineer` | - | Expert in optimizing application performance, identifying bottlenecks, and impro... |
| `security-specialist` | - | Expert in identifying and mitigating security vulnerabilities and implementing s... |
| `tech-lead` | - | Expert in technical leadership, architecture decisions, and coordinating develop... |
| `testing-specialist` | - | Expert in comprehensive testing strategies, test automation, and ensuring code r... |
| `ux-ui-designer` | - | Expert in user experience design, interface design, and creating intuitive user ... |

## plugin:experiment-tracker

| Agent | Model | Description |
|-------|-------|-------------|
| `experiment-tracker` | - | PROACTIVELY use this agent when experiments are started, modified, or when resul... |

## plugin:feature-dev

| Agent | Model | Description |
|-------|-------|-------------|
| `code-architect` | sonnet | Designs feature architectures by analyzing existing codebase patterns and conven... |
| `code-explorer` | sonnet | Deeply analyzes existing codebase features by tracing execution paths, mapping a... |

## plugin:feedback-synthesizer

| Agent | Model | Description |
|-------|-------|-------------|
| `feedback-synthesizer` | - | Use this agent when you need to analyze user feedback from multiple sources, ide... |

## plugin:finance-tracker

| Agent | Model | Description |
|-------|-------|-------------|
| `finance-tracker` | - | Use this agent when managing budgets, optimizing costs, forecasting revenue, or ... |

## plugin:flutter-mobile-app-dev

| Agent | Model | Description |
|-------|-------|-------------|
| `flutter-dev` | sonnet | Use this agent when you need expert assistance with Flutter mobile development t... |

## plugin:frontend-developer

| Agent | Model | Description |
|-------|-------|-------------|
| `frontend-developer` | - | Use this agent when building user interfaces, implementing React/Vue/Angular com... |

## plugin:hookify

| Agent | Model | Description |
|-------|-------|-------------|
| `conversation-analyzer` | inherit | Use this agent when analyzing conversation transcripts to find behaviors worth p... |

## plugin:infrastructure-maintainer

| Agent | Model | Description |
|-------|-------|-------------|
| `infrastructure-maintainer` | - | Use this agent when monitoring system health, optimizing performance, managing s... |

## plugin:joker

| Agent | Model | Description |
|-------|-------|-------------|
| `joker` | - | Use this agent when you need to lighten the mood, create funny content, or add h... |

## plugin:legal-advisor

| Agent | Model | Description |
|-------|-------|-------------|
| `legal-advisor` | - | Use this agent when you need legal advisory, compliance documentation, RFP respo... |

## plugin:legal-compliance-checker

| Agent | Model | Description |
|-------|-------|-------------|
| `legal-compliance-checker` | - | Use this agent when reviewing terms of service, privacy policies, ensuring regul... |

## plugin:mobile-app-builder

| Agent | Model | Description |
|-------|-------|-------------|
| `mobile-app-builder` | - | Use this agent when developing native iOS or Android applications, implementing ... |

## plugin:mobile-ux-optimizer

| Agent | Model | Description |
|-------|-------|-------------|
| `mobile-ux-optimizer` | sonnet | Use this agent when you need to optimize UI/UX components or interfaces for mobi... |

## plugin:monitoring-observability-specialist

| Agent | Model | Description |
|-------|-------|-------------|
| `monitoring-observability-specialist` | - | Use this agent when you need to implement comprehensive monitoring, observabilit... |

## plugin:n8n-workflow-builder

| Agent | Model | Description |
|-------|-------|-------------|
| `n8n-workflow-builder` | sonnet | Use this agent when you need to design, build, or validate n8n automation workfl... |

## plugin:onomastophes

| Agent | Model | Description |
|-------|-------|-------------|
| `onomastophes` | - | Use proactively for generating creative non-olympian Greek god names with rich b... |

## plugin:performance-benchmarker

| Agent | Model | Description |
|-------|-------|-------------|
| `performance-benchmarker` | - | Use this agent for comprehensive performance testing, profiling, and optimizatio... |

## plugin:planning-prd-agent

| Agent | Model | Description |
|-------|-------|-------------|
| `planning-prd-agent` | opus | 'MUST BE USED PROACTIVELY when user mentions: planning, PRD, product requirement... |

## plugin:plugin-dev

| Agent | Model | Description |
|-------|-------|-------------|
| `agent-creator` | sonnet | Use this agent when the user asks to "create an agent", "generate an agent", "bu... |
| `plugin-validator` | inherit | Use this agent when the user asks to "validate my plugin", "check plugin structu... |
| `skill-reviewer` | inherit | Use this agent when the user has created or modified a skill and needs quality r... |

## plugin:pr-review-toolkit

| Agent | Model | Description |
|-------|-------|-------------|
| `code-reviewer` | opus | Use this agent when you need to review code for adherence to project guidelines,... |
| `code-simplifier` | opus | Use this agent when code has been written or modified and needs to be simplified... |
| `comment-analyzer` | inherit | Use this agent when you need to analyze code comments for accuracy, completeness... |
| `pr-test-analyzer` | inherit | Use this agent when you need to review a pull request for test coverage quality ... |
| `silent-failure-hunter` | inherit | Use this agent when reviewing code changes in a pull request to identify silent ... |
| `type-design-analyzer` | inherit | Use this agent when you need expert analysis of type design in your codebase. Sp... |

## plugin:prd-specialist

| Agent | Model | Description |
|-------|-------|-------------|
| `prd-specialist` | sonnet | Use this agent when you need to create comprehensive Product Requirements Docume... |

## plugin:pricing-packaging-specialist

| Agent | Model | Description |
|-------|-------|-------------|
| `pricing-packaging-strategist` | - | Use this agent when you need to optimize B2B pricing strategies, packaging model... |

## plugin:problem-solver-specialist

| Agent | Model | Description |
|-------|-------|-------------|
| `1-problem-solver-specialist` | opus | Universal expert problem-solving agent specializing in complex debugging, myster... |

## plugin:product-sales-specialist

| Agent | Model | Description |
|-------|-------|-------------|
| `product-sales-specialist` | - | Use this agent when you need to support B2B sales through product design, user r... |

## plugin:project-curator

| Agent | Model | Description |
|-------|-------|-------------|
| `project-curator` | opus | Reorganizes project structure by cleaning root clutter, creating logical folder ... |

## plugin:project-shipper

| Agent | Model | Description |
|-------|-------|-------------|
| `project-shipper` | - | PROACTIVELY use this agent when approaching launch milestones, release deadlines... |

## plugin:python-expert

| Agent | Model | Description |
|-------|-------|-------------|
| `python-expert` | sonnet | Use this agent when working with Python code that requires advanced features, pe... |

## plugin:rapid-prototyper

| Agent | Model | Description |
|-------|-------|-------------|
| `rapid-prototyper` | - | Use this agent when you need to quickly create a new application prototype, MVP,... |

## plugin:react-native-dev

| Agent | Model | Description |
|-------|-------|-------------|
| `react-native-dev` | sonnet | Use this agent when you need expert assistance with React Native development tas... |

## plugin:sprint-prioritizer

| Agent | Model | Description |
|-------|-------|-------------|
| `sprint-prioritizer` | - | Use this agent when planning 6-day development cycles, prioritizing features, ma... |

## plugin:studio-coach

| Agent | Model | Description |
|-------|-------|-------------|
| `studio-coach` | - | PROACTIVELY use this agent when complex multi-agent tasks begin, when agents see... |

## plugin:studio-producer

| Agent | Model | Description |
|-------|-------|-------------|
| `studio-producer` | - | PROACTIVELY use this agent when coordinating across multiple teams, allocating r... |

## plugin:sugar

| Agent | Model | Description |
|-------|-------|-------------|
| `quality-guardian` | - | Code quality, testing, and validation enforcement specialist |
| `sugar-orchestrator` | - | Coordinates Sugar's autonomous development workflows with strategic oversight |
| `task-planner` | - | Strategic task planning and breakdown specialist for complex development work |

## plugin:support-responder

| Agent | Model | Description |
|-------|-------|-------------|
| `support-responder` | - | Use this agent when handling customer support inquiries, creating support docume... |

## plugin:technical-sales-engineer

| Agent | Model | Description |
|-------|-------|-------------|
| `technical-sales-engineer` | - | Use this agent when you need to bridge technical and sales requirements for B2B ... |

## plugin:test-results-analyzer

| Agent | Model | Description |
|-------|-------|-------------|
| `test-results-analyzer` | - | Use this agent for analyzing test results, synthesizing test data, identifying t... |

## plugin:test-writer-fixer

| Agent | Model | Description |
|-------|-------|-------------|
| `test-writer-fixer` | - | Use this agent when code changes have been made and you need to write new tests,... |

## plugin:tiktok-strategist

| Agent | Model | Description |
|-------|-------|-------------|
| `tiktok-strategist` | - | Use this agent when you need to create TikTok marketing strategies, develop vira... |

## plugin:tool-evaluator

| Agent | Model | Description |
|-------|-------|-------------|
| `tool-evaluator` | - | Use this agent when evaluating new development tools, frameworks, or services fo... |

## plugin:trend-researcher

| Agent | Model | Description |
|-------|-------|-------------|
| `trend-researcher` | - | Use this agent when you need to identify market opportunities, analyze trending ... |

## plugin:ui-designer

| Agent | Model | Description |
|-------|-------|-------------|
| `ui-designer` | - | Use this agent when creating user interfaces, designing components, building des... |

## plugin:unit-test-generator

| Agent | Model | Description |
|-------|-------|-------------|
| `unit-test-generator` | sonnet | Expert Flutter/Dart unit test specialist that systematically improves test cover... |

## plugin:ux-researcher

| Agent | Model | Description |
|-------|-------|-------------|
| `ux-researcher` | - | Use this agent when conducting user research, analyzing user behavior, creating ... |

## plugin:vision-specialist

| Agent | Model | Description |
|-------|-------|-------------|
| `vision-specialist` | opus | Expert in vision models, OCR systems, barcode detection, and visual AI. Stays cu... |

## plugin:visual-storyteller

| Agent | Model | Description |
|-------|-------|-------------|
| `visual-storyteller` | - | Use this agent when creating visual narratives, designing infographics, building... |

## plugin:web-dev

| Agent | Model | Description |
|-------|-------|-------------|
| `web-dev` | sonnet | Use this agent for expert assistance with web development tasks using React, Nex... |

## plugin:whimsy-injector

| Agent | Model | Description |
|-------|-------|-------------|
| `whimsy-injector` | - | PROACTIVELY use this agent after any UI/UX changes to ensure delightful, playful... |

## plugin:workflow-optimizer

| Agent | Model | Description |
|-------|-------|-------------|
| `workflow-optimizer` | - | Use this agent for optimizing human-agent collaboration workflows and analyzing ... |
