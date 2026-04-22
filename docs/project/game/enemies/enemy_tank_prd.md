# 敌人坦克系统需求文档

## 文档信息
- **创建日期**: 2026-04-22
- **版本**: v1.0
- **状态**: 部分已实现

---

## 1. 系统概述

### 1.1 设计目标
敌人坦克系统是游戏对抗核心，提供多种 AI 行为的敌人类型，通过基类继承架构实现代码复用和灵活扩展，为玩家提供持续的挑战和战术多样性。

### 1.2 核心特点
- **基类继承架构**: EnemyTankBase 提供通用框架，子类专注行为差异
- **Timer 驱动 AI**: 基于 `_on_decision_tick()` 的定时决策机制
- **四方向移动**: 上下左右四方向移动，与玩家坦克保持一致
- **可扩展设计**: 预留追踪、视线、射击等接口，支持快速扩展新类型

---

## 2. 敌人类型定义

### 2.1 BasicEnemyTank - 基础敌人

| 属性 | 值 | 状态 |
|------|-----|------|
| 生命值 | 1 | ✅ |
| 充能值 | 10 | ✅ |
| AI 行为 | 随机巡逻 | ✅ |
| 决策间隔 | 2.0 秒 | ✅ |
| 碰撞层 | LAYER_ENEMY | ✅ |
| 碰撞遮罩 | TERRAIN \| BOUNDARY \| ENEMY \| PLAYER | ✅ |

**行为描述**:
- 每隔 `decision_interval` 秒随机选择一个方向移动
- 无主动攻击能力（当前版本）
- 遇到障碍物或边界时由碰撞物理阻止移动
- 被击杀后发射 `enemy_killed` 事件，攻击者获得充能

### 2.2 ChaseEnemyTank - 追踪型敌人

| 属性 | 值 | 状态 |
|------|-----|------|
| 生命值 | 2 | ❌ |
| 充能值 | 30 | ❌ |
| AI 行为 | 范围内追踪玩家，范围外随机巡逻 | ❌ |
| 追踪范围 | 250 像素 | ❌ |
| 决策间隔 | 1.5 秒 | ❌ |
| 碰撞层 | LAYER_ENEMY | ❌ |
| 碰撞遮罩 | TERRAIN \| BOUNDARY \| ENEMY \| PLAYER | ❌ |

**行为描述**:
- 每个决策 tick 查找 `"player_tanks"` 组中最近的玩家
- 玩家在 `chase_range` 范围内：向玩家方向移动
- 玩家超出范围或无玩家：随机巡逻（复用基类逻辑）
- 方向决策取主分量轴（abs(x) > abs(y) 取水平，否则取垂直）

### 2.3 PatrolEnemyTank - 巡逻型敌人

| 属性 | 值 | 状态 |
|------|-----|------|
| 生命值 | 2 | ❌ |
| 充能值 | 20 | ❌ |
| AI 行为 | 沿预设巡逻点循环移动 | ❌ |
| 巡逻点 | 可配置 Array[Vector2] | ❌ |
| 到达判定距离 | 10 像素 | ❌ |
| 决策间隔 | 1.0 秒 | ❌ |
| 碰撞层 | LAYER_ENEMY | ❌ |
| 碰撞遮罩 | TERRAIN \| BOUNDARY \| ENEMY \| PLAYER | ❌ |

**行为描述**:
- 沿 `patrol_points` 列表循环移动
- 到达巡逻点（距离 < 10px）后切换到下一个
- 巡逻点列表为空时退化为随机巡逻
- 到达最后一个点后循环回到第一个点

---

## 3. 基类功能需求

### 3.1 碰撞配置

| 配置项 | 值 | 状态 |
|--------|-----|------|
| 碰撞层 | LAYER_ENEMY | ✅ |
| 碰撞遮罩 | LAYER_TERRAIN \| LAYER_BOUNDARY \| LAYER_ENEMY \| LAYER_PLAYER | ✅ |

### 3.2 移动系统

| 属性 | 类型 | 默认值 | 说明 | 状态 |
|------|------|--------|------|------|
| decision_interval | float | 2.0 | AI 决策间隔（秒） | ✅ |
| enable_autonomous_movement | bool | true | 是否启用自主移动 | ✅ |
| current_move_direction | enum | DOWN | 当前移动方向 | ✅ |

**方向枚举**: `MoveDirection { UP, DOWN, LEFT, RIGHT }`

**核心方法**:

| 方法 | 说明 | 状态 |
|------|------|------|
| `_update_movement()` | 更新移动（子类可重写） | ✅ |
| `_get_move_direction_vector()` | 获取方向向量 | ✅ |
| `_change_direction_randomly()` | 随机改变方向 | ✅ |

### 3.3 AI 决策框架

| 组件 | 说明 | 状态 |
|------|------|------|
| DirectionTimer (Timer) | 驱动决策 tick | ✅ |
| `_on_decision_tick()` | 决策回调（子类重写） | ✅ |

**决策流程**:
1. DirectionTimer 超时触发 `_on_decision_tick()`
2. 基类默认实现：若 `enable_autonomous_movement` 为 true，调用 `_change_direction_randomly()`
3. 子类重写 `_on_decision_tick()` 实现自定义 AI 行为

### 3.4 生命与死亡

| 属性/方法 | 说明 | 状态 |
|-----------|------|------|
| max_hp | 最大生命值 | ✅ |
| current_hp | 当前生命值 | ✅ |
| take_damage(damage, attacker) | 受伤处理 | ✅ |
| die() | 死亡处理 | ✅ |
| last_attacker | 记录最后攻击者（用于击杀归属） | ✅ |
| charge_value | 携带的充能值 | ✅ |
| energy_core_drop_chance | 能量核心掉落概率 | ✅ |

**死亡流程**:
1. current_hp 降为 0 时调用 `die()`
2. 发射 `EventBus.enemy_killed.emit(self, last_attacker)`
3. 攻击者获得 `charge_value` 充能点数
4. （预留）能量核心掉落

---

## 4. 预留接口（待实现）

### 4.1 玩家追踪

| 属性/方法 | 类型 | 说明 | 状态 |
|-----------|------|------|------|
| target_player | Tank | 当前追踪目标 | ❌ |
| chase_range | float | 追踪触发距离 | ❌ |
| _find_nearest_player() | func | 查找最近玩家 | ❌ |

**需求描述**:
- 在 `"player_tanks"` 组中搜索最近玩家
- 返回最近的 Tank 实例或 null
- 供 ChaseEnemyTank 等追踪型敌人使用

### 4.2 视线检测

| 属性/方法 | 类型 | 说明 | 状态 |
|-----------|------|------|------|
| line_of_sight | RayCast2D | 视线射线节点 | ❌ |
| _has_line_of_sight(target) | func | 检测到目标是否有视线 | ❌ |

**需求描述**:
- 使用 RayCast2D 检测到目标的直线路径是否被墙体遮挡
- 影响射击决策：视线外不攻击
- 影响追踪决策：视线内优先追踪

### 4.3 射击功能

| 属性/方法 | 类型 | 说明 | 状态 |
|-----------|------|------|------|
| fire_cooldown | float | 射击冷却时间 | ❌ |
| can_fire | bool | 当前是否可射击 | ❌ |
| bullet_spawner | Node | 子弹生成器 | ❌ |
| fire() | func | 发射子弹 | ❌ |

**需求描述**:
- 敌人坦克朝自身朝向发射子弹
- 子弹碰撞层为 LAYER_ENEMY_BULLET
- 子弹碰撞遮罩检测 LAYER_PLAYER \| LAYER_TERRAIN \| LAYER_BOUNDARY
- 射击受冷却时间限制
- 射击决策由 AI 行为控制

---

## 5. 场景结构

### 5.1 EnemyTankBase 场景

```
EnemyTankBase (CharacterBody2D)
├── CollisionShape2D
├── TankBody (AnimatedSprite2D)
├── TrackLeft (AnimatedSprite2D)
├── TrackRight (AnimatedSprite2D)
└── DirectionTimer (Timer)
```

### 5.2 扩展场景所需节点

| 敌人类型 | 需额外添加的节点 |
|----------|-----------------|
| ChaseEnemyTank | 无（追踪逻辑纯代码） |
| 具备射击能力的敌人 | BulletSpawner 节点 |
| 具备视线检测的敌人 | RayCast2D (LineOfSight) 节点 |

---

## 6. 实现优先级

### P0 - 已完成

| 功能 | 状态 |
|------|------|
| EnemyTankBase 基类（移动、AI决策框架、HP、死亡） | ✅ |
| BasicEnemyTank（随机巡逻） | ✅ |
| 碰撞配置 | ✅ |
| EventBus 事件集成 | ✅ |

### P1 - 高优先级

| 功能 | 状态 | 说明 |
|------|------|------|
| 射击功能 | ❌ | 敌人需要能攻击玩家 |
| _find_nearest_player() | ❌ | 追踪型敌人前置依赖 |
| ChaseEnemyTank | ❌ | 增加战术多样性 |
| 能量核心掉落 | ❌ | 充能机制闭环 |

### P2 - 中优先级

| 功能 | 状态 | 说明 |
|------|------|------|
| 视线检测 | ❌ | 提升 AI 智能感 |
| PatrolEnemyTank | ❌ | 丰富敌人类型 |
| 射击冷却管理 | ❌ | 控制敌人火力密度 |

### P3 - 低优先级

| 功能 | 状态 | 说明 |
|------|------|------|
| 敌人视觉资源 | ❌ | 专属精灵图区分类型 |
| TurretEnemyTank (炮塔型) | ❌ | 固定位置旋转射击 |
| BossTank (Boss 型) | ❌ | 高血量多阶段 |

---

## 附录：设计决策说明

### A. 为什么采用基类继承而非组件组合？
坦克大战的敌人类型差异主要体现在 AI 行为上，移动、碰撞、生命值等逻辑高度一致。继承架构在行为差异维度清晰时更直观，且 GDScript 对继承支持良好。若未来行为维度增多（如同时需要追踪+巡逻+炮塔），可引入组合模式重构。

### B. 为什么 AI 决策使用 Timer 而非 _process()？
- 性能：避免每帧执行决策逻辑
- 可配置：不同敌人类型可通过 `decision_interval` 调整决策频率
- 可控：Timer 可暂停/恢复，便于实现暂停游戏等功能
- 经典感：定时决策模拟经典坦克大战中敌人的"顿挫感"

### C. 为什么追踪型敌人使用主分量轴方向而非连续方向？
保持与经典坦克大战一致的四方向移动风格，同时简化碰撞检测和地图交互逻辑。连续方向移动在网格化地图中会导致对齐问题。
