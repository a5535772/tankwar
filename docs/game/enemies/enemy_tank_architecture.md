# 敌人坦克系统架构

本文档描述敌人坦克的基类架构设计和使用指南。

## 架构概述

敌人坦克系统采用**基类继承**架构，提供清晰的扩展点和代码复用机制。

### 继承层次

```
Tank (坦克基类)
  └── EnemyTankBase (敌人坦克基类)
        ├── BasicEnemyTank (基础敌人 - 随机巡逻)
        ├── [可扩展] ChaseEnemyTank (追踪型敌人)
        └── [可扩展] PatrolEnemyTank (巡逻型敌人)
```

---

## EnemyTankBase - 敌人坦克基类

**文件路径**: `scripts/entities/tanks/EnemyTankBase.gd`

### 设计目标

- 提供敌人坦克的通用功能框架
- 为不同 AI 行为提供扩展点
- 支持灵活配置

### 核心功能

#### 1. 碰撞配置

自动配置敌人碰撞层和遮罩：

```gdscript
# 碰撞层
collision_layer_type = LAYER_ENEMY

# 碰撞遮罩（检测目标）
collision_mask_types = LAYER_TERRAIN | LAYER_BOUNDARY | LAYER_ENEMY | LAYER_PLAYER
```

#### 2. 移动控制

提供基础的移动控制框架：

```gdscript
# 可配置属性
@export var decision_interval: float = 2.0           # AI 决策间隔（秒）
@export var enable_autonomous_movement: bool = true  # 是否启用自主移动

# 移动方向枚举
enum MoveDirection { UP, DOWN, LEFT, RIGHT }
var current_move_direction: MoveDirection = MoveDirection.DOWN

# 核心方法
func _update_movement() -> void          # 更新移动（子类可重写）
func _get_move_direction_vector() -> Vector2  # 获取方向向量
```

#### 3. AI 决策框架

使用 Timer 驱动的决策系统：

```gdscript
# Timer 节点
@onready var direction_timer: Timer = $DirectionTimer

# 决策回调（子类重写实现具体行为）
func _on_decision_tick() -> void:
    # 默认：随机改变方向
    if enable_autonomous_movement:
        _change_direction_randomly()

# 随机改变方向
func _change_direction_randomly() -> void
```

### 预留接口

为后续功能预留清晰的接口（TODO 注释）：

```gdscript
# TODO: 玩家追踪
# var target_player: Tank = null
# var chase_range: float = 300.0
# func _find_nearest_player() -> Tank

# TODO: 视线检测
# @onready var line_of_sight: RayCast2D = $LineOfSight
# func _has_line_of_sight(target: Vector2) -> bool

# TODO: 射击功能
# var fire_cooldown: float = 1.0
# var can_fire: bool = true
# @onready var bullet_spawner: BulletSpawner = $BulletSpawner
# func fire() -> void
```

### 场景结构

```
EnemyTankBase (CharacterBody2D)
├── CollisionShape2D
├── TankBody (AnimatedSprite2D)
├── TrackLeft (AnimatedSprite2D)
├── TrackRight (AnimatedSprite2D)
└── DirectionTimer (Timer)
```

---

## BasicEnemyTank - 基础敌人

**文件路径**: `scripts/entities/tanks/BasicEnemyTank.gd`

### 行为特点

- **随机巡逻**：定时随机选择方向移动
- **简单 AI**：使用基类的默认决策逻辑
- **快速实现**：无需重写复杂逻辑

### 实现代码

```gdscript
class_name BasicEnemyTank
extends "res://scripts/entities/tanks/EnemyTankBase.gd"

func _ready() -> void:
    # 可选：自定义基础属性
    # decision_interval = 2.0
    # enable_autonomous_movement = true
    super._ready()

# 示例：可重写决策逻辑
# func _on_decision_tick() -> void:
#     # 自定义 AI 行为
#     super._on_decision_tick()
```

---

## 扩展敌人类型

### 创建追踪型敌人

```gdscript
## 追踪型敌人 - 主动追踪玩家
class_name ChaseEnemyTank
extends "res://scripts/entities/tanks/EnemyTankBase.gd"

## 追踪范围
@export var chase_range: float = 300.0

## 目标玩家
var target_player: Tank = null

func _on_decision_tick() -> void:
    # 查找最近的玩家
    target_player = _find_nearest_player()

    if target_player:
        var distance := global_position.distance_to(target_player.global_position)

        # 在追踪范围内
        if distance <= chase_range:
            # 向玩家移动
            var direction_to_player := global_position.direction_to(target_player.global_position)
            current_move_direction = _vector_to_direction(direction_to_player)
        else:
            # 超出范围，随机移动
            _change_direction_randomly()
    else:
        # 没有玩家，随机移动
        _change_direction_randomly()

## 向量转方向枚举
func _vector_to_direction(vec: Vector2) -> int:
    if abs(vec.x) > abs(vec.y):
        return MoveDirection.RIGHT if vec.x > 0 else MoveDirection.LEFT
    else:
        return MoveDirection.DOWN if vec.y > 0 else MoveDirection.UP

## TODO: 实现玩家查找
func _find_nearest_player() -> Tank:
    var players := get_tree().get_nodes_in_group("player_tanks")
    if players.is_empty():
        return null

    var nearest: Tank = null
    var nearest_dist: float = INF

    for player in players:
        var dist := global_position.distance_to(player.global_position)
        if dist < nearest_dist:
            nearest_dist = dist
            nearest = player

    return nearest
```

### 创建巡逻型敌人

```gdscript
## 巡逻型敌人 - 沿固定路径巡逻
class_name PatrolEnemyTank
extends "res://scripts/entities/tanks/EnemyTankBase.gd"

## 巡逻点列表
@export var patrol_points: Array[Vector2] = []

## 当前巡逻点索引
var current_patrol_index: int = 0

func _on_decision_tick() -> void:
    if patrol_points.is_empty():
        _change_direction_randomly()
        return

    # 移动到下一个巡逻点
    var target_point := patrol_points[current_patrol_index]
    var direction := global_position.direction_to(target_point)

    # 到达巡逻点，切换到下一个
    if global_position.distance_to(target_point) < 10.0:
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
    else:
        current_move_direction = _vector_to_direction(direction)
```

---

## 配置指南

### 修改决策间隔

在场景中调整 `DirectionTimer` 的 `wait_time`，或在脚本中设置：

```gdscript
func _ready():
    decision_interval = 1.0  # 每秒决策一次
    super._ready()
```

### 禁用自主移动

```gdscript
func _ready():
    enable_autonomous_movement = false  # 完全由子类控制
    super._ready()

func _update_movement():
    # 完全自定义移动逻辑
    pass
```

---

## 后续开发计划

### 高优先级 (待实施)

- [ ] **子弹系统** ❌
  - [ ] 子弹基类和对象池
  - [ ] 坦克射击能力
  - [ ] 碰撞和伤害检测

- [ ] **玩家追踪** ❌
  - [ ] 实现 `_find_nearest_player()` 方法
  - [ ] 创建 ChaseEnemyTank 类型

### 中优先级 (待实施)

- [ ] **视线检测** ❌
  - [ ] RayCast2D 实现
  - [ ] 墙体遮挡检测
  - [ ] AI 行为调整（视线外不攻击）

- [ ] **射击功能** ❌
  - [ ] 实现 `fire()` 方法
  - [ ] 冷却时间管理

### 低优先级 (待实施)

- [ ] **敌人视觉资源** ❌
  - [ ] 创建专门的敌人坦克精灵图
  - [ ] 不同颜色/样式区分不同类型

- [ ] **更多敌人类型** ❌
  - [ ] PatrolEnemyTank (巡逻型)
  - [ ] TurretEnemyTank (炮塔型)
  - [ ] BossTank (Boss 型)

---

**状态说明**: ❌ = 未实施, ✅ = 已完成

---

## 参考文档

- [GDScript 风格指南](../CONTRIBUTING.md#代码风格规范)
- [AI 工作记录](../ai2ai/AI2AI.md)
- [项目架构](../game/architecture/project_structure.md)
