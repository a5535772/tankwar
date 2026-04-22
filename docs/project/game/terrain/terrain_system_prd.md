# 地形系统产品需求说明书 (Terrain System PRD)

> **文档版本**: 1.0
> **最后更新**: 2026-04-22
> **生成自**: sprint1_prd.md + terrain_system_design.md + boundary_fix_requirements.md + adr_001
> **验证场景**: `scenes/levels/TankTest.tscn`

**相关文档**:
- [ADR-001: TileSet 配置方案](../architecture/adr_001_tileset_configuration.md)
- [边界修复需求](./boundary_fix_requirements.md)
- [地形系统设计](./terrain_system_design.md)
- [Sprint 1 PRD](../../sprint/sprint1/sprint1_prd.md)

---

## 1. 概述

### 1.1 目标

实现完整的战场地形系统，支持多种地形类型（砖墙、钢墙、边界、水域、草地），通过 TileMapLayer + Custom Data Layer 方案统一管理地形的渲染、碰撞和交互。

### 1.2 玩家体验目标

| 地形 | 体验目标 |
|------|---------|
| 边界 | 移动时感受到清晰的战场边界，永远不会"跑出地图" |
| 砖墙 | 射击时的满足感——墙壁碎裂、新路线打开 |
| 钢墙 | 不可逾越的障碍——除非拥有 Lv.3 炮弹，此时感受到力量提升 |
| 水域 | 天然屏障，迫使玩家绕路，创造战术选择 |
| 草地 | 隐蔽身形，在敌人视线中消失 |

### 1.3 需求优先级

| 需求 | 优先级 | Sprint |
|------|--------|--------|
| 战场边界 | P0 | Sprint 1 |
| 砖墙 | P0 | Sprint 1 |
| 钢墙 | P0 | Sprint 1 |
| 水域 | P1 | Sprint 1 |
| 基地 | P2 | Sprint 1 |
| 草地 | P2 | Sprint 1 |
| 冰面 | P3-延期 | 后续 Sprint |

---

## 2. 地形类型规格

### 2.1 [P0] 战场边界

**需求**: 坦克和子弹不可超出战场范围

**实现规格**:
- 战场范围: 416x416 像素（13x13 格 x 32px）
- 实际可活动区域: 11x11 网格 (352x352 像素)
- `BoundaryLayer`（TileMapLayer）使用 `TerrainTileset`，边界瓦片 Physics Layer 0 (TERRAIN=16)
- 边界瓦片标记 `tile_type = "boundary"`（Custom Data Layer）
- 坦克 `collision_mask` 包含 `LAYER_TERRAIN`，被边界阻挡
- 子弹 `collision_mask` 包含 `LAYER_TERRAIN`，触碰边界后通过 `tile_type` 识别并销毁
- 子弹移除 `get_viewport_rect()` 边界检测，完全依赖碰撞系统

**边界布局** (48 个瓦片):
- 上边界: 网格 (0,0) 到 (12,0) -- 13 个瓦片
- 下边界: 网格 (0,12) 到 (12,12) -- 13 个瓦片
- 左边界: 网格 (0,1) 到 (0,11) -- 11 个瓦片
- 右边界: 网格 (12,1) 到 (12,11) -- 11 个瓦片

**输入/输出/失败**:

| 输入 | 预期输出 | 失败状态 |
|------|---------|---------|
| 坦克移动到边界位置 | 被阻挡无法继续移动 | 坦克穿过边界 |
| 子弹到达边界 | 子弹销毁 | 子弹穿过边界或卡在边界外 |
| 坦克对角线移动被边界阻挡 | 沿边界滑行 | 坦克卡住 |

**待修改文件**:
- `assets/tilesets/TerrainTileset.tres` -- 补充边界瓦片定义、碰撞形状和 Custom Data
- `scripts/weapons/Bullet.gd` -- 移除 viewport 边界检测，适配 TileMapLayer 碰撞处理
- `scenes/levels/TankTest.tscn` -- 在 BoundaryLayer 上绘制边界瓦片

---

### 2.2 [P0] 砖墙

**需求**: 可被任意炮弹摧毁的掩体

**实现规格**:
- `WallLayer`（TileMapLayer）使用 `TerrainTileset`，砖墙瓦片 Physics Layer 0 (TERRAIN=16)
- 砖墙瓦片标记 `tile_type = "brick"`（Custom Data Layer）
- 砖墙占 1 格（32x32），可被单发炮弹摧毁
- 子弹击中砖墙 -> `tilemap.erase_cell(tile_coords)` -> 子弹 `queue_free()`
- 碎裂时播放占位动画（色块闪烁后消失）

**输入/输出/失败**:

| 输入 | 预期输出 | 失败状态 |
|------|---------|---------|
| 子弹击中砖墙瓦片 | 砖墙从地图移除，子弹销毁 | 子弹穿墙 / 砖墙不被摧毁 |
| 多发子弹同时击中同一砖墙 | 砖墙被摧毁一次，后续子弹正常飞过或碰撞相邻瓦片 | 崩溃或异常 |

**待修改文件**:
- `assets/tilesets/TerrainTileset.tres` -- 补充砖墙瓦片、碰撞形状和 Custom Data
- `scripts/weapons/Bullet.gd` -- `_on_body_entered()` 中处理 TileMapLayer 碰撞
- `scenes/levels/TankTest.tscn` -- 在 WallLayer 上绘制砖墙布局

---

### 2.3 [P0] 钢墙

**需求**: 仅 Lv.3 消钢炮弹可摧毁；其他炮弹击中后消失

**实现规格**:
- `WallLayer`（TileMapLayer）使用 `TerrainTileset`，钢墙瓦片 Physics Layer 0 (TERRAIN=16)
- 钢墙瓦片标记 `tile_type = "steel"`（Custom Data Layer）
- 子弹 `can_destroy_steel == false` -> 子弹销毁，钢墙不损
- 子弹 `can_destroy_steel == true` -> `tilemap.erase_cell(tile_coords)`，子弹销毁
- 钢墙视觉上与砖墙有明确区分（颜色更亮/更灰）

**输入/输出/失败**:

| 输入 | 预期输出 | 失败状态 |
|------|---------|---------|
| Lv.1/2 子弹击中钢墙 | 子弹消失，钢墙完好 | Lv.1 炮弹摧毁钢墙 |
| Lv.3 子弹击中钢墙 | 钢墙摧毁，子弹销毁 | Lv.3 炮弹无法摧毁钢墙 |

**待修改文件**:
- 同砖墙文件
- `scenes/levels/TankTest.tscn` -- 在 WallLayer 上放置钢墙瓦片

---

### 2.4 [P1] 水域

**需求**: 坦克不可进入，子弹可飞越

**实现规格**:
- `WaterLayer`（TileMapLayer）使用 `WaterTileset`，水域瓦片 Physics Layer 0 (BOUNDARY=32)
- 水域瓦片标记 `tile_type = "water"`（Custom Data Layer）
- 坦克 `collision_mask` 包含 `LAYER_BOUNDARY` -> 被水域阻挡
- 子弹 `collision_mask` 不含 `LAYER_BOUNDARY` -> 子弹穿越水域
- 动态水面效果

**碰撞层方案** (ADR-001):

| 场景 | 水域 collision_layer = 32 | 结果 |
|------|--------------------------|------|
| 坦克碰水域 | 坦克 mask 含 LAYER_BOUNDARY(32) | 坦克被阻挡 |
| 子弹飞越水域 | 子弹 mask 不含 LAYER_BOUNDARY(32) | 子弹穿越 |
| 坦克碰边界 | 边界 collision_layer = TERRAIN(16) | 坦克被阻挡 |
| 子弹碰边界 | 子弹 mask 含 LAYER_TERRAIN(16) | 子弹触碰后销毁 |

**待修改文件**:
- `assets/tilesets/WaterTileset.tres` -- 配置 Physics Layer 和 Custom Data Layer
- `scenes/levels/TankTest.tscn` -- 在 WaterLayer 上绘制水域

---

### 2.5 [P2] 基地

**需求**: 位于战场底部中央，被摧毁则游戏结束

**实现规格**:
- 基地实体使用 `LAYER_BASE`（bit 6 = 64）
- 基地有血量（3 点），被敌人子弹击中扣血
- 血量归零 -> 基地摧毁 -> 触发 `EventBus.game_over()`
- 基地周围有砖墙保护
- 视觉: 占位色块（区别于普通瓦片）

**待创建文件**:
- `scripts/entities/Base.gd` -- 基地脚本
- `scenes/entities/Base.tscn` -- 基地场景

---

### 2.6 [P2] 草地

**需求**: 坦克进入后对敌人不可见（AI 不追踪）

**实现规格**:
- 草地瓦片无碰撞（坦克可自由通过）
- 草地绘制在坦克上方的图层（Z-index 更高），视觉上"遮挡"坦克
- AI 追踪逻辑: 如果目标在草地中，视为不可见
- 使用 `TerrainTileset`，`tile_type = "grass"`

---

### 2.7 [P3-延期] 冰面

**需求**: 坦克经过时产生滑动惯性

**说明**: 冰面的滑动机制实现较复杂（需要修改 Tank.gd 的移动系统），降级到后续 Sprint。

---

## 3. 碰撞系统

### 3.1 碰撞层常量

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

### 3.2 碰撞关系总览

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

> 子弹 mask 移除 LAYER_BOUNDARY，边界瓦片使用 LAYER_TERRAIN + tile_type 识别。坦克 mask 保留 LAYER_BOUNDARY 用于检测水域。

### 3.3 子弹-TileMap 交互流程

```
子弹 body_entered(body)
  +-- body 是 TileMapLayer?
  |   +-- 是: _handle_tilemap_collision(tilemap)
  |   |   +-- tile_coords = tilemap.local_to_map(global_position)
  |   |   +-- tile_data = tilemap.get_cell_tile_data(tile_coords)
  |   |   +-- tile_type = tile_data.get_custom_data("tile_type")
  |   |   +-- match tile_type:
  |   |       +-- "brick":    tilemap.erase_cell(tile_coords) + queue_free()
  |   |       +-- "steel":    can_destroy_steel ? erase_cell + queue_free() : queue_free()
  |   |       +-- "boundary": queue_free()
  |   |       +-- _:          queue_free()
  |   +-- 否: 原有逻辑（组检测等）
  +-- body 是其他物理体?
      +-- 原有逻辑（敌人 HurtArea 等）
```

**实现代码**:

```gdscript
func _handle_tilemap_collision(tilemap: TileMapLayer) -> void:
    var tile_coords := tilemap.local_to_map(global_position)
    var tile_data := tilemap.get_cell_tile_data(tile_coords)
    if tile_data == null:
        queue_free()
        return

    var tile_type: String = tile_data.get_custom_data("tile_type")
    match tile_type:
        "brick":
            tilemap.erase_cell(tile_coords)
            queue_free()
        "steel":
            if can_destroy_steel:
                tilemap.erase_cell(tile_coords)
            queue_free()
        "boundary":
            queue_free()
        _:
            queue_free()
```

---

## 4. TileMap 配置

### 4.1 场景层级结构

```
Level (Node2D)
+-- BackgroundLayer (TileMapLayer)    # 背景装饰（可选）
+-- GroundLayer (TileMapLayer)        # 地面（草地、沙地、道路）
+-- WaterLayer (TileMapLayer)         # 水域层
+-- IceLayer (TileMapLayer)           # 冰面层
+-- WallLayer (TileMapLayer)          # 墙壁层（砖墙、钢墙）
+-- BoundaryLayer (TileMapLayer)      # 边界墙层
+-- GrassLayer (TileMapLayer)         # 草地层（渲染层级更高）
+-- EntitiesLayer (Node2D)            # 坦克、道具
+-- BulletLayer (Node2D)              # 子弹容器
+-- UI (CanvasLayer)                  # UI 层
```

### 4.2 TileSet 资源清单

| 文件 | 用途 | 包含瓦片 | Physics Layer | Custom Data |
|------|------|---------|--------------|-------------|
| `TerrainTileset.tres` | 砖墙+钢墙+边界 | brick, steel, boundary | 0:TERRAIN(16), 1:BOUNDARY(32) | tile_type: String |
| `WaterTileset.tres` | 水域 | water | 0:BOUNDARY(32) | tile_type: String |

### 4.3 瓦片 Physics Layer 映射

| 瓦片类型 | Physics Layer 0 (TERRAIN=16) | Physics Layer 1 (BOUNDARY=32) | 碰撞形状 | Custom Data |
|---------|-----------------------------|------------------------------|---------|-------------|
| 砖墙 | 启用 | 禁用 | RectangleShape2D 32x32 | tile_type="brick" |
| 钢墙 | 启用 | 禁用 | RectangleShape2D 32x32 | tile_type="steel" |
| 边界 | 启用 | 禁用 | RectangleShape2D 32x32 | tile_type="boundary" |
| 水域 | 禁用 | 启用 (WaterTileset) | RectangleShape2D 32x32 | tile_type="water" |

### 4.4 瓦片视觉

| 瓦片 | 图片资源 | 占位色（如无图片） |
|------|---------|-----------------|
| 砖墙 | `assets/images/tiles/brick_wall.png` | 棕色 (Color(0.6, 0.4, 0.2)) |
| 钢墙 | `assets/images/tiles/steel_wall.png` | 灰色 (Color(0.7, 0.7, 0.75)) |
| 边界 | `assets/images/tiles/boundary.png` | 深色 (Color(0.2, 0.2, 0.2)) |
| 水域 | `assets/images/Retina/water/water2-4.png` | 蓝色 |

---

## 5. 碰撞配置变更

根据 ADR-001，以下碰撞配置需修改:

| 实体 | 修改前 mask | 修改后 mask | 原因 |
|------|-----------|-----------|------|
| 玩家子弹 | TERRAIN\|ENEMY\|BOUNDARY (50) | TERRAIN\|ENEMY (18) | 边界改用 TERRAIN 层，移除 BOUNDARY 避免被水域阻挡 |
| 敌人子弹 | TERRAIN\|BOUNDARY\|PLAYER\|BASE (113) | TERRAIN\|PLAYER\|BASE (81) | 同上 |

> 坦克 mask 不变: `TERRAIN | BOUNDARY | ...`，坦克仍需被水域 (LAYER_BOUNDARY) 阻挡。

---

## 6. TankTest.tscn 测试场景布局

```
+---------------------------------------------+
| E     E                  E          |  <- 敌人生成区域（3个位置）
|                                     |
|   BBB   BBBB   BBBB   BBB          |  <- 砖墙区域（可破坏掩体）
|                                     |
|      SSSSSSSS   SSSSSSSS           |  <- 钢墙区域（需 Lv.3 破坏）
|                                     |
|   ~~~   ~~~~   ~~~~               |  <- 水域区域（不可通过）
|                                     |
|          BBBBBBBB                   |  <- 基地保护砖墙
|            [Base]                   |  <- 基地
|   P1          P2                    |  <- 玩家出生点
+---------------------------------------------+

B = 砖墙  S = 钢墙  ~ = 水域  E = 敌人  P = 玩家
```

**场景节点结构**:

```
TankTest (Node2D)
+-- BoundaryIndicator (Line2D)       -- 战场边框指示
+-- GroundLayer (TileMapLayer)        -- 地面瓦片
+-- WaterLayer (TileMapLayer)         -- 水域瓦片
+-- WallLayer (TileMapLayer)          -- 砖墙+钢墙瓦片
+-- BoundaryLayer (TileMapLayer)      -- 边界墙瓦片
+-- GrassLayer (TileMapLayer)         -- 草地瓦片（P2 可选）
+-- Base (Base 场景实例)              -- 基地实体
+-- Player1Tank (Player1Tank 实例)    -- 玩家1
+-- Player2Tank (Player2Tank 实例)    -- 玩家2
+-- BasicEnemyTank (BasicEnemyTank 实例) -- 基础敌人
+-- ChaseEnemyTank (ChaseEnemyTank 实例) -- 追踪敌人
+-- Camera2D (Camera2D)              -- 摄像机
```

---

## 7. 实现顺序

```
Step 1: TileSet 资源配置
  +-- 配置 TerrainTileset (砖墙+钢墙+边界瓦片, Physics Layer, Custom Data)
  +-- 配置 WaterTileset (水域瓦片, Physics Layer, Custom Data)

Step 2: 战场边界
  +-- 在 BoundaryLayer 绘制 48 个边界瓦片
  +-- 修改 Bullet.gd 移除 viewport 检测，添加 _handle_tilemap_collision()
  +-- 修改子弹 collision_mask (移除 LAYER_BOUNDARY)

Step 3: 砖墙与钢墙
  +-- 在 WallLayer 绘制砖墙和钢墙布局
  +-- 验证子弹-地形交互 (摧毁砖墙、钢墙判断)

Step 4: 水域
  +-- 配置 WaterTileset 的 Physics Layer 和 Custom Data
  +-- 在 WaterLayer 绘制水域
  +-- 验证坦克被阻挡、子弹穿越

Step 5: 基地（P2）
  +-- 创建 Base 场景和脚本
  +-- 放置基地和保护砖墙

Step 6: 草地（P2）
  +-- 配置草地瓦片
  +-- 调整 AI 追踪逻辑
```

---

## 8. 已知风险

| 编号 | 风险 | 影响 | 缓解措施 |
|------|------|------|---------|
| R-1 | 子弹高速移动时 `global_position` 可能不在精确碰撞瓦片上 | 子弹跳格，碰撞检测失败 | 后续验证，必要时改用射线检测回退方案 |
| R-2 | 多发子弹同时击中同一瓦片 | `erase_cell()` 被多次调用或第二发子弹找不到瓦片 | `get_cell_tile_data()` 返回 null 时直接 `queue_free()` |
| R-3 | 边界瓦片使用 TERRAIN 层而非 BOUNDARY 层，语义略有偏差 | 代码可读性降低 | 通过 `tile_type` Custom Data 补偿语义 |

---

## 9. 验收检查清单

### 边界

- [ ] 玩家坦克无法移出战场边界
- [ ] 敌人坦克无法移出战场边界
- [ ] 玩家子弹在边界处销毁
- [ ] 敌人子弹在边界处销毁
- [ ] 子弹不会卡在边界外

### 砖墙

- [ ] 玩家子弹击中砖墙 -> 砖墙消失，子弹消失
- [ ] 敌人子弹击中砖墙 -> 砖墙消失，子弹消失
- [ ] 多发子弹同时击中不崩溃

### 钢墙

- [ ] Lv.1/2 子弹击中钢墙 -> 子弹消失，钢墙不损
- [ ] Lv.3 子弹击中钢墙 -> 钢墙消失，子弹消失

### 水域

- [ ] 坦克无法穿越水域
- [ ] 子弹可以飞越水域

### 碰撞整体

- [ ] 坦克与墙壁碰撞正常
- [ ] 子弹与墙壁碰撞正常
- [ ] 碰撞无穿透/卡墙现象
- [ ] 无控制台报错
- [ ] 碰撞性能正常（无明显卡顿）

---

*本文档为地形系统开发的权威需求来源，合并自 Sprint 1 PRD 地形相关需求和地形系统设计文档。*
