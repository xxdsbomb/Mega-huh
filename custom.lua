--[[
    Overdrive MM2 Addon: Gold Bomb Pro Panel (Fixed Dynamic Pin Position Edition)
    Features: Smooth Slide & Fade Open/Close Animation, Idle UI Breathing, Custom Theme Border Animation, Perfectly Fine-Tuned Bomb Model, Default Roblox Jump
    FIXED: Pinning now locks the button instantly at its CURRENT dragged position instead of resetting it back to the menu.
]]

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

-- Настройки по умолчанию
local bombCooldown = 1.6  
local clickDelay = 0.15   
local canDropBomb = true
local autoGiveEnabled = true 
local jumpOnUse = true 
local externalButtonEnabled = false
local isPinned = true -- Привязана ли кнопка к меню изначально

-- Цветовые схемы меню
local currentTheme = 2 

local themes = {
	[1] = { -- Золото-Оранжевый
		MainBg = Color3.fromRGB(25, 20, 15),
		BtnBg = Color3.fromRGB(190, 90, 20),
		Text = Color3.fromRGB(255, 215, 0),
		InputBg = Color3.fromRGB(45, 35, 25),
		ToggleThemeText = "🟠 Gold-Orange Theme",
		Gradient = {
			Color3.fromRGB(255, 215, 0),
			Color3.fromRGB(255, 100, 0),
			Color3.fromRGB(255, 215, 0)
		}
	},
	[2] = { -- Красно-Черный
		MainBg = Color3.fromRGB(15, 10, 10),
		BtnBg = Color3.fromRGB(140, 20, 20),
		Text = Color3.fromRGB(255, 60, 60),
		InputBg = Color3.fromRGB(35, 20, 20),
		ToggleThemeText = "🔴 Red-Black Theme",
		Gradient = {
			Color3.fromRGB(255, 0, 0),
			Color3.fromRGB(30, 0, 0),
			Color3.fromRGB(255, 0, 0)
		}
	}
}

local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Полная очистка старых версий
if playerGui:FindFirstChild("OverdriveBombPluginContainer") then
	playerGui.OverdriveBombPluginContainer:Destroy()
end

----------------------------------------------------------------
-- СОЗДАНИЕ ИНТЕРФЕЙСА
----------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OverdriveBombPluginContainer"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Кнопка настроек ⚙️ C4
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 50, 0, 30)
toggleBtn.Position = UDim2.new(0, 15, 0, 60)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
toggleBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 14
toggleBtn.Text = "⚙️ C4"
toggleBtn.Parent = screenGui

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleBtn

-- ЕДИНЫЙ КОНТЕЙНЕР ДЛЯ КНОПКИ И ЗАКРЕПА (Перемещается целиком)
local bombContainer = Instance.new("Frame")
bombContainer.Size = UDim2.new(0, 160, 0, 46)
bombContainer.Position = UDim2.new(0, 75, 0, 52)
bombContainer.BackgroundTransparency = 1
bombContainer.Visible = false
bombContainer.Parent = screenGui

-- БОЛЬШАЯ ВНЕШНЯЯ КНОПКА BOMB
local externalBombBtn = Instance.new("TextButton")
externalBombBtn.Size = UDim2.new(0, 125, 0, 46)
externalBombBtn.Position = UDim2.new(0, 0, 0, 0)
externalBombBtn.BackgroundColor3 = themes[currentTheme].BtnBg
externalBombBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
externalBombBtn.Font = Enum.Font.SourceSansBold
externalBombBtn.TextSize = 18
externalBombBtn.Text = "💥 BOMB"
externalBombBtn.Parent = bombContainer

local extCorner = Instance.new("UICorner")
extCorner.CornerRadius = UDim.new(0, 8)
extCorner.Parent = externalBombBtn

-- Кнопка закрепления (Pin Button) — жестко сидит в том же контейнере справа
local pinBtn = Instance.new("TextButton")
pinBtn.Size = UDim2.new(0, 30, 0, 46)
pinBtn.Position = UDim2.new(0, 130, 0, 0)
pinBtn.BackgroundColor3 = Color3.fromRGB(46, 125, 50) -- Зеленая (Закреплена)
pinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pinBtn.Font = Enum.Font.SourceSansBold
pinBtn.TextSize = 16
pinBtn.Text = "📌"
pinBtn.Parent = bombContainer

local pinCorner = Instance.new("UICorner")
pinCorner.CornerRadius = UDim.new(0, 8)
pinCorner.Parent = pinBtn

-- Основное меню настроек
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 180, 0, 195)
local hiddenPosition = UDim2.new(0, -200, 0, 105)
local visiblePosition = UDim2.new(0, 15, 0, 105)

mainFrame.Position = hiddenPosition
mainFrame.BackgroundColor3 = themes[currentTheme].MainBg
mainFrame.BackgroundTransparency = 1
mainFrame.Visible = true 
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = mainFrame

local frameStroke = Instance.new("UIStroke")
frameStroke.Thickness = 2
frameStroke.Transparency = 1
frameStroke.Parent = mainFrame

local uigradient = Instance.new("UIGradient")
uigradient.Parent = frameStroke

local function updateStrokeGradient()
	local currentColors = themes[currentTheme].Gradient
	uigradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, currentColors[1]),
		ColorSequenceKeypoint.new(0.5, currentColors[2]),
		ColorSequenceKeypoint.new(1, currentColors[3])
	})
end
updateStrokeGradient()

local menuOpen = false
local animCanvasGroup = Instance.new("CanvasGroup") 
animCanvasGroup.Size = UDim2.new(1, 0, 1, 0)
animCanvasGroup.BackgroundTransparency = 1
animCanvasGroup.GroupTransparency = 1
animCanvasGroup.Parent = mainFrame

-- Постоянные анимации UI (Дыхание + Движение кнопки C4)
RunService.RenderStepped:Connect(function()
	local t = tick()
	uigradient.Rotation = (t * 90) % 360 
	
	if menuOpen then
		local yOffset = math.sin(t * 3) * 3 
		mainFrame.Position = UDim2.new(visiblePosition.X.Scale, visiblePosition.X.Offset, visiblePosition.Y.Scale, visiblePosition.Y.Offset + yOffset)
		
		-- Если кнопка еще ни разу не откреплялась и находится в дефолтном закрепе у меню
		if isPinned and bombContainer.Name == "Frame" then
			-- Позволяем ей слегка покачиваться с меню на стандартном месте
			bombContainer.Position = UDim2.new(0, 75, 0, 52 + yOffset)
		end
	elseif isPinned and bombContainer.Name == "Frame" then
		bombContainer.Position = UDim2.new(0, 75, 0, 52)
	end
end)

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = animCanvasGroup

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.Parent = animCanvasGroup

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 160, 0, 18)
title.BackgroundTransparency = 1
title.Text = "Gold Bomb"
title.TextColor3 = themes[currentTheme].Text
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.LayoutOrder = 1
title.Parent = animCanvasGroup

local labelsList = {}
local inputsList = {}

local function createInputRow(labelText, defaultValue, order)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 160, 0, 24)
	container.BackgroundTransparency = 1
	container.LayoutOrder = order
	container.Parent = animCanvasGroup

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 100, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Font = Enum.Font.SourceSans
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container
	table.insert(labelsList, label)

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(0, 50, 1, 0)
	input.Position = UDim2.new(0, 110, 0, 0)
	input.BackgroundColor3 = themes[currentTheme].InputBg
	input.TextColor3 = themes[currentTheme].Text
	input.Text = tostring(defaultValue)
	input.Font = Enum.Font.SourceSansBold
	input.TextSize = 13
	input.ClipsDescendants = true
	input.Parent = container
	table.insert(inputsList, input)

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 4)
	inputCorner.Parent = input

	return input
end

local cooldownInput = createInputRow("Despawn (sec):", bombCooldown, 2)
local delayInput = createInputRow("Delay / CD (sec):", clickDelay, 3)

local jumpBtn = Instance.new("TextButton")
jumpBtn.Size = UDim2.new(0, 160, 0, 24)
jumpBtn.BackgroundColor3 = themes[currentTheme].BtnBg
jumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpBtn.Font = Enum.Font.SourceSansBold
jumpBtn.TextSize = 12
jumpBtn.Text = "Jump on Use: ON"
jumpBtn.LayoutOrder = 4
jumpBtn.Parent = animCanvasGroup

local jumpCorner = Instance.new("UICorner")
jumpCorner.CornerRadius = UDim.new(0, 4)
jumpCorner.Parent = jumpBtn

-- ПЕРЕКЛЮЧАТЕЛЬ: Добавить кнопку на экран
local toggleExternalBtn = Instance.new("TextButton")
toggleExternalBtn.Size = UDim2.new(0, 160, 0, 24)
toggleExternalBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
toggleExternalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleExternalBtn.Font = Enum.Font.SourceSansBold
toggleExternalBtn.TextSize = 12
toggleExternalBtn.Text = "Show Screen BOMB: OFF"
toggleExternalBtn.LayoutOrder = 5
toggleExternalBtn.Parent = animCanvasGroup

local toggleExtCorner = Instance.new("UICorner")
toggleExtCorner.CornerRadius = UDim.new(0, 4)
toggleExtCorner.Parent = toggleExternalBtn

local themeBtn = Instance.new("TextButton")
themeBtn.Size = UDim2.new(0, 160, 0, 24)
themeBtn.BackgroundColor3 = themes[currentTheme].InputBg
themeBtn.TextColor3 = themes[currentTheme].Text
themeBtn.Font = Enum.Font.SourceSansBold
themeBtn.TextSize = 11
themeBtn.Text = themes[currentTheme].ToggleThemeText
themeBtn.LayoutOrder = 6
themeBtn.Parent = animCanvasGroup

local themeCorner = Instance.new("UICorner")
themeCorner.CornerRadius = UDim.new(0, 4)
themeCorner.Parent = themeBtn

----------------------------------------------------------------
-- ЕДИНАЯ ЛОГИКА ДВИЖЕНИЯ ВСЕГО БЛОКА КНОПОК
----------------------------------------------------------------
local dragging = false
local dragStart, startPos

-- Перетаскивание работает при зажатии BOMB, если откреплено
externalBombBtn.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not isPinned then
		dragging = true
		dragStart = input.Position
		startPos = bombContainer.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

externalBombBtn.InputChanged:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
		local delta = input.Position - dragStart
		bombContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Переключатель закрепа (ИСПРАВЛЕНО: Теперь фиксирует на текущем месте)
pinBtn.MouseButton1Down:Connect(function()
	isPinned = not isPinned
	if isPinned then
		pinBtn.Text = "📌"
		pinBtn.BackgroundColor3 = Color3.fromRGB(46, 125, 50) -- Зеленый (Блок зафиксирован)
		-- Помечаем, что кнопка была кастомно перетащена, чтобы анимация RenderStepped не сбрасывала её к дефолту меню
		bombContainer.Name = "CustomPinnedFrame" 
	else
		pinBtn.Text = "📍"
		pinBtn.BackgroundColor3 = Color3.fromRGB(198, 40, 40) -- Красный (Можно двигать куда угодно)
	end
end)

----------------------------------------------------------------
-- ПОЛНАЯ МЕХАНИКА ЗОЛОТОЙ БОМБЫ
----------------------------------------------------------------
local function giveGoldBomb()
	if not autoGiveEnabled then return nil end
	local backpack = localPlayer:WaitForChild("Backpack")
	local character = localPlayer.Character
	
	local existing = backpack:FindFirstChild("Gold C4 Block") or (character and character:FindFirstChild("Gold C4 Block"))
	if existing then return existing end
	
	local goldTool = Instance.new("Tool")
	goldTool.Name = "Gold C4 Block"
	setupBombLogic(goldTool)
	goldTool.Parent = backpack
	return goldTool
end

local function playPleasantSound(soundId, volume, pitch, parent)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. tostring(soundId)
	sound.Volume = volume or 0.8
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = parent or game.Workspace
	sound:Play()
	Debris:AddItem(sound, 3)
end

local function applyGoldTrail(part)
	local att0 = Instance.new("Attachment", part)
	att0.Position = Vector3.new(0, 0.3, 0)
	local att1 = Instance.new("Attachment", part)
	att1.Position = Vector3.new(0, -0.3, 0)
	
	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Texture = "rbxassetid://403448934"
	trail.Lifetime = 0.25
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Parent = part
end

local function createGoldC4Block(isStatic)
	local block = Instance.new("Part")
	block.Shape = Enum.PartType.Block
	block.Size = Vector3.new(1.6, 0.7, 1.2) 
	block.Color = Color3.fromRGB(255, 200, 40) 
	block.Material = Enum.Material.SmoothPlastic 
	block.Reflectance = 0.4 

	if isStatic then
		block.Anchored = false
		block.CanCollide = true
		
		local attachment = Instance.new("Attachment", block)
		local angularVelocity = Instance.new("AngularVelocity")
		angularVelocity.Attachment0 = attachment
		angularVelocity.MaxTorque = math.huge
		angularVelocity.AngularVelocity = Vector3.new(0, 12, 4) 
		angularVelocity.Parent = block
	else
		block.Massless = true
	end
	return block
end

local function createGoldSparkleParticles(parent)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://6231464309"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 30))
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.8, 0.4),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Speed = NumberRange.new(8, 20)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Gravity = Vector3.new(0, -2, 0)
	emitter.Drag = 1.5
	emitter.Parent = parent
	return emitter
end

local function executeBombDrop(character, humanoid, rootPart)
	canDropBomb = false
	
	local pitchShift = clickDelay < 0.1 and 1.5 or 1.2
	playPleasantSound(9114223171, 0.7, pitchShift, rootPart) 
	
	if jumpOnUse then
		humanoid.Jump = true
	end
	
	local currentCooldown = bombCooldown 
	local currentDelay = clickDelay
	
	local droppedBlock = createGoldC4Block(true)
	droppedBlock.Name = "DroppedVisualC4"
	
	-- Спавним строго ВНИЗУ ног игрока
	local spawnOffset = rootPart.CFrame * CFrame.new(0, -2.8, 0)
	droppedBlock.CFrame = spawnOffset
	droppedBlock.Parent = game.Workspace
	
	droppedBlock.Velocity = rootPart.Velocity + Vector3.new(0, -20, 0)
	applyGoldTrail(droppedBlock)

	task.spawn(function()
		local dissolveTime = math.min(0.3, currentCooldown)
		local waitTime = math.max(0, currentCooldown - dissolveTime)
		task.wait(waitTime)
		
		if droppedBlock and droppedBlock.Parent then
			local tweenInfo = TweenInfo.new(dissolveTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local tween = TweenService:Create(droppedBlock, tweenInfo, {Transparency = 1})
			tween:Play()
			
			local effectAnchor = Instance.new("Part")
			effectAnchor.Size = Vector3.new(1, 1, 1)
			effectAnchor.CFrame = droppedBlock.CFrame
			effectAnchor.Anchored = true
			effectAnchor.CanCollide = false
			effectAnchor.Transparency = 1
			effectAnchor.Parent = game.Workspace
			Debris:AddItem(effectAnchor, 1.2)
			
			playPleasantSound(9114160927, 0.7, pitchShift, effectAnchor)
			
			local sparkles = createGoldSparkleParticles(effectAnchor)
			sparkles:Emit(40)
		end
	end)

	Debris:AddItem(droppedBlock, currentCooldown)
	task.wait(currentDelay) 
	canDropBomb = true
end

function setupBombLogic(tool)
	tool.RequiresHandle = true
	local handle = createGoldC4Block(false)
	handle.Name = "Handle"
	handle.Parent = tool
	tool.Grip = CFrame.new(0, 0, 0)

	tool.Activated:Connect(function()
		local character = localPlayer.Character
		if not character or not canDropBomb then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		
		if humanoid and rootPart and humanoid.Health > 0 then
			executeBombDrop(character, humanoid, rootPart)
		end
	end)
end

local function forceUseBomb()
	local character = localPlayer.Character
	if not character or not canDropBomb then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end
	
	local backpack = localPlayer:WaitForChild("Backpack")
	local tool = character:FindFirstChild("Gold C4 Block") or backpack:FindFirstChild("Gold C4 Block")
	
	if not tool then
		tool = giveGoldBomb()
	end
	
	if tool then
		local originalParent = tool.Parent
		if originalParent ~= character then
			tool.Parent = character
		end
		
		executeBombDrop(character, humanoid, rootPart)
		
		task.defer(function()
			if tool and tool.Parent == character then
				tool.Parent = backpack
			end
		end)
	end
end

externalBombBtn.MouseButton1Down:Connect(function()
	forceUseBomb()
end)

toggleExternalBtn.MouseButton1Down:Connect(function()
	externalButtonEnabled = not externalButtonEnabled
	if externalButtonEnabled then
		toggleExternalBtn.Text = "Show Screen BOMB: ON"
		toggleExternalBtn.BackgroundColor3 = themes[currentTheme].BtnBg
		bombContainer.Visible = true
	else
		toggleExternalBtn.Text = "Show Screen BOMB: OFF"
		toggleExternalBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		bombContainer.Visible = false
	end
end)

----------------------------------------------------------------
-- АНИМАЦИИ ОТКРЫТИЯ МЕНЮ И НАСТРОЙКИ
----------------------------------------------------------------
toggleBtn.MouseButton1Down:Connect(function()
	menuOpen = not menuOpen
	local tInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local fadeInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	if menuOpen then
		TweenService:Create(mainFrame, tInfo, {Position = visiblePosition, BackgroundTransparency = 0}):Play()
		TweenService:Create(animCanvasGroup, fadeInfo, {GroupTransparency = 0}):Play()
		TweenService:Create(frameStroke, fadeInfo, {Transparency = 0}):Play()
	else
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = hiddenPosition, BackgroundTransparency = 1}):Play()
		TweenService:Create(animCanvasGroup, fadeInfo, {GroupTransparency = 1}):Play()
		TweenService:Create(frameStroke, fadeInfo, {Transparency = 1}):Play()
	end
end)

themeBtn.MouseButton1Down:Connect(function()
	currentTheme = (currentTheme == 1) and 2 or 1
	local cfg = themes[currentTheme]
	local tInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	TweenService:Create(mainFrame, tInfo, {BackgroundColor3 = cfg.MainBg}):Play()
	TweenService:Create(title, tInfo, {TextColor3 = cfg.Text}):Play()
	TweenService:Create(jumpBtn, tInfo, {BackgroundColor3 = cfg.BtnBg}):Play()
	TweenService:Create(externalBombBtn, tInfo, {BackgroundColor3 = cfg.BtnBg}):Play()
	TweenService:Create(themeBtn, tInfo, {BackgroundColor3 = cfg.InputBg, TextColor3 = cfg.Text}):Play()
	themeBtn.Text = cfg.ToggleThemeText
	
	if externalButtonEnabled then
		toggleExternalBtn.BackgroundColor3 = cfg.BtnBg
	end
	
	for _, inputUI in ipairs(inputsList) do
		TweenService:Create(inputUI, tInfo, {BackgroundColor3 = cfg.InputBg, TextColor3 = cfg.Text}):Play()
	end
	
	updateStrokeGradient()
end)

cooldownInput.FocusLost:Connect(function()
	local num = tonumber(cooldownInput.Text)
	if num and num >= 0 then bombCooldown = num else cooldownInput.Text = tostring(bombCooldown) end
end)

delayInput.FocusLost:Connect(function()
	local num = tonumber(delayInput.Text)
	if num and num >= 0 then clickDelay = num else delayInput.Text = tostring(clickDelay) end
end)

jumpBtn.MouseButton1Down:Connect(function()
	jumpOnUse = not jumpOnUse
	if jumpOnUse then
		jumpBtn.Text = "Jump on Use: ON"
		jumpBtn.BackgroundColor3 = themes[currentTheme].BtnBg
	else
		jumpBtn.Text = "Jump on Use: OFF"
		jumpBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	end
end)

localPlayer.CharacterAdded:Connect(function()
	task.wait(0.8) 
	giveGoldBomb()
end)

if localPlayer.Character then 
	giveGoldBomb() 
end
