# MVP Plan

## Goal

Build a browser-first Godot MVP for an original cozy multiplayer top-down game. The MVP is intentionally small: one shared test meadow, player movement, collisions, three interactable objects, and simple WebSocket multiplayer.

## Implemented Now

- Godot 4.x project scaffold with Compatibility renderer settings.
- Main menu with player name and 3 placeholder character choices.
- Single playable test meadow.
- Local top-down 4-direction movement with WASD and arrow keys.
- Pixel-friendly placeholder player visuals and walking bob animation.
- Collision against map boundaries and object blockers.
- Three interactables: sign, table, and door marker.
- Minimal HUD with player name, connection status, prompt, message popup, and F3 debug panel.
- Node/Express raw WebSocket server for local and Cloud Run hosting.
- Documentation for local, testing, production, networking, and web export.

## Deferred

- Farming, inventory, quests, combat, crafting, shops, seasons, NPC schedules, persistence, accounts, and anti-cheat.
- Server-authoritative collision parity for every interactable object.
- Real tile art, animation spritesheets, audio, and polished UI.
- Steam or desktop-native packaging.

## Milestones

1. Project scaffold and documentation.
2. Playable local Godot scene.
3. Basic interaction loop.
4. WebSocket multiplayer prototype.
5. Web export documentation.
6. Local validation and deployment gate documentation.

## Known Risks

- Godot web export requires browser-compatible settings and may have audio/fullscreen restrictions.
- Cloud Run WebSocket sessions are subject to request timeouts and reconnect behavior.
- In-memory world state works for one Cloud Run instance only.
- The current server accepts client input without anti-cheat, suitable for MVP only.
