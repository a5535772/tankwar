# 贡献指南

感谢您对坦克大战项目的关注！本文档将帮助您了解如何参与项目开发。

## 开发环境设置

### 前置要求

- **Godot 引擎**：4.3 稳定版或更高版本
  - 下载地址：https://godotengine.org/download
  - 推荐使用标准版（非 .NET 版本）
- **Git**：用于版本控制
- **代码编辑器**（可选）：
  - Godot 内置编辑器
  - VSCode + GDScript 插件
  - 其他支持 GDScript 的编辑器

### 安装步骤

1. **克隆仓库**
   ```bash
   git clone <repository-url>
   cd tankwar
   ```

2. **打开项目**
   ```bash
   godot4 project.godot
   ```
   或在 Godot 编辑器中：项目 → 导入 → 选择 `project.godot`

3. **运行测试场景**
   - 按 F5 运行主场景（TankTest.tscn）
   - 确认两个玩家坦克和敌人坦克正常显示

## 项目结构

```
tankwar/
├── assets/           # 游戏资源（图片、音频、字体）
│   ├── images/       # 图片资源
│   ├── audio/        # 音频文件
│   ├── fonts/        # 字体文件
│   └── tilesets/     # TileSet 资源
├── docs/             # 项目文档
│   ├── me2ai/        # 用户提供的静态信息（只读）
│   ├── shared/       # 共享文档（任务、计划）
│   ├── ai2ai/        # AI 工作记录
│   └── game/         # 游戏设计文档
├── scenes/           # 场景文件
│   ├── entities/     # 实体场景（坦克、子弹）
│   ├── levels/       # 关卡场景
│   └── ui/           # UI 场景
├── scripts/          # GDScript 脚本
│   ├── systems/      # 全局单例系统（EventBus, CollisionLayers）
│   ├── entities/     # 实体脚本（坦克、敌人）
│   ├── weapons/      # 武器系统（主武器、副武器、子弹）
│   ├── powerups/     # 道具系统
│   └── ui/           # UI 脚本
├── scenes/           # 场景文件
│   ├── entities/     # 实体场景（坦克、子弹）
│   ├── bullets/      # 子弹场景
│   ├── powerups/     # 道具场景
│   ├── levels/       # 关卡场景
│   └── ui/           # UI 场景
├── resources/        # 资源文件
│   └── weapons/      # 武器配置资源
└── project.godot     # 项目配置
```

## 代码风格规范

### GDScript 风格指南

遵循 [Godot 官方 GDScript 风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)

#### 命名约定

- **变量和函数**：`snake_case`
  ```gdscript
  var move_speed = 100.0
  func get_input_direction():
  ```

- **类和节点名**：`PascalCase`
  ```gdscript
  class_name PlayerTank
  ```

- **常量**：`ALL_CAPS`
  ```gdscript
  const GRID_SIZE = 32
  ```

- **枚举**：`PascalCase` 名称，`ALL_CAPS` 值
  ```gdscript
  enum MoveDirection { UP, DOWN, LEFT, RIGHT }
  ```

#### 类型提示

始终使用静态类型提示：

```gdscript
# 好
var speed: float = 100.0
var direction: Vector2 = Vector2.DOWN
func move_tank(input_dir: Vector2) -> void:

# 避免
var speed = 100.0
var direction = Vector2.DOWN
func move_tank(input_dir):
```

#### 注释规范

- 使用 `##` 编写文档注释
- 对复杂逻辑、公共接口、信号连接添加注释

```gdscript
## 坦克基类
## 提供通用的移动、旋转逻辑
class_name Tank
extends CharacterBody2D

## 移动速度（像素/秒）
@export var speed: float = 100.0

## 移动坦克（由子类调用）
## @param input_dir 输入方向（归一化后的向量）
func move_tank(input_dir: Vector2) -> void:
    # 实现移动逻辑
    pass
```

#### 缩进和空格

- 使用 **Tab** 缩进（Godot 默认）
- 函数之间空一行
- 逻辑块之间空一行

### 场景文件规范

- 场景文件使用 `.tscn` 格式（文本格式，便于版本控制）
- 节点命名清晰有意义
- 正确配置碰撞层和遮罩

## 开发工作流

### 创建新功能

1. **查看任务列表**
   - 查看 `docs/shared/CURRENT_TASKS.md` 了解当前任务

2. **阅读相关文档**
   - `docs/me2ai/OVERVIEW.md` - 项目概要
   - `docs/me2ai/TECH_STACK.md` - 技术栈
   - `docs/game/architecture/project_structure.md` - 架构设计

3. **实现功能**
   - 遵循现有代码结构
   - 使用面向对象和抽象原则
   - 添加必要的注释

4. **测试功能**
   - 在 Godot 编辑器中运行测试
   - 确保功能正常工作

5. **更新文档**
   - 更新 `docs/ai2ai/AI2AI.md` 记录工作
   - 更新 `docs/shared/CURRENT_TASKS.md` 标记完成

### 提交代码

#### 提交信息规范

使用清晰、描述性的提交信息：

```
<type>: <subject>

<body>
```

**类型**：
- `feat`: 新功能
- `fix`: Bug 修复
- `refactor`: 代码重构
- `docs`: 文档更新
- `style`: 代码格式调整
- `test`: 测试相关
- `chore`: 构建/工具链相关

**示例**：
```
feat: 添加敌人坦克基类

- 创建 EnemyTankBase 作为敌人坦克基类
- 创建 BasicEnemyTank 作为具体实现
- 预留 AI 接口（追踪、视线检测、射击）
```

#### 提交前检查清单

- [ ] 代码遵循 GDScript 风格指南
- [ ] 添加了必要的注释
- [ ] 在编辑器中测试过功能
- [ ] 更新了相关文档
- [ ] 没有遗留调试代码

## 核心原则

### 面向对象设计

- **继承**：合理使用继承建立类层次
  - `Tank` → `PlayerTank` / `EnemyTankBase`
  - `EnemyTankBase` → `BasicEnemyTank` / 未来敌人类型

- **抽象**：将重复元素抽象为基类
  - 坦克移动逻辑在 `Tank` 基类
  - AI 决策框架在 `EnemyTankBase` 基类

- **封装**：功能封装在独立脚本/场景中

### 模块化

- 功能独立，减少耦合
- 使用信号（Signal）进行通信
- 使用节点组（Group）管理同类实体

### 性能优化

- 避免在 `_process()` 中频繁创建对象
- 使用对象池管理频繁创建/销毁的对象（子弹、特效）
- 合理使用信号和组，减少全局查找

## 常见任务

### 添加新的敌人类型

参考 `scripts/entities/tanks/BasicEnemyTank.gd` 和 `docs/ai2ai/AI2AI.md` 中的扩展示例。

### 添加新的道具

1. 创建道具脚本继承 `PowerUp` 基类（待实现）
2. 创建道具场景
3. 配置道具效果和持续时间
4. 在关卡中添加道具实例

### 创建新关卡

1. 创建新场景继承关卡结构
2. 使用 TileMap 绘制地形
3. 放置玩家出生点、敌人出生点、基地
4. 配置关卡参数（敌人数量、波次等）

## 获取帮助

- 查看 `docs/` 目录下的文档
- 查看 `docs/ai2ai/AI2AI.md` 了解开发历史和决策
- 参考 Godot 官方文档：https://docs.godotengine.org

## 许可证

[待添加许可证信息]
