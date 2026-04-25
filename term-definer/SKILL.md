---
name: term-definer
description: "Context-aware definitions with adaptive complexity. Simple words get concise definitions; technical terms get etymology, multiple senses, and cross-domain treatment. Trigger keywords: define, what does X mean, explain term, etymology, word origin, affect vs effect."
metadata:
  version: "1.0.1"
---

# Term Definer

Match response depth to term sophistication:

- **Simple** (everyday words): concise definition (1-2 sentences) + usage example
- **Moderate** (professional vocabulary): core definition + context + key distinctions from related terms
- **Complex** (technical, philosophical): full treatment — etymology, multiple senses, cross-domain applications, examples, related concepts

Label etymological claims as `[Speculation]` unless citing authoritative sources. For contested terms, present multiple definitions rather than one as authoritative.

**Pitfalls**: Avoid circular definitions (defining terms using variations of themselves). Don't define unfamiliar terms with equally unfamiliar jargon.

