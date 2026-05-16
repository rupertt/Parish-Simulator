import type { PlayerShape } from '../shared/types';

type CharacterOption = {
  shape: PlayerShape;
  label: string;
  imageUrl?: string;
};

export const characterOptions: CharacterOption[] = [
  { shape: 'square', label: 'Square' },
  { shape: 'circle', label: 'Circle' },
  { shape: 'diamond', label: 'Diamond' },
  { shape: 'triangle', label: 'Triangle' },
  { shape: 'henry', label: 'Henry', imageUrl: new URL('../../Images for game/Henry.webp', import.meta.url).href },
  { shape: 'dad', label: 'Dad', imageUrl: new URL('../../Images for game/Dad.webp', import.meta.url).href },
  { shape: 'alex', label: 'Alex', imageUrl: new URL('../../Images for game/Alex.webp', import.meta.url).href },
  { shape: 'max', label: 'Max', imageUrl: new URL('../../Images for game/Max.webp', import.meta.url).href },
  { shape: 'julius', label: 'Julius', imageUrl: new URL('../../Images for game/Julius.webp', import.meta.url).href },
  { shape: 'rupert', label: 'Rupert', imageUrl: new URL('../../Images for game/Rupert.webp', import.meta.url).href }
];

export const imageCharacterOptions = characterOptions.filter((option) => option.imageUrl);

export function isPlayerShape(value: string): value is PlayerShape {
  return characterOptions.some((option) => option.shape === value);
}

export function getCharacterImageUrl(shape: PlayerShape): string | undefined {
  return characterOptions.find((option) => option.shape === shape)?.imageUrl;
}
