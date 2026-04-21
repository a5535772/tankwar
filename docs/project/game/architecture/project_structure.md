# 项目架构与目录结构文档

## 1. 项目结构概览

```
project/
├── assets/           # 游戏资源
│   ├── images/       # 图片资源
│   │   ├── tanks/    # 坦克精灵图
│   │   ├── bullets/  # 炮弹精灵图
│   │   ├── terrain/  # 地形元素
│   │   ├── effects/  # 特效图片
│   │   └── powerups/ # 道具图标
│   ├── audio/        # 音频文件
│   │   ├── music/    # 背景音乐
│   │   └── sfx/      # 音效
│   └── fonts/        # 字体文件
├── docs/             # 项目文档
│   ├── game/         # 游戏设计文档
│   ├── me2ai/        # 用户提供的信息
│   ├── shared/       # 共享文档
│   └── ai2ai/        # AI 工作记录
├── scenes/           # 场景文件
│   ├── entities/     # 实体场景
│   │   ├── tanks/    # 坦克场景
│   │   └── bullets/  # 炮弹场景
│   ├── levels/       # 关卡场景
│   ├── terrain/      # 地形场景
│   ├── powerups/     # 道具场景
│   ├── system/       # 系统场景
│   └── ui/           # UI 场景
├── scripts/          # 脚本文件
│   ├── systems/      # 全局单例系统
│   │   ├── EventBus.gd          # 事件总线
│   │   ├── GameManager.gd       # 游戏管理器
│   │   ├── LevelManager.gd      # 关卡管理器
│   │   ├── SaveSystem.gd        # 存档系统
│   │   └── CollisionLayers.gd   # 碰撞层定义
│   ├── entities/     # 游戏实体
│   │   ├── tanks/    # 坦克相关
│   │   │   ├── Tank.gd           # 坦克基类
│   │   │   ├── PlayerTank.gd     # 玩家坦克
│   │   │   ├── EnemyTank.gd      # 敌人坦克
│   │   │   └── TankController.gd # 坦克控制器
│   │   └── bullets/  # 炮弹相关
│   │       ├── Bullet.gd         # 炮弹基类
│   │       └── BulletSpawner.gd  # 炮弹生成器
│   ├── terrain/      # 地形相关
│   │   ├── BrickWall.gd          # 砖墙
│   │   ├── SteelWall.gd          # 钢墙
│   │   ├── Grass.gd              # 草地
│   │   ├── Water.gd              # 水域
│   │   └── Ice.gd                # 冰面
│   ├── powerups/     # 道具系统
│   │   ├── PowerUp.gd            # 道具基类
│   │   ├── ShieldPowerUp.gd      # 护盾道具
│   │   ├── SpeedPowerUp.gd       # 加速道具
│   │   └── PowerPowerUp.gd       # 火力增强道具
│   └── ui/           # UI 相关
│       ├── HUD.gd               # 游戏HUD
│       └── Menu.gd              # 菜单系统
└── project.godot     # 项目配置文件
```

## 2. 目录结构说明

### 2.1 核心目录

#### scripts/systems/ - 全局单例系统
- **EventBus.gd**：事件总线，处理游戏中的所有事件
- **GameManager.gd**：游戏管理器，管理游戏状态
- **LevelManager.gd**：关卡管理器，管理关卡进度、敌人生成、胜负判定
- **SaveSystem.gd**：存档系统，保存和加载游戏数据
- **CollisionLayers.gd**：碰撞层定义，管理游戏中的碰撞关系

#### scripts/entities/ - 游戏实体
- **tanks/**：坦克相关脚本
  - Tank.gd：坦克基类，包含移动、射击、生命值等基础功能
  - PlayerTank.gd：玩家坦克，处理玩家输入和特殊能力
  - EnemyTank.gd：敌人坦克，实现AI行为
  - TankController.gd：坦克控制器，处理移动和旋转逻辑
- **bullets/**：炮弹相关脚本
  - Bullet.gd：炮弹基类，处理移动、碰撞和爆炸
  - BulletSpawner.gd：炮弹生成器，管理炮弹对象池

#### scripts/terrain/ - 地形元素
- **BrickWall.gd**：砖墙脚本，可被炮弹摧毁
- **SteelWall.gd**：钢墙脚本，需要多次攻击或特殊道具才能摧毁
- **Grass.gd**：草地脚本，提供隐蔽效果
- **Water.gd**：水域脚本，不可通过
- **Ice.gd**：冰面脚本，提供滑动效果

#### scripts/powerups/ - 道具系统
- **PowerUp.gd**：道具基类，定义道具基础属性和行为
- **ShieldPowerUp.gd**：护盾道具，提供临时无敌效果
- **SpeedPowerUp.gd**：加速道具，提升移动速度
- **PowerPowerUp.gd**：火力增强道具，增强炮弹威力

### 2.2 场景目录

#### scenes/ - 场景文件
- **entities/**：实体场景
  - **tanks/**：坦克场景
    - PlayerTank.tscn：玩家坦克场景
    - EnemyTank.tscn：敌人坦克场景
  - **bullets/**：炮弹场景
    - Bullet.tscn：炮弹场景
- **levels/**：关卡场景
  - Level1.tscn：第一关
  - Level2.tscn：第二关
- **terrain/**：地形场景
  - BrickWall.tscn：砖墙场景
  - SteelWall.tscn：钢墙场景
  - Grass.tscn：草地场景
  - Water.tscn：水域场景
  - Ice.tscn：冰面场景
- **powerups/**：道具场景
  - ShieldPowerUp.tscn：护盾道具场景
  - SpeedPowerUp.tscn：加速道具场景
  - PowerPowerUp.tscn：火力增强道具场景
- **system/**：系统场景
  - Camera2D.tscn：摄像机场景
- **ui/**：UI 场景
  - HUD.tscn：游戏HUD场景
  - Menu.tscn：主菜单场景

## 3. 架构设计原则

### 3.1 模块化设计
- **职责分离**：每个模块只负责特定功能
- **组件化**：将功能拆分为独立可复用的组件
- **单例模式**：全局系统使用单例模式，确保唯一实例

### 3.2 状态机驱动
- **StateChart**：使用 Godot 的状态机系统管理复杂行为
- **状态管理**：坦克和游戏流程使用状态机管理状态转换
- **清晰的状态逻辑**：状态机使得复杂行为逻辑更加清晰和可维护

### 3.3 事件驱动
- **EventBus**：作为中央事件系统，实现模块间通信
- **松耦合**：模块通过事件通信，减少直接依赖
- **可扩展性**：新功能可以通过监听事件轻松集成

### 3.4 碰撞系统
- **分层碰撞**：使用碰撞层和遮罩管理实体间的碰撞关系
- **Area2D 伤害检测**：使用 Area2D 进行伤害检测，避免物理碰撞的复杂性
- **统一碰撞配置**：所有实体使用统一的碰撞层定义

### 3.5 对象池优化
- **炮弹池**：使用对象池管理炮弹实例，避免频繁创建和销毁
- **特效池**：爆炸特效使用对象池管理，提升性能
- **内存优化**：减少内存分配和垃圾回收开销

## 4. 核心系统架构

### 4.1 坦克系统
- **Tank**：坦克基类，定义移动、射击、生命值等基础功能
- **PlayerTank**：玩家坦克，处理玩家输入和特殊能力
- **EnemyTank**：敌人坦克，实现AI行为（巡逻、追击、射击）
- **TankController**：坦克控制器，处理移动和旋转逻辑

### 4.2 炮弹系统
- **Bullet**：炮弹基类，处理移动、碰撞和爆炸
- **BulletSpawner**：炮弹生成器，管理炮弹对象池
- **碰撞检测**：与不同地形类型的交互（砖墙可摧毁、钢墙反弹等）

### 4.3 地形系统

> **详细设计文档**: [terrain_boundary_design.md](./terrain_boundary_design.md)

- **可破坏地形**：砖墙可被炮弹摧毁
- **不可破坏地形**：钢墙需要特殊道具或多次攻击
- **特殊地形**：草地提供隐蔽、水域不可通过、冰面提供滑动效果
- **边界系统**：战场外围的不可摧毁墙壁，限制坦克和子弹活动范围
- **网格对齐**：所有地形元素与 32x32 像素网格对齐

### 4.4 道具系统
- **道具基类**：定义道具基础属性和行为
- **道具类型**：护盾、加速、火力增强、生命恢复等
- **道具效果**：临时增益效果，有时间限制或使用次数限制
- **道具掉落**：击毁特定敌人掉落道具

### 4.5 关卡系统
- **LevelManager**：管理关卡进度、敌人生成、胜负判定
- **关卡数据**：关卡配置存储为 JSON 或自定义资源格式
- **敌人生成**：按波次生成敌人，控制难度曲线
- **基地保护**：监控基地状态，判定游戏胜负

### 4.6 事件系统
- **全局事件总线**：EventBus 作为全局单例
- **事件类型**：坦克伤害、坦克死亡、炮弹发射、道具拾取、关卡完成、游戏结束
- **事件传递**：通过信号机制实现事件的发射和订阅

### 4.7 碰撞系统

> **详细设计文档**: [collision_system_design.md](./collision_system_design.md)

- **碰撞层定义**：LAYER_PLAYER、LAYER_ENEMY、LAYER_PLAYER_BULLET、LAYER_ENEMY_BULLET、LAYER_TERRAIN、LAYER_BOUNDARY、LAYER_BASE、LAYER_POWERUP
- **碰撞遮罩**：根据实体类型设置不同的碰撞遮罩
- **伤害检测**：使用 Area2D 进行非物理碰撞的伤害检测

## 5. 开发流程

1. **系统初始化**：游戏启动时加载全局单例系统
2. **场景加载**：LevelManager 负责加载关卡场景
3. **实体初始化**：场景中的实体初始化并注册到相应系统
4. **游戏循环**：物理更新、状态管理、事件处理
5. **敌人生成**：按关卡配置生成敌人坦克
6. **胜负判定**：监控基地状态和敌人数量，判定游戏胜负
7. **存档管理**：SaveSystem 定期保存游戏状态

## 6. 扩展建议

### 6.1 未来扩展
- **abilities/**：坦克能力系统（特殊技能、被动能力等）
- **enemies/**：敌人类型扩展（不同AI行为、特殊能力）
- **weapons/**：武器系统（不同炮弹类型、特殊武器）
- **ui/**：HUD 和菜单系统扩展
- **levels/**：关卡场景和管理
- **resources/**：数据资源管理
- **effects/**：特效系统

### 6.2 最佳实践
- 遵循现有的目录结构
- 使用事件系统进行模块间通信
- 保持代码模块化和可测试性
- 为新功能创建相应的文档
- 使用状态机管理复杂行为逻辑
- 遵循碰撞层规范
- 使用对象池优化性能
- 保持网格对齐的设计原则

## 7. 技术栈

- **引擎**：Godot 4.3
- **语言**：GDScript
- **架构**：模块化、事件驱动、状态机驱动
- **工具**：Godot 编辑器
- **状态管理**：Godot State Charts 插件
- **性能优化**：对象池、网格对齐、碰撞优化

此架构设计为游戏提供了清晰的结构和良好的扩展性，便于后续功能的添加和维护。