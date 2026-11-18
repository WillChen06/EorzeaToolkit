---
description: Add tinctures (medicines) tab to skill rotation editor
---

# Add tinctures to Skill Rotation Editor

## Overview

Add a "道具" (Items) category tab to the skill rotation editor so users can insert tinctures (stat potions) into their rotation. In high-end raids, players use a tincture at specific points in the rotation.

## What to change

### 1. Category filter: add "道具" tab

Current tabs: `全部` `戰技` `魔法` `能力`
New tabs: `全部` `戰技` `魔法` `能力` `道具`

When "道具" is selected, show tinctures instead of actions.

### 2. Tincture display logic

When the user selects a job (e.g. PLD), filter tinctures by the stat that matches the job:

- `battle_actions.json` contains `tincture_stat_jobs` which maps `stat → jobs[]`
- Example: PLD is in `strength.jobs`, so show only strength tinctures (剛力之寶藥, 2級剛力之寶藥, 3級剛力之寶藥, 4級剛力之寶藥)
- Sort by `item_level` descending (latest tier first)

### 3. Tinctures in the rotation bar

Tinctures should be addable to the rotation just like skills — tap to add, drag to reorder, long-press to delete. They use the same `RotationSlot` mechanism.

### 4. Long-press detail card for tinctures

Show a simplified detail card:
- Icon + name
- Tag: "道具"
- Item Level (e.g. "iLv.770")
- Stat boost info (e.g. "力量 +10%")

No cast/recast/range fields needed.

## Data source

`battle_actions.json` already contains the tincture data:

```json
{
  "tinctures": [
    {
      "id": 49234,
      "name_cn": "4级刚力之宝药",
      "name_tw": "4級剛力之寶藥",
      "icon_id": 20710,
      "icon_path": "020000/020710_hr1.tex",
      "item_level": 770,
      "stat": "strength"
    }
  ],
  "tincture_stat_jobs": {
    "strength": { "name_tw": "力量", "jobs": ["PLD","WAR","DRK","GNB","DRG","SAM","RPR","VPR"] },
    "dexterity": { "name_tw": "靈巧", "jobs": ["MNK","NIN","BRD","MCH","DNC"] },
    "intelligence": { "name_tw": "智力", "jobs": ["BLM","SMN","RDM","PCT"] },
    "mind": { "name_tw": "精神", "jobs": ["WHM","SCH","AST","SGE"] }
  }
}
```

Icon URL uses the same template: `https://beta.xivapi.com/api/1/asset/ui/icon/{icon_path}?format=png`

## Model changes

Add a `Tincture` struct (similar to `BattleAction` but simpler):

```swift
struct Tincture: Codable, Identifiable {
    let id: Int
    let nameCn: String
    let nameTw: String
    let iconId: Int
    let iconPath: String
    let itemLevel: Int
    let stat: String

    enum CodingKeys: String, CodingKey {
        case id, stat
        case nameCn = "name_cn"
        case nameTw = "name_tw"
        case iconId = "icon_id"
        case iconPath = "icon_path"
        case itemLevel = "item_level"
    }
}
```

`RotationSlot` needs to support both action and tincture. Consider using an enum:

```swift
enum RotationItem {
    case action(BattleAction)
    case tincture(Tincture)

    var iconURL: URL? { ... }
    var displayName: String { ... }
}
```

## Notes

- Read existing code first to understand current `RotationSlot`, `SkillCategory`, and filter logic before making changes
- "全部" tab should show both skills AND tinctures (tinctures at the bottom, separated)
- The `vitality` stat has no matching jobs in `tincture_stat_jobs` — skip showing vitality tinctures
