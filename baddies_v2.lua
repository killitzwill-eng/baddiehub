--[[
    BADDIES — LOCK ON + ESP
    Lock a target, left click won't miss.
    by killitzwill
]]

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UserInput    = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")
local RS           = game:GetService("ReplicatedStorage")
local plr          = Players.LocalPlayer
local cam          = workspace.CurrentCamera
local char, hum, hrp

local function grabChar()
    char = plr.Character
    if not char then return false end
    hum  = char:FindFirstChildOfClass("Humanoid")
    hrp  = char:FindFirstChild("HumanoidRootPart")
    return hum and hrp
end
grabChar()
plr.CharacterAdded:Connect(function() task.wait(1) grabChar() end)

-- ══════════════════════════════════════
-- STATE
-- ══════════════════════════════════════
local lockTarget = nil
local espEnabled = true

-- ══════════════════════════════════════
-- COLORS
-- ══════════════════════════════════════
local BG0  = Color3.fromRGB(8,6,12)
local BG1  = Color3.fromRGB(14,10,20)
local BG2  = Color3.fromRGB(22,14,30)
local BG3  = Color3.fromRGB(32,20,42)
local PNK  = Color3.fromRGB(255,20,120)
local PNK2 = Color3.fromRGB(255,80,160)
local RED  = Color3.fromRGB(255,50,50)
local GRN  = Color3.fromRGB(50,230,110)
local YLW  = Color3.fromRGB(255,210,40)
local CYN  = Color3.fromRGB(60,210,240)
local TXT  = Color3.fromRGB(255,230,245)
local DIM  = Color3.fromRGB(160,110,140)
local MUT  = Color3.fromRGB(80,50,70)
local BDR  = Color3.fromRGB(100,30,70)
local WHT  = Color3.fromRGB(255,255,255)

-- ══════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════
local function cr(n,p) local o=Instance.new("UICorner") o.CornerRadius=UDim.new(0,n) o.Parent=p end
local function stk(c,t,p) local o=Instance.new("UIStroke") o.Color=c o.Thickness=t o.Parent=p end

-- ══════════════════════════════════════
-- TOAST
-- ══════════════════════════════════════
local SG
local toastN = 0
local function toast(msg, col)
    col = col or PNK
    if not SG or not SG.Parent then return end
    toastN = toastN + 1
    local n = toastN
    local tf = Instance.new("Frame", SG)
    tf.Size = UDim2.new(0,260,0,32)
    tf.Position = UDim2.new(1,-275,0,10+(n-1)*38)
    tf.BackgroundColor3 = BG2
    tf.BorderSizePixel = 0
    tf.ZIndex = 100
    cr(8,tf) stk(col,1.5,tf)
    local l = Instance.new("TextLabel",tf)
    l.Size = UDim2.new(1,0,1,0)
    l.BackgroundTransparency = 1
    l.Text = "💅  "..msg
    l.TextColor3 = TXT
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11
    l.ZIndex = 101
    task.delay(2.5, function()
        TweenService:Create(tf,TweenInfo.new(0.3),{Position=UDim2.new(1,20,0,tf.Position.Y.Offset)}):Play()
        task.wait(0.35) pcall(function() tf:Destroy() end)
        toastN = math.max(0, toastN-1)
    end)
end

-- ══════════════════════════════════════
-- LOCK ON LOGIC
-- ══════════════════════════════════════
local lockDeathConn = nil

local function clearLock()
    if lockDeathConn then lockDeathConn:Disconnect() lockDeathConn=nil end
    lockTarget = nil
end

local function setLock(p)
    clearLock()
    lockTarget = p
    toast("🎯 Locked: "..p.Name, PNK)

    -- auto drop on death
    local function watchDeath(c)
        local h = c:WaitForChild("Humanoid",5)
        if not h then return end
        h.Died:Connect(function()
            task.wait(0.5)
            if lockTarget == p then
                clearLock()
                toast("💀 "..p.Name.." died — lock dropped", YLW)
                rebuildList()
            end
        end)
    end
    if p.Character then watchDeath(p.Character) end
    p.CharacterAdded:Connect(function(nc)
        if lockTarget ~= p then return end
        watchDeath(nc)
        toast("🔄 "..p.Name.." respawned — still locked", PNK2)
    end)
    lockDeathConn = Players.PlayerRemoving:Connect(function(lp)
        if lp == p then
            clearLock()
            toast("💀 "..p.Name.." left — lock dropped", YLW)
            rebuildList()
        end
    end)
end

-- ══════════════════════════════════════
-- LOCK ON CAMERA — snap aim to target
-- ══════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not lockTarget then return end
    local tc = lockTarget.Character
    if not tc then return end
    local head = tc:FindFirstChild("Head") or tc:FindFirstChild("HumanoidRootPart")
    if not head then return end
    -- Snap camera look direction toward target head
    local origin = cam.CFrame.Position
    local goal   = head.Position
    cam.CFrame   = CFrame.new(origin, goal)
end)

-- ══════════════════════════════════════
-- SILENT AIM — left click always hits
-- Makes mouse ray point at locked target
-- ══════════════════════════════════════
local mt = getrawmetatable and getrawmetatable(game)
if mt then
    local old_index = mt.__index
    local old_namecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" then
            if lockTarget and lockTarget.Character then
                local head = lockTarget.Character:FindFirstChild("Head")
                    or lockTarget.Character:FindFirstChild("HumanoidRootPart")
                if head then
                    grabChar()
                    if hrp then
                        local ray = Ray.new(hrp.Position, (head.Position - hrp.Position).Unit * 500)
                        local args = {...}
                        args[1] = ray
                        return old_namecall(self, table.unpack(args))
                    end
                end
            end
        end
        return old_namecall(self, ...)
    end)
    setreadonly(mt, true)
end

-- ══════════════════════════════════════
-- ESP
-- ══════════════════════════════════════
local espFolder = Instance.new("Folder", CoreGui)
espFolder.Name = "BadLockESP"

local function clearESP()
    for _, v in pairs(espFolder:GetChildren()) do v:Destroy() end
end

RunService.RenderStepped:Connect(function()
    if not espEnabled then
        if #espFolder:GetChildren() > 0 then clearESP() end
        return
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p == plr then continue end
        local pChar = p.Character
        if not pChar then
            local old = espFolder:FindFirstChild("ESP_"..p.Name)
            if old then old:Destroy() end
            continue
        end
        local pHRP = pChar:FindFirstChild("HumanoidRootPart")
        local pH   = pChar:FindFirstChildOfClass("Humanoid")
        if not pHRP or not pH then continue end

        local ec = espFolder:FindFirstChild("ESP_"..p.Name)
        if not ec then
            ec = Instance.new("BillboardGui", espFolder)
            ec.Name = "ESP_"..p.Name
            ec.AlwaysOnTop = true
            ec.MaxDistance = 500
            ec.Size = UDim2.new(0,200,0,90)
            ec.StudsOffsetWorldSpace = Vector3.new(0,3.5,0)
        end
        ec.Adornee = pHRP
        for _, ch in pairs(ec:GetChildren()) do ch:Destroy() end

        local isLocked = lockTarget == p
        local hp, maxhp = pH.Health, pH.MaxHealth
        local hpPct = hp / math.max(maxhp,1)
        local col = isLocked and PNK or CYN

        grabChar()
        local dist = hrp and math.floor((hrp.Position - pHRP.Position).Magnitude) or 0

        -- Name
        local nl = Instance.new("TextLabel", ec)
        nl.Size = UDim2.new(1,0,0,16)
        nl.Position = UDim2.new(0,0,0,0)
        nl.BackgroundTransparency = 1
        nl.Text = (isLocked and "🎯 " or "")..p.Name.."  ["..dist.."m]"
        nl.TextColor3 = col
        nl.Font = Enum.Font.GothamBlack
        nl.TextSize = 13
        nl.TextStrokeTransparency = 0.3
        nl.TextStrokeColor3 = Color3.new(0,0,0)
        nl.TextXAlignment = Enum.TextXAlignment.Center

        -- HP bar bg
        local hbBg = Instance.new("Frame", ec)
        hbBg.Size = UDim2.new(0.8,0,0,6)
        hbBg.Position = UDim2.new(0.1,0,0,20)
        hbBg.BackgroundColor3 = BG3
        hbBg.BorderSizePixel = 0
        cr(3,hbBg)
        local hbF = Instance.new("Frame", hbBg)
        hbF.Size = UDim2.new(math.clamp(hpPct,0,1),0,1,0)
        hbF.BackgroundColor3 = hpPct>0.5 and GRN or (hpPct>0.25 and YLW or RED)
        hbF.BorderSizePixel = 0
        cr(3,hbF)

        -- HP text
        local ht = Instance.new("TextLabel", ec)
        ht.Size = UDim2.new(1,0,0,12)
        ht.Position = UDim2.new(0,0,0,28)
        ht.BackgroundTransparency = 1
        ht.Text = math.floor(hp).."/"..math.floor(maxhp).."hp"
        ht.TextColor3 = TXT
        ht.Font = Enum.Font.GothamBold
        ht.TextSize = 10
        ht.TextXAlignment = Enum.TextXAlignment.Center
        ht.TextStrokeTransparency = 0
        ht.TextStrokeColor3 = Color3.new(0,0,0)

        -- Box outline
        local box = Instance.new("Frame", ec)
        box.Size = UDim2.new(1,4,1,4)
        box.Position = UDim2.new(0,-2,0,-2)
        box.BackgroundTransparency = 1
        stk(col, isLocked and 2 or 1.2, box)
        cr(4,box)
    end

    -- cleanup dead ESP
    for _, eo in pairs(espFolder:GetChildren()) do
        if not Players:FindFirstChild(eo.Name:gsub("ESP_","")) then
            eo:Destroy()
        end
    end
end)

-- ══════════════════════════════════════
-- BUILD GUI
-- ══════════════════════════════════════
pcall(function()
    if CoreGui:FindFirstChild("BadLockGUI") then CoreGui.BadLockGUI:Destroy() end
    if CoreGui:FindFirstChild("BadLockESP") then CoreGui.BadLockESP:Destroy() end
end)

SG = Instance.new("ScreenGui")
SG.Name = "BadLockGUI"
SG.ResetOnSpawn = false
SG.DisplayOrder = 999
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = CoreGui

local Panel = Instance.new("Frame", SG)
Panel.Size = UDim2.new(0,300,0,480)
Panel.Position = UDim2.new(0.5,-150,0.5,-240)
Panel.BackgroundColor3 = BG1
Panel.BorderSizePixel = 0
Panel.Active = true
Panel.Draggable = true
Panel.ZIndex = 2
cr(14, Panel)
stk(PNK, 1.5, Panel)

-- gradient bg
local g = Instance.new("UIGradient", Panel)
g.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18,8,24)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8,5,14))
}
g.Rotation = 135

-- Header
local Hdr = Instance.new("Frame", Panel)
Hdr.Size = UDim2.new(1,0,0,60)
Hdr.BackgroundColor3 = Color3.fromRGB(20,8,30)
Hdr.BorderSizePixel = 0
cr(14, Hdr)
local hg = Instance.new("UIGradient", Hdr)
hg.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120,0,60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(60,0,30))
}
hg.Rotation = 90

local titleLbl = Instance.new("TextLabel", Hdr)
titleLbl.Size = UDim2.new(1,-50,1,0)
titleLbl.Position = UDim2.new(0,14,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "💅  BADDIES LOCK-ON"
titleLbl.TextColor3 = WHT
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextSize = 15
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
local tg = Instance.new("UIGradient", titleLbl)
tg.Color = ColorSequence.new{ColorSequenceKeypoint.new(0,PNK),ColorSequenceKeypoint.new(1,PNK2)}

local subLbl = Instance.new("TextLabel", Hdr)
subLbl.Size = UDim2.new(1,-50,0,14)
subLbl.Position = UDim2.new(0,14,0,36)
subLbl.BackgroundTransparency = 1
subLbl.Text = "by killitzwill  ● ACTIVE"
subLbl.TextColor3 = Color3.fromRGB(50,230,110)
subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 9
subLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Close button
local closeBtn = Instance.new("TextButton", Hdr)
closeBtn.Size = UDim2.new(0,24,0,24)
closeBtn.Position = UDim2.new(1,-32,0,10)
closeBtn.BackgroundColor3 = RED
closeBtn.Text = "✕"
closeBtn.TextColor3 = WHT
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 11
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 10
cr(6, closeBtn)
closeBtn.MouseButton1Click:Connect(function()
    SG:Destroy()
    espFolder:Destroy()
end)

-- ESP toggle row
local espRow = Instance.new("Frame", Panel)
espRow.Size = UDim2.new(1,-20,0,34)
espRow.Position = UDim2.new(0,10,0,68)
espRow.BackgroundColor3 = BG2
espRow.BorderSizePixel = 0
cr(8, espRow)
stk(BDR, 1, espRow)

local espLbl = Instance.new("TextLabel", espRow)
espLbl.Size = UDim2.new(1,-60,1,0)
espLbl.Position = UDim2.new(0,10,0,0)
espLbl.BackgroundTransparency = 1
espLbl.Text = "👁  ESP"
espLbl.TextColor3 = TXT
espLbl.Font = Enum.Font.GothamBold
espLbl.TextSize = 12
espLbl.TextXAlignment = Enum.TextXAlignment.Left

local espBtn = Instance.new("TextButton", espRow)
espBtn.Size = UDim2.new(0,48,0,22)
espBtn.Position = UDim2.new(1,-54,0.5,-11)
espBtn.BackgroundColor3 = PNK
espBtn.Text = "ON"
espBtn.TextColor3 = WHT
espBtn.Font = Enum.Font.GothamBold
espBtn.TextSize = 10
espBtn.BorderSizePixel = 0
cr(11, espBtn)
espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.Text = espEnabled and "ON" or "OFF"
    espBtn.BackgroundColor3 = espEnabled and PNK or BG3
    if not espEnabled then clearESP() end
    toast(espEnabled and "👁 ESP ON" or "ESP OFF", espEnabled and CYN or DIM)
end)

-- Lock status card
local statusCard = Instance.new("Frame", Panel)
statusCard.Size = UDim2.new(1,-20,0,40)
statusCard.Position = UDim2.new(0,10,0,112)
statusCard.BackgroundColor3 = BG2
statusCard.BorderSizePixel = 0
cr(8, statusCard)
stk(BDR, 1, statusCard)

local statusLbl = Instance.new("TextLabel", statusCard)
statusLbl.Size = UDim2.new(1,0,1,0)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "🔓  No Target"
statusLbl.TextColor3 = DIM
statusLbl.Font = Enum.Font.GothamBlack
statusLbl.TextSize = 13
statusLbl.TextXAlignment = Enum.TextXAlignment.Center

-- Section label
local secLbl = Instance.new("TextLabel", Panel)
secLbl.Size = UDim2.new(1,-20,0,14)
secLbl.Position = UDim2.new(0,10,0,160)
secLbl.BackgroundTransparency = 1
secLbl.Text = "  SELECT TARGET"
secLbl.TextColor3 = MUT
secLbl.Font = Enum.Font.GothamBold
secLbl.TextSize = 9

-- Player list scroll
local listScr = Instance.new("ScrollingFrame", Panel)
listScr.Size = UDim2.new(1,-20,0,220)
listScr.Position = UDim2.new(0,10,0,178)
listScr.BackgroundTransparency = 1
listScr.BorderSizePixel = 0
listScr.ScrollBarThickness = 3
listScr.ScrollBarImageColor3 = PNK
listScr.CanvasSize = UDim2.new(0,0,0,0)
listScr.AutomaticCanvasSize = Enum.AutomaticSize.Y

local listLayout = Instance.new("UIListLayout", listScr)
listLayout.Padding = UDim.new(0,4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Refresh + Clear buttons
local btnRow = Instance.new("Frame", Panel)
btnRow.Size = UDim2.new(1,-20,0,30)
btnRow.Position = UDim2.new(0,10,0,408)
btnRow.BackgroundTransparency = 1
btnRow.BorderSizePixel = 0
local brl = Instance.new("UIListLayout", btnRow)
brl.FillDirection = Enum.FillDirection.Horizontal
brl.Padding = UDim.new(0,6)

local function makeBtn(txt, col, w)
    local b = Instance.new("TextButton", btnRow)
    b.Size = UDim2.new(0,w,1,0)
    b.BackgroundColor3 = col
    b.Text = txt
    b.TextColor3 = WHT
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.BorderSizePixel = 0
    cr(7, b)
    return b
end

function rebuildList()
    for _, c in pairs(listScr:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    local enemies = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= plr then table.insert(enemies, p) end
    end
    if #enemies == 0 then
        local none = Instance.new("TextLabel", listScr)
        none.Size = UDim2.new(1,0,0,28)
        none.BackgroundTransparency = 1
        none.Text = "No players in server"
        none.TextColor3 = MUT
        none.Font = Enum.Font.Gotham
        none.TextSize = 11
        none.TextXAlignment = Enum.TextXAlignment.Center
        return
    end
    for _, p in pairs(enemies) do
        local isLocked = lockTarget == p
        local row = Instance.new("Frame", listScr)
        row.Size = UDim2.new(1,0,0,34)
        row.BackgroundColor3 = isLocked and Color3.fromRGB(50,10,30) or BG2
        row.BorderSizePixel = 0
        cr(7, row)
        if isLocked then stk(PNK, 1, row) end

        -- HP info
        local tChar = p.Character
        local tHum  = tChar and tChar:FindFirstChildOfClass("Humanoid")
        local hpTxt = tHum and (" · "..math.floor(tHum.Health).."hp") or ""

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(1,-80,1,0)
        nameLbl.Position = UDim2.new(0,10,0,0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = (isLocked and "🎯 " or "")..p.Name..hpTxt
        nameLbl.TextColor3 = isLocked and PNK or TXT
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 11
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

        local lockBtn = Instance.new("TextButton", row)
        lockBtn.Size = UDim2.new(0,64,0,24)
        lockBtn.Position = UDim2.new(1,-70,0.5,-12)
        lockBtn.BackgroundColor3 = isLocked and PNK or BG3
        lockBtn.Text = isLocked and "LOCKED" or "LOCK"
        lockBtn.TextColor3 = WHT
        lockBtn.Font = Enum.Font.GothamBold
        lockBtn.TextSize = 10
        lockBtn.BorderSizePixel = 0
        cr(7, lockBtn)
        if isLocked then stk(PNK, 1, lockBtn) end

        lockBtn.MouseButton1Click:Connect(function()
            if isLocked then
                clearLock()
                statusLbl.Text = "🔓  No Target"
                statusLbl.TextColor3 = DIM
                toast("🔓 Lock cleared", DIM)
            else
                setLock(p)
                statusLbl.Text = "🎯 Locked: "..p.Name
                statusLbl.TextColor3 = PNK
            end
            rebuildList()
        end)
    end
end

rebuildList()

makeBtn("🔄 Refresh", BG3, 120).MouseButton1Click:Connect(rebuildList)
makeBtn("🔓 Clear Lock", RED, 120).MouseButton1Click:Connect(function()
    clearLock()
    statusLbl.Text = "🔓  No Target"
    statusLbl.TextColor3 = DIM
    toast("🔓 Lock cleared", DIM)
    rebuildList()
end)

-- Auto refresh list every 3s
task.spawn(function()
    while SG and SG.Parent do
        task.wait(3)
        rebuildList()
        if lockTarget then
            statusLbl.Text = "🎯 Locked: "..lockTarget.Name
            statusLbl.TextColor3 = PNK
        end
    end
end)

toast("💅 Lock-On loaded!", PNK)
print("[Baddies Lock-On] Loaded.")
