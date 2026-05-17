import express from 'express';
import { randomUUID } from 'node:crypto';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { WebSocketServer, type WebSocket } from 'ws';

const PORT = Number(process.env.PORT) || 3000;
const ROOM_WIDTH = 1254;
const ROOM_HEIGHT = 1254;
const PLAYER_SIZE = 16;
const PLAYER_SPEED = 92;
const SPAWN_SPACING_X = 72;
const SPAWN_SPACING_Y = 56;
const SIMULATION_RATE_MS = 1000 / 30;
const STATE_BROADCAST_RATE_MS = 1000 / 15;
const SHARED_ROOM = 'main';
const MAP_BLOCKERS: Rect[] = [
  { x: 252, y: 86, width: 150, height: 133 },
  { x: 468, y: 35, width: 186, height: 160 },
  { x: 718, y: 97, width: 126, height: 142 },
  { x: 976, y: 96, width: 158, height: 140 },
  { x: 210, y: 330, width: 164, height: 124 },
  { x: 915, y: 294, width: 222, height: 166 },
  { x: 50, y: 560, width: 156, height: 150 },
  { x: 260, y: 552, width: 126, height: 126 },
  { x: 552, y: 306, width: 168, height: 304 },
  { x: 924, y: 512, width: 188, height: 170 },
  { x: 282, y: 775, width: 178, height: 160 },
  { x: 792, y: 772, width: 158, height: 148 },
  { x: 1020, y: 773, width: 160, height: 152 },
  { x: 1000, y: 985, width: 178, height: 168 },
  { x: 0, y: 0, width: 70, height: 110 },
  { x: 128, y: 62, width: 70, height: 100 },
  { x: 216, y: 12, width: 64, height: 100 },
  { x: 310, y: 0, width: 70, height: 100 },
  { x: 662, y: 0, width: 72, height: 110 },
  { x: 958, y: 0, width: 78, height: 112 },
  { x: 1052, y: 20, width: 74, height: 112 },
  { x: 1140, y: 60, width: 72, height: 108 },
  { x: 0, y: 190, width: 78, height: 118 },
  { x: 1200, y: 175, width: 54, height: 112 },
  { x: 456, y: 330, width: 64, height: 118 },
  { x: 748, y: 336, width: 62, height: 112 },
  { x: 810, y: 318, width: 72, height: 120 },
  { x: 1180, y: 326, width: 74, height: 110 },
  { x: 0, y: 468, width: 82, height: 108 },
  { x: 1188, y: 535, width: 66, height: 112 },
  { x: 1185, y: 745, width: 69, height: 120 },
  { x: 10, y: 770, width: 68, height: 112 },
  { x: 92, y: 784, width: 66, height: 106 },
  { x: 154, y: 780, width: 62, height: 110 },
  { x: 790, y: 640, width: 62, height: 110 },
  { x: 970, y: 980, width: 70, height: 112 },
  { x: 396, y: 1010, width: 68, height: 105 },
  { x: 502, y: 1000, width: 72, height: 118 },
  { x: 650, y: 1080, width: 70, height: 118 },
  { x: 870, y: 1090, width: 70, height: 118 },
  { x: 1180, y: 1042, width: 74, height: 110 },
  { x: 20, y: 323, width: 150, height: 20 },
  { x: 20, y: 450, width: 150, height: 20 },
  { x: 20, y: 323, width: 18, height: 148 },
  { x: 154, y: 323, width: 18, height: 148 },
  { x: 198, y: 128, width: 55, height: 20 },
  { x: 198, y: 145, width: 18, height: 138 },
  { x: 244, y: 262, width: 39, height: 20 },
  { x: 348, y: 262, width: 100, height: 20 },
  { x: 406, y: 128, width: 44, height: 20 },
  { x: 430, y: 140, width: 20, height: 122 },
  { x: 462, y: 191, width: 86, height: 20 },
  { x: 688, y: 126, width: 18, height: 160 },
  { x: 838, y: 128, width: 18, height: 160 },
  { x: 820, y: 262, width: 50, height: 28 },
  { x: 930, y: 128, width: 18, height: 152 },
  { x: 1130, y: 128, width: 18, height: 152 },
  { x: 948, y: 263, width: 50, height: 20 },
  { x: 1085, y: 263, width: 54, height: 20 },
  { x: 435, y: 480, width: 22, height: 142 },
  { x: 538, y: 572, width: 88, height: 42 },
  { x: 650, y: 596, width: 74, height: 28 },
  { x: 800, y: 480, width: 26, height: 160 },
  { x: 280, y: 692, width: 96, height: 22 },
  { x: 50, y: 586, width: 18, height: 128 },
  { x: 204, y: 586, width: 18, height: 128 },
  { x: 258, y: 692, width: 130, height: 22 },
  { x: 520, y: 665, width: 42, height: 26 },
  { x: 650, y: 665, width: 82, height: 32 },
  { x: 520, y: 820, width: 210, height: 90 },
  { x: 778, y: 790, width: 18, height: 132 },
  { x: 946, y: 790, width: 18, height: 132 },
  { x: 796, y: 912, width: 150, height: 20 },
  { x: 1000, y: 792, width: 18, height: 134 },
  { x: 1178, y: 792, width: 18, height: 134 },
  { x: 1020, y: 914, width: 160, height: 20 },
  { x: 688, y: 1002, width: 212, height: 24 },
  { x: 688, y: 1000, width: 18, height: 196 },
  { x: 898, y: 1000, width: 18, height: 196 },
  { x: 760, y: 1130, width: 70, height: 46 },
  { x: 960, y: 1032, width: 42, height: 180 },
  { x: 1176, y: 1032, width: 18, height: 180 },
  { x: 1000, y: 1160, width: 176, height: 20 },
  { x: 0, y: 922, width: 270, height: 64 },
  { x: 0, y: 978, width: 220, height: 276 },
  { x: 206, y: 1048, width: 70, height: 160 }
];

type Direction = 'down' | 'up' | 'left' | 'right';
type Rect = {
  x: number;
  y: number;
  width: number;
  height: number;
};
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

app.use((_req, res, next) => {
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
  res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
  res.setHeader('Cross-Origin-Resource-Policy', 'same-origin');
  next();
});

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

function isBlockedPosition(x: number, y: number): boolean {
  const radius = PLAYER_SIZE / 2;
  return MAP_BLOCKERS.some(
    (rect) =>
      x >= rect.x - radius &&
      x <= rect.x + rect.width + radius &&
      y >= rect.y - radius &&
      y <= rect.y + rect.height + radius
  );
}

function moveWithCollision(player: Player, input: PlayerInput, deltaSeconds: number): void {
  const nextX = clamp(player.x + input.x * PLAYER_SPEED * deltaSeconds, PLAYER_SIZE, ROOM_WIDTH - PLAYER_SIZE);
  if (!isBlockedPosition(nextX, player.y)) {
    player.x = nextX;
  }

  const nextY = clamp(player.y + input.y * PLAYER_SPEED * deltaSeconds, PLAYER_SIZE, ROOM_HEIGHT - PLAYER_SIZE);
  if (!isBlockedPosition(player.x, nextY)) {
    player.y = nextY;
  }
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
    x: 650 + (roomCount % 5) * SPAWN_SPACING_X,
    y: 635 + Math.floor(roomCount / 5) * SPAWN_SPACING_Y,
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
    moveWithCollision(player, input, deltaSeconds);
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
