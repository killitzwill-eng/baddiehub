-- Baddies Script for Roblox with Orion UI
-- Created for Venice user

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Orion UI Library
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

local Window = OrionLib:MakeWindow({
    Name = "Baddies Script",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "BaddiesConfig"
})

-- Variables
local walkSpeed = 16
local jumpPower = 50
local noclipEnabled = false
local flyEnabled = false
local godModeEnabled = false
local autoFarmEnabled = false
local espEnabled = false
local aimbotEnabled = false
local aimbotPart = "Head"
local aimbotSmoothness = 0.2
local espColor = Color3.new(1, 0, 0)
local espTransparency = 0.5
local flySpeed = 50
local flyVelocity = Vector3.new(0, 0, 0)

-- Connections storage
local noclipConnection = nil
local flyConnection = nil
local godModeConnection = nil

-- =====================
-- FUNCTIONS
-- =====================

function createESP(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetCharacter = targetPlayer.Character
    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    local targetHead = targetCharacter:FindFirstChild("Head")

    if targetRootPart then
        local existingEsp = targetRootPart:FindFirstChild("ESP")
        if existingEsp then existingEsp:Destroy() end

        local esp = Instance.new("BoxHandleAdornment")
        esp.Name = "ESP"
        esp.Size = targetRootPart.Size + Vector3.new(0.5, 0.5, 0.5)
        esp.Color3 = espColor
        esp.Transparency = espTransparency
        esp.ZIndex = 10
        esp.AlwaysOnTop = true
        esp.Visible = true
        esp.Adornee = targetRootPart
        esp.Parent = targetRootPart

        if targetHead then
            local existingNameTag = targetHead:FindFirstChild("NameTag")
            if existingNameTag then existingNameTag:Destroy() end

            local nameTag = Instance.new("BillboardGui")
            nameTag.Name = "NameTag"
            nameTag.Size = UDim2.new(0, 100, 0, 50)
            nameTag.StudsOffset = Vector3.new(0, 3, 0)
            nameTag.AlwaysOnTop = true
            nameTag.Parent = targetHead

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 1, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = targetPlayer.Name
            nameLabel.TextColor3 = espColor
            nameLabel.TextStrokeTransparency = 0
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.Parent = nameTag
        end
    end
end

function removeESP(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetCharacter = targetPlayer.Character
    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    local targetHead = targetCharacter:FindFirstChild("Head")

    if targetRootPart then
        local esp = targetRootPart:FindFirstChild("ESP")
        if esp then esp:Destroy() end
    end

    if targetHead then
        local nameTag = targetHead:FindFirstChild("NameTag")
        if nameTag then nameTag:Destroy() end
    end
end

function toggleESP()
    espEnabled = not espEnabled
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            removeESP(p)
            if espEnabled then createESP(p) end
        end
    end
end

function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character
            and p.Character:FindFirstChild("Humanoid")
            and p.Character:FindFirstChild(aimbotPart)
            and p.Character.Humanoid.Health > 0 then

            local pos, isVisible = workspace.CurrentCamera:WorldToScreenPoint(p.Character[aimbotPart].Position)
            if isVisible then
                local mousePos = UserInputService:GetMouseLocation()
                local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = p
                end
            end
        end
    end

    return closestPlayer
end

function aimbotLoop()
    if aimbotEnabled then
        local target = getClosestPlayerToCursor()
        if target and target.Character and target.Character:FindFirstChild(aimbotPart) then
            local targetPos = target.Character[aimbotPart].Position
            local currentCFrame = workspace.CurrentCamera.CFrame
            local newLookCFrame = CFrame.lookAt(currentCFrame.Position, targetPos)
            workspace.CurrentCamera.CFrame = currentCFrame:lerp(newLookCFrame, aimbotSmoothness)
        end
    end
end

function toggleNoclip()
    noclipEnabled = not noclipEnabled

    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    if noclipEnabled then
        noclipConnection = RunService.Stepped:Connect(function()
            if character and character:FindFirstChild("Humanoid") then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if character then
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

function toggleFly()
    flyEnabled = not flyEnabled

    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end

    if flyEnabled then
        humanoid.PlatformStand = true

        flyConnection = RunService.Heartbeat:Connect(function(delta)
            if flyEnabled and character and humanoid and rootPart then
                local direction = Vector3.new(0, 0, 0)

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    direction = direction + workspace.CurrentCamera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    direction = direction - workspace.CurrentCamera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    direction = direction - workspace.CurrentCamera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    direction = direction + workspace.CurrentCamera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    direction = direction + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    direction = direction - Vector3.new(0, 1, 0)
                end

                if direction.Magnitude > 0 then
                    direction = direction.Unit
                end

                flyVelocity = flyVelocity:lerp(direction * flySpeed, delta * 5)
                rootPart.AssemblyLinearVelocity = flyVelocity
            end
        end)
    else
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        flyVelocity = Vector3.new(0, 0, 0)
    end
end

function toggleGodMode()
    godModeEnabled = not godModeEnabled

    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end

    if godModeEnabled then
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
        godModeConnection = humanoid.HealthChanged:Connect(function()
            if godModeEnabled then
                humanoid.Health = math.huge
            end
        end)
    else
        humanoid.MaxHealth = 100
        humanoid.Health = 100
    end
end

function autoFarm()
    for _, item in pairs(workspace:GetChildren()) do
        if item:IsA("Model") and item.PrimaryPart then
            pcall(function()
                firetouchinterest(rootPart, item.PrimaryPart, 0)
                firetouchinterest(rootPart, item.PrimaryPart, 1)
            end)
        end
    end

    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, enemy in pairs(enemies:GetChildren()) do
            if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 and enemy.PrimaryPart then
                rootPart.CFrame = enemy.PrimaryPart.CFrame * CFrame.new(0, 0, 5)
                task.wait(0.1)
                local attackRemote = game:GetService("ReplicatedStorage"):FindFirstChild("AttackRemote")
                if attackRemote then
                    pcall(function() attackRemote:FireServer(enemy) end)
                end
            end
        end
    end
end

-- =====================
-- PLAYER EVENTS
-- =====================

Players.PlayerAdded:Connect(function(newPlayer)
    if espEnabled then
        newPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            createESP(newPlayer)
        end)
        createESP(newPlayer)
    end
end)

Players.PlayerRemoving:Connect(function(removedPlayer)
    removeESP(removedPlayer)
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    flyEnabled = false
    noclipEnabled = false
    godModeEnabled = false
    flyVelocity = Vector3.new(0, 0, 0)
end)

-- =====================
-- ORION UI TABS
-- =====================

-- Movement Tab
local MovementTab = Window:MakeTab({
    Name = "Movement",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MovementTab:AddSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "speed",
    Callback = function(val)
        walkSpeed = val
        if humanoid then humanoid.WalkSpeed = val end
    end
})

MovementTab:AddSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 300,
    Default = 50,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "power",
    Callback = function(val)
        jumpPower = val
        if humanoid then humanoid.JumpPower = val end
    end
})

MovementTab:AddSlider({
    Name = "Fly Speed",
    Min = 10,
    Max = 200,
    Default = 50,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "speed",
    Callback = function(val)
        flySpeed = val
    end
})

MovementTab:AddToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(state)
        if state ~= noclipEnabled then
            toggleNoclip()
        end
    end
})

MovementTab:AddToggle({
    Name = "Fly",
    Default = false,
    Callback = function(state)
        if state ~= flyEnabled then
            toggleFly()
        end
    end
})

-- Combat Tab
local CombatTab = Window:MakeTab({
    Name = "Combat",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

CombatTab:AddToggle({
    Name = "ESP",
    Default = false,
    Callback = function(state)
        if state ~= espEnabled then
            toggleESP()
        end
    end
})

CombatTab:AddToggle({
    Name = "Aimbot",
    Default = false,
    Callback = function(state)
        aimbotEnabled = state
    end
})

CombatTab:AddSlider({
    Name = "Aimbot Smoothness",
    Min = 1,
    Max = 100,
    Default = 20,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "%",
    Callback = function(val)
        aimbotSmoothness = val / 100
    end
})

CombatTab:AddDropdown({
    Name = "Aimbot Target Part",
    Default = "Head",
    Options = {"Head", "HumanoidRootPart", "Torso"},
    Callback = function(val)
        aimbotPart = val
    end
})

-- Misc Tab
local MiscTab = Window:MakeTab({
    Name = "Misc",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MiscTab:AddToggle({
    Name = "God Mode",
    Default = false,
    Callback = function(state)
        if state ~= godModeEnabled then
            toggleGodMode()
        end
    end
})

MiscTab:AddToggle({
    Name = "Auto Farm",
    Default = false,
    Callback = function(state)
        autoFarmEnabled = state
    end
})

-- =====================
-- MAIN LOOP
-- =====================

RunService.Heartbeat:Connect(function()
    aimbotLoop()
    if autoFarmEnabled then
        autoFarm()
    end
end)

OrionLib:Init()
