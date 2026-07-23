--[[
    Overdrive MM2 Addon: Gold C4 Bomb (Фоновый авто-гивер без кнопок)
]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local localPlayer = Players.LocalPlayer

local bombCooldown = 1.5 -- Время жизни бомбы (сек)
local canDropBomb = true

-- Удаляем старый интерфейс, если он остался в игре от прошлых запусков
local playerGui = localPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("OverdriveBombAddonGui") then
	playerGui.OverdriveBombAddonGui:Destroy()
end

----------------------------------------------------------------
-- 1. КРАСИВЫЙ ЭФФЕКТ РАДУЖНОГО ВЗРЫВА (ПАРТИКЛЫ)
----------------------------------------------------------------
local function createC4Block(color, isStatic)
	local block = Instance.new("Part")
	block.Shape = Enum.PartType.Block
	block.Size = Vector3.new(1.5, 0.6, 1.2) 
	block.Color = color
	block.Material = Enum.Material.SmoothPlastic
	block.Reflectance = 0.12

	if isStatic then
		block.Anchored = false
		block.CanCollide = true
		
		local bodyAngularVelocity = Instance.new("BodyAngularVelocity")
		bodyAngularVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge) 
		bodyAngularVelocity.AngularVelocity = Vector3.new(0, 0, 0)
		bodyAngularVelocity.Parent = block
	else
		block.Massless = true
	end
	return block
end

local function createBeautifulRainbowParticles(parent)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://10849912197" 
	
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(50, 255, 50)),
		ColorSequenceKeypoint.new(0.66, Color3.fromRGB(50, 100, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 255))
	})
	
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.4),
		NumberSequenceKeypoint.new(0.7, 0.9),
		NumberSequenceKeypoint.new(1, 0)
	})
	
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(1, 1)
	})
	
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed = NumberRange.new(15, 30)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Gravity = Vector3.new(0, -8, 0)
	emitter.Drag = 2.2
	emitter.RotSpeed = NumberRange.new(-200, 200)
	
	emitter.Enabled = false
	emitter.Parent = parent
	return emitter
end

----------------------------------------------------------------
-- 2. ЛОГИКА БОМБЫ И АВТО-УДАЛЕНИЯ ЧЕРЕЗ DEBRIS
----------------------------------------------------------------
local function setupBombLogic(tool, color)
	tool.RequiresHandle = true
	local handle = createC4Block(color, false)
	handle.Name = "Handle"
	handle.Parent = tool
	
	tool.Grip = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)

	tool.Activated:Connect(function()
		local character = localPlayer.Character
		if not character or not canDropBomb then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		
		if humanoid and rootPart and humanoid.Health > 0 then
			canDropBomb = false
			humanoid.Jump = true 
			task.wait(0.12)
			
			local droppedBlock = createC4Block(color, true)
			droppedBlock.Name = "DroppedVisualC4"
			
			local currentPos = rootPart.Position - Vector3.new(0, 2, 0)
			droppedBlock.CFrame = CFrame.new(currentPos) 
			droppedBlock.Parent = game.Workspace
			
			droppedBlock.Velocity = Vector3.new(0, -12, 0)

			-- Жесткое удаление блока из Workspace
			Debris:AddItem(droppedBlock, bombCooldown)

			task.spawn(function()
				local waitBeforeParticles = math.max(0, bombCooldown - 0.4)
				task.wait(waitBeforeParticles)
				
				if droppedBlock and droppedBlock.Parent then
					local effectAnchor = Instance.new("Part")
					effectAnchor.Size = Vector3.new(1, 1, 1)
					effectAnchor.CFrame = droppedBlock.CFrame
					effectAnchor.Anchored = true
					effectAnchor.CanCollide = false
					effectAnchor.Transparency = 1
					effectAnchor.Parent = game.Workspace
					
					Debris:AddItem(effectAnchor, 1.6)
					
					local rainbowBoom = createBeautifulRainbowParticles(effectAnchor)
					rainbowBoom:Emit(70)
				end
			end)
			
			task.wait(0.2) 
			canDropBomb = true
		end
	end)
end

----------------------------------------------------------------
-- 3. ПОЛНОСТЬЮ АВТОМАТИЧЕСКАЯ ВЫДАЧА (БЕЗ КНОПОК)
----------------------------------------------------------------
local function giveGoldBomb()
	local backpack = localPlayer:WaitForChild("Backpack")
	if not backpack:FindFirstChild("Gold C4 Block") and not (localPlayer.Character and localPlayer.Character:FindFirstChild("Gold C4 Block")) then
		local goldTool = Instance.new("Tool")
		goldTool.Name = "Gold C4 Block"
		setupBombLogic(goldTool, Color3.fromRGB(255, 185, 35))
		goldTool.Parent = backpack
	end
end

-- Триггер на возрождение персонажа
localPlayer.CharacterAdded:Connect(function()
	task.wait(0.8) 
	giveGoldBomb()
end)

-- Выдать сразу, если плагин запущен посреди игры
if localPlayer.Character then 
	giveGoldBomb() 
end

print("Silent Overdrive Gold Bomb Plugin Loaded!")
