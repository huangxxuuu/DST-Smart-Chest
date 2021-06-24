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
		local tag = target.entity:GetDebugString()
		-- print("[showInfo] " .. tag)
		local index1 = string.find(tag, "Prefab:",0)
		local index2 = string.find(tag, "\n", index1)
		print("[showInfo] Prefab weizhi:" .. index1)
		print("[showInfo] \\n weizhi:" .. index2)
		local s = string.sub(tag,index1+8,index2-1)
		print("[showInfo] " .. s)
		print(s .. " len = " .. string.len(s))
	end

end
_G.TheInput:AddKeyUpHandler(117, showInfo)

-- 给minisign添加一个属性itemname。当画的时候设置这个属性
local function MinisignAddItemname(inst)
	inst.itemname = nil
	local old_draw = inst.components.drawable.ondrawnfn
	inst.components.drawable:SetOnDrawnFn(function(inst, image, src, atlas, bgimage, bgatlas)
		--print("[master chest] ondraw")
		--获取src的prefab名称
		local tag = src.entity:GetDebugString()
		-- print("[showInfo] " .. tag)
		local index1 = string.find(tag, "Prefab:",0)
		local index2 = string.find(tag, "\n", index1)
		inst.itemname = string.sub(tag,index1+8,index2-1)
		old_draw(inst, image, src, atlas, bgimage, bgatlas)
	end)
end
AddPrefabPostInit("minisign", MinisignAddItemname)

