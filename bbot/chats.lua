local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local ParentGui = CoreGui:FindFirstChild("RobloxGui") or LocalPlayer:WaitForChild("PlayerGui")

local SpyGui = ParentGui:FindFirstChild("BBotImguiChatSpy")
if SpyGui then
    SpyGui:Destroy()
end

SpyGui = Instance.new("ScreenGui")
SpyGui.Name = "BBotImguiChatSpy"
SpyGui.ResetOnSpawn = false
SpyGui.Parent = ParentGui

local Container = Instance.new("Frame")
Container.Name = "SpyContainer"
Container.Size = UDim2.new(0, 380, 0, 200)
Container.Position = UDim2.new(0, 10, 0, 220)
Container.BackgroundTransparency = 1
Container.Parent = SpyGui

-- Outer Window Frame (BBot IMGui Style)
local Outer = Instance.new("Frame")
Outer.Size = UDim2.new(1, 0, 1, 0)
Outer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Outer.BorderSizePixel = 0
Outer.Parent = Container

local Inner = Instance.new("Frame")
Inner.Size = UDim2.new(1, -2, 1, -2)
Inner.Position = UDim2.new(0, 1, 0, 1)
Inner.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Inner.BorderSizePixel = 0
Inner.Parent = Outer

local Main = Instance.new("Frame")
Main.Size = UDim2.new(1, -2, 1, -2)
Main.Position = UDim2.new(0, 1, 0, 1)
Main.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Main.BorderSizePixel = 0
Main.Parent = Inner

local Accent = Instance.new("Frame")
Accent.Size = UDim2.new(1, 0, 0, 1)
Accent.BackgroundColor3 = Color3.fromRGB(45, 125, 200)
Accent.BorderSizePixel = 0
Accent.Parent = Main

-- Title Bar / Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 22)
Header.Position = UDim2.new(0, 0, 0, 1)
Header.BackgroundTransparency = 1
Header.Parent = Main

local Logo = Instance.new("ImageLabel")
Logo.Size = UDim2.new(0, 18, 0, 18)
Logo.Position = UDim2.new(0, 5, 0.5, -9)
Logo.BackgroundTransparency = 1
Logo.Image = "rbxassetid://95206582407271"
Logo.ImageColor3 = Color3.fromRGB(45, 125, 200)
Logo.ScaleType = Enum.ScaleType.Fit
Logo.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -125, 1, 0)
TitleLabel.Position = UDim2.new(0, 28, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.Arial
TitleLabel.Text = "BitchBot | Chat Spy"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 12
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

-- Clear Button
local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 42, 0, 16)
ClearBtn.Position = UDim2.new(1, -108, 0.5, -8)
ClearBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ClearBtn.BorderSizePixel = 1
ClearBtn.BorderColor3 = Color3.fromRGB(10, 10, 10)
ClearBtn.Font = Enum.Font.Arial
ClearBtn.Text = "Clear"
ClearBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
ClearBtn.TextSize = 10
ClearBtn.Parent = Header

local ClearBtnAccent = Instance.new("Frame")
ClearBtnAccent.Size = UDim2.new(1, -2, 1, -2)
ClearBtnAccent.Position = UDim2.new(0, 1, 0, 1)
ClearBtnAccent.BackgroundTransparency = 1
ClearBtnAccent.BorderSizePixel = 1
ClearBtnAccent.BorderColor3 = Color3.fromRGB(50, 50, 50)
ClearBtnAccent.Parent = ClearBtn

-- Darker Chatbox Area Container
local ScrollBg = Instance.new("Frame")
ScrollBg.Size = UDim2.new(1, -8, 1, -30)
ScrollBg.Position = UDim2.new(0, 4, 0, 26)
ScrollBg.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
ScrollBg.BorderSizePixel = 1
ScrollBg.BorderColor3 = Color3.fromRGB(5, 5, 5)
ScrollBg.Parent = Main

local ScrollBgInner = Instance.new("Frame")
ScrollBgInner.Size = UDim2.new(1, -2, 1, -2)
ScrollBgInner.Position = UDim2.new(0, 1, 0, 1)
ScrollBgInner.BackgroundTransparency = 1
ScrollBgInner.BorderSizePixel = 1
ScrollBgInner.BorderColor3 = Color3.fromRGB(45, 45, 45)
ScrollBgInner.Parent = ScrollBg

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -4, 1, -4)
Scroll.Position = UDim2.new(0, 2, 0, 2)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(45, 125, 200)
Scroll.Parent = ScrollBg

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 3)
UIListLayout.Parent = Scroll

ClearBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(Scroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end)

ClearBtn.MouseEnter:Connect(function()
    ClearBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
end)

ClearBtn.MouseLeave:Connect(function()
    ClearBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
end)

-- Auto Toggle Button
local AutoScrollEnabled = true

local AutoBtn = Instance.new("TextButton")
AutoBtn.Size = UDim2.new(0, 55, 0, 16)
AutoBtn.Position = UDim2.new(1, -60, 0.5, -8)
AutoBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
AutoBtn.BorderSizePixel = 1
AutoBtn.BorderColor3 = Color3.fromRGB(10, 10, 10)
AutoBtn.Font = Enum.Font.Arial
AutoBtn.Text = "Auto: ON"
AutoBtn.TextColor3 = Color3.fromRGB(45, 125, 200)
AutoBtn.TextSize = 10
AutoBtn.Parent = Header

local AutoBtnAccent = Instance.new("Frame")
AutoBtnAccent.Size = UDim2.new(1, -2, 1, -2)
AutoBtnAccent.Position = UDim2.new(0, 1, 0, 1)
AutoBtnAccent.BackgroundTransparency = 1
AutoBtnAccent.BorderSizePixel = 1
AutoBtnAccent.BorderColor3 = Color3.fromRGB(50, 50, 50)
AutoBtnAccent.Parent = AutoBtn

local function UpdateButton()
    if AutoScrollEnabled then
        AutoBtn.Text = "Auto: ON"
        AutoBtn.TextColor3 = Color3.fromRGB(45, 125, 200)
        AutoBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    else
        AutoBtn.Text = "Auto: OFF"
        AutoBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        AutoBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    end
end

AutoBtn.MouseButton1Click:Connect(function()
    AutoScrollEnabled = not AutoScrollEnabled
    UpdateButton()
end)

AutoBtn.MouseEnter:Connect(function()
    AutoBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
end)

AutoBtn.MouseLeave:Connect(function()
    UpdateButton()
end)

local function AddSpyMessage(speaker, message, userId)
    local Entry = Instance.new("Frame")
    Entry.Size = UDim2.new(1, 0, 0, 22)
    Entry.BackgroundTransparency = 1
    Entry.AutomaticSize = Enum.AutomaticSize.Y
    Entry.Parent = Scroll

    local Icon = Instance.new("ImageLabel")
    Icon.Size = UDim2.new(0, 16, 0, 16)
    Icon.Position = UDim2.new(0, 2, 0, 2)
    Icon.BackgroundTransparency = 1
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.Parent = Entry

    if speaker == "system" then
        Icon.Image = "rbxassetid://95206582407271"
        Icon.ImageColor3 = Color3.fromRGB(45, 125, 200)
    else
        if userId then
            task.spawn(function()
                pcall(function()
                    local thumb = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
                    Icon.Image = thumb
                end)
            end)
        end
    end

    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(1, -22, 1, 0)
    TextBox.Position = UDim2.new(0, 22, 0, 0)
    TextBox.BackgroundTransparency = 1
    TextBox.ClearTextOnFocus = false
    TextBox.TextEditable = false
    TextBox.Font = Enum.Font.Arial
    TextBox.Text = string.format("[%s]: %s", speaker, message)
    TextBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    TextBox.TextSize = 13
    TextBox.TextXAlignment = Enum.TextXAlignment.Left
    TextBox.TextWrapped = true
    TextBox.AutomaticSize = Enum.AutomaticSize.Y
    TextBox.MultiLine = true
    TextBox.Parent = Entry

    if AutoScrollEnabled then
        task.defer(function()
            Scroll.CanvasPosition = Vector2.new(0, Scroll.AbsoluteCanvasSize.Y)
        end)
    end
end

-- Window Dragging Implementation
local IsDragging = false
local DragStart, StartPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsDragging = true
        DragStart = input.Position
        StartPos = Container.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if IsDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - DragStart
        Container.Position = UDim2.new(
            StartPos.X.Scale,
            StartPos.X.Offset + delta.X,
            StartPos.Y.Scale,
            StartPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsDragging = false
    end
end)

-- Resize Grip Handle in bottom-right corner
local ResizeGrip = Instance.new("TextButton")
ResizeGrip.Size = UDim2.new(0, 12, 0, 12)
ResizeGrip.Position = UDim2.new(1, -12, 1, -12)
ResizeGrip.BackgroundTransparency = 1
ResizeGrip.Text = ""
ResizeGrip.ZIndex = 5
ResizeGrip.Parent = Main

local IsResizing = false
local ResizeStartPos, StartSize

ResizeGrip.MouseButton1Down:Connect(function()
    IsResizing = true
    ResizeStartPos = UserInputService:GetMouseLocation()
    StartSize = Container.AbsoluteSize
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        IsResizing = false
    end
end)

RunService.RenderStepped:Connect(function()
    if IsResizing then
        local mousePos = UserInputService:GetMouseLocation()
        local delta = mousePos - ResizeStartPos
        local newWidth = math.clamp(StartSize.X + delta.X, 240, 800)
        local newHeight = math.clamp(StartSize.Y + delta.Y, 140, 600)
        Container.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

-- Hook into chat systems (Legacy and TextChatService) with duplication protection for the local player
task.spawn(function()
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        TextChatService.OnIncomingMessage = function(textMessage)
            if textMessage.TextSource then
                local player = Players:GetPlayerByUserId(textMessage.TextSource.UserId)
                if player then
                    -- Skip local player messages here if TextChatService captures both output channels, 
                    -- preventing duplicate entries caused by TextChannels routing/echoing.
                    if player == LocalPlayer then
                        return
                    end
                    AddSpyMessage(player.Name, textMessage.Text, player.UserId)
                end
            end
        end
    else
        for _, player in ipairs(Players:GetPlayers()) do
            player.Chatted:Connect(function(msg)
                AddSpyMessage(player.Name, msg, player.UserId)
            end)
        end
        Players.PlayerAdded:Connect(function(player)
            player.Chatted:Connect(function(msg)
                AddSpyMessage(player.Name, msg, player.UserId)
            end)
        end)
    end
end)

-- Initial test line
AddSpyMessage("system", "Chat spy ready!", nil)
