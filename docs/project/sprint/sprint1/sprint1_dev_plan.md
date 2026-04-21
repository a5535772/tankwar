# Sprint 1 开发计划：核心机制验证

> **版本**: v1.0  
> **制定日期**: 2026-04-21  
> **制定者**: 项目经理  
> **PRD来源**: `docs/project/sprint/sprint1/sprint1_prd.md`  
> **验证场景**: `scenes/levels/TankTest.tscn`

---

## 0. Sprint 目标回顾

在 `TankTest.tscn` 中完成 **玩家、地图特性、敌人** 三大核心机制的功能搭建和验证。完成后，后续开发只需创作更多关卡内容，无需再修改底层机制。

---

## 1. 已完成项盘点（Sprint 1 PRD 之前已实现）

以下功能在 PRD 制定前已经开发完成，属于 Sprint 1 范围内但**无需再开发**的部分：

| # | 功能 | 对应PRD编号 | 完成状态 | 备注 |
|---|------|------------|----------|------|
| 1 | 坦克基类 Tank.gd（移动/旋转/动画/碰撞配置） | - | ✅ 已完成 | 含网格对齐、碰撞层导出 |
| 2 | PlayerTank 基类（输入框架/武器管理/HUD） | - | ✅ 已完成 | 武器管理器+HUD动态加载 |
| 3 | Player1Tank（WASD+J射击+K副武器） | - | ✅ 已完成 | |
| 4 | Player2Tank（方向键移动） | - | ✅ 已完成 | ⚠️ 缺少射击功能（TD-2） |
| 5 | EnemyTankBase 基类（AI随机巡逻/决策Timer/充能值/受伤/死亡） | - | ✅ 已完成 | take_damage中血量扣减为TODO |
| 6 | BasicEnemyTank（随机巡逻+enemy_tanks组） | - | ✅ 已完成 | |
| 7 | 主武器系统（3级升级/射击/冷却） | - | ✅ 已完成 | MainWeapon+MainWeaponData |
| 8 | 子弹基类 Bullet.gd（移动/碰撞/组检测） | 5.2部分 | 🟡 部分完成 | 缺owner_tank、TileMap适配、viewport边界检测 |
| 9 | 3种子弹场景（Basic/Fast/SteelDestroyer） | - | ✅ 已完成 | |
| 10 | 副武器系统（导弹弹幕/EMP冲击波） | - | ✅ 已完成 | MissileBarrage+EMPShockwave |
| 11 | 充能系统（获取/消耗/信号） | - | ✅ 已完成 | ChargeSystem |
| 12 | 道具系统（PowerUp基类+武器升级道具） | - | ✅ 已完成 | ⚠️ 因player_tanks组缺失，道具实际无法拾取 |
| 13 | 武器HUD（等级+充能条+副武器） | - | ✅ 已完成 | WeaponHUD |
| 14 | 碰撞层定义（8层全部定义） | - | ✅ 已完成 | CollisionLayers，但LAYER_ENEMY_BULLET/LAYER_BASE未被使用 |
| 15 | EventBus 事件总线 | - | ✅ 已完成 | 已注册为Autoload |
| 16 | 测试场景 TankTest.tscn 基础结构 | - | ✅ 已完成 | WallLayer/BoundaryLayer未配置TileSet |

---

## 2. 开发计划（Story 级别）

按PRD建议的5个Phase组织，每个Story标注**执行角色**和**优先级**。

### 角色说明

- **🏗️ 架构师**：负责技术方案设计、接口定义、架构决策。产出设计文档或代码框架。
- **💻 开发**：负责按设计文档/规格编写具体代码实现。
- **📝 PM**：负责验收检查、文档更新。

---

### Phase 1: 基础设施修复（预计 1-2 天）

#### Story 1.1: 修复玩家组注册 Bug

| 属性 | 值 |
|------|-----|
| PRD编号 | 4.4 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 0.5h |
| 状态 | ✅ 已完成 |

**描述**: PlayerTank._ready() 中添加 `add_to_group("player_tanks")`，修复道具无法拾取和追踪敌人找不到玩家的Bug。

**验收标准**:
- [x] PlayerTank._ready() 中包含 `add_to_group("player_tanks")`
- [x] PowerUp 可被玩家正常拾取
- [x] `_find_nearest_player()` 能找到玩家

**修改文件**:
- `scripts/entities/tanks/PlayerTank.gd`

---

#### Story 1.2: 修复子弹击杀者追踪 Bug

| 属性 | 值 |
|------|-----|
| PRD编号 | 5.3 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 1h |
| 状态 | ✅ 已完成 |

**描述**: Bullet 添加 `owner_tank` 属性，MainWeapon.fire() 时设置 bullet.owner_tank，_on_area_entered() 中正确传递 attacker 参数，修复充能掠夺无法识别击杀者的问题。

**验收标准**:
- [x] Bullet.gd 包含 `var owner_tank: Tank = null`
- [x] MainWeapon.fire() 中设置 `bullet.owner_tank`
- [x] _on_area_entered() 调用 `take_damage(damage, owner_tank)` 而非 `take_damage(damage, null)`
- [x] 击杀敌人后充能值正确归属到击杀者

**修改文件**:
- `scripts/weapons/Bullet.gd` — 添加 owner_tank 属性，修复 _on_area_entered()
- `scripts/weapons/MainWeapon.gd` — fire() 中设置 bullet.owner_tank

---

#### Story 1.3: 完善敌人血量系统

| 属性 | 值 |
|------|-----|
| PRD编号 | 3.1 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 1h |
| 状态 | ❌ 未开始 |

**描述**: EnemyTankBase 添加 max_hp 和 current_hp，实现 take_damage() 实际扣减血量，血量归零调用 die()。不同敌人类型可配置不同 max_hp。

**验收标准**:
- [ ] EnemyTankBase 有 `@export var max_hp: int = 1` 和 `var current_hp: int`
- [ ] _ready() 中 `current_hp = max_hp`
- [ ] take_damage() 实际扣减 current_hp，归零调用 die()
- [ ] BasicEnemyTank 默认 max_hp = 1

**修改文件**:
- `scripts/entities/enemys/EnemyTankBase.gd`
- `scripts/entities/enemys/BasicEnemyTank.gd`

---

### Phase 2: 地形系统（预计 3-5 天）

#### Story 2.1: TileSet 配置设计

| 属性 | 值 |
|------|-----|
| PRD编号 | 2.2 / 2.3 / 5.2 |
| 优先级 | P0 |
| 执行角色 | 🏗️ 架构师 |
| 预计工时 | 2h |
| 状态 | ❌ 未开始 |

**描述**: 设计 TerrainTileset 的 TileSet 配置方案，包括自定义数据层(Custom Data Layer)定义、Physics Layer 分配、瓦片类型标记策略。这是后续所有地形开发的基础。

**产出**:
- TileSet 配置方案文档（简短，可写在代码注释中）
- 确定：砖墙/钢墙/边界/水域各自的 Physics Layer 映射
- 确定：Custom Data Layer 中 `tile_type` 的枚举值
- 确定：水域碰撞层方案（PRD建议用与边界相同层bit 5）

**验收标准**:
- [ ] 方案可指导开发人员配置 TileSet
- [ ] 碰撞层方案不会导致子弹误判地形类型
- [ ] 方案具备扩展性（后续加草地/冰面无需改架构）

**参考文件**:
- PRD 5.2 方案 A（推荐方案）

---

#### Story 2.2: 配置 TerrainTileset 资源

| 属性 | 值 |
|------|-----|
| PRD编号 | 2.2 / 2.3 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 2h |
| 依赖 | Story 2.1 |
| 状态 | ❌ 未开始 |

**描述**: 根据 Story 2.1 的设计方案，在 Godot 编辑器中配置 TerrainTileset.tres：添加自定义数据层、Physics Layer、砖墙/钢墙/边界瓦片定义及碰撞形状。

**验收标准**:
- [ ] TerrainTileset.tres 包含 Custom Data Layer `tile_type`
- [ ] 砖墙瓦片标记 `tile_type = "brick"`，碰撞在 LAYER_TERRAIN(bit 4)
- [ ] 钢墙瓦片标记 `tile_type = "steel"`，碰撞在 LAYER_TERRAIN(bit 4)
- [ ] 边界瓦片标记 `tile_type = "boundary"`，碰撞在 LAYER_BOUNDARY(bit 5)
- [ ] 瓦片有占位视觉区分（砖=棕色，钢=灰色，边界=深色）

**修改文件**:
- `assets/tilesets/TerrainTileset.tres`

---

#### Story 2.3: 子弹-TileMap 碰撞交互适配

| 属性 | 值 |
|------|-----|
| PRD编号 | 5.2 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 3h |
| 依赖 | Story 2.2 |
| 状态 | ❌ 未开始 |

**描述**: 重构 Bullet.gd 的碰撞处理，适配 TileMapLayer API。当 body 是 TileMapLayer 时，通过碰撞坐标获取瓦片信息，根据 tile_type 执行不同逻辑（砖墙摧毁、钢墙判断等）。

**验收标准**:
- [ ] _on_body_entered() 能正确识别 TileMapLayer 碰撞
- [ ] _handle_tilemap_collision() 通过 get_cell_tile_data() 读取 tile_type
- [ ] brick 类型 → tilemap.erase_cell() + 子弹销毁
- [ ] steel 类型 + can_destroy_steel → tilemap.erase_cell() + 子弹销毁
- [ ] steel 类型 + !can_destroy_steel → 仅子弹销毁
- [ ] boundary 类型 → 子弹销毁
- [ ] 保留原有的非 TileMap 碰撞处理（敌人 HurtArea 等）
- [ ] 子弹边界检测从 viewport 改为战场矩形检测

**修改文件**:
- `scripts/weapons/Bullet.gd`

---

#### Story 2.4: 实现战场边界

| 属性 | 值 |
|------|-----|
| PRD编号 | 2.1 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 1.5h |
| 依赖 | Story 2.2 |
| 状态 | ❌ 未开始 |

**描述**: 在 TankTest.tscn 的 BoundaryLayer 上绘制边界瓦片，确认碰撞配置正确。子弹超出战场边界时销毁。

**验收标准**:
- [ ] BoundaryLayer 配置了 TerrainTileset，绘制了边界瓦片
- [ ] 坦克无法移出 416×416 战场
- [ ] 子弹超出战场边界后销毁
- [ ] 坦克对角线移动被边界阻挡时沿边界滑行

**修改文件**:
- `scenes/levels/TankTest.tscn`

---

#### Story 2.5: 实现砖墙

| 属性 | 值 |
|------|-----|
| PRD编号 | 2.2 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 1h |
| 依赖 | Story 2.3, 2.4 |
| 状态 | ❌ 未开始 |

**描述**: 在 TankTest.tscn 的 WallLayer 上绘制砖墙布局，验证子弹击中砖墙→砖墙摧毁。

**验收标准**:
- [ ] WallLayer 配置了 TerrainTileset，绘制了砖墙瓦片
- [ ] 子弹击中砖墙 → 瓦片从地图移除，子弹销毁
- [ ] 多发子弹同时击中同一砖墙不报错

**修改文件**:
- `scenes/levels/TankTest.tscn`

---

#### Story 2.6: 实现钢墙

| 属性 | 值 |
|------|-----|
| PRD编号 | 2.3 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 1h |
| 依赖 | Story 2.3, 2.4 |
| 状态 | ❌ 未开始 |

**描述**: 在 TankTest.tscn 的 WallLayer 上放置钢墙瓦片，验证 Lv.1/2 子弹击中钢墙消失、Lv.3 子弹击中钢墙摧毁。

**验收标准**:
- [ ] 钢墙瓦片已放置
- [ ] Lv.1/2 子弹击中钢墙 → 子弹消失，钢墙完好
- [ ] Lv.3 子弹击中钢墙 → 钢墙摧毁，子弹消失
- [ ] 钢墙视觉上与砖墙有明确区分

**修改文件**:
- `scenes/levels/TankTest.tscn`

---

### Phase 3: 敌人射击与玩家血量（预计 3-5 天）

#### Story 3.1: 创建敌人子弹

| 属性 | 值 |
|------|-----|
| PRD编号 | 5.1 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 2h |
| 依赖 | Story 2.3 |
| 状态 | ❌ 未开始 |

**描述**: 创建 EnemyBullet 场景和脚本，使用 LAYER_ENEMY_BULLET(bit 3)，碰撞检测 LAYER_PLAYER | LAYER_TERRAIN | LAYER_BOUNDARY | LAYER_BASE。击中玩家调用 take_damage，击中地形按 tile_type 处理。

**验收标准**:
- [ ] `scripts/weapons/EnemyBullet.gd` 创建完成
- [ ] `scenes/entities/weapons/bullets/EnemyBullet.tscn` 创建完成
- [ ] collision_layer = LAYER_ENEMY_BULLET (8)
- [ ] collision_mask 包含 LAYER_PLAYER | LAYER_TERRAIN | LAYER_BOUNDARY | LAYER_BASE
- [ ] 击中玩家 → player.take_damage()
- [ ] 击中砖墙 → 砖墙摧毁
- [ ] 击中钢墙 → 子弹消失（除非 can_destroy_steel）
- [ ] 击中边界 → 子弹销毁
- [ ] 视觉占位色块与玩家子弹区分（青色/紫色）

**创建文件**:
- `scripts/weapons/EnemyBullet.gd`
- `scenes/entities/weapons/bullets/EnemyBullet.tscn`

---

#### Story 3.2: 实现敌人射击能力

| 属性 | 值 |
|------|-----|
| PRD编号 | 3.2 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 3h |
| 依赖 | Story 3.1 |
| 状态 | ❌ 未开始 |

**描述**: EnemyTankBase 添加 fire() 方法和射击冷却逻辑，AI 决策中随机触发射击。将注释掉的射击相关属性启用。

**验收标准**:
- [ ] EnemyTankBase 有 `@export var fire_cooldown: float = 2.0` 和 `var can_fire: bool = true`
- [ ] fire() 方法实例化 EnemyBullet 并发射
- [ ] _on_decision_tick() 中有概率触发射击
- [ ] 射击方向为坦克当前朝向
- [ ] BasicEnemyTank 继承并使用默认射击行为

**修改文件**:
- `scripts/entities/enemys/EnemyTankBase.gd`
- `scripts/entities/enemys/BasicEnemyTank.gd`

---

#### Story 3.3: 实现玩家血量系统

| 属性 | 值 |
|------|-----|
| PRD编号 | 4.1 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 2h |
| 状态 | ❌ 未开始 |

**描述**: PlayerTank 添加 max_hp/current_hp 和 take_damage() 方法，受伤时发送 EventBus.tank_damaged 信号，HUD 显示血量。

**验收标准**:
- [ ] PlayerTank 有 `@export var max_hp: int = 3` 和 `var current_hp: int`
- [ ] take_damage() 扣减 current_hp，发送 EventBus.tank_damaged
- [ ] current_hp <= 0 调用 die()
- [ ] HUD 显示当前血量（心形或数字）
- [ ] 无敌帧期间不受伤害

**修改文件**:
- `scripts/entities/tanks/PlayerTank.gd`
- `scripts/ui/WeaponHUD.gd`
- `scenes/ui/WeaponHUD.tscn`

---

#### Story 3.4: 实现玩家无敌帧

| 属性 | 值 |
|------|-----|
| PRD编号 | 4.2 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 1.5h |
| 依赖 | Story 3.3 |
| 状态 | ❌ 未开始 |

**描述**: 受伤后进入无敌状态，持续 invincibility_duration 秒，期间 sprite 闪烁，take_damage() 直接 return。使用 Timer 节点控制。

**验收标准**:
- [ ] 受伤后无敌 1.5 秒（默认值）
- [ ] 无敌期间 sprite 闪烁（0.1 秒间隔切换 visible）
- [ ] 无敌期间 take_damage() 不扣血
- [ ] 使用 Timer 节点控制无敌持续时间

**修改文件**:
- `scripts/entities/tanks/PlayerTank.gd`
- `scenes/entities/tanks/Player1Tank.tscn` — 添加 InvincibilityTimer 节点

---

#### Story 3.5: 实现玩家死亡与重生

| 属性 | 值 |
|------|-----|
| PRD编号 | 4.3 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 3h |
| 依赖 | Story 3.3, 3.4 |
| 状态 | ❌ 未开始 |

**描述**: die() 播放爆炸效果、发送信号、隐藏坦克等待重生。重生恢复满血+2秒无敌+武器降回Lv.1。生命数耗尽触发 game_over。

**验收标准**:
- [ ] die() 播放占位爆炸效果
- [ ] die() 发送 EventBus.tank_died.emit(self)
- [ ] 隐藏坦克而非销毁
- [ ] 重生：出生点出现 + 满血 + 2秒无敌
- [ ] 死亡后主武器降回 Lv.1
- [ ] `@export var lives: int = 3`，每次死亡消耗1条命
- [ ] 生命耗尽 → EventBus.game_over()

**修改文件**:
- `scripts/entities/tanks/PlayerTank.gd`

---

#### Story 3.6: 敌人受伤视觉反馈

| 属性 | 值 |
|------|-----|
| PRD编号 | 3.5 |
| 优先级 | P1 |
| 执行角色 | 💻 开发 |
| 预计工时 | 1h |
| 依赖 | Story 1.3 |
| 状态 | ❌ 未开始 |

**描述**: take_damage() 时坦克 sprite 短暂变红（hit flash），死亡时播放占位爆炸动画。

**验收标准**:
- [ ] 受伤时 modulate 闪烁红色 0.1 秒
- [ ] 死亡时播放占位爆炸效果（色块扩大后消失）
- [ ] 不影响正常移动和射击

**修改文件**:
- `scripts/entities/enemys/EnemyTankBase.gd`

---

### Phase 4: 扩展功能（预计 2-3 天）

#### Story 4.1: 配置水域地形

| 属性 | 值 |
|------|-----|
| PRD编号 | 2.4 |
| 优先级 | P1 |
| 执行角色 | 💻 开发 |
| 预计工时 | 2h |
| 依赖 | Story 2.1 |
| 状态 | ❌ 未开始 |

**描述**: 配置 WaterTileset 使用独立 physics layer（与边界相同 bit 5），坦克被水域阻挡，子弹可飞越。在 TankTest.tscn 中放置水域。

**验收标准**:
- [ ] WaterTileset.tres 配置正确 physics layer（bit 5）
- [ ] 坦克无法穿越水域
- [ ] 子弹可以飞越水域
- [ ] TankTest.tscn 中 WaterLayer 有水域瓦片

**修改文件**:
- `assets/tilesets/WaterTileset.tres`
- `scenes/levels/TankTest.tscn`

---

#### Story 4.2: 创建追踪型敌人

| 属性 | 值 |
|------|-----|
| PRD编号 | 3.3 |
| 优先级 | P1 |
| 执行角色 | 💻 开发 |
| 预计工时 | 3h |
| 依赖 | Story 1.1, 1.3, 3.2 |
| 状态 | ❌ 未开始 |

**描述**: 新建 ChaseEnemyTank，继承 EnemyTankBase。在追踪范围内朝玩家方向移动+概率射击，超出范围随机移动。

**验收标准**:
- [ ] `scripts/entities/enemys/ChaseEnemyTank.gd` 创建完成
- [ ] `scenes/entities/enemys/ChaseEnemyTank.tscn` 创建完成
- [ ] chase_range = 250px 内追踪玩家
- [ ] max_hp = 2（比基础敌人更耐打）
- [ ] 追踪时朝玩家方向移动 + 概率射击
- [ ] 超出追踪范围 → 随机移动
- [ ] _find_nearest_player() 正确查找 player_tanks 组

**创建文件**:
- `scripts/entities/enemys/ChaseEnemyTank.gd`
- `scenes/entities/enemys/ChaseEnemyTank.tscn`

---

#### Story 4.3: 射击冷却管理（Timer 方案）

| 属性 | 值 |
|------|-----|
| PRD编号 | 3.4 |
| 优先级 | P1 |
| 执行角色 | 💻 开发 |
| 预计工时 | 1.5h |
| 依赖 | Story 3.2 |
| 状态 | ❌ 未开始 |

**描述**: 将 Story 3.2 中的 await 射击冷却改为 Timer 节点方案，更可控。不同敌人类型可配置不同冷却时间。

**验收标准**:
- [ ] EnemyTankBase 场景中添加 FireCooldownTimer 节点
- [ ] can_fire 标志位由 Timer 的 timeout 信号控制
- [ ] 不同敌人类型可配置不同冷却时间
- [ ] BasicEnemyTank.tscn 和 ChaseEnemyTank.tscn 都有 Timer 节点

**修改文件**:
- `scripts/entities/enemys/EnemyTankBase.gd`
- `scenes/entities/enemys/BasicEnemyTank.tscn`
- `scenes/entities/enemys/ChaseEnemyTank.tscn`

---

#### Story 4.4: 基地系统

| 属性 | 值 |
|------|-----|
| PRD编号 | 2.5 |
| 优先级 | P2 |
| 执行角色 | 💻 开发 |
| 预计工时 | 3h |
| 状态 | ❌ 未开始 |

**描述**: 创建基地实体，使用 LAYER_BASE(bit 6)，3点血量，被敌人子弹击中扣血，血量归零触发 game_over。基地周围有砖墙保护。

**验收标准**:
- [ ] `scripts/entities/Base.gd` 创建完成
- [ ] `scenes/entities/Base.tscn` 创建完成
- [ ] collision_layer = LAYER_BASE (64)
- [ ] 3 点血量，被子弹击中扣血
- [ ] 血量归零 → EventBus.game_over()
- [ ] TankTest.tscn 中有基地实例和周围砖墙
- [ ] 视觉：占位色块

**创建文件**:
- `scripts/entities/Base.gd`
- `scenes/entities/Base.tscn`

**修改文件**:
- `scenes/levels/TankTest.tscn`

---

### Phase 5: 验证与调校（预计 1-2 天）

#### Story 5.1: TankTest 场景完整布局

| 属性 | 值 |
|------|-----|
| PRD编号 | 6 |
| 优先级 | P0 |
| 执行角色 | 💻 开发 |
| 预计工时 | 2h |
| 依赖 | 所有前置Story |
| 状态 | ❌ 未开始 |

**描述**: 按 PRD 第6节的布局图，完善 TankTest.tscn 的地形布局，添加多个敌人位置，确保场景节点结构与PRD一致。

**验收标准**:
- [ ] 场景布局与PRD布局图一致
- [ ] 节点结构：BoundaryIndicator → GroundLayer → WaterLayer → WallLayer → BoundaryLayer → Base → Players → Enemies → Camera2D
- [ ] 敌人生成区域有3个位置
- [ ] 砖墙/钢墙/水域/基地保护砖墙布局合理
- [ ] 玩家出生点在底部

**修改文件**:
- `scenes/levels/TankTest.tscn`

---

#### Story 5.2: 完整游玩验证与调校

| 属性 | 值 |
|------|-----|
| PRD编号 | 10 |
| 优先级 | P0 |
| 执行角色 | 📝 PM + 💻 开发 |
| 预计工时 | 4h |
| 依赖 | Story 5.1 |
| 状态 | ❌ 未开始 |

**描述**: 完整游玩 TankTest.tscn，逐项验证验收检查清单，调校数值。

**验收标准（按PRD第10节）**:

地形:
- [ ] 玩家无法移出战场边界
- [ ] 子弹超出战场边界后销毁
- [ ] 玩家子弹击中砖墙 → 砖墙消失，子弹消失
- [ ] Lv.1/2 子弹击中钢墙 → 子弹消失，钢墙不损
- [ ] Lv.3 子弹击中钢墙 → 钢墙消失，子弹消失
- [ ] 坦克无法穿越水域
- [ ] 子弹可以飞越水域

敌人:
- [ ] 基础敌人随机巡逻移动
- [ ] 敌人被击中1次（基础）→ 死亡
- [ ] 敌人血量>1时，被击中后受伤但不死
- [ ] 敌人会向当前朝向射击
- [ ] 敌人子弹击中玩家 → 玩家扣血
- [ ] 追踪型敌人在范围内主动追踪玩家

玩家:
- [ ] 玩家被击中 → 扣血 + 短暂无敌闪烁
- [ ] 玩家血量归零 → 死亡 + 扣一条命 + 重生
- [ ] 玩家生命耗尽 → 游戏结束
- [ ] 武器升级道具可以正常拾取
- [ ] 击杀敌人后充能值增加
- [ ] 释放副武器正常工作

子弹:
- [ ] 玩家子弹和敌人子弹不会互相误伤
- [ ] 击杀敌人时充能正确归属（不是 null）
- [ ] 子弹击中地形后正确销毁

整体:
- [ ] 无控制台报错
- [ ] 碰撞无穿透/卡墙现象
- [ ] 游戏运行5分钟内无内存持续增长

---

#### Story 5.3: 文档更新与收尾

| 属性 | 值 |
|------|-----|
| PRD编号 | - |
| 优先级 | P1 |
| 执行角色 | 📝 PM |
| 预计工时 | 1h |
| 依赖 | Story 5.2 |
| 状态 | ❌ 未开始 |

**描述**: 更新项目文档，记录 Sprint 1 完成状态和遗留问题。

**验收标准**:
- [ ] docs/shared/CURRENT_TASKS.md 更新完成状态
- [ ] docs/ai2ai/AI2AI.md 记录 Sprint 1 工作总结
- [ ] 数值调校结果记录
- [ ] 遗留问题记录到技术债清单

---

### 延期项（不在 Sprint 1 范围内）

| PRD编号 | 需求 | 原因 |
|---------|------|------|
| 2.6 | 草地（隐蔽效果） | P2，降低范围 |
| 2.7 | 冰面（滑动惯性） | P3-已明确延期 |
| 5.4 | 子弹对象池 | P1，PRD说明测试场景可不优先 |
| TD-2 | Player2Tank 无法射击 | PRD标注"顺便修"，归入技术债 |
| TD-1 | 输入硬编码 | Sprint 5 |
| TD-4 | MainWeapon 硬编码数据 | Sprint 3 |
| TD-5 | State Charts 未使用 | Sprint 2 |
| TD-6 | 占位色块效果 | Sprint 4 |

---

## 3. 依赖关系与执行顺序

```
Phase 1 (无依赖，可立即开始)
  Story 1.1 ─── 玩家组注册 Bug
  Story 1.2 ─── 子弹击杀者 Bug
  Story 1.3 ─── 敌人血量系统

Phase 2 (部分依赖 Phase 1)
  Story 2.1 ─── TileSet 设计 [架构师] ← 可与 Phase 1 并行
  Story 2.2 ─── 配置 TerrainTileset ← 依赖 2.1
  Story 2.3 ─── 子弹-TileMap 适配 ← 依赖 2.2
  Story 2.4 ─── 战场边界 ← 依赖 2.2
  Story 2.5 ─── 砖墙 ← 依赖 2.3, 2.4
  Story 2.6 ─── 钢墙 ← 依赖 2.3, 2.4（可与 2.5 并行）

Phase 3 (依赖 Phase 2)
  Story 3.1 ─── 敌人子弹 ← 依赖 2.3
  Story 3.2 ─── 敌人射击 ← 依赖 3.1
  Story 3.3 ─── 玩家血量 ← 无强依赖，可与 3.1 并行
  Story 3.4 ─── 玩家无敌帧 ← 依赖 3.3
  Story 3.5 ─── 玩家死亡重生 ← 依赖 3.3, 3.4
  Story 3.6 ─── 敌人受伤视觉 ← 依赖 1.3

Phase 4 (依赖 Phase 3)
  Story 4.1 ─── 水域地形 ← 依赖 2.1
  Story 4.2 ─── 追踪型敌人 ← 依赖 1.1, 1.3, 3.2
  Story 4.3 ─── 射击冷却 Timer ← 依赖 3.2
  Story 4.4 ─── 基地系统 ← 独立，可与 4.1-4.3 并行

Phase 5
  Story 5.1 ─── 场景完整布局 ← 依赖所有前置
  Story 5.2 ─── 验证调校 ← 依赖 5.1
  Story 5.3 ─── 文档收尾 ← 依赖 5.2
```

---

## 4. 工时估算汇总

| Phase | Story数 | 预计工时 | 架构师 | 开发 | PM |
|-------|---------|---------|--------|------|-----|
| Phase 1 | 3 | 2.5h | - | 2.5h | - |
| Phase 2 | 6 | 11.5h | 2h | 9.5h | - |
| Phase 3 | 6 | 12.5h | - | 12.5h | - |
| Phase 4 | 4 | 9.5h | - | 9.5h | - |
| Phase 5 | 3 | 7h | - | 4h | 3h |
| **合计** | **22** | **43h** | **2h** | **38h** | **3h** |

> 按每天 6h 有效开发时间估算，约需 **7-8 个工作日**。

---

## 5. 关键风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| TileMapLayer 碰撞回调获取精确碰撞点困难 | 子弹可能无法精准摧毁被击中的瓦片 | PRD已提供方案A（Custom Data Layer），优先采用；如不行降级到方案B（多图层） |
| 水域碰撞层与边界层复用 bit 5 可能冲突 | 子弹本应飞越水域却被边界层阻挡 | 架构师在 Story 2.1 中提前验证方案可行性 |
| EnemyTankBase.fire() 使用 await 冷却不稳定 | 多次射击可能出问题 | Story 4.3 明确改为 Timer 方案 |
| Player2Tank 无法射击（TD-2） | 双人模式无法游玩 | 不在 Sprint 1 核心范围，但如时间允许可顺手修复 |

---

*本计划为 Sprint 1 的权威开发指导。任何需求变更需更新 PRD 并同步此计划。*
