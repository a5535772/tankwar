## 玩家坦克基类
## 定义输入处理的抽象接口，子类实现具体键位映射
class_name PlayerTank
extends "res://scripts/entities/tanks/Tank.gd"

## 武器管理器
var weapon_manager: WeaponManager

## HUD 引用
var hud: WeaponHUD = null


func _ready() -> void:
	super._ready()

	# 初始化武器管理器
	weapon_manager = WeaponManager.new()
	weapon_manager.name = "WeaponManager"
	add_child(weapon_manager)

	print("PlayerTank: 武器管理器已创建, main_weapon=%s" % weapon_manager.main_weapon)

	# 初始化 HUD
	_init_hud()

	# 连接敌人击杀事件
	EventBus.enemy_killed.connect(_on_enemy_killed)


func _physics_process(delta: float) -> void:
	# 获取输入方向
	var input_dir := _get_input_direction()
	# 执行移动
	move_tank(input_dir)
	# 处理武器输入
	_handle_weapon_input()
	# 调用父类的物理处理（move_and_slide）
	super._physics_process(delta)


## 获取输入方向（子类必须重写）
## @return 归一化后的方向向量
func _get_input_direction() -> Vector2:
	push_error("子类必须实现 _get_input_direction()")
	return Vector2.ZERO


## 处理武器输入（子类可重写）
func _handle_weapon_input() -> void:
	# 主武器射击（子类实现具体键位）
	_handle_main_weapon_input()

	# 副武器射击（子类实现具体键位）
	_handle_secondary_weapon_input()

	# 副武器切换 (Q键)
	if Input.is_key_pressed(KEY_Q):
		# 使用防抖,避免连续触发
		if not _q_key_pressed:
			_q_key_pressed = true
			weapon_manager.switch_secondary_weapon()
	else:
		_q_key_pressed = false

	# 作弊模式: 无限充能 (F1键)
	if Input.is_key_pressed(KEY_F1):
		if not _f1_key_pressed:
			_f1_key_pressed = true
			weapon_manager.toggle_cheat_infinite_charge()
	else:
		_f1_key_pressed = false


## Q键防抖标志
var _q_key_pressed: bool = false

## F1键防抖标志
var _f1_key_pressed: bool = false


## 主武器输入处理（子类实现）
func _handle_main_weapon_input() -> void:
	# 子类重写实现射击键位
	pass


## 副武器输入处理（子类实现）
func _handle_secondary_weapon_input() -> void:
	# 子类重写实现射击键位
	pass


## 敌人击杀回调
func _on_enemy_killed(enemy: Node, killer: Node) -> void:
	# 通过武器管理器处理充能掠夺
	weapon_manager.on_enemy_killed(enemy, killer)


## 初始化 HUD
func _init_hud() -> void:
	# 尝试从场景树中查找 HUD
	hud = get_tree().current_scene.get_node_or_null("WeaponHUD") as WeaponHUD

	# 如果没有找到,则尝试加载
	if hud == null:
		var hud_scene := load("res://scenes/ui/WeaponHUD.tscn") as PackedScene
		if hud_scene == null:
			print("PlayerTank: 无法加载 WeaponHUD.tscn,跳过 HUD 初始化")
			return

		hud = hud_scene.instantiate() as WeaponHUD
		if hud == null:
			print("PlayerTank: 无法实例化 WeaponHUD,跳过 HUD 初始化")
			return

		# 使用 call_deferred 延迟添加节点
		get_tree().current_scene.add_child.call_deferred(hud)
		print("PlayerTank: 已延迟加载 HUD")

		# 延迟连接 HUD
		_connect_hud_deferred()
	else:
		print("PlayerTank: 找到现有 HUD")
		# 连接 HUD 到武器管理器
		weapon_manager.set_hud(hud)


## 延迟连接 HUD
func _connect_hud_deferred() -> void:
	# 等待一帧确保 HUD 已添加
	await get_tree().process_frame

	# 连接 HUD 到武器管理器
	if hud and weapon_manager:
		weapon_manager.set_hud(hud)
