local module = {}
module.__index = module



local module = setmetatable({}, module)

module.teams = {}
module.spawnAssignments = {}
module.roundActive = false

local field = game.Workspace:WaitForChild("field")
local players = game:GetService("Players")
local teams = game.Teams
local assign = {
	[1] = teams["The Oak Beavers"],
	[2] = teams["The Spruce Bears"]
}

function module.count(teams)
	local team1 = 0
	local team2 = 0

	for i,v in teams do
		if v == 1 then
			team1 += 1
		elseif v == 2 then
			team2 += 1
		end
	end
	
	module.teams = {team1, team2}

	return team1, team2
end

function module.makeTeams()
	local teamList = {}
	local players = game:GetService("Players")

	for i,v in players:GetPlayers() do
		if teamList[v] == nil then
			--use userID not player instance
			local team1PlayerCount, team2PlayerCount = module.count(teamList)

			if team1PlayerCount > team2PlayerCount then
				teamList[v.UserId] = 2
			elseif team1PlayerCount < team2PlayerCount then
				teamList[v.UserId] = 1
			else
				teamList[v.UserId] = math.random(1,2)
			end
		end
	end

	return teamList
end

function module.getHighest(table)
	local highest = 0
	for key, _ in pairs(table) do
		if key > highest then
			highest = key
		end
	end
	return highest
end

function module.spawnTeams()
	
	local spawnAssignments = module.spawnAssignments
	
	for teamNum, playerList in spawnAssignments do
		local folder = field:WaitForChild("team" .. teamNum .. "Spawns")

		for spawnIndex, player in playerList do
			local spawnPart = folder:FindFirstChild(tostring(spawnIndex))
			if spawnPart then
				local char = player.Character or player.CharacterAdded:Wait()
				if char and char:FindFirstChild("HumanoidRootPart") then
					local spawnPos = spawnPart.Position + Vector3.new(0, char.HumanoidRootPart.Size.Y/2 + 0.5, 0)
					char:MoveTo(spawnPos)
				end
			end
		end
	end
end

function module.startRound()
	
	module.roundActive = true
	
	local gameStorage = game.ReplicatedStorage:WaitForChild("game")
	local gameScores = gameStorage:WaitForChild("scores")
	
	gameScores:WaitForChild("team1Score").Value = 0
	gameScores.team2Score.Value = 0
	gameScores.maxScore.Value = 15
	gameStorage.roundActive.Value = true
	
	



	local teamList = module.makeTeams()
	
	local spawnAssignments = {
		[1] = {},
		[2] = {},
	}

	-- First, fire client effects to all players who will be in the round
	-- This happens BEFORE assigning teams so clients can prepare their UI
	for userId, teamNum in teamList do
		local player = players:GetPlayerByUserId(userId)
		if player then
			game.ReplicatedStorage:WaitForChild("remotes"):WaitForChild("roundHandlers"):WaitForChild("clientRoundEffects"):FireClient(player)
		end
	end

	-- Now assign teams and prepare spawn assignments
	for userId, teamNum in teamList do
		local player = players:GetPlayerByUserId(userId)
		if player then
			player.Team = assign[teamNum]

			local assignTable = spawnAssignments[teamNum]
			local spawnNum = module.getHighest(assignTable) + 1
			assignTable[spawnNum] = player
		end
	end

	warn("Team assignments:", teamList)
	warn("Spawn assignments:", spawnAssignments)
	
	module.spawnAssignments = spawnAssignments

	-- Delay teleportation so it happens when UI is covering the screen
	task.delay(2, function()
		module.spawnTeams()
	end)
	
	
end

function module.endRound()
	module.roundActive=  false
	local lobbySpawns = game.Workspace:WaitForChild("lobbySpawns")
	
	local gameStorage = game.ReplicatedStorage:WaitForChild("game")
	local gameScores = gameStorage:WaitForChild("scores")
	
	for i, player in pairs(players:GetPlayers()) do
		if player.Team ~= teams.Spectators then
			player.Team = teams.Spectators

			local spawnPart = lobbySpawns:FindFirstChild(tostring(math.random(1,4)))
			if spawnPart then
				local char = player.Character or player.CharacterAdded:Wait()
				if char and char:FindFirstChild("HumanoidRootPart") then
					local spawnPos = spawnPart.Position + Vector3.new(0, char.HumanoidRootPart.Size.Y/2 + 0.5, 0)
					char:MoveTo(spawnPos)
				end
			end
		end
	end
	
	if gameScores.team1Score.Value > gameScores.team2Score.Value then
		warn("team 1 wins")
	elseif gameScores.team1Score.Value < gameScores.team2Score.Value then
		warn("team 2 wins")
	elseif gameScores.team1Score.Value == gameScores.team2Score.Value then
		warn("tie")
	end
	
	gameScores.team1Score.Value = 0
	gameScores.team2Score.Value = 0
	gameScores.maxScore.Value = 15
	gameStorage:WaitForChild("roundActive").Value = false
	
end

function module.score(team)
	
	local gameStorage = game.ReplicatedStorage:WaitForChild("game")
	local gameScores = gameStorage:WaitForChild("scores")
	
	local scoreToIncrease = gameScores:FindFirstChild("team"..team.."Score")
	
	if scoreToIncrease ~= nil then
		scoreToIncrease.Value += 1
	end	
	
	task.delay(0.7, function()
		module.spawnTeams()
	end)
	
end

return module
