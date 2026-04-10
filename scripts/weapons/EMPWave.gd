## EMP 冲击波效果
## 瘫痪范围内的敌人
class_name EMPWave
extends Node2D

## 影响半径
var radius: float = 200.0

## 瘫痪持续时间
var duration: float = 3.0

## EMP 颜色(占位用)
var stun_color: Color = Color.CYAN

## 动画持续时间
var animation_duration: float = 0.5

## 当前动画进度
var animation_progress: float = 0.0

## 是否已影响敌人
var has_affected_enemies: bool = false


func _ready() -> void:
	# 创建占位视觉效果(扩散圆圈)
	var circle := ColorRect.new()
	circle.size = Vector2(radius * 2, radius * 2)
	circle.color = Color(stun_color.r, stun_color.g, stun_color.b, 0.3)
	circle.position = Vector2(-radius, -radius)
	add_child(circle)

	# 开始时立即影响敌人
	_affect_enemies()


func _process(delta: float) -> void:
	# 动画进度
	animation_progress += delta / animation_duration

	# 动画完成后销毁
	if animation_progress >= 1.0:
		queue_free()
		return

	# 更新透明度(渐隐效果)
	for child in get_children():
		if child is ColorRect:
			var alpha := 0.3 * (1.0 - animation_progress)
			child.color.a = alpha


## 影响范围内的敌人
func _affect_enemies() -> void:
	if has_affected_enemies:
		return

	has_affected_enemies = true

	# 获取范围内的敌人
	var enemies := get_tree().get_nodes_in_group("enemy_tanks")
	for enemy in enemies:
		if enemy is Node2D:
			var distance := global_position.distance_to(enemy.global_position)
			if distance <= radius:
				# 瘫痪敌人
				_stun_enemy(enemy)


## 瘫痪敌人
## @param enemy 敌人节点
func _stun_enemy(enemy: Node) -> void:
	# 暂停敌人的移动和AI
	if enemy.has_method("set_stunned"):
		enemy.set_stunned(true, duration)

	# 简单实现: 禁用敌人
	if enemy.has_node("DirectionTimer"):
		var timer := enemy.get_node("DirectionTimer")
		timer.stop()
		# 在duration秒后恢复
		await get_tree().create_timer(duration).timeout
		if is_instance_valid(timer):
			timer.start()

	# 视觉效果: 改变颜色
	if enemy.has_node("TankBody"):
		var body := enemy.get_node("TankBody")
		if body is AnimatedSprite2D:
			body.modulate = stun_color
			# 在duration秒后恢复
			await get_tree().create_timer(duration).timeout
			if is_instance_valid(body):
				body.modulate = Color.WHITE
