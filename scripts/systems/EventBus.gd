## 事件总线
## 全局事件系统,用于解耦各模块之间的通信
extends Node

# === 坦克相关信号 ===

## 敌人被击杀信号
## @param enemy 被击杀的敌人
## @param killer 击杀者
signal enemy_killed(enemy: Node, killer: Node)

## 坦克受伤信号
## @param tank 受伤的坦克
## @param damage 伤害值
signal tank_damaged(tank: Node, damage: int)

## 坦克死亡信号
## @param tank 死亡的坦克
signal tank_died(tank: Node)


# === 武器相关信号 ===

## 武器升级信号
## @param weapon_type 武器类型 ("main" 或 "secondary")
## @param new_level 新等级
signal weapon_upgraded(weapon_type: String, new_level: int)

## 副武器解锁信号
## @param weapon 解锁的副武器
signal secondary_weapon_unlocked(weapon: Node)


# === 道具相关信号 ===

## 道具拾取信号
## @param power_up 道具
## @param collector 拾取者
signal powerup_collected(power_up: Node, collector: Node)


# === 地形相关信号 ===

## 地形瓦片被摧毁
## @param tile_type 瓦片类型 ("brick" 或 "steel")
## @param coords 被摧毁的瓦片坐标
signal terrain_destroyed(tile_type: String, coords: Vector2i)


# === 关卡相关信号 ===

## 关卡开始信号
signal level_started()

## 关卡结束信号
## @param success 是否成功
signal level_finished(success: bool)

## 游戏结束信号
signal game_over()
