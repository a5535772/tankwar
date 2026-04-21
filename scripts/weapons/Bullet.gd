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

## 战场边界（标准 13×13 网格 = 416×416 像素）
const BATTLEFIELD_SIZE: Vector2 = Vector2(416, 416)

## 碰撞层定义
const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")


func _ready() -> void:
	# 添加到子弹组
	add_to_group("bullets")

	# 设置碰撞层(根据发射者设置,这里默认为玩家子弹)
	collision_layer = CollisionLayersClass.LAYER_PLAYER_BULLET
	# 检测地形、敌人
	# 注意：移除 LAYER_BOUNDARY，边界瓦片使用 TERRAIN 层，子弹不应被水域阻挡
	collision_mask = CollisionLayersClass.LAYER_TERRAIN | \
					CollisionLayersClass.LAYER_ENEMY

	# 更新占位颜色
	_update_bullet_color()

	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	# 移动子弹
	position += direction * speed * delta

	# 战场边界检测（替代 viewport 检测）
	if _is_out_of_bounds():
		queue_free()


## 检查是否超出战场边界
func _is_out_of_bounds() -> bool:
	# 战场范围: 0 ~ 416 像素
	return global_position.x < 0 or global_position.x > BATTLEFIELD_SIZE.x or \
		   global_position.y < 0 or global_position.y > BATTLEFIELD_SIZE.y


## 更新子弹颜色(占位实现)
func _update_bullet_color() -> void:
	# 查找 ColorRect 子节点并更新颜色
	for child in get_children():
		if child is ColorRect:
			child.color = bullet_color
			break


## 碰撞体进入检测
func _on_body_entered(body: Node2D) -> void:
	# TileMapLayer 碰撞处理（优先检测）
	if body is TileMapLayer:
		_handle_tilemap_collision(body)
		return

	# 原有逻辑：组检测（兼容非 TileMap 的 StaticBody2D 等实体）
	if body.is_in_group("terrain") or body.is_in_group("boundary"):
		# 如果是砖墙,销毁砖墙
		if body.is_in_group("brick_wall"):
			if body.has_method("destroy"):
				body.destroy()
			queue_free()
		# 如果是钢墙
		elif body.is_in_group("steel_wall"):
			if can_destroy_steel and body.has_method("destroy"):
				body.destroy()
			queue_free()
		else:
			queue_free()


## 处理 TileMapLayer 碰撞
func _handle_tilemap_collision(tilemap: TileMapLayer) -> void:
	# 获取子弹位置对应的瓦片坐标
	var tile_coords: Vector2i = tilemap.local_to_map(global_position)

	# 获取瓦片数据
	var tile_data: TileData = tilemap.get_cell_tile_data(tile_coords)

	# 如果没有瓦片数据，直接销毁子弹（可能在边界外）
	if tile_data == null:
		queue_free()
		return

	# 读取瓦片类型（Custom Data）
	var tile_type: String = tile_data.get_custom_data("tile_type")

	# 根据瓦片类型执行不同逻辑
	match tile_type:
		"brick":
			# 砖墙：摧毁瓦片 + 销毁子弹
			tilemap.erase_cell(tile_coords)
			queue_free()
		"steel":
			# 钢墙：Lv.3 可摧毁，其他销毁子弹
			if can_destroy_steel:
				tilemap.erase_cell(tile_coords)
			queue_free()
		"boundary":
			# 边界墙：仅销毁子弹
			queue_free()
		_:
			# 其他类型：销毁子弹
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
