# 游戏技术文档索引

> 本文档为 `docs/project/game/` 下所有技术文档的导航索引，供 AI 快速定位所需文档。

---

## 总览

| 文档 | 说明 | 关键词 |
|------|------|--------|
| [game_overview.md](game_overview.md) | 游戏设计总纲：设计理念、核心循环、全系统机制清单、美术音频风格、技术架构概览 | 设计支柱、玩法循环、系统清单、实现状态 |
| [evolution_roadmap.md](evolution_roadmap.md) | 5 个 Sprint 的开发路线图：优先级、交付物、验收标准、里程碑依赖与风险 | Sprint 计划、功能优先级、交付标准 |

---

## 架构决策

| 文档 | 说明 | 关键词 |
|------|------|--------|
| [architecture/adr_001_tileset_configuration.md](architecture/adr_001_tileset_configuration.md) | TileSet 配置决策：Custom Data Layer `tile_type`、Physics Layer 分配、水面碰撞方案、子弹与 TileMap 交互流程 | ADR、TileSet、碰撞层、水面、子弹交互 |

---

## 玩家系统

| 文档 | 说明 | 关键词 |
|------|------|--------|
| [player/player_tank_prd.md](player/player_tank_prd.md) | 玩家坦克完整需求：移动系统、操控方案、主武器三级升级、副武器充能机制、双人模式、HUD、拾取机制 | 移动、操控、主武器、副武器、双人、HUD |
| [player/weapons_prd.md](player/weapons_prd.md) | 双武器架构需求：主武器（3 级升级）、副武器（6 种类型 + 充能系统 + 操控方案）、占位资源约定 | 武器升级、充能、导弹/EMP/黑客/护盾/时停/终极 |

---

## 敌人系统

| 文档 | 说明 | 关键词 |
|------|------|--------|
| [enemies/enemy_tank_design.md](enemies/enemy_tank_design.md) | 敌方坦克架构设计：Tank → EnemyTankBase → 具体 Enemy 的继承体系、AI 决策框架（Timer 驱动）、各类敌人实现细节与配置指南 | 继承体系、AI 决策、追击/巡逻、碰撞配置 |
| [enemies/enemy_tank_prd.md](enemies/enemy_tank_prd.md) | 敌人坦克需求文档：3 种敌人类型定义（Basic/Chase/Patrol）、基类功能需求、预留接口（追踪/视线/射击）、实现优先级 | 敌人类型、PRD、追踪、视线检测、射击 |

---

## 地形系统

| 文档 | 说明 | 关键词 |
|------|------|--------|
| [terrain/terrain_system_design.md](terrain/terrain_system_design.md) | 地形系统完整设计（v2.0）：6 种地形定义与碰撞配置、碰撞层常量、碰撞关系矩阵、TileMap 层级结构、标准战场尺寸、边界布局 | 砖墙/钢墙/水面/草地/冰面、碰撞矩阵、TileMap、战场尺寸 |
| [terrain/terrain_system_prd.md](terrain/terrain_system_prd.md) | 地形系统 PRD：整合 Sprint1 需求与设计文档，地形功能需求与验收标准 | 地形 PRD、验收标准、Sprint1 |

---

## 关卡系统

| 目录 | 说明 |
|------|------|
| `levels/` | 暂无文档，待补充 |

---

## 按主题速查

- **碰撞/物理** → `architecture/adr_001_tileset_configuration.md`、`terrain/terrain_system_design.md`、`terrain/terrain_system_prd.md`
- **武器/战斗** → `player/weapons_prd.md`、`player/player_tank_prd.md`
- **AI/敌人** → `enemies/enemy_tank_design.md`、`enemies/enemy_tank_prd.md`
- **地图/地形** → `terrain/terrain_system_design.md`、`terrain/terrain_system_prd.md`
- **整体规划** → `game_overview.md`、`evolution_roadmap.md`
- **测试清单** → `terrain/terrain_system_design.md`（测试清单部分）
