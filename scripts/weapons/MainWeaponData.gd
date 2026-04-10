## 主武器数据资源
## 定义主武器的等级属性配置
class_name MainWeaponData
extends Resource

## 武器等级 (1-3)
@export var level: int = 1

## 子弹速度 (像素/秒)
@export var bullet_speed: float = 400.0

## 子弹伤害
@export var bullet_damage: int = 1

## 射击冷却时间 (秒)
@export var fire_cooldown: float = 0.5

## 是否可摧毁钢墙
@export var can_destroy_steel: bool = false

## 子弹场景
@export var bullet_scene: PackedScene

## 子弹占位颜色 (开发阶段使用)
@export var bullet_color: Color = Color.YELLOW
