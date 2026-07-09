local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
while not player do task.wait(); player = Players.LocalPlayer end

-- БЕЗОПАСНЫЙ ПОИСК ДОСТУПНОГО КОНТЕЙНЕРА ДЛЯ GUI
local targetGui = nil
local success, err = pcall(function()
    if gethui then
        targetGui = gethui()
    elseif game:GetService("CoreGui"):FindFirstChild("RobloxGui") then
        targetGui = game:GetService("CoreGui")
    end
end)

if not targetGui then
    targetGui = player:WaitForChild("PlayerGui", 10)
end

if not targetGui then
    targetGui = player:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui")
end

-- Очистка старых копий
if targetGui:FindFirstChild("CustomRainbowCursor2026") then
    targetGui["CustomRainbowCursor2026"]:Destroy()
end

pcall(function() UserInputService.MouseIconEnabled = false end)
pcall(function() player.DevEnableMouseLock = true end)

-- СИСТЕМА ПРИЯТНЫХ ЗВУКОВ
local function playSound(soundType)
    local sound = Instance.new("Sound")
    sound.Volume = 0.5
    sound.PlayOnRemove = true
    
    if soundType == "click" then
        sound.SoundId = "rbxassetid://8535914611" -- Мягкий клик интерфейса
        sound.PlaybackSpeed = 1.1
    elseif soundType == "hover" then
        sound.SoundId = "rbxassetid://6803473187" -- Очень тихий, аккуратный шорох при наведении
        sound.Volume = 0.15
        sound.PlaybackSpeed = 1.4
    elseif soundType == "toggle" then
        sound.SoundId = "rbxassetid://8535914611" -- Открытие/закрытие меню
        sound.PlaybackSpeed = 0.85
        sound.Volume = 0.6
    elseif soundType == "select" then
        sound.SoundId = "rbxassetid://6836371720" -- Выбор элемента в дропдауне
        sound.PlaybackSpeed = 1.2
    end
    
    sound.Parent = SoundService
    sound:Destroy()
end

-- ОСНОВНОЙ GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomRainbowCursor2026"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 99999
screenGui.Parent = targetGui

-- НАСТРОЙКИ ПО УМОЛЧАНИЮ
local currentLang = "RU" 
local colorMode = "BlueCyan" 
local bgMode = "Space" 
local bgSpeed = 1.0    
local isRotating = true
local targetRotation = 0
local isLocked = false
local rotationSpeed = 60

local crosshairType = "Cross" 
local crosshairEnabled = true  
local textEnabled = true       

local thickness = 3          
local length = 14             
local offset = 10             
local currentText = "Yurei.win" 

local fontList = {Enum.Font.GothamBold, Enum.Font.FredokaOne, Enum.Font.Arcade, Enum.Font.SciFi, Enum.Font.Highway, Enum.Font.LuckiestGuy}
local fontNames = {"Gotham Bold", "Fredoka One", "Arcade Retro", "Sci-Fi Future", "Highway Sign", "Luckiest Guy"}
local currentFontIndex = 1

local useOutline = true
local outlineThickness = 1
local useCenterDot = true
local centerDotSize = 4
local rainbowMenuUi = true

-- Список всех палитр для выпадающего меню (РАСШИРЕННЫЙ)
local colorPalettes = {
    {ID = "BlueCyan", Name = "Blue ⇄ Cyan 💎"},
    {ID = "NeonMint", Name = "Neon Mint 🍃"},
    {ID = "CosmicSakura", Name = "Cosmic Sakura 🌸"},
    {ID = "AcidLime", Name = "Acid Lime 🔋"},
    {ID = "DeepOcean", Name = "Deep Ocean 🌊"},
    {ID = "GoldYellow", Name = "Gold ⇄ Yellow 👑"},
    {ID = "SunsetGlow", Name = "Sunset Glow 🌅"},
    {ID = "PurpleMagic", Name = "Purple Magic ✨"},
    {ID = "IceBlizzard", Name = "Ice Blizzard ❄️"},
    {ID = "CyberPunk", Name = "Cyber Punk 🦾"},
    {ID = "ToxicBlood", Name = "Toxic Blood 🩸"},
    {ID = "VampireMyth", Name = "Vampire Myth 🧛"},
    {ID = "ElectricVoid", Name = "Electric Void ⚡"},
    {ID = "AtomicWaste", Name = "Atomic Waste ☢️"},
    {ID = "GhostVapor", Name = "Ghost Vapor 🌫️"},
    {ID = "CaramelLatte", Name = "Caramel Latte ☕"},
    {ID = "MilkyWay", Name = "Milky Way 🌌"},
    {ID = "DesertMirage", Name = "Desert Mirage 🏜️"},
    {ID = "JungleMoss", Name = "Jungle Moss 🌿"},
    {ID = "Rainbow", Name = "RGB Rainbow 🌈"}
}

-- КОНТЕЙНЕР ПРИЦЕЛА
local crosshairContainer = Instance.new("Frame")
crosshairContainer.BackgroundTransparency = 1
crosshairContainer.Size = UDim2.new(0, 150, 0, 150)
crosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairContainer.Parent = screenGui

local visualElements = {}
local centerDotInstance = nil

local function rebuildCrosshair()
    for _, obj in ipairs(visualElements) do obj:Destroy() end
    visualElements = {}
    if centerDotInstance then centerDotInstance:Destroy(); centerDotInstance = nil end

    crosshairContainer.Visible = crosshairEnabled
    if not crosshairEnabled then return end

    if useCenterDot then
        centerDotInstance = Instance.new("Frame")
        centerDotInstance.Name = "CenterDot"
        centerDotInstance.Size = UDim2.new(0, centerDotSize, 0, centerDotSize)
        centerDotInstance.Position = UDim2.new(0.5, 0, 0.5, 0)
        centerDotInstance.AnchorPoint = Vector2.new(0.5, 0.5)
        centerDotInstance.BorderSizePixel = 0
        centerDotInstance.ZIndex = 5
        centerDotInstance.Parent = crosshairContainer
        
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = centerDotInstance

        if useOutline then
            local dotStroke = Instance.new("UIStroke")
            dotStroke.Thickness = outlineThickness
            dotStroke.Color = Color3.fromRGB(0, 0, 0)
            dotStroke.Parent = centerDotInstance
        end
    end

    if crosshairType == "Cross" then
        local lineDefs = {
            {size = UDim2.new(0, thickness, 0, length), pos = UDim2.new(0.5, 0, 0.5, -offset - length/2)},
            {size = UDim2.new(0, thickness, 0, length), pos = UDim2.new(0.5, 0, 0.5, offset + length/2)},
            {size = UDim2.new(0, length, 0, thickness), pos = UDim2.new(0.5, -offset - length/2, 0.5, 0)},
            {size = UDim2.new(0, length, 0, thickness), pos = UDim2.new(0.5, offset + length/2, 0.5, 0)}
        }
        for _, def in ipairs(lineDefs) do
            local line = Instance.new("Frame")
            line.Name = "MainLine"
            line.Size = def.size
            line.Position = def.pos
            line.AnchorPoint = Vector2.new(0.5, 0.5)
            line.BorderSizePixel = 0
            line.ZIndex = 4
            line.Parent = crosshairContainer
            if useOutline then
                local stroke = Instance.new("UIStroke")
                stroke.Thickness = outlineThickness
                stroke.Color = Color3.fromRGB(0, 0, 0)
                stroke.Parent = line
            end
            table.insert(visualElements, line)
        end

    elseif crosshairType == "Box" then
        local boxSize = (offset * 2) + length
        local boxFrame = Instance.new("Frame")
        boxFrame.Name = "ContainerFrame"
        boxFrame.Size = UDim2.new(0, boxSize, 0, boxSize)
        boxFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        boxFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        boxFrame.BackgroundTransparency = 1
        boxFrame.ZIndex = 4
        boxFrame.Parent = crosshairContainer

        local mainStroke = Instance.new("UIStroke")
        mainStroke.Name = "MainStroke"
        mainStroke.Thickness = thickness
        mainStroke.Color = Color3.fromRGB(255, 255, 255)
        mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        mainStroke.Parent = boxFrame

        if useOutline then
            local outStroke = Instance.new("UIStroke")
            outStroke.Name = "OutlineStroke"
            outStroke.Thickness = thickness + (outlineThickness * 2)
            outStroke.Color = Color3.fromRGB(0, 0, 0)
            outStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            outStroke.Parent = boxFrame
            mainStroke.ZIndex = 2
        end
        table.insert(visualElements, boxFrame)

    elseif crosshairType == "Circle" then
        local circleSize = (offset * 2) + length
        local circleFrame = Instance.new("Frame")
        circleFrame.Name = "ContainerFrame"
        circleFrame.Size = UDim2.new(0, circleSize, 0, circleSize)
        circleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        circleFrame.BackgroundTransparency = 1
        circleFrame.ZIndex = 4
        circleFrame.Parent = crosshairContainer

        local roundCorner = Instance.new("UICorner")
        roundCorner.CornerRadius = UDim.new(1, 0)
        roundCorner.Parent = circleFrame

        local mainStroke = Instance.new("UIStroke")
        mainStroke.Name = "MainStroke"
        mainStroke.Thickness = thickness
        mainStroke.Color = Color3.fromRGB(255, 255, 255)
        mainStroke.Parent = circleFrame

        if useOutline then
            local outStroke = Instance.new("UIStroke")
            outStroke.Name = "OutlineStroke"
            outStroke.Thickness = thickness + (outlineThickness * 2)
            outStroke.Color = Color3.fromRGB(0, 0, 0)
            outStroke.Parent = circleFrame
            mainStroke.ZIndex = 2
        end
        table.insert(visualElements, circleFrame)
    end
end
rebuildCrosshair()

-- НАДПИСЬ ПОД ПРИЦЕЛАМИ
local textLabel = Instance.new("TextLabel")
textLabel.Text = currentText
textLabel.Size = UDim2.new(0, 200, 0, 30)
textLabel.AnchorPoint = Vector2.new(0.5, 0)
textLabel.BackgroundTransparency = 1
textLabel.Font = fontList[currentFontIndex]
textLabel.TextSize = 17              
textLabel.TextStrokeTransparency = 0.5 
textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
textLabel.Visible = textEnabled
textLabel.Parent = screenGui

local function updateTextPos()
    textLabel.Position = UDim2.new(0.5, 0, 0.5, offset + length + 15)
end
updateTextPos()

-- СЛОВАРЬ ПЕРЕВОДОВ
local langTable = {
    RU = {
        tab_main = "🏠 Главное", tab_shape = "📐 Форма", tab_colors = "🎨 Цвета", tab_configs = "📁 Конфиги", tab_settings = "⚙️ Опции",
        head_text = "НАСТРОЙКА ТЕКСТА И ФОРМЫ ПРИЦЕЛА", placeholder_text = "Напиши ник...", head_rot = "РЕЖИМЫ ВРАЩЕНИЯ",
        btn_rot = "Постоянное вращение 🔄", btn_angle = "Угол: ", head_size = "ГЕОМЕТРИЯ ПРИЦЕЛА И ДЕТАЛИ",
        btn_thick_p = "Толщина +", btn_thick_m = "Толщина -", btn_len_p = "Длина/Радиус +", btn_len_m = "Длина/Радиус -",
        head_geo = "ЗАЗОРЫ И СКОРОСТЬ ВРАЩЕНИЯ", btn_gap_p = "Зазор +", btn_gap_m = "Зазор -", btn_speed_p = "Скорость +", btn_speed_m = "Скорость -",
        head_pal = "ВЫБОР ЦВЕТОВОЙ ПАЛИТРЫ ПРИЦЕЛА", head_cfg = "СОХРАНЕНИЕ И ЗАГРУЗКА НАСТРОЕК", placeholder_cfg = "Имя конфига...",
        btn_save = "💾 Сохранить конфиг", btn_load = "📂 Загрузить конфиг", head_security = "БЕЗОПАСНОСТЬ И ОФОРМЛЕНИЕ МЕНЮ",
        btn_lock_u = "Кнопка меню: Разблокирована 🔓", btn_lock_l = "Кнопка меню: Заблокирована 🔒",
        btn_bg = "Фон меню: ", btn_bgspeed = "Скорость фона: ",
        btn_outline = "Обводка линий: ", btn_out_thick = "Толщина обводки: ",
        btn_dot = "Центральная точка: ", btn_dot_size = "Размер точки: ",
        btn_rainbow_ui = "Подсветка меню: ", btn_font = "Шрифт текста: ",
        btn_type = "Тип прицела: ",
        btn_cross_toggle = "Прицел: ", btn_text_toggle = "Надпись: ",
        msg_no_files = "❌ Нет доступа", msg_saved = "✅ Сохранено!", msg_loaded = "✅ Загружено!", msg_err = "❌ Ошибка",
        dropdown_title = "Выбрать цвет: "
    },
    EN = {
        tab_main = "🏠 Main", tab_shape = "📐 Shape", tab_colors = "🎨 Colors", tab_configs = "📁 Configs", tab_settings = "⚙️ Settings",
        head_text = "CROSSHAIR TEXT & TYPE SETTING", placeholder_text = "Type text...", head_rot = "CROSSHAIR ROTATION MODES",
        btn_rot = "Constant Rotation 🔄", btn_angle = "Angle: ", head_size = "CROSSHAIR GEOMETRY & DETAILS",
        btn_thick_p = "Thickness +", btn_thick_m = "Thickness -", btn_len_p = "Length/Radius +", btn_len_m = "Length/Radius -",
        head_geo = "GAP & ROTATION SPEED", btn_gap_p = "Gap +", btn_gap_m = "Gap -", btn_speed_p = "Speed +", btn_speed_m = "Speed -",
        head_pal = "SELECT CROSSHAIR COLOR PALETTE", head_cfg = "CONFIG SAVE & MANAGEMENT", placeholder_cfg = "Config name...",
        btn_save = "💾 Save Config", btn_load = "📂 Load Config", head_security = "SECURITY & MENU VISUALS",
        btn_lock_u = "Menu Button: Unlocked 🔓", btn_lock_l = "Menu Button: Locked 🔒",
        btn_bg = "Menu BG: ", btn_bgspeed = "BG Speed: ",
        btn_outline = "Crosshair Outline: ", btn_out_thick = "Outline Thick: ",
        btn_dot = "Center Dot: ", btn_dot_size = "Dot Size: ",
        btn_rainbow_ui = "Rainbow Menu Border: ", btn_font = "Text Font: ",
        btn_type = "Crosshair Type: ",
        btn_cross_toggle = "Crosshair: ", btn_text_toggle = "Text Label: ",
        msg_no_files = "❌ No File Access", msg_saved = "✅ Saved!", msg_loaded = "✅ Loaded!", msg_err = "❌ Error",
        dropdown_title = "Select Color: "
    }
}

-- КНОПКА ОТКРЫТИЯ МЕНЮ (⚙️)
local menuToggle = Instance.new("TextButton")
menuToggle.Size = UDim2.new(0, 55, 0, 55)
menuToggle.Position = UDim2.new(0, 30, 0, 150)
menuToggle.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
menuToggle.Text = "⚙️"
menuToggle.TextSize = 24
menuToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
menuToggle.AutoButtonColor = false
menuToggle.ZIndex = 10
menuToggle.Parent = screenGui

local toggleCorner = Instance.new("UICorner"); toggleCorner.CornerRadius = UDim.new(1, 0); toggleCorner.Parent = menuToggle
local toggleStroke = Instance.new("UIStroke"); toggleStroke.Thickness = 1.5; toggleStroke.Color = Color3.fromRGB(60, 60, 75); toggleStroke.Parent = menuToggle

-- ОКНО МЕНЮ (680x480)
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 680, 0, 480)
menuFrame.Position = UDim2.new(0.5, -340, 0.5, -240)
menuFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 14)
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.Active = true 
menuFrame.ClipsDescendants = false 
menuFrame.ZIndex = 8
menuFrame.Parent = screenGui

local bgUIGradient = Instance.new("UIGradient")
bgUIGradient.Rotation = 45
bgUIGradient.Parent = menuFrame

local menuCorner = Instance.new("UICorner"); menuCorner.CornerRadius = UDim.new(0, 14); menuCorner.Parent = menuFrame
local menuStroke = Instance.new("UIStroke"); menuStroke.Thickness = 1.5; menuStroke.Color = Color3.fromRGB(50, 50, 60); menuStroke.Parent = menuFrame

local tabScroller = Instance.new("ScrollingFrame")
tabScroller.Size = UDim2.new(1, -30, 0, 44)
tabScroller.Position = UDim2.new(0, 15, 0, 15)
tabScroller.BackgroundTransparency = 1
tabScroller.CanvasSize = UDim2.new(0, 650, 0, 0)
tabScroller.ScrollBarThickness = 0
tabScroller.ScrollingDirection = Enum.ScrollingDirection.X
tabScroller.ZIndex = 9
tabScroller.Parent = menuFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = tabScroller

local container = Instance.new("Frame")
container.Size = UDim2.new(1, -30, 1, -85)
container.Position = UDim2.new(0, 15, 0, 70)
container.BackgroundTransparency = 1
container.ZIndex = 8
container.Parent = menuFrame

local function makeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not isLocked then
            dragging = true; dragStart = input.Position; startPos = guiObject.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    guiObject.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) 
        if input == dragInput and dragging and not isLocked then 
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end 
    end)
end
makeDraggable(menuToggle); makeDraggable(menuFrame)

local tabs = {}
local function createTabFrame(useGrid)
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, 0, 1, 0); frame.BackgroundTransparency = 1; frame.BorderSizePixel = 0
    frame.CanvasSize = UDim2.new(0, 0, 0, 520); frame.ScrollBarThickness = 3; frame.ScrollBarImageColor3 = Color3.fromRGB(75, 75, 90)
    frame.ZIndex = 8; frame.Visible = false; frame.ClipsDescendants = false 
    frame.Parent = container
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 2); padding.PaddingRight = UDim.new(0, 6); padding.PaddingTop = UDim.new(0, 4)
    padding.Parent = frame

    if useGrid then
        local grid = Instance.new("UIGridLayout")
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        grid.CellSize = UDim2.new(0.5, -6, 0, 38)
        grid.CellPadding = UDim2.new(0, 12, 0, 10)
        grid.Parent = frame
    else
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 10)
        layout.Parent = frame
    end
    return frame
end

local function createMenuButton(layoutOrder, parent)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 13; btn.TextColor3 = Color3.fromRGB(215, 215, 220); btn.AutoButtonColor = false; btn.ZIndex = 9; btn.LayoutOrder = layoutOrder; btn.Parent = parent
    local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(0, 6); btnCorner.Parent = btn
    local btnStroke = Instance.new("UIStroke"); btnStroke.Thickness = 1; btnStroke.Color = Color3.fromRGB(40, 40, 50); btnStroke.Parent = btn

    btn.MouseEnter:Connect(function()
        playSound("hover")
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30, 30, 38)}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.12), {Color = Color3.fromRGB(65, 65, 80)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(20, 20, 25)}):Play()
        TweenService:Create(btnStroke, TweenInfo.new(0.12), {Color = Color3.fromRGB(40, 40, 50)}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        playSound("click")
    end)
    return btn
end

local function createMenuTextBox(layoutOrder, parent)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 38)
    box.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    box.Font = Enum.Font.GothamBold; box.TextSize = 13; box.TextColor3 = Color3.fromRGB(255, 255, 255); box.ClearTextOnFocus = false; box.ZIndex = 9; box.LayoutOrder = layoutOrder; box.Parent = parent
    local boxCorner = Instance.new("UICorner"); boxCorner.CornerRadius = UDim.new(0, 6); boxCorner.Parent = box
    local boxStroke = Instance.new("UIStroke"); boxStroke.Thickness = 1; boxStroke.Color = Color3.fromRGB(55, 55, 65); boxStroke.Parent = box
    return box
end

local function createTabButton(layoutOrder, tabFrame, tabKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 118, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    btn.BackgroundTransparency = 0.4
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 13; btn.TextColor3 = Color3.fromRGB(130, 130, 140); btn.ZIndex = 9; btn.LayoutOrder = layoutOrder; btn.Parent = tabScroller
    local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(0, 6); btnCorner.Parent = btn
    local btnStroke = Instance.new("UIStroke"); btnStroke.Thickness = 1; btnStroke.Color = Color3.fromRGB(38, 38, 48); btnStroke.Parent = btn

    btn.MouseEnter:Connect(function() playSound("hover") end)
    btn.MouseButton1Click:Connect(function()
        playSound("click")
        for _, t in ipairs(tabs) do 
            t.Frame.Visible = false; t.Btn.TextColor3 = Color3.fromRGB(130, 130, 140); 
            TweenService:Create(t.Btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.4, BackgroundColor3 = Color3.fromRGB(20, 20, 26)}):Play()
        end
        tabFrame.Visible = true; btn.TextColor3 = Color3.fromRGB(255, 255, 255); 
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(32, 32, 42)}):Play()
    end)
    table.insert(tabs, {Frame = tabFrame, Btn = btn, Key = tabKey})
end

local headers = {}
local function createHeader(layoutOrder, parent, key, fullWidthGrid)
    local containerFrame = Instance.new("Frame")
    containerFrame.Size = fullWidthGrid and UDim2.new(1, 6, 0, 24) or UDim2.new(1, 0, 0, 24)
    containerFrame.BackgroundTransparency = 1; containerFrame.LayoutOrder = layoutOrder; containerFrame.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.TextColor3 = Color3.fromRGB(150, 150, 165)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 9; lbl.Parent = containerFrame
    table.insert(headers, {Instance = lbl, Key = key})
end

local frameMain = createTabFrame(true)
local frameShape = createTabFrame(true)
local frameColors = createTabFrame(false) 
local frameConfigs = createTabFrame(false)
local frameSettings = createTabFrame(true)

createTabButton(1, frameMain, "tab_main")
createTabButton(2, frameShape, "tab_shape")
createTabButton(3, frameColors, "tab_colors")
createTabButton(4, frameConfigs, "tab_configs")
createTabButton(5, frameSettings, "tab_settings")

createHeader(1, frameMain, "head_text", true)
local inputNick = createMenuTextBox(2, frameMain)
local bFontToggle = createMenuButton(3, frameMain)
local bTypeToggle = createMenuButton(4, frameMain) 

createHeader(5, frameMain, "head_rot", true)
local bRot = createMenuButton(6, frameMain)
local b20 = createMenuButton(7, frameMain)
local b40 = createMenuButton(8, frameMain)
local b60 = createMenuButton(9, frameMain)
local b90 = createMenuButton(10, frameMain)

createHeader(1, frameShape, "head_size", true)
local bThickPlus = createMenuButton(2, frameShape)
local bThickMinus = createMenuButton(3, frameShape)
local bLenPlus = createMenuButton(4, frameShape)
local bLenMinus = createMenuButton(5, frameShape)
local bOutlineToggle = createMenuButton(6, frameShape)
local bOutlineThick = createMenuButton(7, frameShape)
local bDotToggle = createMenuButton(8, frameShape)
local bDotSizeToggle = createMenuButton(9, frameShape)

createHeader(10, frameShape, "head_geo", true)
local bGapPlus = createMenuButton(11, frameShape)
local bGapMinus = createMenuButton(12, frameShape)
local bSpeedPlus = createMenuButton(13, frameShape)
local bSpeedMinus = createMenuButton(14, frameShape)

-- ТАБ ЦВЕТОВ
createHeader(1, frameColors, "head_pal", false)

local dropdownContainer = Instance.new("Frame")
dropdownContainer.Size = UDim2.new(1, 0, 0, 42)
dropdownContainer.BackgroundTransparency = 1
dropdownContainer.LayoutOrder = 2
dropdownContainer.ZIndex = 50 
dropdownContainer.Parent = frameColors

local dropdownMainButton = Instance.new("TextButton")
dropdownMainButton.Size = UDim2.new(1, 0, 1, 0)
dropdownMainButton.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
dropdownMainButton.Font = Enum.Font.GothamBold
dropdownMainButton.TextSize = 14
dropdownMainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
dropdownMainButton.TextXAlignment = Enum.TextXAlignment.Left
dropdownMainButton.AutoButtonColor = false
dropdownMainButton.ZIndex = 51
dropdownMainButton.Parent = dropdownContainer

local dropdownPadding = Instance.new("UIPadding")
dropdownPadding.PaddingLeft = UDim.new(0, 12)
dropdownPadding.Parent = dropdownMainButton

local dropdownCorner = Instance.new("UICorner"); dropdownCorner.CornerRadius = UDim.new(0, 6); dropdownCorner.Parent = dropdownMainButton
local dropdownStroke = Instance.new("UIStroke"); dropdownStroke.Thickness = 1.2; dropdownStroke.Color = Color3.fromRGB(55, 55, 70); dropdownStroke.Parent = dropdownMainButton

local dropdownArrow = Instance.new("TextLabel")
dropdownArrow.Size = UDim2.new(0, 30, 1, 0)
dropdownArrow.Position = UDim2.new(1, -40, 0, 0)
dropdownArrow.BackgroundTransparency = 1
dropdownArrow.Text = "▼"
dropdownArrow.TextColor3 = Color3.fromRGB(150, 150, 160)
dropdownArrow.Font = Enum.Font.GothamBold
dropdownArrow.TextSize = 12
dropdownArrow.ZIndex = 52
dropdownArrow.Parent = dropdownMainButton

local dropdownListScroller = Instance.new("ScrollingFrame")
dropdownListScroller.Size = UDim2.new(1, 0, 0, 220)
dropdownListScroller.Position = UDim2.new(0, -12, 1, 5) 
dropdownListScroller.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
dropdownListScroller.Visible = false
dropdownListScroller.ZIndex = 60
dropdownListScroller.CanvasSize = UDim2.new(0, 0, 0, #colorPalettes * 34 + 10)
dropdownListScroller.ScrollBarThickness = 4
dropdownListScroller.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
dropdownListScroller.Parent = dropdownMainButton

local listCorner = Instance.new("UICorner"); listCorner.CornerRadius = UDim.new(0, 6); listCorner.Parent = dropdownListScroller
local listStroke = Instance.new("UIStroke"); listStroke.Thickness = 1; listStroke.Color = Color3.fromRGB(45, 45, 55); listStroke.Parent = dropdownListScroller

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 2)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = dropdownListScroller

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 5); listPadding.PaddingBottom = UDim.new(0, 5)
listPadding.PaddingLeft = UDim.new(0, 6); listPadding.PaddingRight = UDim.new(0, 6)
listPadding.Parent = dropdownListScroller

local function getPaletteName(id)
    for _, item in ipairs(colorPalettes) do
        if item.ID == id then return item.Name end
    end
    return tostring(id)
end

local dropdownOpen = false
local function toggleDropdown()
    dropdownOpen = not dropdownOpen
    dropdownListScroller.Visible = dropdownOpen
    dropdownArrow.Text = dropdownOpen and "▲" or "▼"
    playSound("click")
end
dropdownMainButton.MouseButton1Click:Connect(toggleDropdown)
dropdownMainButton.MouseEnter:Connect(function() playSound("hover") end)

-- ЗАПОЛНЕНИЕ ДРОПДАУНА ЭЛЕМЕНТАМИ
for i, palette in ipairs(colorPalettes) do
    local itemBtn = Instance.new("TextButton")
    itemBtn.Size = UDim2.new(1, 0, 0, 32)
    itemBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    itemBtn.BackgroundTransparency = 1
    itemBtn.Font = Enum.Font.GothamBold
    itemBtn.TextSize = 13
    itemBtn.TextColor3 = Color3.fromRGB(200, 200, 205)
    itemBtn.TextXAlignment = Enum.TextXAlignment.Left
    itemBtn.Text = palette.Name
    itemBtn.ZIndex = 62
    itemBtn.LayoutOrder = i
    itemBtn.Parent = dropdownListScroller
    
    local itemPadding = Instance.new("UIPadding"); itemPadding.PaddingLeft = UDim.new(0, 8); itemPadding.Parent = itemBtn
    local itemCorner = Instance.new("UICorner"); itemCorner.CornerRadius = UDim.new(0, 4); itemCorner.Parent = itemBtn

    itemBtn.MouseEnter:Connect(function()
        playSound("hover")
        itemBtn.BackgroundTransparency = 0
        itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    itemBtn.MouseLeave:Connect(function()
        itemBtn.BackgroundTransparency = 1
        itemBtn.TextColor3 = Color3.fromRGB(200, 200, 205)
    end)
    itemBtn.MouseButton1Click:Connect(function()
        colorMode = palette.ID
        playSound("select")
        dropdownOpen = false
        dropdownListScroller.Visible = false
        dropdownArrow.Text = "▼"
        local ln = langTable[currentLang]
        dropdownMainButton.Text = ln.dropdown_title .. palette.Name
    end)
end

-- ТАБЫ КОНФИГОВ И НАСТРОЕК
createHeader(1, frameConfigs, "head_cfg", false)
local configNameInput = createMenuTextBox(2, frameConfigs)
local bSaveConfig = createMenuButton(3, frameConfigs)
local bLoadConfig = createMenuButton(4, frameConfigs)

createHeader(1, frameSettings, "head_security", true)
local bLock = createMenuButton(2, frameSettings)
local bLangToggle = createMenuButton(3, frameSettings) 
local bBgToggle = createMenuButton(4, frameSettings)     
local bBgSpeedToggle = createMenuButton(5, frameSettings) 
local bRainbowUiToggle = createMenuButton(6, frameSettings) 
local bCrosshairToggleBtn = createMenuButton(7, frameSettings) 
local bTextToggleBtn = createMenuButton(8, frameSettings)      

local allBackgrounds = {
    "Dark", "Space", "Matrix", "Pulse", "CyberPunk", 
    "Inferno", "ToxicSlime", "Glitch", "SynthWave", "Emerald", 
    "MonoNight", "SakuraBlossom", "Amethyst", "Frostbite", "Volcanic",
    "Nebula", "CyberSpace", "NordicFrost", "CrimsonVoid", "ToxicNeon"
}

local function refreshLocalization()
    local ln = langTable[currentLang]
    for _, tab in ipairs(tabs) do tab.Btn.Text = ln[tab.Key] end
    for _, head in ipairs(headers) do head.Instance.Text = ln[head.Key] end
    
    inputNick.PlaceholderText = ln.placeholder_text
    inputNick.Text = currentText
    configNameInput.PlaceholderText = ln.placeholder_cfg
    
    bFontToggle.Text = ln.btn_font .. fontNames[currentFontIndex]
    bTypeToggle.Text = ln.btn_type .. tostring(crosshairType)
    
    bRot.Text = ln.btn_rot
    b20.Text = ln.btn_angle .. "20°"
    b40.Text = ln.btn_angle .. "40°"
    b60.Text = ln.btn_angle .. "60°"
    b90.Text = ln.btn_angle .. "90°"
    
    bThickPlus.Text = ln.btn_thick_p; bThickMinus.Text = ln.btn_thick_m
    bLenPlus.Text = ln.btn_len_p; bLenMinus.Text = ln.btn_len_m
    bGapPlus.Text = ln.btn_gap_p; bGapMinus.Text = ln.btn_gap_m
    bSpeedPlus.Text = ln.btn_speed_p; bSpeedMinus.Text = ln.btn_speed_m
    
    bSaveConfig.Text = ln.btn_save; bLoadConfig.Text = ln.btn_load
    
    bLangToggle.Text = "🌐 Language: " .. currentLang
    bBgToggle.Text = ln.btn_bg .. tostring(bgMode)
    bBgSpeedToggle.Text = ln.btn_bgspeed .. tostring(bgSpeed) .. "x"
    if isLocked then bLock.Text = ln.btn_lock_l else bLock.Text = ln.btn_lock_u end

    bOutlineToggle.Text = ln.btn_outline .. (useOutline and "ON ✅" or "OFF ❌")
    bOutlineThick.Text = ln.btn_out_thick .. tostring(outlineThickness) .. "px"
    bDotToggle.Text = ln.btn_dot .. (useCenterDot and "ON ✅" or "OFF ❌")
    bDotSizeToggle.Text = ln.btn_dot_size .. tostring(centerDotSize) .. "px"
    bRainbowUiToggle.Text = ln.btn_rainbow_ui .. (rainbowMenuUi and "ON ✅" or "OFF ❌")
    
    bCrosshairToggleBtn.Text = ln.btn_cross_toggle .. (crosshairEnabled and "ON ✅" or "OFF ❌")
    bTextToggleBtn.Text = ln.btn_text_toggle .. (textEnabled and "ON ✅" or "OFF ❌")

    dropdownMainButton.Text = ln.dropdown_title .. getPaletteName(colorMode)
end

bCrosshairToggleBtn.MouseButton1Click:Connect(function()
    crosshairEnabled = not crosshairEnabled
    rebuildCrosshair()
    refreshLocalization()
end)

bTextToggleBtn.MouseButton1Click:Connect(function()
    textEnabled = not textEnabled
    textLabel.Visible = textEnabled
    refreshLocalization()
end)

bTypeToggle.MouseButton1Click:Connect(function()
    if crosshairType == "Cross" then crosshairType = "Box" elseif crosshairType == "Box" then crosshairType = "Circle" else crosshairType = "Cross" end
    rebuildCrosshair(); refreshLocalization()
end)

bFontToggle.MouseButton1Click:Connect(function()
    currentFontIndex = currentFontIndex + 1
    if currentFontIndex > #fontList then currentFontIndex = 1 end
    textLabel.Font = fontList[currentFontIndex]
    refreshLocalization()
end)

bOutlineToggle.MouseButton1Click:Connect(function() useOutline = not useOutline; rebuildCrosshair(); refreshLocalization() end)
bOutlineThick.MouseButton1Click:Connect(function() outlineThickness = (outlineThickness == 1) and 2 or 1; rebuildCrosshair(); refreshLocalization() end)
bDotToggle.MouseButton1Click:Connect(function() useCenterDot = not useCenterDot; rebuildCrosshair(); refreshLocalization() end)
bDotSizeToggle.MouseButton1Click:Connect(function()
    if centerDotSize == 4 then centerDotSize = 6 elseif centerDotSize == 6 then centerDotSize = 2 else centerDotSize = 4 end
    rebuildCrosshair(); refreshLocalization()
end)

bBgToggle.MouseButton1Click:Connect(function()
    local currentIndex = 1
    for i, v in ipairs(allBackgrounds) do if v == bgMode then currentIndex = i; break end end
    currentIndex = currentIndex + 1
    if currentIndex > #allBackgrounds then currentIndex = 1 end
    bgMode = allBackgrounds[currentIndex]
    refreshLocalization()
end)

bBgSpeedToggle.MouseButton1Click:Connect(function()
    if bgSpeed == 1.0 then bgSpeed = 2.0 elseif bgSpeed = 2.0 then bgSpeed = 0.5 else bgSpeed = 1.0 end
    refreshLocalization()
end)

bRainbowUiToggle.MouseButton1Click:Connect(function()
    rainbowMenuUi = not rainbowMenuUi
    if not rainbowMenuUi then toggleStroke.Color = Color3.fromRGB(60, 60, 75) end
    refreshLocalization()
end)

bLangToggle.MouseButton1Click:Connect(function() currentLang = (currentLang == "RU") and "EN" or "RU"; refreshLocalization() end)

frameMain.Visible = true
tabs[1].Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
tabs[1].Btn.BackgroundTransparency = 0
tabs[1].Btn.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
configNameInput.Text = "MyConfig1"
refreshLocalization()

inputNick.FocusLost:Connect(function() currentText = inputNick.Text; textLabel.Text = currentText end)
bThickPlus.MouseButton1Click:Connect(function() thickness = math.clamp(thickness + 1, 1, 15); rebuildCrosshair() end)
bThickMinus.MouseButton1Click:Connect(function() thickness = math.clamp(thickness - 1, 1, 15); rebuildCrosshair() end)
bLenPlus.MouseButton1Click:Connect(function() length = math.clamp(length + 2, 2, 100); rebuildCrosshair(); updateTextPos() end)
bLenMinus.MouseButton1Click:Connect(function() length = math.clamp(length - 2, 2, 100); rebuildCrosshair(); updateTextPos() end)
bGapPlus.MouseButton1Click:Connect(function() offset = math.clamp(offset + 2, 0, 60); rebuildCrosshair(); updateTextPos() end)
bGapMinus.MouseButton1Click:Connect(function() offset = math.clamp(offset - 2, 0, 60); rebuildCrosshair(); updateTextPos() end)
bSpeedPlus.MouseButton1Click:Connect(function() rotationSpeed = math.clamp(rotationSpeed + 20, 0, 500) end)
bSpeedMinus.MouseButton1Click:Connect(function() rotationSpeed = math.clamp(rotationSpeed - 20, 0, 500) end)

bRot.MouseButton1Click:Connect(function() isRotating = true end)
b20.MouseButton1Click:Connect(function() isRotating = false; targetRotation = 20 end)
b40.MouseButton1Click:Connect(function() isRotating = false; targetRotation = 40 end)
b60.MouseButton1Click:Connect(function() isRotating = false; targetRotation = 60 end)
b90.MouseButton1Click:Connect(function() isRotating = false; targetRotation = 90 end)

bLock.MouseButton1Click:Connect(function()
    isLocked = not isLocked
    local ln = langTable[currentLang]
    if isLocked then bLock.Text = ln.btn_lock_l; bLock.TextColor3 = Color3.fromRGB(255, 90, 90) else bLock.Text = ln.btn_lock_u; bLock.TextColor3 = Color3.fromRGB(90, 255, 90) end
end)

local folderName = "CrosshairConfigsDte"
pcall(function() if isfolder and not isfolder(folderName) then makefolder(folderName) end end)

bSaveConfig.MouseButton1Click:Connect(function()
    local ln = langTable[currentLang]
    if not writefile then bSaveConfig.Text = ln.msg_no_files; task.wait(1.5); bSaveConfig.Text = ln.btn_save; return end
    local cfgName = configNameInput.Text == "" and "Default" or configNameInput.Text
    local data = {
        colorMode=colorMode, bgMode=bgMode, bgSpeed=bgSpeed, isRotating=isRotating, targetRotation=targetRotation, 
        rotationSpeed=rotationSpeed, thickness=thickness, length=length, offset=offset, customText=currentText, 
        currentLang=currentLang, useOutline=useOutline, outlineThickness=outlineThickness, useCenterDot=useCenterDot, 
        centerDotSize=centerDotSize, rainbowMenuUi=rainbowMenuUi, currentFontIndex=currentFontIndex, crosshairType=crosshairType,
        crosshairEnabled=crosshairEnabled, textEnabled=textEnabled
    }
    pcall(function() writefile(folderName.."/"..cfgName..".txt", HttpService:JSONEncode(data)) end)
    bSaveConfig.Text = ln.msg_saved; task.wait(1.5); bSaveConfig.Text = ln.btn_save
end)

bLoadConfig.MouseButton1Click:Connect(function()
    local ln = langTable[currentLang]
    if not readfile then bLoadConfig.Text = ln.msg_no_files; task.wait(1.5); bLoadConfig.Text = ln.btn_load; return end
    local cfgName = configNameInput.Text == "" and "Default" or configNameInput.Text
    local success, result = pcall(function() return HttpService:JSONDecode(readfile(folderName.."/"..cfgName..".txt")) end)
    if success and type(result) == "table" then
        colorMode = result.colorMode or "BlueCyan"
        bgMode = result.bgMode or "Space"
        bgSpeed = result.bgSpeed or 1.0
        isRotating = result.isRotating ~= false
        targetRotation = result.targetRotation or 0; rotationSpeed = result.rotationSpeed or 60
        thickness = result.thickness or 3; length = result.length or 14; offset = result.offset or 10
        currentText = result.customText or "Yurei.win"; currentLang = result.currentLang or currentLang
        useOutline = result.useOutline ~= false; outlineThickness = result.outlineThickness or 1
        useCenterDot = result.useCenterDot ~= false; centerDotSize = result.centerDotSize or 4
        rainbowMenuUi = result.rainbowMenuUi ~= false; currentFontIndex = result.currentFontIndex or 1
        crosshairType = result.crosshairType or "Cross"
        crosshairEnabled = result.crosshairEnabled ~= false
        textEnabled = result.textEnabled ~= false
        
        textLabel.Font = fontList[currentFontIndex]; textLabel.Text = currentText
        textLabel.Visible = textEnabled
        rebuildCrosshair(); updateTextPos(); refreshLocalization()
        bLoadConfig.Text = ln.msg_loaded
    else bLoadConfig.Text = ln.msg_err end
    task.wait(1.5); bLoadConfig.Text = ln.btn_load
end)

local menuOpen = false
menuToggle.MouseButton1Click:Connect(function()
    playSound("toggle")
    TweenService:Create(menuToggle, TweenInfo.new(0.1), {Rotation = menuToggle.Rotation + 45}):Play()
    menuOpen = not menuOpen; menuFrame.Visible = menuOpen
end)

menuToggle.MouseEnter:Connect(function() playSound("hover") end)

local toggleKey = Enum.KeyCode.Insert
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == toggleKey then
        playSound("toggle")
        menuOpen = not menuOpen
        menuFrame.Visible = menuOpen
        TweenService:Create(menuToggle, TweenInfo.new(0.1), {Rotation = menuToggle.Rotation + 45}):Play()
    end
end)

local connection
connection = RunService.RenderStepped:Connect(function(deltaTime)
    if not screenGui or not screenGui.Parent then connection:Disconnect(); return end
    
    if isRotating then
        crosshairContainer.Rotation = (crosshairContainer.Rotation + (rotationSpeed * deltaTime)) % 360
    else
        crosshairContainer.Rotation = crosshairContainer.Rotation + (targetRotation - crosshairContainer.Rotation) * 0.15
    end
    
    local t = (math.sin(tick() * 3) + 1) / 2
    local fastT = (math.sin(tick() * 5) + 1) / 2
    local bgTime = tick() * bgSpeed
    
    if bgMode == "Dark" then
        bgUIGradient.Enabled = false
        menuFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 14)
    else
        bgUIGradient.Enabled = true
        menuFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255) 
        
        if bgMode == "Space" then
            local c1 = Color3.fromRGB(8, 4, 20):Lerp(Color3.fromRGB(20, 4, 32), (math.sin(bgTime * 1.5) + 1) / 2)
            local c2 = Color3.fromRGB(4, 12, 24):Lerp(Color3.fromRGB(4, 28, 36), (math.cos(bgTime * 1.2) + 1) / 2)
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)})
            bgUIGradient.Rotation = (bgTime * 10) % 360
        elseif bgMode == "Matrix" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 8, 4)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 25 + (math.sin(bgTime * 4) * 15), 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 6, 2))})
            bgUIGradient.Rotation = 90
        elseif bgMode == "Pulse" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(11, 11, 14)), ColorSequenceKeypoint.new(0.5, Color3.fromHSV((bgTime * 0.08) % 1, 0.7, 0.14)), ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 11, 14))})
            bgUIGradient.Rotation = (math.sin(bgTime * 0.5) * 45) + 45
        elseif bgMode == "CyberPunk" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 0, 20)), ColorSequenceKeypoint.new(1, Color3.fromRGB(230, 0, 110):Lerp(Color3.fromRGB(110, 0, 160), (math.sin(bgTime * 2) + 1) / 2))})
            bgUIGradient.Rotation = (bgTime * -15) % 360
        elseif bgMode == "Inferno" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 1, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 50, 0):Lerp(Color3.fromRGB(70, 8, 0), (math.cos(bgTime * 1.5) + 1) / 2)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 3, 0))})
            bgUIGradient.Rotation = (math.sin(bgTime * 0.8) * 30) + 90
        elseif bgMode == "ToxicSlime" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 12, 4)), ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 150, 15):Lerp(Color3.fromRGB(8, 40, 10), (math.sin(bgTime * 1) + 1) / 2))})
            bgUIGradient.Rotation = (bgTime * 25) % 360
        elseif bgMode == "Glitch" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(6, 6, 10)), ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 32, 40):Lerp(Color3.fromRGB(50, 8, 32), (math.sin(bgTime * 10) + 1) / 2))})
            bgUIGradient.Rotation = (math.floor(bgTime * 6) * 45) % 360
        elseif bgMode == "SynthWave" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 5, 30)), ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 0, 180):Lerp(Color3.fromRGB(240, 0, 140), (math.sin(bgTime * 2) + 1) / 2))})
            bgUIGradient.Rotation = 60
        elseif bgMode == "Emerald" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(2, 12, 6)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 110, 50):Lerp(Color3.fromRGB(0, 35, 15), (math.cos(bgTime * 1.3) + 1) / 2))})
            bgUIGradient.Rotation = (bgTime * 12) % 360
        elseif bgMode == "MonoNight" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 8, 10)), ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 35):Lerp(Color3.fromRGB(12, 12, 15), (math.sin(bgTime * 0.8) + 1) / 2))})
            bgUIGradient.Rotation = 135
        elseif bgMode == "SakuraBlossom" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 10, 15)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 200):Lerp(Color3.fromRGB(40, 15, 25), (math.cos(bgTime * 0.7) + 1) / 2))})
            bgUIGradient.Rotation = 45
        elseif bgMode == "Amethyst" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 5, 18)), ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 20, 160):Lerp(Color3.fromRGB(15, 35, 90), (math.sin(bgTime * 1.1) + 1) / 2))})
            bgUIGradient.Rotation = (bgTime * -8) % 360
        elseif bgMode == "Frostbite" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(3, 10, 20)), ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 220, 255):Lerp(Color3.fromRGB(10, 30, 60), (math.sin(bgTime * 1.8) + 1) / 2))})
            bgUIGradient.Rotation = 180
        elseif bgMode == "Volcanic" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 4, 4)), ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 15, 15):Lerp(Color3.fromRGB(20, 20, 22), (math.cos(bgTime * 2.2) + 1) / 2))})
            bgUIGradient.Rotation = 0
        elseif bgMode == "Nebula" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 0, 30)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 120, 180)), ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 100))})
            bgUIGradient.Rotation = (bgTime * 8) % 360
        elseif bgMode == "CyberSpace" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 5, 5)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255):Lerp(Color3.fromRGB(0, 20, 40), (math.sin(bgTime * 1.5) + 1) / 2))})
            bgUIGradient.Rotation = 90
        elseif bgMode == "NordicFrost" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 25, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 220, 240):Lerp(Color3.fromRGB(40, 60, 80), (math.cos(bgTime) + 1) / 2))})
            bgUIGradient.Rotation = 30
        elseif bgMode == "CrimsonVoid" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 0, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 0, 20)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 0, 5))})
            bgUIGradient.Rotation = (math.sin(bgTime) * 60)
        elseif bgMode == "ToxicNeon" then
            bgUIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 25, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 255, 0):Lerp(Color3.fromRGB(0, 80, 20), (math.sin(bgTime * 2.5) + 1) / 2))})
            bgUIGradient.Rotation = 120
        end
    end
    
    local finalColor = Color3.fromRGB(255, 255, 255)
    if colorMode == "Rainbow" then finalColor = Color3.fromHSV((tick() * 0.7) % 1, 0.8, 1)
    elseif colorMode == "BlueCyan" then finalColor = Color3.fromRGB(0, 210, 255):Lerp(Color3.fromRGB(0, 255, 210), t)
    elseif colorMode == "NeonMint" then finalColor = Color3.fromRGB(50, 255, 130):Lerp(Color3.fromRGB(170, 255, 200), t)
    elseif colorMode == "CosmicSakura" then finalColor = Color3.fromRGB(255, 80, 160):Lerp(Color3.fromRGB(255, 190, 220), t)
    elseif colorMode == "AcidLime" then finalColor = Color3.fromRGB(140, 255, 0):Lerp(Color3.fromRGB(210, 255, 30), t)
    elseif colorMode == "DeepOcean" then finalColor = Color3.fromRGB(10, 80, 255):Lerp(Color3.fromRGB(0, 190, 255), fastT)
    elseif colorMode == "GoldYellow" then finalColor = Color3.fromRGB(255, 170, 0):Lerp(Color3.fromRGB(255, 235, 90), t)
    elseif colorMode == "SunsetGlow" then finalColor = Color3.fromRGB(255, 45, 0):Lerp(Color3.fromRGB(255, 140, 50), t)
    elseif colorMode == "PurpleMagic" then finalColor = Color3.fromRGB(180, 0, 255):Lerp(Color3.fromRGB(255, 0, 150), t)
    elseif colorMode == "IceBlizzard" then finalColor = Color3.fromRGB(230, 245, 255):Lerp(Color3.fromRGB(100, 200, 255), t)
    elseif colorMode == "CyberPunk" then finalColor = Color3.fromRGB(255, 0, 130):Lerp(Color3.fromRGB(0, 240, 200), fastT)
    elseif colorMode == "ToxicBlood" then finalColor = Color3.fromRGB(220, 0, 0):Lerp(Color3.fromRGB(70, 0, 15), t)
    elseif colorMode == "VampireMyth" then finalColor = Color3.fromRGB(130, 0, 40):Lerp(Color3.fromRGB(90, 0, 140), t)
    elseif colorMode == "ElectricVoid" then finalColor = Color3.fromRGB(0, 50, 255):Lerp(Color3.fromRGB(150, 0, 255), fastT)
    elseif colorMode == "AtomicWaste" then finalColor = Color3.fromRGB(0, 255, 50):Lerp(Color3.fromRGB(220, 255, 0), t)
    elseif colorMode == "GhostVapor" then finalColor = Color3.fromRGB(160, 170, 185):Lerp(Color3.fromRGB(255, 255, 255), t)
    elseif colorMode == "CaramelLatte" then finalColor = Color3.fromRGB(160, 110, 75):Lerp(Color3.fromRGB(235, 200, 165), t)
    elseif colorMode == "MilkyWay" then finalColor = Color3.fromRGB(40, 20, 130):Lerp(Color3.fromRGB(255, 100, 180), t)
    elseif colorMode == "DesertMirage" then finalColor = Color3.fromRGB(255, 110, 0):Lerp(Color3.fromRGB(255, 200, 80), t)
    elseif colorMode == "JungleMoss" then finalColor = Color3.fromRGB(10, 85, 30):Lerp(Color3.fromRGB(120, 195, 60), t)
    end
    
    for _, obj in ipairs(visualElements) do
        if obj.Name == "MainLine" then
            obj.BackgroundColor3 = finalColor
        elseif obj.Name == "ContainerFrame" then
            local ms = obj:FindFirstChild("MainStroke")
            if ms then ms.Color = finalColor end
        end
    end
    
    if centerDotInstance then centerDotInstance.BackgroundColor3 = finalColor end
    if textLabel then textLabel.TextColor3 = finalColor end
    
    if rainbowMenuUi then 
        menuStroke.Color = finalColor
        toggleStroke.Color = finalColor 
        dropdownStroke.Color = finalColor
    else 
        menuStroke.Color = Color3.fromRGB(50, 50, 60) 
        dropdownStroke.Color = Color3.fromRGB(55, 55, 70)
    end
end)
