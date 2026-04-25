---
name: proxy-measurement-designer
description: Design observable proxies for measuring invisible phenomena. Auto-activates when discussing indirect measurement, leading indicators, or quantifying hard-to-observe outcomes. Trigger keywords: proxy measurement, leading indicator, observable proxy, indirect measurement, inference, quantify.
license: MIT
metadata:
  author: ngpestelos
  version: "1.0.1"
---

# Proxy Measurement Designer

**Core principle**: "Measurement is never direct observation — it's always inference from observable effects to invisible causes. A thermometer measures its own temperature; it becomes useful only when reaching equilibrium with what you're trying to measure."

## The Four Principles

| Principle | Application | Test |
|-----------|------------|------|
| Thermal Equilibrium | Proxy must be genuinely connected to target, not just historically correlated | "If the target changed, would my proxy change?" |
| Proxy Properties | Find observable properties that change predictably with target | "What observable effect does this invisible phenomenon produce?" |
| Calibration | Validate proxy against cases where you know the true value | "How do I know my proxy is calibrated correctly?" |
| Minimal Disturbance | Measurement shouldn't significantly change what's being measured | Especially important with human behavior (Goodhart's Law) |

## The 5-Step Design Process

### Step 1: Define the Invisible Target
Be precise — "likelihood of production bugs" not "code quality"

### Step 2: Identify Observable Effects
Brainstorm all possible effects. Consider leading vs. lagging indicators.

### Step 3: Select Best Proxy Candidates
Evaluate: **Reliability** (consistent correlation?), **Measurability** (can you track it?), **Timeliness** (how quickly does it reflect changes?), **Gaming Resistance** (how easily manipulated?)

### Step 4: Calibrate Against Known Cases
Test where you know the true value. Document valid range and limitations.

### Step 5: Monitor for Goodhart's Law
"When a measure becomes a target, it ceases to be a good measure."

Defenses: multiple independent proxies, proxy rotation, qualitative overlay, leading + lagging indicators, measure proxy validity itself.

## Key Rules

- Start from the target, not from what's available — measuring the easy instead of the important is the most common mistake
- Never rely on a single proxy for complex phenomena — triangulate with multiple independent indicators
- Validate causal mechanism, not just correlation — happy employees may not cause productivity
- Match precision to signal strength — tracking satisfaction to 2 decimal places is meaningless
- All measurement is indirect — design proxies deliberately rather than accepting whatever is convenient
