---
name: para-organizer
description: "Expert guidance for organizing content according to Tiago Forte's PARA methodology (Projects/Areas/Resources/Archives) with actionability-based categorization, decision tree framework, Container Principle, Cathedral Effect, and topic synthesis patterns. Trigger keywords: PARA, organize, categorize, where should this go, topic organization, related documents, synthesis, actionability, decision tree, Container Principle, Cathedral Effect, magic number 4, file organization, folder structure, Tiago Forte, Second Brain."
allowed-tools: Read, Grep, Glob
---

# PARA Organizer

Organize content using the PARA Method — categorization by actionability, not taxonomy.

## Core Principles

- **Actionability Over Taxonomy**: PARA asks "What is this for?" not "What is this about?" Same document goes different places depending on current actionability.
- **Magic Number 4**: Four categories match working memory capacity, reducing decision fatigue.
- **Container Principle**: Every project begins with a folder — signals commitment, enables bold creative risks.
- **Cathedral Effect**: Digital containers shape thinking quality, like physical spaces shape thought.

## Decision Tree

```
Is this related to a current project with a deadline?
├── YES → 0 Projects/
└── NO → Is this related to an ongoing responsibility?
    ├── YES → 1 Areas/
    └── NO → Is this a topic I'm interested in?
        ├── YES → 2 Resources/
        └── NO → Keep at all?
            ├── YES → 3 Archives/
            └── NO → Delete
```

## The Four Categories

| Category | Nature | Key Question |
|----------|--------|-------------|
| **Projects** | Time-bound, specific outcome, deadline | "What am I trying to accomplish right now?" |
| **Areas** | Ongoing responsibility, standard to maintain | "What responsibilities must I maintain?" |
| **Resources** | Topics of interest, reference material | "What topics am I exploring?" |
| **Archives** | Inactive items from the other three | "What can I set aside?" |

## Vault Structure

- **0 Projects/**: Time-bound initiatives with deadlines and specific outcomes
- **1 Areas/**: Ongoing responsibilities organized by life domain (work, family, health, etc.)
- **2 Resources/**: Topics of interest, reference material, curated collections
- **3 Archives/**: Inactive items from any of the above three categories

## Content Transitions

| Transition | Trigger |
|-----------|---------|
| Project → Archives | Completion or abandonment |
| Areas → Archives | Role/responsibility permanently concluded (rare) |
| Resources → Archives | Information no longer relevant |
| Archives → Active | Previously completed work becomes relevant again |

## Topic Organization (Resources)

When multiple documents share a theme across complementary angles:

1. **Create topic directory**: `2 Resources/Topics/[Topic Name]/`
2. **Move documents**: `git mv` to preserve history
3. **Create synthesizing README**: Must reveal insights not present in individual documents (not just summaries)
4. **Document relationships**: Macro/micro, theoretical/empirical, why/how

**Anti-patterns**: File dumping without README, README as mere summary, creating topics for single documents.

## Key Principles

1. Actionability is primary — not topic, theme, or source
2. Projects have end dates; if ongoing, it's an Area
3. Areas are responsibilities (standards to maintain, not goals to achieve)
4. Movement between categories is expected and healthy
5. Quick categorization beats perfect taxonomy
