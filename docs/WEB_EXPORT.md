# Web Export

## Why GDScript

The browser target requires Godot's web export path. GDScript is the safest choice for this MVP because C# web export support is more constrained and native extensions/plugins are not appropriate for browser-first builds.

## Required Settings

- Renderer: Compatibility.
- Texture filtering: nearest.
- Pixel snap: enabled.
- Avoid native plugins, GDExtension, and C#.
- Keep assets small.
- Test audio after a user click.

## Export Steps

1. Open the project in Godot 4.2+.
2. Install the matching export templates if Godot asks.
3. Create a Web export preset.
4. Export into:

```text
web-export/
```

5. Start the local Node server:

```bash
npm run start
```

6. Open:

```text
http://localhost:3000
```

## Generated Files

Godot web export usually generates files such as:

- `index.html`
- `.wasm`
- `.pck`
- `.js`
- optional side files depending on export settings

These files should replace the placeholder in `web-export/` before pushing to testing or production.

## Common Issues

- Browser cache can keep older `.pck` or `.wasm` files. Hard refresh or clear site data.
- Audio may not start until after a click or keypress.
- Fullscreen requires user interaction.
- HTTPS pages must use `wss://` WebSocket URLs.
- Cloud Run WebSockets can reconnect after platform timeouts.

## Future Desktop Builds

Desktop/native builds can reuse the same GDScript scenes. Add platform-specific export presets later and keep web-incompatible features behind explicit platform checks.
