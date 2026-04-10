## 武器升级道具
## 拾取后升级玩家主武器
class_name WeaponUpgradePowerUp
extends "res://scripts/powerups/PowerUp.gd"


func _ready() -> void:
	powerup_name = "武器升级"
	description = "提升主武器等级"
	powerup_color = Color.YELLOW  # 黄色表示武器升级

	super._ready()


## 应用道具效果
## @param collector 拾取者(玩家坦克)
func apply_effect(collector: Node) -> void:
	# 获取武器管理器
	var weapon_manager := collector.get_node_or_null("WeaponManager")
	if weapon_manager and weapon_manager.main_weapon:
		weapon_manager.upgrade_main_weapon()
