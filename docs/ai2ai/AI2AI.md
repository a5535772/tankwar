# AI 工作记录

## 2026-04-21

### Story 1.1: 修复玩家组注册 Bug ✅

**修改文件**:
- `scripts/entities/tanks/PlayerTank.gd` — 在 `_ready()` 中添加 `add_to_group("player_tanks")`

**修复内容**:
- PlayerTank 现在会在 `_ready()` 时注册到 `"player_tanks"` 组
- 修复了 `PowerUp.gd` 中 `body.is_in_group("player_tanks")` 始终返回 false 导致道具无法拾取的问题
- 为后续追踪型敌人（ChaseEnemyTank）的 `_find_nearest_player()` 查找 `"player_tanks"` 组铺平道路

**对应PRD**: 4.4 [P0] 玩家组注册（Bug 修复）
**对应Dev Plan**: Story 1.1

---

### Story 1.2: 修复子弹击杀者追踪 Bug ✅

**修改文件**:
- `scripts/weapons/Bullet.gd` — 添加 `var owner_tank: Tank = null` 属性，`_on_area_entered()` 中将 `take_damage(damage, null)` 改为 `take_damage(damage, owner_tank)`
- `scripts/weapons/MainWeapon.gd` — `fire()` 中添加 `bullet.owner_tank = owner_tank`

**修复内容**:
- 子弹现在知道是谁发射的（owner_tank），击中敌人时会正确传递攻击者信息
- 修复了充能掠夺系统断裂的问题：之前 take_damage 传入 null → last_attacker 为 null → enemy_killed 信号中 killer 为 null → WeaponManager.on_enemy_killed() 中 killer != get_parent() → 充能永远无法增长
- 修复后完整链路：MainWeapon.fire() 设置 owner_tank → Bullet 传递给 take_damage → EnemyTankBase 记录 last_attacker → die() 发出正确的 killer → WeaponManager 匹配成功 → 充能增长

**对应PRD**: 5.3 [P0] 子弹击杀者追踪（Bug 修复）
**对应Dev Plan**: Story 1.2

---

### Story 1.3: 完善敌人血量系统 ✅

**修改文件**:
- `scripts/entities/enemys/EnemyTankBase.gd` — 添加 `@export var max_hp: int = 1` 和 `var current_hp: int`，_ready() 中初始化 `current_hp = max_hp`，take_damage() 实现血量扣减和死亡判定
- `scripts/entities/enemys/BasicEnemyTank.gd` — 添加注释说明基础敌人一击必杀（max_hp = 1 继承自基类）

**修复内容**:
- EnemyTankBase 现在有完整的血量系统：max_hp（可配置）和 current_hp（运行时）
- take_damage() 实际扣减 current_hp，血量归零时调用 die()
- 修复了敌人"无敌"的问题：之前 take_damage() 只打印日志，敌人永远不会死
- 完整链路：子弹击中 → take_damage() → current_hp -= damage → current_hp <= 0 → die() → enemy_killed 信号 → 充能掠夺 → queue_free()

**对应PRD**: 3.1 [P0] 完善敌人血量系统
**对应Dev Plan**: Story 1.3

---

### Sprint 1 开发计划制定

**产出文件**:
- `docs/project/sprint/sprint1/sprint1_dev_plan.md` — Sprint 1 开发计划

**关键内容**:
- 盘点了 PRD 制定前已完成的16项功能（坦克基类、武器系统、碰撞层定义等）
- 将 PRD 的20项需求拆解为22个 Story，按5个 Phase 组织
- 明确了角色分工：架构师负责 TileSet 配置方案设计(1个Story)，开发负责具体实现(18个Story)，PM负责验收和文档(3个Story)
- 识别了关键依赖链：TileSet 设计→配置→子弹适配→地形实现 为核心路径
- 估算总工时约43h，预计7-8个工作日

**发现的实现缺口**:
- Bullet.gd 缺少 owner_tank 属性 → 充能掠夺无法识别击杀者
- PlayerTank.gd 未添加 player_tanks 组 → 道具无法拾取
- EnemyTankBase.gd 的 take_damage() 血量扣减为 TODO → 敌人无法被击杀
- EnemyTankBase.gd 的 fire() 为 TODO → 敌人无法射击
- TankTest.tscn 的 WallLayer/BoundaryLayer 未配置 TileSet → 地形碰撞不生效
- 不存在 EnemyBullet 场景和脚本

---

### 游戏设计文档编写

**产出文件**:
1. `docs/project/game/game_overview.md` — 游戏概要文档
2. `docs/project/game/evolution_roadmap.md` — 演进计划文档（5期路线图）
3. `docs/project/sprint/sprint1_prd.md` — Sprint 1 详细产品需求说明书

**关键设计决策**:
- 定义了 4 条设计支柱：一炮一决、攻守博弈、火力进化、可破坏战场
- 将开发分为 5 期：核心验证 → 单关可玩 → 多关卡 → 视听打磨 → 扩展发布
- Sprint 1 聚焦在 TankTest.tscn 中验证核心机制，共 20 项需求（11 项 P0）
- 识别了 2 个必须修复的 bug：玩家组注册缺失、子弹击杀者传递 null
- 地形碰撞采用 TileSet Custom Data Layer 方案，比多 TileMapLayer 更灵活

**发现的关键问题**:
- PlayerTank 未添加到 "player_tanks" 组 → 道具无法拾取 + 追踪敌人找不到玩家
- Bullet.gd 的 take_damage() 传入 null attacker → 充能掠夺无法识别击杀者
- Player2Tank 未实现射击方法 → 玩家2无法游玩
- 所有输入使用硬编码键位 → 无法自定义
- 子弹与 TileMapLayer 碰撞需要特殊处理（body 是整个 TileMapLayer）

---

## 2026-04-10

### 武器系统开发 - Phase 1, 2 & 3 完成

#### Phase 1: 基础架构

**1. 设计文档**
- 创建武器系统设计文档（`docs/game/player/武器系统设计文档.md`）
- 定义了主武器3级升级系统、6种副武器类型
- 确认所有武器效果先用色块占位

**2. 核心脚本实现**

| 文件 | 说明 |
|------|------|
| `scripts/weapons/ChargeSystem.gd` | 充能系统,管理副武器充能值的增减 |
| `scripts/weapons/MainWeaponData.gd` | 主武器数据资源类 |
| `scripts/weapons/MainWeapon.gd` | 主武器控制类,管理射击和升级 |
| `scripts/weapons/Bullet.gd` | 子弹基类,处理移动和碰撞 |
| `scripts/weapons/SecondaryWeapon.gd` | 副武器基类,定义通用接口 |
| `scripts/weapons/WeaponManager.gd` | 武器管理器,管理主副武器和充能 |
| `scripts/systems/EventBus.gd` | 事件总线,添加敌人击杀等信号 |

**3. 系统集成**
- 修改 `EnemyTankBase.gd`: 添加充能值属性和攻击者跟踪
- 修改 `PlayerTank.gd`: 集成武器管理器,添加武器输入处理
- 注册 `EventBus` 为单例

#### Phase 2: 主武器实现

**1. 子弹场景**（使用色块占位）

| 场景文件 | 等级 | 颜色 | 属性 |
|----------|------|------|------|
| `scenes/bullets/BasicBullet.tscn` | Lv.1 | 黄色 | 速度400, 伤害1, 冷却0.5s |
| `scenes/bullets/FastBullet.tscn` | Lv.2 | 橙色 | 速度500, 伤害1, 冷却0.3s |
| `scenes/bullets/SteelDestroyerBullet.tscn` | Lv.3 | 红色 | 速度450, 伤害2, 冷却0.4s, 可摧毁钢墙 |

**2. 武器配置资源**
- `resources/weapons/MainWeapon_Level1.tres`
- `resources/weapons/MainWeapon_Level2.tres`
- `resources/weapons/MainWeapon_Level3.tres`

**3. 道具系统**

| 文件 | 说明 |
|------|------|
| `scripts/powerups/PowerUp.gd` | 道具基类 |
| `scripts/powerups/WeaponUpgradePowerUp.gd` | 武器升级道具 |
| `scenes/powerups/WeaponUpgradePowerUp.tscn` | 武器升级道具场景 |

**4. UI 系统**

| 文件 | 说明 |
|------|------|
| `scripts/ui/WeaponHUD.gd` | 武器 HUD 脚本 |
| `scenes/ui/WeaponHUD.tscn` | 武器 HUD 场景 |

**5. 射击功能**
- 修改 `Player1Tank.gd`: 实现 J 键射击、K 键释放副武器
- 修复子弹发射方向问题,使用 `_get_facing_direction()` 方法

#### Phase 3: 副武器基础

**1. 导弹弹幕**

| 文件 | 说明 |
|------|------|
| `scripts/weapons/secondary/MissileBarrage.gd` | 导弹弹幕副武器 |
| `scripts/weapons/Missile.gd` | 追踪导弹类 |

**特点**:
- 向四周发射8枚导弹
- 导弹自动追踪最近敌人
- 每枚导弹造成2点伤害
- 充能消耗: 50点
- 占位颜色: 蓝色

**2. EMP 冲击波**

| 文件 | 说明 |
|------|------|
| `scripts/weapons/secondary/EMPShockwave.gd` | EMP 冲击波副武器 |
| `scripts/weapons/EMPWave.gd` | EMP 波效果类 |

**特点**:
- 释放电磁脉冲,瘫痪范围内敌人
- 半径200像素
- 持续3秒
- 充能消耗: 40点
- 占位颜色: 青色

**3. HUD 集成**
- 修改 `PlayerTank.gd`: 添加 `_init_hud()` 方法,自动加载 HUD
- 修改 `WeaponManager.gd`:
  - 添加 `set_hud()` 方法连接 HUD
  - 添加 `_init_secondary_weapons()` 自动创建副武器
  - 添加 HUD 更新方法

**4. 测试文档**
- 创建 `docs/game/player/副武器测试指南.md`: 详细的测试步骤和排查指南

#### 技术决策

1. **子弹实例化方式**: 从预制场景实例化,而非动态创建节点
2. **道具基类设计**: 使用 Area2D 作为基类,便于碰撞检测
3. **UI 分离**: HUD 作为独立场景,自动加载到当前场景
4. **占位素材**: 所有视觉效果使用 ColorRect 色块,便于后续替换
5. **导弹追踪**: 使用 `lerp()` 插值实现平滑追踪
6. **EMP 效果**: 通过暂停敌人 Timer 和改变颜色实现瘫痪效果

#### 遗留问题

1. 子弹碰撞需要完善:
   - 需要添加地形分组标签（`brick_wall`、`steel_wall`）
   - 需要实现敌人的受伤系统
2. 输入映射需要在项目设置中配置:
   - `switch_secondary_weapon`: Q键切换副武器
3. 需要在 Godot 编辑器中:
   - 为敌人坦克添加 `enemy_tanks` 组
   - 为玩家坦克添加 `player_tanks` 组
4. 导弹和子弹未使用对象池,大量实例可能影响性能

#### 下一步工作

Phase 4-7 (根据设计文档):
- 实现剩余副武器(敌人控制、护盾屏障、时空减速、终极毁灭)
- 实现副武器升级系统
- 添加音效和特效
- 性能优化(对象池)
- 全面测试和平衡调整

---

## 历史记录

(之前的记录)
