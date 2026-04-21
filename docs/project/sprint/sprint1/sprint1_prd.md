# Sprint 1: 核心机制验证 — 产品需求说明书

> **文档版本**: v1.0  
> **最后更新**: 2026-04-21  
> **维护者**: 游戏设计师  
> **验证场景**: `scenes/levels/TankTest.tscn`

---

## 0. Sprint 目标

在 `TankTest.tscn` 中完成 **玩家、地图特性、敌人** 三大核心机制的功能搭建和验证。完成后，后续开发只需创作更多关卡内容，无需再修改底层机制。

**完成标志**: 运行 `TankTest.tscn`，玩家可以——

1. ✅ 在有边界、有地形（砖墙/钢墙/水域）的战场上移动和射击
2. ✅ 子弹击中砖墙 → 砖墙被摧毁；击中钢墙 → 子弹消失（Lv.3 除外则钢墙摧毁）
3. ✅ 敌人会移动、会射击、有血量、被击杀后死亡
4. ✅ 被敌人子弹击中 → 玩家受伤扣血；血量归零 → 玩家死亡
5. ✅ 击杀敌人 → 掠夺充能值 → 释放副武器
6. ✅ 所有碰撞行为正确，坦克和子弹不会穿墙或出界

---

## 1. 需求总览

| 模块 | 需求数 | P0 | P1 | P2 |
|------|--------|----|----|-----|
| 地形与边界 | 7 | 3 | 2 | 2 |
| 敌人补全 | 5 | 2 | 3 | 0 |
| 玩家补全 | 4 | 3 | 1 | 0 |
| 子弹系统补全 | 4 | 3 | 1 | 0 |
| **合计** | **20** | **11** | **7** | **2** |

> **P0**: 必须完成，否则核心循环不可玩  
> **P1**: 应该完成，显著提升体验  
> **P2**: 可以延期到后续 Sprint

---

## 2. 地形与边界系统

### 2.1 [P0] 战场边界

**需求**: 坦克和子弹不可超出战场范围

**玩家体验目标**: 移动时感受到清晰的战场边界，永远不会"跑出地图"

**实现规格**:
- 战场范围: 416×416 像素（13×13 格 × 32px）
- `BoundaryLayer`（TileMapLayer）配置碰撞，使用 `LAYER_BOUNDARY`（bit 5）
- 坦克 `collision_mask` 已包含 `LAYER_BOUNDARY`，确认 `BoundaryLayer` 的 TileSet 正确配置 physics layer
- 子弹超出战场边界时销毁（当前使用 viewport 检测，需改为战场矩形检测）

**输入**: 坦克移动到边界位置  
**输出**: 坦克被阻挡无法继续移动  
**失败状态**: 坦克或子弹穿过边界  
**边界情况**: 坦克对角线移动被边界阻挡时，应沿边界滑行

**待修改文件**:
- `assets/tilesets/TerrainTileset.tres` — 补充边界瓦片定义和碰撞形状
- `Bullet.gd` — 将 viewport 边界检测改为战场矩形检测
- `TankTest.tscn` — 在 BoundaryLayer 上绘制边界瓦片

---

### 2.2 [P0] 砖墙

**需求**: 可被任意炮弹摧毁的掩体

**玩家体验目标**: 射击砖墙时的满足感——墙壁碎裂、新路线打开

**实现规格**:
- `WallLayer`（TileMapLayer）使用配置了 `LAYER_TERRAIN`（bit 4）碰撞的 TileSet
- 砖墙瓦片加入 `"terrain"` 和 `"brick_wall"` 组
- 子弹击中砖墙 → 调用砖墙 `destroy()` → 瓦片从 TileMapLayer 移除
- 砖墙占 1 格（32×32），可被单发炮弹摧毁
- 碎裂时播放占位动画（色块闪烁后消失）

**输入**: 子弹击中砖墙瓦片  
**输出**: 砖墙瓦片从地图移除，子弹销毁  
**失败状态**: 子弹穿墙 / 砖墙不被摧毁  
**边界情况**: 多发子弹同时击中同一砖墙

**待创建/修改文件**:
- `assets/tilesets/TerrainTileset.tres` — 补充砖墙瓦片和碰撞形状
- `Bullet.gd` — `_on_body_entered()` 中处理 TileMap 碰撞（需适配 TileMapLayer API）
- `TankTest.tscn` — 在 WallLayer 上绘制砖墙布局

**技术备注**: TileMapLayer 的碰撞体通过 TileSet 的 Physics Layer 配置。子弹检测 `body_entered` 时，body 是 TileMapLayer 节点，需通过 `get_tile_data()` 获取瓦片信息并判断类型。可使用 TileSet 的自定义数据层（Custom Data Layer）标记瓦片类型（如 `tile_type = "brick"`），或使用 TileMapLayer 的 `get_cell_tile_data()` 方法。

---

### 2.3 [P0] 钢墙

**需求**: 仅 Lv.3 消钢炮弹可摧毁；其他炮弹击中后消失

**玩家体验目标**: 钢墙是不可逾越的障碍——除非你拥有 Lv.3 炮弹，此时感受到力量提升

**实现规格**:
- 钢墙瓦片加入 `"terrain"` 和 `"steel_wall"` 组
- 子弹 `can_destroy_steel == false` → 子弹销毁，钢墙不损
- 子弹 `can_destroy_steel == true` → 钢墙摧毁，子弹销毁
- 钢墙视觉上与砖墙有明确区分（颜色更亮/更灰）

**输入**: 不同等级子弹击中钢墙  
**输出**: Lv.1/2 → 子弹消失，钢墙完好；Lv.3 → 钢墙摧毁  
**失败状态**: Lv.1 炮弹摧毁钢墙 / Lv.3 炮弹无法摧毁钢墙

**待修改文件**:
- 同砖墙的文件
- `TankTest.tscn` — 在 WallLayer 上放置钢墙瓦片

---

### 2.4 [P1] 水域

**需求**: 坦克不可进入，子弹可飞越

**玩家体验目标**: 水域是天然屏障，迫使玩家绕路，创造战术选择

**实现规格**:
- `WaterLayer`（TileMapLayer）使用 `LAYER_TERRAIN` 碰撞
- 坦克被水域阻挡（碰撞配置已包含 LAYER_TERRAIN）
- 子弹 collision_mask 不包含 LAYER_TERRAIN 中的水域瓦片
- 需要将水域的碰撞层与墙壁的碰撞层区分，或者使用 TileSet 的不同 physics layer
- **方案**: 水域使用独立的 physics layer（bit 5 = 边界层可复用，或新增），坦克检测水域，子弹不检测水域

**技术备注**: 当前 `LAYER_TERRAIN` 统一为 bit 4，如果水域和墙壁共用同一层，子弹就无法区分。建议将水域的碰撞放在不同的 physics layer，或使用 Area2D 检测方式。最简方案：水域使用与边界相同的 collision layer（bit 5），坦克 mask 已包含 bit 5，子弹 mask 不包含 bit 5。

**待修改文件**:
- `assets/tilesets/WaterTileset.tres` — 配置正确的 physics layer
- `TankTest.tscn` — 在 WaterLayer 上绘制水域

---

### 2.5 [P2] 基地

**需求**: 位于战场底部中央，被摧毁则游戏结束

**实现规格**:
- 基地实体使用 `LAYER_BASE`（bit 6）
- 基地有血量（3 点），被敌人子弹击中扣血
- 血量归零 → 基地摧毁 → 触发 `EventBus.game_over()`
- 基地周围有砖墙保护
- 视觉：占位色块（区别于普通瓦片）

**待创建文件**:
- `scripts/entities/Base.gd` — 基地脚本
- `scenes/entities/Base.tscn` — 基地场景

---

### 2.6 [P2] 草地

**需求**: 坦克进入后对敌人不可见（AI 不追踪）

**实现规格**:
- 草地瓦片无碰撞（坦克可自由通过）
- 草地绘制在坦克上方的图层（Z-index 更高），视觉上"遮挡"坦克
- AI 追踪逻辑：如果目标在草地中，视为不可见

---

### 2.7 [P3-延期] 冰面

**需求**: 坦克经过时产生滑动惯性

**说明**: 冰面的滑动机制实现较复杂（需要修改 Tank.gd 的移动系统），降级到后续 Sprint。

---

## 3. 敌人补全

### 3.1 [P0] 敌人血量系统

**需求**: `take_damage()` 实际扣减血量，血量归零调用 `die()`

**玩家体验目标**: 打击敌人时有明确的"血量在减少"反馈，多次射击后敌人倒下

**实现规格**:
- `EnemyTankBase` 添加 `@export var max_hp: int = 1` 和 `var current_hp: int`
- `take_damage(damage: int, attacker: Tank)`:
  ```gdscript
  func take_damage(damage: int, attacker: Tank) -> void:
      last_attacker = attacker
      current_hp -= damage
      if current_hp <= 0:
          die()
  ```
- `_ready()` 中 `current_hp = max_hp`
- 不同敌人类型可配置不同 `max_hp`:
  - BasicEnemyTank: `max_hp = 1`（一炮击杀，经典 90 坦克风格）
  - ChaseEnemyTank: `max_hp = 2`

**待修改文件**:
- `scripts/entities/enemys/EnemyTankBase.gd` — 添加血量属性，完善 `take_damage()`
- `scripts/entities/enemys/BasicEnemyTank.gd` — 配置 `max_hp`

**调校杠杆**:
- `max_hp`: 控制敌人耐久度
- `charge_value`: 控制击杀奖励

---

### 3.2 [P0] 敌人射击

**需求**: 敌人可向当前朝向发射子弹

**玩家体验目标**: 敌人是真正有威胁的——不只会乱跑，还会还击

**实现规格**:
- `EnemyTankBase` 添加射击功能:
  ```gdscript
  @export var fire_cooldown: float = 2.0  # 射击冷却（秒）
  var can_fire: bool = true
  
  func fire() -> void:
      if not can_fire: return
      can_fire = false
      # 实例化敌人子弹
      var bullet := preload("res://scenes/entities/weapons/bullets/EnemyBullet.tscn").instantiate()
      bullet.global_position = global_position
      bullet.direction = _get_move_direction_vector()
      bullet.damage = 1
      get_tree().current_scene.add_child(bullet)
      # 冷却
      await get_tree().create_timer(fire_cooldown).timeout
      can_fire = true
  ```
- AI 决策中随机触发射击: `_on_decision_tick()` 中有 30% 概率调用 `fire()`
- 敌人子弹使用 `LAYER_ENEMY_BULLET`（bit 3），mask 检测 `LAYER_PLAYER | LAYER_TERRAIN | LAYER_BOUNDARY | LAYER_BASE`

**待创建文件**:
- `scenes/entities/weapons/bullets/EnemyBullet.tscn` — 敌人子弹场景
- `scripts/weapons/EnemyBullet.gd` — 敌人子弹脚本（继承或复制 Bullet.gd，修改碰撞层）

**待修改文件**:
- `scripts/entities/enemys/EnemyTankBase.gd` — 添加 `fire()` 方法和冷却逻辑
- `scripts/entities/enemys/BasicEnemyTank.gd` — 在决策中添加射击行为

**调校杠杆**:
- `fire_cooldown`: 射击频率（2s = 缓慢，0.5s = 疯狂）
- 射击概率: 决策 tick 中触发射击的概率（30% [占位符]）

---

### 3.3 [P1] 追踪型敌人

**需求**: 检测到玩家后主动追踪

**玩家体验目标**: 有些敌人不只是乱逛——它们会找你、追你，增加紧迫感

**实现规格**:
- 新类 `ChaseEnemyTank`，继承 `EnemyTankBase`
- 属性:
  - `@export var chase_range: float = 250.0` — 追踪触发距离
  - `@export var max_hp: int = 2` — 比基础敌人更耐打
- `_on_decision_tick()` 行为:
  1. 调用 `_find_nearest_player()` 查找玩家
  2. 如果玩家在追踪范围内 → 朝玩家方向移动 + 有概率射击
  3. 如果无玩家或超出范围 → 随机移动
- `_find_nearest_player()`: 在 `"player_tanks"` 组中查找距离最近的玩家

**待创建文件**:
- `scripts/entities/enemys/ChaseEnemyTank.gd`
- `scenes/entities/enemys/ChaseEnemyTank.tscn`

**调校杠杆**:
- `chase_range`: 追踪距离（250px ≈ 8 格）
- `decision_interval`: 决策频率
- 追踪方向偏好: 水平优先 / 垂直优先 / 最短轴

---

### 3.4 [P1] 射击冷却管理

**需求**: 敌人射击有冷却时间，不会疯狂射击

**实现规格**:
- 使用 `Timer` 节点替代 `await`，更可控:
  ```
  场景中添加 FireCooldownTimer (Timer)
  ```
- `can_fire` 标志位控制射击状态
- 不同敌人类型可配置不同冷却时间

**待修改文件**:
- `scripts/entities/enemys/EnemyTankBase.gd` — 添加 `FireCooldownTimer` 节点
- `scenes/entities/enemys/BasicEnemyTank.tscn` — 添加 Timer 节点
- `scenes/entities/enemys/ChaseEnemyTank.tscn` — 添加 Timer 节点

---

### 3.5 [P1] 敌人受伤视觉反馈

**需求**: 敌人被击中时有视觉反馈

**实现规格**:
- `take_damage()` 时: 坦克 sprite 短暂变白（0.1 秒 hit flash）
- 使用 `modulate` 属性实现:
  ```gdscript
  func _flash_hit() -> void:
      modulate = Color.WHITE  # 正常
      # 创建 hurt 红色闪烁
      modulate = Color(2, 0.5, 0.5)  # 过曝红色
      await get_tree().create_timer(0.1).timeout
      modulate = Color.WHITE
  ```
- 死亡时: 短暂爆炸动画（占位色块扩大后消失）

**待修改文件**:
- `scripts/entities/enemys/EnemyTankBase.gd` — 添加受伤闪烁效果

---

## 4. 玩家补全

### 4.1 [P0] 玩家血量系统

**需求**: PlayerTank 拥有血量，被敌人子弹击中扣血

**玩家体验目标**: 每次被击中都有紧迫感——你离死亡只差几发

**实现规格**:
- `PlayerTank` 添加:
  ```gdscript
  @export var max_hp: int = 3
  var current_hp: int
  
  func take_damage(damage: int, attacker: Tank = null) -> void:
      if invincible: return  # 无敌帧期间不受伤害
      current_hp -= damage
      EventBus.tank_damaged.emit(self, damage)
      if current_hp <= 0:
          die()
      else:
          _start_invincibility()  # 触发无敌帧
  ```
- HUD 显示当前血量（心形图标或数字）

**待修改文件**:
- `scripts/entities/tanks/PlayerTank.gd` — 添加血量属性和受伤逻辑
- `scripts/ui/WeaponHUD.gd` — 添加血量显示
- `scenes/ui/WeaponHUD.tscn` — 添加血量 UI 元素

**调校杠杆**:
- `max_hp`: 玩家耐久度（3 = 经典，5 = 宽容）
- 无敌帧持续时间: 1.5 秒 [占位符]

---

### 4.2 [P0] 玩家无敌帧

**需求**: 受伤后短暂无敌，防止连续受伤

**玩家体验目标**: 被击中后有喘息时间，不会瞬间被秒杀

**实现规格**:
- 受伤后进入无敌状态，持续 `invincibility_duration` 秒（默认 1.5 秒）
- 无敌期间: 坦克 sprite 闪烁（0.1 秒间隔切换 visible）
- 无敌期间: `take_damage()` 直接 return
- 使用 Timer 节点控制无敌持续时间

**待修改文件**:
- `scripts/entities/tanks/PlayerTank.gd` — 添加无敌帧逻辑
- `scripts/entities/tanks/Player1Tank.tscn` — 添加 InvincibilityTimer 节点

---

### 4.3 [P0] 玩家死亡与重生

**需求**: 血量归零 → 死亡，可重生

**玩家体验目标**: 死亡不是终点——重新站起来继续战斗

**实现规格**:
- `die()` 方法:
  1. 播放爆炸效果（占位）
  2. 发送 `EventBus.tank_died.emit(self)`
  3. 隐藏坦克（而非销毁），等待重生
- 重生:
  1. 在出生点重新出现
  2. 恢复满血
  3. 2 秒无敌时间
  4. 主武器等级降回 Lv.1
- 生命数: `@export var lives: int = 3`
  - 每次死亡消耗 1 条命
  - 生命耗尽 → 游戏结束（触发 `EventBus.game_over()`）

**待修改文件**:
- `scripts/entities/tanks/PlayerTank.gd` — 添加死亡、重生、生命数逻辑

**调校杠杆**:
- `lives`: 生命数（3 = 经典，5 = 宽容）
- 重生无敌时间: 2.0 秒 [占位符]
- 死亡后武器降级: 是/否

---

### 4.4 [P1] 玩家组注册（Bug 修复）

**需求**: PlayerTank 添加到 `"player_tanks"` 组

**实现规格**:
- 在 `PlayerTank._ready()` 中添加 `add_to_group("player_tanks")`
- 这修复了以下问题:
  - `PowerUp.gd` 检查 `body.is_in_group("player_tanks")` → 道具无法被拾取
  - `_find_nearest_player()` 查找 `"player_tanks"` 组 → 追踪型敌人找不到玩家

**待修改文件**:
- `scripts/entities/tanks/PlayerTank.gd` — 添加 `add_to_group("player_tanks")`

---

## 5. 子弹系统补全

### 5.1 [P0] 敌人子弹

**需求**: 敌人射击产生的子弹，使用 `LAYER_ENEMY_BULLET`

**实现规格**:
- `EnemyBullet` 场景，与 `BasicBullet` 结构相同但碰撞层不同:
  - `collision_layer = LAYER_ENEMY_BULLET`（bit 3 = 8）
  - `collision_mask = LAYER_PLAYER | LAYER_TERRAIN | LAYER_BOUNDARY | LAYER_BASE`
- 碰撞检测:
  - 击中玩家 → 调用 `player.take_damage(damage, owner_tank)`
  - 击中砖墙 → 砖墙摧毁
  - 击中钢墙 → 子弹消失（除非 can_destroy_steel）
  - 击中边界 → 子弹销毁
  - 击中基地 → 基地受损
- 视觉: 占位色块（青色 / 紫色，与玩家子弹区分）

**待创建文件**:
- `scripts/weapons/EnemyBullet.gd`
- `scenes/entities/weapons/bullets/EnemyBullet.tscn`

**调校杠杆**:
- 子弹速度: 200 px/s [占位符]（比玩家子弹慢，给玩家反应时间）
- 子弹伤害: 1

---

### 5.2 [P0] 子弹-地形交互（TileMap 适配）

**需求**: 子弹正确与 TileMapLayer 中的地形交互

**技术挑战**: TileMapLayer 碰撞回调中，`body` 是整个 TileMapLayer 节点，不是单个瓦片。需要通过碰撞坐标获取瓦片信息。

**实现方案**:

方案 A: 使用 TileSet 自定义数据层
1. 在 TerrainTileset 中为每种瓦片添加 `Custom Data Layer`（如 `tile_type: String`）
2. 子弹 `body_entered` 时，通过碰撞点坐标获取瓦片坐标 → 读取自定义数据 → 判断瓦片类型
3. 根据类型执行不同逻辑（砖墙摧毁、钢墙判断等）

方案 B: 使用多个 TileMapLayer
1. 砖墙和钢墙使用不同的 TileMapLayer
2. 子弹通过判断 body 节点名区分地形类型
3. 更简单但扩展性较差

**推荐**: 方案 A（更灵活，后续增加新地形类型无需添加新图层）

**实现规格**（方案 A）:
```gdscript
# Bullet.gd - 修改后的碰撞处理
func _on_body_entered(body: Node2D) -> void:
    if body is TileMapLayer:
        _handle_tilemap_collision(body)
        return
    # ... 原有的非 TileMap 碰撞处理

func _handle_tilemap_collision(tilemap: TileMapLayer) -> void:
    # 获取碰撞点（近似使用子弹当前位置）
    var tile_coords := tilemap.local_to_map(global_position)
    var tile_data := tilemap.get_cell_tile_data(tile_coords)
    if tile_data == null:
        queue_free()
        return
    
    var tile_type: String = tile_data.get_custom_data("tile_type")
    match tile_type:
        "brick":
            tilemap.erase_cell(tile_coords)  # 摧毁砖墙
            queue_free()
        "steel":
            if can_destroy_steel:
                tilemap.erase_cell(tile_coords)  # Lv.3 摧毁钢墙
            queue_free()
        "boundary":
            queue_free()
        _:
            queue_free()
```

**待修改文件**:
- `assets/tilesets/TerrainTileset.tres` — 添加 Custom Data Layer + 碰撞形状
- `scripts/weapons/Bullet.gd` — 重构碰撞处理，适配 TileMapLayer

---

### 5.3 [P0] 子弹击杀者追踪（Bug 修复）

**需求**: `take_damage()` 接收正确的 attacker 参数

**当前问题**: `Bullet.gd` 的 `_on_area_entered()` 调用 `enemy_tank.take_damage(damage, null)`，attacker 为 null，导致充能掠夺无法正确识别击杀者。

**实现规格**:
- Bullet 添加 `var owner_tank: Tank = null` 属性
- MainWeapon.fire() 时设置 `bullet.owner_tank = get_parent()` (PlayerTank)
- `_on_area_entered()` 中调用 `take_damage(damage, owner_tank)`

**待修改文件**:
- `scripts/weapons/Bullet.gd` — 添加 `owner_tank` 属性，修复 `_on_area_entered()`
- `scripts/weapons/MainWeapon.gd` — fire() 中设置 `bullet.owner_tank`

---

### 5.4 [P1] 子弹对象池

**需求**: 减少频繁实例化/销毁的性能开销

**实现规格**:
- 创建 `BulletPool` 单例或在场景中管理子弹池
- 预创建子弹实例（每种类型 10 个）
- 发射时从池中获取而非实例化
- 子弹"销毁"时归还池中而非 `queue_free()`
- 池满时再创建新实例

**说明**: 这是性能优化，不影响功能。如果测试场景中子弹数量不多（< 20），可以先不做。

**待创建文件**:
- `scripts/systems/BulletPool.gd` — 子弹对象池

---

## 6. TankTest.tscn 测试场景布局

完成所有功能后，TankTest.tscn 应包含以下布局:

```
┌─────────────────────────────────────┐
│ E     E                  E          │  ← 敌人生成区域（3个位置）
│                                     │
│   ███   ████   ████   ███          │  ← 砖墙区域（可破坏掩体）
│                                     │
│      ████████   ████████           │  ← 钢墙区域（需 Lv.3 破坏）
│                                     │
│   ≈≈≈   ≈≈≈≈   ≈≈≈≈               │  ← 水域区域（不可通过）
│                                     │
│          ████████                   │  ← 基地保护砖墙
│            [Base]                   │  ← 基地
│   P1          P2                    │  ← 玩家出生点
└─────────────────────────────────────┘

█ = 砖墙  ▓ = 钢墙  ≈ = 水域  E = 敌人  P = 玩家
```

**场景节点结构**:
```
TankTest (Node2D)
├── BoundaryIndicator (Line2D)       — 战场边框指示
├── GroundLayer (TileMapLayer)        — 地面瓦片
├── WaterLayer (TileMapLayer)         — 水域瓦片
├── WallLayer (TileMapLayer)          — 砖墙+钢墙瓦片
├── BoundaryLayer (TileMapLayer)      — 边界墙瓦片
├── GrassLayer (TileMapLayer)         — 草地瓦片（P2 可选）
├── Base (Base 场景实例)              — 基地实体
├── Player1Tank (Player1Tank 实例)    — 玩家1
├── Player2Tank (Player2Tank 实例)    — 玩家2
├── BasicEnemyTank (BasicEnemyTank 实例) — 基础敌人
├── ChaseEnemyTank (ChaseEnemyTank 实例) — 追踪敌人
└── Camera2D (Camera2D)              — 摄像机
```

---

## 7. 实现优先级与顺序

建议按以下顺序实现，每步完成后验证再进入下一步:

```
Phase 1: 基础设施（1-2 天）
  ├── 修复玩家组注册 bug（4.4）
  ├── 修复子弹击杀者 bug（5.3）
  └── 完善敌人血量系统（3.1）

Phase 2: 地形系统（3-5 天）
  ├── 创建 TerrainTileset 配置（砖墙+钢墙+碰撞）
  ├── 实现战场边界（2.1）
  ├── 实现砖墙（2.2）
  ├── 实现钢墙（2.3）
  ├── 适配子弹-TileMap 交互（5.2）
  └── 配置 TankTest.tscn 地形布局

Phase 3: 敌人射击与玩家血量（3-5 天）
  ├── 创建敌人子弹（5.1）
  ├── 实现敌人射击能力（3.2）
  ├── 实现玩家血量系统（4.1）
  ├── 实现玩家无敌帧（4.2）
  ├── 实现玩家死亡与重生（4.3）
  └── 敌人受伤视觉反馈（3.4）

Phase 4: 扩展功能（2-3 天）
  ├── 实现水域地形（2.4）
  ├── 创建追踪型敌人（3.3）
  ├── 实现射击冷却管理（3.4）
  └── 基地系统（2.5）

Phase 5: 验证与调校（1-2 天）
  ├── 完整游玩 TankTest.tscn
  ├── 调校数值（血量、速度、冷却等）
  ├── 修复发现的 bug
  └── 更新文档
```

---

## 8. 数值调校表

所有数值为初始假设 `[占位符]`，需在 Phase 5 验证后调整:

| 变量 | 基础值 | 最小值 | 最大值 | 调校备注 |
|------|--------|--------|--------|----------|
| 玩家 max_hp | 3 | 1 | 10 | 经典90坦克 = 1命，这里3命给容错 |
| 玩家 lives | 3 | 1 | 5 | 总共能死几次 |
| 无敌帧持续时间 | 1.5s | 0.5s | 3.0s | 太长不紧张，太短不公平 |
| 基础敌人 max_hp | 1 | 1 | 5 | 1 = 经典一炮杀 |
| 追踪敌人 max_hp | 2 | 1 | 8 | 比基础敌人更耐打 |
| 敌人射击冷却 | 2.0s | 0.5s | 5.0s | 太快=不公平，太慢=无威胁 |
| 敌人射击概率/决策 | 30% | 10% | 60% | 每次决策 tick 触发射击的概率 |
| 敌人子弹速度 | 200 px/s | 100 | 400 | 比玩家子弹慢，给反应时间 |
| 追踪敌人 chase_range | 250 px | 100 | 500 | ≈ 8 格距离开始追踪 |
| 重生无敌时间 | 2.0s | 1.0s | 5.0s | 出生时保护 |

---

## 9. 已知技术债

以下问题在 Sprint 1 中不修复，记录在此以便后续处理:

| 编号 | 问题 | 影响 | 建议修复时间 |
|------|------|------|-------------|
| TD-1 | 输入使用 `Input.is_key_pressed()` 硬编码 | 无法自定义键位 | Sprint 5 |
| TD-2 | Player2Tank 无法射击（未重写武器输入方法） | 玩家2无法游玩 | Sprint 1 顺便修 |
| TD-3 | 子弹/导弹未使用对象池 | 大量实例化时性能下降 | Sprint 2 |
| TD-4 | MainWeapon 硬编码武器数据（未使用 .tres 资源） | 配置不灵活 | Sprint 3 |
| TD-5 | Godot State Charts 插件已引入但未使用 | 状态管理分散 | Sprint 2 |
| TD-6 | 爆炸/受伤效果全部使用占位色块 | 视觉粗糙 | Sprint 4 |

---

## 10. 验收检查清单

Sprint 1 完成后，逐项验证:

### 地形
- [ ] 玩家无法移出战场边界
- [ ] 子弹超出战场边界后销毁
- [ ] 玩家子弹击中砖墙 → 砖墙消失，子弹消失
- [ ] Lv.1/2 子弹击中钢墙 → 子弹消失，钢墙不损
- [ ] Lv.3 子弹击中钢墙 → 钢墙消失，子弹消失
- [ ] 坦克无法穿越水域
- [ ] 子弹可以飞越水域

### 敌人
- [ ] 基础敌人随机巡逻移动
- [ ] 敌人被击中 1 次（基础）→ 死亡
- [ ] 敌人血量 > 1 时，被击中后受伤但不死
- [ ] 敌人会向当前朝向射击
- [ ] 敌人子弹击中玩家 → 玩家扣血
- [ ] 追踪型敌人在范围内主动追踪玩家

### 玩家
- [ ] 玩家被击中 → 扣血 + 短暂无敌闪烁
- [ ] 玩家血量归零 → 死亡 + 扣一条命 + 重生
- [ ] 玩家生命耗尽 → 游戏结束
- [ ] 武器升级道具可以正常拾取
- [ ] 击杀敌人后充能值增加
- [ ] 释放副武器正常工作

### 子弹
- [ ] 玩家子弹和敌人子弹不会互相误伤
- [ ] 击杀敌人时充能正确归属（不是 null）
- [ ] 子弹击中地形后正确销毁

### 整体
- [ ] 无控制台报错
- [ ] 碰撞无穿透/卡墙现象
- [ ] 游戏运行 5 分钟内无内存持续增长

---

*本文档为 Sprint 1 的权威需求来源。任何需求变更需更新此文档并通知开发团队。*
