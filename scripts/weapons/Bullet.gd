## 子弹基类
## 处理子弹的移动、碰撞检测
class_name Bullet
extends Area2D

## 子弹速度
var speed: float = 400.0

## 子弹伤害
var damage: int = 1

## 移动方向
var direction: Vector2 = Vector2.UP

## 是否可摧毁钢墙
var can_destroy_steel: bool = false

## 子弹所有者（发射该子弹的坦克），用于击杀者追踪和充能掠夺
var owner_tank: Tank = null

## 子弹颜色(占位用)
var bullet_color: Color = Color.YELLOW

## 碰撞层定义
const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")


func _ready() -> void:
	# 添加到子弹组
	add_to_group("bullets")

	# 设置碰撞层(根据发射者设置,这里默认为玩家子弹)
	collision_layer = CollisionLayersClass.LAYER_PLAYER_BULLET
	# 检测地形、敌人、边界
	collision_mask = CollisionLayersClass.LAYER_TERRAIN | \
					CollisionLayersClass.LAYER_ENEMY | \
					CollisionLayersClass.LAYER_BOUNDARY

	# 更新占位颜色
	_update_bullet_color()

	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	# 移动子弹
	position += direction * speed * delta

	# 超出屏幕范围则销毁
	var viewport_rect := get_viewport_rect()
	if not viewport_rect.has_point(position):
		queue_free()


## 更新子弹颜色(占位实现)
func _update_bullet_color() -> void:
	# 查找 ColorRect 子节点并更新颜色
	for child in get_children():
		if child is ColorRect:
			child.color = bullet_color
			break


## 碰撞体进入检测
func _on_body_entered(body: Node2D) -> void:
	# 碰到地形或边界
	if body.is_in_group("terrain") or body.is_in_group("boundary"):
		# 如果是砖墙,销毁砖墙
		if body.is_in_group("brick_wall"):
			body.destroy()
			queue_free()
		# 如果是钢墙
		elif body.is_in_group("steel_wall"):
			if can_destroy_steel:
				body.destroy()
			queue_free()
		else:
			queue_free()


## 区域进入检测（检测敌人坦克的 HurtArea）
func _on_area_entered(area: Area2D) -> void:
	# 碰到敌人坦克的 HurtArea
	if area.is_in_group("enemy_tanks") or area.get_parent().is_in_group("enemy_tanks"):
		# 造成伤害
		var enemy_tank = area.get_parent()
		if enemy_tank.has_method("take_damage"):
			enemy_tank.take_damage(damage, owner_tank)
		queue_free()
	# 碰到其他子弹（避免误伤）
	elif area.is_in_group("bullets"):
		queue_free()
