local _G = GLOBAL

Assets = {
}
PrefabFiles = {

}                   

local t0 = GetModConfigData("collect_items_dist0")
local t1 = GetModConfigData("collect_items_dist1")
local collectdist = 10*t0 + t1
local minisigndist = GetModConfigData("minisign_dist")
local iscollectone = GetModConfigData("iscollectone")
local istreasurechest = GetModConfigData("treasurechest")
local isdragonflychest = GetModConfigData("dragonflychest")
local isicebox = GetModConfigData("icebox")
local issaltbox = GetModConfigData("saltbox")
local is_collect_drop = GetModConfigData("is_collect_drop")
local is_collect_open = GetModConfigData("is_collect_open")
local is_collect_take = GetModConfigData("is_collect_take")
local is_collect_periodicspawner = GetModConfigData("is_collect_periodicspawner")
local is_collect_lootdropper = GetModConfigData("is_collect_lootdropper")

local TheNet = _G.TheNet
local IsServer = TheNet:GetIsServer() or TheNet:IsDedicated()


if IsServer then

	-- 显示信息
	--[[
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
			if target.prefab == "treasurechest" or target.prefab == "dragonflychest" or target.prefab == "icebox" or target.prefab == "saltbox" then
				print("[showInfo] " .. target.prefab .. ".items : start")
				if target and target.components.lxautocollectitems then
					for key, value in pairs(target.components.lxautocollectitems.items) do
						print(value)
					end
				end
				print("[showInfo] " .. target.prefab .. ".items : end")
			end
		end

	end
	_G.TheInput:AddKeyUpHandler(118, showInfo)]]--

	-- 功能1. 设置要收集的物品
	-- 箱子主动收集附近的物品
	local function collectChest2Item(chest)
		if chest and chest.components and chest.components.lxautocollectitems then
			local x, y, z = chest.Transform:GetWorldPosition()
			-- 要求物品一定是 inventoryitem。一定不能是
			local items = _G.TheSim:FindEntities(x, y, z, collectdist, { "_inventoryitem" }, { "INLIMBO", "NOCLICK", "catchable", "fire" })
			for k, v in pairs(items) do
				local name = v.drawnameoverride or v:GetBasicDisplayName()
				chest.components.lxautocollectitems:onCollectItems(v, name)
			end
		end
	end

	-- 改变箱子的部分
	local function changeChest(inst) -- ACI == LXautocollectitems
		-- 给箱子添加 LXautocollectitems 这个component,并且箱子打开时设置要收集的items
		if inst and inst.components and inst.components.container then
			-- 添加 lxautocollectitems 组件，和tag
			inst:AddComponent("lxautocollectitems")
			inst:AddTag("lxautocollectitems") -- 给对应箱子添加Tag
			inst.components.lxautocollectitems.minisigndist = minisigndist
			inst.components.lxautocollectitems.iscollectone = iscollectone

			-- 箱子打开时收集物品
			if is_collect_open == 1 then
				local old_open = inst.components.container.onopenfn
				inst.components.container.onopenfn = function(inst2)
					--inst2.components.lxautocollectitems:SetItems()
					old_open(inst2)
					collectChest2Item(inst2)
				end
			end

			-- 箱子内物品被整组取出时收集物品
			if is_collect_take == 1 then
				local old_take = inst.components.container.TakeActiveItemFromAllOfSlot
				function inst.components.container:TakeActiveItemFromAllOfSlot(slot, opener)
					old_take(self,slot, opener)
					collectChest2Item(self.inst)
				end
				local old_move = inst.components.container.MoveItemFromAllOfSlot
				function inst.components.container:MoveItemFromAllOfSlot(slot,container, opener)
					old_move(self,slot,container, opener)
					collectChest2Item(self.inst)
				end
			end

			-- 箱子加载时设置收集物
			local old_onload = inst.OnLoad
			inst.OnLoad = function(inst2, data)
				if old_onload ~= nil then
					old_onload(inst2, data)
				end
				if inst2 and inst2.components and inst2.components.lxautocollectitems then
					inst2.components.lxautocollectitems:SetItems()
				end
			end

			-- 箱子建造时设置收集物
			local function onChestBuild(inst)
				inst.components.lxautocollectitems:SetItems()
			end
			inst:ListenForEvent("onbuilt", onChestBuild)

			-- 解决箱子敲毁时 掉落物消失的问题
			if inst.components.workable then
				local old_onfinish = inst.components.workable.onfinish
				inst.components.workable:SetOnFinishCallback(function(inst2, worker)
					inst2.components.lxautocollectitems.items = {}
					old_onfinish(inst2, worker)
				end)
			end
		end
	end
	if istreasurechest == 1 then
		AddPrefabPostInit("treasurechest", changeChest)
	end
	if isicebox == 1 then
		AddPrefabPostInit("icebox", changeChest)
	end
	if issaltbox == 1 then
		AddPrefabPostInit("saltbox", changeChest)
	end
	if isdragonflychest == 1 then
		AddPrefabPostInit("dragonflychest", changeChest)
	end

	-- 改变小木牌的部分（小木牌画，挖，加载，种的时候，设置箱子）
	local function changeMinisign(inst)
		if inst.prefab == "minisign" then
			local old_draw = inst.components.drawable.ondrawnfn
			inst.components.drawable:SetOnDrawnFn(function(inst2, image, src, atlas, bgimage, bgatlas)
				old_draw(inst2, image, src, atlas, bgimage, bgatlas)
				local x, y, z = inst2.Transform:GetWorldPosition()
				local ents = _G.TheSim:FindEntities(x, y, z, collectdist, {"lxautocollectitems"})
				for k, v in pairs(ents) do
					v.components.lxautocollectitems:SetItems()
				end
			end)
			local old_onfinish = inst.components.workable.onfinish
			inst.components.workable:SetOnFinishCallback(function(inst2)
				old_onfinish(inst2)
				local x, y, z = inst2.Transform:GetWorldPosition()
				local ents = _G.TheSim:FindEntities(x, y, z, collectdist, {"lxautocollectitems"})
				for k, v in pairs(ents) do
					v.components.lxautocollectitems:SetItems()
				end
			end)
			local old_onload = inst.OnLoad
			inst.OnLoad = function(inst2, data)
				--print("[master chest] onload")
				old_onload(inst2, data)
				local x, y, z = inst2.Transform:GetWorldPosition()
				local ents = _G.TheSim:FindEntities(x, y, z, collectdist, {"lxautocollectitems"})
				for k, v in pairs(ents) do
					v.components.lxautocollectitems:SetItems()
				end
			end
		end
		if inst.prefab == "minisign_drawn" then
			local old_ondeply = inst.components.deployable.ondeploy
			inst.components.deployable.ondeploy = function(inst2,pt)
				local x, y, z = pt:Get()
				old_ondeply(inst,pt)
				local ents = _G.TheSim:FindEntities(x, y, z, collectdist, {"lxautocollectitems"})
				for k, v in pairs(ents) do
					v.components.lxautocollectitems:SetItems()
				end
			end
		end
	end
	AddPrefabPostInit("minisign", changeMinisign) -- 画 挖 世界加载
	AddPrefabPostInit("minisign_drawn", changeMinisign) -- 种


	-- 功能2. 收集物品
	local function collectItem2Chest(dropped)
		if dropped ~= nil then
			-- 搜索周围的箱子
			--print("[collectItem2Chest] prefab = " .. dropped.prefab)
			--print("[collect] search Tag lxautocollectitems")
			local x, y, z = dropped.Transform:GetWorldPosition()
			local ents = _G.TheSim:FindEntities(x, y, z, collectdist, {"lxautocollectitems"}, {"burnt"})
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
		end
	end

	-- 玩家触发drop动作时，收集。(inventory:DropItem)
	if is_collect_drop == 1 then
		local function onDropCollect(inst)
			local old_DropItem = inst.DropItem
			function inst:DropItem(item, wholestack, randomdir, pos)
				--print("[DropItem] enter")
				local dropped = old_DropItem(self, item, wholestack, randomdir, pos)
				collectItem2Chest(dropped)
				--print("[DropItem] exit")
				return dropped
			end
		end
		AddComponentPostInit("inventory",onDropCollect)
	end

	-- 战利品掉落时，收集。
	if is_collect_lootdropper == 1 then
		local function onLootdropCollect(inst)
			local old_SpawnLootPrefab = inst.SpawnLootPrefab
			function inst:SpawnLootPrefab(lootprefab, pt, linked_skinname, skin_id, userid)
				--print("[SpawnLootPrefab] enter")
				local dropped = old_SpawnLootPrefab(self, lootprefab, pt, linked_skinname, skin_id, userid)
				collectItem2Chest(dropped)
				--print("[SpawnLootPrefab] exit")
				return dropped
			end
		end
		AddComponentPostInit("lootdropper",onLootdropCollect)

		--[[燃烧的灰 收集
		local function onBurntCollect(inst)
			print("[onBurntCollect]")
			local old_onburnt = inst.onburnt
			inst.onburnt = function(inst2)
				if inst2 then
					local x, y, z = inst2.Transform:GetWorldPosition()
					print("[onburnt] x y z = " .. x .. " ".. y .. " " .. z)
					old_onburnt(inst2)
					local ents = _G.TheSim:FindEntities(x, y, z, collectdist, {"lxautocollectitems"}, {"burnt"})
					for k, v in pairs(ents) do
						collectChest2Item(v)
					end
				else
					old_onburnt(inst2)
				end
			end
		end
		AddComponentPostInit("burnable",onBurntCollect)]]
	end

	-- 周期性掉落物品，收集。
	if is_collect_periodicspawner == 1 then
		local function onPerioddropCOllect(inst)
			local old_onspawn = inst.onspawn
			inst.onspawn = function(inst1, inst2)
				--[[if inst2 ~= nil then
					print("[onspawn old] prefab = " .. inst2.prefab)
				else
					print("[onspawn old]")
				end]]--
				if old_onspawn ~= nil then
					old_onspawn(inst1, inst2)
				end
				collectItem2Chest(inst2)
			end
			function inst:SetOnSpawnFn(fn)
				self.onspawn = function(inst1, inst2)
					--[[if inst2 ~= nil then
						print("[onspawn new] prefab = " .. inst2.prefab)
					else
						print("[onspawn new]")
					end]]--
					fn(inst1, inst2)
					collectItem2Chest(inst2)
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
					collectItem2Chest(item)
				end
				return item
			end
		end
		AddPrefabPostInit("bearger",onbeargerCollect)
	end

	-- 功能3. 打补丁

end
