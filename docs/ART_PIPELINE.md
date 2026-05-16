# Art Pipeline

The MVP uses original placeholder pixel shapes. Do not copy Stardew Valley art, maps, characters, UI, music, story, or systems.

## Current Placeholder Rules

- Small, readable silhouettes.
- Low color count.
- Nearest-neighbor filtering.
- Pixel snap enabled.
- Keep source files small for browser export.

## Future Asset Rules

- Store character sprites in `assets/art/characters/`.
- Store tilesets in `assets/art/tilesets/`.
- Store object sprites in `assets/art/objects/`.
- Store UI art in `assets/art/ui/`.
- Export sprites as PNG, not oversized layered source files.
- Keep source art files outside web builds unless needed.

## Directional Character Plan

Each playable character should eventually have:

- Idle down/up/left/right.
- Walk down/up/left/right.
- Consistent origin around the feet.
- Collision shape separate from visible sprite.

## Audio

Browser audio often requires user interaction before playback. Keep initial music/sfx optional and small.
