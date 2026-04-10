# CODEBUDDY.md

This file provides guidance to CodeBuddy Code when working with code in this repository.

## Project Overview

This is a classic top-down tank battle game (坦克大战) built in Godot 4.3 with GDScript. The game features pixel-art graphics, player-controlled tanks, enemy AI, destructible terrain, power-ups, and a base defense mechanic.

**Target Platform**: Windows Desktop

---

## AI Development Rules (MUST FOLLOW)

### Documentation Structure

The `docs/` directory contains core documents that AI must reference and update according to rules:

```
docs/
├── me2ai/          # User-provided static info (READ-ONLY for AI)
│   ├── OVERVIEW.md          # Project overview (gameplay, goals, style)
│   ├── TECH_STACK.md        # Tech stack, project structure (user maintained)
│   └── ME2AI.md             # User's principles and requirements for AI
├── shared/         # Dynamic info co-maintained by user and AI
│   └── CURRENT_TASKS.md     # Current task memo (task status, next steps)
└── ai2ai/          # AI work logs (AI writes, user reads)
    └── AI2AI.md             # AI work record (summaries, decisions, issues)
```

### Workflow (MUST FOLLOW)

1. **Check current tasks**: Read `docs/shared/CURRENT_TASKS.md` first
2. **Reference docs as needed**: Read relevant docs in `docs/me2ai/` based on task requirements (no need to read all)
3. **Develop and test**: Implement in Godot 4.3, following specifications
4. **Record work**: Update `docs/ai2ai/AI2AI.md` (content, files, decisions, issues)
5. **Update tasks**: Mark completion in `docs/shared/CURRENT_TASKS.md`, add follow-up tasks
6. **Sync with user**: Communicate major changes promptly

### Core Principles

- **READ-ONLY**: `docs/me2ai/` files are maintained by user, AI must NOT modify them
- **Object-Oriented & Abstraction**: Abstract repeated elements into base classes / reusable scenes
- **Follow Specs**: Feature details are defined in independent spec documents, implement strictly per spec
- **Ask when uncertain**: If questions arise, consult with user

---

## Commands

### Running the Game

```bash
# Open project in Godot Editor (Windows)
godot4 project.godot

# Run the game directly
godot4 project.godot --path . --editor
```

Note: This project requires Godot 4.3 to be installed. Replace `godot4` with your actual Godot executable path if different.

## Architecture

### Core Systems (Singletons)

Located in `scripts/systems/`:
- **EventBus** - Central event system for decoupled communication
- **GameManager** - Game state management
- **LevelManager** - Level progress, enemy spawning, win/lose conditions
- **SaveSystem** - Save/load game data
- **CollisionLayers** - Collision layer definitions

### Entity Hierarchy

- **Tank** (base class) → PlayerTank / EnemyTank
  - Movement, shooting, health, rotation
  - Uses `CharacterBody2D`
- **Bullet** - Projectile handling with object pooling
  - Uses `Area2D` for collision
- **PowerUp** (base class) → ShieldPowerUp / SpeedPowerUp / PowerPowerUp

### Terrain Types

- **BrickWall** - Destructible by bullets
- **SteelWall** - Requires multiple hits or special power-ups
- **Grass** - Provides concealment
- **Water** - Impassable
- **Ice** - Sliding effect

### State Management

Uses **Godot State Charts** plugin (located in `godot-statecharts-main/addons/godot_state_charts/`) for:
- Tank behavior states (idle, moving, shooting, etc.)
- Game flow states
- AI behavior states

### Event-Driven Architecture

EventBus handles:
- Tank damage/death
- Bullet fired
- Power-up collected
- Level complete
- Game over

### Collision Layers

Defined in CollisionLayers.gd:
- `LAYER_PLAYER`
- `LAYER_ENEMY`
- `LAYER_PLAYER_BULLET`
- `LAYER_ENEMY_BULLET`
- `LAYER_TERRAIN`
- `LAYER_POWERUP`
- `LAYER_BASE`

## Code Conventions

- **Naming**: `snake_case` for variables/functions, `PascalCase` for classes/nodes, `ALL_CAPS` for constants
- **Type hints**: Use static typing (e.g., `var speed: float = 100.0`)
- **Comments**: Add comments for complex logic, signal connections, public interfaces
- **Performance**: Avoid expensive operations in `_process()`, use signals and groups

## Physics Configuration

- **Gravity**: 0 (top-down game)
- **Tank movement**: `CharacterBody2D` with `move_and_slide()`
- **Terrain**: `StaticBody2D` (walls) or `Area2D` (grass, water)
- **Bullets**: `Area2D` for collision detection

## Performance Notes

- Use object pooling for bullets and explosion effects
- Limit on-screen bullets and effects
- Merge TileMap collision shapes where possible
- Avoid frequent object creation in `_process()`

## Asset Formats

- **Images**: PNG (16x16 or 32x32 pixels, nearest-neighbor filtering)
- **Music**: OGG Vorbis
- **Sound Effects**: WAV
- **Fonts**: TTF or OTF (dynamic font import)
