# 地形与边界系统设计文档

## 概述

本文档详细定义坦克大战游戏的地形系统（砖墙、钢墙、草地、水域、冰面）和边界系统设计，解决当前存在的边界问题，并提供完整的实施计划。

**相关文档**:
- [项目架构总览](./project_structure.md)
- [碰撞系统设计](./collision_system_design.md)

---

## 1. 问题诊断

### 1.1 当前问题

#### 问题1: 坦克可以移动到绘制边界之外

**现象**: 玩家坦克可以跑出 `BoundaryIndicator` (Line2D) 标识的战场范围

**根本原因**:
- `Tank.gd` 的 `collision_mask` 包含 `LAYER_BOUNDARY`
- 但 `TankTest.tscn` 的 `BoundaryLayer` (TileMapLayer) 没有配置碰撞形状
- `BoundaryIndicator` 只是一个 Line2D，不参与物理碰撞

**相关代码**:
```gdscript
# scripts/entities/tanks/Tank.gd:30
@export var collision_mask_types: int = CollisionLayersClass.LAYER_TERRAIN | \
                                        CollisionLayersClass.LAYER_BOUNDARY | \
                                        CollisionLayersClass.LAYER_PLAYER
```

#### 问题2: 子弹无法穿透左侧外围

**现象**: 玩家子弹在左侧边界外被阻挡

**根本原因**:
```gdscript
# scripts/weapons/Bullet.gd:48-51
func _process(delta: float) -> void:
    position += direction * speed * delta

    # 超出屏幕范围则销毁
    var viewport_rect := get_viewport_rect()
    if not viewport_rect.has_point(position):
        queue_free()
```

问题分析:
- 使用 `get_viewport_rect()` 获取的是视口矩形，可能包含 UI 区域
- 战场实际范围是 416x416 像素 (13x13 网格)
- 左侧边界可能存在未配置的碰撞体

---

## 2. 战场范围定义

### 2.1 标准战场尺寸

**经典坦克大战标准**: 13x13 网格

**当前测试场景** (`TankTest.tscn`):
- 网格大小: 32x32 像素
- 战场范围: 416x416 像素 (13x13)
- 边界坐标: (0,0) → (416,0) → (416,416) → (0,416) → (0,0)

### 2.2 边界布局

**推荐方案**: 边界墙占用外围一圈

```
战场网格布局 (13x13):
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
. = 活动区域 (可放置地形元素)
```

**实际可活动区域**: 11x11 网格 (352x352 像素)

---

## 3. 地形系统设计

### 3.1 砖墙 (Brick Wall)

#### 属性定义

```gdscript
class_name BrickWall
extends StaticBody2D

const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")

## 生命值
@export var health: int = 1

## 精灵节点
@onready var sprite: Sprite2D = $Sprite2D
```

#### 碰撞配置

```gdscript
func _ready() -> void:
    # 配置碰撞层
    collision_layer = CollisionLayersClass.LAYER_TERRAIN
    collision_mask = 0

    # 添加到组
    add_to_group("terrain")
    add_to_group("brick_wall")
```

#### 行为逻辑

```gdscript
## 受到伤害
func take_damage(amount: int, _source: Node) -> void:
    health -= amount
    if health <= 0:
        destroy()

## 销毁砖墙
func destroy() -> void:
    # TODO: 播放碎裂动画/特效
    # TODO: 实例化爆炸特效

    # 发送事件
    EventBus.terrain_destroyed.emit(self)

    # 销毁节点
    queue_free()
```

**特性**:
- ✅ 可被所有子弹摧毁（1发）
- ✅ 阻止坦克通过
- ✅ 子弹碰撞后销毁

---

### 3.2 钢墙 (Steel Wall)

#### 属性定义

```gdscript
class_name SteelWall
extends StaticBody2D

const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")

## 生命值
@export var health: int = 4

## 是否可被摧毁
@export var indestructible: bool = false
```

#### 碰撞配置

```gdscript
func _ready() -> void:
    collision_layer = CollisionLayersClass.LAYER_TERRAIN
    collision_mask = 0

    add_to_group("terrain")
    add_to_group("steel_wall")
```

#### 行为逻辑

```gdscript
## 受到伤害
func take_damage(amount: int, source: Node) -> void:
    if indestructible:
        return

    # 只有特殊子弹才能造成伤害
    if source is Bullet and source.can_destroy_steel:
        health -= amount
        if health <= 0:
            destroy()
    else:
        # 普通子弹：播放反弹音效
        pass

## 销毁钢墙
func destroy() -> void:
    # TODO: 播放金属碎裂特效
    EventBus.terrain_destroyed.emit(self)
    queue_free()
```

**特性**:
- ✅ 普通子弹反弹并销毁
- ✅ 增强子弹可摧毁（需要 `can_destroy_steel=true`）
- ✅ 阻止坦克通过

---

### 3.3 草地 (Grass)

#### 属性定义

```gdscript
class_name Grass
extends Node2D  # 注意：不是物理节点
```

#### 行为逻辑

草地不参与物理碰撞，只影响渲染层级：

**实现方案A: YSort 排序**

```gdscript
func _ready() -> void:
    # 草地在坦克上层渲染
    z_index = 1
    z_as_relative = false
```

**实现方案B: 遮罩效果**

当坦克进入草地时：
1. 坦克本体渲染层级降低
2. 草地在坦克上层渲染
3. 视觉效果：坦克被草地遮挡

**特性**:
- ✅ 坦克可穿过
- ✅ 子弹可穿过
- ✅ 提供隐蔽效果（坦克被遮挡）

---

### 3.4 水域 (Water)

#### 属性定义

```gdscript
class_name Water
extends Area2D

const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")

## 动画播放器
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## 上一个有效位置缓存
var _last_valid_positions: Dictionary = {}
```

#### 碰撞配置

```gdscript
func _ready() -> void:
    # 配置碰撞层（视为不可通过地形）
    collision_layer = CollisionLayersClass.LAYER_TERRAIN
    collision_mask = CollisionLayersClass.LAYER_PLAYER | CollisionLayersClass.LAYER_ENEMY

    add_to_group("terrain")
    add_to_group("water")

    # 连接信号
    body_entered.connect(_on_body_entered)

    # 播放水面动画
    if animation_player:
        animation_player.play("ripple")
```

#### 行为逻辑

```gdscript
## 坦克试图进入水域
func _on_body_entered(body: Node2D) -> void:
    if body is Tank:
        # 方案1: 阻止进入
        _block_tank_entry(body)

        # 方案2: 允许进入但持续伤害（可选）
        # _apply_water_damage(body)

## 阻止坦克进入水域
func _block_tank_entry(tank: Tank) -> void:
    # 获取坦克进入前的位置
    var last_pos = _last_valid_positions.get(tank.get_instance_id(), tank.position)

    # 将坦克推回上一个有效位置
    tank.velocity = Vector2.ZERO
    tank.position = last_pos

## 持续跟踪坦克位置
func _physics_process(_delta: float) -> void:
    # 更新所有在场内的坦克位置
    var bodies = get_overlapping_bodies()
    for body in bodies:
        if body is Tank:
            # 如果坦克在水域内，推回
            _block_tank_entry(body)
```

**特性**:
- ✅ 坦克无法通过
- ✅ 子弹可穿过
- ✅ 动态水面效果

---

### 3.5 冰面 (Ice)

#### 属性定义

```gdscript
class_name Ice
extends Area2D

const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")

## 摩擦系数 (0=无摩擦, 1=正常摩擦)
@export var friction: float = 0.0

## 原始摩擦系数缓存
var _original_frictions: Dictionary = {}
```

#### 碰撞配置

```gdscript
func _ready() -> void:
    collision_layer = 0
    collision_mask = CollisionLayersClass.LAYER_PLAYER | CollisionLayersClass.LAYER_ENEMY

    add_to_group("terrain")
    add_to_group("ice")

    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
```

#### 行为逻辑

```gdscript
## 坦克进入冰面
func _on_body_entered(body: Node2D) -> void:
    if body is Tank:
        # 缓存原始摩擦系数
        _original_frictions[body.get_instance_id()] = body.friction if "friction" in body else 1.0

        # 设置冰面摩擦
        if "friction" in body:
            body.friction = friction

## 坦克离开冰面
func _on_body_exited(body: Node2D) -> void:
    if body is Tank:
        # 恢复原始摩擦系数
        var instance_id = body.get_instance_id()
        if _original_frictions.has(instance_id):
            if "friction" in body:
                body.friction = _original_frictions[instance_id]
            _original_frictions.erase(instance_id)
```

**特性**:
- ✅ 坦克可穿过
- ✅ 子弹可穿过
- ✅ 产生滑动效果（惯性）

**滑动效果实现**:

需要在 `Tank.gd` 中添加摩擦力支持：

```gdscript
# scripts/entities/tanks/Tank.gd
## 摩擦系数 (0-1)
@export var friction: float = 1.0

func _physics_process(delta: float) -> void:
    # 应用摩擦力
    if velocity != Vector2.ZERO and direction == Vector2.ZERO:
        velocity = velocity.lerp(Vector2.ZERO, friction)

    move_and_slide()
```

---

### 3.6 边界墙 (Boundary Wall)

#### 属性定义

```gdscript
class_name BoundaryWall
extends StaticBody2D

const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")
```

#### 碰撞配置

```gdscript
func _ready() -> void:
    # 配置碰撞层
    collision_layer = CollisionLayersClass.LAYER_BOUNDARY
    collision_mask = 0

    # 添加到组
    add_to_group("boundary")
```

**特性**:
- ✅ 不可摧毁
- ✅ 阻止坦克通过
- ✅ 销毁子弹

---

## 4. TileMap 配置方案

### 4.1 场景层级结构

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

### 4.2 TileSet 资源文件

#### 墙壁 TileSet (`WallTileset.tres`)

```
Physics Layer 0:
  collision_layer = 16 (LAYER_TERRAIN)

瓦片类型:
- BrickWall: Physics Layer 0, Group: "terrain", "brick_wall"
- SteelWall: Physics Layer 0, Group: "terrain", "steel_wall"
```

#### 边界 TileSet (`BoundaryTileset.tres`)

```
Physics Layer 0:
  collision_layer = 32 (LAYER_BOUNDARY)

瓦片类型:
- BoundaryWall: Physics Layer 0, Group: "boundary"
```

#### 水域 TileSet (`WaterTileset.tres`)

当前已存在，需要确认配置：
- collision_layer = 16 (LAYER_TERRAIN)
- 添加 Area2D 监测

### 4.3 瓦片碰撞形状配置

在 TileSet 编辑器中为每个瓦片配置：

**砖墙/钢墙**:
1. 选择瓦片
2. 添加 Physics Layer 0
3. 绘制 RectangleShape2D (覆盖整个32x32瓦片)

**边界墙**:
1. 选择瓦片
2. 添加 Physics Layer 0 (对应 collision_layer = 32)
3. 绘制 RectangleShape2D

---

## 5. 边界系统实现方案

### 5.1 方案A: TileMap 边界墙

**优势**:
- 与现有 TileMap 系统一致
- 易于编辑和修改
- 视觉上统一

**实施步骤**:

1. 创建 `BoundaryTileset.tres`
2. 在 `TankTest.tscn` 的 `BoundaryLayer` 上绘制边界墙
3. 配置碰撞形状

**边界墙位置**:
- 上边界: 网格 (0,0) 到 (12,0)
- 下边界: 网格 (0,12) 到 (12,12)
- 左边界: 网格 (0,1) 到 (0,11)
- 右边界: 网格 (12,1) 到 (12,11)

### 5.2 方案B: StaticBody2D 碰撞体

**优势**:
- 性能更好（单个碰撞体）
- 边界定义明确

**实施步骤**:

1. 在 `TankTest.tscn` 添加 4 个 StaticBody2D 节点
2. 配置 CollisionShape2D (RectangleShape2D)

**边界尺寸**:
```
上边界: position=(208, -16), size=(448, 32)
下边界: position=(208, 432), size=(448, 32)
左边界: position=(-16, 208), size=(32, 448)
右边界: position=(432, 208), size=(32, 448)
```

### 5.3 推荐方案: 混合方案

**TileMap 边界墙** + **四个角点补充**

1. 使用 TileMap 绘制边界墙（视觉统一）
2. 在四个角点添加 StaticBody2D 补充碰撞

---

## 6. 子弹边界处理修复

### 6.1 当前问题代码

```gdscript
# scripts/weapons/Bullet.gd:48-51
func _process(delta: float) -> void:
    position += direction * speed * delta

    # 超出屏幕范围则销毁
    var viewport_rect := get_viewport_rect()
    if not viewport_rect.has_point(position):
        queue_free()
```

### 6.2 修复方案

**方案1: 使用战场边界常量**

```gdscript
const BATTLEFIELD_RECT := Rect2(0, 0, 416, 416)

func _process(delta: float) -> void:
    position += direction * speed * delta

    # 使用战场边界而非 viewport
    if not BATTLEFIELD_RECT.has_point(position):
        queue_free()
```

**方案2: 完全依赖碰撞检测（推荐）**

```gdscript
func _process(delta: float) -> void:
    position += direction * speed * delta

    # 移除 viewport 检测，完全依赖与 BoundaryLayer 的碰撞
    # 碰撞逻辑在 _on_body_entered 中处理
```

**推荐**: 方案2 - 统一使用碰撞系统

---

## 7. 实施计划

### Phase 1: 创建地形脚本

**优先级**: 高

**任务列表**:
- [ ] 创建 `scripts/terrain/TerrainBase.gd` (地形基类)
- [ ] 创建 `scripts/terrain/BrickWall.gd`
- [ ] 创建 `scripts/terrain/SteelWall.gd`
- [ ] 创建 `scripts/terrain/Water.gd`
- [ ] 创建 `scripts/terrain/Ice.gd`
- [ ] 创建 `scripts/terrain/BoundaryWall.gd`

### Phase 2: 配置 TileSet 资源

**优先级**: 高

**任务列表**:
- [ ] 创建 `assets/tilesets/WallTileset.tres`
  - 配置 Physics Layer 0: collision_layer = 16
  - 添加砖墙和钢墙瓦片
  - 配置碰撞形状
- [ ] 创建 `assets/tilesets/BoundaryTileset.tres`
  - 配置 Physics Layer 0: collision_layer = 32
  - 添加边界墙瓦片
- [ ] 更新 `assets/tilesets/WaterTileset.tres`
  - 确认 Area2D 配置
  - 配置 collision_layer = 16

### Phase 3: 修复边界系统

**优先级**: 高

**任务列表**:
- [ ] 在 `TankTest.tscn` 的 BoundaryLayer 绘制边界墙
- [ ] 修复 `Bullet.gd` 边界检测逻辑
  - 移除 viewport 检测
  - 依赖碰撞系统
- [ ] 测试坦克边界行为
- [ ] 测试子弹边界行为

### Phase 4: 地形元素实现

**优先级**: 中

**任务列表**:
- [ ] 在 `TankTest.tscn` 添加地形元素测试
- [ ] 实现草地隐蔽效果
- [ ] 实现水域阻挡逻辑
- [ ] 实现冰面滑动效果

### Phase 5: 场景模板

**优先级**: 低

**任务列表**:
- [ ] 创建 `scenes/levels/LevelTemplate.tscn`
- [ ] 编写关卡数据加载系统
- [ ] 创建测试关卡

---

## 8. 测试检查清单

### 8.1 边界测试

- [ ] 玩家坦克无法移出战场边界
- [ ] 敌人坦克无法移出战场边界
- [ ] 玩家子弹在边界处销毁
- [ ] 敌人子弹在边界处销毁
- [ ] 子弹不会卡在边界外

### 8.2 地形测试

- [ ] 砖墙可被子弹摧毁
- [ ] 钢墙需要增强子弹才能摧毁
- [ ] 草地不阻止坦克移动
- [ ] 水域阻止坦克进入
- [ ] 冰面产生滑动效果

### 8.3 碰撞测试

- [ ] 坦克与墙壁碰撞正常
- [ ] 子弹与墙壁碰撞正常
- [ ] 坦克之间碰撞正常
- [ ] 碰撞性能正常（无明显卡顿）

---

## 9. 参考资源

- Godot 官方文档: [TileMap](https://docs.godotengine.org/en/stable/classes/class_tilemap.html)
- Godot 官方文档: [Physics Layers](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html)
- 经典坦克大战规则: [Battle City (NES)](https://strategywiki.org/wiki/Battle_City)

---

**文档版本**: 1.0
**创建日期**: 2026-04-10
**维护者**: AI Assistant
**最后更新**: 2026-04-10
