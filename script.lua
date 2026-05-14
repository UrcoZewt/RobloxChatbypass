local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

if CoreGui:FindFirstChild("RobloxChatBypass") then
    CoreGui:FindFirstChild("RobloxChatBypass"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RobloxChatBypass"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local PLACE_ID = tostring(game.PlaceId)
local LOCAL_USER = Players.LocalPlayer.Name
local isChatVisible = true
local isBinding = false

-- Распознавание устройства (Проверка наличия тач-скрина/акселерометра)
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function playSound(assetId, volume)
    task.spawn(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. tostring(assetId)
        sound.Volume = volume or 1
        sound.PlayOnRemove = true
        sound.Parent = SoundService
        sound:Destroy()
    end)
end

local SETTINGS_FILE = "chat_bypass_settings.json"
local toggleKey = Enum.KeyCode.P

local function loadSettings()
    local success, content = pcall(function()
        if readfile then return readfile(SETTINGS_FILE) end
    end)
    if success and content then
        local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(content) end)
        if decodeSuccess and data and data.toggleKey then
            local keySuccess, keyEnum = pcall(function() return Enum.KeyCode[data.toggleKey] end)
            if keySuccess then toggleKey = keyEnum end
        end
    end
end

local function saveSettings()
    pcall(function()
        if writefile then
            local data = { toggleKey = toggleKey.Name }
            writefile(SETTINGS_FILE, HttpService:JSONEncode(data))
        end
    end)
end

loadSettings()

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.4
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local function makeDraggable(frame, restrictToTextBox)
    local dragToggle, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if restrictToTextBox and UserInputService:GetFocusedTextBox() then return end
            dragToggle = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragToggle = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragToggle then
            local delta = input.Position - dragStart
            local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            game:GetService("TweenService"):Create(frame, TweenInfo.new(0.1), {Position = position}):Play()
        end
    end)
end

makeDraggable(MainFrame, true)

local function toggleChat()
    isChatVisible = not isChatVisible
    MainFrame.Visible = isChatVisible
    playSound(6891630713, 0.4)
end

-- КНОПКА ДЛЯ ТЕЛЕФОНОВ (Создается и показывается СТРОГО на мобильных устройствах)
if isMobile then
    local MobileToggleButton = Instance.new("TextButton")
    MobileToggleButton.Name = "MobileToggleButton"
    MobileToggleButton.Size = UDim2.new(0, 60, 0, 35)
    MobileToggleButton.Position = UDim2.new(0.9, -65, 0.05, 0)
    MobileToggleButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MobileToggleButton.BackgroundTransparency = 0.4
    MobileToggleButton.Font = Enum.Font.SourceSansBold
    MobileToggleButton.TextSize = 14
    MobileToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MobileToggleButton.Text = "CHAT"
    MobileToggleButton.Active = true
    MobileToggleButton.Parent = ScreenGui

    local MobileButtonCorner = Instance.new("UICorner")
    MobileButtonCorner.CornerRadius = UDim.new(0, 6)
    MobileButtonCorner.Parent = MobileToggleButton

    makeDraggable(MobileToggleButton, false)
    MobileToggleButton.MouseButton1Click:Connect(toggleChat)
end

local MessagesContainer = Instance.new("ScrollingFrame")
MessagesContainer.Name = "MessagesContainer"
MessagesContainer.Size = UDim2.new(1, -10, 1, -60)
MessagesContainer.Position = UDim2.new(0, 5, 0, 5)
MessagesContainer.BackgroundTransparency = 1
MessagesContainer.BorderSizePixel = 0
MessagesContainer.ScrollBarThickness = 6
MessagesContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
MessagesContainer.ScrollBarImageTransparency = 0.5
MessagesContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
MessagesContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = MessagesContainer
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    MessagesContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
    MessagesContainer.CanvasPosition = Vector2.new(0, math.max(0, UIListLayout.AbsoluteContentSize.Y - MessagesContainer.AbsoluteWindowSize.Y))
end)

local TextBox = Instance.new("TextBox")
TextBox.Name = "MessageInput"
TextBox.Size = UDim2.new(1, -55, 0, 40)
TextBox.Position = UDim2.new(0, 5, 1, -45)
TextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextBox.BackgroundTransparency = 0.5
TextBox.BorderSizePixel = 0
TextBox.Font = Enum.Font.SourceSans
TextBox.TextSize = 16
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.PlaceholderText = "Type text here..."
TextBox.PlaceholderColor3 = Color3.fromRGB(200, 200, 200)
TextBox.Text = ""
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.ClearTextOnFocus = false
TextBox.Parent = MainFrame

local TextBoxCorner = Instance.new("UICorner")
TextBoxCorner.CornerRadius = UDim.new(0, 6)
TextBoxCorner.Parent = TextBox

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingLeft = UDim.new(0, 10)
UIPadding.Parent = TextBox

local SettingsButton = Instance.new("ImageButton")
SettingsButton.Name = "SettingsButton"
SettingsButton.Size = UDim2.new(0, 40, 0, 40)
SettingsButton.Position = UDim2.new(1, -45, 1, -45)
SettingsButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SettingsButton.BackgroundTransparency = 0.5
SettingsButton.BorderSizePixel = 0
SettingsButton.Image = "rbxassetid://6031280224"
SettingsButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
SettingsButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 6)
ButtonCorner.Parent = SettingsButton

local SettingsFrame = Instance.new("Frame")
SettingsFrame.Name = "SettingsFrame"
SettingsFrame.Size = UDim2.new(0, 160, 0, 100)
SettingsFrame.Position = UDim2.new(1, -165, 1, -155)
SettingsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
SettingsFrame.BackgroundTransparency = 0.2
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Visible = false
SettingsFrame.ZIndex = 5
SettingsFrame.Parent = MainFrame

local SettingsCorner = Instance.new("UICorner")
SettingsCorner.CornerRadius = UDim.new(0, 6)
SettingsCorner.Parent = SettingsFrame

local SettingsLayout = Instance.new("UIListLayout")
SettingsLayout.Parent = SettingsFrame
SettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
SettingsLayout.Padding = UDim.new(0, 6)

local SettingsPadding = Instance.new("UIPadding")
SettingsPadding.PaddingTop = UDim.new(0, 8)
SettingsPadding.PaddingLeft = UDim.new(0, 8)
SettingsPadding.PaddingRight = UDim.new(0, 8)
SettingsPadding.Parent = SettingsFrame

local BindButton = Instance.new("TextButton")
BindButton.Name = "BindButton"
BindButton.Size = UDim2.new(1, 0, 0, 35)
BindButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
BindButton.BorderSizePixel = 0
BindButton.Font = Enum.Font.SourceSansBold
BindButton.TextSize = 14
BindButton.TextColor3 = Color3.fromRGB(255, 255, 255)
BindButton.Text = "TOGGLE KEY: " .. string.upper(toggleKey.Name)
BindButton.ZIndex = 6
BindButton.Parent = SettingsFrame

local BindCorner = Instance.new("UICorner")
BindCorner.CornerRadius = UDim.new(0, 4)
BindCorner.Parent = BindButton

local UnloadButton = Instance.new("TextButton")
UnloadButton.Name = "UnloadButton"
UnloadButton.Size = UDim2.new(1, 0, 0, 35)
UnloadButton.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
UnloadButton.BorderSizePixel = 0
UnloadButton.Font = Enum.Font.SourceSansBold
UnloadButton.TextSize = 14
UnloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
UnloadButton.Text = "UNLOAD SCRIPT"
UnloadButton.ZIndex = 6
UnloadButton.Parent = SettingsFrame

local UnloadCorner = Instance.new("UICorner")
UnloadCorner.CornerRadius = UDim.new(0, 4)
UnloadCorner.Parent = UnloadButton

local function addMessage(senderName, messageText, systemColor, assetId)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 0, 22)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.SourceSansBold
    Label.TextSize = 16
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextStrokeTransparency = 0.5
    Label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Label.RichText = true
    Label.Parent = MessagesContainer
    
    if systemColor then
        Label.Text = string.format("<font color='rgb(%d,%d,%d)'>%s %s</font>", systemColor.R*255, systemColor.G*255, systemColor.B*255, senderName, messageText)
    else
        Label.Text = string.format("<font color='rgb(255,255,255)'>%s:</font> <font color='rgb(205,205,205)'>%s</font>", senderName, messageText)
    end
    
    if assetId then
        Label.Size = UDim2.new(1, -10, 0, 85)
        local Img = Instance.new("ImageLabel")
        Img.Size = UDim2.new(0, 60, 0, 60)
        Img.Position = UDim2.new(0, 0, 0, 22)
        Img.Image = "rbxassetid://" .. tostring(assetId)
        Img.BackgroundTransparency = 1
        Img.Parent = Label
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == toggleKey and not isBinding then
        toggleChat()
    end
end)

BindButton.MouseButton1Click:Connect(function()
    if isBinding then return end
    isBinding = true
    BindButton.Text = "PRESS ANY KEY..."
    BindButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    playSound(4561001476, 0.5)
    
    local connection
    connection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode ~= Enum.KeyCode.Return and input.KeyCode ~= Enum.KeyCode.Escape then
                toggleKey = input.KeyCode
                BindButton.Text = "TOGGLE KEY: " .. string.upper(input.KeyCode.Name)
                saveSettings()
            else
                BindButton.Text = "TOGGLE KEY: " .. string.upper(toggleKey.Name)
            end
            BindButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            isBinding = false
            playSound(4561001476, 0.6)
            connection:Disconnect()
        end
    end)
end)

SettingsButton.MouseButton1Click:Connect(function() 
    SettingsFrame.Visible = not SettingsFrame.Visible 
    playSound(4561001476, 0.5)
end)

UnloadButton.MouseButton1Click:Connect(function() 
    playSound(5311438992, 0.8)
    ScreenGui:Destroy()
end)

TextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and TextBox.Text ~= "" then
        local text = TextBox.Text
        TextBox.Text = ""
        playSound(4561001476, 0.7) 
        
        local targetPlayer, privateMsg = text:match("^/msg%s+(%S+)%s+(.+)$")
        if targetPlayer and privateMsg then
            addMessage("[ЛС] Вы -> " .. targetPlayer .. ":", privateMsg, Color3.fromRGB(165, 55, 253))
        else
            local asset = text:match("rbxassetid://(%d+)") or text:match("^%d+$")
            if text:match("^%d+$") and #text > 5 then asset = text end
            addMessage(LOCAL_USER, text, nil, asset)
        end
    end
end)

playSound(1380842870, 0.5)
addMessage("System:", "Chat loaded. Active bind: [" .. string.upper(toggleKey.Name) .. "]", Color3.fromRGB(255, 220, 80))
