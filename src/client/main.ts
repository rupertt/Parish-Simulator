import Phaser from 'phaser';
import './styles.css';
import { GameScene } from './game/GameScene';
import { configureSocket } from './network/socket';
import type { PlayerProfile } from '../shared/types';

const defaultColors = ['#ef4444', '#f97316', '#eab308', '#22c55e', '#06b6d4', '#3b82f6', '#a855f7', '#ec4899'];

function getSavedProfile(): PlayerProfile {
  const saved = window.localStorage.getItem('player-profile');
  if (!saved) {
    return { name: '', color: defaultColors[Math.floor(Math.random() * defaultColors.length)] };
  }

  try {
    const profile = JSON.parse(saved) as Partial<PlayerProfile>;
    return {
      name: typeof profile.name === 'string' ? profile.name : '',
      color: typeof profile.color === 'string' ? profile.color : defaultColors[0]
    };
  } catch {
    return { name: '', color: defaultColors[0] };
  }
}

function askForPlayerProfile(): Promise<PlayerProfile> {
  const savedProfile = getSavedProfile();
  const overlay = document.createElement('div');
  overlay.className = 'join-overlay';
  overlay.innerHTML = `
    <form class="join-card">
      <h1>Join Game</h1>
      <label>
        Name
        <input name="name" maxlength="12" placeholder="Player" autocomplete="off" value="${savedProfile.name}" />
      </label>
      <label>
        Color
        <input name="color" type="color" value="${savedProfile.color}" />
      </label>
      <button type="submit">Join</button>
    </form>
  `;

  document.body.appendChild(overlay);

  return new Promise((resolve) => {
    const form = overlay.querySelector('form');
    form?.addEventListener('submit', (event) => {
      event.preventDefault();
      const data = new FormData(form);
      const profile = {
        name: String(data.get('name') || '').trim() || 'Player',
        color: String(data.get('color') || savedProfile.color)
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
