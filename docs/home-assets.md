# Home Assets

Home artwork is optional during development. If an asset is missing from `EorzeaToolkit/Resources/Assets.xcassets`, the Home screen falls back to the existing SwiftUI placeholder artwork.

## Asset Names

Add future local images to `Assets.xcassets` using these exact imageset names:

| Surface | Imageset name | Recommended ratio |
| --- | --- | --- |
| Hero banner | `home_hero_banner` | `3:1` |
| Item search card | `home_item_search` | `2:3` |
| Treasure map card | `home_treasure_map` | `2:3` |
| Relic weapon card | `home_relic_weapon` | `2:3` |
| Mini Cactpot card | `home_mini_cactpot` | `2:3` |
| Skill rotation card | `home_skill_rotation` | `2:3` |

The same names are defined in `HomeArtworkAsset` so the UI can automatically switch from placeholder artwork to local assets.

## Layout Expectations

- Images are rendered with `scaledToFill`, so edges may be cropped.
- Keep important subject matter near the center of each image.
- Feature card images are displayed in a narrow portrait frame, currently matching the `2:3` ratio.
- The hero banner is a short landscape crop, currently matching the `3:1` ratio.

## Replacement Workflow

1. Create an imageset in `Assets.xcassets` with the exact name from the table.
2. Add the image renditions to that imageset.
3. Run the app and verify Home still looks correct on the iPhone simulator.
4. Keep generated drafts or prompt notes out of the public repo unless they are intentionally ready to publish.
