import Phaser from 'phaser';
import type { Player, PlayerInput, PlayerState, Projectile } from '../../shared/types';
import { getCharacterImageUrl, imageCharacterOptions } from '../characterOptions';
import { getSocket, type GameSocket } from '../network/socket';

const ROOM_WIDTH = 800;
const ROOM_HEIGHT = 600;
const PLAYER_SIZE = 24;
const PLAYER_SPEED = 180;
const INPUT_SEND_INTERVAL_MS = 1000 / 20;
const REMOTE_INTERPOLATION = 0.35;
const LOCAL_RECONCILE_DISTANCE = 48;
const PROJECTILE_SIZE = 6;
const PROJECTILE_SPEED = 380;
const PROJECTILE_LIFETIME_MS = 5000;
const PROJECTILE_COOLDOWN_MS = 250;
const PROJECTILE_KNOCKBACK_DISTANCE = 72;
const RIVER_LEFT = ROOM_WIDTH / 2 - 48;
const RIVER_WIDTH = 96;
const RIVER_RIGHT = RIVER_LEFT + RIVER_WIDTH;
const BRIDGE_HEIGHT = 64;
const BRIDGES = [
  { x: RIVER_LEFT, y: 96, width: RIVER_WIDTH, height: BRIDGE_HEIGHT },
  { x: RIVER_LEFT, y: ROOM_HEIGHT / 2 - BRIDGE_HEIGHT / 2, width: RIVER_WIDTH, height: BRIDGE_HEIGHT },
  { x: RIVER_LEFT, y: ROOM_HEIGHT - 96 - BRIDGE_HEIGHT, width: RIVER_WIDTH, height: BRIDGE_HEIGHT }
];

type PlayerSprite = {
  body: Phaser.GameObjects.Shape | Phaser.GameObjects.Image;
  label: Phaser.GameObjects.Text;
  targetPosition: Phaser.Math.Vector2;
};

type ProjectileSprite = {
  body: Phaser.GameObjects.Arc;
  ownerId: string;
  velocity: Phaser.Math.Vector2;
  remainingMs: number;
  hitPlayerIds: Set<string>;
};

export class GameScene extends Phaser.Scene {
  private socket?: GameSocket;
  private cursors?: Phaser.Types.Input.Keyboard.CursorKeys;
  private keys?: Record<'W' | 'A' | 'S' | 'D', Phaser.Input.Keyboard.Key>;
  private fireKey?: Phaser.Input.Keyboard.Key;
  private playerSprites = new Map<string, PlayerSprite>();
  private projectileSprites = new Map<string, ProjectileSprite>();
  private localPlayerId = '';
  private localPosition = new Phaser.Math.Vector2(ROOM_WIDTH / 2, ROOM_HEIGHT / 2);
  private lastFacing = new Phaser.Math.Vector2(1, 0);
  private lastSentInput: PlayerInput = { directionX: 0, directionY: 0 };
  private inputSendElapsed = INPUT_SEND_INTERVAL_MS;
  private projectileCooldownElapsed = PROJECTILE_COOLDOWN_MS;

  constructor() {
    super('GameScene');
  }

  preload(): void {
    imageCharacterOptions.forEach((option) => {
      if (option.imageUrl) {
        this.load.image(option.shape, option.imageUrl);
      }
    });
  }

  create(): void {
    this.cameras.main.setBackgroundColor('#111827');
    this.createGrid();
    this.socket = getSocket();

    this.add
      .text(16, 14, 'WASD to move - Space to fire - share your host IP with friends on the same network', {
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
    this.fireKey = this.input.keyboard?.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
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

    this.socket.on('player:left', (id) => {
      this.removePlayer(id);
    });

    this.socket.on('projectile:spawn', (projectile) => {
      this.spawnProjectile(projectile);
    });

    this.socket.connect();
  }

  update(_time: number, delta: number): void {
    this.interpolateRemotePlayers();
    this.updateProjectiles(delta);
    this.projectileCooldownElapsed += delta;

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

    const input = this.toPlayerInput(move);
    this.inputSendElapsed += delta;
    this.sendInputIfNeeded(input);

    if (move.lengthSq() > 0) {
      move.normalize();
      this.lastFacing.copy(move);
      move.scale(PLAYER_SPEED * (delta / 1000));
      this.localPosition.copy(
        this.resolvePlayerPosition(
          this.localPosition,
          new Phaser.Math.Vector2(this.localPosition.x + move.x, this.localPosition.y + move.y)
        )
      );

      this.movePlayerSprite(this.localPlayerId, this.localPosition.x, this.localPosition.y);
    }

    if (
      this.fireKey &&
      Phaser.Input.Keyboard.JustDown(this.fireKey) &&
      this.projectileCooldownElapsed >= PROJECTILE_COOLDOWN_MS
    ) {
      this.fireProjectile();
    }
  }

  private createGrid(): void {
    const graphics = this.add.graphics();
    graphics.fillStyle(0x1d4ed8, 0.9);
    graphics.fillRect(RIVER_LEFT, 0, RIVER_WIDTH, ROOM_HEIGHT);
    graphics.fillStyle(0x38bdf8, 0.22);
    graphics.fillRect(RIVER_LEFT + 12, 0, 10, ROOM_HEIGHT);
    graphics.fillRect(RIVER_RIGHT - 22, 0, 10, ROOM_HEIGHT);
    graphics.fillStyle(0x475569, 1);
    graphics.lineStyle(2, 0xcbd5e1, 0.8);
    BRIDGES.forEach((bridge) => {
      graphics.fillRect(bridge.x, bridge.y, bridge.width, bridge.height);
      graphics.strokeRect(bridge.x, bridge.y, bridge.width, bridge.height);
    });

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
      this.applyServerPlayerPosition(player, sprite);
      return;
    }

    const body = this.createPlayerBody(player);

    const label = this.add
      .text(player.x, player.y - 26, player.name, {
        fontFamily: 'monospace',
        fontSize: '12px',
        color: '#f9fafb'
      })
      .setOrigin(0.5)
      .setDepth(3);

    this.playerSprites.set(player.id, {
      body,
      label,
      targetPosition: new Phaser.Math.Vector2(player.x, player.y)
    });

    if (player.id === this.localPlayerId) {
      this.localPosition.set(player.x, player.y);
    }
  }

  private createPlayerBody(player: Player): Phaser.GameObjects.Shape | Phaser.GameObjects.Image {
    if (getCharacterImageUrl(player.shape)) {
      return this.add
        .image(player.x, player.y, player.shape)
        .setDisplaySize(PLAYER_SIZE * 1.4, PLAYER_SIZE * 1.4)
        .setDepth(2);
    }

    const color = Phaser.Display.Color.HexStringToColor(player.color).color;
    const halfSize = PLAYER_SIZE / 2;

    if (player.shape === 'circle') {
      return this.add.circle(player.x, player.y, halfSize, color).setStrokeStyle(2, 0xf9fafb).setDepth(2);
    }

    if (player.shape === 'diamond') {
      return this.add
        .polygon(
          player.x,
          player.y,
          [
            0,
            -halfSize,
            halfSize,
            0,
            0,
            halfSize,
            -halfSize,
            0
          ],
          color
        )
        .setStrokeStyle(2, 0xf9fafb)
        .setDepth(2);
    }

    if (player.shape === 'triangle') {
      return this.add
        .triangle(player.x, player.y, 0, PLAYER_SIZE, halfSize, 0, PLAYER_SIZE, PLAYER_SIZE, color)
        .setStrokeStyle(2, 0xf9fafb)
        .setDepth(2);
    }

    return this.add.rectangle(player.x, player.y, PLAYER_SIZE, PLAYER_SIZE, color).setStrokeStyle(2, 0xf9fafb).setDepth(2);
  }

  private movePlayerSprite(id: string, x: number, y: number): void {
    const sprite = this.playerSprites.get(id);
    if (!sprite) {
      return;
    }

    sprite.body.setPosition(x, y);
    sprite.label.setPosition(x, y - 26);
    sprite.targetPosition.set(x, y);

    if (id === this.localPlayerId) {
      this.localPosition.set(x, y);
    }
  }

  private setPlayerSpritePosition(sprite: PlayerSprite, x: number, y: number): void {
    sprite.body.setPosition(x, y);
    sprite.label.setPosition(x, y - 26);
  }

  private applyServerPlayerPosition(player: Player, sprite: PlayerSprite): void {
    sprite.targetPosition.set(player.x, player.y);

    if (player.id !== this.localPlayerId) {
      return;
    }

    const distanceFromServer = Phaser.Math.Distance.Between(
      this.localPosition.x,
      this.localPosition.y,
      player.x,
      player.y
    );

    if (distanceFromServer >= LOCAL_RECONCILE_DISTANCE) {
      this.localPosition.set(player.x, player.y);
      this.setPlayerSpritePosition(sprite, player.x, player.y);
    }
  }

  private interpolateRemotePlayers(): void {
    for (const [id, sprite] of this.playerSprites) {
      if (id === this.localPlayerId) {
        continue;
      }

      const nextX = Phaser.Math.Linear(sprite.body.x, sprite.targetPosition.x, REMOTE_INTERPOLATION);
      const nextY = Phaser.Math.Linear(sprite.body.y, sprite.targetPosition.y, REMOTE_INTERPOLATION);
      this.setPlayerSpritePosition(sprite, nextX, nextY);
    }
  }

  private toPlayerInput(move: Phaser.Math.Vector2): PlayerInput {
    if (move.lengthSq() === 0) {
      return { directionX: 0, directionY: 0 };
    }

    const normalizedMove = move.clone().normalize();
    return {
      directionX: normalizedMove.x,
      directionY: normalizedMove.y
    };
  }

  private sendInputIfNeeded(input: PlayerInput): void {
    const changed =
      input.directionX !== this.lastSentInput.directionX || input.directionY !== this.lastSentInput.directionY;

    if (!changed && this.inputSendElapsed < INPUT_SEND_INTERVAL_MS) {
      return;
    }

    this.inputSendElapsed = 0;
    this.lastSentInput = input;
    this.socket?.emit('player:input', input);
  }

  private resolvePlayerPosition(current: Phaser.Math.Vector2, requested: Phaser.Math.Vector2): Phaser.Math.Vector2 {
    const next = new Phaser.Math.Vector2(
      Phaser.Math.Clamp(requested.x, PLAYER_SIZE / 2, ROOM_WIDTH - PLAYER_SIZE / 2),
      Phaser.Math.Clamp(requested.y, PLAYER_SIZE / 2, ROOM_HEIGHT - PLAYER_SIZE / 2)
    );

    const resolved = current.clone();
    if (this.canStandAt(next.x, resolved.y)) {
      resolved.x = next.x;
    }
    if (this.canStandAt(resolved.x, next.y)) {
      resolved.y = next.y;
    }

    return resolved;
  }

  private canStandAt(x: number, y: number): boolean {
    const halfSize = PLAYER_SIZE / 2;
    const overlapsRiver = x + halfSize > RIVER_LEFT && x - halfSize < RIVER_RIGHT;
    if (!overlapsRiver) {
      return true;
    }

    return BRIDGES.some((bridge) => y - halfSize >= bridge.y && y + halfSize <= bridge.y + bridge.height);
  }

  private fireProjectile(): void {
    this.projectileCooldownElapsed = 0;

    const spawnOffset = PLAYER_SIZE / 2 + PROJECTILE_SIZE + 2;
    this.socket?.emit('projectile:fire', {
      x: this.localPosition.x + this.lastFacing.x * spawnOffset,
      y: this.localPosition.y + this.lastFacing.y * spawnOffset,
      directionX: this.lastFacing.x,
      directionY: this.lastFacing.y
    });
  }

  private spawnProjectile(projectile: Projectile): void {
    const existingProjectile = this.projectileSprites.get(projectile.id);
    if (existingProjectile) {
      existingProjectile.body.destroy();
      this.projectileSprites.delete(projectile.id);
    }

    const color = Phaser.Display.Color.HexStringToColor(projectile.color).color;
    const body = this.add
      .circle(projectile.x, projectile.y, PROJECTILE_SIZE, color)
      .setStrokeStyle(2, 0xfef3c7)
      .setDepth(4);

    this.projectileSprites.set(projectile.id, {
      body,
      ownerId: projectile.ownerId,
      velocity: new Phaser.Math.Vector2(projectile.directionX, projectile.directionY).scale(PROJECTILE_SPEED),
      remainingMs: PROJECTILE_LIFETIME_MS,
      hitPlayerIds: new Set()
    });
  }

  private updateProjectiles(delta: number): void {
    for (const [id, projectile] of this.projectileSprites) {
      projectile.remainingMs -= delta;
      projectile.body.x += projectile.velocity.x * (delta / 1000);
      projectile.body.y += projectile.velocity.y * (delta / 1000);

      if (projectile.body.x <= PROJECTILE_SIZE || projectile.body.x >= ROOM_WIDTH - PROJECTILE_SIZE) {
        projectile.body.x = Phaser.Math.Clamp(projectile.body.x, PROJECTILE_SIZE, ROOM_WIDTH - PROJECTILE_SIZE);
        projectile.velocity.x *= -1;
      }

      if (projectile.body.y <= PROJECTILE_SIZE || projectile.body.y >= ROOM_HEIGHT - PROJECTILE_SIZE) {
        projectile.body.y = Phaser.Math.Clamp(projectile.body.y, PROJECTILE_SIZE, ROOM_HEIGHT - PROJECTILE_SIZE);
        projectile.velocity.y *= -1;
      }

      this.handleProjectilePlayerHit(projectile);

      if (projectile.remainingMs <= 0) {
        projectile.body.destroy();
        this.projectileSprites.delete(id);
      }
    }
  }

  private handleProjectilePlayerHit(projectile: ProjectileSprite): void {
    if (
      !this.localPlayerId ||
      projectile.ownerId === this.localPlayerId ||
      projectile.hitPlayerIds.has(this.localPlayerId)
    ) {
      return;
    }

    const distanceToLocalPlayer = Phaser.Math.Distance.Between(
      projectile.body.x,
      projectile.body.y,
      this.localPosition.x,
      this.localPosition.y
    );

    if (distanceToLocalPlayer > PLAYER_SIZE / 2 + PROJECTILE_SIZE) {
      return;
    }

    projectile.hitPlayerIds.add(this.localPlayerId);
    const knockback = projectile.velocity.clone().normalize().scale(PROJECTILE_KNOCKBACK_DISTANCE);
    this.localPosition.copy(
      this.resolvePlayerPosition(
        this.localPosition,
        new Phaser.Math.Vector2(this.localPosition.x + knockback.x, this.localPosition.y + knockback.y)
      )
    );
    this.movePlayerSprite(this.localPlayerId, this.localPosition.x, this.localPosition.y);
    this.socket?.emit('player:knockback', {
      directionX: projectile.velocity.x,
      directionY: projectile.velocity.y,
      distance: PROJECTILE_KNOCKBACK_DISTANCE
    });
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
