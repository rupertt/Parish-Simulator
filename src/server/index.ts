import express from 'express';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Server } from 'socket.io';
import type { Player, PlayerMove, PlayerProfile, PlayerShape, PlayerState, ProjectileFire } from '../shared/types';

const PORT = Number(process.env.PORT) || 3000;
const ROOM_WIDTH = 800;
const ROOM_HEIGHT = 600;
const PLAYER_SIZE = 24;
const MAX_PROJECTILE_OFFSET = PLAYER_SIZE * 2;

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*'
  }
});

const players: PlayerState = {};
const colors = ['#ef4444', '#f97316', '#eab308', '#22c55e', '#06b6d4', '#3b82f6', '#a855f7', '#ec4899'];
const shapes: PlayerShape[] = ['square', 'circle', 'diamond', 'triangle'];

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

function clampMove(move: PlayerMove): PlayerMove {
  return {
    x: clamp(move.x, PLAYER_SIZE / 2, ROOM_WIDTH - PLAYER_SIZE / 2),
    y: clamp(move.y, PLAYER_SIZE / 2, ROOM_HEIGHT - PLAYER_SIZE / 2)
  };
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

  socket.emit('player:state', players);
  socket.broadcast.emit('player:join', player);

  socket.on('player:move', (move: PlayerMove) => {
    const existingPlayer = players[socket.id];
    if (!existingPlayer) {
      return;
    }

    const clampedMove = clampMove(move);
    existingPlayer.x = clampedMove.x;
    existingPlayer.y = clampedMove.y;
    io.emit('player:move', existingPlayer);
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
    io.emit('player:left', socket.id);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});
