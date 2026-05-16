import express from 'express';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Server } from 'socket.io';
import {
  PLAYER_SHAPES,
  type Player,
  type PlayerInput,
  type PlayerKnockback,
  type PlayerProfile,
  type PlayerShape,
  type PlayerState,
  type ProjectileFire
} from '../shared/types';

const PORT = Number(process.env.PORT) || 3000;
const ROOM_WIDTH = 800;
const ROOM_HEIGHT = 600;
const PLAYER_SIZE = 24;
const PLAYER_SPEED = 180;
const SIMULATION_RATE_MS = 1000 / 60;
const STATE_BROADCAST_RATE_MS = 1000 / 30;
const MAX_PROJECTILE_OFFSET = PLAYER_SIZE * 2;
const MAX_KNOCKBACK_DISTANCE = 96;
const RIVER_LEFT = ROOM_WIDTH / 2 - 48;
const RIVER_WIDTH = 96;
const RIVER_RIGHT = RIVER_LEFT + RIVER_WIDTH;
const BRIDGE_HEIGHT = 64;
const BRIDGES = [
  { y: 96, height: BRIDGE_HEIGHT },
  { y: ROOM_HEIGHT / 2 - BRIDGE_HEIGHT / 2, height: BRIDGE_HEIGHT },
  { y: ROOM_HEIGHT - 96 - BRIDGE_HEIGHT, height: BRIDGE_HEIGHT }
];

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*'
  }
});

const players: PlayerState = {};
const playerInputs: Record<string, PlayerInput> = {};
const colors = ['#ef4444', '#f97316', '#eab308', '#22c55e', '#06b6d4', '#3b82f6', '#a855f7', '#ec4899'];
const shapes: readonly PlayerShape[] = PLAYER_SHAPES;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const clientDistPath = path.resolve(__dirname, '../../dist/client');

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

if (process.env.NODE_ENV === 'production') {
  app.use(express.static(clientDistPath));
  app.get('*', (_req, res) => {
    res.sendFile(path.join(clientDistPath, 'index.html'));
  });
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function resolvePlayerPosition(current: Pick<Player, 'x' | 'y'>, target: Pick<Player, 'x' | 'y'>): Pick<Player, 'x' | 'y'> {
  const requested = {
    x: clamp(target.x, PLAYER_SIZE / 2, ROOM_WIDTH - PLAYER_SIZE / 2),
    y: clamp(target.y, PLAYER_SIZE / 2, ROOM_HEIGHT - PLAYER_SIZE / 2)
  };

  const resolved = { x: current.x, y: current.y };
  if (canStandAt(requested.x, resolved.y)) {
    resolved.x = requested.x;
  }
  if (canStandAt(resolved.x, requested.y)) {
    resolved.y = requested.y;
  }

  return resolved;
}

function canStandAt(x: number, y: number): boolean {
  const halfSize = PLAYER_SIZE / 2;
  const overlapsRiver = x + halfSize > RIVER_LEFT && x - halfSize < RIVER_RIGHT;
  if (!overlapsRiver) {
    return true;
  }

  return BRIDGES.some((bridge) => y - halfSize >= bridge.y && y + halfSize <= bridge.y + bridge.height);
}

function normalizeProjectileFire(fire: ProjectileFire, player: Player): ProjectileFire | undefined {
  const direction = {
    x: Number.isFinite(fire.directionX) ? fire.directionX : 0,
    y: Number.isFinite(fire.directionY) ? fire.directionY : 0
  };
  const length = Math.hypot(direction.x, direction.y);

  if (length === 0) {
    return undefined;
  }

  return {
    x: clamp(
      Number.isFinite(fire.x) && Math.abs(fire.x - player.x) <= MAX_PROJECTILE_OFFSET ? fire.x : player.x,
      PLAYER_SIZE / 2,
      ROOM_WIDTH - PLAYER_SIZE / 2
    ),
    y: clamp(
      Number.isFinite(fire.y) && Math.abs(fire.y - player.y) <= MAX_PROJECTILE_OFFSET ? fire.y : player.y,
      PLAYER_SIZE / 2,
      ROOM_HEIGHT - PLAYER_SIZE / 2
    ),
    directionX: direction.x / length,
    directionY: direction.y / length
  };
}

function normalizePlayerInput(input: PlayerInput): PlayerInput {
  const directionX = Number.isFinite(input.directionX) ? clamp(input.directionX, -1, 1) : 0;
  const directionY = Number.isFinite(input.directionY) ? clamp(input.directionY, -1, 1) : 0;
  const length = Math.hypot(directionX, directionY);

  if (length === 0) {
    return { directionX: 0, directionY: 0 };
  }

  return {
    directionX: directionX / length,
    directionY: directionY / length
  };
}

function applyKnockback(player: Player, knockback: PlayerKnockback): void {
  const directionX = Number.isFinite(knockback.directionX) ? knockback.directionX : 0;
  const directionY = Number.isFinite(knockback.directionY) ? knockback.directionY : 0;
  const length = Math.hypot(directionX, directionY);

  if (length === 0) {
    return;
  }

  const distance = Number.isFinite(knockback.distance) ? clamp(knockback.distance, 0, MAX_KNOCKBACK_DISTANCE) : 0;
  const resolved = resolvePlayerPosition(player, {
    x: player.x + (directionX / length) * distance,
    y: player.y + (directionY / length) * distance
  });
  player.x = resolved.x;
  player.y = resolved.y;
}

function sanitizeProfile(auth: unknown, fallbackName: string, fallbackColor: string): PlayerProfile {
  const profile = auth && typeof auth === 'object' ? (auth as Partial<PlayerProfile>) : {};
  const rawName = typeof profile.name === 'string' ? profile.name.trim() : '';
  const rawColor = typeof profile.color === 'string' ? profile.color.trim() : '';
  const rawShape = typeof profile.shape === 'string' ? profile.shape : '';

  return {
    name: rawName.slice(0, 12) || fallbackName,
    color: /^#[0-9a-fA-F]{6}$/.test(rawColor) ? rawColor : fallbackColor,
    shape: shapes.includes(rawShape as PlayerShape) ? (rawShape as PlayerShape) : 'square'
  };
}

function createPlayer(id: string, profile: PlayerProfile): Player {
  const index = Object.keys(players).length;
  return {
    id,
    x: 120 + (index % 6) * 48,
    y: 120 + Math.floor(index / 6) * 48,
    color: profile.color,
    name: profile.name,
    shape: profile.shape
  };
}

io.on('connection', (socket) => {
  const index = Object.keys(players).length;
  const profile = sanitizeProfile(socket.handshake.auth, `P${index + 1}`, colors[index % colors.length]);
  const player = createPlayer(socket.id, profile);
  players[socket.id] = player;
  playerInputs[socket.id] = { directionX: 0, directionY: 0 };

  socket.emit('player:state', players);
  socket.broadcast.emit('player:join', player);

  socket.on('player:input', (input: PlayerInput) => {
    if (!players[socket.id]) {
      return;
    }

    playerInputs[socket.id] = normalizePlayerInput(input);
  });

  socket.on('player:knockback', (knockback: PlayerKnockback) => {
    const existingPlayer = players[socket.id];
    if (!existingPlayer) {
      return;
    }

    applyKnockback(existingPlayer, knockback);
  });

  socket.on('projectile:fire', (fire: ProjectileFire) => {
    const existingPlayer = players[socket.id];
    if (!existingPlayer) {
      return;
    }

    const projectileFire = normalizeProjectileFire(fire, existingPlayer);
    if (!projectileFire) {
      return;
    }

    io.emit('projectile:spawn', {
      ...projectileFire,
      id: `${socket.id}:${Date.now()}`,
      ownerId: socket.id,
      color: existingPlayer.color,
      createdAt: Date.now()
    });
  });

  socket.on('disconnect', () => {
    delete players[socket.id];
    delete playerInputs[socket.id];
    io.emit('player:left', socket.id);
  });
});

let lastSimulationTime = Date.now();
setInterval(() => {
  const now = Date.now();
  const deltaSeconds = (now - lastSimulationTime) / 1000;
  lastSimulationTime = now;

  for (const [id, player] of Object.entries(players)) {
    const input = playerInputs[id] ?? { directionX: 0, directionY: 0 };
    const resolved = resolvePlayerPosition(player, {
      x: player.x + input.directionX * PLAYER_SPEED * deltaSeconds,
      y: player.y + input.directionY * PLAYER_SPEED * deltaSeconds
    });
    player.x = resolved.x;
    player.y = resolved.y;
  }
}, SIMULATION_RATE_MS);

setInterval(() => {
  io.emit('player:state', players);
}, STATE_BROADCAST_RATE_MS);

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});
