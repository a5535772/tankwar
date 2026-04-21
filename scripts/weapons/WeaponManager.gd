## 武器管理器
## 管理主副武器、充能系统、武器切换
class_name WeaponManager
extends Node

## 主武器升级信号
signal main_weapon_upgraded(new_level: int)

## 副武器切换信号
signal secondary_weapon_changed(weapon_name: String, charge_cost: int)

## 主武器
@export var main_weapon: MainWeapon

## 副武器列表
@export var secondary_weapons: Array[SecondaryWeapon] = []

## 充能系统
var charge_system: ChargeSystem

## 当前副武器索引
var current_secondary_weapon_index: int = 0

## HUD 引用
var hud: WeaponHUD = null

## 作弊模式: 无限充能(测试用)
var cheat_infinite_charge: bool = false


func _ready() -> void:
	# 初始化充能系统
	charge_system = ChargeSystem.new()
	add_child(charge_system)
	charge_system.charge_changed.connect(_on_charge_changed)
	charge_system.charge_full.connect(_on_charge_full)

	# 初始化主武器
	if not main_weapon:
		main_weapon = MainWeapon.new()
		add_child(main_weapon)
		print("WeaponManager: 主武器已创建")

	# 设置主武器的所有者坦克（确保子弹的 owner_tank 不为 null）
	var owner_tank := get_parent() as Tank
	if owner_tank and main_weapon:
		main_weapon.set_owner_tank(owner_tank)

	# 初始化副武器
	_init_secondary_weapons()

	# 连接主武器升级信号
	if main_weapon:
		main_weapon.weapon_upgraded.connect(_on_main_weapon_upgraded)


func _process(_delta: float) -> void:
	# 作弊模式: 始终保持满充能
	if cheat_infinite_charge:
		if charge_system.current_charge < charge_system.max_charge:
			charge_system.current_charge = charge_system.max_charge


## 初始化副武器
func _init_secondary_weapons() -> void:
	# 创建导弹弹幕
	var missile_barrage := preload("res://scripts/weapons/secondary/MissileBarrage.gd").new()
	missile_barrage.name = "MissileBarrage"
	add_child(missile_barrage)
	secondary_weapons.append(missile_barrage)

	# 创建 EMP 冲击波
	var emp_shockwave := preload("res://scripts/weapons/secondary/EMPShockwave.gd").new()
	emp_shockwave.name = "EMPShockwave"
	add_child(emp_shockwave)
	secondary_weapons.append(emp_shockwave)

	print("WeaponManager: 已创建 %d 个副武器" % secondary_weapons.size())


## 升级主武器
func upgrade_main_weapon() -> void:
	if main_weapon.upgrade():
		main_weapon_upgraded.emit(main_weapon.current_level)


## 切换副武器
func switch_secondary_weapon() -> void:
	if secondary_weapons.is_empty():
		return

	var next_index := (current_secondary_weapon_index + 1) % secondary_weapons.size()
	current_secondary_weapon_index = next_index

	var weapon := secondary_weapons[current_secondary_weapon_index]
	secondary_weapon_changed.emit(weapon.weapon_name, weapon.get_charge_cost())

	# 更新 HUD
	_update_hud_secondary_weapon()


## 释放副武器
func fire_secondary_weapon() -> void:
	if secondary_weapons.is_empty():
		return

	var weapon := secondary_weapons[current_secondary_weapon_index]
	if weapon.can_fire(charge_system.current_charge):
		# 获取武器所有者(坦克)
		var owner_tank := get_parent() as Tank
		if owner_tank:
			weapon.fire(owner_tank)
			charge_system.consume_charge(weapon.get_charge_cost())


## 敌人被击杀回调
## @param enemy 被击杀的敌人
## @param killer 击杀者
func on_enemy_killed(enemy: Node, killer: Node) -> void:
	# 击杀者是自己才掠夺充能
	if killer == get_parent() and enemy.has_method("get_charge_value"):
		var charge_value: int = enemy.get_charge_value()
		charge_system.add_charge(charge_value)


## 充能变化回调
func _on_charge_changed(current: int, maximum: int) -> void:
	# 更新 HUD 充能条
	if hud:
		hud.update_charge(current, maximum)


## 充能满回调
func _on_charge_full() -> void:
	# 充能满提示
	print("充能已满!")


## 主武器升级回调
func _on_main_weapon_upgraded(new_level: int) -> void:
	main_weapon_upgraded.emit(new_level)
	# 更新 HUD
	if hud:
		hud.update_main_weapon_level(new_level)


## 设置 HUD 引用
func set_hud(hud_node: WeaponHUD) -> void:
	hud = hud_node
	# 初始化 HUD 显示
	if hud:
		# 更新主武器等级
		if main_weapon:
			hud.update_main_weapon_level(main_weapon.current_level)
		# 更新充能条
		hud.update_charge(charge_system.current_charge, charge_system.max_charge)
		# 更新副武器信息
		_update_hud_secondary_weapon()


## 更新 HUD 副武器显示
func _update_hud_secondary_weapon() -> void:
	if hud and not secondary_weapons.is_empty():
		var weapon := secondary_weapons[current_secondary_weapon_index]
		hud.update_secondary_weapon(weapon.weapon_name, weapon.get_charge_cost())


## 切换作弊模式: 无限充能
## @param enabled 是否启用
func set_cheat_infinite_charge(enabled: bool) -> void:
	cheat_infinite_charge = enabled
	if enabled:
		print("作弊模式已启用: 无限充能")
		# 立即设置满充能
		charge_system.current_charge = charge_system.max_charge
	else:
		print("作弊模式已关闭: 无限充能")


## 切换作弊模式状态
func toggle_cheat_infinite_charge() -> void:
	set_cheat_infinite_charge(not cheat_infinite_charge)
