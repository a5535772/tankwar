# 边界系统修复需求文档

## 1. 需求概述

### 1.1 背景

当前坦克大战游戏中存在边界问题，导致坦克可以移动出战场范围，子弹边界检测不准确。需要修复边界系统，确保游戏玩法正常。

### 1.2 目标

- 阻止坦克移出战场边界
- 修复子弹边界检测逻辑
- 提供可视化编辑支持（TileMap拖拽）

### 1.3 范围

- 边界墙脚本创建
- TileSet资源配置
- 测试场景边界绘制
- 子弹边界检测修复

---

## 2. 功能需求

### 2.1 边界墙脚本 (BoundaryWall.gd)

#### 2.1.1 功能描述

创建边界墙实体类，用于限制坦克和子弹的活动范围。

#### 2.1.2 技术要求

- 继承自 `StaticBody2D`
- 碰撞层配置为 `LAYER_BOUNDARY` (值: 32)
- 碰撞遮罩设置为 0
- 添加到 "boundary" 组

#### 2.1.3 代码实现

```gdscript
class_name BoundaryWall
extends StaticBody2D

const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")

func _ready() -> void:
    # 配置碰撞层
    collision_layer = CollisionLayersClass.LAYER_BOUNDARY
    collision_mask = 0

    # 添加到组
    add_to_group("boundary")
```

#### 2.1.4 文件路径

`scripts/terrain/BoundaryWall.gd`

---

### 2.2 边界 TileSet 资源 (BoundaryTileset.tres)

#### 2.2.1 功能描述

创建边界墙专用的 TileSet 资源，支持在 TileMap 中可视化编辑边界。

#### 2.2.2 技术要求

- Physics Layer 0 配置: collision_layer = 32 (LAYER_BOUNDARY)
- 瓦片尺寸: 32x32 像素
- 碰撞形状: RectangleShape2D (覆盖整个瓦片)
- 添加瓦片组标签: "boundary"

#### 2.2.3 配置步骤

1. 创建新 TileSet 资源文件
2. 添加 Physics Layer 0，设置 collision_layer = 32
3. 创建边界墙瓦片（32x32 像素）
4. 为瓦片配置 RectangleShape2D 碰撞形状
5. 添加瓦片元数据：Group = "boundary"

#### 2.2.4 文件路径

`assets/tilesets/BoundaryTileset.tres`

---

### 2.3 测试场景边界绘制

#### 2.3.1 功能描述

在测试场景的 BoundaryLayer 上绘制边界墙，限制坦克活动范围。

#### 2.3.2 战场范围定义

```
网格大小: 32x32 像素
战场范围: 416x416 像素 (13x13 网格)
实际可活动区域: 11x11 网格 (352x352 像素)
```

#### 2.3.3 边界墙位置

```
上边界: 网格坐标 (0,0) 到 (12,0)   [13个瓦片]
下边界: 网格坐标 (0,12) 到 (12,12) [13个瓦片]
左边界: 网格坐标 (0,1) 到 (0,11)   [11个瓦片]
右边界: 网格坐标 (12,1) 到 (12,11) [11个瓦片]

总计: 48个边界墙瓦片
```

#### 2.3.4 边界布局示意

```
战场网格布局 (13x13):
┌─────────────────┐
│ B B B B B B B B B B B B B │  第0行: 边界墙
│ B . . . . . . . . . . . B │  第1-11行: 活动区域
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B . . . . . . . . . . . B │
│ B B B B B B B B B B B B B │  第12行: 边界墙
└─────────────────┘

B = 边界墙 (Boundary)
. = 活动区域
```

#### 2.3.5 文件路径

`scenes/levels/TankTest.tscn` 的 `BoundaryLayer` 节点

---

### 2.4 子弹边界检测修复

#### 2.4.1 功能描述

修复子弹边界检测逻辑，移除不准确的视口检测，完全依赖碰撞系统。

#### 2.4.2 当前问题代码

```gdscript
# scripts/weapons/Bullet.gd:44-51
func _process(delta: float) -> void:
    position += direction * speed * delta

    # 超出屏幕范围则销毁
    var viewport_rect := get_viewport_rect()
    if not viewport_rect.has_point(position):
        queue_free()
```

**问题**:
- 使用 `get_viewport_rect()` 获取视口矩形
- 视口可能包含 UI 区域，与战场范围不一致
- 边界检测不准确

#### 2.4.3 修复方案

**方案: 完全依赖碰撞检测**

```gdscript
func _process(delta: float) -> void:
    # 移动子弹
    position += direction * speed * delta
    # 移除 viewport 检测，完全依赖与 BoundaryLayer 的碰撞
    # 碰撞逻辑在 _on_body_entered 中处理
```

#### 2.4.4 依赖验证

确认子弹的碰撞遮罩配置:

```gdscript
# scripts/weapons/Bullet.gd:32-34
collision_mask = CollisionLayersClass.LAYER_TERRAIN | \
                CollisionLayersClass.LAYER_ENEMY | \
                CollisionLayersClass.LAYER_BOUNDARY  # ✅ 已包含
```

#### 2.4.5 碰撞处理逻辑

```gdscript
# scripts/weapons/Bullet.gd:64-77
func _on_body_entered(body: Node2D) -> void:
    # 碰到边界墙
    if body.is_in_group("boundary"):  # ✅ 已有此逻辑
        queue_free()
        return

    # 碰到地形或边界
    if body.is_in_group("terrain") or body.is_in_group("boundary"):
        # ... 其他逻辑
```

#### 2.4.6 文件路径

`scripts/weapons/Bullet.gd`

---

## 3. 非功能需求

### 3.1 性能要求

- 边界墙碰撞检测不影响帧率
- TileMap 渲染效率正常
- 子弹边界碰撞响应及时

### 3.2 可维护性要求

- 代码遵循项目编码规范
- 文件结构符合项目架构文档
- 支持可视化编辑（TileMap拖拽）

### 3.3 兼容性要求

- 兼容现有碰撞系统
- 不影响现有坦克和子弹逻辑
- 符合 Godot 4.3 开发规范

---

## 4. 实施计划

### 4.1 Phase 1: 创建边界墙脚本

**任务**:
- [ ] 创建 `scripts/terrain/` 目录（如不存在）
- [ ] 创建 `BoundaryWall.gd` 脚本
- [ ] 配置碰撞层和组

**预计时间**: 10分钟

---

### 4.2 Phase 2: 创建边界 TileSet 资源

**任务**:
- [ ] 在 Godot 编辑器中创建 `BoundaryTileset.tres`
- [ ] 添加 Physics Layer 0 (collision_layer = 32)
- [ ] 创建边界墙瓦片
- [ ] 配置碰撞形状 (RectangleShape2D)
- [ ] 添加瓦片元数据

**预计时间**: 15分钟

---

### 4.3 Phase 3: 在测试场景绘制边界墙

**任务**:
- [ ] 打开 `TankTest.tscn`
- [ ] 为 `BoundaryLayer` 节点分配 `BoundaryTileset`
- [ ] 绘制上边界: (0,0) 到 (12,0)
- [ ] 绘制下边界: (0,12) 到 (12,12)
- [ ] 绘制左边界: (0,1) 到 (0,11)
- [ ] 绘制右边界: (12,1) 到 (12,11)

**预计时间**: 10分钟

---

### 4.4 Phase 4: 修复子弹边界检测

**任务**:
- [ ] 修改 `Bullet.gd` 的 `_process()` 方法
- [ ] 移除 `get_viewport_rect()` 检测
- [ ] 验证碰撞遮罩配置正确
- [ ] 验证 `_on_body_entered()` 处理边界碰撞

**预计时间**: 5分钟

---

### 4.5 Phase 5: 测试验证

**任务**:
- [ ] 启动游戏，控制玩家坦克尝试移出边界
- [ ] 控制敌人坦克观察是否被边界阻挡
- [ ] 发射子弹，观察是否在边界处销毁
- [ ] 检查子弹是否卡在边界外

**预计时间**: 10分钟

---

## 5. 测试验收标准

### 5.1 功能测试

- [ ] **TC1**: 玩家坦克无法移出战场边界
  - 操作: 控制玩家1和玩家2坦克向四个方向移动
  - 预期: 坦克被边界墙阻挡，无法移出

- [ ] **TC2**: 敌人坦克无法移出战场边界
  - 操作: 观察敌人坦克随机移动行为
  - 预期: 敌人坦克被边界墙阻挡

- [ ] **TC3**: 玩家子弹在边界处销毁
  - 操作: 玩家向四个方向发射子弹
  - 预期: 子弹触碰边界墙后销毁

- [ ] **TC4**: 敌人子弹在边界处销毁
  - 操作: 敌人发射子弹
  - 预期: 子弹触碰边界墙后销毁

- [ ] **TC5**: 子弹不会卡在边界外
  - 操作: 在边界附近发射子弹
  - 预期: 子弹正常销毁，无残留

### 5.2 性能测试

- [ ] 帧率稳定，无明显卡顿
- [ ] 边界碰撞响应及时
- [ ] 多个子弹同时碰撞边界无性能问题

### 5.3 视觉测试

- [ ] 边界墙位置与 `BoundaryIndicator` (Line2D) 一致
- [ ] 边界墙瓦片渲染正常
- [ ] 边界墙与地形元素视觉协调

---

## 6. 依赖关系

### 6.1 前置依赖

- ✅ `scripts/systems/CollisionLayers.gd` 已存在
- ✅ `scripts/entities/tanks/Tank.gd` 已配置碰撞遮罩
- ✅ `scripts/weapons/Bullet.gd` 已配置碰撞遮罩
- ✅ `scenes/levels/TankTest.tscn` 已创建

### 6.2 后续扩展

- 地形系统实现 (砖墙、钢墙、水域等)
- 关卡系统实现
- 地形编辑器支持

---

## 7. 风险与缓解

### 7.1 TileSet 配置错误

**风险**: Physics Layer 配置不正确，导致碰撞失效

**缓解措施**:
- 参考 Godot 官方文档
- 使用 CollisionLayers.gd 中的常量
- Phase 5 进行完整测试验证

### 7.2 边界墙位置计算错误

**风险**: 网格坐标计算错误，边界位置不正确

**缓解措施**:
- 使用战场范围定义 (416x416 像素)
- 绘制时参考 `BoundaryIndicator` 位置
- 视觉验证边界墙与 Line2D 对齐

### 7.3 子弹修改后边界检测失效

**风险**: 移除 viewport 检测后，子弹可能飞出边界外

**缓解措施**:
- 确认碰撞遮罩包含 `LAYER_BOUNDARY`
- Phase 5 测试验证所有边界方向
- 测试快速连续射击场景

---

## 8. 参考文档

- [地形与边界系统设计文档](../architecture/terrain_boundary_design.md)
- [碰撞系统设计文档](../architecture/collision_system_design.md)
- [项目架构文档](../architecture/project_structure.md)
- [当前任务备忘录](../../shared/CURRENT_TASKS.md)

---

## 9. 附录

### 9.1 网格坐标系统说明

```
网格原点: (0, 0) - 左上角
X轴: 向右递增
Y轴: 向下递增
每个网格: 32x32 像素

示例:
(0, 0) → 像素坐标 (0, 0)
(12, 12) → 像素坐标 (384, 384)
```

### 9.2 碰撞层定义参考

```gdscript
# scripts/systems/CollisionLayers.gd
const LAYER_BOUNDARY: int = 1 << 5  # 值: 32 (二进制: 100000)
```

### 9.3 边界墙特性

- ✅ 不可摧毁
- ✅ 阻止坦克通过
- ✅ 销毁子弹
- ✅ 视觉上标识战场范围

---

**文档版本**: 1.0
**创建日期**: 2026-04-10
**维护者**: AI Assistant
**最后更新**: 2026-04-10
