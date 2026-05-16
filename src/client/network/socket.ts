import { io, Socket } from 'socket.io-client';
import type { Player, PlayerMove, PlayerProfile, PlayerState, Projectile, ProjectileFire } from '../../shared/types';

type ServerToClientEvents = {
  'player:join': (player: Player) => void;
  'player:move': (player: Player) => void;
  'player:state': (players: PlayerState) => void;
  'player:left': (id: string) => void;
  'projectile:spawn': (projectile: Projectile) => void;
};

type ClientToServerEvents = {
  'player:move': (move: PlayerMove) => void;
  'projectile:fire': (projectile: ProjectileFire) => void;
};

export type GameSocket = Socket<ServerToClientEvents, ClientToServerEvents>;

let socket: GameSocket | undefined;

function getServerUrl(): string {
  const configuredUrl = import.meta.env.VITE_SOCKET_URL as string | undefined;
  if (configuredUrl) {
    return configuredUrl;
  }

  return window.location.origin;
}

export function configureSocket(profile: PlayerProfile): GameSocket {
  socket = io(getServerUrl(), {
    auth: profile,
    autoConnect: false,
    transports: ['websocket']
  });

  return socket;
}

export function getSocket(): GameSocket {
  if (!socket) {
    throw new Error('Socket has not been configured yet.');
  }

  return socket;
}
