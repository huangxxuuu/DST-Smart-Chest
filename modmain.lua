local _G = GLOBAL

Assets = {
}
PrefabFiles = {

}                   


local minisigndist = GetModConfigData("minisign_dist")
local collectdist = GetModConfigData("collect_items_dist")
local isshowanim = GetModConfigData("is_show_anim")
local TheNet = _G.TheNet
local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()

-- 显示信息
local function showInfo()
	local target = _G.TheInput:GetWorldEntityUnderMouse()
	if target ~= nil then
		if target.prefab == "minisign" or target.prefab == "minisign_drawn" then
			if target._imagename then
				print("[showInfo] minisign._imagename:" .. target._imagename:value())
			else
				print("[showInfo] minisign.itemname == nil")
			end
		end
		if target.prefab == "treasurechest" then
			print("[showInfo] treasurechest.items : start")
			if target and target.components.lxautocollectitems then
				for key, value in pairs(target.components.lxautocollectitems.items) do
					print(value)
				end
			end
			print("[showInfo] treasurechest.items : end")
		end
	end

end
_G.TheInput:AddKeyUpHandler(118, showInfo)

-- 使用minisign的属性_imagename（所以这里就不需要修改了）
--[[
local function MinisignAddItemname(inst)
	inst.itemname = nil
	if inst and inst.components and inst.components.drawable then
		--print("change ondrawnfn")
		local old_draw = inst.components.drawable.ondrawnfn
		inst.components.drawable:SetOnDrawnFn(function(inst2, image, src, atlas, bgimage, bgatlas)
			--print("[master chest] ondraw")
			if src ~= nil then
				--获取src的prefab名称
				inst2.itemname = src.prefab
			end
			old_draw(inst2, image, src, atlas, bgimage, bgatlas)
		end)
	end

	--修改dig_up
	if inst and inst.components and inst.components.workable then
		--print("change dig_up")
		--local old_onfinish = inst.components.workable.onfinish
		inst.components.workable:SetOnFinishCallback(function(inst2)
			local image = inst2.components.drawable:GetImage()
			if image ~= nil then
				local item = inst2.components.lootdropper:SpawnLootPrefab("minisign_drawn", nil, inst2.linked_skinname_drawn, inst2.skin_id )
				item.components.drawable:OnDrawn(image, nil, inst2.components.drawable:GetAtlas(), inst2.components.drawable:GetBGImage(), inst2.components.drawable:GetBGAtlas())
				item._imagename:set(inst2._imagename:value())
				if inst2.itemname then
					--print("[dig_ip] inst.itemname:" .. inst2.itemname)
					item.itemname = inst2.itemname
				end
			else
				inst2.components.lootdropper:SpawnLootPrefab("minisign_item", nil, inst2.linked_skinname, inst2.skin_id )
			end
			inst2:Remove()
		end)
	end

	--修改ondeploy
	if inst and inst.components and inst.components.deployable then
		--print("change ondeploy")
		inst.components.deployable.ondeploy = function(inst2, pt)
			local ent = _G.SpawnPrefab("minisign", inst2.linked_skinname, inst2.skin_id )

			if inst2.components.stackable ~= nil then
				inst2.components.stackable:Get():Remove()
			else
				ent.components.drawable:OnDrawn(inst2.components.drawable:GetImage(), nil, inst2.components.drawable:GetAtlas(), inst2.components.drawable:GetBGImage(), inst2.components.drawable:GetBGAtlas())
				ent._imagename:set(inst2._imagename:value())
				if inst2.itemname then
					--print("[ondeply] inst.itemname:" .. inst2.itemname)
					ent.itemname = inst2.itemname
				end
				inst2:Remove()
			end

			ent.Transform:SetPosition(pt:Get())
			ent.SoundEmitter:PlaySound("dontstarve/common/sign_craft")
		end
	end

	--保存和加载
	if inst.OnSave ~= nil then
		local old_OnSave = inst.OnSave
		inst.OnSave = function(inst2, data)
			data.itemname = inst2.itemname
			old_OnSave(inst2, data)
		end
	end
	if inst.OnLoad ~= nil then
		local old_OnLoad = inst.OnLoad
		--print("old_OnLoad = " .. old_OnLoad)
		inst.OnLoad = function(inst2, data)
			if data.itemname then
				inst2.itemname = data.itemname
			end
			old_OnLoad(inst2, data)
		end
	end

end
AddPrefabPostInit("minisign", MinisignAddItemname)
AddPrefabPostInit("minisign_item", MinisignAddItemname)
AddPrefabPostInit("minisign_drawn", MinisignAddItemname)
]]--

-- 功能1. 设置要收集的物品
-- 给箱子添加 LXautocollectitems 这个component,并且箱子打开时设置要收集的items
local function ContainerAddACI(inst) -- ACI == LXautocollectitems
	if inst and inst.components and inst.components.container then
		inst:AddComponent("lxautocollectitems")
		inst:AddTag("lxautocollectitems") -- 给对应箱子添加Tag
		local old_open = inst.components.container.onopenfn
		inst.components.container.onopenfn = function(inst2)
			inst2.components.lxautocollectitems:SetItems()
			old_open(inst2)
		end
	end
end
AddPrefabPostInit("treasurechest", ContainerAddACI)


-- 功能2. 收集物品
local function collect(dropped)
	if dropped ~= nil then
		local snumb = nil
		if dropped and dropped.components and dropped.components.stackable then
			snumb = dropped.components.stackable.stacksize
		end
		-- 搜索周围的箱子
		print("[collect] search Tag lxautocollectitems")
		local x, y, z = dropped.Transform:GetWorldPosition()
		local ents = _G.TheSim:FindEntities(x, y, z, collectdist, {"lxautocollectitems"})
		local name = dropped.drawnameoverride or dropped:GetBasicDisplayName()
		for k, v in pairs(ents) do
			if dropped ~= nil then
				if v and v.components and v.components.lxautocollectitems then
					dropped = v.components.lxautocollectitems:onCollectItems(dropped, name)
				end
			else
				break
			end
		end
		if dropped == nil then
			local collectanim = _G.SpawnPrefab("sand_puff") --消失的动画
			collectanim.Transform:SetPosition(x, y, z)
			collectanim.Transform:SetScale(1,1,1)
		else
			if dropped and dropped.components and dropped.components.stackable and dropped.components.stackable.stacksize < snumb then
				local collectanim = _G.SpawnPrefab("sand_puff") --消失的动画
				collectanim.Transform:SetPosition(x, y, z)
				collectanim.Transform:SetScale(1,1,1)
			end
		end
	end
end

-- 玩家触发drop动作时，收集。(inventory:DropItem)
local function onDropCollect(inst)
	local old_DropItem = inst.DropItem
	function inst:DropItem(item, wholestack, randomdir, pos)
		print("[DropItem] enter")
		local dropped = old_DropItem(self, item, wholestack, randomdir, pos)
		collect(dropped)
		print("[DropItem] exit")
		return dropped
	end
end
AddComponentPostInit("inventory",onDropCollect)

-- 战利品掉落时，收集。
local function onLootdropCollect(inst)
	local old_SpawnLootPrefab = inst.SpawnLootPrefab
	function inst:SpawnLootPrefab(lootprefab, pt, linked_skinname, skin_id, userid)
		print("[SpawnLootPrefab] enter")
		local dropped = old_SpawnLootPrefab(self, lootprefab, pt, linked_skinname, skin_id, userid)
		collect(dropped)
		print("[SpawnLootPrefab] exit")
		return dropped
	end
end
--LootDropper:SpawnLootPrefab
AddComponentPostInit("lootdropper",onLootdropCollect)

-- 周期性掉落物品，收集。
local function onPerioddropCOllect(inst)
	--local old_setonspawnfn = inst.SetOnSpawnFn
	function inst:SetOnSpawnFn(fn)
		inst.onspawn = function(inst1, inst2)
			fn(inst1, inst2)
			collect(inst2)
		end
	end
end
AddComponentPostInit("periodicspawner",onPerioddropCOllect)

-- 熊的毛簇，收集。
local function onbeargerCollect(inst)
	local old_DoSingleShed = inst.components.shedder.DoSingleShed
	function inst.components.shedder:DoSingleShed()
		local item = old_DoSingleShed(self)
		if item ~= nil then
			collect(item)
		end
		return item
	end
end
AddPrefabPostInit("bearger",onbeargerCollect)