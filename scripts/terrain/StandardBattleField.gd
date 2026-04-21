## 标准战场场景
## 战场尺寸: 960×544 像素 (30×17 格，每格 32px)
## 边界墙使用 StaticBody2D 薄墙（4px），其他地形使用 TileMap 瓦片
class_name StandardBattleField
extends Node2D

## 战场网格宽度 (30 格 = 960 像素)
const GRID_WIDTH: int = 30

## 战场网格高度 (17 格 = 544 像素)
const GRID_HEIGHT: int = 17

## 瓦片大小 (32×32 像素)
const TILE_SIZE: int = 32

## 战场总尺寸 (像素)
const BATTLEFIELD_SIZE: Vector2 = Vector2i(GRID_WIDTH * TILE_SIZE, GRID_HEIGHT * TILE_SIZE)

## 边界墙厚度 (像素)
const WALL_THICKNESS: float = 4.0

## 碰撞层定义
const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")


func _ready() -> void:
	_create_boundary_walls()


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
