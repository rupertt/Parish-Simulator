import express from 'express';
import { randomUUID } from 'node:crypto';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { WebSocketServer, type WebSocket } from 'ws';

const PORT = Number(process.env.PORT) || 3000;
const ROOM_WIDTH = 768;
const ROOM_HEIGHT = 432;
const PLAYER_SIZE = 16;
const PLAYER_SPEED = 92;
const SPAWN_SPACING_X = 72;
const SPAWN_SPACING_Y = 40;
const SIMULATION_RATE_MS = 1000 / 30;
const STATE_BROADCAST_RATE_MS = 1000 / 15;
const SHARED_ROOM = 'main';

type Direction = 'down' | 'up' | 'left' | 'right';
type CharacterId =
  | 'char_01'
  | 'char_02'
  | 'char_03'
  | 'char_04'
  | 'char_05'
  | 'char_06'
  | 'char_07'
  | 'char_08'
  | 'char_09'
  | 'char_10';

type Player = {
  id: string;
  room: string;
  name: string;
  characterId: CharacterId;
  x: number;
  y: number;
  color: string;
  facing: Direction;
  moving: boolean;
};

type PlayerInput = {
  x: number;
  y: number;
  facing?: Direction;
};

type ClientMessage =
  | { type: 'join'; name?: string; characterId?: string }
  | { type: 'input'; input?: Partial<PlayerInput> }
  | { type: 'ping'; sentAt?: number };

type ServerMessage =
  | { type: 'welcome'; id: string; room: string; players: Player[] }
  | { type: 'snapshot'; players: Player[]; serverTime: number }
  | { type: 'player_joined'; player: Player }
  | { type: 'player_left'; id: string }
  | { type: 'pong'; sentAt: number; serverTime: number }
  | { type: 'error'; message: string };

type ClientState = {
  socket: WebSocket;
  player: Player;
  input: PlayerInput;
};

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/ws' });
const clients = new Map<string, ClientState>();
const characters: Record<CharacterId, { color: string }> = {
  char_01: { color: '#d95f5f' },
  char_02: { color: '#e6a84f' },
  char_03: { color: '#d79c5f' },
  char_04: { color: '#df7aa8' },
  char_05: { color: '#5f8fd9' },
  char_06: { color: '#6d8bb8' },
  char_07: { color: '#c95757' },
  char_08: { color: '#8d6a4a' },
  char_09: { color: '#d6b94d' },
  char_10: { color: '#7b8f67' }
};

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const webExportPath = path.resolve(__dirname, '../../web-export');
const compressedAssetTypes: Record<string, string> = {
  '.js': 'application/javascript; charset=utf-8',
  '.pck': 'application/octet-stream',
  '.wasm': 'application/wasm'
};

app.get('/health', (_req, res) => {
  res.json({ ok: true, app: 'parish-simulator-godot-mvp' });
});

app.get('/config', (req, res) => {
  const protocol = req.headers['x-forwarded-proto'] ?? req.protocol;
  const wsProtocol = protocol === 'https' ? 'wss' : 'ws';
  const host = req.headers['x-forwarded-host'] ?? req.headers.host;
  const currentUrl = host ? `${protocol}://${host}` : '';
  const currentWebSocketUrl = host ? `${wsProtocol}://${host}/ws` : '';
  const appEnv = process.env.APP_ENV === 'testing' ? 'testing' : 'production';

  res.json({
    appEnv,
    webSocketUrl: currentWebSocketUrl,
    productionUrl: process.env.PRODUCTION_URL || (appEnv === 'production' ? currentUrl : ''),
    testingUrl: process.env.TESTING_URL || (appEnv === 'testing' ? currentUrl : '')
  });
});

if (process.env.NODE_ENV !== 'production') {
  app.get('/debug/rooms', (_req, res) => {
    const rooms = new Map<string, Player[]>();
    for (const client of clients.values()) {
      const roomPlayers = rooms.get(client.player.room) ?? [];
      roomPlayers.push(client.player);
      rooms.set(client.player.room, roomPlayers);
    }

    res.json({
      rooms: Object.fromEntries(rooms),
      totalPlayers: clients.size
    });
  });
}

app.get(['/index.js', '/index.pck', '/index.wasm'], (req, res, next) => {
  const extension = path.extname(req.path);
  const contentType = compressedAssetTypes[extension];
  const gzipPath = path.join(webExportPath, `${path.basename(req.path)}.gz`);

  if (!contentType || !req.acceptsEncodings('gzip')) {
    next();
    return;
  }

  res.setHeader('Content-Encoding', 'gzip');
  res.setHeader('Content-Type', contentType);
  res.setHeader('Vary', 'Accept-Encoding');
  res.sendFile(gzipPath, (error) => {
    if (error) {
      next();
    }
  });
});

app.use(express.static(webExportPath));
app.get('*', (_req, res) => {
  res.sendFile(path.join(webExportPath, 'index.html'), (error) => {
    if (error) {
      res
        .status(200)
        .type('html')
        .send(
          '<!doctype html><title>Parish Simulator</title><h1>Parish Simulator Godot MVP</h1><p>Run the Node server for WebSocket tests. Export the Godot Web build into <code>web-export/</code> to serve the browser game here.</p>'
        );
    }
  });
});

function sanitizeName(value: unknown, fallback: string): string {
  return typeof value === 'string' && value.trim() ? value.trim().slice(0, 18) : fallback;
}

function sanitizeCharacterId(value: unknown): CharacterId {
  return typeof value === 'string' && value in characters ? (value as CharacterId) : 'char_01';
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function normalizeInput(input: Partial<PlayerInput> | undefined): PlayerInput {
  const x = Number.isFinite(input?.x) ? clamp(Number(input?.x), -1, 1) : 0;
  const y = Number.isFinite(input?.y) ? clamp(Number(input?.y), -1, 1) : 0;
  const length = Math.hypot(x, y);
  const facing = input?.facing && ['down', 'up', 'left', 'right'].includes(input.facing) ? input.facing : 'down';

  if (length === 0) {
    return { x: 0, y: 0, facing };
  }

  return { x: x / length, y: y / length, facing };
}

function createPlayer(id: string, name: string, characterId: CharacterId): Player {
  const roomCount = [...clients.values()].filter((client) => client.player.room === SHARED_ROOM).length;
  return {
    id,
    room: SHARED_ROOM,
    name,
    characterId,
    x: 160 + (roomCount % 5) * SPAWN_SPACING_X,
    y: 216 + Math.floor(roomCount / 5) * SPAWN_SPACING_Y,
    color: characters[characterId].color,
    facing: 'down',
    moving: false
  };
}

function roomPlayers(room: string): Player[] {
  return [...clients.values()].filter((client) => client.player.room === room).map((client) => client.player);
}

function send(socket: WebSocket, message: ServerMessage): void {
  if (socket.readyState === socket.OPEN) {
    socket.send(JSON.stringify(message));
  }
}

function broadcast(room: string, message: ServerMessage, exceptId?: string): void {
  for (const [id, client] of clients) {
    if (id !== exceptId && client.player.room === room) {
      send(client.socket, message);
    }
  }
}

function readMessage(raw: Buffer): ClientMessage | undefined {
  try {
    const parsed = JSON.parse(raw.toString()) as ClientMessage;
    return typeof parsed.type === 'string' ? parsed : undefined;
  } catch {
    return undefined;
  }
}

wss.on('connection', (socket) => {
  const id = randomUUID();
  let joined = false;

  socket.on('message', (raw) => {
    const message = readMessage(raw as Buffer);
    if (!message) {
      send(socket, { type: 'error', message: 'Invalid JSON message.' });
      return;
    }

    if (message.type === 'join') {
      const player = createPlayer(
        id,
        sanitizeName(message.name, `Player ${clients.size + 1}`),
        sanitizeCharacterId(message.characterId)
      );
      clients.set(id, {
        socket,
        player,
        input: { x: 0, y: 0, facing: 'down' }
      });
      joined = true;
      send(socket, { type: 'welcome', id, room: SHARED_ROOM, players: roomPlayers(SHARED_ROOM) });
      broadcast(SHARED_ROOM, { type: 'player_joined', player }, id);
      return;
    }

    if (message.type === 'ping') {
      send(socket, { type: 'pong', sentAt: Number(message.sentAt) || Date.now(), serverTime: Date.now() });
      return;
    }

    const client = clients.get(id);
    if (!joined || !client) {
      send(socket, { type: 'error', message: 'Enter the world before sending gameplay messages.' });
      return;
    }

    if (message.type === 'input') {
      client.input = normalizeInput(message.input);
    }
  });

  socket.on('close', () => {
    const client = clients.get(id);
    clients.delete(id);
    if (client) {
      broadcast(client.player.room, { type: 'player_left', id });
    }
  });
});

let lastSimulationTime = Date.now();
setInterval(() => {
  const now = Date.now();
  const deltaSeconds = (now - lastSimulationTime) / 1000;
  lastSimulationTime = now;

  for (const client of clients.values()) {
    const { player, input } = client;
    player.facing = input.facing ?? player.facing;
    player.moving = input.x !== 0 || input.y !== 0;
    player.x = clamp(player.x + input.x * PLAYER_SPEED * deltaSeconds, PLAYER_SIZE, ROOM_WIDTH - PLAYER_SIZE);
    player.y = clamp(player.y + input.y * PLAYER_SPEED * deltaSeconds, PLAYER_SIZE, ROOM_HEIGHT - PLAYER_SIZE);
  }
}, SIMULATION_RATE_MS);

setInterval(() => {
  const rooms = new Set([...clients.values()].map((client) => client.player.room));
  for (const room of rooms) {
    broadcast(room, { type: 'snapshot', players: roomPlayers(room), serverTime: Date.now() });
  }
}, STATE_BROADCAST_RATE_MS);

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Parish Simulator WebSocket server listening on http://localhost:${PORT}`);
});
