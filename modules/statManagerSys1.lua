local module = {}
local playerMassChanged = game.ReplicatedStorage:WaitForChild("communication"):WaitForChild("playerMassChanged")

module.stats = {}

function module.setStat(player, stat, value)
	if not module.stats[player] then
		module.stats[player] = {}
	end
	
	module.stats[player][stat] = value
	
	if stat == "mass" or stat == "maxMass" then
		
		if module.stats[player].mass ~= nil and module.stats[player].maxMass ~= nil then
			playerMassChanged:FireClient(player, module.stats[player].mass, module.stats[player].maxMass, nil, nil)
		end
		
	end
	
end

function module.modifyPlayerStat(player, stat, amount )
	
	if not module.stats[player] then
		module.stats[player] = {}
	end
	
	if module.stats[player] ~= nil and module.stats[player][stat] ~= nil then
		module.stats[player][stat] += amount
	else
		module.stats[player][stat] = amount
	end
	
	if stat == "mass" or stat == "maxMass" then
		playerMassChanged:FireClient(player, module.getStat(player, "mass"), module.getStat(player, "maxMass"), amount, 0)
	end
	
end

function module.getStat(player, stat)
	
	if module.stats[player] ~= nil then
		return module.stats[player][stat]
	else
		return nil
	end
	
end

function module.getAllStats(player)
	return module.stats[player] or nil
end

return module
