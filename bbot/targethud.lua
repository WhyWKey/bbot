local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ParentGui = CoreGui:FindFirstChild("RobloxGui") or LocalPlayer:WaitForChild("PlayerGui")

if ParentGui:FindFirstChild("BBotTargetHud") then
    ParentGui.BBotTargetHud:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BBotTargetHud"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = ParentGui

-- 1:1 Color Palette matching menu & loader
local AccentBlue = Color3.fromRGB(45, 125, 200)
local MainBg = Color3.fromRGB(35, 35, 35)
local InnerBorderColor = Color3.fromRGB(60, 60, 60)
local OuterBorderColor = Color3.fromRGB(15, 15, 15)
local DarkBg = Color3.fromRGB(20, 20, 20)
local TextWhite = Color3.fromRGB(255, 255, 255)
local TextGrey = Color3.fromRGB(170, 170, 170)

-- Main Container (Outer Border)
local HudOuter = Instance.new("Frame")
HudOuter.Name = "OuterBorder"
HudOuter.Size = UDim2.new(0, 240, 0, 80)
HudOuter.Position = UDim2.new(0.5, 50, 0.5, 50)
HudOuter.BackgroundColor3 = OuterBorderColor
HudOuter.BorderSizePixel = 0
HudOuter.BackgroundTransparency = 1 -- Start fully transparent for fade-in
HudOuter.Visible = false
HudOuter.Parent = ScreenGui

-- Inner Border
local HudInner = Instance.new("Frame")
HudInner.Size = UDim2.new(1, -2, 1, -2)
HudInner.Position = UDim2.new(0, 1, 0, 1)
HudInner.BackgroundColor3 = InnerBorderColor
HudInner.BorderSizePixel = 0
HudInner.BackgroundTransparency = 1
HudInner.Parent = HudOuter

-- Main Background
local HudMain = Instance.new("Frame")
HudMain.Size = UDim2.new(1, -2, 1, -2)
HudMain.Position = UDim2.new(0, 1, 0, 1)
HudMain.BackgroundColor3 = MainBg
HudMain.BorderSizePixel = 0
HudMain.BackgroundTransparency = 1
HudMain.Parent = HudInner

-- Top Accent Line
local TopAccent = Instance.new("Frame")
TopAccent.Size = UDim2.new(1, 0, 0, 1)
TopAccent.BackgroundColor3 = AccentBlue
TopAccent.BorderSizePixel = 0
TopAccent.BackgroundTransparency = 1
TopAccent.Parent = HudMain

-- Avatar Image Border & Label
local AvatarBorder = Instance.new("Frame")
AvatarBorder.Size = UDim2.new(0, 56, 0, 56)
AvatarBorder.Position = UDim2.new(0, 10, 0, 12)
AvatarBorder.BackgroundColor3 = OuterBorderColor
AvatarBorder.BorderSizePixel = 0
AvatarBorder.BackgroundTransparency = 1
AvatarBorder.Parent = HudMain

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size = UDim2.new(1, -2, 1, -2)
AvatarImage.Position = UDim2.new(0, 1, 0, 1)
AvatarImage.BackgroundColor3 = MainBg
AvatarImage.BorderSizePixel = 0
AvatarImage.Image = ""
AvatarImage.ImageTransparency = 1
AvatarImage.Parent = AvatarBorder

-- Display Name
local DisplayName = Instance.new("TextLabel")
DisplayName.Size = UDim2.new(1, -80, 0, 18)
DisplayName.Position = UDim2.new(0, 75, 0, 12)
DisplayName.BackgroundTransparency = 1
DisplayName.Font = Enum.Font.Arial
DisplayName.Text = "DisplayName"
DisplayName.TextColor3 = TextWhite
DisplayName.TextSize = 14
DisplayName.TextTransparency = 1
DisplayName.TextXAlignment = Enum.TextXAlignment.Left
DisplayName.TextTruncate = Enum.TextTruncate.AtEnd
DisplayName.Parent = HudMain

-- Username
local Username = Instance.new("TextLabel")
Username.Size = UDim2.new(1, -80, 0, 14)
Username.Position = UDim2.new(0, 75, 0, 30)
Username.BackgroundTransparency = 1
Username.Font = Enum.Font.Arial
Username.Text = "@username"
Username.TextColor3 = TextGrey
Username.TextSize = 12
Username.TextTransparency = 1
Username.TextXAlignment = Enum.TextXAlignment.Left
Username.TextTruncate = Enum.TextTruncate.AtEnd
Username.Parent = HudMain

-- Health Bar Container
local HealthBgOuter = Instance.new("Frame")
HealthBgOuter.Size = UDim2.new(1, -80, 0, 12)
HealthBgOuter.Position = UDim2.new(0, 75, 0, 54)
HealthBgOuter.BackgroundColor3 = OuterBorderColor
HealthBgOuter.BorderSizePixel = 0
HealthBgOuter.BackgroundTransparency = 1
HealthBgOuter.Parent = HudMain

local HealthBg = Instance.new("Frame")
HealthBg.Size = UDim2.new(1, -2, 1, -2)
HealthBg.Position = UDim2.new(0, 1, 0, 1)
HealthBg.BackgroundColor3 = DarkBg
HealthBg.BorderSizePixel = 0
HealthBg.BackgroundTransparency = 1
HealthBg.Parent = HealthBgOuter

-- Health Bar Fill
local HealthFill = Instance.new("Frame")
HealthFill.Size = UDim2.new(1, 0, 1, 0)
HealthFill.BackgroundColor3 = Color3.fromRGB(65, 190, 65)
HealthFill.BorderSizePixel = 0
HealthFill.BackgroundTransparency = 1
HealthFill.Parent = HealthBg

-- Health Text Overlay
local HealthText = Instance.new("TextLabel")
HealthText.Size = UDim2.new(1, 0, 1, 0)
HealthText.Position = UDim2.new(0, 0, 0, -1)
HealthText.BackgroundTransparency = 1
HealthText.Font = Enum.Font.Arial
HealthText.Text = "100 HP"
HealthText.TextColor3 = TextWhite
HealthText.TextSize = 10
HealthText.TextTransparency = 1
HealthText.TextStrokeTransparency = 0.3
HealthText.Parent = HealthBg

-- ====== ANIMATION FUNCTIONS ====== --
local CurrentTarget = nil
local HealthConnection = nil
local IsVisible = false
local FadeTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function FadeUI(show)
    if show and not IsVisible then
        IsVisible = true
        HudOuter.Visible = true
        
        TweenService:Create(HudOuter, FadeTweenInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(HudInner, FadeTweenInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(HudMain, FadeTweenInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(TopAccent, FadeTweenInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(AvatarBorder, FadeTweenInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(AvatarImage, FadeTweenInfo, {ImageTransparency = 0}):Play()
        TweenService:Create(DisplayName, FadeTweenInfo, {TextTransparency = 0}):Play()
        TweenService:Create(Username, FadeTweenInfo, {TextTransparency = 0}):Play()
        TweenService:Create(HealthBgOuter, FadeTweenInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(HealthBg, FadeTweenInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(HealthFill, FadeTweenInfo, {BackgroundTransparency = 0}):Play()
        TweenService:Create(HealthText, FadeTweenInfo, {TextTransparency = 0}):Play()
        
    elseif not show and IsVisible then
        IsVisible = false
        
        local fadeOutInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local t1 = TweenService:Create(HudOuter, fadeOutInfo, {BackgroundTransparency = 1})
        TweenService:Create(HudInner, fadeOutInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(HudMain, fadeOutInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(TopAccent, fadeOutInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(AvatarBorder, fadeOutInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(AvatarImage, fadeOutInfo, {ImageTransparency = 1}):Play()
        TweenService:Create(DisplayName, fadeOutInfo, {TextTransparency = 1}):Play()
        TweenService:Create(Username, fadeOutInfo, {TextTransparency = 1}):Play()
        TweenService:Create(HealthBgOuter, fadeOutInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(HealthBg, fadeOutInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(HealthFill, fadeOutInfo, {BackgroundTransparency = 1}):Play()
        TweenService:Create(HealthText, fadeOutInfo, {TextTransparency = 1}):Play()
        t1:Play()
        
        t1.Completed:Connect(function()
            if not IsVisible then
                HudOuter.Visible = false
            end
        end)
    end
end

-- ====== CORE TARGET LOGIC ====== --
_G.SetTargetHUD = function(player)
    if CurrentTarget == player then return end

    if HealthConnection then
        HealthConnection:Disconnect()
        HealthConnection = nil
    end

    CurrentTarget = player

    if not player then
        FadeUI(false)
        return
    end

    FadeUI(true)
    DisplayName.Text = player.DisplayName
    Username.Text = "@" .. player.Name

    task.spawn(function()
        local content = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
        if CurrentTarget == player then
            AvatarImage.Image = content
        end
    end)

    local function UpdateHealth(humanoid)
        local hp = humanoid.Health
        local maxHp = humanoid.MaxHealth
        local pct = math.clamp(hp / maxHp, 0, 1)
        
        HealthText.Text = tostring(math.floor(hp)) .. " HP"
        
        TweenService:Create(HealthFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(pct, 0, 1, 0)
        }):Play()

        local r = 255 - (255 * pct)
        local g = 255 * pct
        TweenService:Create(HealthFill, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), 65)
        }):Play()
    end

    local function ConnectCharacter(char)
        if HealthConnection then
            HealthConnection:Disconnect()
            HealthConnection = nil
        end
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            UpdateHealth(hum)
            HealthConnection = hum.HealthChanged:Connect(function()
                UpdateHealth(hum)
            end)
        end
    end

    if player.Character then
        ConnectCharacter(player.Character)
    end
    
    player.CharacterAdded:Connect(ConnectCharacter)
end

-- ====== MOUSE PROXIMITY CHECKER ====== --
-- This checks who is closest to your crosshair/mouse cursor within 90 pixels
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    local closestPlayer = nil
    local shortestDistance = 95 -- Max pixel radius threshold

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health > 0 then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local screenPos = Vector2.new(screenPoint.X, screenPoint.Y)
                    local distance = (mousePos - screenPos).Magnitude
                    
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end

    _G.SetTargetHUD(closestPlayer)
end)

-- ====== DRAGGING LOGIC ====== --
local dragging, dragInput, dragStart, startPos

HudOuter.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = HudOuter.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

HudOuter.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        HudOuter.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
