local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local ParentGui = CoreGui:FindFirstChild("RobloxGui") or Players.LocalPlayer:WaitForChild("PlayerGui")

local NotifGui = ParentGui:FindFirstChild("BBotImguiLogs")
if NotifGui then
    NotifGui:Destroy()
end

NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "BBotImguiLogs"
NotifGui.ResetOnSpawn = false
NotifGui.Parent = ParentGui

local Container = Instance.new("Frame")
Container.Name = "LogContainer"
Container.Size = UDim2.new(0, 350, 0, 300)
Container.Position = UDim2.new(0, 10, 0, 10)
Container.BackgroundTransparency = 1
Container.Parent = NotifGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
UIListLayout.Padding = UDim.new(0, 3)
UIListLayout.Parent = Container

local AccentBlue = Color3.fromRGB(45, 125, 200)
local MainBg = Color3.fromRGB(35, 35, 35)
local InnerBorderColor = Color3.fromRGB(60, 60, 60)
local OuterBorderColor = Color3.fromRGB(15, 15, 15)
local TextWhite = Color3.fromRGB(255, 255, 255)

_G.Notify = function(message, duration)
    duration = duration or 4

    local Outer = Instance.new("Frame")
    Outer.Size = UDim2.new(0, 0, 0, 22)
    Outer.ClipsDescendants = true
    Outer.BackgroundColor3 = OuterBorderColor
    Outer.BorderSizePixel = 0
    Outer.BackgroundTransparency = 1
    Outer.Parent = Container

    local Inner = Instance.new("Frame")
    Inner.Size = UDim2.new(1, -2, 1, -2)
    Inner.Position = UDim2.new(0, 1, 0, 1)
    Inner.BackgroundColor3 = InnerBorderColor
    Inner.BorderSizePixel = 0
    Inner.BackgroundTransparency = 1
    Inner.Parent = Outer

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(1, -2, 1, -2)
    Main.Position = UDim2.new(0, 1, 0, 1)
    Main.BackgroundColor3 = MainBg
    Main.BorderSizePixel = 0
    Main.BackgroundTransparency = 1
    Main.Parent = Inner

    local Accent = Instance.new("Frame")
    Accent.Size = UDim2.new(1, 0, 0, 1)
    Accent.BackgroundColor3 = AccentBlue
    Accent.BorderSizePixel = 0
    Accent.BackgroundTransparency = 1
    Accent.Parent = Main

    -- Increased logo size from 12x12 to 16x16 and adjusted position offset
    local Logo = Instance.new("ImageLabel")
    Logo.Name = "Logo"
    Logo.Size = UDim2.new(0, 16, 0, 16)
    Logo.Position = UDim2.new(0, 5, 0.5, -8)
    Logo.BackgroundTransparency = 1
    Logo.Image = "rbxassetid://95206582407271"
    Logo.ImageColor3 = AccentBlue
    Logo.ScaleType = Enum.ScaleType.Fit
    Logo.ImageTransparency = 1
    Logo.Parent = Main

    -- Increased left text offset to 26 to accommodate the larger logo width
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 0, 1, 0)
    Label.Position = UDim2.new(0, 26, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Arial
    Label.Text = message
    Label.TextColor3 = TextWhite
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTransparency = 1
    Label.AutomaticSize = Enum.AutomaticSize.X
    Label.Parent = Main

    task.spawn(function()
        task.wait() 
        local targetWidth = math.max(Label.AbsoluteSize.X + 38, 140)

        Outer.BackgroundTransparency = 0
        Inner.BackgroundTransparency = 0
        Main.BackgroundTransparency = 0
        Accent.BackgroundTransparency = 0

        local expandTween = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenService:Create(Outer, expandTween, {Size = UDim2.new(0, targetWidth, 0, 22)}):Play()
        
        TweenService:Create(Logo, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.05), {
            ImageTransparency = 0
        }):Play()

        TweenService:Create(Label, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.05), {
            TextTransparency = 0
        }):Play()

        task.wait(duration)
        
        local collapseTween = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        TweenService:Create(Logo, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            ImageTransparency = 1
        }):Play()

        TweenService:Create(Label, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            TextTransparency = 1
        }):Play()

        local shrink = TweenService:Create(Outer, collapseTween, {Size = UDim2.new(0, 0, 0, 22)})
        shrink:Play()
        shrink.Completed:Wait()
        
        Outer:Destroy()
    end)
end

-- Test out the notification box with the larger logo:
_G.Notify("Working logo in the notfication")
_G.Notify("I'll probably add custom icons for it later")
_G.Notify("but yea notfications seems to be finished for now")
_G.Notify("now I gotta make it so the use the ui library")
