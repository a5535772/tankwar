# 边界系统修复需求

> **文档版本**: 2.0
> **最后更新**: 2026-04-21
> **精简自**: boundary_system_fix_requirements.md

**相关文档**:
- [地形系统设计](./terrain_system_design.md)
- [ADR-001: TileSet 配置](../architecture/adr_001_tileset_configuration.md)

---

## 1. 问题描述

### 问题1: 坦克可移出边界

- **现象**: 玩家坦克可以跑出 `BoundaryIndicator` (Line2D) 标识的战场范围
- **原因**: `Tank.gd` 的 `collision_mask` 包含 `LAYER_BOUNDARY`，但 `TankTest.tscn` 的 `BoundaryLayer` 没有配置碰撞形状

### 问题2: 子弹边界检测不准确

- **现象**: 玩家子弹在左侧边界外被阻挡
- **原因**: 使用 `get_viewport_rect()` 检测边界，视口矩形与战场实际范围 416×416 不一致

---

## 2. 修复需求

### 2.1 创建边界墙 TileSet

- 创建 `BoundaryTileset.tres`，Physics Layer 配置 collision_layer = 16 (LAYER_TERRAIN)
- 瓦片尺寸: 32×32 像素，碰撞形状: RectangleShape2D
- 详见 [ADR-001](../architecture/adr_001_tileset_configuration.md)

### 2.2 绘制战场边界

在 `TankTest.tscn` 的 `BoundaryLayer` 绘制 48 个边界瓦片：
- 上边界: (0,0) 到 (12,0) — 13 瓦片
- 下边界: (0,12) 到 (12,12) — 13 瓦片
- 左边界: (0,1) 到 (0,11) — 11 瓦片
- 右边界: (12,1) 到 (12,11) — 11 瓦片

> 边界布局图见 [地形系统设计 §4.2](./terrain_system_design.md)

### 2.3 修复子弹边界检测

- 移除 `Bullet.gd` 中 `get_viewport_rect()` 检测
- 完全依赖碰撞系统（子弹 mask 含 LAYER_TERRAIN，边界瓦片在 LAYER_TERRAIN 层）
- 碰撞处理通过 Custom Data `tile_type="boundary"` 识别

---

## 3. 验收标准

### 3.1 功能测试

| ID | 测试项 | 预期结果 |
|----|-------|---------|
| TC1 | 玩家坦克向四方向移动 | 被边界墙阻挡，无法移出 |
| TC2 | 敌人坦克随机移动 | 被边界墙阻挡 |
| TC3 | 玩家向四方向发射子弹 | 子弹触碰边界墙后销毁 |
| TC4 | 敌人发射子弹 | 子弹触碰边界墙后销毁 |
| TC5 | 边界附近发射子弹 | 子弹正常销毁，无残留 |

### 3.2 性能要求

- 边界碰撞检测不影响帧率
- 多子弹同时碰撞边界无性能问题

### 3.3 视觉要求

- 边界墙位置与 `BoundaryIndicator` (Line2D) 一致
- 边界墙瓦片渲染正常
