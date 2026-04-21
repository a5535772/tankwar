## 引擎与语言

- **引擎**：Godot 4.3 稳定版
- **渲染模式**：Forward Plus
- **主要编程语言**：GDScript（遵循官方风格指南）
- **状态机插件**：Godot State Charts（位于 `godot-statecharts-main/addons/godot_state_charts/`）

---

## 项目结构规范

```
project/
├── assets/                     # 游戏资源
│   └── images/
│       └── Retina/             # 像素风格素材（坦克、子弹、爆炸、障碍物等）
├── docs/                       # 项目文档
│   ├── me2ai/                  # 用户提供的信息（只读）
│   │   ├── OVERVIEW.md         # 项目概要
│   │   ├── TECH_STACK.md       # 技术栈文档（本文档）
│   │   └── ME2AI.md            # 用户对 AI 的原则和要求
│   ├── shared/                 # 双方共同维护的动态信息
│   │   └── CURRENT_TASKS.md    # 当前任务备忘录
│   ├── ai2ai/                  # AI 自行记录的工作日志
│   │   └── AI2AI.md            # AI 工作记录
│   └── game/                   # 游戏设计文档
│       ├── architecture/       # 架构设计文档
│       ├── player/             # 玩家相关文档
│       └── enemies/            # 敌人相关文档
├── resources/                  # 资源文件
│   └── weapons/                # 武器配置资源（.tres）
├── scenes/                     # 场景文件
│   ├── entities/
│   │   ├── tanks/              # 坦克场景
│   │   ├── enemys/             # 敌人场景
│   │   └── weapons/            # 武器场景
│   │       └── bullets/        # 子弹场景
│   ├── levels/                 # 关卡场景
│   ├── powerups/               # 道具场景
│   └── ui/                     # UI 场景
├── scripts/                    # 脚本文件
│   ├── systems/                # 全局单例系统
│   │   ├── EventBus.gd         # 事件总线（已实现）
│   │   └── CollisionLayers.gd  # 碰撞层定义（已实现）
│   ├── entities/
│   │   ├── tanks/              # 坦克脚本
│   │   │   ├── Tank.gd         # 坦克基类
│   │   │   ├── PlayerTank.gd   # 玩家坦克基类
│   │   │   ├── Player1Tank.gd  # 玩家1
│   │   │   └── Player2Tank.gd  # 玩家2
│   │   └── enemys/             # 敌人脚本
│   │       ├── EnemyTankBase.gd    # 敌人坦克基类
│   │       └── BasicEnemyTank.gd   # 基础敌人
│   ├── weapons/                # 武器系统
│   │   ├── WeaponManager.gd    # 武器管理器
│   │   ├── MainWeapon.gd       # 主武器控制器
│   │   ├── MainWeaponData.gd   # 主武器配置数据
│   │   ├── Bullet.gd           # 子弹基类
│   │   ├── ChargeSystem.gd     # 充能系统
│   │   ├── SecondaryWeapon.gd  # 副武器基类
│   │   ├── Missile.gd          # 导弹实体
│   │   ├── EMPWave.gd          # EMP 波实体
│   │   └── secondary/          # 副武器实现
│   │       ├── MissileBarrage.gd   # 导弹弹幕
│   │       └── EMPShockwave.gd     # EMP 冲击波
│   ├── powerups/               # 道具系统
│   │   ├── PowerUp.gd          # 道具基类
│   │   └── WeaponUpgradePowerUp.gd # 武器升级道具
│   └── ui/                     # UI 脚本
│       └── WeaponHUD.gd        # 武器 HUD
├── godot-statecharts-main/     # 状态机插件
│   └── addons/godot_state_charts/
└── project.godot               # 项目配置
```

---

## 核心架构模式

### 单例系统（Autoload）

| 名称 | 脚本 | 状态 | 用途 |
|------|------|------|------|
| EventBus | `scripts/systems/EventBus.gd` | 已实现 | 全局事件总线，解耦模块间通信 |

### 类继承设计

采用面向对象设计，通过继承实现代码复用：

**坦克体系**
```
CharacterBody2D
└── Tank                    # 坦克基类（移动、旋转、动画、碰撞配置）
    ├── PlayerTank          # 玩家基类（输入框架、武器管理、HUD连接）
    │   ├── Player1Tank     # 玩家1（WASD移动，J射击）
    │   └── Player2Tank     # 玩家2（方向键移动，/射击）
    └── EnemyTankBase       # 敌人基类（AI决策框架、充能掉落）
        └── BasicEnemyTank  # 基础敌人（随机巡逻行为）
```

**武器体系**
```
Node
├── WeaponManager           # 武器管理器（主副武器集成、充能管理）
├── MainWeapon              # 主武器（射击、升级、冷却）
├── SecondaryWeapon         # 副武器基类（充能消耗、效果框架）
│   ├── MissileBarrage      # 导弹弹幕
│   └── EMPShockwave        # EMP 冲击波
└── ChargeSystem            # 充能系统（充能获取、消耗、信号）

Area2D
├── Bullet                  # 子弹基类
├── Missile                 # 导弹实体
└── EMPWave                 # EMP 波实体
```

**道具体系**
```
Area2D
└── PowerUp                 # 道具基类
    └── WeaponUpgradePowerUp # 武器升级道具
```

---

## 碰撞系统设计

### 碰撞层定义（CollisionLayers.gd）

使用位掩码定义碰撞层，便于灵活配置碰撞关系：

| 层名称 | 位值 | 用途 |
|--------|------|------|
| LAYER_PLAYER | 1 << 0 | 玩家坦克（包括玩家1和玩家2） |
| LAYER_ENEMY | 1 << 1 | 敌人坦克 |
| LAYER_PLAYER_BULLET | 1 << 2 | 玩家炮弹 |
| LAYER_ENEMY_BULLET | 1 << 3 | 敌人炮弹 |
| LAYER_TERRAIN | 1 << 4 | 地形（TileMap中的墙壁、障碍物） |
| LAYER_BOUNDARY | 1 << 5 | 边界墙（战场边界） |
| LAYER_BASE | 1 << 6 | 基地（需保护的目标） |
| LAYER_POWERUP | 1 << 7 | 道具 |

### 碰撞配置规则

| 实体 | Layer | Mask | 说明 |
|------|-------|------|------|
| PlayerTank | LAYER_PLAYER | TERRAIN, BOUNDARY, PLAYER | 检测地形、边界、友军 |
| EnemyTankBase | LAYER_ENEMY | TERRAIN, BOUNDARY, ENEMY, PLAYER | 检测地形、边界、友军、玩家 |
| Bullet (玩家) | LAYER_PLAYER_BULLET | TERRAIN, ENEMY, BOUNDARY | 检测地形、敌人、边界 |
| PowerUp | LAYER_POWERUP | PLAYER | 仅检测玩家 |

---

## 事件驱动架构

通过 EventBus 单例实现模块间解耦通信：

```gdscript
# 坦克相关信号
signal enemy_killed(enemy: Node, killer: Node)    # 敌人被击杀
signal tank_damaged(tank: Node, damage: int)      # 坦克受伤
signal tank_died(tank: Node)                      # 坦克死亡

# 武器相关信号
signal weapon_upgraded(weapon_type: String, new_level: int)  # 武器升级
signal secondary_weapon_unlocked(weapon: Node)               # 副武器解锁

# 道具相关信号
signal powerup_collected(power_up: Node, collector: Node)    # 道具拾取

# 关卡相关信号
signal level_started()                  # 关卡开始
signal level_finished(success: bool)    # 关卡结束
signal game_over()                      # 游戏结束
```

---

## 武器系统设计

### 主武器等级配置

| 等级 | 场景 | 速度 | 伤害 | 冷却 | 特性 |
|------|------|------|------|------|------|
| 1 | BasicBullet | 400 | 1 | 0.5s | 普通炮弹 |
| 2 | FastBullet | 500 | 1 | 0.3s | 快速炮弹 |
| 3 | SteelDestroyerBullet | 450 | 2 | 0.4s | 可摧毁钢墙 |

### 副武器类型

| 名称 | 充能消耗 | 效果 |
|------|----------|------|
| 导弹弹幕 (MissileBarrage) | 50 | 发射8枚追踪导弹 |
| EMP冲击波 (EMPShockwave) | 40 | 范围内敌人瘫痪 |

### 充能系统

- **最大充能**：100
- **获取方式**：击杀敌人掠夺充能值
- **消耗方式**：释放副武器时消耗
- **HUD同步**：通过信号实时更新显示

---

## 资源管理

- **图片格式**：优先使用 PNG（支持透明），像素艺术建议使用 16x16 或 32x32 单位。
- **音频格式**：音乐使用 OGG Vorbis（`.ogg`），音效使用 WAV（`.wav`）以获得更好的实时播放性能。
- **字体**：使用 `.ttf` 或 `.otf`，通过动态字体导入。
- **导入设置**：所有资源通过 Godot 的导入系统管理（`.import` 文件自动生成），不应手动修改。可根据需要调整纹理过滤（如"最近邻"保持像素清晰度）和压缩。

---

## 版本控制

- **工具**：Git

- **忽略文件**（.gitignore）：
  ```
  .import/
  exports/
  *.translation
  *.import
  .godot/
  ```

- **提交规范**：每次提交信息应清晰描述改动，如 "Add player tank movement" 或 "Fix bullet collision detection"。

---

## 第三方服务

- 初期无需后端服务。若后续需要（如排行榜、云存档），可考虑 Firebase 或自建简单后端（Node.js + Express）。

---

## 导出平台

- **Windows（桌面）**：作为主要目标平台，确保所有功能在 Windows 上正常运行。
- **Web（HTML5）**：后续支持，需注意音频自动播放限制、文件系统访问差异。
- **macOS / Linux**：可选，但应保持跨平台兼容性。

---

## 开发工具建议

- **像素绘图**：Aseprite、Piskel 或 GraphicsGale。
- **音效制作**：BFXR、ChipTone 或 Audacity。
- **关卡设计**：直接在 Godot 编辑器中搭建场景，利用 TileMap 节点绘制地形。

---

## 代码规范要点

- **变量/函数命名**：`snake_case`
- **类/节点名**：`PascalCase`
- **常量**：`ALL_CAPS`
- **注释**：对复杂逻辑、信号连接、公共接口进行注释。
- **类型提示**：尽可能使用静态类型声明（如 `var speed: float = 100.0`）。

---

## 特效实现

- 使用 Godot 内置粒子系统（`CPUParticles2D` 或 `GPUParticles2D`）实现动态特效，如炮弹爆炸、坦克爆炸、道具拾取闪光等。
- 优先采用 `GPUParticles2D` 以获得更好性能，但注意兼容性。
- 特效材质可配合 `ShaderMaterial` 制作简单着色器效果。

---

## 物理设置

- 使用 Godot 2D 物理引擎，世界重力设为 `0`（俯视角游戏）。
- 坦克使用 `CharacterBody2D`，移动通过 `move_and_slide()` 实现。
- 地形元素使用 `StaticBody2D`（砖墙、钢墙）或 `Area2D`（草地、水域）。
- 炮弹使用 `Area2D` 或 `RigidBody2D` 进行碰撞检测。
- **网格对齐**：32x32 像素。

---

## 性能注意事项

- 避免在 `_process()` 中频繁创建对象。
- 使用对象池（Object Pooling）管理炮弹和爆炸特效。
- 合理使用节点组和信号进行通信，减少全局查找。
- 关卡中 TileMap 应尽量合并碰撞形状，减少物理计算开销。
- 限制同屏炮弹和爆炸特效数量。

---

## 游戏特定技术要点

- **网格移动系统**：坦克移动应与网格对齐（32x32），确保流畅的移动体验。
- **炮弹碰撞**：炮弹应正确处理与不同地形类型的交互（砖墙可摧毁、钢墙反弹等）。
- **敌人AI**：使用 Timer 驱动决策周期，基类提供决策框架，子类实现具体行为。
- **道具效果**：道具效果应有明确的时间限制或使用次数限制。
- **关卡数据**：关卡数据可存储为 JSON 或自定义资源格式，便于关卡编辑。
