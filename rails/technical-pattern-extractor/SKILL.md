---
name: technical-pattern-extractor
description: Extract and generalize project-specific Rails patterns into reusable skills and knowledge notes
version: 1.0.0
trigger: extract pattern, generalize skill, port pattern, Rails pattern, technical pattern, reusable pattern
---

# Technical Pattern Extractor

Transform project-specific technical skills into reusable Rails patterns by removing project-specific references, preserving core pattern principles, and creating dual outputs (knowledge note + skill file).

## Core Principles

1. **Rails-Specific Generalization**: Extract patterns that apply to any Rails project. Remove project-specific model names, business logic, and file paths while preserving the core technical insight.
2. **Dual Output Strategy**: Each extraction creates a knowledge note (human-readable reference) AND a skill file (agent guidance with auto-activation triggers).
3. **Self-Contained Patterns**: Extracted patterns must be understandable without access to the source project.
4. **Source Attribution**: Always maintain clear lineage to the original project and skill.

## Extraction Workflow

### Phase 1: Source Reading
Read source skill from the project. Identify pattern category:

| Category | Indicators |
|----------|------------|
| ActiveRecord | Database queries, associations, callbacks, validations |
| Performance | Optimization, caching, N+1, query reduction |
| Testing | RSpec/Minitest patterns, factories, mocking |
| Stimulus | JavaScript controllers, Turbo, Hotwire |
| Architecture | Service objects, concerns, decorators, jobs |

Assess extraction viability using decision framework (below).

### Phase 2: Generalization
Replace project-specific elements with generic equivalents (e.g., `Spree::Order` → `Order`, business-specific columns → generic names, project file paths → removed). Extract core pattern principle: what problem does it solve, what's the fundamental insight, what are the key decision criteria. Create generic code examples preserving Rails idioms.

### Phase 3: Dual Output Creation
- **Knowledge note**: Human-readable reference with frontmatter (source_project, source_skill, date_extracted, tags, related_skill)
- **Skill file**: `.claude/skills/[pattern-name-kebab-case]/SKILL.md` — agent guidance with auto-activation triggers
- Add cross-references between outputs

### Phase 4: Verification
- Pattern is self-contained (no source project context required)
- All project-specific references removed
- Generic code examples compile conceptually
- Cross-references between note and skill are valid

## Decision Framework

- Is it project-specific business logic? → DO NOT EXTRACT
- Would it apply to any Rails project? → NO: too narrow, skip
- Can it be understood without source project context? → NO: needs more abstraction first
- YES to all → EXTRACT to appropriate category
