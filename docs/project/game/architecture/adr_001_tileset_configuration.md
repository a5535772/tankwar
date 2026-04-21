# ADR-001: TileSet 配置方案 — 地形系统

## 状态
已接受

## 上下文

Sprint 1 Phase 2 需要实现地形系统（砖墙、钢墙、边界、水域）。地形使用 TileMapLayer 渲染，子弹需要与瓦片交互（摧毁砖墙、判断钢墙类型等）。

**核心问题**：
1. TileMapLayer 的 `body_entered` 回调中，`body` 是整个 TileMapLayer 节点而非单个瓦片，需要机制判断瓦片类型
2. 水域需要阻挡坦克但允许子弹穿越，与边界墙共享碰撞层需求
3. 现有 `TerrainTileset.tres` 仅有骨架定义（2个 Physics Layer），无瓦片数据和 Custom Data Layer

**当前约束**：
- 碰撞层：`LAYER_TERRAIN` = bit 4 (16), `LAYER_BOUNDARY` = bit 5 (32)
- 坦克 mask 含 `LAYER_TERRAIN | LAYER_BOUNDARY`
- 玩家子弹 mask 含 `LAYER_TERRAIN | LAYER_BOUNDARY`（当前），敌人子弹同理
- 子弹当前通过 `is_in_group()` 判断地形类型，无法适配 TileMapLayer

---

## 决策

### 1. 采用 Custom Data Layer 方案标识瓦片类型

在 TerrainTileset 中添加 **Custom Data Layer** `tile_type: String`，子弹碰撞时通过 `get_cell_tile_data().get_custom_data("tile_type")` 读取类型。

**`tile_type` 枚举值**：

| 值 | 含义 | 所在 TileSet | 所在 TileMapLayer |
|----|------|-------------|------------------|
| `"brick"` | 砖墙（可摧毁） | TerrainTileset | WallLayer |
| `"steel"` | 钢墙（Lv.3可摧毁） | TerrainTileset | WallLayer |
| `"boundary"` | 边界墙（不可摧毁） | TerrainTileset | BoundaryLayer |
| `"water"` | 水域（坦克不可入，子弹可越） | WaterTileset | WaterLayer |
| `"grass"` | 草地（隐蔽，P2延期） | TerrainTileset | GrassLayer |
| `"ice"` | 冰面（滑动，P3延期） | TerrainTileset | IceLayer |

### 2. Physics Layer 分配

**TerrainTileset** 包含 2 个 Physics Layer：

| Physics Layer ID | collision_layer 值 | 对应常量 | 用途 |
|-----------------|-------------------|---------|------|
| 0 | 16 | LAYER_TERRAIN | 砖墙、钢墙碰撞 |
| 1 | 32 | LAYER_BOUNDARY | 边界墙碰撞 |

**瓦片 → Physics Layer 映射**：

| 瓦片类型 | Physics Layer 0 (TERRAIN) | Physics Layer 1 (BOUNDARY) | 碰撞形状 |
|---------|--------------------------|---------------------------|---------|
| 砖墙 (`"brick"`) | ✅ 启用 | ❌ | RectangleShape2D 32×32 |
| 钢墙 (`"steel"`) | ✅ 启用 | ❌ | RectangleShape2D 32×32 |
| 边界 (`"boundary"`) | ❌ | ✅ 启用 | RectangleShape2D 32×32 |

**WaterTileset** 包含 1 个 Physics Layer：

| Physics Layer ID | collision_layer 值 | 对应常量 | 用途 |
|-----------------|-------------------|---------|------|
| 0 | 32 | LAYER_BOUNDARY | 水域阻挡坦克 |

### 3. 水域碰撞层方案

**决策**：水域使用 `LAYER_BOUNDARY` (bit 5 = 32) 作为碰撞层。

**验证**：

| 场景 | 水域 collision_layer = 32 | 结果 |
|------|--------------------------|------|
| 坦克碰水域 | 坦克 mask 含 LAYER_BOUNDARY(32) | ✅ 坦克被阻挡 |
| 子弹飞越水域 | 子弹 mask 不含 LAYER_BOUNDARY(32) | ✅ 子弹穿越 |
| 坦克碰边界 | 边界 collision_layer = 32 | ✅ 坦克被阻挡 |
| 子弹碰边界 | 子弹 mask 不含 LAYER_BOUNDARY(32) | ❌ 子弹不碰边界！ |

**问题**：当前子弹 mask 含 `LAYER_BOUNDARY`，如果水域也用 `LAYER_BOUNDARY`，则子弹也会被水域阻挡。

**解决方案**：子弹需要**移除** mask 中的 `LAYER_BOUNDARY`，改为通过 TileMapLayer 的 Custom Data 判断。具体为：

1. 子弹 mask 改为：`LAYER_TERRAIN`（检测砖墙/钢墙）+ `LAYER_ENEMY`（检测敌人）
2. 边界瓦片的碰撞从 Physics Layer 1 (BOUNDARY) **改为** Physics Layer 0 (TERRAIN)
3. 边界瓦片标记 `tile_type = "boundary"`，子弹通过 Custom Data 判断
4. 水域瓦片使用 `LAYER_BOUNDARY`，子弹 mask 不含此层 → 子弹穿越水域 ✅

**修正后的 Physics Layer 分配**：

| 瓦片类型 | Physics Layer 0 (TERRAIN=16) | Physics Layer 1 (BOUNDARY=32) |
|---------|-----------------------------|------------------------------|
| 砖墙 | ✅ | ❌ |
| 钢墙 | ✅ | ❌ |
| 边界 | ✅ **修正：改用TERRAIN** | ❌ |
| 水域 | ❌ | ✅ (WaterTileset) |

**子弹 mask**：`LAYER_TERRAIN | LAYER_ENEMY`（移除 LAYER_BOUNDARY）

**这样**：
- 子弹碰砖墙/钢墙/边界 → 通过 LAYER_TERRAIN 触发碰撞 → 读取 tile_type 区分处理 ✅
- 子弹碰水域 → mask 不含 LAYER_BOUNDARY → 不触发碰撞 → 穿越水域 ✅
- 坦克碰水域 → mask 含 LAYER_BOUNDARY → 被阻挡 ✅
- 坦克碰边界 → mask 含 LAYER_TERRAIN → 被阻挡 ✅

### 4. 子弹-TileMap 交互流程

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

### 5. TileSet 资源清单

| 文件 | 用途 | 包含瓦片 | Physics Layer | Custom Data |
|------|------|---------|--------------|-------------|
| `TerrainTileset.tres` | 砖墙+钢墙+边界 | brick, steel, boundary | 0:TERRAIN(16), 1:BOUNDARY(32) | tile_type: String |
| `WaterTileset.tres` | 水域 | water | 0:BOUNDARY(32) | tile_type: String |

> 注：TerrainTileset 保留 Physics Layer 1 (BOUNDARY=32) 用于未来扩展（如特殊地形需要区分碰撞层），但当前 Phase 2 的边界瓦片使用 Physics Layer 0 (TERRAIN)。

### 6. 瓦片视觉

| 瓦片 | 图片资源 | 占位色（如无图片） |
|------|---------|-----------------|
| 砖墙 | `assets/images/tiles/brick_wall.png` | 棕色 (Color(0.6, 0.4, 0.2)) |
| 钢墙 | `assets/images/tiles/steel_wall.png` | 灰色 (Color(0.7, 0.7, 0.75)) |
| 边界 | `assets/images/tiles/boundary.png` | 深色 (Color(0.2, 0.2, 0.2)) |
| 水域 | `assets/images/Retina/water/water2-4.png` | 蓝色 |

---

## 后果

### 正面
- **统一交互模型**：所有子弹-地形交互通过 Custom Data Layer + match 处理，扩展新地形类型只需加 tile_type 值
- **水域语义正确**：利用碰撞层差异实现"坦克被挡/子弹穿越"，无需额外代码
- **TileMapLayer API 兼容**：`get_cell_tile_data()` 是 Godot 4.3 推荐方式，稳定可靠

### 负面
- **边界碰撞层变更**：边界瓦片使用 TERRAIN 而非 BOUNDARY 层，语义略有偏差（但通过 tile_type 补偿）
- **子弹 mask 需修改**：移除 LAYER_BOUNDARY，依赖 LAYER_TERRAIN + tile_type 检测边界
- **WaterTileset 需补充 Custom Data Layer**：现有资源只有瓦片渲染，无碰撞和自定义数据

### 风险
- **碰撞点精度**：子弹 `global_position` 可能不在精确的碰撞瓦片上（子弹高速移动时可能跳格），需要后续验证和可能的射线检测回退方案

---

## 需修改的碰撞配置汇总

| 实体 | 当前 mask | 修改后 mask | 原因 |
|------|----------|-----------|------|
| 玩家子弹 | TERRAIN\|ENEMY\|BOUNDARY (50) | TERRAIN\|ENEMY (18) | 边界改用TERRAIN层，移除BOUNDARY避免被水域阻挡 |
| 敌人子弹 | TERRAIN\|BOUNDARY\|PLAYER\|BASE (113) | TERRAIN\|PLAYER\|BASE (81) | 同上 |

> 坦克 mask 不变：`TERRAIN | BOUNDARY | ...`，坦克仍需被水域(LAYER_BOUNDARY)阻挡。

---

*本文档为 Story 2.1 的产出，指导后续 Story 2.2-2.6 的实现。*
