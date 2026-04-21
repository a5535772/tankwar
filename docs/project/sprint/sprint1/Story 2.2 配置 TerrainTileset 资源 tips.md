# Sprint 1 架构说明

> **版本**: v1.0
> **最后更新**: 2026-04-21
> **整理自**: terrain_system_design.md + ADR-001 + sprint1_dev_plan.md

---

## 1. TileSet 资源架构

### 1.1 TileSet 资源清单

| TileSet 文件 | 用途 | 包含瓦片类型 | Physics Layer | Custom Data |
|-------------|------|-------------|--------------|-------------|
| `GroundTileset.tres` | 地面（草地/沙地/道路） | grass, sand, road | **无碰撞** | 无 |
| `WaterTileset.tres` | 水域 | water | Layer 0 = **BOUNDARY(32)** | `tile_type: String` |
| `TerrainTileset.tres` | 墙壁+边界 | brick, steel, boundary | Layer 0 = **TERRAIN(16)** | `tile_type: String` |

### 1.2 碰撞层分配（ADR-001 关键决策）

```
碰撞层常量定义 (CollisionLayers.gd):
- LAYER_TERRAIN = bit 4 = 16
- LAYER_BOUNDARY = bit 5 = 32
- LAYER_PLAYER = bit 0 = 1
- LAYER_ENEMY = bit 1 = 2
- LAYER_PLAYER_BULLET = bit 2 = 4
- LAYER_ENEMY_BULLET = bit 3 = 8
- LAYER_BASE = bit 6 = 64
- LAYER_POWERUP = bit 7 = 128
```

| 瓦片类型 | Physics Layer | collision_layer 值 | 说明 |
|---------|---------------|-------------------|------|
| 砖墙 | Layer 0 | 16 (TERRAIN) | 可被任意子弹摧毁 |
| 钢墙 | Layer 0 | 16 (TERRAIN) | 仅 Lv.3 子弹可摧毁 |
| 边界 | Layer 0 | 16 (TERRAIN) | **注意：不是 Layer 1** |
| 水域 | Layer 0 | 32 (BOUNDARY) | 在 WaterTileset 中配置 |

### 1.3 为什么边界使用 TERRAIN 层？

**原因**：子弹需要移除 `LAYER_BOUNDARY` mask，否则子弹会被水域阻挡（水域使用 LAYER_BOUNDARY）。

**方案**：
- 边界瓦片改用 `LAYER_TERRAIN`
- 子弹 mask = `LAYER_TERRAIN | LAYER_ENEMY`（移除 LAYER_BOUNDARY）
- 子弹通过 `tile_type` Custom Data 判断瓦片类型

---

## 2. 场景层级架构

### 2.1 Level 场景标准结构

```
Level (Node2D)
├── BoundaryIndicator (Line2D)    — 416×416 边框指示（可选）
├── GroundLayer (TileMapLayer)    — 地面 → GroundTileset（无碰撞）
├── WaterLayer (TileMapLayer)     — 水域 → WaterTileset
├── IceLayer (TileMapLayer)       — 冰面（P3 延期）
├── WallLayer (TileMapLayer)      — 墙壁 → TerrainTileset
├── BoundaryLayer (TileMapLayer)  — 边界 → TerrainTileset
├── GrassLayer (TileMapLayer)     — 草地（P2 延期，渲染层级更高）
├── EntitiesLayer (Node2D)        — 坦克、道具容器
├── BulletLayer (Node2D)          — 子弹容器
└── UI (CanvasLayer)              — UI 层
```

### 2.2 TankTest.tscn 当前结构

```
TankTest.tscn
├── BoundaryIndicator → 416×416 边框指示 ✅
├── GroundLayer → GroundTileset ✅ 已配图
├── WaterLayer → WaterTileset ✅ 已配图
├── WallLayer → TerrainTileset ✅ Story 2.2 完成
├── BoundaryLayer → TerrainTileset ✅ Story 2.2 完成
├── Player1Tank
├── Player2Tank
├── BasicEnemyTank
└── Camera2D
```

---

## 3. 碰撞关系总览

| 实体类型 | collision_layer | collision_mask | 检测对象 |
|---------|----------------|----------------|---------|
| 玩家坦克 | PLAYER (1) | TERRAIN \| BOUNDARY \| ENEMY \| POWERUP (178) | 墙、水域、敌人、道具 |
| 敌人坦克 | ENEMY (2) | TERRAIN \| BOUNDARY \| PLAYER \| BASE (113) | 墙、水域、玩家、基地 |
| 玩家子弹 | PLAYER_BULLET (4) | **TERRAIN \| ENEMY (18)** | 墙(含边界)、敌人 |
| 敌人子弹 | ENEMY_BULLET (8) | **TERRAIN \| PLAYER \| BASE (81)** | 墙(含边界)、玩家、基地 |
| 砖墙/钢墙 | TERRAIN (16) | 0 | 无 |
| 边界墙 | TERRAIN (16) | 0 | 无 |
| 水域瓦片 | BOUNDARY (32) | 0 | 无 |
| 基地 | BASE (64) | 0 | 无 |
| 道具 | POWERUP (128) | PLAYER (1) | 玩家 |

> **关键变更**：子弹 mask 移除 LAYER_BOUNDARY，边界瓦片改用 LAYER_TERRAIN + tile_type 识别。

---

## 4. 子弹-TileMap 交互流程

```
子弹 body_entered(body)
  ├── body 是 TileMapLayer?
  │   ├── 是: _handle_tilemap_collision(tilemap)
  │   │   ├── tile_coords = tilemap.local_to_map(global_position)
  │   │   ├── tile_data = tilemap.get_cell_tile_data(tile_coords)
  │   │   ├── tile_type = tile_data.get_custom_data("tile_type")
  │   │   └── match tile_type:
  │   │       ├── "brick":  tilemap.erase_cell() + queue_free()
  │   │       ├── "steel":  can_destroy_steel ? erase_cell : skip + queue_free()
  │   │       ├── "boundary": queue_free()
  │   │       └── _: queue_free()
  │   └── 否: 原有逻辑（组检测等）
  └── body 是其他物理体?
      └── 原有逻辑（敌人 HurtArea 等）
```

---

## 5. 战场边界定义

### 5.1 标准战场尺寸

- 经典坦克大战标准: 13×13 网格
- 网格大小: 32×32 像素
- 战场范围: 416×416 像素

### 5.2 边界瓦片布局

```
┌─────────────────────────────┐
│ B B B B B B B B B B B B B │  第0行: 边界墙 (13个)
│ B . . . . . . . . . . . B │  第1-11行: 活动区域
│ B . . . . . . . . . . . B │
│ ...                       │
│ B . . . . . . . . . . . B │
│ B B B B B B B B B B B B B │  第12行: 边界墙 (13个)
└─────────────────────────────┘

B = 边界瓦片 (boundary)
. = 活动区域
```

**边界瓦片数量**: 48 个（上13 + 下13 + 左11 + 右11）

---

## 6. 扩展材质设计（后续 Sprint）

### 6.1 草地 (P2 延期)

| 特性 | 实现方案 |
|------|---------|
| 坦克可穿过 | 无碰撞 |
| 隐蔽效果 | GrassLayer z_index = 1（渲染在坦克上层） |
| AI 不追踪 | 检测目标是否在 GrassLayer 中 |

### 6.2 冰面 (P3 延期)

| 特性 | 实现方案 |
|------|---------|
| 滑动惯性 | Tank.gd 移动系统修改 |
| 坦克可穿过 | 无碰撞 |
| 子弹可穿过 | 无碰撞 |

### 6.3 扩展架构原则

**不修改 GroundTileset**，特殊材质独立 TileSet + Layer：

```
后续新增:
├── GrassTileset.tres → GrassLayer
├── IceTileset.tres → IceLayer
└── 各 TileSet 配置 Custom Data: tile_type
```

---

## 7. 开发顺序建议

```
Phase 2: 地形系统
  ├── Story 2.1: TileSet 配置设计 [架构师] ✅ 已完成
  ├── Story 2.2: 配置 TerrainTileset ✅ 已完成
  ├── Story 2.3: 子弹-TileMap 适配 ← 当前任务
  ├── Story 2.4: 实现战场边界
  ├── Story 2.5: 实现砖墙
  └── Story 2.6: 实现钢墙
```

---

## 8. 参考文档

| 文档 | 路径 | 内容 |
|------|------|------|
| ADR-001 | `docs/project/game/architecture/adr_001_tileset_configuration.md` | TileSet 配置技术决策 |
| 地形系统设计 | `docs/project/game/terrain/terrain_system_design.md` | 地形类型+碰撞系统设计 |
| Sprint 1 PRD | `docs/project/sprint/sprint1/sprint1_prd.md` | 产品需求定义 |
| Sprint 1 开发计划 | `docs/project/sprint/sprint1/sprint1_dev_plan.md` | Story 级别开发任务 |

---

*本文档帮助开发者快速理解地形系统架构，避免重复查阅多个设计文档。*