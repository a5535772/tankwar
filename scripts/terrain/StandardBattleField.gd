## 标准战场场景
## 战场尺寸: 960×544 像素 (30×17 格，每格 32px)
## 边界墙需要手动在编辑器中绘制
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


func _ready() -> void:
	# 边界墙需要手动在 BoundaryLayer 上绘制
	# TerrainTileset 包含 boundary 瓦片 (Source ID = 2)
	pass
