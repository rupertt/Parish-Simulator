export type PlayerShape = 'square' | 'circle' | 'diamond' | 'triangle';

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

export type PlayerMove = {
  x: number;
  y: number;
};

export type PlayerState = Record<string, Player>;
