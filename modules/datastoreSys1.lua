local module = {}

local dss = game:GetService("DataStoreService")
local dataStore = dss:GetDataStore("data")
local statModule = require(game.ServerScriptService.modules.statManager)
local upgradeInfo = require(game.ReplicatedStorage.modules.upgradeInfo)
local compressionInfo = require(game.ReplicatedStorage.rocks.compressionInfo)

local function generateSaveTable(player)
	
	local saveTable = {
		rockMass = 0,
		mass = 0,
		pickaxeLevel = 0,
		backpackLevel = 0,
		guideDone = false,
		guideStage = 1,
	}

	for i, v in pairs(saveTable) do
		saveTable[i] = statModule.getStat(player, i) or v
	end

	local rockIndex = statModule.getStat(player, "rockCompression") or 1
	local rockInfo = compressionInfo.info[rockIndex] or compressionInfo.info[1]
	saveTable.rockCompression = rockInfo.name
	
	saveTable.guideStage = player:GetAttribute("guideStage")

	return saveTable
end

local function loadAllData(loadedData)
	local allData = {}

	for i, v in pairs(loadedData) do
		allData[i] = v
	end

	local defaults = {
		rockMass = 0,
		rockCompression = "Sand",
		mass = 0,
		pickaxeLevel = 0,
		backpackLevel = 0,
		guideStage = 1
	}

	for i, v in pairs(defaults) do
		allData[i] = allData[i] or v
	end

	allData.maxMass = upgradeInfo.backpackCalculation(allData.backpackLevel or 0) or 10
	local compIndex = compressionInfo.nameToIndex[allData.rockCompression] or 1
	allData.maxRockMass = compressionInfo.info[compIndex].maxMass or 10
	allData.collectAmount = upgradeInfo.pickaxeCalculation(allData.pickaxeLevel or 0) or 2

	return allData
end

function module.savePlayerData(player)
	if not player then return false end

	local userId = player.UserId
	local data = generateSaveTable(player)

	local success, err = pcall(function()
		dataStore:UpdateAsync("data_" .. userId, function()
			return data
		end)
	end)

	if not success then
		warn("Failed to save for", player, err)
		return false
	else
		warn("Saved data for", player, data)
	end

	return true
end

function module.loadPlayerData(player)
	if not player then return false end

	local userId = player.UserId
	local success, data = pcall(function()
		return dataStore:GetAsync("data_" .. userId)
	end)

	local allData = loadAllData(data or {})

	if success then
		warn("Loaded data", player, allData)
		return true, allData
	else
		warn("Failed to load data for", player, data)
		return false, nil
	end
end

return module
