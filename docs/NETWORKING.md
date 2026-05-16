# Networking

## Choice

The MVP uses raw WebSocket rather than WebRTC or Socket.IO.

Godot 4 provides `WebSocketPeer`, which works in browser export and desktop builds. It speaks normal WebSocket, not the Socket.IO protocol, so the Node backend uses the `ws` package.

## Current Protocol

Client to server:

- `join`: `{ "type": "join", "name": "Rupert", "characterId": "char_01" }`
- `input`: `{ "type": "input", "input": { "x": 1, "y": 0, "facing": "right" } }`
- `ping`: `{ "type": "ping", "sentAt": 12345 }`

Server to client:

- `welcome`: assigns client id and sends current shared-world players.
- `snapshot`: sends player positions for the shared world.
- `player_joined`: announces a new player.
- `player_left`: removes a disconnected player.
- `pong`: supports latency display.
- `error`: reports protocol errors.

## Authority Model

This is a simple prototype. The server accepts directional input, simulates basic bounded movement, and broadcasts snapshots. The local Godot client also moves immediately for responsiveness.

Later, movement should become more server-authoritative:

- Match collision rules on server and client.
- Include sequence numbers for input reconciliation.
- Reject impossible positions and rates.
- Add reconnect/resync logic.
- Add authentication and world/instance permissions if public servers are used.

## Local Testing

Run:

```bash
npm run dev
```

Use this fallback server URL in the Godot editor:

```text
ws://localhost:3000/ws
```

Multiple local clients join the same shared world. Browser exports infer the WebSocket URL from the page host.

## Browser Notes

Use `wss://` when the game is served over HTTPS. The `/config` endpoint exposes the environment's WebSocket URL for future auto-fill behavior.
