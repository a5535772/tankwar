## 引擎与语言

- **引擎**：Godot 4.3 稳定版
- **主要编程语言**：GDScript（遵循官方风格指南）
- **可选语言**：C#（如需要，需提前说明，并配置对应构建工具）

## 项目结构规范

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

## 资源管理

- **图片格式**：优先使用 PNG（支持透明），像素艺术建议使用 16x16 或 32x32 单位。
- **音频格式**：音乐使用 OGG Vorbis（`.ogg`），音效使用 WAV（`.wav`）以获得更好的实时播放性能。
- **字体**：使用 `.ttf` 或 `.otf`，通过动态字体导入。
- **导入设置**：所有资源通过 Godot 的导入系统管理（`.import` 文件自动生成），不应手动修改。可根据需要调整纹理过滤（如"最近邻"保持像素清晰度）和压缩。

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

## 第三方服务

- 初期无需后端服务。若后续需要（如排行榜、云存档），可考虑 Firebase 或自建简单后端（Node.js + Express）。

## 导出平台

- **Windows（桌面）**：作为主要目标平台，确保所有功能在 Windows 上正常运行。
- **Web（HTML5）**：后续支持，需注意音频自动播放限制、文件系统访问差异。
- **macOS / Linux**：可选，但应保持跨平台兼容性。

## 开发工具建议

- **像素绘图**：Aseprite、Piskel 或 GraphicsGale。
- **音效制作**：BFXR、ChipTone 或 Audacity。
- **关卡设计**：直接在 Godot 编辑器中搭建场景，利用 TileMap 节点绘制地形。

## 代码规范要点

- **变量/函数命名**：`snake_case`
- **类/节点名**：`PascalCase`
- **常量**：`ALL_CAPS`
- **注释**：对复杂逻辑、信号连接、公共接口进行注释。
- **类型提示**：尽可能使用静态类型声明（如 `var speed: float = 100.0`）。

## 特效实现

- 使用 Godot 内置粒子系统（`CPUParticles2D` 或 `GPUParticles2D`）实现动态特效，如炮弹爆炸、坦克爆炸、道具拾取闪光等。
- 优先采用 `GPUParticles2D` 以获得更好性能，但注意兼容性。
- 特效材质可配合 `ShaderMaterial` 制作简单着色器效果。

## 物理设置

- 使用 Godot 2D 物理引擎，世界重力设为 `0`（俯视角游戏）。
- 坦克使用 `CharacterBody2D`，移动通过 `move_and_slide()` 实现。
- 地形元素使用 `StaticBody2D`（砖墙、钢墙）或 `Area2D`（草地、水域）。
- 炮弹使用 `Area2D` 或 `RigidBody2D` 进行碰撞检测。

## 性能注意事项

- 避免在 `_process()` 中频繁创建对象。
- 使用对象池（Object Pooling）管理炮弹和爆炸特效。
- 合理使用节点组和信号进行通信，减少全局查找。
- 关卡中 TileMap 应尽量合并碰撞形状，减少物理计算开销。
- 限制同屏炮弹和爆炸特效数量。

## 游戏特定技术要点

- **网格移动系统**：坦克移动应与网格对齐，确保流畅的移动体验。
- **炮弹碰撞**：炮弹应正确处理与不同地形类型的交互（砖墙可摧毁、钢墙反弹等）。
- **敌人AI**：实现基础的寻路和射击逻辑，可使用状态机管理敌人行为。
- **道具效果**：道具效果应有明确的时间限制或使用次数限制。
- **关卡数据**：关卡数据可存储为 JSON 或自定义资源格式，便于关卡编辑。