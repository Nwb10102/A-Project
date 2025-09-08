--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local inst = require(ReplicatedStorage.Packages.inst)
local playerStateMap = require(ServerStorage.Features.StateSync.Scripts.playerStateMap)

inst.observePlayer(function(player)
	local state = playerStateMap.waitFor(player)
	local t = task.spawn(function()
		while task.wait(1) do
			state.tix(function(s)
				return s + 10
			end)
		end
	end)
	return function()
		task.cancel(t)
	end
end)
