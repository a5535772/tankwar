## 玩家2坦克
## 使用方向键移动
class_name Player2Tank
extends "res://scripts/entities/tanks/PlayerTank.gd"


func _get_input_direction() -> Vector2:
	# 90坦克风格：只允许上下左右移动，不允许斜向移动
	# 优先级：上 > 下 > 左 > 右（同时按下时的决定顺序）
	
	if Input.is_key_pressed(KEY_UP):
		return Vector2.UP
	if Input.is_key_pressed(KEY_DOWN):
		return Vector2.DOWN
	if Input.is_key_pressed(KEY_LEFT):
		return Vector2.LEFT
	if Input.is_key_pressed(KEY_RIGHT):
		return Vector2.RIGHT
	
	return Vector2.ZERO
