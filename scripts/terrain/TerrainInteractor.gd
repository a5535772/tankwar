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


## 诊断标记（仅首次打印 TileSet 信息）
static var _diagnostic_printed: bool = false


## 通过 source_id 推断瓦片类型（custom_data 不可用时的后备方案）
## TerrainTileset: source 0=brick, 1=steel, 2=boundary
static func _tile_type_from_source(source_id: int) -> String:
	match source_id:
		0: return "brick"
		1: return "steel"
		2: return "boundary"
		_: return ""


## 打印 TileSet 诊断信息（仅首次）
static func _print_tileset_diagnostic(tilemap: TileMapLayer) -> void:
	if _diagnostic_printed:
		return
	_diagnostic_printed = true

	var tileset: TileSet = tilemap.tile_set
	if tileset == null:
		push_warning("[TerrainInteractor] TileSet 为 null!")
		return

	print("[TerrainInteractor] === TileSet 诊断 ===")
	print("  tile_size: %s" % tileset.tile_size)
	print("  custom_data_layers_count: %d" % tileset.get_custom_data_layers_count())
	for i in range(tileset.get_custom_data_layers_count()):
		print("  custom_data_layer[%d]: name='%s' type=%d" % [i, tileset.get_custom_data_layer_name(i), tileset.get_custom_data_layer_type(i)])
	print("  sources_count: %d" % tileset.get_source_count())
	for i in range(tileset.get_source_count()):
		var source_id: int = tileset.get_source_id(i)
		var source: TileSetSource = tileset.get_source(source_id)
		print("  source[%d]: class=%s" % [source_id, source.get_class()])
	# 扫描 WallLayer 上的前几个瓦片
	var used_cells: Array[Vector2i] = tilemap.get_used_cells()
	print("  used_cells_count: %d" % used_cells.size())
	var count: int = 0
	for cell_coords in used_cells:
		if count >= 5:
			break
		var data: TileData = tilemap.get_cell_tile_data(cell_coords)
		var src_id: int = tilemap.get_cell_source_id(cell_coords)
		var cd: String = ""
		if data != null:
			var raw_cd: Variant = data.get_custom_data("tile_type")
			cd = str(raw_cd) if raw_cd != null else "<null>"
		print("  tile[%s]: source_id=%d custom_data='%s'" % [cell_coords, src_id, cd])
		count += 1
	print("[TerrainInteractor] === 诊断结束 ===")


## 处理 CharacterBody2D 抛射物命中 TileMapLayer
## 碰撞点在瓦片边界上，local_to_map 可能映射到空格
## 因此用碰撞法线方向微偏移确保定位到砖块格
static func handle_hit_at_position(
		projectile: Node2D,
		tilemap: TileMapLayer,
		collision_point: Vector2,
		collision_normal: Vector2,
		can_destroy_steel: bool
) -> void:
	# 首次碰撞时打印 TileSet 诊断
	#_print_tileset_diagnostic(tilemap)

	# 碰撞法线指向子弹（远离墙），所以减去法线才是向墙内偏移
	var probe: Vector2 = collision_point - collision_normal * 1.0
	var coords: Vector2i = tilemap.local_to_map(tilemap.to_local(probe))
	#print("[TerrainInteractor] handle_hit_at_position: probe=%s coords=%s" % [probe, coords])

	var tile_data: TileData = tilemap.get_cell_tile_data(coords)

	# 碰撞点在瓦片边界时，local_to_map 可能映射到空格
	# 此时检查相邻8格（含对角线），找到实际被击中的瓦片
	if tile_data == null:
		var original_coords: Vector2i = coords
		for offset in [
			Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
			Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)
		]:
			var neighbor: Vector2i = coords + offset
			var neighbor_data: TileData = tilemap.get_cell_tile_data(neighbor)
			if neighbor_data != null:
				coords = neighbor
				tile_data = neighbor_data
				#print("[TerrainInteractor] 边界修正: %s → %s" % [original_coords, coords])
				break

	if tile_data == null:
		push_warning("[TerrainInteractor] 瓦片数据为null! coords=%s probe=%s collision_point=%s" % [coords, probe, collision_point])
		projectile.queue_free()
		return

	var raw: Variant = tile_data.get_custom_data("tile_type")
	var tile_type: String = raw if raw is String else ""

	# 后备方案：custom_data 为空时，通过 source_id 推断瓦片类型
	if tile_type == "":
		var source_id: int = tilemap.get_cell_source_id(coords)
		tile_type = _tile_type_from_source(source_id)
		#if tile_type != "":
			#print("[TerrainInteractor] custom_data为空，通过source_id推断: coords=%s source_id=%d tile_type='%s'" % [coords, source_id, tile_type])

	#print("[TerrainInteractor] 瓦片命中: coords=%s tile_type='%s' raw=%s raw_type=%s" % [coords, tile_type, raw, type_string(typeof(raw))])

	_process_tile_hit(projectile, tilemap, coords, tile_type, can_destroy_steel)


## 处理 Area2D 抛射物命中 TileMapLayer（导弹等）
## 使用抛射物位置 + 方向搜索定位瓦片
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

	# 后备方案：custom_data 为空时，通过 source_id 推断瓦片类型
	if tile_type == "":
		var source_id: int = tilemap.get_cell_source_id(coords)
		tile_type = _tile_type_from_source(source_id)

	_process_tile_hit(projectile, tilemap, coords, tile_type, can_destroy_steel)


## 统一的瓦片命中处理逻辑
static func _process_tile_hit(
		projectile: Node2D,
		tilemap: TileMapLayer,
		coords: Vector2i,
		tile_type: String,
		can_destroy_steel: bool
) -> void:
	match tile_type:
		"brick":
			#print("[TerrainInteractor] 销毁砖墙: coords=%s" % coords)
			_spawn_destroy_fx(tilemap, coords, FX_COLOR_BRICK)
			tilemap.erase_cell(coords)
			EventBus.terrain_destroyed.emit("brick", coords)
			projectile.queue_free()
		"steel":
			if can_destroy_steel:
				#print("[TerrainInteractor] 销毁钢墙: coords=%s" % coords)
				_spawn_destroy_fx(tilemap, coords, FX_COLOR_STEEL)
				tilemap.erase_cell(coords)
				EventBus.terrain_destroyed.emit("steel", coords)
			#else:
				#print("[TerrainInteractor] 钢墙未摧毁(无法破坏钢墙): coords=%s" % coords)
			projectile.queue_free()
		"boundary":
			projectile.queue_free()
		_:
			push_warning(
				"TerrainInteractor: tile at %s has unexpected tile_type='%s'" % [coords, tile_type]
			)
			projectile.queue_free()


## 查找抛射物实际命中的瓦片坐标（Area2D 版本）
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
	# 16x16 子瓦片的 VFX 半尺寸
	var hs: float = 8.0
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
