# AI 工作记录

## 2026-04-24

### Story 4.1: 配置水域地形 ✅

**修改文件**:
- `assets/tilesets/WaterTileset.tres` — 完整重写，添加 Physics Layer 配置和每个瓦片的碰撞形状

**实现内容**:
- `physics_layer_0/collision_layer = 32`（LAYER_BOUNDARY）
- `physics_layer_0/collision_mask = 0`（瓦片不主动检测其他物体）
- 为每个使用的水域瓦片（0:0, 0:1, ..., 6:3）添加 16×16 矩形碰撞形状
- WaterLayer 已在 StandardBattleField.tscn 中绘制水域布局

**碰撞层设计原理**:
- 水域使用 LAYER_BOUNDARY(32) 而非 LAYER_TERRAIN(16)
- 坦克 collision_mask 包含 LAYER_BOUNDARY → 坦克被水域阻挡
- 子弹 collision_mask 不含 LAYER_BOUNDARY → 子弹可穿越水域

**关键修复**:
- 原配置 `collision_layer = 2147483648`（第31位）错误，改为 `32`（第5位）
- 原配置缺少瓦片碰撞形状（polygon_0），导致水域不产生实际碰撞

**验证链路**:
- 坦克移动到水域 → collision_mask 检测 LAYER_BOUNDARY → StaticBody2D 碰撞 → move_and_slide() 阻挡
- 子弹飞向水域 → collision_mask 不含 LAYER_BOUNDARY → 无碰撞 → 穿越继续飞行
- 子弹超出战场 → _is_out_of_bounds() → queue_free()（416×416 矩形检测）

**对应PRD**: 2.4 [P1] 水域
**对应Dev Plan**: Story 4.1

---

### Bug 排查: 子弹击中砖墙后无法消除砖块 (进行中)

**问题现象**: 子弹击中砖墙后，碰撞检测正常（子弹被销毁），但砖墙不被消除。

**修改文件**:
- `scripts/weapons/Bullet.gd` — 添加碰撞诊断日志
- `scripts/terrain/TerrainInteractor.gd` — 添加完整诊断日志 + source_id 后备方案

**诊断日志添加位置**:
1. `Bullet._handle_collision()`: 打印 collider 名称/类型/碰撞点
2. `TerrainInteractor.handle_hit_at_position()`: 首次碰撞时打印 TileSet 诊断（custom_data 层数、名称、类型、source 列表、前5个瓦片的 custom_data 值）
3. `TerrainInteractor.handle_hit_at_position()`: 打印 probe 坐标、coords、tile_type、raw 值和类型
4. `TerrainInteractor._process_tile_hit()`: 打印砖墙/钢墙销毁日志

**修复措施（source_id 后备方案）**:
- 新增 `_tile_type_from_source()` 方法：当 `get_custom_data("tile_type")` 返回空时，通过 `get_cell_source_id()` 推断瓦片类型
- TerrainTileset 约定：source 0=brick, 1=steel, 2=boundary
- 对 `handle_hit_at_position()` 和 `handle_hit()` 两个入口都添加了后备逻辑

**根因推测**（待日志确认）:
- AI2AI.md 2026-04-22 记录了相同问题：`.tres` 文件的 `custom_data` 被 Godot 编辑器重新导出时还原
- 当前 `TerrainTileset.tres` 文件内容正确，但运行时可能丢失 custom_data
- 后备方案确保即使 custom_data 丢失，砖墙仍可被正确销毁

---

## 2026-04-22

### 架构重构: 16x16 子瓦片 + CharacterBody2D 子弹 ✅

**修改文件**:
- `assets/tilesets/TerrainTileset.tres` — tile_size 32→16, collision polygon 16x16
- `scripts/terrain/StandardBattleField.gd` — GRID 翻倍(60x34), 子瓦片放置方法
- `scripts/terrain/TerrainInteractor.gd` — 新增 handle_hit_at_position(), VFX 8x8
- `scripts/weapons/Bullet.gd` — Area2D→CharacterBody2D, move_and_collide()
- `scenes/entities/weapons/bullets/BasicBullet.tscn` — Area2D→CharacterBody2D
- `scenes/entities/weapons/bullets/FastBullet.tscn` — Area2D→CharacterBody2D
- `scenes/entities/weapons/bullets/SteelDestroyerBullet.tscn` — Area2D→CharacterBody2D
- `scenes/entities/enemys/BasicEnemyTank.tscn` — 移除 HurtArea 节点

**根因（两个架构缺陷）**:
1. **Area2D 碰撞不可靠**: 子弹用 Area2D + body_entered 信号检测碰撞，但物理帧与移动不同步，擦边时漏检导致穿模
2. **32x32 瓦片过大**: 一发子弹摧毁整个 32x32 砖块，不符合经典坦克大战的"一个大砖块=2x2小砖块"设计

**修复内容**:
1. **16x16 子瓦片系统**:
   - TerrainTileset tile_size 从 32 改为 16
   - 每个大砖块(32x32) = 2×2=4 个子瓦片，每个可独立摧毁
   - StandardBattleField 使用 `_big_tile_to_sub_tiles()` 自动展开坐标
   - 战场网格从 30×17(32px) 变为 60×34(16px)，像素尺寸不变

2. **CharacterBody2D 子弹**:
   - Bullet 从 Area2D 改为 CharacterBody2D
   - 使用 `move_and_collide()` 替代手动位移 + overlap 检测
   - 物理引擎保证碰撞不遗漏，无穿模
   - 通过 `KinematicCollision2D.get_collider()` 直接判断碰撞对象
   - 使用碰撞点 `collision.get_position()` 定位瓦片，比子弹中心更精确

3. **移除敌人 HurtArea**:
   - 子弹现在是 CharacterBody2D，可直接与敌人 CharacterBody2D 碰撞
   - 不再需要 HurtArea（Area2D 子节点）中转
   - 导弹 Missile.gd 仍使用 Area2D + body_entered，不影响（Area2D 可检测 CharacterBody2D）

**TerrainInteractor 变更**:
- 新增 `handle_hit_at_position()`: CharacterBody2D 子弹使用，接收碰撞点坐标
- 保留 `handle_hit()`: Area2D 导弹使用，接收方向搜索逻辑
- 提取 `_process_tile_hit()` 统一瓦片命中处理
- VFX 半尺寸: 16.0→8.0（适配 16x16 子瓦片）

### Bug 修复: 子弹打中砖墙不消失 ✅

**修改文件**:
- `assets/tilesets/TerrainTileset.tres` — 重新添加瓦片 custom_data 和修正类型

**根因**:
TerrainTileset.tres 中存在两个问题：
1. `custom_data_layer_0/type = 0`（NIL 类型），应为 `4`（STRING 类型）
2. 砖墙/钢墙/边界瓦片均缺少 `0:0/0/custom_data_0` 值

**影响链路**:
- `get_custom_data("tile_type")` 返回 null → tile_type 变为 "" → match 语句走默认分支 → 只销毁子弹不消除瓦片

**修复内容**:
- `custom_data_layer_0/type = 0` → `4`（String 类型）
- 砖墙添加 `0:0/0/custom_data_0 = "brick"`
- 钢墙添加 `0:0/0/custom_data_0 = "steel"`
- 边界添加 `0:0/0/custom_data_0 = "boundary"`

**备注**: 此问题与 Story 2.5 相同，之前已修复但 .tres 文件疑似被 Godot 编辑器重新导出时还原。需注意在编辑器中修改 TileSet 后检查 custom_data 是否保留。

---

### Bug 修复: 子弹穿模（穿过砖墙不触发碰撞） ✅

**修改文件**:
- `scripts/weapons/Bullet.gd` — 重构移动和碰撞检测逻辑

**根因**:
1. 子弹使用 `_process()` 移动，但 Area2D 的 `body_entered` 信号只在物理帧中触发，移动和碰撞检测不同步
2. 高速子弹单帧移动距离（~6.7px at 60fps）可能跨越碰撞区域而不被检测到
3. 子弹碰撞半径仅 4px，容易漏检

**修复内容**:
- `_process()` → `_physics_process()`：移动与碰撞检测同步
- 添加分步移动（MAX_STEP=8px）：每步不超过 8px，高速子弹自动分多步移动
- 每步移动后主动调用 `get_overlapping_bodies()/get_overlapping_areas()` 检测碰撞，不再仅依赖信号
- 添加 `_hit` 标志防止 `queue_free` 延迟期间重复处理碰撞

---

## 2026-04-21

### Story 2.6: 实现钢墙 ✅

**修改文件**:
- `scripts/terrain/StandardBattleField.gd` — 添加 STEEL_SOURCE_ID/STEEL_ATLAS_COORDS 常量、`_create_steel_walls()` 和 `_place_steel_cluster()` 方法

**实现内容**:
- 3 组钢墙集群：左中(6,5)、右中(22,5)、中央大块(13,9)
- 钢墙 source ID = 1（对应 TileSetAtlasSource_steel），custom_data_0 = "steel"
- 子弹碰撞逻辑已在 Story 2.3 中实现：can_destroy_steel → erase_cell，否则仅 queue_free

**验证链路**:
- Lv.1/2 子弹 can_destroy_steel = false → match "steel" → 仅 queue_free()，钢墙完好
- Lv.3 子弹 can_destroy_steel = true → match "steel" → erase_cell() + queue_free()
- 钢墙使用 steel_wall.png 纹理（灰色），与砖墙（棕色）视觉区分

**对应PRD**: 2.3 [P0] 钢墙
**对应Dev Plan**: Story 2.6

---

### Story 2.5: 实现砖墙 ✅

**修改文件**:
- `assets/tilesets/TerrainTileset.tres` — 为 3 个瓦片添加 `custom_data_0` 值（brick/steel/boundary）
- `scripts/terrain/StandardBattleField.gd` — 添加 `_create_brick_walls()` 和 `_place_brick_cluster()` 方法

**修复内容**:
- **关键修复**: TerrainTileset.tres 中 3 个瓦片（砖墙/钢墙/边界）缺少 `custom_data_0` 值，导致 `get_custom_data("tile_type")` 始终返回 null，子弹-TileMap 交互逻辑完全失效
- 添加砖墙布局到 WallLayer：6 组砖墙集群（左上/中上/右上/左中/右中/基地保护）
- 使用代码生成瓦片而非在 .tscn 中硬编码 tile_map_data，更易维护

**实现决策**:
- 砖墙布局通过 `StandardBattleField.gd` 的 `_create_brick_walls()` 方法在 _ready() 时生成
- `_place_brick_cluster()` 辅助方法简化矩形区域砖墙放置
- 砖墙 source ID = 0（对应 TileSetAtlasSource_brick），atlas 坐标 (0,0)

**验证链路**:
- 子弹 collision_mask 包含 LAYER_TERRAIN → 检测到 WallLayer 碰撞
- _on_body_entered() → body is TileMapLayer → _handle_tilemap_collision()
- get_custom_data("tile_type") 返回 "brick" → match "brick" → erase_cell() + queue_free()
- 坦克 collision_mask 包含 LAYER_TERRAIN → 被砖墙阻挡
- 多子弹安全：第二颗子弹碰到已移除瓦片 → tile_data == null → queue_free()

**对应PRD**: 2.2 [P0] 砖墙
**对应Dev Plan**: Story 2.5

---

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
