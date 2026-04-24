## 子弹基类
## 使用 CharacterBody2D + move_and_collide() 实现可靠碰撞检测
class_name Bullet
extends CharacterBody2D

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

## 战场边界（960×544 像素）
const BATTLEFIELD_SIZE: Vector2 = Vector2(960, 544)

## 碰撞层定义
const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")

## 子弹是否已命中（防止 queue_free 延迟期间重复处理）
var _hit: bool = false


func _ready() -> void:
	add_to_group("bullets")
	collision_layer = CollisionLayersClass.LAYER_PLAYER_BULLET
	collision_mask = CollisionLayersClass.LAYER_TERRAIN | CollisionLayersClass.LAYER_ENEMY
	_update_bullet_color()


func _physics_process(delta: float) -> void:
	if _hit:
		return

	velocity = direction.normalized() * speed
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)

	if collision:
		_handle_collision(collision)

	if not _hit and _is_out_of_bounds():
		queue_free()


## 处理碰撞结果
func _handle_collision(collision: KinematicCollision2D) -> void:
	if _hit:
		return
	_hit = true

	var collider: Node = collision.get_collider()
	#print("[Bullet] 碰撞检测: collider=%s type=%s pos=%s" % [collider.name if collider else "null", collider.get_class() if collider else "null", collision.get_position()])

	# TileMapLayer 碰撞（地形瓦片）
	if collider is TileMapLayer:
		var collision_point: Vector2 = collision.get_position()
		var collision_normal: Vector2 = collision.get_normal()
		#print("[Bullet] TileMapLayer碰撞: point=%s normal=%s" % [collision_point, collision_normal])
		TerrainInteractor.handle_hit_at_position(self, collider, collision_point, collision_normal, can_destroy_steel)
		return

	# 边界 StaticBody2D 薄墙（由 StandardBattleField 动态创建）
	if collider.is_in_group("boundary"):
		queue_free()
		return

	# 敌人坦克 CharacterBody2D
	if collider.is_in_group("enemy_tanks"):
		if collider.has_method("take_damage"):
			collider.take_damage(damage, owner_tank)
		queue_free()
		return

	# 玩家坦克（为未来敌人子弹预留）
	if collider.is_in_group("player_tanks"):
		if collider.has_method("take_damage"):
			collider.take_damage(damage, owner_tank)
		queue_free()
		return

	# 默认：销毁子弹
	queue_free()


## 检查是否超出战场边界
func _is_out_of_bounds() -> bool:
	return global_position.x < 0 or global_position.x > BATTLEFIELD_SIZE.x or \
		   global_position.y < 0 or global_position.y > BATTLEFIELD_SIZE.y


## 更新子弹颜色(占位实现)
func _update_bullet_color() -> void:
	for child in get_children():
		if child is ColorRect:
			child.color = bullet_color
			break
