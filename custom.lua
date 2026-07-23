--[[
    Overdrive MM2 Addon: Gold C4 Plugin (English UI Mini Buttons)
]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local localPlayer = Players.LocalPlayer

local bombCooldown = 1.5
local canDropBomb = true
local autoGiveEnabled = true 

local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Удаляем старые интерфейсы, чтобы не наслаивались
if playerGui:FindFirstChild("OverdriveBombPluginContainer") then
	playerGui.OverdriveBombPluginContainer:Destroy()
end
if playerGui:FindFirstChild("OverdriveBombAddonGui") then
	playerGui.OverdriveBombAddonGui:Destroy()
end

----------------------------------------------------------------
-- СОЗДАНИЕ МАЛЕНЬКОЙ ПАНЕЛИ УПРАВЛЕНИЯ В УГЛУ ЭКРАНА
----------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OverdriveBombPluginContainer"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Контейнер в левом верхнем углу (чуть ниже стандартного меню Roblox)
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 180, 0, 30)
container.Position = UDim2.new(0, 15, 0, 60) 
container.BackgroundTransparency = 1
container.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = container

-- Функция для мини-кнопок
local function createMiniButton(text, color, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 85, 1, 0)
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 11
	btn.Text = text
	btn.LayoutOrder = order
	btn.Parent = container
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = btn
	
	return btn
end

-- Кнопки теперь полностью на английском
local removeBtn = createMiniButton("❌ Remove C4", Color3.fromRGB(150, 40, 40), 1)
local returnBtn = createMiniButton("♻️ Return C4", Color3.fromRGB(40, 130, 40), 2)

----------------------------------------------------------------
-- МЕХАНИКА РАДУЖНОЙ БОМБЫ
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
-- УПРАВЛЕНИЕ ВЫДАЧЕЙ
----------------------------------------------------------------
local function giveGoldBomb()
	if not autoGiveEnabled then return end
	local backpack = localPlayer:WaitForChild("Backpack")
	if not backpack:FindFirstChild("Gold C4 Block") and not (localPlayer.Character and localPlayer.Character:FindFirstChild("Gold C4 Block")) then
		local goldTool = Instance.new("Tool")
		goldTool.Name = "Gold C4 Block"
		setupBombLogic(goldTool, Color3.fromRGB(255, 185, 35))
		goldTool.Parent = backpack
	end
end

local function removeGoldBomb()
	local backpack = localPlayer:FindFirstChild("Backpack")
	if backpack then
		local item = backpack:FindFirstChild("Gold C4 Block")
		if item then item:Destroy() end
	end
	local character = localPlayer.Character
	if character then
		local item = character:FindFirstChild("Gold C4 Block")
		if item then item:Destroy() end
	end
end

removeBtn.MouseButton1Down:Connect(function()
	autoGiveEnabled = false
	removeGoldBomb()
end)

returnBtn.MouseButton1Down:Connect(function()
	autoGiveEnabled = true
	giveGoldBomb()
end)

localPlayer.CharacterAdded:Connect(function()
	task.wait(0.8) 
	giveGoldBomb()
end)

if localPlayer.Character then 
	giveGoldBomb() 
end
