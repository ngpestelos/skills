---
name: parallel-development-strategy
description: "Build features and foundation simultaneously through iterative refinement. Maintain 'best possible product at every moment.' Sketch-to-detail approach ensures completeness and shippability throughout. Trigger keywords: parallel development, breadth first, sketch to detail, MVP strategy, all features simultaneously, minimum viable product, product steering."
metadata:
  version: "1.0.0"
---

# Parallel Development Strategy

## The Sketch-to-Detail Metaphor

> "Rather than drawing one corner in perfect detail while leaving the rest blank (feature-at-a-time), or spending all time preparing the canvas (foundation-first), **sketch the rough outline first**. Then progressively add detail to the whole picture until time runs out."

**Guarantee**: At ANY point, you have a complete recognizable product.

## The 4-Step Approach

### Step 1: Define Complete-Enough Scope

List every feature needed for product viability. **Complete enough > glorious enough** (breadth before depth).

Identify: Core features (must-have), Desirable features (add value), Foundation (infrastructure).

### Step 2: Define Minimum Viable for Each

For EACH feature, define the simplest functional version:
- Core capability that works
- Minimum foundation to support it
- What's deliberately excluded for later

**Goal**: Every feature has a "simple yet functional" V1.0.

### Step 3: Build All V1.0s in Parallel

Work streams across all features simultaneously:
- Feature A: V1.0 implementation
- Feature B: V1.0 implementation
- Feature C: V1.0 implementation
- Foundation: Minimum to support all

**Deliverable**: Sketch of entire product — complete and shippable.

### Step 4: Iterate All Features Together

Refine all features to V1.1, V1.2 together. Steering determines where to add detail.

```
Week 1-2: Rough sketch (all features at V1.0)
Week 3-4: Add rough color (all features at V1.1)
Week 5-6: Add detail selectively (steering-driven)
```

## Steering Mechanism

Weekly review:
1. If we shipped today, what's missing? (Completeness)
2. Which features are below acceptable quality? (Quality)
3. Where can we add most value with remaining time? (Priority)

## Anti-Patterns

| Pattern | Symptom | Intervention |
|---------|---------|--------------|
| Foundation Creep | Infrastructure consuming most time | "What features need this? Defer until needed." |
| Feature Perfectionism | One feature perfect, others missing | "Good enough for now. Bring others up." |
| Scope Creep | New features added mid-development | "Add to backlog for next phase." |
| No Steering | Rigidly following initial plan | "Adjust priorities based on what you've learned." |
