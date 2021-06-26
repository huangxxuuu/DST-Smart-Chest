local zh = "zh" --Chinese(default)
local en = "en" --English
local variable = (locale == "en" or locale == "zhr") and en or zh

local info = {
	information = {
		mod_name = {
            [zh] = "成熟的箱子",
            [en] = "Smart Chest"
        },
		description_text = {
			[zh] = "你已经是个成熟的箱子了，要学会自己捡东西\n收集的物品由附近的（小木牌图案）决定\n（丢弃物品、战利品掉落、周期性掉落）的物品会自动进入附近的箱子（如果有对应小木牌的话）\n（打开箱子）会使这个箱子收集一次周围的物品\n箱子包括（木箱、龙蝇箱、冰箱、盐盒）\n收集物品种类可以设置一种或多种\n\n兼容Smart Minisign和Smart Minisign [Server Only]",
            [en] = "The chest can collect items automatically\nThe items collected are determined by the nearby (picture on a small wooden card)\n(drop items, spoils drop, periodic drop) items will automatically enter the nearby box (if there is a corresponding small wooden card)\n(open the box) will make the box collect the surrounding items once\nBoxes include (wooden chest, dragon fly chest, ice box, salt box)\nOne or more kinds items collections can be set"
		}
	},
	chesttype = {
		titlename = {
			[zh] = "箱子种类",
            [en] = "Chest type"
		},
		open = {
			[zh] = "开启自动收集",
			[en] = "open auto collect"
		},
		close = {
			[zh] = "关闭自动收集",
			[en] = "close auto collect"
		},
		treasurechest = {
			label = {
				[zh] = "木箱",
				[en] = "wooden chest"
			}
		},
		dragonflychest = {
			label = {
				[zh] = "龙蝇箱子",
				[en] = "dragon fly chest"
			}
		},
		icebox = {
			label = {
				[zh] = "冰箱",
				[en] = "ice box"
			}
		},
		saltbox = {
			label = {
				[zh] = "盐盒",
				[en] = "salt box"
			}
		},
	},
	iscollectone = {
		label = {
			[zh] = "收集种类限制",
			[en] = "Collection type restrictions"
		},
		onlyone = {
			[zh] = "每个箱子是否只收集一种",
			[en] = "is only collect one kind pre chest"
		},
		one = {
			[zh] = "只能一种",
			[en] = "only one kind"
		},
		many = {
			[zh] = "可以多种",
			[en] = "can many kinds"
		}
	},
	distance = {
		label = {
			[zh] = "距离设置 (4 == 一块地皮)",
			[en] = "distance setting (4 == A piece of land)"
		},
		hover = {
			[zh] = "4 == 一块地皮",
			[en] = "4 == A piece of land"
		},
		minisign = {
			[zh] = "检测小木牌半径",
			[en] = "Test the radius of small wooden sign"
		},
		collect0 = {
			[zh] = "收集物品半径 十位",
			[en] = "Radius of items collected (ten)"
		},
		collect1 = {
			[zh] = "收集物品半径 个位",
			[en] = "Radius of items collected (one)"
		},
		collecthover = {
			[zh] = "实际半径是 10*十位 + 个位",
			[en] = "The actual radius is 10 * tenValue + oneValue"
		}
	},
	collectTime = {
		label = {
			[zh] = "收集时机",
			[en] = "Timing of collection"
		},
		yes = {
			[zh] = "收集",
			[en] = "yes"
		},
		no = {
			[zh] = "不收集",
			[en] = "no"
		},
		drop = {
			[zh] = "丢弃时是否收集物品",
			[en] = "is collect when drop?"
		},
		open = {
			[zh] = "打开时是否收集物品",
			[en] = "is collect when open?"
		},
		take = {
			[zh] = "取出整组物品时是否收集物品",
			[en] = "is collect when take items?"
		},
		period = {
			label = {
				[zh] = "是否收集周期性掉落物品",
				[en] = "is collect periodic dropped items?"
			},
			hover = {
				[zh] = "例如格罗姆掉落的粘液",
				[en] = "such as glommer fuel"
			}
		},
		loot = {
			label = {
				[zh] = "是否收集战利品",
				[en] = "is collect spoils?"
			},
			hover = {
				[zh] = "例如格罗姆死亡掉落的怪物肉、粘液、翅膀",
				[en] = "such as the monster meat, fule, wings dropped by glommer's death"
			}
		},
		ash = {
			label = {
				[zh] = "是否收集燃烧产生的灰",
				[en] = "is collect ash when item burnt?"
			},
		},
	}
}

name = "Smart Chest"
-- info.information.description_text[variable]
description = info.information.description_text[variable]
author = "little_xuuu"
version = "2.0.5"
forumthread = ""
api_version = 10
all_clients_require_mod = false
server_only_mod = true
dst_compatible = true
icon_atlas = "modicon.xml"
icon = "modicon.tex"
folder_name = folder_name or "workshop-"
description = "Mod文件夹：" .. folder_name .."\n" .. description

-- Refer to other mod designs 增加标题
local function ModOptions(title, hover)
    return {
        name = title,
        hover = hover,
        options = {{description = "", data = false}},
        default = false
    }
end

-- Add mod setting/增加MOD设置
local function AddConfig(name, label, hover, options, default)
    return {
        name = name,
        label = label,
        hover = hover or "",
        options = options,
        default = default
    }
end

configuration_options =
{
	ModOptions(info.chesttype.titlename[variable]),
	AddConfig("treasurechest", 
		info.chesttype.treasurechest.label[variable],
		nil, 
		{
			{description = info.chesttype.open[variable], data = 1},
			{description = info.chesttype.close[variable], data = 0},
		},
		1
	),
	AddConfig("dragonflychest", 
		info.chesttype.dragonflychest.label[variable],
		nil, 
		{
			{description = info.chesttype.open[variable], data = 1},
			{description = info.chesttype.close[variable], data = 0},
		},
		1
	),
	AddConfig("icebox", 
		info.chesttype.icebox.label[variable],
		nil, 
		{
			{description = info.chesttype.open[variable], data = 1},
			{description = info.chesttype.close[variable], data = 0},
		},
		1
	),
	AddConfig("saltbox", 
		info.chesttype.saltbox.label[variable],
		nil, 
		{
			{description = info.chesttype.open[variable], data = 1},
			{description = info.chesttype.close[variable], data = 0},
		},
		1
	),
	ModOptions(info.iscollectone.label[variable]),
	AddConfig("iscollectone", 
		info.iscollectone.onlyone[variable],
		nil, 
		{
			{description = info.iscollectone.one[variable], data = 1},
			{description = info.iscollectone.many[variable], data = 0},
		},
		1
	),
	ModOptions(info.distance.label[variable], info.distance.hover[variable]),
	AddConfig("minisign_dist", 
		info.distance.minisign[variable],
		nil, 
		{
			{description = "0.1", data = 0.1},
			{description = "0.5", data = 0.5},
			{description = "1", data = 1},
			{description = "1.5", data = 1.5},
			{description = "2", data = 2},
			{description = "2.5", data = 2.5},
			{description = "3", data = 3},
		},
		1.5
	),
	AddConfig("collect_items_dist0", 
		info.distance.collect0[variable],
		info.distance.collecthover[variable],
		{
			{description = "0", data = 0},
			{description = "1", data = 1},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
			{description = "6", data = 6},
		},
		1
	),
	AddConfig("collect_items_dist1", 
		info.distance.collect1[variable],
		info.distance.collecthover[variable],
		{
			{description = "0", data = 0},
			{description = "1", data = 1},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
			{description = "6", data = 6},
			{description = "7", data = 7},
			{description = "8", data = 8},
			{description = "9", data = 9},
		},
		6
	),
	ModOptions(info.collectTime.label[variable]),
	AddConfig("is_collect_drop", 
		info.collectTime.drop[variable],
		nil,
		{
			{description = info.collectTime.yes[variable], data = 1},
			{description = info.collectTime.no[variable], data = 0},
		},
		1
	),
	AddConfig("is_collect_open", 
		info.collectTime.open[variable],
		nil,
		{
			{description = info.collectTime.yes[variable], data = 1},
			{description = info.collectTime.no[variable], data = 0},
		},
		1
	),
	AddConfig("is_collect_take", 
		info.collectTime.take[variable],
		nil,
		{
			{description = info.collectTime.yes[variable], data = 1},
			{description = info.collectTime.no[variable], data = 0},
		},
		1
	),
	AddConfig("is_collect_periodicspawner", 
		info.collectTime.period.label[variable],
		info.collectTime.period.hover[variable],
		{
			{description = info.collectTime.yes[variable], data = 1},
			{description = info.collectTime.no[variable], data = 0},
		},
		1
	),
	AddConfig("is_collect_lootdropper", 
		info.collectTime.loot.label[variable],
		info.collectTime.loot.hover[variable],
		{
			{description = info.collectTime.yes[variable], data = 1},
			{description = info.collectTime.no[variable], data = 0},
		},
		1
	),
	--[[AddConfig("is_collect_ash", 
		info.collectTime.ash.label[variable],
		nil,
		{
			{description = info.collectTime.yes[variable], data = 1},
			{description = info.collectTime.no[variable], data = 0},
		},
		1
	),]]
}

--[[
if isLocal then
	table.insert(configuration_options, 1, ModOptions("本地mod"))
end]]--