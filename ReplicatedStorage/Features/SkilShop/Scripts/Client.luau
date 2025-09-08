--!strict

-- StarterPlayerScripts > SkillShopTriggerHandler (LocalScript)
-- 멀티플레이어 환경에서 안정적으로 작동하도록 개선

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local quickBounds = require(ReplicatedStorage.Packages.quickBounds)
local inst = require(ReplicatedStorage.Packages.inst)
local bin = require(ReplicatedStorage.Packages.bin)
local charm = require(ReplicatedStorage.Packages.charm)
local bloxycharm = require(ReplicatedStorage.Packages.bloxycharm)
local playerAtoms = require(ReplicatedStorage.Features.StateSync.Scripts.playerAtoms)
local tags = require(ReplicatedStorage.Shared.Scripts.tags)

local CUTSCENE_DATA = {{CFrame = CFrame.new(205.392471, 51.0465736, 43.466362, -0.63840872, -0.0599638559, -0.768238008, 5.90786367e-05, 0.997497201, -0.078068465, 0.77005291, -0.0497940332, -0.63688159);Seconds = 2;Style = Enum.EasingStyle.Quad}}

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui
local gui = script.Parent.Parent.UI.NpcGui
gui.Parent = playerGui
local group = quickBounds.createGroup()
local cutSceneTweens: { Tween } = {}
local currentCamera = workspace.CurrentCamera

local atom = charm.atom
local reactive = bloxycharm.reactive
local effect = charm.effect
local subscribe = charm.subscribe

local skillShopVisible = atom(false)

-- 트윈 데이터 미리 만들어두기
for i, data in CUTSCENE_DATA do
	cutSceneTweens[i] = TweenService:Create(
		currentCamera,
		TweenInfo.new(
			data.Seconds,
			data.Style,
			Enum.EasingDirection.Out,
			0,
			false,
			0
		),
		{CFrame = data.CFrame}
	)
end

--- 컷씬 트윈 토글 재생
subscribe(skillShopVisible, function(toggle)
	for _, tween in cutSceneTweens do
		if toggle then
			currentCamera.CameraType = Enum.CameraType.Scriptable
			tween:Play()
		else
			currentCamera.CameraType = Enum.CameraType.Custom
			tween:Cancel()
		end
	end
end)
reactive(gui.SkillShop).Visible = skillShopVisible
reactive(gui.SkillShop.TixFrame.TextLabel).Text = playerAtoms.tix

tags.skillShopTrigger:extend(inst.generic("BasePart") :: inst.Generic<BasePart>,
	function(trigger)
		--if not trigger:IsA("BasePart") then
		--	error("SkillShopTrigger는 BasePart만 가능합니다.")
		--end
		local cleanup, emptyBin = bin()

		local zone = quickBounds.createZoneFromInstance(trigger)
		zone:watchGroups(group)
		cleanup(function()
			zone:unwatchGroups(group)
			zone:destroy()
		end)

		cleanup(group:onEntered(function(_, zone, data)
			skillShopVisible(true)
			if typeof(data) == "Instance" and data:IsA("Model") then
				tags.hiddenModel:add(data)
			end
		end))

		cleanup(group:onExited(function(_, zone, data)
			skillShopVisible(false)
			if typeof(data) == "Instance" and data:IsA("Model") then
				tags.hiddenModel:remove(data)
			end
		end))

		return emptyBin
	end
)

inst.observePlayerCharacter(localPlayer, function(character)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoidRootPart or not humanoidRootPart:IsA("BasePart") then
		return
	end
	group:add(humanoidRootPart, character)
	return function()
		group:remove(humanoidRootPart)
	end
end)

