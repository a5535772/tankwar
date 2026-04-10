## 道具基类
## 所有道具的通用逻辑
class_name PowerUp
extends Area2D

## 道具拾取信号
signal collected(collector: Node)

## 道具名称
@export var powerup_name: String = "未知道具"

## 道具描述
@export var description: String = ""

## 道具颜色(占位用)
@export var powerup_color: Color = Color.WHITE

## 碰撞层定义
const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")


func _ready() -> void:
	# 设置碰撞层
	collision_layer = CollisionLayersClass.LAYER_POWERUP
	# 只检测玩家
	collision_mask = CollisionLayersClass.LAYER_PLAYER

	# 连接碰撞信号
	body_entered.connect(_on_body_entered)

	# 更新颜色(占位实现)
	_update_color()


## 更新道具颜色(子类重写)
func _update_color() -> void:
	# 查找 ColorRect 子节点并更新颜色
	for child in get_children():
		if child is ColorRect:
			child.color = powerup_color
			break


## 碰撞体进入检测
func _on_body_entered(body: Node2D) -> void:
	# 检查是否是玩家
	if body.is_in_group("player_tanks"):
		# 应用道具效果
		apply_effect(body)
		# 发送拾取信号
		collected.emit(body)
		EventBus.powerup_collected.emit(self, body)
		# 销毁道具
		queue_free()


## 应用道具效果(子类实现)
## @param collector 拾取者
func apply_effect(collector: Node) -> void:
	push_error("子类必须实现 apply_effect()")
