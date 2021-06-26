
local name = "Smart Chest"
local modname = KnownModIndex:GetModActualName(name)
local minisigndist = GetModConfigData("minisign_dist", modname)
local iscollectone = GetModConfigData("iscollectone", modname)

local LXautocollectitems = Class(function(self, inst)
	self.inst = inst
	self.iscollect = false -- 判断是否开始收集
	self.items = {}
	self.x = nil
	self.y = nil
	self.z = nil
	self.iscollectone = false
	self.minisigndist = 1.5
end,
nil,
nil)

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
	--print("[LXautocollectitems]SetItems enter")
	if self.inst and self.inst.components and self.inst.components.container then
		self.items = {} -- 清空当前的设置
		-- 获取周围的小木牌
		local x, y, z = self.inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, self.minisigndist, { "sign" }, { "INLIMBO"}) --包括所有木牌
		--print("#minisign = " .. #ents)
		-- 筛选画好的,并填入items
		for i, v in ipairs(ents) do
			if v and v.prefab == "minisign" and v.components and v.components.drawable and v.components.drawable:GetImage() ~= nil then
				table.insert(self.items, v._imagename:value())
				if self.iscollectone == 1 then
					break
				end
			end
		end
		if #self.items > 0 then
			self.iscollect = true
		else
			self.iscollect = false
		end
		--[[
		for key, value in pairs(self.items) do
			print("" .. key .. " " .. value)
		end
		]]--
	end
	--print("[LXautocollectitems]SetItems exit")
end

-- 功能2：收集物品
-- 判断物品是否在items中
local function isCanCollect(items, item)
	if items == nil then
		return false
	end
	for k, v in pairs(items) do
        if v == item then
            return true
        end
    end
    return false
end

-- 把物品移入箱子中，并返回剩余的
local function moveToContainer(inst, item) -- inst 箱子.components.container
	local slot = nil
	local src_pos = nil
	local drop_on_fail = nil
	if item == nil then
		print("[moveToContainer]85")
        return item
    elseif item.components.inventoryitem ~= nil and inst:CanTakeItemInSlot(item, slot) then
        if slot == nil then
            slot = inst:GetSpecificSlotForItem(item)
            if slot ~= nil then
                print("[moveToContainer]88 slot = " .. slot)
            else
                print("[moveToContainer]88 slot = nil")
            end
        end

        --try to burn off stacks if we're just dumping it in there
        if item.components.stackable ~= nil and inst.acceptsstacks then
            --Added this for when we want to dump a stack back into a
            --specific spot (e.g. moving half a stack failed, so we
            --need to dump the leftovers back into the original stack)
            if slot ~= nil and slot <= inst.numslots then
                local other_item = inst.slots[slot]
                if other_item ~= nil and other_item.prefab == item.prefab and other_item.skinname == item.skinname and not other_item.components.stackable:IsFull() then
                    if inst.inst.components.inventoryitem ~= nil and inst.inst.components.inventoryitem.owner ~= nil then
                        inst.inst.components.inventoryitem.owner:PushEvent("gotnewitem", { item = item, slot = slot })
                    end

                    item = other_item.components.stackable:Put(item, src_pos)
                    if item == nil then
						print("[moveToContainer]110")
                        return item
                    end

                    slot = inst:GetSpecificSlotForItem(item)
                end
            end

            if slot ~= nil then
                print("[moveToContainer]118 slot = " .. slot)
            else
                print("[moveToContainer]118 slot = nil")
            end
            if slot == nil then
                for k = 1, inst.numslots do
                    local other_item = inst.slots[k]
                    if other_item and other_item.prefab == item.prefab and other_item.skinname == item.skinname and not other_item.components.stackable:IsFull() then
                        if inst.inst.components.inventoryitem ~= nil and inst.inst.components.inventoryitem.owner ~= nil then
                            inst.inst.components.inventoryitem.owner:PushEvent("gotnewitem", { item = item, slot = k })
                        end

                        print("[moveToContainer] other_item.prefab = " .. other_item.prefab)
                        item = other_item.components.stackable:Put(item, src_pos)
                        if item == nil then
							print("[moveToContainer]133")
                            return item
                        end
                    end
                end
            end
        end

        local in_slot = nil
        if slot ~= nil and slot <= inst.numslots and not inst.slots[slot] then
            in_slot = slot
        elseif not inst.usespecificslotsforitems and inst.numslots > 0 then
            for i = 1, inst.numslots do
                if not inst.slots[i] then
                    in_slot = i
                    break
                end
            end
        end

        if in_slot then
            --weird case where we are trying to force a stack into a non-stacking container. this should probably have been handled earlier, but this is a failsafe
            if not inst.acceptsstacks and item.components.stackable and item.components.stackable:StackSize() > 1 then
                local t = nil
				if item.components.stackable.stacksize == 1 then
					t = item
					item = nil
				elseif item.components.stackable.stacksize > 1 then
					t = item.components.stackable:Get()
					item.components.stackable:SetStackSize(item.components.stackable.stacksize - 1)
				else
					print("[moveToContainer]163")
					return nil
				end
				--item = item.components.stackable:Get()
                inst.slots[in_slot] = t
                t.components.inventoryitem:OnPutInInventory(inst.inst)
                inst.inst:PushEvent("itemget", { slot = in_slot, item = t, src_pos = src_pos, })
				print("[moveToContainer]169")
                return item
            end

            inst.slots[in_slot] = item
            item.components.inventoryitem:OnPutInInventory(inst.inst)
            inst.inst:PushEvent("itemget", { slot = in_slot, item = item, src_pos = src_pos })

            if not inst.ignoresound and inst.inst.components.inventoryitem ~= nil and inst.inst.components.inventoryitem.owner ~= nil then
                inst.inst.components.inventoryitem.owner:PushEvent("gotnewitem", { item = item, slot = in_slot })
            end
			print("[moveToContainer]179")
            return nil
        end
    end

    --default to true if nil
    --[[if drop_on_fail ~= false then
        item.Transform:SetPosition(inst.inst.Transform:GetWorldPosition())
        if item.components.inventoryitem ~= nil then
            item.components.inventoryitem:OnDropped(true)
        end
    end]]--
	print("[moveToContainer]197")
    return item
end

-- 收集物品
function LXautocollectitems:onCollectItems(item, itemname)
	print("[onCollectItems] enter")
	if item == nil then -- 判断是否有剩余
		print("item == nil")
        return nil
    end
	if (self.inst.components and self.inst.components.burnable ~= nil and self.inst.components.burnable:IsBurning()) or self.inst:HasTag("burnt") then -- 正在燃烧和燃烧结束不能收集
		return item
	end
	if isCanCollect(self.items, itemname) then --判断可以收集
		print("isCanCollect OK")
		-- 因为这个现成的GiveItem没有返回值，所以要重写
		-- self.inst.components.container:GiveItem(item)
		local snumb
		if item and item.components and item.components.stackable then
			snumb = item.components.stackable.stacksize
		end
		local x, y, z = item.Transform:GetWorldPosition()
		item = moveToContainer(self.inst.components.container, item)
		if item and item.components and item.components.stackable then
			print("" .. item.prefab .. " number is " .. item.components.stackable.stacksize)
		else
			print("item = 0")
		end
		if item == nil then
			local collectanim = SpawnPrefab("sand_puff") --消失的动画
			collectanim.Transform:SetPosition(x, y, z)
			collectanim.Transform:SetScale(1,1,1)
		else
			if item and item.components and item.components.stackable and item.components.stackable.stacksize < snumb then
				local collectanim = SpawnPrefab("sand_puff") --消失的动画
				collectanim.Transform:SetPosition(x, y, z)
				collectanim.Transform:SetScale(1,1,1)
			end
		end
	end
	print("[onCollectItems] exit")
	return item
end


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