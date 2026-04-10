## 导弹类
## 追踪最近的敌人
class_name Missile
extends Area2D

## 导弹速度
var speed: float = 300.0

## 伤害
var damage: int = 2

## 移动方向
var direction: Vector2 = Vector2.UP

## 导弹颜色(占位用)
var missile_color: Color = Color.BLUE

## 导弹所有者
var owner_tank: Tank = null

## 追踪目标
var target: Node2D = null

## 追踪强度
var tracking_strength: float = 5.0

## 生命周期
var lifetime: float = 5.0

## 碰撞层定义
const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")


func _ready() -> void:
	# 设置碰撞层
	collision_layer = CollisionLayersClass.LAYER_PLAYER_BULLET
	collision_mask = CollisionLayersClass.LAYER_ENEMY | CollisionLayersClass.LAYER_TERRAIN

	# 创建碰撞形状
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	collision.shape = shape
	add_child(collision)

	# 创建占位色块
	var color_rect := ColorRect.new()
	color_rect.size = Vector2(6, 10)
	color_rect.color = missile_color
	color_rect.position = Vector2(-3, -5)  # 居中
	add_child(color_rect)

	# 连接碰撞信号
	body_entered.connect(_on_body_entered)

	# 查找最近的敌人
	_find_nearest_enemy()


func _process(delta: float) -> void:
	# 生命周期倒计时
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return

	# 追踪目标
	if target and is_instance_valid(target):
		var to_target := (target.global_position - global_position).normalized()
		direction = direction.lerp(to_target, tracking_strength * delta).normalized()

	# 移动导弹
	position += direction * speed * delta

	# 更新旋转角度
	rotation = direction.angle()

	# 超出屏幕范围则销毁
	var viewport_rect := get_viewport_rect()
	if not viewport_rect.has_point(position):
		queue_free()


## 查找最近的敌人
func _find_nearest_enemy() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy_tanks")
	if enemies.is_empty():
		return

	var nearest_distance := INF
	for enemy in enemies:
		if enemy is Node2D:
			var distance := global_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				target = enemy


## 碰撞体进入检测
func _on_body_entered(body: Node2D) -> void:
	# 碰到敌人
	if body.is_in_group("enemy_tanks"):
		# 造成伤害
		if body.has_method("take_damage"):
			body.take_damage(damage, owner_tank)
		# 销毁导弹
		queue_free()
	# 碰到地形
	elif body.is_in_group("terrain"):
		queue_free()
