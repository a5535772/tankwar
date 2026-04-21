# 碰撞系统设计文档

## 概述

本文档详细定义坦克大战游戏的碰撞层系统，包括碰撞层常量、碰撞关系矩阵、以及各实体的碰撞配置。

**相关文档**:
- [项目架构总览](./project_structure.md)
- [地形与边界系统设计](./terrain_boundary_design.md)

---

## 1. 碰撞层常量定义

### 1.1 碰撞层枚举

```gdscript
# scripts/systems/CollisionLayers.gd
class_name CollisionLayers

## 玩家坦克层（包括玩家1和玩家2）
const LAYER_PLAYER: int = 1 << 0  # 二进制: 00000001, 十进制: 1

## 敌人坦克层
const LAYER_ENEMY: int = 1 << 1   # 二进制: 00000010, 十进制: 2

## 玩家炮弹层
const LAYER_PLAYER_BULLET: int = 1 << 2  # 二进制: 00000100, 十进制: 4

## 敌人炮弹层
const LAYER_ENEMY_BULLET: int = 1 << 3   # 二进制: 00001000, 十进制: 8

## 地形层（TileMap 中的墙壁、障碍物）
const LAYER_TERRAIN: int = 1 << 4        # 二进制: 00010000, 十进制: 16

## 边界墙层（战场边界）
const LAYER_BOUNDARY: int = 1 << 5       # 二进制: 00100000, 十进制: 32

## 基地层（需保护的基地）
const LAYER_BASE: int = 1 << 6           # 二进制: 01000000, 十进制: 64

## 道具层
const LAYER_POWERUP: int = 1 << 7        # 二进制: 10000000, 十进制: 128
```

### 1.2 层级用途说明

| 层级 | 名称 | 用途 | 节点类型 |
|------|------|------|----------|
| 1 | PLAYER | 玩家坦克（1P、2P） | CharacterBody2D |
| 2 | ENEMY | 敌人坦克 | CharacterBody2D |
| 3 | PLAYER_BULLET | 玩家发射的子弹 | Area2D |
| 4 | ENEMY_BULLET | 敌人发射的子弹 | Area2D |
| 5 | TERRAIN | 砖墙、钢墙等障碍物 | StaticBody2D / TileMap |
| 6 | BOUNDARY | 战场边界墙 | StaticBody2D / TileMap |
| 7 | BASE | 基地（老鹰） | Area2D / StaticBody2D |
| 8 | POWERUP | 道具（护盾、加速等） | Area2D |

---

## 2. 碰撞关系矩阵

### 2.1 玩家坦克

**collision_layer**: `LAYER_PLAYER` (1)

**collision_mask**: `LAYER_TERRAIN | LAYER_BOUNDARY | LAYER_ENEMY | LAYER_POWERUP` (16 | 32 | 2 | 128 = 178)

**检测对象**:
- ✅ 地形（墙壁）
- ✅ 边界墙
- ✅ 敌人坦克（阻止通过）
- ✅ 道具（拾取）

**不检测**:
- ❌ 敌人子弹（通过 Area2D 伤害检测处理）
- ❌ 玩家子弹
- ❌ 基地

### 2.2 敌人坦克

**collision_layer**: `LAYER_ENEMY` (2)

**collision_mask**: `LAYER_TERRAIN | LAYER_BOUNDARY | LAYER_PLAYER | LAYER_BASE` (16 | 32 | 1 | 64 = 113)

**检测对象**:
- ✅ 地形（墙壁）
- ✅ 边界墙
- ✅ 玩家坦克（阻止通过）
- ✅ 基地（触发游戏失败）

**不检测**:
- ❌ 玩家子弹（通过 Area2D 伤害检测处理）
- ❌ 敌人子弹
- ❌ 道具

### 2.3 玩家子弹

**collision_layer**: `LAYER_PLAYER_BULLET` (4)

**collision_mask**: `LAYER_TERRAIN | LAYER_BOUNDARY | LAYER_ENEMY` (16 | 32 | 2 = 50)

**检测对象**:
- ✅ 地形（砖墙可摧毁，钢墙反弹）
- ✅ 边界墙（销毁子弹）
- ✅ 敌人坦克（造成伤害）

**不检测**:
- ❌ 玩家坦克（不误伤）
- ❌ 敌人子弹（可能互相抵消，待定）
- ❌ 基地

### 2.4 敌人子弹

**collision_layer**: `LAYER_ENEMY_BULLET` (8)

**collision_mask**: `LAYER_TERRAIN | LAYER_BOUNDARY | LAYER_PLAYER | LAYER_BASE` (16 | 32 | 1 | 64 = 113)

**检测对象**:
- ✅ 地形
- ✅ 边界墙
- ✅ 玩家坦克（造成伤害）
- ✅ 基地（可摧毁基地）

**不检测**:
- ❌ 敌人坦克
- ❌ 玩家子弹

### 2.5 地形元素

**collision_layer**: `LAYER_TERRAIN` (16)

**collision_mask**: `0`（不检测其他物体）

**类型**:
- 砖墙 (BrickWall)
- 钢墙 (SteelWall)

### 2.6 边界墙

**collision_layer**: `LAYER_BOUNDARY` (32)

**collision_mask**: `0`（不检测其他物体）

### 2.7 基地

**collision_layer**: `LAYER_BASE` (64)

**collision_mask**: `0` 或 `LAYER_ENEMY`（检测敌人碰撞）

### 2.8 道具

**collision_layer**: `LAYER_POWERUP` (128)

**collision_mask**: `LAYER_PLAYER`（检测玩家拾取）

---

## 3. 碰撞关系总览表

| 实体类型 | collision_layer | collision_mask | 检测对象 |
|---------|----------------|----------------|---------|
| 玩家坦克 | PLAYER (1) | TERRAIN\|BOUNDARY\|ENEMY\|POWERUP (178) | 墙、边界、敌人、道具 |
| 敌人坦克 | ENEMY (2) | TERRAIN\|BOUNDARY\|PLAYER\|BASE (113) | 墙、边界、玩家、基地 |
| 玩家子弹 | PLAYER_BULLET (4) | TERRAIN\|BOUNDARY\|ENEMY (50) | 墙、边界、敌人 |
| 敌人子弹 | ENEMY_BULLET (8) | TERRAIN\|BOUNDARY\|PLAYER\|BASE (113) | 墙、边界、玩家、基地 |
| 砖墙 | TERRAIN (16) | 0 | 无 |
| 钢墙 | TERRAIN (16) | 0 | 无 |
| 边界墙 | BOUNDARY (32) | 0 | 无 |
| 基地 | BASE (64) | 0 或 ENEMY (2) | 敌人（可选） |
| 道具 | POWERUP (128) | PLAYER (1) | 玩家 |

---

## 4. 实体碰撞配置代码

### 4.1 玩家坦克

```gdscript
# scripts/entities/tanks/Tank.gd
const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")

@export var collision_layer_type: int = CollisionLayersClass.LAYER_PLAYER
@export var collision_mask_types: int = CollisionLayersClass.LAYER_TERRAIN | \
                                        CollisionLayersClass.LAYER_BOUNDARY | \
                                        CollisionLayersClass.LAYER_ENEMY | \
                                        CollisionLayersClass.LAYER_POWERUP

func _ready() -> void:
    collision_layer = collision_layer_type
    collision_mask = collision_mask_types
```

### 4.2 敌人坦克

```gdscript
# scripts/entities/tanks/EnemyTankBase.gd
func _ready() -> void:
    super._ready()

    # 覆盖碰撞配置
    collision_layer = CollisionLayersClass.LAYER_ENEMY
    collision_mask = CollisionLayersClass.LAYER_TERRAIN | \
                     CollisionLayersClass.LAYER_BOUNDARY | \
                     CollisionLayersClass.LAYER_PLAYER | \
                     CollisionLayersClass.LAYER_BASE
```

### 4.3 玩家子弹

```gdscript
# scripts/weapons/Bullet.gd
const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")

func _ready() -> void:
    add_to_group("bullets")

    # 玩家子弹碰撞配置
    collision_layer = CollisionLayersClass.LAYER_PLAYER_BULLET
    collision_mask = CollisionLayersClass.LAYER_TERRAIN | \
                     CollisionLayersClass.LAYER_BOUNDARY | \
                     CollisionLayersClass.LAYER_ENEMY

    # 连接碰撞信号
    body_entered.connect(_on_body_entered)
    area_entered.connect(_on_area_entered)
```

### 4.4 敌人子弹

```gdscript
# scripts/weapons/EnemyBullet.gd
extends "res://scripts/weapons/Bullet.gd"

func _ready() -> void:
    add_to_group("bullets")
    add_to_group("enemy_bullets")

    # 敌人子弹碰撞配置
    collision_layer = CollisionLayersClass.LAYER_ENEMY_BULLET
    collision_mask = CollisionLayersClass.LAYER_TERRAIN | \
                     CollisionLayersClass.LAYER_BOUNDARY | \
                     CollisionLayersClass.LAYER_PLAYER | \
                     CollisionLayersClass.LAYER_BASE
```

### 4.5 边界墙

```gdscript
# scripts/terrain/BoundaryWall.gd
class_name BoundaryWall
extends StaticBody2D

const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")

func _ready() -> void:
    collision_layer = CollisionLayersClass.LAYER_BOUNDARY
    collision_mask = 0
    add_to_group("boundary")
```

---

## 5. TileMap 碰撞配置

### 5.1 地形 TileSet 配置

在 TileSet 资源文件中配置 Physics Layer:

```
Physics Layer 0:
  collision_layer = 16 (LAYER_TERRAIN)
  collision_layer_name = "terrain"

Physics Layer 1:
  collision_layer = 32 (LAYER_BOUNDARY)
  collision_layer_name = "boundary"
```

### 5.2 瓦片碰撞形状

为每个瓦片配置碰撞形状：

**砖墙/钢墙瓦片**:
- Physics Layer: 0 (TERRAIN)
- Collision Shape: RectangleShape2D (32x32)
- 添加到组: "terrain", "brick_wall" 或 "steel_wall"

**边界墙瓦片**:
- Physics Layer: 1 (BOUNDARY)
- Collision Shape: RectangleShape2D (32x32)
- 添加到组: "boundary"

---

## 6. 特殊碰撞场景

### 6.1 子弹与地形交互

```gdscript
# scripts/weapons/Bullet.gd
func _on_body_entered(body: Node2D) -> void:
    # 碰到地形
    if body.is_in_group("terrain"):
        if body.is_in_group("brick_wall"):
            # 砖墙：销毁砖墙和子弹
            body.destroy()
            queue_free()
        elif body.is_in_group("steel_wall"):
            # 钢墙：根据子弹类型处理
            if can_destroy_steel:
                body.destroy()
            queue_free()
        else:
            queue_free()

    # 碰到边界
    elif body.is_in_group("boundary"):
        queue_free()
```

### 6.2 子弹与敌人交互

```gdscript
# scripts/weapons/Bullet.gd
func _on_area_entered(area: Area2D) -> void:
    # 碰到敌人坦克的伤害区域
    if area.is_in_group("enemy_tanks") or area.get_parent().is_in_group("enemy_tanks"):
        var enemy = area.get_parent()
        if enemy.has_method("take_damage"):
            enemy.take_damage(damage, null)
        queue_free()
```

### 6.3 玩家拾取道具

```gdscript
# scripts/powerups/PowerUp.gd
class_name PowerUp
extends Area2D

func _ready() -> void:
    collision_layer = CollisionLayersClass.LAYER_POWERUP
    collision_mask = CollisionLayersClass.LAYER_PLAYER

    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player_tanks"):
        apply_effect(body)
        queue_free()
```

---

## 7. 调试工具

### 7.1 可视化碰撞层

在 Godot 编辑器中启用碰撞形状可视化：
- 菜单: Debug → Visible Collision Shapes

### 7.2 运行时检测碰撞层

```gdscript
# 调试脚本示例
func print_collision_info(node: Node2D) -> void:
    print("节点: ", node.name)
    print("  collision_layer: ", node.collision_layer)
    print("  collision_mask: ", node.collision_mask)
    print("  Layer 名称:")
    if node.collision_layer & CollisionLayers.LAYER_PLAYER:
        print("    - PLAYER")
    if node.collision_layer & CollisionLayers.LAYER_ENEMY:
        print("    - ENEMY")
    # ... 以此类推
```

---

## 8. 常见问题

### Q1: 为什么子弹使用 Area2D 而不是 RigidBody2D？

**A**: Area2D 更适合子弹场景：
- 不需要物理模拟（重力、摩擦力）
- 只需要碰撞检测
- 性能更好
- 可以直接使用 `body_entered` 和 `area_entered` 信号

### Q2: 为什么玩家坦克不检测敌人子弹？

**A**: 伤害检测通过 Area2D 实现：
- 坦克的 HurtArea 监测子弹进入
- 子弹的 Area2D 触发伤害信号
- 避免物理碰撞导致的推动效果

### Q3: 边界墙和地形墙有什么区别？

**A**:
- **地形墙**: 位于战场内部，可被子弹摧毁（砖墙）或需要特殊子弹（钢墙）
- **边界墙**: 位于战场外围，不可摧毁，限制坦克活动范围

---

## 9. 更新日志

| 日期 | 版本 | 更新内容 |
|------|------|----------|
| 2026-04-10 | 1.0 | 初始版本，定义8个碰撞层 |

---

**文档维护者**: AI Assistant
**最后更新**: 2026-04-10
