## 碰撞层定义
## 所有碰撞层使用位掩码定义，便于灵活配置碰撞关系
class_name CollisionLayers

## 玩家坦克层（包括玩家1和玩家2）
const LAYER_PLAYER: int = 1 << 0

## 敌人坦克层
const LAYER_ENEMY: int = 1 << 1

## 玩家炮弹层
const LAYER_PLAYER_BULLET: int = 1 << 2

## 敌人炮弹层
const LAYER_ENEMY_BULLET: int = 1 << 3

## 地形层（TileMap 中的墙壁、障碍物）
const LAYER_TERRAIN: int = 1 << 4

## 边界墙层（战场边界）
const LAYER_BOUNDARY: int = 1 << 5

## 基地层（需保护的基地）
const LAYER_BASE: int = 1 << 6

## 道具层
const LAYER_POWERUP: int = 1 << 7
