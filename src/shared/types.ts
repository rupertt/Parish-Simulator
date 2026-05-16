export const PLAYER_SHAPES = [
  'square',
  'circle',
  'diamond',
  'triangle',
  'henry',
  'dad',
  'alex',
  'max',
  'julius',
  'rupert'
] as const;

export type PlayerShape = (typeof PLAYER_SHAPES)[number];

export type Player = {
  id: string;
  x: number;
  y: number;
  color: string;
  name: string;
  shape: PlayerShape;
};

export type PlayerProfile = {
  name: string;
  color: string;
  shape: PlayerShape;
};

export type PlayerInput = {
  directionX: number;
  directionY: number;
};

export type PlayerKnockback = {
  directionX: number;
  directionY: number;
  distance: number;
};

export type ProjectileFire = {
  x: number;
  y: number;
  directionX: number;
  directionY: number;
};

export type Projectile = ProjectileFire & {
  id: string;
  ownerId: string;
  color: string;
  createdAt: number;
};

export type PlayerState = Record<string, Player>;
