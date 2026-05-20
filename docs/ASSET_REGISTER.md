# Asset Register

Track all game-ready art assets added under `res://assets/art/`.

| Asset | Path | Status | Source | License/Originality | Godot Test Notes |
| --- | --- | --- | --- | --- | --- |
| Project icon | `res://assets/art/ui/icon.svg` | placeholder | Created in repo | Original placeholder | Loads as project icon |
| Text panel | `res://assets/art/ui/text_panel.png` | placeholder | User-provided `panel.png`; original preserved at `art-source/text_panel_original.png` | User-provided; originality/license pending explicit confirmation | Checkerboard background removed for transparent UI use; used by HUD prompt and message panels with nearest filtering |
| Character screen background | `res://assets/art/ui/character_screen_background.png` | placeholder | User-provided `background_image.png` | User-provided; originality/license pending explicit confirmation | Used as the parchment background on `CharacterScreen.tscn`; tested with nearest filtering in Godot web export |
| Old priest character sheet | `res://assets/art/animations/old_priest_bible_walk_sheet.png` | placeholder | User-provided `an_old_priest_with_a.zip`; source export preserved under `art-source/old_priest_bible/` | User-provided; originality/license pending explicit confirmation | Converted from 8 directional `120x120` rotation frames into the Godot `8x4` walk sheet format; used by selectable character `char_14` |
| Old priest character icon | `res://assets/art/animations/icons/old_priest_bible.png` | placeholder | Derived from user-provided `an_old_priest_with_a.zip`; source export preserved under `art-source/old_priest_bible/` | User-provided; originality/license pending explicit confirmation | Built from the cleaned south-facing source frame and used by the main menu character selector |
| Old priest animated walk sheet | `res://assets/art/animations/old_priest_animated_walk_sheet.png` | placeholder | User-provided `priest2.zip`; source export preserved under `art-source/old_priest_animated/` | User-provided; originality/license pending explicit confirmation | Converted from directional animation frames into Godot `8x4` walk sheet format; used by selectable character `char_15` |
| Old priest animated icon | `res://assets/art/animations/icons/old_priest_animated.png` | placeholder | Derived from user-provided `priest2.zip`; source export preserved under `art-source/old_priest_animated/` | User-provided; originality/license pending explicit confirmation | Built from cleaned south-facing frame and used in character selector for `char_15` |
| Parish church prop | `res://assets/art/objects/parish_church.png` | placeholder | User-provided `churches.png` copied from project root | User-provided; originality/license pending explicit confirmation | Used by `res://scenes/props/parish_church_prop.tscn`; nearest filtering, lower-body collision, door interaction area |
| Gothic cathedral prop | `res://assets/art/objects/gothic_cathedral.png` | placeholder | User-provided `churches2.png` copied from project root | User-provided; originality/license pending explicit confirmation | Used by `res://scenes/props/gothic_cathedral_prop.tscn`; nearest filtering, lower-body collision, door interaction area |
| Big cathedral prop | `res://assets/art/objects/big_cathedral.png` | placeholder | User-provided `bigcathedral.png` copied from project root | User-provided; originality/license pending explicit confirmation | Used by `res://scenes/props/big_cathedral_prop.tscn`; background removed, nearest filtering, scale `1`, lower-body collision, door interaction area |
| Pixel house | `res://assets/props/house_pixel.png` | placeholder | Created in repo from replacement pixel-art texture because provided base64 payload was invalid | Original placeholder | Used by `res://scenes/props/pixel_house.tscn`; sprite uses nearest filtering |
| Exact house prop | `res://assets/props/house_exact.png` | placeholder | User-provided `house1.png` copied from project root | User-provided; originality/license pending explicit confirmation | Used by `res://scenes/props/house_prop.tscn`; sprite uses nearest filtering and `0.35` scale |
| Church entrance room | `res://assets/art/tilesets/church_entrance_room.png` | draft | User-provided `ChatGPT Image May 16, 2026, 05_59_22 PM.png` | User-provided generated image; originality/license pending explicit confirmation | Used as the first church interior room background in `ChurchEntrance.tscn` |
| Church sanctuary room | `res://assets/art/tilesets/church_sanctuary_room.png` | draft | User-provided `ChatGPT Image May 16, 2026, 06_22_27 PM.png` | User-provided generated image; originality/license pending explicit confirmation | Used as the sanctuary background in `ChurchSanctuary.tscn` |

## Font Assets

| Asset | Path | Status | Source | License/Originality | Godot Test Notes |
| --- | --- | --- | --- | --- | --- |
| Pixelify Sans | `res://assets/fonts/pixelify_sans.ttf` | final | Google Fonts / google/fonts | SIL Open Font License 1.1; license stored at `res://assets/fonts/pixelify_sans_ofl.txt` | Used by HUD prompt and message labels |
