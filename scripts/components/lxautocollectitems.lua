local LXautocollectitems = Class(function(self, inst)
	self.inst = inst
	self.iscollect = false -- 判断是否开始收集
	self.items = {}
end,
nil,
nil)

local modname = KnownModIndex:GetModActualName(" 成熟的箱子2 - Local")
local minisigndist = GetModConfigData("minisign_dist", modname)
local iscollectone = GetModConfigData("iscollectone", modname)

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
	print("[LXautocollectitems]SetItems enter")
	if self.inst and self.inst.components and self.inst.components.container then 
		self.items = {} -- 清空当前的设置
		-- 获取周围的小木牌
		local x, y, z = self.inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, minisigndist, { "sign" }, { "INLIMBO"}) --包括所有木牌
		print("#minisign = " .. #ents)
		-- 筛选画好的,并填入items
		for i, v in ipairs(ents) do
			if v and v.prefab == "minisign" and v.components and v.components.drawable and v.components.drawable:GetImage() ~= nil then
				table.insert(self.items, v._imagename:value())
				if iscollectone == 1 then 
					break
				end
			end
		end
		for key, value in pairs(self.items) do
			print("" .. key .. " " .. value)
		end
	end
	print("[LXautocollectitems]SetItems exit")
end

-- 功能2：收集物品


-- 保存和加载
function LXautocollectitems:OnSave()
	local data = {
		iscollect = self.iscollect,
		items = self.items
	}
	return data
end

function LXautocollectitems:OnLoad(data)
	self.iscollect = data.iscollect
	self.items = data.items
end


return LXautocollectitems