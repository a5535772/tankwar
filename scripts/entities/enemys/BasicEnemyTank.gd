## 基础敌人坦克
## 实现简单的随机巡逻行为
class_name BasicEnemyTank
extends "res://scripts/entities/enemys/EnemyTankBase.gd"


## 基础敌人坦克使用默认的随机巡逻行为
## 如需自定义行为，可以重写 _on_decision_tick() 方法

## 血量配置：基础敌人一击必杀（max_hp = 1，继承自基类）
## 如需增加血量，可在编辑器中修改 max_hp 属性


func _ready() -> void:
	# 添加到敌人坦克组
	add_to_group("enemy_tanks")

	# 可以自定义基础属性
	# decision_interval = 2.0  # 决策间隔
	# enable_autonomous_movement = true  # 启用自主移动
	super._ready()


## 示例：可以重写决策逻辑
# func _on_decision_tick() -> void:
#     # 自定义 AI 行为
#     super._on_decision_tick()  # 调用基类的默认行为
