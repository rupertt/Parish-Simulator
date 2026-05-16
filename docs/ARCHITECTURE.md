# Architecture

## Runtime Shape

Godot is the game client. The Node server hosts the exported web files and provides the WebSocket server for one shared world.

```text
Godot editor or web export
  -> WebSocketPeer
  -> Node Express/ws server
  -> shared-world snapshots
  -> all connected clients
```

## Godot Scenes

- `scenes/main/Main.tscn`: boot scene and scene switcher.
- `scenes/ui/MainMenu.tscn`: start/join screen.
- `scenes/ui/HUD.tscn`: name, status, prompt, message, debug panel.
- `scenes/world/TestMeadow.tscn`: one small tile-style test map.
- `scenes/player/LocalPlayer.tscn`: local movement and collision.
- `scenes/player/RemotePlayer.tscn`: remote player display.
- `scenes/interactables/Interactable.tscn`: reusable interaction trigger.

## Autoloads

- `GameState`: session fields and connection status.
- `NetworkManager`: WebSocket connection and JSON message handling.
- `PlayerRegistry`: current known player state.
- `SceneLoader`: small scene-change helper.
- `SettingsManager`: runtime input action setup.

These are intentionally minimal. Feature systems should be scene-owned until they prove they need global access.

## Layers

- Ground layer: drawn tile-style meadow placeholder.
- Object layer: wall/object collision bodies.
- Interactables: sign, table, door trigger areas.
- Remote players: other connected users.
- Local player: local controlled character.
- Above-player layer: reserved for canopy/roof objects.
- HUD: CanvasLayer.

## Deployment Infra

The existing Docker and Cloud Build path stays in place. The Node server runs locally, in testing, and in production. The Godot web export is committed into `web-export/` before branch deploys.
