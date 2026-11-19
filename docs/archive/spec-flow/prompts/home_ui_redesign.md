---
description: Redesign the app shell from tabs into an adventurer manual style home page
---

# Home UI Redesign

## Direction

Replace the current tab-based root with a single Home page inspired by a bright fantasy adventurer manual.

Confirmed choices:

1. App title: `Eorzea Toolkit`
2. Image placeholders may use `https://placehold.co` during development
3. Final assets should move to local asset catalogs later
4. Visual direction: bright parchment, antique gold details, readable card layout

## Scope

Use only existing implemented features:

- Item search
- Treasure maps
- Relic weapons
- Mini Cactpot
- Skill rotations

Do not add sample-image features that are not implemented yet, such as market prices, crafting notes, mount data, notifications, or settings.

## Home Layout

1. Header
   - Title: `Eorzea Toolkit`
   - Subtitle: `冒險工具手冊`
   - No fake settings or notification buttons for now

2. Hero banner
   - Development placeholder:
     `https://placehold.co/1200x420/efe3c4/5b4630?text=Eorzea+Toolkit`
   - Later replacement: local generated fantasy banner asset

3. Feature cards
   - Two-column card layout for the first four features
   - One wide card for Skill Rotations to avoid an awkward fifth half-width card
   - Each card contains a placeholder image, SF Symbol, title, description, and chevron

4. Navigation
   - Root uses `NavigationStack`
   - Card taps push into the existing feature views
   - Existing feature internals should stay unchanged unless navigation requires a small adjustment

## Feature Card Copy

- `道具搜尋`: `查詢道具資料、來源與相關資訊`
- `藏寶圖`: `查看藏寶圖位置與地點提示`
- `發光武器`: `追蹤發光武器資料與製作階段`
- `仙人微彩`: `輔助推算仙人微彩最佳選擇`
- `技能循環`: `查看職業技能與循環參考`

## Implementation Notes

- Keep the first implementation scoped to UI shell changes.
- Avoid using official Final Fantasy logos, screenshots, characters, or marks as assets.
- Prefer SwiftUI-native layout, small local components, and accessible labels.
- Keep placeholder imagery replaceable by centralizing URLs in the feature model.
