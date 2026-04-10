## 导弹弹幕副武器
## 向四周发射追踪导弹
class_name MissileBarrage
extends "res://scripts/weapons/SecondaryWeapon.gd"


func _ready() -> void:
	weapon_name = "导弹弹幕"
	description = "向四周发射8枚追踪导弹"
	icon_color = Color.BLUE
	base_charge_cost = 50


## 执行武器效果
## @param owner 武器所有者(坦克)
func _execute_fire(owner: Tank) -> void:
	# 发射8枚导弹,每45度一枚
	for i in range(8):
		var angle := i * 45.0
		_fire_missile(owner.global_position, angle, owner)


## 发射单枚导弹
## @param position 发射位置
## @param angle 发射角度
## @param owner 武器所有者
func _fire_missile(position: Vector2, angle: float, owner: Tank) -> void:
	# 创建导弹节点
	var missile := Area2D.new()
	missile.set_script(preload("res://scripts/weapons/Missile.gd"))

	# 设置导弹属性
	missile.global_position = position
	missile.direction = Vector2.from_angle(deg_to_rad(angle))
	missile.damage = 2
	missile.owner_tank = owner
	missile.missile_color = Color.BLUE  # 占位颜色

	# 添加到场景
	owner.get_tree().current_scene.add_child(missile)
