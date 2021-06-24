-- 让container自动收集附近物品的component。
-- 功能1：设置要收集的物品。
-- 			通过打开container来设置
-- 			设置的内容来自附近的小木牌（需要给minisign加一个属性itemname，当写的时候赋值）
--			根据设置选项中的内容来决定是只收集一种还是好多种。
-- 功能2：收集物品
--			以下几种情况时触发收集物品功能
--			1. 玩家丢弃（pick up）物品时
--			2. 生物死亡掉落物品时
local LXautocollectitems = Class(function(self, inst)
	self.inst = inst
	self.iscollect = false -- 判断是否开始收集
	self.items = {}
	self.setitemsfn = nil
end,
nil,
nil)

local _G = GLOBAL
local minisigndist = GetModConfigData("minisign_dist")
local iscollectone = GetModConfigData("iscollectone")

--[[
local function getMinisign(inst){
	local x, y, z = inst.Transform:GetWorldPosition()
	local ents = _G.TheSim:FindEntities(x, y, z, minisigndist, { "sign", "drawable" }, { "INLIMBO"}) --包括所有木牌
	--筛选画好的
	for i, v in ipairs(ents) do
		if v and v.prefab == "minisign" and v.components and v.components.drawable and v.components.drawable.candraw == false then
			return v
		end
	end
	return nil
}
]]--

-- 功能1：设置要收集的物品。
function LXautocollectitems:SetItems()
	if self.inst and self.inst.container then 
		self.items = {} -- 清空当前的设置
		-- 获取周围的小木牌
		local x, y, z = self.inst.Transform:GetWorldPosition()
		local ents = _G.TheSim:FindEntities(x, y, z, minisigndist, { "sign", "drawable" }, { "INLIMBO"}) --包括所有木牌
		-- 筛选画好的,并填入items
		for i, v in ipairs(ents) do
			if v and v.prefab == "minisign" and v.components and v.components.drawable and v.components.drawable.candraw == false then
				table.insert(self.items, v.itemname)
				if iscollectone == 1 then 
					break
				end
			end
		end
	end
end

-- 功能2：收集物品





return LXautocollectitems