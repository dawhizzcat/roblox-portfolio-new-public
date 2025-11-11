local module = {}

local dss = game:GetService("DataStoreService")
local inventoryStore = dss:GetDataStore("inventories")
--local toolStore = dss:GetDataStore("tools")
local inventoryModule = require(game.ServerScriptService:WaitForChild("inventories"):WaitForChild("inventoryModule"))
local itemList = require(game.ReplicatedStorage:WaitForChild("items"):WaitForChild("itemList"))

module.conversionTableSave = {
	
	["rarity"] = {
		Common = 1,
		Uncommon = 2,
		Rare = 3,
		Epic = 4,
		Legendary = 5,
		Mythic = 6
	},
	
	["type"] = {
		
		Material = 1,
		Accesory = 2,
		Tool = 3,
	},
	
	["modifiers"] = {
		Blazing = 1,
		Electrified = 2,
		Huge = 3,
		Perfect = 4,
	},
	
}

module.conversionTableLoad = {
	
	["rarity"] = {
		[1] = "Common",
		[2] = "Uncommon",
		[3] = "Rare",
		[4] = "Epic",
		[5] = "Legendary",
		[6] = "Mythic"
	},
	
	["type"] = {
		[1] = "Material",
		[2] = "Accesory",
		[3] = "Tool",
	},
	
	["modifiers"] = {
		[1] = "Blazing",
		[2] = "Electrified",
		[3] = "Huge",
		[4] = "Perfect"
	}
	
}

function module.itemExists(numericId)
	for _, itemInfo in pairs(itemList) do
		if itemInfo.numericId == numericId then
			return true
		end
	end
	return false
end

function module.convertData(mode, loadedData)
	local result = {}
	if type(loadedData) ~= "table" then return result end

	local mapTable = (mode=="save") and module.conversionTableSave or module.conversionTableLoad

	for uuid, props in pairs(loadedData) do
		
		local newProps = {}
		--[[
		if not module.itemExists(props.numericId) then
			warn("item does not exist ", props.numericId)
			continue
		end
		]]
		
		for key, val in pairs(props) do
			
			
			
			if (key == "itemId" or key == "name") and mode == "save" then
				continue
				
			end
			
			local fieldMap = mapTable[key]
			if fieldMap and fieldMap[val] then
				newProps[key] = fieldMap[val]
			else
				newProps[key] = val
			end
			
		end
		
		if mode == "load" then
			
			local itemId 
			local itemName

			for i,v in itemList.allItems do
				
				if v.numericId == props.numericId then
					itemId = i
					itemName = v.name
					break
				end
				
			end

			if itemId ~= nil then
				newProps.itemId = itemId
			end

			if itemName ~= nil then
				newProps.name = itemName
			end
		end
		
		result[uuid] = newProps
	end
	
	
	
	

	return result
end


function module.savePlayerData(player)
	
	if not player then return false end
	
	local playerInventory = inventoryModule.getInventory(player)
	
	if not playerInventory then return false end
	
	local userId = player.UserId
	
	local convertedData = module.convertData("save", playerInventory)
	
	warn("converted save data: ", convertedData)
	
	local success, err = pcall(function()
		
		inventoryStore:UpdateAsync("inv_" .. userId, function()
			return convertedData
		end)
		
	end)
	
	if not success then
		
		warn("Failed to save for", player, err)
		return false
		
	else
		
		warn("saved data for ", player)
		
	end
	
	return true
end

function module.loadPlayerData(player)
	
	if not player then return false end
	
	local userId = player.UserId
	
	local success, data = pcall(function()
		return inventoryStore:GetAsync("inv_" .. userId)
	end)
	
	

	if success then
		if data == nil then
			data = {}
		end
		
		
		local convertedData = module.convertData("load", data)
		
		warn("converted data for ", player, convertedData)

		return true, convertedData
	else
		warn("Failed to load data for player " .. player .. ": " .. tostring(data))
		
		return false, nil
	end
	
	
	
end

return module
