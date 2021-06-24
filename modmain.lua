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

if IsServer then
	local function isOK(inst) -- 判断物品能否被箱子收集
		if inst and inst:IsValid() and inst.components and inst.components.inventoryitem ~= nil then
			if inst.components.inventoryitem.cangoincontainer == true 
			and (inst.components.inventoryitem.canbepickedup == true or inst.components.inventoryitem.canbepickedupalive == true ) 
			and not inst:HasTag("INLIMBO") 
			and not inst:HasTag("NOCLICK") 
			and not inst:HasTag("catchable") 
			and not inst:HasTag("fire") then
				if inst.prefab == "bullkelp_beachedroot" then --原本生成在地面的公牛海带不进行收集
					return false
				end
				return true
			end
		end
		return false
	end

	local function move2chest(v,chest) --将物品v放入箱子，返回剩余物品
		for slot = 1, chest.components.container.numslots,1 do
			local item = chest.components.container:GetItemInSlot(slot)
			if item == nil then --这个格子没有东西，把物品直接放进去。对于可堆叠与不可堆叠的都可以这样处理
				if chest and chest.components and chest.components.container and chest.components.container:CanTakeItemInSlot(v, slot) then
					if isshowanim == 1 then
						local collectanim = _G.SpawnPrefab("sand_puff") --消失的动画
						collectanim.Transform:SetPosition(v.Transform:GetWorldPosition())
						collectanim.Transform:SetScale(1,1,1)
					end
					chest.components.container.ignoresound = true
					chest.components.container:GiveItem(v, slot)
					chest.components.container.ignoresound = false
					if v and v.flies ~= nil then --移除苍蝇
						v.flies:Remove()
						v.flies = nil
					end
					return nil
				end
			else --这个格子有东西，判断物品、皮肤是否一致，是否可堆叠。不可堆叠不能放入，可堆叠可放入（可能会剩下）
				if chest and chest.components and chest.components.container and chest.components.container:CanTakeItemInSlot(v, slot) and v and item.prefab == v.prefab and item.skinname == v.skinname then
					if v.components and v.components.stackable ~= nil and item.components and item.components.stackable and not item.components.stackable:IsFull() then
						if isshowanim == 1 and v.components.stackable.stacksize <= (item.components.stackable.maxsize - item.components.stackable.stacksize) then --物品可以被全部放入时显示动画
							local collectanim = _G.SpawnPrefab("sand_puff") --消失的动画
							collectanim.Transform:SetPosition(v.Transform:GetWorldPosition())
							collectanim.Transform:SetScale(1,1,1)
						end
						local leftovers = item.components.stackable:Put(v)
						if leftovers == nil then 
							if v and v.flies ~= nil then --移除苍蝇
								v.flies:Remove()
								v.flies = nil
							end
							return nil
						end
					end
				end
			end
		end
		return v --返回剩余物品
	end
	
	--=====================================================================================
	-- %% 设置箱子相关-------------------------- 

	local function getNearestSign(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = _G.TheSim:FindEntities(x, y, z, minisigndist, { "sign" }, { "INLIMBO"}) --包括所有木牌
		--筛选画好的
		for i, v in ipairs(ents) do
			if v and v.prefab == "minisign" and v.components and v.components.drawable and v.components.drawable.candraw == false then
				return v
			end
		end
		return nil
	end

	--设置收集的物品
	local function setgoods(inst)
		if inst then
			local ent = getNearestSign(inst)
			--print("[master chest]")
			if ent == nil then
				inst.collectitems =  ""
			else
				inst.collectitems = ent._imagename:value()
			end
		end
		--print("[master chest] setgoods" .. inst.collectitems)
	end

	--箱子进行物品收集,收集半径
	local function collectgoods(inst) --箱子
		if inst then
			if inst.components and inst.components.container == nil then
				return
			end
			if inst.collectitems == nil or inst.collectitems == "" then
				return
			end
			local x, y, z = inst.Transform:GetWorldPosition()
			local ents = _G.TheSim:FindEntities(x, y, z, collectdist, { "_inventoryitem" }, { "INLIMBO", "NOCLICK", "catchable", "fire" }) --
			for i, v in ipairs(ents) do
				if isOK(v) and (v.drawnameoverride or v:GetBasicDisplayName()) == inst.collectitems then
					local leftovers = move2chest(v, inst)
					--因为只有一个箱子，所以剩下了也不需要处理，继续放地上就行
					--if leftovers == nil then
					--	break
					--end
				end
			end
		end
	end
	
	--兼容智能小木牌mod服务器端做的修改
	local function smart_minisign(inst)
		local old_onclose = inst.OnClose
		function inst:OnClose()
			old_onclose(self)
			if self.inst and self.inst.components and (self.inst.prefab == "treasurechest" or self.inst.prefab == "dragonflychest") then --代码直接复制的智能小木牌mod服务器端smart_minisign中的一段
				--print("[master chest]smart_minisign")
				if self.sign ~= nil and  self.inst.components.container ~= nil then
					local container = self.inst.components.container
					for i = 1, container:GetNumSlots() do
						local item = container:GetItemInSlot(i)
						if item ~= nil and item.replica.inventoryitem ~= nil  then
							local name = item ~= nil and (item.drawnameoverride or item:GetBasicDisplayName()) or ""
							--for bundle
							if item.components.unwrappable ~= nil and item.components.unwrappable.itemdata then --因为不会获取其他mod的配置信息，所以这里默认拆开捆绑包分析
								for i, v in ipairs(item.components.unwrappable.itemdata) do
									if  v  then
										local copy = _G.SpawnPrefab(v.prefab)
										if copy then 
											if copy.replica.inventoryitem ~= nil  then
												name = copy ~= nil and (copy.drawnameoverride or copy:GetBasicDisplayName()) or ""
											end
											copy:Remove()
											break
										end
									end
								end
							end
							self.sign._imagename:set(name)
							self.inst.collectitems = name
							break
						end
						if i == container:GetNumSlots() and item == nil then
							local name = ""
							self.sign._imagename:set(name)
							self.inst.collectitems = name
						end
					end
				end
				self.inst:SetGoods(self.inst)
				self.inst:CollectGoods(self.inst)
			end
		end
	end
	AddComponentPostInit("smart_minisign",smart_minisign)
	
	--使箱子在世界加载时就设置收集的物品
	local function addFun(inst)
		inst.SetGoods = setgoods
		inst.CollectGoods = collectgoods
		inst.collectitems =  ""
		local old_onload = inst.OnLoad
		inst.OnLoad = function(inst2, data)
			if old_onload ~= nil then
				old_onload(inst2, data)
			end
			--print("[master chest] onload")
			if data ~= nil and data.burnt ~= true then
				--[[if data.collectitems ~= nil then
					inst.collectitems = data.collectitems
					--print(inst.collectitems)
					--print("[master chest] onload1")
				else]]--
					inst:SetGoods(inst2)
					--print("[master chest] onload2")
				--end
			end
		end
		local function ttt(inst2)
			--print("[master chest] onbuilt")
			inst2:SetGoods(inst2)
			inst2:CollectGoods(inst2)
		end
		inst:ListenForEvent("onbuilt", ttt)
	end
	AddPrefabPostInit("treasurechest", addFun)
	AddPrefabPostInit("dragonflychest", addFun)

	--解决箱子被敲毁或烧毁时物品消失的问题
	local function change_onhammered(inst)
		if inst and (inst.prefab == "treasurechest" or inst.prefab == "dragonflychest") then
			--print("[matser chest] onhammered")
			local old_onhammerde = inst.components.workable.onfinish
			local function finish(inst2, worker)
				inst2.collectitems = ""
				old_onhammerde(inst2,worker)
			end
			inst.components.workable.onfinish = finish
			if inst.prefab == "treasurechest" then
				local old_onburnt = inst.components.burnable.onburnt
				local function burnt(inst2)
					inst2.collectitems = ""
					old_onburnt(inst2)
				end
				inst.components.burnable.onburnt = burnt
			end
		end
	end
	AddPrefabPostInit("treasurechest", change_onhammered)
	AddPrefabPostInit("dragonflychest", change_onhammered)

	--箱子打开关闭时收集物品
	local is_collect_open_close = GetModConfigData("is_collect_open_close")
	local function change_open_close(inst)
		local old_open = inst.components.container.onopenfn
		inst.components.container.onopenfn = function(inst2)
			if not inst2:HasTag("burnt") then
				inst2:CollectGoods(inst2)
			end
			old_open(inst2)
		end
		local old_close = inst.components.container.onclosefn
		inst.components.container.onclosefn = function(inst2)
			old_close(inst2)
			if not inst2:HasTag("burnt") then
				inst2:CollectGoods(inst2)
			end
		end
	end
	if is_collect_open_close == 1 then
		AddPrefabPostInit("treasurechest", change_open_close)
		AddPrefabPostInit("dragonflychest", change_open_close)
	end

	--箱子内物品被整组取出时收集物品
	local is_collect_take = GetModConfigData("is_collect_take")
	local function change_take_move(inst)
		local old_take = inst.components.container.TakeActiveItemFromAllOfSlot
		function inst.components.container:TakeActiveItemFromAllOfSlot(slot)
			old_take(self,slot)
			--print("[master chest] take")
			self.inst:CollectGoods(self.inst)
		end
		local old_move = inst.components.container.MoveItemFromAllOfSlot
		function inst.components.container:MoveItemFromAllOfSlot(slot,container)
			old_move(self,slot,container)
			--print("[master chest] move")
			self.inst:CollectGoods(self.inst)
		end
	end
	if is_collect_take == 1 then
		AddPrefabPostInit("treasurechest", change_take_move)
		AddPrefabPostInit("dragonflychest", change_take_move)
	end


	-- %% 设置箱子相关 结束-------------------------- 
	--=====================================================================================


	--=====================================================================================
	-- %% 设置木牌相关--------------------------

	--找到附近的箱子，并设置物品，进行一次收集
	local function findchest(x,y,z)
		local ents = _G.TheSim:FindEntities(x, y, z, minisigndist, { "chest" }, { "INLIMBO"}) 
		for i, v in ipairs(ents) do
			--print(v)
			if v and v.prefab == "treasurechest" or v.prefab == "dragonflychest" then
				v:SetGoods(v)
				v:CollectGoods(v)
			end
		end
		--print("[matset chest] findchest end")
	end

	--将画好的小木牌插到地上
	local function changeMinisign(inst)
		local old_ondeply = inst.components.deployable.ondeploy
		inst.components.deployable.ondeploy = function(inst,pt)
			--print("[master chest] minisign ondeply")
			local x, y, z = pt:Get()
			--print(x,y,z)
			old_ondeply(inst,pt)
			findchest(x,y,z)
		end
	end
	AddPrefabPostInit("minisign_drawn", changeMinisign)

	--挖出画好的小木牌
	local function changeMinisign2(inst)
		local old_digup = inst.components.workable.onfinish
		inst.components.workable.onfinish = function(inst)
			--print("[master chest] digup")
			local x, y, z = inst.Transform:GetWorldPosition()
			--print(x,y,z)
			old_digup(inst)
			findchest(x,y,z)
		end
	end
	AddPrefabPostInit("minisign", changeMinisign2)

	--对小木牌进行画和世界加载操作时，更新周围箱子的收集物品
	local function changeMinisign3(inst)
		local old_draw = inst.components.drawable.ondrawnfn
		inst.components.drawable:SetOnDrawnFn(function(inst, image, src, atlas, bgimage, bgatlas)
			--print("[master chest] ondraw")
			local x, y, z = inst.Transform:GetWorldPosition()
			--print(x,y,z)
			old_draw(inst, image, src, atlas, bgimage, bgatlas)
			findchest(x,y,z)
		end)
		local old_onload = inst.OnLoad
		inst.OnLoad = function(inst, data)
			--print("[master chest] onload")
			old_onload(inst, data)
			local x, y, z = inst.Transform:GetWorldPosition()
			findchest(x,y,z)
		end
	end
	AddPrefabPostInit("minisign", changeMinisign3)
	-- %% 设置木牌相关 结束--------------------------
	--=====================================================================================


	--=====================================================================================
	-- %% 被收集物品相关------------------------------------

	--1.丢弃时收集

	--寻找周围可以收集它的箱子（不是箱子收集周围所有物品，减少计算量）
	local function findchest2(inst) --一个物品
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = _G.TheSim:FindEntities(x, y, z, collectdist, { "chest" }, { "INLIMBO"}) 
		for i, v in ipairs(ents) do
			if v and (v.prefab == "treasurechest" or v.prefab == "dragonflychest") and v.components and v.components.container ~= nil and isOK(inst) and v.collectitems == (inst.drawnameoverride or inst:GetBasicDisplayName()) then
				--依次判断箱子的每个格子是否可以放这个物品，直到物品被放完
				local leftovers = move2chest(inst, v)
				if leftovers == nil then --物品被放完则返回，否则寻找下一个箱子
					return
				end
			end
		end
	end

	--设置物品丢弃时，寻找周围可以收集它的箱子（不是箱子收集周围所有物品，减少计算量）
	local function onDrop(inst) --inst是组件
		local drop = inst.DropItem
		function inst:DropItem(item, wholestack, randomdir, pos)
			local dropped = drop(self, item, wholestack, randomdir, pos)
			if self.inst and self.inst:HasTag("player") and dropped ~= nil then
				findchest2(dropped) --拥有这个组件的预制物 prefab
			end
			return dropped
		end
	end
	AddComponentPostInit("inventory",onDrop)

	--2.周期性掉落物收集

	--收集周期性掉落物品
	local is_collect_periodicspawner = GetModConfigData("is_collect_periodicspawner")
	if is_collect_periodicspawner == 1 then
		local function onspawn2(inst1, inst2) --inst1 原生物 inst2 掉落物
			--print("[master chest] onspawn2")
			if isOK(inst2) then
				--print("[master chest] ondrop1")
				findchest2(inst2) --拥有这个组件的预制物 prefab
			end
		end
		--设置周期性掉落的物品掉落时，寻找可以收集它的箱子
		local function change_SetOnSpawnFn(inst)
			--print("[master chest] change_SetOnSpawnFn")
			inst.onspawn = onspawn2
			local old_setonspawnfn = inst.SetOnSpawnFn
			function inst:SetOnSpawnFn(fn)
				--print("[master chest] SetOnSpawnFn")
				inst.onspawn = function(inst1, inst2)
					fn(inst1, inst2)
					onspawn2(inst1, inst2)
				end
			end
		end
		AddComponentPostInit("periodicspawner",change_SetOnSpawnFn)
		--收集熊的毛丛
		local function change_shedder(inst)
			local old_DoSingleShed = inst.components.shedder.DoSingleShed
			function inst.components.shedder:DoSingleShed()
				local item = old_DoSingleShed(self)
				if item ~= nil then
					findchest2(item)
				end
				return item
			end
		end
		AddPrefabPostInit("bearger",change_shedder)
	end

	--3.战利品收集

	--收集战利品
	--寻找周围可以收集它的箱子（不是箱子收集周围所有物品，减少计算量）
	local function findchest3(x,y,z,lootprefab) --lootprefab
		local ents = _G.TheSim:FindEntities(x, y, z, collectdist, { "chest" }, { "INLIMBO"}) 
		for i, v in ipairs(ents) do
			--print(v)
			if v and (v.prefab == "treasurechest" or v.prefab == "dragonflychest") and v.components.container ~= nil and lootprefab and v.collectitems == (lootprefab.drawnameoverride or lootprefab:GetBasicDisplayName()) then --找到一个可以收集这种物品的箱子
				--交给箱子去检测它周围的物品
				findchest2(lootprefab)
			end
		end
	end

	local is_collect_lootdropper = GetModConfigData("is_collect_lootdropper")
	if is_collect_lootdropper == 1 then
		local function change_SpawnLootPrefab(inst)
			local old_SpawnLootPrefab = inst.SpawnLootPrefab
			function inst:SpawnLootPrefab(lootprefab, pt, linked_skinname, skin_id, userid)
				t = old_SpawnLootPrefab(self, lootprefab, pt, linked_skinname, skin_id, userid)
				if pt == nil then
					pt = self.inst:GetPosition()
				end
				local x,y,z = pt:Get()
				findchest3(x,y,z,t)
				return t
			end
		end
		AddComponentPostInit("lootdropper",change_SpawnLootPrefab)
	end
	-- %% 被收集物品相关 结束------------------------------------
	--=====================================================================================
end


  
