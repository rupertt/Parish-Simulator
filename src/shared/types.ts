export type Player = {
  id: string;
  x: number;
  y: number;
  color: string;
  name: string;
};

export type PlayerProfile = {
  name: string;
  color: string;
};

export type PlayerMove = {
  x: number;
  y: number;
};

export type PlayerState = Record<string, Player>;
