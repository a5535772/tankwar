## 副武器基类
## 定义副武器的通用接口和逻辑
class_name SecondaryWeapon
extends Node

## 武器释放信号
signal weapon_fired(weapon: SecondaryWeapon)

## 充能消耗信号
signal charge_consumed(amount: int)

## 武器名称
@export var weapon_name: String = "未命名武器"

## 武器描述
@export var description: String = ""

## 武器图标(占位用颜色)
@export var icon_color: Color = Color.BLUE

## 基础充能消耗
@export var base_charge_cost: int = 50

## 当前等级
@export var current_level: int = 1

## 最大等级
@export var max_level: int = 4

## 是否已解锁(默认解锁用于测试)
var is_unlocked: bool = true


## 检查是否可以释放
## @param current_charge 当前充能值
## @return 是否可以释放
func can_fire(current_charge: int) -> bool:
	return is_unlocked and current_charge >= get_charge_cost()


## 释放武器
## @param owner 武器所有者(坦克)
func fire(owner: Tank) -> void:
	if not can_fire(_get_current_charge(owner)):
		return

	# 执行武器效果
	_execute_fire(owner)

	# 发送信号
	charge_consumed.emit(get_charge_cost())
	weapon_fired.emit(self)


## 获取当前充能消耗(根据等级降低)
## @return 充能消耗点数
func get_charge_cost() -> int:
	return max(0, base_charge_cost - (current_level - 1) * 5)


## 升级武器
## @return 是否升级成功
func upgrade() -> bool:
	if current_level >= max_level:
		return false

	current_level += 1
	return true


## 执行武器效果(子类实现)
## @param _owner 武器所有者
func _execute_fire(_owner: Tank) -> void:
	push_error("子类必须实现 _execute_fire()")


## 获取当前充能值(辅助方法)
## @param owner 武器所有者
## @return 当前充能值
func _get_current_charge(owner: Tank) -> int:
	# 从 WeaponManager 获取充能值
	var weapon_manager := owner.get_node_or_null("WeaponManager")
	if weapon_manager and weapon_manager.charge_system:
		return weapon_manager.charge_system.current_charge
	return 0
