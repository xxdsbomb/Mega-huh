-- Аддон для Overdrive MM2: Авто-выдача Золотой Бомбы с радужным эффектом (Исчезновение исправлено)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

local bombCooldown = 1.5 -- Время жизни бомбы (сек)
local canDropBomb = true

----------------------------------------------------------------
-- 1. СОЗДАНИЕ ОДНОЙ ПЕРЕТАСКИВАЕМОЙ КНОПКИ АВТО-ВЗЯТИЯ
----------------------------------------------------------------
local playerGui = localPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OverdriveBombAddonGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local autoButton = Instance.new("TextButton")
autoButton.Name = "AutoGoldBombButton"
autoButton.Size = UDim2.new(0, 160, 0, 40)
autoButton.Position = UDim2.new(0.5, -80, 0.85, 0) 
autoButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0) 
autoButton.TextColor3 = Color3.fromRGB(0, 0, 0)
autoButton.TextSize = 14
autoButton.Font = Enum.Font.SourceSansBold
autoButton.Text = "⚡ Авто-взятие Бомбы"
autoButton.Active = true
autoButton.Parent = screenGui

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0, 8)
uicorner.Parent = autoButton

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(150, 110, 0)
stroke.Parent = autoButton

-- Система перетаскивания (Drag & Drop) кнопки пальцем по экрану
local dragging, dragInput, dragStart, startPos
local function update(input)
	local delta = input.Position - dragStart
	autoButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

autoButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = autoButton.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)

autoButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then update(input) end
end)

----------------------------------------------------------------
-- 2. КРАСИВЫЙ ЭФФЕКТ РАДУЖНОГО ВЗРЫВА (ПАРТИКЛЫ)
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
-- 3. ЛОГИКА ВЫДАЧИ И СТОПРОЦЕНТНОГО УДАЛЕНИЯ ПОСЛЕ БРОСКА
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

			local currentCooldown = bombCooldown 
			
			task.spawn(function()
				local waitBeforeParticles = math.max(0, currentCooldown - 0.4)
				task.wait(waitBeforeParticles)
				
				-- Безопасная проверка: если бомба на месте, спавним эффекты и жестко чистим объект
				if droppedBlock and droppedBlock.Parent then
					local effectAnchor = Instance.new("Part")
					effectAnchor.Size = Vector3.new(1, 1, 1)
					effectAnchor.CFrame = droppedBlock.CFrame
					effectAnchor.Anchored = true
					effectAnchor.CanCollide = false
					effectAnchor.Transparency = 1
					effectAnchor.Parent = game.Workspace
					
					local rainbowBoom = createBeautifulRainbowParticles(effectAnchor)
					rainbowBoom:Emit(70)
					
					task.wait(0.4)
					
					-- Принудительное удаление блока бомбы из игры
					if droppedBlock then 
						droppedBlock:Destroy() 
					end
					
					-- Удаляем якорь эффектов после того, как частицы догорят
					task.wait(1.2)
					effectAnchor:Destroy()
				else
					-- Запасной вариант на случай сбоев физики
					if droppedBlock then 
						droppedBlock:Destroy() 
					end
				end
			end)
			
			task.wait(0.2) 
			canDropBomb = true
		end
	end)
end

local function giveGoldBomb()
	local backpack = localPlayer:WaitForChild("Backpack")
	if not backpack:FindFirstChild("Gold C4 Block") and not (localPlayer.Character and localPlayer.Character:FindFirstChild("Gold C4 Block")) then
		local goldTool = Instance.new("Tool")
		goldTool.Name = "Gold C4 Block"
		setupBombLogic(goldTool, Color3.fromRGB(255, 185, 35))
		goldTool.Parent = backpack
	end
end

autoButton.MouseButton1Down:Connect(giveGoldBomb)

localPlayer.CharacterAdded:Connect(function()
	task.wait(0.8) 
	giveGoldBomb()
end)

if localPlayer.Character then 
	giveGoldBomb() 
end
