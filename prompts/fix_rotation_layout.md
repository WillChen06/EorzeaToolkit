---
description: Fix skill rotation editor layout - rotation bar height constraints
---

# Fix: SkillRotationEditorView layout issue

## Problem
In `SkillRotationEditorView`, the rotation bar (top section showing selected skills) grows unbounded as users add more skills. This pushes the skill grid (bottom section) off screen, making it unusable.

## Required behavior

The rotation bar height should follow these rules:

1. **1–6 skills**: single row height (no scroll)
2. **7–12 skills**: two rows height (no scroll)
3. **Continue growing** until the skill grid below would be compressed below 30% of screen height
4. **Once at max height**: rotation bar becomes scrollable internally, height stays fixed
5. **Skill grid below**: always retains at least 30% of the available screen height

## Implementation approach

Use `GeometryReader` to get the available height, then calculate:

```
let availableHeight = geometry.size.height
let minSkillGridHeight = availableHeight * 0.3
let maxRotationHeight = availableHeight - minSkillGridHeight - categoryFilterHeight - dividers

// If rotation content height > maxRotationHeight → wrap in ScrollView with .frame(maxHeight: maxRotationHeight)
// Otherwise → show at natural height (no scroll needed)
```

Key points:
- The rotation bar content is a `LazyVGrid` with `GridItem(.adaptive(minimum: 48), spacing: 8)` — each row is roughly 44 + 8 = 52pt
- Category filter + dividers ≈ ~50pt fixed height
- Only the rotation bar section should become scrollable; the overall page structure stays the same
- Do NOT make the entire top area (rotation + category filter) scroll together

## File to modify
Find the `SkillRotationEditorView` in the project and update only the layout logic. Do not change any other functionality (drag & drop, context menus, filtering, etc.).
