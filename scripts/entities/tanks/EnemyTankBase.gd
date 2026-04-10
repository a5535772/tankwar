## 敌人坦克基类
## 提供敌人坦克的通用功能，子类实现具体的 AI 行为
class_name EnemyTankBase
extends "res://scripts/entities/tanks/Tank.gd"


## 移动方向枚举
enum MoveDirection { UP, DOWN, LEFT, RIGHT }

## 当前移动方向
var current_move_direction: MoveDirection = MoveDirection.DOWN

## 方向改变计时器
@onready var direction_timer: Timer = $DirectionTimer


# === AI 行为属性（子类可重写）===

## AI 决策频率（秒）
@export var decision_interval: float = 2.0

## 是否启用自主移动（子类可控制）
@export var enable_autonomous_movement: bool = true


# === 武器系统相关属性 ===

## 敌人携带的充能点数（被击败后掠夺）
@export var charge_value: int = 10

## 能量核心掉落概率
@export var energy_core_drop_chance: float = 0.05

## 最后攻击者（用于充能掠夺）
var last_attacker: Tank = null


# === TODO: 后续实现 ===
# TODO: 玩家追踪
# var target_player: Tank = null
# var chase_range: float = 300.0

# TODO: 视线检测
# @onready var line_of_sight: RayCast2D = $LineOfSight

# TODO: 射击功能
# var fire_cooldown: float = 1.0
# var can_fire: bool = true
# @onready var bullet_spawner: BulletSpawner = $BulletSpawner


func _ready() -> void:
	# 配置敌人碰撞层
	collision_layer_type = CollisionLayersClass.LAYER_ENEMY
	# 检测地形、边界、敌人（友军）、玩家
	collision_mask_types = CollisionLayersClass.LAYER_TERRAIN | \
							CollisionLayersClass.LAYER_BOUNDARY | \
							CollisionLayersClass.LAYER_ENEMY | \
							CollisionLayersClass.LAYER_PLAYER

	# 调用父类的 _ready 设置碰撞层
	super._ready()

	# 配置方向计时器
	if direction_timer:
		direction_timer.wait_time = decision_interval
		direction_timer.timeout.connect(_on_direction_timer_timeout)
		direction_timer.start()


func _physics_process(delta: float) -> void:
	# 执行移动逻辑（由子类控制）
	_update_movement()

	# 调用父类的物理处理
	super._physics_process(delta)


## 更新移动逻辑（子类可重写）
func _update_movement() -> void:
	if not enable_autonomous_movement:
		return

	var move_vector := _get_move_direction_vector()
	move_tank(move_vector)


## 获取当前移动方向向量
func _get_move_direction_vector() -> Vector2:
	match current_move_direction:
		MoveDirection.UP: return Vector2.UP
		MoveDirection.DOWN: return Vector2.DOWN
		MoveDirection.LEFT: return Vector2.LEFT
		MoveDirection.RIGHT: return Vector2.RIGHT
	return Vector2.ZERO


## 方向计时器回调
func _on_direction_timer_timeout() -> void:
	_on_decision_tick()


## AI 决策回调（子类重写实现具体行为）
func _on_decision_tick() -> void:
	# 默认行为：随机改变方向
	if enable_autonomous_movement:
		_change_direction_randomly()


## 随机改变方向
func _change_direction_randomly() -> void:
	var directions: Array[MoveDirection] = [
		MoveDirection.UP,
		MoveDirection.DOWN,
		MoveDirection.LEFT,
		MoveDirection.RIGHT
	]
	current_move_direction = directions[randi() % directions.size()]


## 获取充能值
## @return 敌人携带的充能点数
func get_charge_value() -> int:
	return charge_value


## 受伤处理
## @param damage 伤害值
## @param attacker 攻击者
func take_damage(damage: int, attacker: Tank) -> void:
	# 记录最后攻击者
	last_attacker = attacker
	# 输出受伤日志
	print("[EnemyTank] %s 受到 %d 点伤害，攻击者: %s" % [name, damage, attacker.name if attacker else "未知"])
	# TODO: 实现血量扣减和死亡逻辑


## 死亡处理
func die() -> void:
	# 发送击杀事件
	EventBus.enemy_killed.emit(self, last_attacker)
	
	# TODO: 掉落能量核心
	# if randf() < energy_core_drop_chance:
	#     _spawn_energy_core()
	
	# 销毁节点
	queue_free()


# === TODO: 后续实现的功能 ===

# TODO: 查找最近的玩家
# func _find_nearest_player() -> Tank:
#     var players := get_tree().get_nodes_in_group("player_tanks")
#     if players.is_empty():
#         return null
#
#     var nearest_player: Tank = null
#     var nearest_distance: float = INF
#
#     for player in players:
#         var distance := global_position.distance_to(player.global_position)
#         if distance < nearest_distance:
#             nearest_distance = distance
#             nearest_player = player
#
#     return nearest_player

# TODO: 视线检测
# func _has_line_of_sight(target: Vector2) -> bool:
#     if not line_of_sight:
#         return true
#
#     line_of_sight.target_position = target - global_position
#     line_of_sight.force_raycast_update()
#
#     # 如果碰撞了，说明视线被遮挡
#     return not line_of_sight.is_colliding()

# TODO: 射击
# func fire() -> void:
#     if not can_fire:
#         return
#
#     can_fire = false
#     # 发射子弹
#     if bullet_spawner:
#         bullet_spawner.spawn_bullet(global_position, direction)
#
#     # 冷却计时器
#     await get_tree().create_timer(fire_cooldown).timeout
#     can_fire = true
