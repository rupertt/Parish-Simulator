import express from 'express';
import { randomUUID } from 'node:crypto';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { WebSocketServer, type WebSocket } from 'ws';

const PORT = Number(process.env.PORT) || 3000;
const ROOM_WIDTH = 1600;
const ROOM_HEIGHT = 1400;
const PLAYER_SIZE = 16;
const PLAYER_SPEED = 92;
const SPAWN_SPACING_X = 72;
const SPAWN_SPACING_Y = 56;
const SIMULATION_RATE_MS = 1000 / 30;
const STATE_BROADCAST_RATE_MS = 1000 / 15;
const SHARED_ROOM = 'main';
const MAP_COLLISION_SHAPES: MapCollisionShape[] = [];

type Direction = 'down' | 'up' | 'left' | 'right' | 'up_left' | 'up_right' | 'down_left' | 'down_right';
type Point = {
  x: number;
  y: number;
};
type MapCollisionShape =
  | { kind: 'footprint'; position: Point; size: Point }
  | { kind: 'polygon'; points: Point[] }
  | { kind: 'circle'; position: Point; radius: number }
  | { kind: 'capsule'; from: Point; to: Point; radius: number };
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
  | 'char_10'
  | 'char_11'
  | 'char_12'
  | 'char_13';

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
  char_10: { color: '#7b8f67' },
  char_11: { color: '#5f7fd9' },
  char_12: { color: '#b7b7c4' },
  char_13: { color: '#7b6154' }
};

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const webExportPath = path.resolve(__dirname, '../../web-export');
const compressedAssetTypes: Record<string, string> = {
  '.js': 'application/javascript; charset=utf-8',
  '.wasm': 'application/wasm'
};
const noCacheHeaders: Record<string, string> = {
  'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
  Pragma: 'no-cache',
  Expires: '0',
  'Surrogate-Control': 'no-store'
};

function applyNoCacheHeaders(res: express.Response): void {
  if (res.headersSent) {
    return;
  }
  for (const [key, value] of Object.entries(noCacheHeaders)) {
    res.setHeader(key, value);
  }
}

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

app.get(['/index.js', '/index.wasm'], (req, res, next) => {
  const extension = path.extname(req.path);
  const contentType = compressedAssetTypes[extension];
  const gzipPath = path.join(webExportPath, `${path.basename(req.path)}.gz`);

  if (!contentType || !req.acceptsEncodings('gzip')) {
    next();
    return;
  }

  applyNoCacheHeaders(res);
  res.setHeader('Content-Encoding', 'gzip');
  res.setHeader('Content-Type', contentType);
  res.setHeader('Vary', 'Accept-Encoding');
  res.sendFile(gzipPath, (error) => {
    if (error) {
      next();
    }
  });
});

app.use((req, res, next) => {
  if (req.method === 'GET' || req.method === 'HEAD') {
    applyNoCacheHeaders(res);
  }
  next();
});

app.use(express.static(webExportPath, { etag: false, lastModified: false }));
app.get('*', (_req, res) => {
  applyNoCacheHeaders(res);
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

function distanceSquared(a: Point, b: Point): number {
  return (a.x - b.x) ** 2 + (a.y - b.y) ** 2;
}

function distanceToSegmentSquared(point: Point, start: Point, end: Point): number {
  const dx = end.x - start.x;
  const dy = end.y - start.y;
  const lengthSquared = dx * dx + dy * dy;

  if (lengthSquared === 0) {
    return distanceSquared(point, start);
  }

  const t = clamp(((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared, 0, 1);
  const closest = { x: start.x + dx * t, y: start.y + dy * t };
  return distanceSquared(point, closest);
}

function isPointInsidePolygon(point: Point, polygon: Point[]): boolean {
  let inside = false;

  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const current = polygon[i];
    const previous = polygon[j];
    const crossesY = current.y > point.y !== previous.y > point.y;

    if (crossesY) {
      const crossingX = ((previous.x - current.x) * (point.y - current.y)) / (previous.y - current.y) + current.x;
      if (point.x < crossingX) {
        inside = !inside;
      }
    }
  }

  return inside;
}

function collidesWithPolygon(point: Point, radius: number, polygon: Point[]): boolean {
  if (isPointInsidePolygon(point, polygon)) {
    return true;
  }

  const radiusSquared = radius * radius;
  return polygon.some((start, index) => {
    const end = polygon[(index + 1) % polygon.length];
    return distanceToSegmentSquared(point, start, end) <= radiusSquared;
  });
}

function footprintToPolygon(position: Point, size: Point): Point[] {
  const halfWidth = size.x / 2;
  const halfHeight = size.y / 2;
  const bevel = Math.min(18, size.x * 0.18);

  return [
    { x: position.x - halfWidth + bevel, y: position.y - halfHeight },
    { x: position.x + halfWidth - bevel, y: position.y - halfHeight },
    { x: position.x + halfWidth, y: position.y - halfHeight + bevel },
    { x: position.x + halfWidth, y: position.y + halfHeight },
    { x: position.x - halfWidth, y: position.y + halfHeight },
    { x: position.x - halfWidth, y: position.y - halfHeight + bevel }
  ];
}

function collidesWithShape(point: Point, radius: number, shape: MapCollisionShape): boolean {
  if (shape.kind === 'footprint') {
    return collidesWithPolygon(point, radius, footprintToPolygon(shape.position, shape.size));
  }

  if (shape.kind === 'circle') {
    const combinedRadius = radius + shape.radius;
    return distanceSquared(point, shape.position) <= combinedRadius * combinedRadius;
  }

  if (shape.kind === 'capsule') {
    const combinedRadius = radius + shape.radius;
    return distanceToSegmentSquared(point, shape.from, shape.to) <= combinedRadius * combinedRadius;
  }

  return collidesWithPolygon(point, radius, shape.points);
}

function isBlockedPosition(x: number, y: number): boolean {
  const radius = PLAYER_SIZE / 2;
  return MAP_COLLISION_SHAPES.some((shape) => collidesWithShape({ x, y }, radius, shape));
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
  const facing =
    input?.facing && ['down', 'up', 'left', 'right', 'up_left', 'up_right', 'down_left', 'down_right'].includes(input.facing)
      ? input.facing
      : 'down';

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
    x: 800 + (roomCount % 5) * SPAWN_SPACING_X,
    y: 650 + Math.floor(roomCount / 5) * SPAWN_SPACING_Y,
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
