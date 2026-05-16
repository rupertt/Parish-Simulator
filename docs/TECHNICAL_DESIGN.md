# Technical Design

## Stack

- TypeScript
- Phaser 3
- Node.js
- Express
- Socket.IO
- Vite

## Runtime Shape

The server owns the current player list and clamps player positions to the room boundaries. The client handles input and rendering, then sends movement updates to the server.

## Socket.IO Events

- `player:join`: server tells other clients that a new player joined.
- `player:move`: client sends movement position; server broadcasts the updated player.
- `player:state`: server sends the full current player state to a newly connected client.
- `player:left`: server tells clients to remove a disconnected player.

## Room Settings

- Width: `800`
- Height: `600`
- Player size: `24`
