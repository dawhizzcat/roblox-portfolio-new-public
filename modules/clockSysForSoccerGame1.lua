local roundFunctions = require(game.ServerStorage:WaitForChild("serverModules"):WaitForChild("serverFunctions"))
local returnTime = game.ReplicatedStorage:WaitForChild("remotes"):WaitForChild("roundHandlers"):WaitForChild("returnTime")
local periodicCorrection = game.ReplicatedStorage:WaitForChild("remotes"):WaitForChild("roundHandlers"):WaitForChild("periodic")
local cycleChange = game.ReplicatedStorage:WaitForChild("remotes"):WaitForChild("roundHandlers"):WaitForChild("cycleChange")
local doClientRoundEffects = game.ReplicatedStorage:WaitForChild("remotes"):WaitForChild("roundHandlers"):WaitForChild("clientRoundEffects")
local reset = game.ReplicatedStorage.reset
local freezeServerClock = game.ReplicatedStorage:WaitForChild("remotes"):WaitForChild("roundHandlers"):WaitForChild("freezeServerClock") 
local config = require(game.ServerStorage:WaitForChild("config"))



local intermissionTime = config.intermissionTime -- seconds between rounds
local roundTime = config.roundTime       -- round duration
local updateInterval = config.updateInterval    -- client update interval (seconds)
local cycleChangeDelay = config.cycleChangeDelay --time that the server waits to resume the clock when the cycle changes (allows for ui changes and stuff)

local gameInProgress = false
local lastPhaseTime = time()
local lastClientUpdate = 0
local clockFrozen = false --used to freeze the server clock

local frozenStartTime = nil
local totalFrozenTime = 0

local function pushCorrectionNow(timeRemaining)
	
	periodicCorrection:FireAllClients(gameInProgress, math.max(0, math.ceil(timeRemaining)))
	lastClientUpdate = time()
	
end



freezeServerClock.Event:Connect(function(frozen)
	
	if frozen ~= nil then
		
		if frozen then
			frozenStartTime = time()
			
		elseif not frozen then
			
			totalFrozenTime += (time() - frozenStartTime)
			
			local phaseDuration = gameInProgress and roundTime or intermissionTime
			local timeRemaining = phaseDuration - (time() - lastPhaseTime)
			timeRemaining += totalFrozenTime
			
			pushCorrectionNow(timeRemaining)
			
		end
		
		clockFrozen = frozen
	end

end)


game:GetService("RunService").Heartbeat:Connect(function(dt)
	--dont update anything if clock is frozen
	if clockFrozen then
		return
	end

	local now = time()
	
	
	local phaseDuration = gameInProgress and roundTime or intermissionTime
	local timeRemaining = phaseDuration - (now - lastPhaseTime)
	timeRemaining += totalFrozenTime
	
	--[[
	local phaseDuration = gameInProgress and roundTime or intermissionTime
	local adjustedTime = now - lastPhaseTime - totalFrozenTime
	
	local timeRemaining = phaseDuration - adjustedTime
	]]

	
	--warn("time remaining ", timeRemaining)
	
	--checking phases
	if timeRemaining <= 0 then
		totalFrozenTime = 0

		-- freeze clock when phase ends
		clockFrozen = true

		--get next phase
		local nextGameInProgress = not gameInProgress
		local nextPhaseDuration = nextGameInProgress and roundTime or intermissionTime

		if nextGameInProgress then
			warn("Starting round...")
			reset:Fire()

			-- Fire client effects to ALL players who will be in the round
			roundFunctions.startRound() --in module

			--freeze duration wait
			task.wait(cycleChangeDelay)

		else
			warn("Ending round...")
			roundFunctions.endRound() --in module

			-- Wait a bit for end round effects
			task.wait(1)
		end

		-- Update server state
		gameInProgress = nextGameInProgress
		lastPhaseTime = time() -- Reset phase time to now

		-- Fire cycle change to all clients
		cycleChange:FireAllClients(gameInProgress, nextPhaseDuration)

		-- Unfreeze the clock
		clockFrozen = false
	end

	-- fire event to clients every few seconds to update their clocks
	if not clockFrozen and now - lastClientUpdate >= updateInterval then
		local displayTime = math.max(0, math.ceil(timeRemaining))
		--warn("periodic update: ", displayTime)
		periodicCorrection:FireAllClients(gameInProgress, displayTime)
		lastClientUpdate = now
	end
end)

returnTime.OnServerInvoke = function(player)
	if clockFrozen then
		-- Return 0 time remaining if clock is frozen
		local phaseDuration = gameInProgress and roundTime or intermissionTime
		return 0, phaseDuration
	end

	local now = time()
	local phaseDuration = gameInProgress and roundTime or intermissionTime
	local timeRemaining = phaseDuration - (now - lastPhaseTime) + totalFrozenTime

	return timeRemaining, phaseDuration
end
