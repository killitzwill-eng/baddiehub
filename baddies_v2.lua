-- Baddies Script for Roblox with Xeno Integration
-- Created for Venice user

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Player
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Xeno Integration
local Xeno = loadstring(game:HttpGet("https://raw.githubusercontent.com/xenohub/xeno/main/loader.lua"))()
local ui = Xeno:CreateWindow("Baddies Script")

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
local flyDirection = Vector3.new(0, 0, 0)
local flyVelocity = Vector3.new(0, 0, 0)

-- Connections storage
local noclipConnection = nil
local flyConnection = nil
local godModeConnection = nil
local aimbotLoopConnection = nil
local autoFarmLoopConnection = nil

-- Functions
function createESP(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local targetCharacter = targetPlayer.Character
    local targetRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    local targetHead = targetCharacter:FindFirstChild("Head")

    if targetRootPart then
        local existingEsp = targetRootPart:FindFirstChild("ESP")
        if existingEsp then existingEsp:Destroy() end -- Remove old ESP if exists

        local esp = Instance.new("BoxHandleAdornment")
        esp.Name = "ESP"
        esp.Size = targetRootPart.Size + Vector3.new(0.5, 0.5, 0.5) -- Slightly larger for visibility
        esp.Color3 = espColor
        esp.Transparency = espTransparency
        esp.ZIndex = 10
        esp.AlwaysOnTop = true
        esp.Visible = true
        esp.Adornee = targetRootPart
        esp.Parent = targetRootPart

        if targetHead then
            local existingNameTag = targetHead:FindFirstChild("NameTag")
            if existingNameTag then existingNameTag:Destroy() end -- Remove old NameTag if exists

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
        return esp, nameTag
    end
    return nil, nil
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

function updateAllESPs()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            removeESP(p) -- Remove existing
            if espEnabled then
                createESP(p) -- Create new with updated settings
            end
        end
    end
end

function toggleESP()
    espEnabled = not espEnabled

    if espEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then
                createESP(p)
            end
        end
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player then
                removeESP(p)
            end
        end
    end
end

function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character:FindFirstChild(aimbotPart) and p.Character.Humanoid.Health > 0 then
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

            -- Create a new CFrame looking at the target
            local newLookCFrame = CFrame.lookAt(currentCFrame.Position, targetPos)

            -- Smoothly interpolate the camera's CFrame
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
        humanoid:ChangeState(Enum.HumanoidStateType.Flying) -- Set to flying state if available, or Freefall
        humanoid.PlatformStand = true -- Prevent falling

        flyConnection = RunService.Heartbeat:Connect(function(delta)
            if flyEnabled and character and humanoid and rootPart then
                local direction = Vector3.new(0, 0, 0)

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    direction = direction + workspace.CurrentCamera
