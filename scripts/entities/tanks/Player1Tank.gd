## 玩家1坦克
## 使用 WASD 键移动，J键射击
class_name Player1Tank
extends "res://scripts/entities/tanks/PlayerTank.gd"


func _get_input_direction() -> Vector2:
	# 90坦克风格：只允许上下左右移动，不允许斜向移动
	# 优先级：上 > 下 > 左 > 右（同时按下时的决定顺序）

	if Input.is_key_pressed(KEY_W):
		return Vector2.UP
	if Input.is_key_pressed(KEY_S):
		return Vector2.DOWN
	if Input.is_key_pressed(KEY_A):
		return Vector2.LEFT
	if Input.is_key_pressed(KEY_D):
		return Vector2.RIGHT

	return Vector2.ZERO


## 主武器输入处理
func _handle_main_weapon_input() -> void:
	# J键射击
	if Input.is_key_pressed(KEY_J):
		if weapon_manager and weapon_manager.main_weapon:
			# 根据坦克旋转角度计算射击方向
			# 坦克旋转: 0度=上, 90度=右, 180度=下, 270度=左
			# 需要转换为 Godot 角度系统: 0度=右, 90度=下, 180度=左, 270度=上
			var fire_direction := _get_facing_direction()
			weapon_manager.main_weapon.fire(global_position, fire_direction)
		else:
			print("Player1Tank: weapon_manager 或 main_weapon 为 null")


## 获取坦克朝向方向
## @return 坦克面朝的方向向量
func _get_facing_direction() -> Vector2:
	# 根据旋转角度确定方向
	var angle_degrees = int(round(rotation_degrees)) % 360
	if angle_degrees < 0:
		angle_degrees += 360

	match angle_degrees:
		0: return Vector2.UP      # 0度 = 上
		90: return Vector2.RIGHT  # 90度 = 右
		180: return Vector2.DOWN  # 180度 = 下
		270: return Vector2.LEFT  # 270度 = 左
		_: return Vector2.DOWN    # 默认朝下


## 副武器输入处理
func _handle_secondary_weapon_input() -> void:
	# K键释放副武器
	if Input.is_key_pressed(KEY_K):
		weapon_manager.fire_secondary_weapon()
