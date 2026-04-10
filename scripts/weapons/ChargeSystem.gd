## 充能系统
## 管理副武器的充能值
class_name ChargeSystem
extends Node

## 充能值变化信号
signal charge_changed(current: int, maximum: int)
## 充能满信号
signal charge_full()

## 最大充能值
@export var max_charge: int = 100

## 当前充能值
var current_charge: int = 0:
	set(value):
		var old_value := current_charge
		current_charge = clamp(value, 0, max_charge)
		if current_charge != old_value:
			charge_changed.emit(current_charge, max_charge)
			# 充能满时发送信号
			if current_charge >= max_charge and old_value < max_charge:
				charge_full.emit()


## 添加充能
## @param amount 充能点数
func add_charge(amount: int) -> void:
	current_charge += amount


## 消耗充能
## @param amount 需要消耗的充能点数
## @return 是否消耗成功
func consume_charge(amount: int) -> bool:
	if current_charge >= amount:
		current_charge -= amount
		return true
	return false


## 检查是否有足够充能
## @param amount 需要的充能点数
## @return 是否充能足够
func has_enough_charge(amount: int) -> bool:
	return current_charge >= amount


## 重置充能
func reset_charge() -> void:
	current_charge = 0


## 获取充能百分比
## @return 充能百分比 (0.0 - 1.0)
func get_charge_percentage() -> float:
	if max_charge == 0:
		return 0.0
	return float(current_charge) / float(max_charge)
