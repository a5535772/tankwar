## 子弹基类
## 处理子弹的移动、碰撞检测、TileMap 交互
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

## 战场边界（960×544 像素，30×17 格）
const BATTLEFIELD_SIZE: Vector2 = Vector2(960, 544)

## 子弹每帧最大移动距离（像素），超出此距离则分步移动防止穿模
const MAX_STEP: float = 8.0

## 碰撞层定义
const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")

## 子弹是否已命中（防止 queue_free 延迟期间重复处理）
var _hit: bool = false


func _ready() -> void:
	add_to_group("bullets")
	collision_layer = CollisionLayersClass.LAYER_PLAYER_BULLET
	collision_mask = CollisionLayersClass.LAYER_TERRAIN | CollisionLayersClass.LAYER_ENEMY
	_update_bullet_color()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	var remaining: float = speed * delta
	var step_dir: Vector2 = direction.normalized()
	# 分步移动：每步不超过 MAX_STEP，防止高速子弹穿透薄墙
	while remaining > 0.0 and not _hit:
		var step: float = minf(remaining, MAX_STEP)
		position += step_dir * step
		remaining -= step
		# 每步移动后立即检测碰撞
		_check_overlap()
	if not _hit and _is_out_of_bounds():
		queue_free()


## 检查是否超出战场边界
func _is_out_of_bounds() -> bool:
	# 战场范围: 0 ~ 960×544 像素
	return global_position.x < 0 or global_position.x > BATTLEFIELD_SIZE.x or \
		   global_position.y < 0 or global_position.y > BATTLEFIELD_SIZE.y


## 每步移动后主动检测碰撞体（补充 Area2D 信号可能遗漏的情况）
func _check_overlap() -> void:
	# 检测重叠的 body（地形、边界等）
	for body in get_overlapping_bodies():
		_on_body_entered(body)
		if _hit:
			return
	# 检测重叠的 area（敌人 HurtArea 等）
	for area in get_overlapping_areas():
		_on_area_entered(area)
		if _hit:
			return


## 更新子弹颜色(占位实现)
func _update_bullet_color() -> void:
	for child in get_children():
		if child is ColorRect:
			child.color = bullet_color
			break


## 碰撞体进入检测
func _on_body_entered(body: Node2D) -> void:
	if _hit:
		return
	if body is TileMapLayer:
		_hit = true
		TerrainInteractor.handle_hit(self, body, direction, can_destroy_steel)
		return
	# 边界 StaticBody2D 薄墙（4px，由 StandardBattleField 动态创建）
	if body.is_in_group("boundary"):
		_hit = true
		queue_free()
		return
	# 敌人坦克 CharacterBody2D 直接命中兜底（正常由 HurtArea 的 area_entered 处理）
	if body.is_in_group("enemy_tanks"):
		_hit = true
		if body.has_method("take_damage"):
			body.take_damage(damage, owner_tank)
		queue_free()
		return
	_hit = true
	queue_free()


## 区域进入检测（检测敌人坦克的 HurtArea）
func _on_area_entered(area: Area2D) -> void:
	if _hit:
		return
	if area.is_in_group("enemy_tanks") or area.get_parent().is_in_group("enemy_tanks"):
		_hit = true
		var enemy_tank: Node = area.get_parent()
		if enemy_tank.has_method("take_damage"):
			enemy_tank.take_damage(damage, owner_tank)
		queue_free()
	elif area.is_in_group("bullets"):
		_hit = true
		queue_free()
