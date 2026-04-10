# 开发命令参考

本文档列出了坦克大战项目的常用开发命令和操作。

<!-- AUTO-GENERATED: Generated from project.godot and GDScript files -->

## Godot 编辑器命令

### 运行项目

| 命令 | 描述 |
|------|------|
| `godot4 project.godot` | 在编辑器中打开项目 |
| `godot4 --path .` | 运行项目（主场景） |
| `godot4 --path . --editor` | 在编辑器中打开项目 |
| F5 | 在编辑器中运行主场景 |
| F6 | 在编辑器中运行当前场景 |

### 项目配置

| 配置项 | 值 | 描述 |
|--------|-----|------|
| 引擎版本 | Godot 4.3 | 项目使用的 Godot 版本 |
| 主场景 | `res://scenes/levels/TankTest.tscn` | 默认运行场景 |
| 项目名称 | tankwar | 项目名称 |

## 场景结构

### 实体场景

| 场景路径 | 类名 | 描述 |
|----------|------|------|
| `scenes/entities/tanks/Tank.tscn` | `Tank` | 坦克基类场景 |
| `scenes/entities/tanks/Player1Tank.tscn` | `Player1Tank` | 玩家1坦克场景（WASD + J射击） |
| `scenes/entities/tanks/Player2Tank.tscn` | `Player2Tank` | 玩家2坦克场景（方向键控制） |
| `scenes/entities/enemys/BasicEnemyTank.tscn` | `BasicEnemyTank` | 基础敌人坦克场景 |

### 武器场景

| 场景路径 | 类名 | 描述 |
|----------|------|------|
| `scenes/bullets/BasicBullet.tscn` | `Bullet` | Lv.1 普通炮弹（黄色） |
| `scenes/bullets/FastBullet.tscn` | `Bullet` | Lv.2 快速炮弹（橙色） |
| `scenes/bullets/SteelDestroyerBullet.tscn` | `Bullet` | Lv.3 消钢炮弹（红色） |
| `scenes/powerups/WeaponUpgradePowerUp.tscn` | `WeaponUpgradePowerUp` | 武器升级道具 |
| `scenes/ui/WeaponHUD.tscn` | `WeaponHUD` | 武器 HUD 界面 |

### 关卡场景

| 场景路径 | 描述 |
|----------|------|
| `scenes/levels/TankTest.tscn` | 坦克测试场景（包含玩家和敌人） |

## 脚本结构

### 核心系统脚本

| 脚本路径 | 类名 | 描述 |
|----------|------|------|
| `scripts/systems/CollisionLayers.gd` | `CollisionLayers` | 碰撞层定义 |
| `scripts/systems/EventBus.gd` | `EventBus` | 全局事件总线单例 |

### 武器系统脚本

| 脚本路径 | 类名 | 描述 |
|----------|------|------|
| `scripts/weapons/ChargeSystem.gd` | `ChargeSystem` | 副武器充能系统 |
| `scripts/weapons/MainWeaponData.gd` | `MainWeaponData` | 主武器数据资源 |
| `scripts/weapons/MainWeapon.gd` | `MainWeapon` | 主武器控制类 |
| `scripts/weapons/Bullet.gd` | `Bullet` | 子弹基类 |
| `scripts/weapons/SecondaryWeapon.gd` | `SecondaryWeapon` | 副武器基类 |
| `scripts/weapons/WeaponManager.gd` | `WeaponManager` | 武器管理器 |

### 道具系统脚本

| 脚本路径 | 类名 | 描述 |
|----------|------|------|
| `scripts/powerups/PowerUp.gd` | `PowerUp` | 道具基类 |
| `scripts/powerups/WeaponUpgradePowerUp.gd` | `WeaponUpgradePowerUp` | 武器升级道具 |

### UI 脚本

| 脚本路径 | 类名 | 描述 |
|----------|------|------|
| `scripts/ui/WeaponHUD.gd` | `WeaponHUD` | 武器 HUD 显示 |

### 坦克脚本层次

| 脚本路径 | 类名 | 描述 |
|----------|------|------|
| `scripts/entities/tanks/Tank.gd` | `Tank` | 坦克基类（移动、旋转、动画） |
| `scripts/entities/tanks/PlayerTank.gd` | `PlayerTank` | 玩家坦克基类（输入抽象、武器系统） |
| `scripts/entities/tanks/Player1Tank.gd` | `Player1Tank` | 玩家1坦克（WASD + J射击 + K副武器） |
| `scripts/entities/tanks/Player2Tank.gd` | `Player2Tank` | 玩家2坦克（方向键控制） |
| `scripts/entities/tanks/EnemyTankBase.gd` | `EnemyTankBase` | 敌人坦克基类（AI 框架、充能值） |
| `scripts/entities/tanks/BasicEnemyTank.gd` | `BasicEnemyTank` | 基础敌人坦克（随机巡逻） |

## 碰撞层定义

| 层名称 | 值 | 描述 |
|--------|-----|------|
| `LAYER_PLAYER` | 1 << 0 | 玩家坦克层 |
| `LAYER_ENEMY` | 1 << 1 | 敌人坦克层 |
| `LAYER_PLAYER_BULLET` | 1 << 2 | 玩家炮弹层 |
| `LAYER_ENEMY_BULLET` | 1 << 3 | 敌人炮弹层 |
| `LAYER_TERRAIN` | 1 << 4 | 地形层（墙壁、障碍物） |
| `LAYER_BOUNDARY` | 1 << 5 | 边界墙层 |
| `LAYER_BASE` | 1 << 6 | 基地层 |
| `LAYER_POWERUP` | 1 << 7 | 道具层 |

## EventBus 信号

| 信号 | 参数 | 描述 |
|------|------|------|
| `enemy_killed` | (enemy: Node, killer: Node) | 敌人被击杀 |
| `tank_damaged` | (tank: Node, damage: int) | 坦克受伤 |
| `tank_died` | (tank: Node) | 坦克死亡 |
| `weapon_upgraded` | (weapon_type: String, new_level: int) | 武器升级 |
| `secondary_weapon_unlocked` | (weapon: Node) | 副武器解锁 |
| `powerup_collected` | (power_up: Node, collector: Node) | 道具拾取 |
| `level_started` | - | 关卡开始 |
| `level_finished` | (success: bool) | 关卡结束 |
| `game_over` | - | 游戏结束 |

## 主武器属性

| 等级 | 名称 | 子弹速度 | 伤害 | 冷却 | 特殊能力 | 颜色 |
|------|------|----------|------|------|----------|------|
| Lv.1 | 普通炮弹 | 400 px/s | 1 | 0.5s | 无 | 黄色 |
| Lv.2 | 快速炮弹 | 500 px/s | 1 | 0.3s | 射速提升 | 橙色 |
| Lv.3 | 消钢炮弹 | 450 px/s | 2 | 0.4s | 可摧毁钢墙 | 红色 |

<!-- END AUTO-GENERATED -->

## 开发工作流

### 创建新的敌人类型

1. 创建新脚本继承 `EnemyTankBase`：
   ```gdscript
   class_name NewEnemyTank
   extends "res://scripts/entities/tanks/EnemyTankBase.gd"

   func _on_decision_tick():
       # 实现自定义 AI 行为
       pass
   ```

2. 创建新场景继承坦克结构
3. 在场景中配置脚本和资源
4. 在关卡中实例化测试

### 创建新的玩家坦克

1. 创建新脚本继承 `PlayerTank`：
   ```gdscript
   class_name Player3Tank
   extends "res://scripts/entities/tanks/PlayerTank.gd"

   func _get_input_direction() -> Vector2:
       # 实现自定义输入映射
       return Vector2.ZERO

   func _handle_main_weapon_input() -> void:
       # 实现主武器射击键位
       pass

   func _handle_secondary_weapon_input() -> void:
       # 实现副武器释放键位
       pass
   ```

2. 创建新场景
3. 配置控制键位和视觉资源

### 添加新的副武器

1. 创建新脚本继承 `SecondaryWeapon`：
   ```gdscript
   class_name NewSecondaryWeapon
   extends "res://scripts/weapons/SecondaryWeapon.gd"

   func _execute_fire(owner: Tank) -> void:
       # 实现武器效果
       pass
   ```

2. 创建新场景（可选）
3. 在 WeaponManager 中添加到 secondary_weapons 数组

### 添加新的道具类型

1. 创建新脚本继承 `PowerUp`：
   ```gdscript
   class_name NewPowerUp
   extends "res://scripts/powerups/PowerUp.gd"

   func apply_effect(collector: Node) -> void:
       # 实现道具效果
       pass
   ```

2. 创建新场景
3. 在敌人掉落逻辑中添加掉落概率

## 常见问题排查

### 场景保存错误
- **症状**：保存场景时报错"依赖项存在问题"
- **原因**：Godot 资源索引缓存问题
- **解决**：重启编辑器或 Project → Reload Current Project

### 碰撞检测不工作
- **检查项**：
  1. 确认碰撞层（collision_layer）设置正确
  2. 确认碰撞遮罩（collision_mask）包含目标层
  3. 确认 CollisionShape2D 节点存在且配置正确

### 动画不播放
- **检查项**：
  1. AnimatedSprite2D 节点的 SpriteFrames 资源是否正确
  2. 动画名称是否匹配（"move"、"idle"）
  3. 是否调用了 `play()` 方法

### 主武器无法射击
- **检查项**：
  1. 确认 WeaponManager 已添加到坦克节点
  2. 确认 MainWeapon 初始化成功（查看控制台输出）
  3. 确认子弹场景文件存在并可加载
  4. 确认射击键位正确（Player1Tank 为 J 键）

### 子弹方向错误
- **原因**：坦克旋转角度与方向向量转换错误
- **解决**：使用 `_get_facing_direction()` 方法根据旋转角度获取方向

### 充能系统不工作
- **检查项**：
  1. 确认敌人有 `charge_value` 属性
  2. 确认击杀时触发 `EventBus.enemy_killed` 信号
  3. 确认 WeaponManager 已连接事件总线
