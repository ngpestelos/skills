---
name: backend-contract-format-compliance
description: "Detect and resolve format mismatches between frontend and backend contracts. Save-time normalization, threshold detection, gradual type strengthening. Trigger keywords: format mismatch, wrong format, decimal vs percentage, coordinate format, contract violation, 100x difference, save-time normalization."
---

# Backend Contract Format Compliance

Detect and resolve format mismatches between application layers that cause silent failures or incorrect output.

## Methodology

1. **Map data flow**: Frontend → Controller → Model (normalization) → Database → Service
2. **Add boundary logging**: Log at each layer transition to find where format diverges
3. **Document contract**: Comment the expected format at enforcement points

## Save-Time Normalization (Threshold-Based)

Use when legacy data exists in wrong format and immediate migration is too risky.

```ruby
def normalize_coordinate_format(placement)
  left = placement[:left].to_f
  top = placement[:top].to_f
  width = placement[:width].to_f
  height = placement[:height].to_f

  # If ALL values < 2.0, assume decimal format (0-1 range)
  # Rationale: placement < 2% of image would be invisible/unusable
  is_decimal_format = (left < 2.0 && top < 2.0 && width < 2.0 && height < 2.0)

  if is_decimal_format
    placement[:left] = left * 100
    placement[:top] = top * 100
    placement[:width] = width * 100
    placement[:height] = height * 100
    Rails.logger.info "[Normalization] Converted decimal to percentage"
  end

  placement
end
```

**Critical**: Check ALL values, not just one. If ANY >= threshold, treat entire set as percentage format.

## Prevention

```ruby
def validate_coordinate_format!(coords)
  [:left, :top, :width, :height].each do |key|
    value = coords[key].to_f
    unless value.between?(0, 100)
      raise ArgumentError, "#{key} must be between 0 and 100 (percentage format)"
    end
  end
end
```

**Gradual type strengthening**: Phase 1: log mismatches → Phase 2: deprecation warnings → Phase 3: reject invalid formats.

## Optimization History

- **March 13, 2026**: Five-step optimizer pass 1. 138 → 68 lines (51%).
- **April 1, 2026**: Five-step optimizer pass 2. Deleted symptoms (generic), threshold selection (obvious), dead REFERENCE.md references. 68 → 38 lines (44%).
