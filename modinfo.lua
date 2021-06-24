name = "成熟的箱子"
description = "你已经是个成熟的箱子了，要学会自己捡东西\n现在不需要打开箱子，只要在箱子附近把物品丢弃就可自动收进去\n第一次做mod，有bug反馈的话我会尽快修复。\n可以选择是否收集战利品和周期性掉落物品\nUse for treasure chest and dragonfly chest.\nYou're a mature chest. You need to learn to pick up things by yourself.\nNow you don't need to open the chest.You just need to abandon  the items near the chest to automatically collect them.\nYou can choose whether to collect loot and periodic dropped items"
author = "little_xuuu"
version = "1.9.10"
forumthread = ""
api_version = 10
all_clients_require_mod = false
server_only_mod = true
dst_compatible = true
icon_atlas = "modicon.xml"
icon = "modicon.tex"
folder_name = folder_name or "workshop-"
if not folder_name:find("workshop-") then
  name = " "..name.." - Local"
end

configuration_options =
{
	{
        name = "minisign_dist",
        label = "检测小木牌半径",
		hover = "test the radius of mini worden card",
        options = {
			{description = "0.1", data = 0.1},
			{description = "0.5", data = 0.5},
			{description = "1", data = 1},
			{description = "1.5", data = 1.5},
			{description = "2", data = 2},
			{description = "2.5", data = 2.5},
			{description = "3", data = 3},
		},
		default = 1.5,
    },
	{
        name = "collect_items_dist",
        label = "收集物品半径\nthe radius of collection items",
		hover = "范围过大可能导致卡顿\nToo large a range maybe lead to carton\n4==一块地皮\n4==A piece of land",
        options = {
			{description = "4", data = 4},
			{description = "8", data = 8},
			{description = "12", data = 12},
			{description = "16", data = 16},
		},
		default = 8,
    },
	{
        name = "is_collect_open_close",
        label = "打开关闭时是否收集物品\nis collect when open/close?",
        options = {
			{description = "yes", data = 1},
			{description = "no", data = 0},
		},
		default = 1,
    },
	{
        name = "is_collect_take",
        label = "取出整组物品时是否收集物品\nis collect when take items?",
        options = {
			{description = "yes", data = 1},
			{description = "no", data = 0},
		},
		default = 0,
    },
	{
        name = "is_collect_periodicspawner",
        label = "是否收集周期性掉落物品\ncollect periodic dropped items",
		hover = "例如格罗姆掉落的粘液\nsuch as glommer fuel",
        options = {
			{description = "yes", data = 1},
			{description = "no", data = 0},
		},
		default = 1,
    },
	{
        name = "is_collect_lootdropper",
        label = "是否收集战利品\ncollect spoils ",
		hover = "例如格罗姆死亡掉落的怪物肉、粘液、翅膀\nsuch as the monster meat, fule, wings dropped by glommer's death",
        options = {
			{description = "yes", data = 1},
			{description = "no", data = 0},
		},
		default = 1,
    },
	{
        name = "is_show_anim",
        label = "是否显示收集动画\nis show the collect animation  ",
        options = {
			{description = "yes", data = 1},
			{description = "no", data = 0},
		},
		default = 1,
    },
}