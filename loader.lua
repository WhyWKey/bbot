local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- Container Setup
local ParentGui = CoreGui:FindFirstChild("RobloxGui") or Players.LocalPlayer:WaitForChild("PlayerGui")
if ParentGui:FindFirstChild("BBotMenuLoader") then
    ParentGui.BBotMenuLoader:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BBotMenuLoader"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = ParentGui

-- Colors exactly matching the BitchBot Menu UI
local AccentBlue = Color3.fromRGB(45, 125, 200)
local MainBg = Color3.fromRGB(35, 35, 35)
local InnerBorderColor = Color3.fromRGB(60, 60, 60)
local OuterBorderColor = Color3.fromRGB(15, 15, 15)
local BottomBg = Color3.fromRGB(20, 20, 20)
local TextWhite = Color3.fromRGB(255, 255, 255)

-- 1. Outer Border (Black) - Starts fully transparent for fade-in
local OuterBorder = Instance.new("Frame")
OuterBorder.Name = "OuterBorder"
OuterBorder.Size = UDim2.new(0, 220, 0, 70)
OuterBorder.Position = UDim2.new(0.5, -110, 0.5, -35)
OuterBorder.BackgroundColor3 = OuterBorderColor
OuterBorder.BorderSizePixel = 0
OuterBorder.BackgroundTransparency = 1
OuterBorder.Parent = ScreenGui

-- 2. Inner Border (Light Grey)
local InnerBorder = Instance.new("Frame")
InnerBorder.Name = "InnerBorder"
InnerBorder.Size = UDim2.new(1, -2, 1, -2)
InnerBorder.Position = UDim2.new(0, 1, 0, 1)
InnerBorder.BackgroundColor3 = InnerBorderColor
InnerBorder.BorderSizePixel = 0
InnerBorder.BackgroundTransparency = 1
InnerBorder.Parent = OuterBorder

-- 3. Main Background (Dark Grey)
local LoaderFrame = Instance.new("Frame")
LoaderFrame.Name = "MainFrame"
LoaderFrame.Size = UDim2.new(1, -2, 1, -2)
LoaderFrame.Position = UDim2.new(0, 1, 0, 1)
LoaderFrame.BackgroundColor3 = MainBg
LoaderFrame.BorderSizePixel = 0
LoaderFrame.BackgroundTransparency = 1
LoaderFrame.ClipsDescendants = true
LoaderFrame.Parent = InnerBorder

-- Top Accent Line
local TopAccent = Instance.new("Frame")
TopAccent.Name = "TopAccent"
TopAccent.Size = UDim2.new(1, 0, 0, 1)
TopAccent.Position = UDim2.new(0, 0, 0, 0)
TopAccent.BackgroundColor3 = AccentBlue
TopAccent.BorderSizePixel = 0
TopAccent.BackgroundTransparency = 1
TopAccent.Parent = LoaderFrame

-- Left Logo 
local Logo = Instance.new("ImageLabel")
Logo.Name = "Logo"
Logo.Size = UDim2.new(0, 35, 0, 35)
Logo.Position = UDim2.new(0, 15, 0.5, -17.5)
Logo.BackgroundTransparency = 1
Logo.Image = "rbxassetid://95206582407271"
Logo.ImageColor3 = AccentBlue
Logo.ScaleType = Enum.ScaleType.Fit
Logo.ImageTransparency = 1
Logo.Parent = LoaderFrame

-- Main Text 
local MainText = Instance.new("TextLabel")
MainText.Name = "MainText"
MainText.Size = UDim2.new(1, -70, 0, 20)
MainText.Position = UDim2.new(0, 65, 0.5, -10)
MainText.BackgroundTransparency = 1
MainText.Font = Enum.Font.Arial
MainText.Text = "Loading..."
MainText.TextColor3 = TextWhite
MainText.TextSize = 14
MainText.TextTransparency = 1
MainText.TextXAlignment = Enum.TextXAlignment.Left
MainText.TextTruncate = Enum.TextTruncate.AtEnd 
MainText.Parent = LoaderFrame

-- Sub Text ("production")
local SubText = Instance.new("TextLabel")
SubText.Name = "SubText"
SubText.Size = UDim2.new(1, -70, 0, 16)
SubText.Position = UDim2.new(0, 65, 0.5, 4)
SubText.BackgroundTransparency = 1
SubText.Font = Enum.Font.Arial
SubText.Text = "production"
SubText.TextColor3 = AccentBlue
SubText.TextSize = 12
SubText.TextXAlignment = Enum.TextXAlignment.Left
SubText.TextTransparency = 1 
SubText.Parent = LoaderFrame

-- Separator line directly above the progress bar
local ProgressTopBorder = Instance.new("Frame")
ProgressTopBorder.Name = "ProgressSeparator"
ProgressTopBorder.Size = UDim2.new(1, 0, 0, 1)
ProgressTopBorder.Position = UDim2.new(0, 0, 1, -3)
ProgressTopBorder.BackgroundColor3 = InnerBorderColor
ProgressTopBorder.BorderSizePixel = 0
ProgressTopBorder.BackgroundTransparency = 1
ProgressTopBorder.Parent = LoaderFrame

-- Bottom Progress Bar Background
local BottomBarBg = Instance.new("Frame")
BottomBarBg.Name = "BottomBarBg"
BottomBarBg.Size = UDim2.new(1, 0, 0, 2)
BottomBarBg.Position = UDim2.new(0, 0, 1, -2)
BottomBarBg.BackgroundColor3 = BottomBg
BottomBarBg.BorderSizePixel = 0
BottomBarBg.BackgroundTransparency = 1
BottomBarBg.Parent = LoaderFrame

-- Bottom Progress Fill
local ProgressFill = Instance.new("Frame")
ProgressFill.Name = "ProgressFill"
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = AccentBlue
ProgressFill.BorderSizePixel = 0
ProgressFill.BackgroundTransparency = 1
ProgressFill.Parent = BottomBarBg

-- Animation & Loading Sequence
task.spawn(function()
    local gameName = "Universal" 
    
    -- Fetch Game Name in background
    task.spawn(function()
        if game.PlaceId > 0 then
            local success, info = pcall(function()
                return MarketplaceService:GetProductInfo(game.PlaceId)
            end)
            if success and info and info.Name then
                gameName = info.Name
            end
        end
    end)

    -- 1. Fade In Sequence
    local FadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    TweenService:Create(OuterBorder, FadeInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(InnerBorder, FadeInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(LoaderFrame, FadeInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(TopAccent, FadeInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(Logo, FadeInfo, {ImageTransparency = 0}):Play()
    TweenService:Create(MainText, FadeInfo, {TextTransparency = 0}):Play()
    TweenService:Create(ProgressTopBorder, FadeInfo, {BackgroundTransparency = 0}):Play()
    TweenService:Create(BottomBarBg, FadeInfo, {BackgroundTransparency = 0}):Play()
    local fillFade = TweenService:Create(ProgressFill, FadeInfo, {BackgroundTransparency = 0})
    fillFade:Play()
    
    -- Wait for fade-in to finish before starting progress bar
    fillFade.Completed:Wait()

    -- 2. Play Loading Bar Tween
    local LoadTween = TweenService:Create(ProgressFill, TweenInfo.new(3, Enum.EasingStyle.Linear), {
        Size = UDim2.new(1, 0, 1, 0)
    })
    LoadTween:Play()
    
    task.wait(1.5)
    
    -- Snap text to fetched game name
    MainText.Text = gameName
    
    -- Shift text up and fade in "production"
    TweenService:Create(MainText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 65, 0.5, -16)
    }):Play()
    
    TweenService:Create(SubText, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0
    }):Play()
    
    LoadTween.Completed:Wait()
    task.wait(0.5)
    
    -- 3. Fade Out Sequence
    for _, item in ipairs(OuterBorder:GetDescendants()) do
        if item:IsA("TextLabel") then
            TweenService:Create(item, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        elseif item:IsA("ImageLabel") then
            TweenService:Create(item, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
        elseif item:IsA("Frame") then
            TweenService:Create(item, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        end
    end
    
    local finalFadeOut = TweenService:Create(OuterBorder, TweenInfo.new(0.3), {BackgroundTransparency = 1})
    finalFadeOut:Play()
    finalFadeOut.Completed:Wait()
    
    ScreenGui:Destroy()
    
    -- Main code execution starts here
end)
