# Parish Simulator

Godot 4.x MVP for a browser-first 2D pixel-art multiplayer prototype. The current goal is a small original cozy test meadow where players join one shared world, choose from 3 placeholder characters, move around, see each other, and interact with a few simple objects.

The project keeps the existing deployment shape:

- Run locally first.
- Push to the `testing` branch only when ready for testing.
- Push to `main` only when ready for production.

## Requirements

- Godot 4.2 or newer, using GDScript.
- Node.js 20+ and npm for the WebSocket backend.
- Git.

## Install

```bash
npm install
```

## Run Locally

Start the local WebSocket/static server:

```bash
npm run dev
```

Open the repo in Godot, press Play, enter a player name, choose a placeholder character, and enter the world.

The browser export automatically connects to the server hosting the page. In the Godot editor, the fallback server is:

```text
ws://localhost:3000/ws
```

Everyone connects to the same shared world for now. Room selection is intentionally deferred.

## Browser Export

In Godot:

1. Use the Compatibility renderer.
2. Add a Web export preset.
3. Export into `web-export/`, replacing the placeholder `index.html`.
4. Run `npm run start`.
5. Open `http://localhost:3000`.

## Project Structure

```text
res://
  scenes/
    main/
    ui/
    player/
    world/
    networking/
    interactables/
  scripts/
    player/
    world/
    networking/
    ui/
    interactables/
    autoload/
  assets/
    art/
    audio/
    fonts/
  resources/
  docs/
```

## Development Workflow

```bash
git checkout -b feature/local-mvp-change
npm run typecheck
git add .
git commit -m "Build Godot multiplayer MVP scaffold"
git push -u origin feature/local-mvp-change
```

Open a pull request before merging.

Recommended initial milestone commits:

- `Replace Phaser prototype with Godot MVP scaffold`
- `Add playable top-down movement and interactions`
- `Add WebSocket multiplayer backend`
- `Document web export and deployment workflow`

## Testing And Production Workflow

Local work happens on feature branches.

Testing deploy:

```bash
git checkout testing
git merge feature/local-mvp-change
git push origin testing
```

Production deploy:

```bash
git checkout main
git merge testing
git push origin main
```

Do not push to `testing` or `main` until explicitly deciding that stage is ready.

## Manual Test Checklist

- Game starts from main menu.
- Player can enter name.
- Player can select one of 3 placeholder characters.
- Player spawns into map.
- WASD movement works.
- Arrow movement works.
- Placeholder animation changes while walking.
- Directional facing changes up, down, left, right.
- Collision works against map boundaries and object blockers.
- Camera follows player.
- Interaction prompt appears near sign, table, and door.
- E key triggers each interaction.
- Multiple Godot clients or browser exports can connect to the same local world.
- Remote players appear.
- Remote movement updates.
- Disconnect removes player.
- F3 debug panel toggles.
- Web export launches from local Node server.

## Docs

- [MVP Plan](docs/MVP_PLAN.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Networking](docs/NETWORKING.md)
- [Art Pipeline](docs/ART_PIPELINE.md)
- [Web Export](docs/WEB_EXPORT.md)
- [Roadmap](docs/ROADMAP.md)
- [GCP Deployment](docs/DEPLOYMENT_GCP.md)
