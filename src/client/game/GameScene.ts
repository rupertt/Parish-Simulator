import Phaser from 'phaser';
import type { Player, PlayerState } from '../../shared/types';
import { getSocket, type GameSocket } from '../network/socket';

const ROOM_WIDTH = 800;
const ROOM_HEIGHT = 600;
const PLAYER_SIZE = 24;
const PLAYER_SPEED = 180;
const MOVE_SEND_INTERVAL_MS = 1000 / 30;

type PlayerSprite = {
  body: Phaser.GameObjects.Rectangle;
  label: Phaser.GameObjects.Text;
};

export class GameScene extends Phaser.Scene {
  private socket?: GameSocket;
  private cursors?: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys?: Record<'W' | 'A' | 'S' | 'D', Phaser.Input.Keyboard.Key>;
  private playerSprites = new Map<string, PlayerSprite>();
  private localPlayerId = '';
  private localPosition = new Phaser.Math.Vector2(ROOM_WIDTH / 2, ROOM_HEIGHT / 2);
  private lastSentPosition = new Phaser.Math.Vector2(-1, -1);
  private moveSendElapsed = 0;

  constructor() {
    super('GameScene');
  }

  create(): void {
    this.cameras.main.setBackgroundColor('#111827');
    this.createGrid();
    this.socket = getSocket();

    this.add
      .text(16, 14, 'WASD to move - share your host IP with friends on the same network', {
        fontFamily: 'monospace',
        fontSize: '14px',
        color: '#d1d5db'
      })
      .setDepth(10);

    this.cursors = this.input.keyboard?.createCursorKeys();
    this.keys = this.input.keyboard?.addKeys('W,A,S,D') as Record<
      'W' | 'A' | 'S' | 'D',
      Phaser.Input.Keyboard.Key
    >;
    this.localPlayerId = this.socket.id ?? '';

    this.socket.on('connect', () => {
      this.localPlayerId = this.socket?.id ?? '';
      this.refreshLocalPosition();
    });

    this.socket.on('player:state', (players) => {
      this.localPlayerId = this.socket?.id ?? this.localPlayerId;
      this.syncPlayerState(players);
    });

    this.socket.on('player:join', (player) => {
      this.upsertPlayer(player);
    });

    this.socket.on('player:move', (player) => {
      this.upsertPlayer(player);
    });

    this.socket.on('player:left', (id) => {
      this.removePlayer(id);
    });
  }

  update(_time: number, delta: number): void {
    if (!this.localPlayerId || !this.keys) {
      return;
    }

    const move = new Phaser.Math.Vector2(0, 0);
    if (this.keys.W.isDown || this.cursors?.up?.isDown) {
      move.y -= 1;
    }
    if (this.keys.S.isDown || this.cursors?.down?.isDown) {
      move.y += 1;
    }
    if (this.keys.A.isDown || this.cursors?.left?.isDown) {
      move.x -= 1;
    }
    if (this.keys.D.isDown || this.cursors?.right?.isDown) {
      move.x += 1;
    }

    if (move.lengthSq() === 0) {
      return;
    }

    move.normalize().scale(PLAYER_SPEED * (delta / 1000));
    this.localPosition.x = Phaser.Math.Clamp(
      this.localPosition.x + move.x,
      PLAYER_SIZE / 2,
      ROOM_WIDTH - PLAYER_SIZE / 2
    );
    this.localPosition.y = Phaser.Math.Clamp(
      this.localPosition.y + move.y,
      PLAYER_SIZE / 2,
      ROOM_HEIGHT - PLAYER_SIZE / 2
    );

    this.movePlayerSprite(this.localPlayerId, this.localPosition.x, this.localPosition.y);
    this.moveSendElapsed += delta;

    if (
      this.moveSendElapsed >= MOVE_SEND_INTERVAL_MS ||
      Phaser.Math.Distance.BetweenPoints(this.localPosition, this.lastSentPosition) >= PLAYER_SIZE / 2
    ) {
      this.moveSendElapsed = 0;
      this.lastSentPosition.copy(this.localPosition);
      this.socket?.emit('player:move', {
        x: this.localPosition.x,
        y: this.localPosition.y
      });
    }
  }

  private createGrid(): void {
    const graphics = this.add.graphics();
    graphics.lineStyle(1, 0x374151, 0.45);

    for (let x = 0; x <= ROOM_WIDTH; x += 32) {
      graphics.lineBetween(x, 0, x, ROOM_HEIGHT);
    }

    for (let y = 0; y <= ROOM_HEIGHT; y += 32) {
      graphics.lineBetween(0, y, ROOM_WIDTH, y);
    }

    graphics.lineStyle(4, 0x9ca3af, 1);
    graphics.strokeRect(0, 0, ROOM_WIDTH, ROOM_HEIGHT);
  }

  private syncPlayerState(players: PlayerState): void {
    for (const [id, sprite] of this.playerSprites) {
      if (!players[id]) {
        sprite.body.destroy();
        sprite.label.destroy();
        this.playerSprites.delete(id);
      }
    }

    Object.values(players).forEach((player) => this.upsertPlayer(player));
  }

  private upsertPlayer(player: Player): void {
    const sprite = this.playerSprites.get(player.id);
    if (sprite) {
      this.movePlayerSprite(player.id, player.x, player.y);
      return;
    }

    const body = this.add
      .rectangle(player.x, player.y, PLAYER_SIZE, PLAYER_SIZE, Phaser.Display.Color.HexStringToColor(player.color).color)
      .setStrokeStyle(2, 0xf9fafb)
      .setDepth(2);

    const label = this.add
      .text(player.x, player.y - 26, player.name, {
        fontFamily: 'monospace',
        fontSize: '12px',
        color: '#f9fafb'
      })
      .setOrigin(0.5)
      .setDepth(3);

    this.playerSprites.set(player.id, { body, label });

    if (player.id === this.localPlayerId) {
      this.localPosition.set(player.x, player.y);
    }
  }

  private movePlayerSprite(id: string, x: number, y: number): void {
    const sprite = this.playerSprites.get(id);
    if (!sprite) {
      return;
    }

    sprite.body.setPosition(x, y);
    sprite.label.setPosition(x, y - 26);

    if (id === this.localPlayerId) {
      this.localPosition.set(x, y);
    }
  }

  private refreshLocalPosition(): void {
    const sprite = this.playerSprites.get(this.localPlayerId);
    if (!sprite) {
      return;
    }

    this.localPosition.set(sprite.body.x, sprite.body.y);
  }

  private removePlayer(id: string): void {
    const sprite = this.playerSprites.get(id);
    if (!sprite) {
      return;
    }

    sprite.body.destroy();
    sprite.label.destroy();
    this.playerSprites.delete(id);
  }
}
