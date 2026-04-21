## 主武器控制类
## 管理主武器的射击、升级逻辑
class_name MainWeapon
extends Node

## 武器升级信号
signal weapon_upgraded(new_level: int)

## 最大等级
const MAX_LEVEL: int = 3

## 当前等级
var current_level: int = 1:
	set(value):
		current_level = clamp(value, 1, MAX_LEVEL)
		_update_weapon_data()

## 当前武器数据
var weapon_data: MainWeaponData

## 射击冷却计时器
var fire_cooldown_timer: float = 0.0

## 是否可以射击
var can_fire: bool = true

## 武器所有者(坦克)
var owner_tank: Tank = null

## 武器配置数据列表
var weapon_configs: Array[MainWeaponData] = []

## 子弹场景列表
var bullet_scenes: Array[PackedScene] = []


func _ready() -> void:
	# 初始化武器配置数据
	_init_weapon_configs()
	# 加载子弹场景
	_init_bullet_scenes()
	# 设置初始等级并更新武器数据
	current_level = 1
	_update_weapon_data()  # 确保武器数据被初始化


func _init_weapon_configs() -> void:
	# 直接创建配置数据，避免资源加载问题
	# Level 1: 普通炮弹
	var level1 := MainWeaponData.new()
	level1.level = 1
	level1.bullet_speed = 400.0
	level1.bullet_damage = 1
	level1.fire_cooldown = 0.5
	level1.can_destroy_steel = false
	level1.bullet_color = Color.YELLOW
	weapon_configs.append(level1)

	# Level 2: 快速炮弹
	var level2 := MainWeaponData.new()
	level2.level = 2
	level2.bullet_speed = 500.0
	level2.bullet_damage = 1
	level2.fire_cooldown = 0.3
	level2.can_destroy_steel = false
	level2.bullet_color = Color.ORANGE
	weapon_configs.append(level2)

	# Level 3: 消钢炮弹
	var level3 := MainWeaponData.new()
	level3.level = 3
	level3.bullet_speed = 450.0
	level3.bullet_damage = 2
	level3.fire_cooldown = 0.4
	level3.can_destroy_steel = true
	level3.bullet_color = Color.RED
	weapon_configs.append(level3)


func _init_bullet_scenes() -> void:
	# 加载子弹场景
	bullet_scenes.append(preload("res://scenes/entities/weapons/bullets/BasicBullet.tscn"))
	bullet_scenes.append(preload("res://scenes/entities/weapons/bullets/FastBullet.tscn"))
	bullet_scenes.append(preload("res://scenes/entities/weapons/bullets/SteelDestroyerBullet.tscn"))


func _process(delta: float) -> void:
	# 更新冷却计时器
	if not can_fire:
		fire_cooldown_timer -= delta
		if fire_cooldown_timer <= 0.0:
			can_fire = true
			fire_cooldown_timer = 0.0


## 更新武器数据
func _update_weapon_data() -> void:
	if current_level >= 1 and current_level <= weapon_configs.size():
		weapon_data = weapon_configs[current_level - 1]


## 升级武器
func upgrade() -> bool:
	if current_level >= MAX_LEVEL:
		return false

	current_level += 1
	weapon_upgraded.emit(current_level)
	return true


## 射击
## @param position 发射位置
## @param direction 发射方向
## @return 是否成功发射
func fire(position: Vector2, direction: Vector2) -> bool:
	if not can_fire:
		print("主武器: 冷却中，无法射击")
		return false

	if weapon_data == null:
		push_error("主武器: weapon_data 为 null")
		return false

	# 从场景实例化子弹
	if current_level < 1 or current_level > bullet_scenes.size():
		push_error("主武器: 子弹场景索引越界, current_level=%d, bullet_scenes.size()=%d" % [current_level, bullet_scenes.size()])
		return false

	var bullet := bullet_scenes[current_level - 1].instantiate() as Bullet
	bullet.global_position = position
	bullet.direction = direction
	bullet.speed = weapon_data.bullet_speed
	bullet.damage = weapon_data.bullet_damage
	bullet.can_destroy_steel = weapon_data.can_destroy_steel
	bullet.bullet_color = weapon_data.bullet_color

	# 添加到场景
	get_tree().current_scene.add_child(bullet)

	# 设置冷却
	can_fire = false
	fire_cooldown_timer = weapon_data.fire_cooldown

	print("主武器: 成功发射子弹, 等级=%d, 位置=%s, 方向=%s" % [current_level, position, direction])
	return true


## 设置武器所有者坦克
func set_owner_tank(tank: Tank) -> void:
	owner_tank = tank
