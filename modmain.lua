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

-- 获取prefabs名称的函数
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

-- 给箱子添加 LXautocollectitems 这个component,并且箱子打开时设置要收集的items
local function ContainerAddACI(inst) -- ACI == LXautocollectitems
	if inst and inst.components and inst.components.container then
		inst:AddComponent("lxautocollectitems")
		local old_open = inst.components.container.onopenfn
		inst.components.container.onopenfn = function(inst2)
			inst2.components.lxautocollectitems:SetItems()
			old_open(inst2)
		end
	end
end
AddPrefabPostInit("treasurechest", ContainerAddACI)
