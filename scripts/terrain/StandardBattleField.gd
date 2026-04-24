## 标准战场场景
## 战场尺寸: 960×544 像素 (60×34 格，每格 16px)
## 边界墙使用 StaticBody2D 薄墙（4px），其他地形使用 TileMap 瓦片
## 每个游戏逻辑大格 = 2×2 子瓦片（16px），一个大砖块需 4 个子瓦片
class_name StandardBattleField
extends Node2D

## 战场网格宽度 (60 格 = 960 像素，对应旧 30 大格)
const GRID_WIDTH: int = 60

## 战场网格高度 (34 格 = 544 像素，对应旧 17 大格)
const GRID_HEIGHT: int = 34

## 瓦片大小 (16×16 像素，一个大格=2×2 子瓦片)
const TILE_SIZE: int = 16

## 战场总尺寸 (像素)
const BATTLEFIELD_SIZE: Vector2 = Vector2i(GRID_WIDTH * TILE_SIZE, GRID_HEIGHT * TILE_SIZE)

## 边界墙厚度 (像素)
const WALL_THICKNESS: float = 4.0

## 砖墙瓦片在 TerrainTileset 中的 source ID
const BRICK_SOURCE_ID: int = 0

## 砖墙瓦片在 atlas 中的坐标
const BRICK_ATLAS_COORDS: Vector2i = Vector2i(0, 0)

## 钢墙瓦片在 TerrainTileset 中的 source ID
const STEEL_SOURCE_ID: int = 1

## 钢墙瓦片在 atlas 中的坐标
const STEEL_ATLAS_COORDS: Vector2i = Vector2i(0, 0)

## 碰撞层定义
const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")


func _ready() -> void:
	_create_boundary_walls()
	_create_brick_walls()
	_create_steel_walls()


## 创建 4 个 StaticBody2D 薄墙作为战场边界
## 碰撞层: LAYER_TERRAIN (16)，组: "boundary"
## 子弹和坦克都能正确检测
func _create_boundary_walls() -> void:
	var width: float = BATTLEFIELD_SIZE.x
	var height: float = BATTLEFIELD_SIZE.y
	var t: float = WALL_THICKNESS

	# 上墙: 宽960, 高4, 位于 (480, 2)
	_create_wall("TopWall", Vector2(width / 2, t / 2), Vector2(width, t))
	# 下墙: 宽960, 高4, 位于 (480, 542)
	_create_wall("BottomWall", Vector2(width / 2, height - t / 2), Vector2(width, t))
	# 左墙: 宽4, 高544, 位于 (2, 272)
	_create_wall("LeftWall", Vector2(t / 2, height / 2), Vector2(t, height))
	# 右墙: 宽4, 高544, 位于 (958, 272)
	_create_wall("RightWall", Vector2(width - t / 2, height / 2), Vector2(t, height))


## 将旧 32x32 大格坐标转换为 16x16 子瓦片坐标数组
## 一个大格 → 4 个子瓦片 (2×2)
static func _big_tile_to_sub_tiles(big_x: int, big_y: int) -> Array[Vector2i]:
	var sub_x: int = big_x * 2
	var sub_y: int = big_y * 2
	return [
		Vector2i(sub_x, sub_y),         # 左上
		Vector2i(sub_x + 1, sub_y),     # 右上
		Vector2i(sub_x, sub_y + 1),     # 左下
		Vector2i(sub_x + 1, sub_y + 1)  # 右下
	]


## 在 WallLayer 上绘制砖墙布局
## 战场 60×34 子格，砖墙放置在活动区域（避开边界）
## 坐标参数按旧 32x32 大格定义，内部自动展开为 2×2 子瓦片
func _create_brick_walls() -> void:
	var wall_layer: TileMapLayer = get_node_or_null("WallLayer")
	if wall_layer == null:
		push_warning("StandardBattleField: WallLayer not found, skipping brick walls")
		return

	# 砖墙测试布局（参考 PRD 第6节布局图）
	# 坐标为旧 32x32 大格坐标，内部展开为 2×2 子瓦片

	# 第一组砖墙 (左上掩体)
	_place_brick_cluster_16x16(wall_layer, 3, 3, 3, 2)

	# 第二组砖墙 (中上掩体)
	_place_brick_cluster_16x16(wall_layer, 12, 3, 4, 2)

	# 第三组砖墙 (右上掩体)
	_place_brick_cluster_16x16(wall_layer, 23, 3, 4, 2)

	# 第四组砖墙 (左中掩体)
	_place_brick_cluster_16x16(wall_layer, 5, 7, 3, 2)

	# 第五组砖墙 (右中掩体)
	_place_brick_cluster_16x16(wall_layer, 22, 7, 3, 2)

	# 基地保护砖墙 (底部中央)
	_place_brick_cluster_16x16(wall_layer, 13, 13, 4, 2)


## 在 WallLayer 上放置一个矩形区域的砖墙（大格坐标）
## 每个大格自动展开为 2×2 子瓦片
func _place_brick_cluster_16x16(wall_layer: TileMapLayer, big_start_x: int, big_start_y: int, big_width: int, big_height: int) -> void:
	for big_y in range(big_start_y, big_start_y + big_height):
		for big_x in range(big_start_x, big_start_x + big_width):
			for sub_tile in _big_tile_to_sub_tiles(big_x, big_y):
				wall_layer.set_cell(sub_tile, BRICK_SOURCE_ID, BRICK_ATLAS_COORDS)


## 在 WallLayer 上绘制钢墙布局
func _create_steel_walls() -> void:
	var wall_layer: TileMapLayer = get_node_or_null("WallLayer")
	if wall_layer == null:
		push_warning("StandardBattleField: WallLayer not found, skipping steel walls")
		return

	# 钢墙测试布局（参考 PRD 第6节布局图）
	# 钢墙位于砖墙下方，形成中排屏障

	# 第一组钢墙 (左中)
	_place_steel_cluster_16x16(wall_layer, 6, 5, 2, 2)

	# 第二组钢墙 (右中)
	_place_steel_cluster_16x16(wall_layer, 22, 5, 2, 2)

	# 第三组钢墙 (中央大块)
	_place_steel_cluster_16x16(wall_layer, 13, 9, 4, 2)


## 在 WallLayer 上放置一个矩形区域的钢墙（大格坐标）
func _place_steel_cluster_16x16(wall_layer: TileMapLayer, big_start_x: int, big_start_y: int, big_width: int, big_height: int) -> void:
	for big_y in range(big_start_y, big_start_y + big_height):
		for big_x in range(big_start_x, big_start_x + big_width):
			for sub_tile in _big_tile_to_sub_tiles(big_x, big_y):
				wall_layer.set_cell(sub_tile, STEEL_SOURCE_ID, STEEL_ATLAS_COORDS)


## 创建单个边界墙体
func _create_wall(wall_name: String, pos: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.position = pos
	wall.collision_layer = CollisionLayersClass.LAYER_TERRAIN
	wall.collision_mask = 0
	wall.add_to_group("boundary")

	# 碰撞形状
	var shape := RectangleShape2D.new()
	shape.size = size

	var collider := CollisionShape2D.new()
	collider.shape = shape

	wall.add_child(collider)
	add_child(wall)
