## EMP 冲击波副武器
## 瘫痪范围内的敌人
class_name EMPShockwave
extends "res://scripts/weapons/SecondaryWeapon.gd"


func _ready() -> void:
	weapon_name = "EMP 冲击波"
	description = "瘫痪范围内敌人3秒"
	icon_color = Color.CYAN
	base_charge_cost = 40


## 执行武器效果
## @param owner 武器所有者(坦克)
func _execute_fire(owner: Tank) -> void:
	# 创建 EMP 冲击波效果
	var emp := EMPWave.new()
	emp.global_position = owner.global_position
	emp.radius = 200.0
	emp.duration = 3.0
	emp.stun_color = Color.CYAN

	# 添加到场景
	owner.get_tree().current_scene.add_child(emp)
