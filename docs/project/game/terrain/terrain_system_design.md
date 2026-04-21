# 地形系统设计文档

> **文档版本**: 2.0
> **最后更新**: 2026-04-21
> **合并自**: collision_system_design.md + terrain_boundary_design.md

**相关文档**:
- [ADR-001: TileSet 配置方案](../architecture/adr_001_tileset_configuration.md)
- [边界修复需求](./boundary_fix_requirements.md)
- [敌人坦克架构](../enemies/enemy_tank_architecture.md)

---

## 1. 地形类型定义

### 1.1 砖墙 (Brick Wall)

```gdscript
class_name BrickWall
extends StaticBody2D

## 生命值
@export var health: int = 1
```

**碰撞配置**: `collision_layer = LAYER_TERRAIN (16)`, `collision_mask = 0`

**特性**:
- ✅ 可被所有子弹摧毁（1发）
- ✅ 阻止坦克通过
- ✅ 子弹碰撞后销毁

### 1.2 钢墙 (Steel Wall)

```gdscript
class_name SteelWall
extends StaticBody2D

## 生命值
@export var health: int = 4
## 是否可被摧毁
@export var indestructible: bool = false
```

**碰撞配置**: `collision_layer = LAYER_TERRAIN (16)`, `collision_mask = 0`

**特性**:
- ✅ 普通子弹反弹并销毁
- ✅ 增强子弹可摧毁（需要 `can_destroy_steel=true`）
- ✅ 阻止坦克通过

### 1.3 边界墙 (Boundary Wall)

```gdscript
class_name BoundaryWall
extends StaticBody2D
```

**碰撞配置**: `collision_layer = LAYER_TERRAIN (16)`, `collision_mask = 0`

> ⚠️ 注意：根据 ADR-001，边界瓦片使用 LAYER_TERRAIN 而非 LAYER_BOUNDARY，通过 Custom Data `tile_type="boundary"` 区分。

**特性**:
- ✅ 不可摧毁
- ✅ 阻止坦克通过
- ✅ 销毁子弹

### 1.4 水域 (Water)

**碰撞配置**: `collision_layer = LAYER_BOUNDARY (32)`, `collision_mask = LAYER_PLAYER | LAYER_ENEMY`

> 水域使用 LAYER_BOUNDARY 阻挡坦克，子弹 mask 不含 LAYER_BOUNDARY 故可穿越。

**特性**:
- ✅ 坦克无法通过
- ✅ 子弹可穿过
- ✅ 动态水面效果

### 1.5 草地 (Grass) — P2 延期

**特性**: 坦克可穿过，子弹可穿过，提供隐蔽效果（坦克被遮挡）

**实现**: `z_index = 1`，渲染在坦克上层

### 1.6 冰面 (Ice) — P3 延期

**特性**: 坦克可穿过，子弹可穿过，产生滑动效果（惯性）

---

## 2. 碰撞系统设计

### 2.1 碰撞层常量定义

```gdscript
# scripts/systems/CollisionLayers.gd
class_name CollisionLayers

const LAYER_PLAYER: int = 1 << 0         # 1
const LAYER_ENEMY: int = 1 << 1          # 2
const LAYER_PLAYER_BULLET: int = 1 << 2  # 4
const LAYER_ENEMY_BULLET: int = 1 << 3   # 8
const LAYER_TERRAIN: int = 1 << 4        # 16
const LAYER_BOUNDARY: int = 1 << 5       # 32
const LAYER_BASE: int = 1 << 6           # 64
const LAYER_POWERUP: int = 1 << 7        # 128
```

### 2.2 碰撞关系总览

| 实体类型 | collision_layer | collision_mask | 检测对象 |
|---------|----------------|----------------|---------|
| 玩家坦克 | PLAYER (1) | TERRAIN\|BOUNDARY\|ENEMY\|POWERUP (178) | 墙、水域、敌人、道具 |
| 敌人坦克 | ENEMY (2) | TERRAIN\|BOUNDARY\|PLAYER\|BASE (113) | 墙、水域、玩家、基地 |
| 玩家子弹 | PLAYER_BULLET (4) | TERRAIN\|ENEMY (18) | 墙(含边界)、敌人 |
| 敌人子弹 | ENEMY_BULLET (8) | TERRAIN\|PLAYER\|BASE (81) | 墙(含边界)、玩家、基地 |
| 砖墙/钢墙 | TERRAIN (16) | 0 | 无 |
| 边界墙 | TERRAIN (16) | 0 | 无 |
| 水域瓦片 | BOUNDARY (32) | 0 | 无 |
| 基地 | BASE (64) | 0 或 ENEMY (2) | 敌人（可选） |
| 道具 | POWERUP (128) | PLAYER (1) | 玩家 |

> ⚠️ 关键变更（ADR-001）：子弹 mask 移除 LAYER_BOUNDARY，边界瓦片改用 LAYER_TERRAIN + tile_type 识别。

### 2.3 子弹-TileMap 交互流程

```
子弹 body_entered(body)
  ├── body 是 TileMapLayer?
  │   ├── 是: _handle_tilemap_collision(tilemap)
  │   │   ├── tile_coords = tilemap.local_to_map(global_position)
  │   │   ├── tile_data = tilemap.get_cell_tile_data(tile_coords)
  │   │   ├── tile_type = tile_data.get_custom_data("tile_type")
  │   │   └── match tile_type:
  │   │       ├── "brick":  tilemap.erase_cell(tile_coords) + queue_free()
  │   │       ├── "steel":  can_destroy_steel ? erase_cell : skip + queue_free()
  │   │       ├── "boundary": queue_free()
  │   │       └── _: queue_free()
  │   └── 否: 原有逻辑（组检测等）
  └── body 是其他物理体?
      └── 原有逻辑（敌人 HurtArea 等）
```

---

## 3. TileMap 配置方案

> 详细技术决策见 [ADR-001](../architecture/adr_001_tileset_configuration.md)

### 3.1 场景层级结构

```
Level (Node2D)
├── BackgroundLayer (TileMapLayer)    # 背景装饰（可选）
├── GroundLayer (TileMapLayer)        # 地面（草地、沙地、道路）
├── WaterLayer (TileMapLayer)         # 水域层
├── IceLayer (TileMapLayer)           # 冰面层
├── WallLayer (TileMapLayer)          # 墙壁层（砖墙、钢墙）
├── BoundaryLayer (TileMapLayer)      # 边界墙层
├── GrassLayer (TileMapLayer)         # 草地层（渲染层级更高）
├── EntitiesLayer (Node2D)            # 坦克、道具
├── BulletLayer (Node2D)              # 子弹容器
└── UI (CanvasLayer)                  # UI 层
```

### 3.2 TileSet 资源清单

| 文件 | 用途 | 包含瓦片 | Physics Layer | Custom Data |
|------|------|---------|--------------|-------------|
| `TerrainTileset.tres` | 砖墙+钢墙+边界 | brick, steel, boundary | 0:TERRAIN(16), 1:BOUNDARY(32) | tile_type: String |
| `WaterTileset.tres` | 水域 | water | 0:BOUNDARY(32) | tile_type: String |

### 3.3 瓦片 Physics Layer 映射

| 瓦片类型 | Physics Layer 0 (TERRAIN=16) | Physics Layer 1 (BOUNDARY=32) | 碰撞形状 |
|---------|-----------------------------|------------------------------|---------|
| 砖墙 | ✅ | ❌ | RectangleShape2D 32×32 |
| 钢墙 | ✅ | ❌ | RectangleShape2D 32×32 |
| 边界 | ✅ | ❌ | RectangleShape2D 32×32 |
| 水域 | ❌ | ✅ (WaterTileset) | RectangleShape2D 32×32 |

---

## 4. 战场边界定义

### 4.1 标准战场尺寸

- 经典坦克大战标准: 13×13 网格
- 网格大小: 32×32 像素
- 战场范围: 416×416 像素
- 实际可活动区域: 11×11 网格 (352×352 像素)

### 4.2 边界布局

```
┌─────────────────┐
│ B B B B B B B B B B B B B │  第0行: 边界墙
│ B . . . . . . . . . . . B │  第1-11行: 活动区域
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B B B B B B B B B B B B B │  第12行: 边界墙
└─────────────────┘

B = 边界墙 (Boundary)
. = 活动区域
```

**边界墙位置**:
- 上边界: 网格 (0,0) 到 (12,0) — 13 个瓦片
- 下边界: 网格 (0,12) 到 (12,12) — 13 个瓦片
- 左边界: 网格 (0,1) 到 (0,11) — 11 个瓦片
- 右边界: 网格 (12,1) 到 (12,11) — 11 个瓦片
- 总计: 48 个边界墙瓦片

---

## 5. 测试检查清单

### 5.1 边界测试

- [ ] 玩家坦克无法移出战场边界
- [ ] 敌人坦克无法移出战场边界
- [ ] 玩家子弹在边界处销毁
- [ ] 敌人子弹在边界处销毁
- [ ] 子弹不会卡在边界外

### 5.2 地形测试

- [ ] 砖墙可被子弹摧毁
- [ ] 钢墙需要增强子弹才能摧毁
- [ ] 草地不阻止坦克移动
- [ ] 水域阻止坦克进入
- [ ] 冰面产生滑动效果

### 5.3 碰撞测试

- [ ] 坦克与墙壁碰撞正常
- [ ] 子弹与墙壁碰撞正常
- [ ] 坦克之间碰撞正常
- [ ] 碰撞性能正常（无明显卡顿）
