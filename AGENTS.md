# Codex Operating Rules

These instructions apply to this repository.

## Product Direction

- This is a Godot 4.x, GDScript-only, browser-first multiplayer MVP.
- Keep the game original. Do not copy Stardew Valley art, maps, characters, UI, music, story, or systems.
- The current MVP is one shared world served by the active backend. Do not add room selection unless explicitly requested.
- Keep character selection simple. Placeholder characters are acceptable until an original art pass is requested.
- Do not add farming, inventory, quests, combat, shops, seasons, NPC schedules, persistence, accounts, or anti-cheat unless explicitly requested.

## Deployment Gates

- Local first: every new change should be made and validated locally.
- Do not push anything to `main`.
- Local changes may be built, tested, and run locally without asking.
- Do not deploy to Cloud Run, production, or any hosted environment unless explicitly requested.
- Treat generated export files as local artifacts unless the user asks for deployment.
- Testing next: only push to `testing` when the user explicitly asks to push to testing.
- Production last: never deploy or release to production unless the user explicitly asks for production release work.
- Do not merge `testing` into `main` without explicit user approval.

## Required Validation

Before committing or pushing gameplay/backend changes, run:

```bash
npm run typecheck
```

If the portable Godot tool exists, also run:

```bash
.\.tools\godot-4.6.2\Godot_v4.6.2-stable_win64_console.exe --headless --path . --quit-after 2
```

For browser-facing Godot changes, regenerate the Web export:

```bash
.\.tools\godot-4.6.2\Godot_v4.6.2-stable_win64_console.exe --headless --path . --export-release Web web-export\index.html
```

Then regenerate compressed web assets:

```bash
node -e "const fs=require('node:fs');const zlib=require('node:zlib');for(const name of ['index.js','index.pck','index.wasm']){const input=`web-export/${name}`;fs.writeFileSync(`${input}.gz`,zlib.gzipSync(fs.readFileSync(input),{level:9}));}"
```

The `.gz` files are required for Cloud Run because the Godot `.wasm` file is too large to serve uncompressed reliably.

## Architecture Rules

- Godot client files live under `scenes/`, `scripts/`, `assets/`, and `resources/`.
- The Node backend lives in `src/server/index.ts`.
- The browser-deployed Godot build lives in `web-export/`.
- Browser exports should infer the WebSocket endpoint from the page host and use `/ws`.
- Editor/local fallback should remain `ws://localhost:3000/ws`.
- Use raw WebSockets. Do not reintroduce Socket.IO unless the Godot client is deliberately changed to support it.
- Keep Cloud Run `max-instances=1` while world state is in memory.

## Git Rules

- Preserve user changes. Do not reset, checkout, or discard unrelated work.
- Commit only when requested or when pushing is requested.
- Default working branch should be `testing` or a feature branch, never `main`.
- If currently on `main`, create or switch to a non-`main` branch before making changes.
- Keep all new work local by default; do not push unless the user explicitly requests a push.
- `main` is protected production history.
- Keep `main` untouched unless the user explicitly requests production release work.
- Never push directly to `main`.
- Do not merge, rebase, or fast-forward `main` unless the user explicitly requests production release work.
- Before any push, state the branch, remote, and exact command that will be run.
- Push only the named branch the user requested.
- Never use `git push --all` or `git push --mirror`.
- If pushing to testing, confirm the current branch is `testing`, commit there, and push only `origin testing`.

## Documentation Rules

- Keep `README.md` and docs in `docs/` aligned with the actual gameplay flow.
- If menus, networking, deployment, or export behavior changes, update the relevant docs in the same change.
- Do not leave references to obsolete Phaser/Vite gameplay, Socket.IO, room-code selection, or old web routes unless documenting migration history.

## Art Asset Instructions

When new art is added to the project, it must be organized, tracked, and tested before the task is considered complete.

All game-ready art assets should be kept inside:

```text
res://assets/art/
```

Use these folders:

```text
res://assets/art/characters/
res://assets/art/tilesets/
res://assets/art/objects/
res://assets/art/ui/
res://assets/art/portraits/
res://assets/art/vfx/
```

Source files should be kept separately when possible:

```text
art-source/
```

Examples of source files include:

```text
.aseprite
.psd
.kra
.svg
```

Exported files used by Godot should usually be:

```text
.png
```

Every new art asset must follow these rules:

1. Put the file in the correct folder.
2. Use lowercase snake_case filenames.
3. Keep source files when available.
4. Export game-ready files into the Godot asset folders.
5. Update `docs/ASSET_REGISTER.md`.
6. Mark the asset status as `placeholder`, `draft`, or `final`.
7. Confirm the asset is original or properly licensed.
8. Test that the asset appears crisp and correctly scaled in Godot.

Good filename examples:

```text
player_walk_down.png
player_idle_up.png
cozy_room_tileset.png
object_chest_closed.png
ui_dialogue_box.png
interaction_icon.png
```

No art task is complete until the asset is placed correctly, named correctly, tested in Godot, and recorded in `docs/ASSET_REGISTER.md`.
