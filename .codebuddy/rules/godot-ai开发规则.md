---
description: Godot AI 开发规则
alwaysApply: true
enabled: true
---

# AI 开发规则

## 项目文档结构

在 `docs/` 目录下有以下核心文档，AI 必须随时参考并按规定更新：

```
docs/
├── me2ai/          # 用户提供给 AI 的静态信息（只读参考）
│   ├── overview.md          # 项目概要（核心玩法、目标、风格等）
│   ├── TECH_STACK.md        # 技术栈文档，项目结构文档（用户维护）
│   └── ME2AI.md             # 用户对 AI 的原则和要求（用户维护）
├── shared/         # 双方共同维护的动态信息（用户和 AI 共同编辑）
│   └── CURRENT_TASKS.md     # 当前任务备忘录（任务状态、下一步计划）
└── ai2ai/          # AI 自行记录的工作日志（仅 AI 写，用户可读）
    └── AI2AI.md             # AI 工作记录（工作总结、重要信息、遗留问题）
```

## 详细需求（Spec）

功能细节由独立 spec 文档定义，AI 须严格按 spec 实现。如有疑问，与用户协商。

## 工作流程

1. **明确当前任务**：查看 `docs/shared/CURRENT_TASKS.md`。
2. **选择性查阅**：根据任务需要，阅读相关文档（`docs/me2ai/overview.md`、`docs/me2ai/TECH_STACK.md`、`docs/me2ai/ME2AI.md`、历史记录），无需全读。
3. **开发与测试**：在 Godot 4.3 中实现，遵循规范。
4. **记录工作**：更新 `docs/ai2ai/AI2AI.md`（内容、文件、决策、问题）。
5. **更新任务**：在 `docs/shared/CURRENT_TASKS.md` 标记完成，添加后续任务。
6. **同步用户**：重大变更及时沟通。

## 核心原则

- **只读参考**：`me2ai/` 文件由用户维护，AI 不修改。
- **面向对象与抽象**：重复元素抽象为基类/复用场景。
