extends RefCounted
class_name UIEvent

## 游戏世界地图创建
const CREATE_MAP_SUCCESS := "create_map_success"  # 世界地图创建成功
const CREATE_NEW_SAVE := "create_new_save"  # 创建新档
const UPDATE_PLAYER_INFO := "update_player_info"  # 更新玩家数据
## game form场景下所有按钮事件
const BACKPACK_CHANGED := "backpack_changed"  # 背包物品改变
const INVENTORY_CHANGED := "inventory_changed"  # 仓库物品改变
const QUICK_TOOLS_CHANGED := "quick_tools_changed"  # 快捷栏物品改变
const WORLD_MAP_CHANGED := "world_map_changed"  # 世界地图物品改变
const LANDSCAPE_CHANGED := "landscape_changed"  # 布局物品改变
const ITEMS_CHANGED := "items_changed"  # 多格容器物品发生改变
const INVENTORY_FULL := "inventory_full"  # 物品背包容器满了或者自动摆放不下了
const SUB_ITEM := "sub_item"  # 扣除物品
#const ADD_ITEM := "add_item"  # 增加物品
#const MOVE_ITEM := "move_item"  # 物品移动
#const DELETE_ITEM := "delete_item"  # 物品删除
