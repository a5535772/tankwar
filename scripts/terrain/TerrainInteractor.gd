## 地形交互工具类
## 集中处理子弹/导弹命中 TileMapLayer 的逻辑：坐标解析、瓦片消除、VFX、事件广播
## 所有方法均为 static，供 Bullet、Missile 等抛射物直接调用
class_name TerrainInteractor

## 无效瓦片坐标哨兵值（用于替代不存在的 Vector2i.MIN）
const INVALID_TILE: Vector2i = Vector2i(-2147483648, -2147483648)

## 砖墙销毁 VFX 颜色
const FX_COLOR_BRICK: Color = Color(0.85, 0.4, 0.1, 1.0)

## 钢墙销毁 VFX 颜色
const FX_COLOR_STEEL: Color = Color(0.75, 0.75, 0.8, 1.0)


## 处理抛射物命中 TileMapLayer 的完整逻辑
## 负责：坐标查找 → 类型判断 → 消除瓦片 → VFX → EventBus → 销毁抛射物
static func handle_hit(
		projectile: Node2D,
		tilemap: TileMapLayer,
		direction: Vector2,
		can_destroy_steel: bool
) -> void:
	var coords: Vector2i = _find_hit_coords(tilemap, projectile.global_position, direction)
	if coords == INVALID_TILE:
		projectile.queue_free()
		return

	var tile_data: TileData = tilemap.get_cell_tile_data(coords)
	if tile_data == null:
		projectile.queue_free()
		return

	var raw: Variant = tile_data.get_custom_data("tile_type")
	var tile_type: String = raw if raw is String else ""

	match tile_type:
		"brick":
			_spawn_destroy_fx(tilemap, coords, FX_COLOR_BRICK)
			tilemap.erase_cell(coords)
			EventBus.terrain_destroyed.emit("brick", coords)
			projectile.queue_free()
		"steel":
			if can_destroy_steel:
				_spawn_destroy_fx(tilemap, coords, FX_COLOR_STEEL)
				tilemap.erase_cell(coords)
				EventBus.terrain_destroyed.emit("steel", coords)
			projectile.queue_free()
		"boundary":
			projectile.queue_free()
		_:
			push_warning(
				"TerrainInteractor: tile at %s has unexpected tile_type='%s'" % [coords, tile_type]
			)
			projectile.queue_free()


## 查找子弹实际命中的瓦片坐标
## 子弹速度较快时中心可能已穿越瓦片，因此同时向前/向后各搜索 2 格
static func _find_hit_coords(
		tilemap: TileMapLayer,
		world_pos: Vector2,
		direction: Vector2
) -> Vector2i:
	var center: Vector2i = tilemap.local_to_map(tilemap.to_local(world_pos))
	if tilemap.get_cell_tile_data(center) != null:
		return center

	var step: Vector2i = Vector2i(
		1 if direction.x > 0 else (-1 if direction.x < 0 else 0),
		1 if direction.y > 0 else (-1 if direction.y < 0 else 0)
	)

	for i in range(1, 3):
		var forward: Vector2i = center + step * i
		if tilemap.get_cell_tile_data(forward) != null:
			return forward
		var backward: Vector2i = center - step * i
		if tilemap.get_cell_tile_data(backward) != null:
			return backward

	return INVALID_TILE


## 在销毁坐标处生成占位闪光 VFX（Polygon2D 淡出动画）
static func _spawn_destroy_fx(tilemap: TileMapLayer, coords: Vector2i, color: Color) -> void:
	var world_pos: Vector2 = tilemap.to_global(tilemap.map_to_local(coords))

	var fx := Polygon2D.new()
	var hs: float = 16.0
	fx.polygon = PackedVector2Array([
		Vector2(-hs, -hs), Vector2(hs, -hs),
		Vector2(hs, hs), Vector2(-hs, hs)
	])
	fx.color = color
	fx.z_index = 10

	var scene_root: Node = tilemap.get_tree().current_scene
	scene_root.add_child(fx)
	fx.global_position = world_pos

	var tween: Tween = tilemap.get_tree().create_tween()
	tween.tween_property(fx, "modulate:a", 0.0, 0.15)
	tween.tween_callback(fx.queue_free)
