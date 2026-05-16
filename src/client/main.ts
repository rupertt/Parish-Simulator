import Phaser from 'phaser';
import './styles.css';
import { GameScene } from './game/GameScene';
import { characterOptions, isPlayerShape } from './characterOptions';
import { configureSocket } from './network/socket';
import type { PlayerProfile } from '../shared/types';

const defaultColors = ['#ef4444', '#f97316', '#eab308', '#22c55e', '#06b6d4', '#3b82f6', '#a855f7', '#ec4899'];
const defaultNicknames = ['Bellringer', 'Lantern', 'Vestry', 'Candlewick', 'Parish Pal', 'Steeple'];

function getRandomNickname(): string {
  return defaultNicknames[Math.floor(Math.random() * defaultNicknames.length)];
}

function escapeAttribute(value: string): string {
  return value.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function getSavedProfile(): PlayerProfile {
  const saved = window.localStorage.getItem('player-profile');
  if (!saved) {
    return { name: '', color: defaultColors[Math.floor(Math.random() * defaultColors.length)], shape: 'square' };
  }

  try {
    const profile = JSON.parse(saved) as Partial<PlayerProfile>;
    const savedShape = typeof profile.shape === 'string' && isPlayerShape(profile.shape) ? profile.shape : 'square';
    return {
      name: typeof profile.name === 'string' ? profile.name : '',
      color: typeof profile.color === 'string' ? profile.color : defaultColors[0],
      shape: savedShape
    };
  } catch {
    return { name: '', color: defaultColors[0], shape: 'square' };
  }
}

function renderCharacterChoice(option: (typeof characterOptions)[number], selectedShape: PlayerProfile['shape']): string {
  const checked = option.shape === selectedShape ? 'checked' : '';
  const preview = option.imageUrl
    ? `<img src="${option.imageUrl}" alt="" />`
    : `<span class="shape-preview shape-preview-${option.shape}"></span>`;

  return `
    <label class="character-choice">
      <input type="radio" name="shape" value="${option.shape}" ${checked} />
      <span class="character-preview">${preview}</span>
      <span class="character-name">${option.label}</span>
    </label>
  `;
}

function askForPlayerProfile(): Promise<PlayerProfile> {
  const savedProfile = getSavedProfile();
  const suggestedNickname = getRandomNickname();
  const characterChoices = characterOptions.map((option) => renderCharacterChoice(option, savedProfile.shape)).join('');
  const overlay = document.createElement('div');
  overlay.className = 'join-overlay';
  overlay.innerHTML = `
    <form class="join-card">
      <h1>Join Game</h1>
      <label>
        Name
        <span class="name-row">
          <input name="name" maxlength="12" placeholder="Player" autocomplete="off" value="${escapeAttribute(savedProfile.name)}" />
          <button class="nickname-button" type="button" data-nickname="${escapeAttribute(suggestedNickname)}">Use Nickname</button>
        </span>
      </label>
      <label>
        Color
        <input name="color" type="color" value="${savedProfile.color}" />
      </label>
      <fieldset class="character-picker">
        <legend>Character</legend>
        <div class="character-grid">${characterChoices}</div>
      </fieldset>
      <button type="submit">Join</button>
    </form>
  `;

  document.body.appendChild(overlay);

  return new Promise((resolve) => {
    const form = overlay.querySelector('form');
    const nameInput = overlay.querySelector<HTMLInputElement>('input[name="name"]');
    const nicknameButton = overlay.querySelector<HTMLButtonElement>('.nickname-button');

    nicknameButton?.addEventListener('click', () => {
      const nickname = nicknameButton.dataset.nickname || getRandomNickname();
      nicknameButton.dataset.nickname = getRandomNickname();
      if (nameInput) {
        nameInput.value = nickname;
        nameInput.focus();
      }
    });

    form?.addEventListener('submit', (event) => {
      event.preventDefault();
      const data = new FormData(form);
      const profile = {
        name: String(data.get('name') || '').trim() || 'Player',
        color: String(data.get('color') || savedProfile.color),
        shape: isPlayerShape(String(data.get('shape') || '')) ? String(data.get('shape')) as PlayerProfile['shape'] : savedProfile.shape
      };

      window.localStorage.setItem('player-profile', JSON.stringify(profile));
      overlay.remove();
      resolve(profile);
    });
  });
}

async function startGame(): Promise<void> {
  const profile = await askForPlayerProfile();
  configureSocket(profile);

  const config: Phaser.Types.Core.GameConfig = {
    type: Phaser.AUTO,
    parent: 'app',
    width: 800,
    height: 600,
    pixelArt: true,
    roundPixels: true,
    scene: [GameScene],
    scale: {
      mode: Phaser.Scale.FIT,
      autoCenter: Phaser.Scale.CENTER_BOTH
    }
  };

  new Phaser.Game(config);
}

void startGame();
