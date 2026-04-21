## 用户需求

完善敌人血量系统，让敌人能够真正被击杀。

## 核心功能

- EnemyTankBase 添加 max_hp 和 current_hp 血量属性
- take_damage() 实际扣减血量，血量归零时调用 die()
- 不同敌人类型可配置不同血量（基础敌人 max_hp = 1，一击必杀）

## 验收标准

- EnemyTankBase 有 `@export var max_hp: int = 1` 和 `var current_hp: int`
- _ready() 中 `current_hp = max_hp`
- take_damage() 实际扣减 current_hp，归零调用 die()
- BasicEnemyTank 默认 max_hp = 1

## 技术方案

### EnemyTankBase.gd 修改

1. 在属性区域添加血量属性：

- `@export var max_hp: int = 1` — 最大血量，子类可通过编辑器配置
- `var current_hp: int` — 当前血量

2. 在 `_ready()` 中初始化血量：

- `current_hp = max_hp`

3. 完善 `take_damage()` 方法：

- 记录 last_attacker（已有）
- 扣减血量：`current_hp -= damage`
- 打印血量变化日志
- 血量归零时调用 `die()`

### BasicEnemyTank.gd 修改

- 默认 max_hp = 1（继承自基类，无需额外设置）
- 可添加注释说明基础敌人一击必杀的设计意图

### 数据流

```
子弹击中敌人 → take_damage(damage, owner_tank)
    → last_attacker = owner_tank
    → current_hp -= damage
    → current_hp <= 0 ? → die()
        → EventBus.enemy_killed.emit(self, last_attacker)
        → WeaponManager.on_enemy_killed() → 充能掠夺
        → queue_free()
```

## 实现要点

- 使用 `@export` 让子类可在编辑器中配置不同血量
- 血量扣减应在记录 last_attacker 之后，确保击杀者信息正确传递
- 保持现有 die() 方法不变，它已正确处理击杀事件和节点销毁