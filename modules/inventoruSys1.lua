local module = {}
local players = game:GetService("Players")
local getInventoryInfoClient = game.ReplicatedStorage:WaitForChild("communication"):WaitForChild("getInventoryInfo")
local inventoryChangeClient = game.ReplicatedStorage:WaitForChild("communication"):WaitForChild("inventoryChange")
local itemList = require(game.ReplicatedStorage:WaitForChild("items"):WaitForChild("itemList"))
local HttpService = game:GetService("HttpService")

--[[

	each item in a players inv will look like:
	
	["itemUUID"] = {
		name = "" (display name)
		rarity = "",
		type = "",
		value = 0,
		numericId = 0
		modifiers = {}
	}

]]

module.requiredProperties = {
	
	name = "err",
	rarity = "err",
	type = "err",
	value = 0
	
}

module.inventories = {}
module.lastPushList = {}
module.pushThrottle = 0.2


function module.getByType(player, t)
	
	local out = {}
	for uuid, item in pairs(module.inventories[player.UserId]) do
		if item.type == t then out[uuid] = item end
	end
	
	return out
end

function module.loadPlayerInventory(player, loadedInventory)
	
	if not player or not loadedInventory then return false end
	
	if module.inventories[player.UserId] == nil then
		--make whole inventory the loaded inventory
		module.inventories[player.UserId] = loadedInventory
	else
		--merge the loaded inventory and the existing inventory
		--this probably shouldnt happen but just in case i added it
		
		warn("merging for ", player)
		
		for i,v in module.inventories[player.UserId] do
			
			if loadedInventory[i] == nil then
				loadedInventory[i] = v
			end
			
		end
		
		module.inventories[player.UserId] = loadedInventory
		
		warn("merged: ", module.inventories[player.UserId])
		
	end
	
	module.pushDataToClient(player, "full", module.getInventory(player))
	
end

function module.getInventory(player)
	
	local inv = module.inventories[player.UserId]
	
	if inv == nil then
		module.inventories[player.UserId] = {}
		return {}
	end
	
	local copy = {}
	
	for uuid, item in pairs(inv) do
		copy[uuid] = item
	end
	
	return copy
	
end

function module.addItem(player, itemNameOrId, itemProperties, shouldPush)
	local inv = module.inventories[player.UserId]
	
	if not inv then
		module.inventories[player.UserId] = {}
	end
	
	local itemUUID = HttpService:GenerateGUID(false)
	
	local itemObject = {}
	
	local itemInfo = itemList.allItems[itemNameOrId]
	
	if not itemInfo then return false end
	
	for name,val in itemProperties do
		itemObject[name] = val
	end
	
	itemObject.rarity = itemInfo.rarity
	itemObject.type = itemInfo.type
	itemObject.numericId = itemInfo.numericId
	itemObject.itemId = itemNameOrId
	
	for propName, default in module.requiredProperties do
		if itemObject[propName] == nil then
			itemObject[propName] = default
		end
	end
	
	itemObject.name = itemInfo.name 
	
	module.inventories[player.UserId][itemUUID] = itemObject

	module.pushDataToClient(player, "add", itemUUID, itemObject)
	
	return true, itemUUID
end

function module.removeItem(player, itemId)
	if player == nil or itemId == nil then return false end
	
	if module.inventories[player.UserId] == nil then return false end
	
	if module.inventories[player.UserId][itemId] == nil then return false end
	
	module.inventories[player.UserId][itemId] = nil

	module.pushDataToClient(player, "remove", itemId)
	
	return true, itemId
end

function module.pushDataToClient(player : Player, mode, ...)
	
	--print("push ")
	
	if not player or not mode then return false end
	
	local now = os.clock()
	
	if module.lastPushList[player.UserId] ~= nil then
		if now - module.lastPushList[player.UserId] <= module.pushThrottle and mode == "full" then
			warn("push to client throttled for", player)
			return false
		end
	end
	
	module.lastPushList[player.UserId] = now
	
	inventoryChangeClient:FireClient(player, mode, ...)
	
	return true
end



getInventoryInfoClient.OnServerInvoke = function(player, requestType, ...)

	if player == nil or requestType == nil then return nil end
		
	if requestType == 1 then
		return module.getInventory(player)
	elseif requestType == 2 then
		return module.getByType(player, "Material")
	elseif requestType == 3 then
		return module.getByType(player, "Tool")
	end
end

players.PlayerRemoving:Connect(function(player)
	module.inventories[player.UserId] = nil
	module.lastPushList[player.UserId] = nil
end)


return module

--I was here
--:thumbsup:
--sybau
