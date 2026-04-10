## 武器 HUD
## 显示主武器等级和充能条
class_name WeaponHUD
extends CanvasLayer

## 主武器等级容器
@onready var main_weapon_container: HBoxContainer = $MarginContainer/VBoxContainer/MainWeaponContainer

## 充能条
@onready var charge_bar: ProgressBar = $MarginContainer/VBoxContainer/ChargeBar

## 充能标签
@onready var charge_label: Label = $MarginContainer/VBoxContainer/ChargeLabel

## 当前副武器标签
@onready var secondary_weapon_label: Label = $MarginContainer/VBoxContainer/SecondaryWeaponLabel

## 当前星星节点列表
var star_nodes: Array[ColorRect] = []


func _ready() -> void:
	# 初始化显示
	_update_main_weapon_display(1)
	_update_charge_display(0, 100)


## 更新主武器等级显示
## @param level 武器等级
func update_main_weapon_level(level: int) -> void:
	_update_main_weapon_display(level)


## 更新主武器显示
## @param level 武器等级
func _update_main_weapon_display(level: int) -> void:
	# 清除现有星星
	for star in star_nodes:
		star.queue_free()
	star_nodes.clear()

	# 创建新的星星(最多3颗)
	for i in range(3):
		var star := ColorRect.new()
		star.custom_minimum_size = Vector2(16, 16)
		# 已激活的星星显示黄色,未激活的显示灰色
		if i < level:
			star.color = Color.YELLOW
		else:
			star.color = Color(0.3, 0.3, 0.3, 1)  # 深灰色
		main_weapon_container.add_child(star)
		star_nodes.append(star)


## 更新充能显示
## @param current 当前充能值
## @param maximum 最大充能值
func update_charge(current: int, maximum: int) -> void:
	_update_charge_display(current, maximum)


## 更新充能显示
## @param current 当前充能值
## @param maximum 最大充能值
func _update_charge_display(current: int, maximum: int) -> void:
	if charge_bar:
		charge_bar.max_value = maximum
		charge_bar.value = current

	if charge_label:
		charge_label.text = "充能: %d/%d" % [current, maximum]


## 更新副武器显示
## @param weapon_name 武器名称
## @param charge_cost 充能消耗
func update_secondary_weapon(weapon_name: String, charge_cost: int) -> void:
	if secondary_weapon_label:
		secondary_weapon_label.text = "副武器: %s (消耗: %d) [Q切换]" % [weapon_name, charge_cost]
