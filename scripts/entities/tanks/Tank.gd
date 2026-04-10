## 坦克基类
## 提供通用的移动、旋转逻辑，不处理具体输入
class_name Tank
extends CharacterBody2D

## 预加载碰撞层定义
const CollisionLayersClass = preload("res://scripts/systems/CollisionLayers.gd")

## 移动速度（像素/秒）
@export var speed: float = 100.0

## 当前朝向（上、下、左、右）
var direction: Vector2 = Vector2.DOWN

## 网格对齐大小
const GRID_SIZE: int = 32

## 动画节点引用
@onready var tank_body: AnimatedSprite2D = $TankBody
@onready var track_left: AnimatedSprite2D = $TrackLeft
@onready var track_right: AnimatedSprite2D = $TrackRight


## 碰撞层类型：用于区分玩家和敌人坦克
## 在检查器中设置，PlayerTank 默认为 LAYER_PLAYER，EnemyTank 默认为 LAYER_ENEMY
@export var collision_layer_type: int = CollisionLayersClass.LAYER_PLAYER

## 碰撞检测目标：地形、边界、友军
## 子类可根据需要覆盖（例如敌人检测 LAYER_ENEMY）
@export var collision_mask_types: int = CollisionLayersClass.LAYER_TERRAIN | CollisionLayersClass.LAYER_BOUNDARY | CollisionLayersClass.LAYER_PLAYER


func _ready() -> void:
	# 根据导出变量设置碰撞层
	collision_layer = collision_layer_type
	collision_mask = collision_mask_types


## 移动坦克（由子类调用）
## @param input_dir 输入方向（归一化后的向量）
func move_tank(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		velocity = Vector2.ZERO
		_stop_animation()
		return
	
	# 更新朝向
	direction = input_dir
	# 更新旋转角度（0度=右，顺时针）
	_update_rotation()
	# 播放移动动画
	_play_move_animation()
	
	# 设置速度
	velocity = input_dir * speed


## 根据方向更新坦克旋转
func _update_rotation() -> void:
	# 坦克图片默认朝上
	# 上=0度，右=90度，下=180度，左=270度（顺时针）
	if direction == Vector2.UP:
		rotation_degrees = 0
	elif direction == Vector2.RIGHT:
		rotation_degrees = 90
	elif direction == Vector2.DOWN:
		rotation_degrees = 180
	elif direction == Vector2.LEFT:
		rotation_degrees = 270


func _physics_process(_delta: float) -> void:
	# 应用移动
	move_and_slide()


## 播放移动动画
func _play_move_animation() -> void:
	if tank_body:
		tank_body.play("move")
	if track_left:
		track_left.play("move")
	if track_right:
		track_right.play("move")


## 停止动画
func _stop_animation() -> void:
	if tank_body:
		tank_body.play("idle")
		tank_body.stop()
	if track_left:
		track_left.stop()
	if track_right:
		track_right.stop()
