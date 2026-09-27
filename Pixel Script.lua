local dhlockSource = game:HttpGet(
    "https://raw.githubusercontent.com/Stratxgy/DH-Lua-Lock/refs/heads/main/Main.lua"
)

dhlockSource = dhlockSource:gsub(
    "local function GetClosestPlayer%(%)",
    [[local function IsTargetVisible(player, part)
     if not dhlock.wallcheck then return true end

     local camera = Workspace.CurrentCamera
     local raycastParams = RaycastParams.new()
     raycastParams.FilterType = Enum.RaycastFilterType.Exclude
     raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}

     local result = Workspace:Raycast(
          camera.CFrame.Position,
          part.Position - camera.CFrame.Position,
          raycastParams
     )

     return not result or result.Instance:IsDescendantOf(player.Character)
end

local function GetClosestPlayer()]]
)

dhlockSource = dhlockSource:gsub(
    "if onScreen and distance <= dhlock%.fov and distance < shortestDistance then",
    "if onScreen and IsTargetVisible(player, part) and distance <= dhlock.fov and distance < shortestDistance then"
)

dhlockSource = dhlockSource:gsub(
    "if lockedPlayer then%s+SmoothAimAtPlayer%(lockedPlayer%)%s+end",
    "local lockedPart = lockedPlayer and lockedPlayer.Character and lockedPlayer.Character:FindFirstChild(GetCurrentLockPart())\n        if lockedPart and IsTargetVisible(lockedPlayer, lockedPart) then\n            SmoothAimAtPlayer(lockedPlayer)\n        else\n            lockedPlayer = nil\n        end"
)

local dhlock = loadstring(dhlockSource)()

getgenv().dhlock.keybind = Enum.UserInputType.MouseButton1
getgenv().dhlock.toggle = false
getgenv().dhlock.findPlayers = false
getgenv().dhlock.espType = "Highlight"
getgenv().dhlock.espShowNames = true
getgenv().dhlock.espShowDistance = true
getgenv().dhlock.espShowHealth = true
getgenv().dhlock.espColor = Color3.fromRGB(255, 80, 80)

local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local espObjects = {}
local skeletonJoints = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local function clearPlayerESP(player)
    local objects = espObjects[player]
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    local billboard = head and head:FindFirstChild("TesterPlayerInfo")
    if billboard then billboard:Destroy() end
    if not objects then return end

    for _, object in ipairs(objects) do
        if object.Destroy then
            object:Destroy()
        else
            object:Remove()
        end
    end

    espObjects[player] = nil
end

local function updatePlayerHighlight(player)
    if player == Players.LocalPlayer or not player.Character then
        return
    end

    clearPlayerESP(player)
    if not getgenv().dhlock.findPlayers then
        return
    end

    local objects = {}
    if getgenv().dhlock.espType == "Highlight" then
        local highlight = Instance.new("Highlight")
        highlight.Name = "TesterPlayerHighlight"
        highlight.FillColor = getgenv().dhlock.espColor
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = player.Character
        table.insert(objects, highlight)
    elseif getgenv().dhlock.espType == "Box" then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "TesterPlayerBox"
            box.Adornee = root
            box.Size = Vector3.new(4, 6, 2)
            box.Color3 = getgenv().dhlock.espColor
            box.Transparency = 0.35
            box.AlwaysOnTop = true
            box.ZIndex = 5
            box.Parent = root
            table.insert(objects, box)
        end
    elseif Drawing then
        for _ in ipairs(skeletonJoints) do
            local line = Drawing.new("Line")
            line.Color = getgenv().dhlock.espColor
            line.Thickness = 2
            line.Visible = false
            table.insert(objects, line)
        end
    end

    espObjects[player] = objects
end

local function updatePlayerInfoESP(player)
    if player == Players.LocalPlayer or not player.Character then return end

    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    local billboard = head:FindFirstChild("TesterPlayerInfo")
    if not getgenv().dhlock.findPlayers or not (getgenv().dhlock.espShowNames or getgenv().dhlock.espShowDistance or getgenv().dhlock.espShowHealth) then
        if billboard then billboard:Destroy() end
        return
    end

    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "TesterPlayerInfo"
        billboard.Size = UDim2.fromOffset(180, 42)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head

        local label = Instance.new("TextLabel")
        label.Name = "Info"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextColor3 = getgenv().dhlock.espColor
        label.TextStrokeTransparency = 0.25
        label.Font = Enum.Font.Code
        label.TextSize = 12
        label.Parent = billboard
    end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local camera = workspace.CurrentCamera
    local distance = math.floor((camera.CFrame.Position - head.Position).Magnitude)
    local health = humanoid and math.floor(humanoid.Health) or 0
    local maxHealth = humanoid and math.floor(humanoid.MaxHealth) or 0
    local lines = {}
    if getgenv().dhlock.espShowNames then table.insert(lines, player.Name) end
    if getgenv().dhlock.espShowDistance then table.insert(lines, distance .. " studs") end
    if getgenv().dhlock.espShowHealth then table.insert(lines, "HP " .. health .. "/" .. maxHealth) end
    billboard.Info.Text = table.concat(lines, "\n")
    billboard.Info.TextColor3 = getgenv().dhlock.espColor
end

local function updateAllPlayerHighlights()
    for _, player in ipairs(Players:GetPlayers()) do
        updatePlayerHighlight(player)
        updatePlayerInfoESP(player)
    end
end

local function updateSkeletonESP()
    if not getgenv().dhlock.findPlayers or getgenv().dhlock.espType ~= "Skeleton" then
        return
    end

    Camera = workspace.CurrentCamera
    for player, objects in pairs(espObjects) do
        local character = player.Character
        for index, joint in ipairs(skeletonJoints) do
            local line = objects[index]
            local firstPart = character and character:FindFirstChild(joint[1])
            local secondPart = character and character:FindFirstChild(joint[2])
            if line and firstPart and secondPart then
                local firstPoint, firstVisible = Camera:WorldToViewportPoint(firstPart.Position)
                local secondPoint, secondVisible = Camera:WorldToViewportPoint(secondPart.Position)
                line.From = Vector2.new(firstPoint.X, firstPoint.Y)
                line.To = Vector2.new(secondPoint.X, secondPoint.Y)
                line.Visible = firstVisible or secondVisible
            elseif line then
                line.Visible = false
            end
        end
    end
end

local function updateAllESPInfo()
    if not getgenv().dhlock.findPlayers then return end
    for _, player in ipairs(Players:GetPlayers()) do
        updatePlayerInfoESP(player)
    end
end

local function watchPlayer(player)
    if player == Players.LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function()
        task.wait()
        updatePlayerHighlight(player)
        updatePlayerInfoESP(player)
    end)

    if player.Character then
        updatePlayerHighlight(player)
        updatePlayerInfoESP(player)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    watchPlayer(player)
end

Players.PlayerAdded:Connect(watchPlayer)

Players.PlayerRemoving:Connect(function(player)
    clearPlayerESP(player)
end)


getgenv().dhlock.maxdistance = 18
getgenv().dhlock.wallcheck = true
getgenv().dhlock.smoothness = 100
getgenv().dhlock.showfov = false

local UserInputService = game:GetService("UserInputService")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local existingGui = playerGui:FindFirstChild("TesterUI")
if existingGui then existingGui:Destroy() end

local ui = Instance.new("ScreenGui")
ui.Name = "TesterUI"
ui.ResetOnSpawn = false
ui.Parent = playerGui

local accentColor = Color3.fromRGB(238, 194, 55)

local window = Instance.new("Frame")
window.Size = UDim2.fromOffset(620, 470)
window.Position = UDim2.fromScale(0.5, 0.5)
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
window.BorderColor3 = accentColor
window.Parent = ui

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1
uiScale.Parent = window

local titleBar = Instance.new("TextLabel")
titleBar.Size = UDim2.new(1, 0, 0, 28)
titleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
titleBar.BorderColor3 = accentColor
titleBar.Text = "Tester - enhancements"
titleBar.TextColor3 = Color3.fromRGB(235, 235, 235)
titleBar.Font = Enum.Font.Code
titleBar.TextSize = 13
titleBar.Parent = window

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -12, 0, 30)
tabBar.Position = UDim2.fromOffset(6, 34)
tabBar.BackgroundTransparency = 1
tabBar.Parent = window

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 3)
tabLayout.Parent = tabBar

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -12, 1, -72)
content.Position = UDim2.fromOffset(6, 68)
content.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
content.BorderColor3 = Color3.fromRGB(55, 55, 55)
content.Parent = window

local pages = {}
local function createPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.fromScale(1, 1)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.CanvasSize = UDim2.new()
    page.Visible = false
    page.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = page
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
    end)
    pages[name] = page
    return page
end

local function createSection(parent, text)
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, -10, 0, 24)
    section.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    section.BorderColor3 = accentColor
    section.Text = "  " .. text
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.TextColor3 = accentColor
    section.Font = Enum.Font.Code
    section.TextSize = 12
    section.Parent = parent
end

local function createButton(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 26)
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    button.BorderColor3 = Color3.fromRGB(75, 75, 75)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(225, 225, 225)
    button.Font = Enum.Font.Code
    button.TextSize = 12
    button.AutoButtonColor = true
    button.Parent = parent
    button.MouseButton1Click:Connect(callback)
    return button
end

local function createSelector(parent, label, options, current, callback)
    local index = table.find(options, current) or 1
    local button
    button = createButton(parent, label .. ": " .. options[index], function()
        index = index % #options + 1
        button.Text = label .. ": " .. options[index]
        callback(options[index])
    end)
    return button
end

local function createToggle(parent, label, current, callback)
    local enabled = current
    local button
    button = createButton(parent, label .. ": " .. (enabled and "ON" or "OFF"), function()
        enabled = not enabled
        button.Text = label .. ": " .. (enabled and "ON" or "OFF")
        callback(enabled)
    end)
    return button
end

local function createInput(parent, label, placeholder, callback)
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -10, 0, 26)
    input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    input.BorderColor3 = Color3.fromRGB(70, 70, 70)
    input.PlaceholderText = label .. " (" .. placeholder .. ")"
    input.Text = ""
    input.TextColor3 = Color3.fromRGB(235, 235, 235)
    input.Font = Enum.Font.Code
    input.TextSize = 12
    input.ClearTextOnFocus = false
    input.Parent = parent
    input.FocusLost:Connect(function()
        callback(input.Text)
    end)
    return input
end

local tabNames = {"main", "world", "esp", "visuals", "character", "misc", "settings"}
for _, name in ipairs(tabNames) do
    local page = createPage(name)
    local tab = createButton(tabBar, name, function()
        for pageName, otherPage in pairs(pages) do
            otherPage.Visible = pageName == name
        end
    end)
    tab.Size = UDim2.fromOffset(82, 26)
end

local mainPage = pages.main
createSection(mainPage, "activation")
createSelector(mainPage, "aim method", {"Hold to Aim", "Toggle Aim"}, "Hold to Aim", function(option)
    getgenv().dhlock.toggle = option == "Toggle Aim"
end)
createToggle(mainPage, "aim assist", false, function(value)
    getgenv().dhlock.enabled = value
end)
createSection(mainPage, "targeting")
createSelector(mainPage, "select part", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg"}, "Head", function(partName)
    getgenv().dhlock.lockpart = partName
    getgenv().dhlock.lockpartair = partName
end)
createSection(mainPage, "tuning")
createInput(mainPage, "aim strength 1-100", "1", function(text)
    local strength = math.clamp(tonumber(text) or 1, 1, 100)
    getgenv().dhlock.smoothness = 101 - strength
end)
createInput(mainPage, "smoothness 1-10", "5", function(text)
    getgenv().dhlock.smoothness = math.clamp(tonumber(text) or 10, 1, 10)
end)
createSection(mainPage, "prediction")
createInput(mainPage, "prediction x", "0", function(text)
    getgenv().dhlock.predictionX = tonumber(text) or 0
end)
createInput(mainPage, "prediction y", "0", function(text)
    getgenv().dhlock.predictionY = tonumber(text) or 0
end)

local espPage = pages.esp
createSection(espPage, "player esp")
createSelector(espPage, "esp type", {"Highlight", "Box", "Skeleton"}, "Highlight", function(espType)
    getgenv().dhlock.espType = espType
    updateAllPlayerHighlights()
end)
createToggle(espPage, "find players", false, function(value)
    getgenv().dhlock.findPlayers = value
    updateAllPlayerHighlights()
end)
createSelector(espPage, "esp color", {"Red", "Yellow", "Blue", "White"}, "Red", function(colorName)
    local colors = {
        Red = Color3.fromRGB(255, 80, 80),
        Yellow = Color3.fromRGB(238, 194, 55),
        Blue = Color3.fromRGB(80, 160, 255),
        White = Color3.fromRGB(255, 255, 255),
    }
    getgenv().dhlock.espColor = colors[colorName]
    updateAllPlayerHighlights()
end)
createToggle(espPage, "show names", true, function(value)
    getgenv().dhlock.espShowNames = value
    updateAllESPInfo()
end)
createToggle(espPage, "show distance", true, function(value)
    getgenv().dhlock.espShowDistance = value
    updateAllESPInfo()
end)
createToggle(espPage, "show health", true, function(value)
    getgenv().dhlock.espShowHealth = value
    updateAllESPInfo()
end)

local worldPage = pages.world
createSection(worldPage, "world checks")
createToggle(worldPage, "wall check", true, function(value)
    getgenv().dhlock.wallcheck = value
end)
createToggle(worldPage, "team check", false, function(value)
    getgenv().dhlock.teamcheck = value
end)
createToggle(worldPage, "alive check", false, function(value)
    getgenv().dhlock.alivecheck = value
end)
createInput(worldPage, "fov", "50", function(text)
    getgenv().dhlock.fov = math.clamp(tonumber(text) or 50, 1, 500)
end)
createInput(worldPage, "max distance", "18", function(text)
    getgenv().dhlock.maxdistance = math.max(1, tonumber(text) or 18)
end)

local characterPage = pages.character
createSection(characterPage, "character targeting")
createSelector(characterPage, "lock part", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg"}, "Head", function(partName)
    getgenv().dhlock.lockpart = partName
    getgenv().dhlock.lockpartair = partName
end)

local miscPage = pages.misc
createSection(miscPage, "misc")
createButton(miscPage, "toggle menu: right shift", function()
    ui.Enabled = not ui.Enabled
end)

local settingsPage = pages.settings
createSection(settingsPage, "settings")
createSelector(settingsPage, "ui scale", {"80%", "100%", "120%", "140%"}, "100%", function(scale)
    uiScale.Scale = tonumber(scale:sub(1, -2)) / 100
end)
createButton(settingsPage, "reset menu position", function()
    window.Position = UDim2.fromScale(0.5, 0.5)
end)

local visualsPage = pages.visuals
createSection(visualsPage, "visuals")
createToggle(visualsPage, "show fov", false, function(value)
    getgenv().dhlock.showfov = value
end)
createInput(visualsPage, "screen shake 1-20", "1", function(text)
    getgenv().dhlock.screenshake = math.clamp(tonumber(text) or 1, 1, 20)
end)
pages.main.Visible = true

local dragging = false
local dragStart
local startPosition
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = window.Position
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        window.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        ui.Enabled = not ui.Enabled
    end
end)

getgenv().dhlock.Keybind = getgenv().dhlock.keybind


local RunService = game:GetService("RunService")

getgenv().dhlock.screenshake = 1




RunService.RenderStepped:Connect(function()
    updateSkeletonESP()
    updateAllESPInfo()

    if not getgenv().dhlock.enabled then
        return
    end

    local camera = workspace.CurrentCamera
   if not getgenv().dhlock.enabled then
    return
end
    local offset = Vector3.new(
        math.random(-amount, amount) / 100,
        math.random(-amount, amount) / 100,
        0
    )

    camera.CFrame = camera.CFrame * CFrame.new(offset)
end)
