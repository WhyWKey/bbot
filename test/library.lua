--[[
    Bitch Bot UI Library v3
    Dark minimal • Two-column panel layout • Sub-tab system
    Widgets: Toggle, Slider, Dropdown, Keybind, Colorpicker, Button, Label, Textbox
    Extras: Notifications, Watermark, Player List, Theme System, Visibility Keybind
]]

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------
local Players        = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local CoreGui        = game:GetService("CoreGui")
local HttpService    = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()
local Camera      = workspace.CurrentCamera

----------------------------------------------------------------
-- LIBRARY TABLE
----------------------------------------------------------------
local Library = {
    Name        = "Bitch Bot",
    Version     = "3.0",
    Flags       = {},           -- all widget values live here
    Connections = {},           -- all RBXScriptConnections for cleanup
    Themes      = {},           -- registered themes
    ActiveTheme = nil,
    Watermark   = nil,
    Notifications = {},
    Windows     = {},
    Unloaded    = false,
    VisibilityKey = Enum.KeyCode.Insert,
    Visible     = true,
}
Library.__index = Library

----------------------------------------------------------------
-- THEME SYSTEM
----------------------------------------------------------------
Library.Themes.Default = {
    Background    = Color3.fromRGB(18,  18,  20),   -- deepest bg
    Surface       = Color3.fromRGB(26,  26,  30),   -- panel bg
    Elevated      = Color3.fromRGB(34,  34,  40),   -- section / sub-panel
    Outline       = Color3.fromRGB(50,  50,  60),   -- borders
    OutlineFaint  = Color3.fromRGB(38,  38,  46),   -- subtle dividers
    Accent        = Color3.fromRGB(130, 80,  220),  -- purple accent
    AccentDim     = Color3.fromRGB(80,  50,  140),  -- dimmed accent (slider track bg)
    Text          = Color3.fromRGB(230, 230, 235),  -- primary text
    TextDim       = Color3.fromRGB(140, 140, 155),  -- secondary / disabled text
    TextAccent    = Color3.fromRGB(180, 140, 255),  -- accent-colored text
    CheckFill     = Color3.fromRGB(130, 80,  220),  -- toggle on fill
    CheckBorder   = Color3.fromRGB(90,  60,  160),  -- toggle border
    SliderFill    = Color3.fromRGB(130, 80,  220),
    SliderTrack   = Color3.fromRGB(45,  45,  55),
    NotifBg       = Color3.fromRGB(22,  22,  28),
    NotifAccent   = Color3.fromRGB(130, 80,  220),
    WatermarkBg   = Color3.fromRGB(18,  18,  20),
    Friendly      = Color3.fromRGB(80,  200, 120),
    Enemy         = Color3.fromRGB(220, 70,  70),
}
Library.Themes.Cobalt = {
    Background    = Color3.fromRGB(10,  14,  26),
    Surface       = Color3.fromRGB(16,  22,  38),
    Elevated      = Color3.fromRGB(22,  30,  50),
    Outline       = Color3.fromRGB(40,  55,  90),
    OutlineFaint  = Color3.fromRGB(28,  38,  62),
    Accent        = Color3.fromRGB(60,  140, 255),
    AccentDim     = Color3.fromRGB(30,  70,  150),
    Text          = Color3.fromRGB(220, 230, 255),
    TextDim       = Color3.fromRGB(120, 140, 190),
    TextAccent    = Color3.fromRGB(120, 180, 255),
    CheckFill     = Color3.fromRGB(60,  140, 255),
    CheckBorder   = Color3.fromRGB(40,  100, 200),
    SliderFill    = Color3.fromRGB(60,  140, 255),
    SliderTrack   = Color3.fromRGB(30,  40,  70),
    NotifBg       = Color3.fromRGB(12,  16,  30),
    NotifAccent   = Color3.fromRGB(60,  140, 255),
    WatermarkBg   = Color3.fromRGB(10,  14,  26),
    Friendly      = Color3.fromRGB(80,  200, 120),
    Enemy         = Color3.fromRGB(220, 70,  70),
}
Library.Themes.Crimson = {
    Background    = Color3.fromRGB(20,  12,  12),
    Surface       = Color3.fromRGB(30,  18,  18),
    Elevated      = Color3.fromRGB(40,  24,  24),
    Outline       = Color3.fromRGB(70,  35,  35),
    OutlineFaint  = Color3.fromRGB(50,  28,  28),
    Accent        = Color3.fromRGB(220, 55,  55),
    AccentDim     = Color3.fromRGB(130, 30,  30),
    Text          = Color3.fromRGB(235, 220, 220),
    TextDim       = Color3.fromRGB(160, 130, 130),
    TextAccent    = Color3.fromRGB(255, 140, 140),
    CheckFill     = Color3.fromRGB(220, 55,  55),
    CheckBorder   = Color3.fromRGB(160, 35,  35),
    SliderFill    = Color3.fromRGB(220, 55,  55),
    SliderTrack   = Color3.fromRGB(55,  28,  28),
    NotifBg       = Color3.fromRGB(22,  12,  12),
    NotifAccent   = Color3.fromRGB(220, 55,  55),
    WatermarkBg   = Color3.fromRGB(20,  12,  12),
    Friendly      = Color3.fromRGB(80,  200, 120),
    Enemy         = Color3.fromRGB(220, 70,  70),
}

Library.ActiveTheme = Library.Themes.Default

-- Themeable objects registry: { object, propertyName, themeKey }
Library._Themed = {}

function Library:T(key)
    return self.ActiveTheme[key] or Color3.new(1,1,1)
end

function Library:Themify(obj, prop, key)
    obj[prop] = self:T(key)
    table.insert(self._Themed, { obj = obj, prop = prop, key = key })
end

function Library:ApplyTheme(themeName)
    local t = self.Themes[themeName]
    if not t then return end
    self.ActiveTheme = t
    for _, entry in ipairs(self._Themed) do
        pcall(function()
            entry.obj[entry.prop] = t[entry.key]
        end)
    end
end

----------------------------------------------------------------
-- UTILITY
----------------------------------------------------------------
local function tween(obj, props, duration, style, dir)
    style = style or Enum.EasingStyle.Quint
    dir   = dir   or Enum.EasingDirection.Out
    local ti = TweenInfo.new(duration or 0.2, style, dir)
    local tw = TweenService:Create(obj, ti, props)
    tw:Play()
    return tw
end

local function conn(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Library.Connections, c)
    return c
end

local function create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            obj[k] = v
        end
    end
    if props.Parent then obj.Parent = props.Parent end
    return obj
end

local function makeStroke(parent, thickness, color, transparency)
    return create("UIStroke", {
        Thickness   = thickness or 1,
        Color       = color or Color3.fromRGB(50,50,60),
        Transparency = transparency or 0,
        LineJoinMode = Enum.LineJoinMode.Miter,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent      = parent,
    })
end

local function makeCorner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 3), Parent = parent })
end

local function makePadding(parent, top, bottom, left, right)
    return create("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft   = UDim.new(0, left   or 0),
        PaddingRight  = UDim.new(0, right  or 0),
        Parent        = parent,
    })
end

----------------------------------------------------------------
-- ROOT SCREENGUI
----------------------------------------------------------------
local ScreenGui = create("ScreenGui", {
    Name             = "BBotV3",
    ResetOnSpawn     = false,
    ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset   = true,
})
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Notification layer (on top of everything)
local NotifLayer = create("Frame", {
    Name              = "NotifLayer",
    Size              = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex            = 999,
    Parent            = ScreenGui,
})

-- Watermark layer
local WatermarkLayer = create("Frame", {
    Name              = "WatermarkLayer",
    Size              = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex            = 100,
    Parent            = ScreenGui,
})

----------------------------------------------------------------
-- DRAGGING HELPER
----------------------------------------------------------------
local function makeDraggable(titleBar, window)
    local dragging, dragStart, startPos = false, nil, nil
    conn(titleBar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = window.Position
        end
    end)
    conn(titleBar.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    conn(UserInputService.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

----------------------------------------------------------------
-- NOTIFICATION SYSTEM
----------------------------------------------------------------
local NOTIF_WIDTH   = 260
local NOTIF_HEIGHT  = 54
local NOTIF_PAD     = 8
local NOTIF_X       = 12
local NOTIF_BOTTOM  = 16
local notifQueue    = {}

local function shiftNotifs()
    for i, n in ipairs(notifQueue) do
        local targetY = -(NOTIF_BOTTOM + (i - 1) * (NOTIF_HEIGHT + NOTIF_PAD))
        tween(n, { Position = UDim2.new(1, -(NOTIF_WIDTH + NOTIF_X), 1, targetY) }, 0.25)
    end
end

function Library:Notify(opts)
    opts = opts or {}
    local title   = opts.Title   or "Notification"
    local message = opts.Message or ""
    local duration = opts.Duration or 4
    local accent  = opts.Accent or self:T("NotifAccent")

    -- container
    local frame = create("Frame", {
        Name              = "Notif",
        Size              = UDim2.new(0, NOTIF_WIDTH, 0, NOTIF_HEIGHT),
        Position          = UDim2.new(1, NOTIF_WIDTH + NOTIF_X, 1, -(NOTIF_BOTTOM)),
        BackgroundColor3  = self:T("NotifBg"),
        BorderSizePixel   = 0,
        ZIndex            = 999,
        Parent            = NotifLayer,
        ClipsDescendants  = true,
    })
    makeCorner(frame, 4)
    self:Themify(frame, "BackgroundColor3", "NotifBg")

    -- left accent bar
    local bar = create("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        ZIndex           = 1000,
        Parent           = frame,
    })
    makeCorner(bar, 2)

    -- outline
    local stroke = makeStroke(frame, 1, self:T("Outline"))
    self:Themify(stroke, "Color", "Outline")

    -- title
    local titleLbl = create("TextLabel", {
        Size              = UDim2.new(1, -16, 0, 18),
        Position          = UDim2.new(0, 12, 0, 7),
        BackgroundTransparency = 1,
        Text              = title,
        TextColor3        = self:T("Text"),
        TextSize          = 13,
        Font              = Enum.Font.GothamBold,
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 1000,
        Parent            = frame,
    })
    self:Themify(titleLbl, "TextColor3", "Text")

    -- message
    local msgLbl = create("TextLabel", {
        Size              = UDim2.new(1, -16, 0, 16),
        Position          = UDim2.new(0, 12, 0, 28),
        BackgroundTransparency = 1,
        Text              = message,
        TextColor3        = self:T("TextDim"),
        TextSize          = 11,
        Font              = Enum.Font.Gotham,
        TextXAlignment    = Enum.TextXAlignment.Left,
        TextTruncate      = Enum.TextTruncate.AtEnd,
        ZIndex            = 1000,
        Parent            = frame,
    })
    self:Themify(msgLbl, "TextColor3", "TextDim")

    -- progress bar (shrinks over duration)
    local progBg = create("Frame", {
        Size             = UDim2.new(1, -6, 0, 2),
        Position         = UDim2.new(0, 3, 1, -3),
        BackgroundColor3 = self:T("SliderTrack"),
        BorderSizePixel  = 0,
        ZIndex           = 1001,
        Parent           = frame,
    })
    self:Themify(progBg, "BackgroundColor3", "SliderTrack")
    local prog = create("Frame", {
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        ZIndex           = 1002,
        Parent           = progBg,
    })
    makeCorner(progBg, 1)
    makeCorner(prog, 1)

    table.insert(notifQueue, 1, frame)
    shiftNotifs()

    -- slide in
    local targetY = -(NOTIF_BOTTOM)
    tween(frame, { Position = UDim2.new(1, -(NOTIF_WIDTH + NOTIF_X), 1, targetY) }, 0.3)

    -- progress drain
    tween(prog, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)

    -- expire
    task.delay(duration, function()
        tween(frame, { Position = UDim2.new(1, NOTIF_WIDTH + NOTIF_X, 1, targetY) }, 0.25)
        task.wait(0.3)
        local idx = table.find(notifQueue, frame)
        if idx then table.remove(notifQueue, idx) end
        frame:Destroy()
        shiftNotifs()
    end)
end

----------------------------------------------------------------
-- WATERMARK
----------------------------------------------------------------
function Library:SetupWatermark(opts)
    opts = opts or {}
    local text = opts.Text or (self.Name .. " v" .. self.Version)
    local key  = opts.Key  or Enum.KeyCode.Unknown  -- optional toggle key

    local frame = create("Frame", {
        Name              = "Watermark",
        Size              = UDim2.new(0, 180, 0, 24),
        Position          = UDim2.new(0, 12, 0, 12),
        BackgroundColor3  = self:T("WatermarkBg"),
        BorderSizePixel   = 0,
        Parent            = WatermarkLayer,
    })
    makeCorner(frame, 3)
    local stroke = makeStroke(frame, 1, self:T("Outline"))
    self:Themify(frame,  "BackgroundColor3", "WatermarkBg")
    self:Themify(stroke, "Color", "Outline")

    -- accent left pip
    local pip = create("Frame", {
        Size             = UDim2.new(0, 3, 0, 14),
        Position         = UDim2.new(0, 4, 0.5, -7),
        BackgroundColor3 = self:T("Accent"),
        BorderSizePixel  = 0,
        Parent           = frame,
    })
    makeCorner(pip, 2)
    self:Themify(pip, "BackgroundColor3", "Accent")

    local lbl = create("TextLabel", {
        Size              = UDim2.new(1, -16, 1, 0),
        Position          = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text              = text,
        TextColor3        = self:T("Text"),
        TextSize          = 12,
        Font              = Enum.Font.GothamBold,
        TextXAlignment    = Enum.TextXAlignment.Left,
        Parent            = frame,
    })
    self:Themify(lbl, "TextColor3", "Text")

    self.Watermark = { Frame = frame, Label = lbl }
    return self.Watermark
end

function Library:SetWatermarkText(text)
    if self.Watermark then
        self.Watermark.Label.Text = text
    end
end

----------------------------------------------------------------
-- WINDOW
----------------------------------------------------------------
function Library:CreateWindow(opts)
    opts = opts or {}
    local title    = opts.Title    or self.Name
    local size     = opts.Size     or Vector2.new(560, 420)
    local position = opts.Position or UDim2.new(0.5, -size.X/2, 0.5, -size.Y/2)

    local win = {
        Tabs     = {},
        ActiveTab = nil,
        _tabBtns  = {},
    }

    ----------------------------------------------------------------
    -- WINDOW FRAME
    ----------------------------------------------------------------
    local windowFrame = create("Frame", {
        Name              = "Window",
        Size              = UDim2.new(0, size.X, 0, size.Y),
        Position          = position,
        BackgroundColor3  = self:T("Background"),
        BorderSizePixel   = 0,
        ClipsDescendants  = false,
        Parent            = ScreenGui,
    })
    makeCorner(windowFrame, 5)
    local winStroke = makeStroke(windowFrame, 1, self:T("Outline"))
    self:Themify(windowFrame, "BackgroundColor3", "Background")
    self:Themify(winStroke,   "Color",            "Outline")
    win.Frame = windowFrame

    ----------------------------------------------------------------
    -- TITLE BAR
    ----------------------------------------------------------------
    local titleBar = create("Frame", {
        Name             = "TitleBar",
        Size             = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = self:T("Surface"),
        BorderSizePixel  = 0,
        ZIndex           = 2,
        Parent           = windowFrame,
    })
    makeCorner(titleBar, 5)
    self:Themify(titleBar, "BackgroundColor3", "Surface")

    -- bottom border of title bar
    local titleBorder = create("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = self:T("Outline"),
        BorderSizePixel  = 0,
        Parent           = titleBar,
    })
    self:Themify(titleBorder, "BackgroundColor3", "Outline")

    -- accent pip
    local titlePip = create("Frame", {
        Size             = UDim2.new(0, 3, 0, 14),
        Position         = UDim2.new(0, 8, 0.5, -7),
        BackgroundColor3 = self:T("Accent"),
        BorderSizePixel  = 0,
        Parent           = titleBar,
    })
    makeCorner(titlePip, 2)
    self:Themify(titlePip, "BackgroundColor3", "Accent")

    local titleLbl = create("TextLabel", {
        Size              = UDim2.new(1, -20, 1, 0),
        Position          = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text              = title,
        TextColor3        = self:T("Text"),
        TextSize          = 13,
        Font              = Enum.Font.GothamBold,
        TextXAlignment    = Enum.TextXAlignment.Left,
        Parent            = titleBar,
    })
    self:Themify(titleLbl, "TextColor3", "Text")

    makeDraggable(titleBar, windowFrame)

    ----------------------------------------------------------------
    -- TAB BAR
    ----------------------------------------------------------------
    local tabBar = create("Frame", {
        Name             = "TabBar",
        Size             = UDim2.new(1, 0, 0, 26),
        Position         = UDim2.new(0, 0, 0, 28),
        BackgroundColor3 = self:T("Surface"),
        BorderSizePixel  = 0,
        Parent           = windowFrame,
    })
    self:Themify(tabBar, "BackgroundColor3", "Surface")

    local tabBarBorder = create("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = self:T("Outline"),
        BorderSizePixel  = 0,
        Parent           = tabBar,
    })
    self:Themify(tabBarBorder, "BackgroundColor3", "Outline")

    local tabList = create("Frame", {
        Size              = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent            = tabBar,
    })
    create("UIListLayout", {
        FillDirection  = Enum.FillDirection.Horizontal,
        SortOrder      = Enum.SortOrder.LayoutOrder,
        Padding        = UDim.new(0, 0),
        Parent         = tabList,
    })
    makePadding(tabList, 0, 0, 6, 6)

    ----------------------------------------------------------------
    -- CONTENT AREA
    ----------------------------------------------------------------
    local content = create("Frame", {
        Name              = "Content",
        Size              = UDim2.new(1, 0, 1, -54),
        Position          = UDim2.new(0, 0, 0, 54),
        BackgroundTransparency = 1,
        ClipsDescendants  = true,
        Parent            = windowFrame,
    })
    win.Content = content

    ----------------------------------------------------------------
    -- VISIBILITY TOGGLE
    ----------------------------------------------------------------
    conn(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if input.KeyCode == Library.VisibilityKey then
            Library.Visible = not Library.Visible
            windowFrame.Visible = Library.Visible
        end
    end)

    ----------------------------------------------------------------
    -- TAB CONSTRUCTOR
    ----------------------------------------------------------------
    function win:Tab(tabOpts)
        tabOpts = tabOpts or {}
        local tabName   = tabOpts.Name or ("Tab" .. #self.Tabs + 1)
        local isIconTab = tabOpts.Icon ~= nil  -- for Misc icon tabs

        local tab = {
            Name     = tabName,
            Panels   = {},
            _panelBtns = {},
            ActivePanel = nil,
        }

        -- tab button
        local tbtn = create("TextButton", {
            Name              = "Tab_" .. tabName,
            Size              = UDim2.new(0, 0, 1, 0),
            AutomaticSize     = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text              = tabName,
            TextColor3        = Library:T("TextDim"),
            TextSize          = 12,
            Font              = Enum.Font.Gotham,
            AutoButtonColor   = false,
            Parent            = tabList,
        })
        makePadding(tbtn, 0, 0, 10, 10)
        self:Themify(tbtn, "TextColor3", "TextDim")

        -- underline indicator
        local underline = create("Frame", {
            Size             = UDim2.new(1, -16, 0, 2),
            Position         = UDim2.new(0, 8, 1, -2),
            BackgroundColor3 = Library:T("Accent"),
            BorderSizePixel  = 0,
            Visible          = false,
            Parent           = tbtn,
        })
        self:Themify(underline, "BackgroundColor3", "Accent")

        -- tab content frame
        local tabFrame = create("Frame", {
            Name              = "TabFrame_" .. tabName,
            Size              = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible           = false,
            Parent            = content,
        })
        tab.Frame = tabFrame

        table.insert(self.Tabs, tab)
        table.insert(self._tabBtns, { btn = tbtn, underline = underline, tab = tab })

        local function selectTab()
            -- deselect all
            for _, entry in ipairs(self._tabBtns) do
                entry.underline.Visible = false
                tween(entry.btn, { TextColor3 = Library:T("TextDim") }, 0.15)
                entry.tab.Frame.Visible = false
            end
            -- select this
            underline.Visible = true
            tween(tbtn, { TextColor3 = Library:T("Text") }, 0.15)
            tabFrame.Visible = true
            self.ActiveTab = tab
        end

        conn(tbtn.MouseButton1Click, selectTab)

        -- auto-select first tab
        if #self.Tabs == 1 then
            selectTab()
        end

        ----------------------------------------------------------------
        -- TWO-COLUMN LAYOUT inside tab
        ----------------------------------------------------------------
        local leftCol = create("Frame", {
            Name              = "LeftCol",
            Size              = UDim2.new(0.5, -4, 1, 0),
            Position          = UDim2.new(0, 4, 0, 4),
            BackgroundTransparency = 1,
            Parent            = tabFrame,
        })
        local rightCol = create("Frame", {
            Name              = "RightCol",
            Size              = UDim2.new(0.5, -8, 1, 0),
            Position          = UDim2.new(0.5, 4, 0, 4),
            BackgroundTransparency = 1,
            Parent            = tabFrame,
        })

        local leftScroll = create("ScrollingFrame", {
            Size              = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel   = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library:T("Accent"),
            CanvasSize        = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent            = leftCol,
        })
        Library:Themify(leftScroll, "ScrollBarImageColor3", "Accent")

        local rightScroll = create("ScrollingFrame", {
            Size              = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel   = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library:T("Accent"),
            CanvasSize        = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent            = rightCol,
        })
        Library:Themify(rightScroll, "ScrollBarImageColor3", "Accent")

        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 5),
            Parent    = leftScroll,
        })
        makePadding(leftScroll, 4, 4, 4, 4)

        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 5),
            Parent    = rightScroll,
        })
        makePadding(rightScroll, 4, 4, 4, 4)

        tab.LeftScroll  = leftScroll
        tab.RightScroll = rightScroll

        ----------------------------------------------------------------
        -- PANEL (named section block with optional sub-tab bar)
        ----------------------------------------------------------------
        function tab:Panel(panelOpts)
            panelOpts = panelOpts or {}
            local panelName = panelOpts.Name  or "Panel"
            local side      = panelOpts.Side  or "Left"   -- "Left" | "Right"
            local subTabs   = panelOpts.SubTabs or {}      -- list of sub-tab name strings

            local parent = side == "Right" and rightScroll or leftScroll

            local panel = {
                Name       = panelName,
                SubTabs    = {},
                ActiveSub  = nil,
                _subBtns   = {},
                Widgets    = {},
            }

            -- panel container
            local panelFrame = create("Frame", {
                Name              = "Panel_" .. panelName,
                Size              = UDim2.new(1, 0, 0, 0),
                AutomaticSize     = Enum.AutomaticSize.Y,
                BackgroundColor3  = Library:T("Surface"),
                BorderSizePixel   = 0,
                Parent            = parent,
                LayoutOrder       = #(side == "Right" and tab.Panels or tab.Panels) + 1,
            })
            makeCorner(panelFrame, 4)
            local panelStroke = makeStroke(panelFrame, 1, Library:T("Outline"))
            Library:Themify(panelFrame,  "BackgroundColor3", "Surface")
            Library:Themify(panelStroke, "Color",            "Outline")

            local panelLayout = create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0, 0),
                Parent    = panelFrame,
            })

            -- panel header row (holds sub-tab buttons)
            local headerRow = create("Frame", {
                Name              = "Header",
                Size              = UDim2.new(1, 0, 0, 24),
                BackgroundColor3  = Library:T("Elevated"),
                BorderSizePixel   = 0,
                LayoutOrder       = 0,
                Parent            = panelFrame,
            })
            makeCorner(headerRow, 4)
            Library:Themify(headerRow, "BackgroundColor3", "Elevated")

            -- bottom border of header
            local hdrBorder = create("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                Position         = UDim2.new(0, 0, 1, -1),
                BackgroundColor3 = Library:T("Outline"),
                BorderSizePixel  = 0,
                Parent           = headerRow,
            })
            Library:Themify(hdrBorder, "BackgroundColor3", "Outline")

            local subTabList = create("Frame", {
                Size              = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Parent            = headerRow,
            })
            create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder     = Enum.SortOrder.LayoutOrder,
                Padding       = UDim.new(0, 0),
                Parent        = subTabList,
            })
            makePadding(subTabList, 0, 0, 6, 0)

            -- widget area (for active sub-tab content)
            local widgetArea = create("Frame", {
                Name              = "WidgetArea",
                Size              = UDim2.new(1, 0, 0, 0),
                AutomaticSize     = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder       = 1,
                Parent            = panelFrame,
            })
            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0, 0),
                Parent    = widgetArea,
            })
            makePadding(widgetArea, 4, 6, 0, 0)

            panel.PanelFrame = panelFrame
            panel.WidgetArea = widgetArea

            ----------------------------------------------------------------
            -- SUB-TAB SYSTEM
            ----------------------------------------------------------------
            local subFrames = {}  -- subName → Frame

            local function selectSub(subName)
                for sn, sf in pairs(subFrames) do
                    sf.Visible = (sn == subName)
                end
                for _, entry in ipairs(panel._subBtns) do
                    local active = entry.name == subName
                    tween(entry.btn, {
                        TextColor3 = active and Library:T("TextAccent") or Library:T("TextDim")
                    }, 0.12)
                    entry.underline.Visible = active
                end
                panel.ActiveSub = subName
            end

            -- build sub-tab buttons from provided list
            for i, subName in ipairs(subTabs) do
                local sbtn = create("TextButton", {
                    Name              = "Sub_" .. subName,
                    Size              = UDim2.new(0, 0, 1, 0),
                    AutomaticSize     = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    Text              = subName,
                    TextColor3        = Library:T("TextDim"),
                    TextSize          = 11,
                    Font              = Enum.Font.Gotham,
                    AutoButtonColor   = false,
                    Parent            = subTabList,
                })
                makePadding(sbtn, 0, 0, 8, 8)
                Library:Themify(sbtn, "TextColor3", "TextDim")

                local subUnderline = create("Frame", {
                    Size             = UDim2.new(1, -12, 0, 2),
                    Position         = UDim2.new(0, 6, 1, -2),
                    BackgroundColor3 = Library:T("Accent"),
                    BorderSizePixel  = 0,
                    Visible          = false,
                    Parent           = sbtn,
                })
                Library:Themify(subUnderline, "BackgroundColor3", "Accent")

                -- sub-tab content frame
                local subFrame = create("Frame", {
                    Name              = "Sub_" .. subName,
                    Size              = UDim2.new(1, 0, 0, 0),
                    AutomaticSize     = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Visible           = false,
                    Parent            = widgetArea,
                })
                create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding   = UDim.new(0, 0),
                    Parent    = subFrame,
                })
                subFrames[subName] = subFrame

                table.insert(panel._subBtns, { name = subName, btn = sbtn, underline = subUnderline })
                conn(sbtn.MouseButton1Click, function() selectSub(subName) end)

                if i == 1 then
                    selectSub(subName)
                end
            end

            -- if no sub-tabs, just one default frame in widgetArea
            if #subTabs == 0 then
                local defaultFrame = create("Frame", {
                    Name              = "DefaultSub",
                    Size              = UDim2.new(1, 0, 0, 0),
                    AutomaticSize     = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                    Visible           = true,
                    Parent            = widgetArea,
                })
                create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding   = UDim.new(0, 0),
                    Parent    = defaultFrame,
                })
                subFrames["_default"] = defaultFrame
                panel.ActiveSub = "_default"
            end

            ----------------------------------------------------------------
            -- WIDGET HELPER: get current sub frame
            ----------------------------------------------------------------
            local function getSubFrame(subName)
                if subName then
                    return subFrames[subName]
                end
                return subFrames[panel.ActiveSub] or subFrames["_default"]
            end

            ----------------------------------------------------------------
            -- WIDGET ROW BASE
            ----------------------------------------------------------------
            local function makeRow(subName, height)
                local sf = getSubFrame(subName)
                if not sf then return nil end
                local row = create("Frame", {
                    Size              = UDim2.new(1, 0, 0, height or 22),
                    BackgroundTransparency = 1,
                    Parent            = sf,
                })
                return row
            end

            ----------------------------------------------------------------
            -- TOGGLE
            ----------------------------------------------------------------
            function panel:Toggle(opts)
                opts = opts or {}
                local label    = opts.Name     or "Toggle"
                local flag     = opts.Flag     or label
                local default  = opts.Default  ~= nil and opts.Default or false
                local keybind  = opts.Keybind  -- Enum.KeyCode or nil
                local sub      = opts.Sub
                local callback = opts.Callback or function() end

                Library.Flags[flag] = default

                local row = makeRow(sub, 22)
                if not row then return end
                makePadding(row, 0, 0, 8, 6)

                -- checkbox
                local box = create("Frame", {
                    Size             = UDim2.new(0, 11, 0, 11),
                    Position         = UDim2.new(0, 0, 0.5, -5),
                    BackgroundColor3 = default and Library:T("CheckFill") or Library:T("Surface"),
                    BorderSizePixel  = 0,
                    Parent           = row,
                })
                makeCorner(box, 2)
                local boxStroke = makeStroke(box, 1, Library:T("CheckBorder"))
                Library:Themify(boxStroke, "Color", "CheckBorder")

                -- check mark (simple inner dot)
                local check = create("Frame", {
                    Size             = UDim2.new(0, 5, 0, 5),
                    Position         = UDim2.new(0.5, -2, 0.5, -2),
                    BackgroundColor3 = Color3.new(1,1,1),
                    BorderSizePixel  = 0,
                    Visible          = default,
                    Parent           = box,
                })
                makeCorner(check, 1)

                local lbl = create("TextLabel", {
                    Size              = UDim2.new(1, -80, 1, 0),
                    Position          = UDim2.new(0, 18, 0, 0),
                    BackgroundTransparency = 1,
                    Text              = label,
                    TextColor3        = Library:T("Text"),
                    TextSize          = 12,
                    Font              = Enum.Font.Gotham,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    Parent            = row,
                })
                Library:Themify(lbl, "TextColor3", "Text")

                -- keybind label
                local kbLbl = nil
                if keybind then
                    kbLbl = create("TextLabel", {
                        Size              = UDim2.new(0, 36, 1, 0),
                        Position          = UDim2.new(1, -40, 0, 0),
                        BackgroundTransparency = 1,
                        Text              = keybind.Name or "?",
                        TextColor3        = Library:T("TextDim"),
                        TextSize          = 11,
                        Font              = Enum.Font.Gotham,
                        TextXAlignment    = Enum.TextXAlignment.Right,
                        Parent            = row,
                    })
                    Library:Themify(kbLbl, "TextColor3", "TextDim")
                end

                -- click area
                local btn = create("TextButton", {
                    Size              = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text              = "",
                    AutoButtonColor   = false,
                    Parent            = row,
                })

                local value = default
                local function setValue(v)
                    value = v
                    Library.Flags[flag] = v
                    tween(box, { BackgroundColor3 = v and Library:T("CheckFill") or Library:T("Surface") }, 0.12)
                    check.Visible = v
                    pcall(callback, v)
                end

                conn(btn.MouseButton1Click, function()
                    setValue(not value)
                end)

                if keybind then
                    conn(UserInputService.InputBegan, function(input, gpe)
                        if gpe then return end
                        if input.KeyCode == keybind then
                            setValue(not value)
                        end
                    end)
                end

                return { SetValue = setValue, GetValue = function() return value end }
            end

            ----------------------------------------------------------------
            -- SLIDER
            ----------------------------------------------------------------
            function panel:Slider(opts)
                opts = opts or {}
                local label   = opts.Name    or "Slider"
                local flag    = opts.Flag    or label
                local min     = opts.Min     or 0
                local max     = opts.Max     or 100
                local default = opts.Default or min
                local step    = opts.Step    or 0.1
                local suffix  = opts.Suffix  or ""
                local sub     = opts.Sub
                local callback = opts.Callback or function() end

                Library.Flags[flag] = default

                local row = makeRow(sub, 34)
                if not row then return end
                makePadding(row, 2, 2, 8, 6)

                -- top row: label + value
                local topRow = create("Frame", {
                    Size              = UDim2.new(1, 0, 0, 14),
                    BackgroundTransparency = 1,
                    Parent            = row,
                })
                local nameLbl = create("TextLabel", {
                    Size              = UDim2.new(0.6, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text              = label,
                    TextColor3        = Library:T("Text"),
                    TextSize          = 12,
                    Font              = Enum.Font.Gotham,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    Parent            = topRow,
                })
                Library:Themify(nameLbl, "TextColor3", "Text")

                -- step buttons + value
                local stepDown = create("TextButton", {
                    Size              = UDim2.new(0, 14, 0, 14),
                    Position          = UDim2.new(1, -56, 0, 0),
                    BackgroundColor3  = Library:T("Elevated"),
                    BorderSizePixel   = 0,
                    Text              = "-",
                    TextColor3        = Library:T("TextDim"),
                    TextSize          = 13,
                    Font              = Enum.Font.GothamBold,
                    AutoButtonColor   = false,
                    Parent            = topRow,
                })
                makeCorner(stepDown, 2)
                Library:Themify(stepDown, "BackgroundColor3", "Elevated")
                Library:Themify(stepDown, "TextColor3", "TextDim")

                local valLbl = create("TextLabel", {
                    Size              = UDim2.new(0, 24, 0, 14),
                    Position          = UDim2.new(1, -40, 0, 0),
                    BackgroundTransparency = 1,
                    Text              = tostring(default) .. suffix,
                    TextColor3        = Library:T("TextAccent"),
                    TextSize          = 11,
                    Font              = Enum.Font.Gotham,
                    TextXAlignment    = Enum.TextXAlignment.Center,
                    Parent            = topRow,
                })
                Library:Themify(valLbl, "TextColor3", "TextAccent")

                local stepUp = create("TextButton", {
                    Size              = UDim2.new(0, 14, 0, 14),
                    Position          = UDim2.new(1, -14, 0, 0),
                    BackgroundColor3  = Library:T("Elevated"),
                    BorderSizePixel   = 0,
                    Text              = "+",
                    TextColor3        = Library:T("TextDim"),
                    TextSize          = 13,
                    Font              = Enum.Font.GothamBold,
                    AutoButtonColor   = false,
                    Parent            = topRow,
                })
                makeCorner(stepUp, 2)
                Library:Themify(stepUp, "BackgroundColor3", "Elevated")
                Library:Themify(stepUp, "TextColor3", "TextDim")

                -- slider track
                local trackBg = create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 6),
                    Position         = UDim2.new(0, 0, 0, 20),
                    BackgroundColor3 = Library:T("SliderTrack"),
                    BorderSizePixel  = 0,
                    Parent           = row,
                })
                makeCorner(trackBg, 3)
                Library:Themify(trackBg, "BackgroundColor3", "SliderTrack")

                local trackFill = create("Frame", {
                    Size             = UDim2.new((default - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = Library:T("SliderFill"),
                    BorderSizePixel  = 0,
                    Parent           = trackBg,
                })
                makeCorner(trackFill, 3)
                Library:Themify(trackFill, "BackgroundColor3", "SliderFill")

                -- thumb
                local thumb = create("Frame", {
                    Size             = UDim2.new(0, 8, 0, 8),
                    AnchorPoint      = Vector2.new(0.5, 0.5),
                    Position         = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
                    BackgroundColor3 = Color3.new(1,1,1),
                    BorderSizePixel  = 0,
                    ZIndex           = 2,
                    Parent           = trackBg,
                })
                makeCorner(thumb, 4)

                local value   = default
                local sliding = false

                local function setValue(v)
                    v = math.clamp(math.round(v / step) * step, min, max)
                    v = math.floor(v * 1000 + 0.5) / 1000
                    value = v
                    Library.Flags[flag] = v
                    local pct = (v - min) / (max - min)
                    tween(trackFill, { Size = UDim2.new(pct, 0, 1, 0) }, 0.06)
                    tween(thumb,     { Position = UDim2.new(pct, 0, 0.5, 0) }, 0.06)
                    valLbl.Text = tostring(math.floor(v * 10 + 0.5) / 10) .. suffix
                    pcall(callback, v)
                end

                local clickArea = create("TextButton", {
                    Size              = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text              = "",
                    AutoButtonColor   = false,
                    ZIndex            = 3,
                    Parent            = trackBg,
                })
                conn(clickArea.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = true
                    end
                end)
                conn(clickArea.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = false
                    end
                end)
                conn(UserInputService.InputChanged, function(input)
                    if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local abs   = trackBg.AbsolutePosition
                        local sz    = trackBg.AbsoluteSize
                        local pct   = math.clamp((Mouse.X - abs.X) / sz.X, 0, 1)
                        setValue(min + (max - min) * pct)
                    end
                end)

                conn(stepDown.MouseButton1Click, function() setValue(value - step) end)
                conn(stepUp.MouseButton1Click,   function() setValue(value + step) end)

                return { SetValue = setValue, GetValue = function() return value end }
            end

            ----------------------------------------------------------------
            -- DROPDOWN
            ----------------------------------------------------------------
            function panel:Dropdown(opts)
                opts = opts or {}
                local label   = opts.Name    or "Dropdown"
                local flag    = opts.Flag    or label
                local items   = opts.Items   or {}
                local default = opts.Default or (items[1] or "")
                local sub     = opts.Sub
                local callback = opts.Callback or function() end

                Library.Flags[flag] = default

                local row = makeRow(sub, 38)
                if not row then return end
                makePadding(row, 2, 2, 8, 6)

                local nameLbl = create("TextLabel", {
                    Size              = UDim2.new(1, 0, 0, 14),
                    BackgroundTransparency = 1,
                    Text              = label,
                    TextColor3        = Library:T("TextDim"),
                    TextSize          = 11,
                    Font              = Enum.Font.Gotham,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    Parent            = row,
                })
                Library:Themify(nameLbl, "TextColor3", "TextDim")

                local dropBox = create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 20),
                    Position         = UDim2.new(0, 0, 0, 16),
                    BackgroundColor3 = Library:T("Elevated"),
                    BorderSizePixel  = 0,
                    Parent           = row,
                })
                makeCorner(dropBox, 3)
                local dStroke = makeStroke(dropBox, 1, Library:T("Outline"))
                Library:Themify(dropBox,  "BackgroundColor3", "Elevated")
                Library:Themify(dStroke,  "Color",            "Outline")

                local valLbl = create("TextLabel", {
                    Size              = UDim2.new(1, -24, 1, 0),
                    Position          = UDim2.new(0, 8, 0, 0),
                    BackgroundTransparency = 1,
                    Text              = default,
                    TextColor3        = Library:T("Text"),
                    TextSize          = 11,
                    Font              = Enum.Font.Gotham,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    Parent            = dropBox,
                })
                Library:Themify(valLbl, "TextColor3", "Text")

                local arrow = create("TextLabel", {
                    Size              = UDim2.new(0, 16, 1, 0),
                    Position          = UDim2.new(1, -18, 0, 0),
                    BackgroundTransparency = 1,
                    Text              = "▾",
                    TextColor3        = Library:T("TextDim"),
                    TextSize          = 12,
                    Font              = Enum.Font.Gotham,
                    TextXAlignment    = Enum.TextXAlignment.Center,
                    Parent            = dropBox,
                })
                Library:Themify(arrow, "TextColor3", "TextDim")

                -- dropdown list (appears below)
                local listFrame = create("Frame", {
                    Size              = UDim2.new(1, 0, 0, 0),
                    Position          = UDim2.new(0, 0, 1, 2),
                    BackgroundColor3  = Library:T("Surface"),
                    BorderSizePixel   = 0,
                    Visible           = false,
                    ZIndex            = 50,
                    ClipsDescendants  = true,
                    Parent            = dropBox,
                })
                makeCorner(listFrame, 3)
                local lfStroke = makeStroke(listFrame, 1, Library:T("Outline"))
                Library:Themify(listFrame, "BackgroundColor3", "Surface")
                Library:Themify(lfStroke,  "Color",            "Outline")

                local listLayout = create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding   = UDim.new(0, 0),
                    Parent    = listFrame,
                })

                local value = default
                local open  = false

                local function buildList()
                    for _, c in ipairs(listFrame:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for _, item in ipairs(items) do
                        local itm = create("TextButton", {
                            Size              = UDim2.new(1, 0, 0, 20),
                            BackgroundColor3  = Library:T("Elevated"),
                            BorderSizePixel   = 0,
                            Text              = "  " .. item,
                            TextColor3        = item == value and Library:T("TextAccent") or Library:T("Text"),
                            TextSize          = 11,
                            Font              = Enum.Font.Gotham,
                            TextXAlignment    = Enum.TextXAlignment.Left,
                            AutoButtonColor   = false,
                            ZIndex            = 51,
                            Parent            = listFrame,
                        })
                        Library:Themify(itm, "BackgroundColor3", "Elevated")
                        conn(itm.MouseEnter, function()
                            tween(itm, { BackgroundColor3 = Library:T("Surface") }, 0.08)
                        end)
                        conn(itm.MouseLeave, function()
                            tween(itm, { BackgroundColor3 = Library:T("Elevated") }, 0.08)
                        end)
                        conn(itm.MouseButton1Click, function()
                            value = item
                            Library.Flags[flag] = item
                            valLbl.Text = item
                            pcall(callback, item)
                            -- close
                            open = false
                            tween(listFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                            task.delay(0.15, function() listFrame.Visible = false end)
                            tween(arrow, { Rotation = 0 }, 0.15)
                        end)
                    end
                    local totalH = #items * 20
                    return totalH
                end

                local dropBtn = create("TextButton", {
                    Size              = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text              = "",
                    AutoButtonColor   = false,
                    ZIndex            = 5,
                    Parent            = dropBox,
                })
                conn(dropBtn.MouseButton1Click, function()
                    open = not open
                    if open then
                        local totalH = buildList()
                        listFrame.Visible = true
                        listFrame.Size = UDim2.new(1, 0, 0, 0)
                        tween(listFrame, { Size = UDim2.new(1, 0, 0, math.min(totalH, 120)) }, 0.15)
                        tween(arrow, { Rotation = 180 }, 0.15)
                    else
                        tween(listFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                        task.delay(0.15, function() listFrame.Visible = false end)
                        tween(arrow, { Rotation = 0 }, 0.15)
                    end
                end)

                local function setItems(newItems)
                    items = newItems
                end

                return {
                    SetItems   = setItems,
                    SetValue   = function(v)
                        value = v
                        Library.Flags[flag] = v
                        valLbl.Text = v
                    end,
                    GetValue   = function() return value end,
                }
            end

            ----------------------------------------------------------------
            -- KEYBIND
            ----------------------------------------------------------------
            function panel:Keybind(opts)
                opts = opts or {}
                local label   = opts.Name    or "Keybind"
                local flag    = opts.Flag    or label
                local default = opts.Default or Enum.KeyCode.Unknown
                local sub     = opts.Sub
                local callback = opts.Callback or function() end

                local Keys = {
                    [Enum.KeyCode.LeftShift]   = "LShift",
                    [Enum.KeyCode.RightShift]  = "RShift",
                    [Enum.KeyCode.LeftControl] = "LCtrl",
                    [Enum.KeyCode.RightControl]= "RCtrl",
                    [Enum.KeyCode.LeftAlt]     = "LAlt",
                    [Enum.KeyCode.Insert]      = "INS",
                    [Enum.KeyCode.Delete]      = "DEL",
                    [Enum.KeyCode.Return]      = "Enter",
                    [Enum.KeyCode.Backspace]   = "BS",
                    [Enum.KeyCode.CapsLock]    = "Caps",
                    [Enum.UserInputType.MouseButton1] = "MB1",
                    [Enum.UserInputType.MouseButton2] = "MB2",
                }
                local function keyName(kc)
                    return Keys[kc] or (typeof(kc) == "EnumItem" and kc.Name or tostring(kc))
                end

                Library.Flags[flag] = default

                local row = makeRow(sub, 22)
                if not row then return end
                makePadding(row, 0, 0, 8, 6)

                local nameLbl = create("TextLabel", {
                    Size              = UDim2.new(1, -70, 1, 0),
                    BackgroundTransparency = 1,
                    Text              = label,
                    TextColor3        = Library:T("Text"),
                    TextSize          = 12,
                    Font              = Enum.Font.Gotham,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    Parent            = row,
                })
                Library:Themify(nameLbl, "TextColor3", "Text")

                local kbBox = create("TextButton", {
                    Size              = UDim2.new(0, 50, 0, 16),
                    Position          = UDim2.new(1, -54, 0.5, -8),
                    BackgroundColor3  = Library:T("Elevated"),
                    BorderSizePixel   = 0,
                    Text              = "[" .. keyName(default) .. "]",
                    TextColor3        = Library:T("TextAccent"),
                    TextSize          = 11,
                    Font              = Enum.Font.Gotham,
                    AutoButtonColor   = false,
                    Parent            = row,
                })
                makeCorner(kbBox, 3)
                local kbStroke = makeStroke(kbBox, 1, Library:T("Outline"))
                Library:Themify(kbBox,   "BackgroundColor3", "Elevated")
                Library:Themify(kbBox,   "TextColor3",       "TextAccent")
                Library:Themify(kbStroke,"Color",            "Outline")

                local value    = default
                local listening = false

                conn(kbBox.MouseButton1Click, function()
                    if listening then return end
                    listening = true
                    kbBox.Text = "[...]"
                    tween(kbStroke, { Color = Library:T("Accent") }, 0.12)
                    local c
                    c = conn(UserInputService.InputBegan, function(input, gpe)
                        if gpe then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            c:Disconnect()
                            listening = false
                            value = input.KeyCode
                            Library.Flags[flag] = value
                            kbBox.Text = "[" .. keyName(value) .. "]"
                            tween(kbStroke, { Color = Library:T("Outline") }, 0.12)
                            pcall(callback, value)
                        end
                    end)
                end)

                return {
                    GetValue = function() return value end,
                    SetValue = function(v)
                        value = v
                        Library.Flags[flag] = v
                        kbBox.Text = "[" .. keyName(v) .. "]"
                    end,
                }
            end

            ----------------------------------------------------------------
            -- BUTTON
            ----------------------------------------------------------------
            function panel:Button(opts)
                opts = opts or {}
                local label    = opts.Name    or "Button"
                local sub      = opts.Sub
                local callback = opts.Callback or function() end

                local row = makeRow(sub, 24)
                if not row then return end
                makePadding(row, 2, 2, 8, 6)

                local btn = create("TextButton", {
                    Size              = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3  = Library:T("Elevated"),
                    BorderSizePixel   = 0,
                    Text              = label,
                    TextColor3        = Library:T("Text"),
                    TextSize          = 12,
                    Font              = Enum.Font.Gotham,
                    AutoButtonColor   = false,
                    Parent            = row,
                })
                makeCorner(btn, 3)
                local bStroke = makeStroke(btn, 1, Library:T("Outline"))
                Library:Themify(btn,    "BackgroundColor3", "Elevated")
                Library:Themify(btn,    "TextColor3",       "Text")
                Library:Themify(bStroke,"Color",            "Outline")

                conn(btn.MouseEnter, function()
                    tween(btn, { BackgroundColor3 = Library:T("Surface") }, 0.1)
                end)
                conn(btn.MouseLeave, function()
                    tween(btn, { BackgroundColor3 = Library:T("Elevated") }, 0.1)
                end)
                conn(btn.MouseButton1Click, function()
                    tween(bStroke, { Color = Library:T("Accent") }, 0.08)
                    task.delay(0.2, function()
                        tween(bStroke, { Color = Library:T("Outline") }, 0.12)
                    end)
                    pcall(callback)
                end)
            end

            ----------------------------------------------------------------
            -- LABEL
            ----------------------------------------------------------------
            function panel:Label(opts)
                opts = opts or {}
                local text = type(opts) == "string" and opts or (opts.Text or "Label")
                local sub  = type(opts) == "table" and opts.Sub or nil

                local row = makeRow(sub, 18)
                if not row then return end
                makePadding(row, 0, 0, 8, 6)

                local lbl = create("TextLabel", {
                    Size              = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text              = text,
                    TextColor3        = Library:T("TextDim"),
                    TextSize          = 11,
                    Font              = Enum.Font.Gotham,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    Parent            = row,
                })
                Library:Themify(lbl, "TextColor3", "TextDim")

                return {
                    SetText = function(t) lbl.Text = t end,
                }
            end

            ----------------------------------------------------------------
            -- TEXTBOX
            ----------------------------------------------------------------
            function panel:Textbox(opts)
                opts = opts or {}
                local label       = opts.Name        or "Textbox"
                local flag        = opts.Flag        or label
                local placeholder = opts.Placeholder or ""
                local default     = opts.Default     or ""
                local sub         = opts.Sub
                local callback    = opts.Callback or function() end

                Library.Flags[flag] = default

                local row = makeRow(sub, 38)
                if not row then return end
                makePadding(row, 2, 2, 8, 6)

                local nameLbl = create("TextLabel", {
                    Size              = UDim2.new(1, 0, 0, 14),
                    BackgroundTransparency = 1,
                    Text              = label,
                    TextColor3        = Library:T("TextDim"),
                    TextSize          = 11,
                    Font              = Enum.Font.Gotham,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    Parent            = row,
                })
                Library:Themify(nameLbl, "TextColor3", "TextDim")

                local boxFrame = create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 20),
                    Position         = UDim2.new(0, 0, 0, 16),
                    BackgroundColor3 = Library:T("Elevated"),
                    BorderSizePixel  = 0,
                    Parent           = row,
                })
                makeCorner(boxFrame, 3)
                local tbStroke = makeStroke(boxFrame, 1, Library:T("Outline"))
                Library:Themify(boxFrame, "BackgroundColor3", "Elevated")
                Library:Themify(tbStroke, "Color",            "Outline")

                local tb = create("TextBox", {
                    Size              = UDim2.new(1, -10, 1, 0),
                    Position          = UDim2.new(0, 6, 0, 0),
                    BackgroundTransparency = 1,
                    Text              = default,
                    PlaceholderText   = placeholder,
                    TextColor3        = Library:T("Text"),
                    PlaceholderColor3 = Library:T("TextDim"),
                    TextSize          = 11,
                    Font              = Enum.Font.Gotham,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    ClearTextOnFocus  = false,
                    Parent            = boxFrame,
                })
                Library:Themify(tb, "TextColor3", "Text")
                Library:Themify(tb, "PlaceholderColor3", "TextDim")

                conn(tb.Focused,     function() tween(tbStroke, { Color = Library:T("Accent") }, 0.12) end)
                conn(tb.FocusLost,   function(enter)
                    tween(tbStroke, { Color = Library:T("Outline") }, 0.12)
                    Library.Flags[flag] = tb.Text
                    pcall(callback, tb.Text, enter)
                end)

                return {
                    GetValue = function() return tb.Text end,
                    SetValue = function(v) tb.Text = v; Library.Flags[flag] = v end,
                }
            end

            ----------------------------------------------------------------
            -- COLORPICKER (inline swatch)
            ----------------------------------------------------------------
            function panel:Colorpicker(opts)
                opts = opts or {}
                local label   = opts.Name    or "Color"
                local flag    = opts.Flag    or label
                local default = opts.Default or Color3.fromRGB(130,80,220)
                local sub     = opts.Sub
                local callback = opts.Callback or function() end

                Library.Flags[flag] = default

                local row = makeRow(sub, 22)
                if not row then return end
                makePadding(row, 0, 0, 8, 6)

                local nameLbl = create("TextLabel", {
                    Size              = UDim2.new(1, -30, 1, 0),
                    BackgroundTransparency = 1,
                    Text              = label,
                    TextColor3        = Library:T("Text"),
                    TextSize          = 12,
                    Font              = Enum.Font.Gotham,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    Parent            = row,
                })
                Library:Themify(nameLbl, "TextColor3", "Text")

                local swatch = create("Frame", {
                    Size             = UDim2.new(0, 20, 0, 14),
                    Position         = UDim2.new(1, -22, 0.5, -7),
                    BackgroundColor3 = default,
                    BorderSizePixel  = 0,
                    Parent           = row,
                })
                makeCorner(swatch, 3)
                makeStroke(swatch, 1, Library:T("Outline"))

                -- minimal inline colorpicker popup (H/S/V sliders)
                -- full colorpicker popup omitted for brevity — wire in later
                local value = default
                return {
                    GetValue = function() return value end,
                    SetValue = function(v)
                        value = v
                        Library.Flags[flag] = v
                        swatch.BackgroundColor3 = v
                        pcall(callback, v)
                    end,
                }
            end

            ----------------------------------------------------------------
            -- DIVIDER
            ----------------------------------------------------------------
            function panel:Divider(sub)
                local sf = getSubFrame(sub)
                if not sf then return end
                local div = create("Frame", {
                    Size             = UDim2.new(1, -16, 0, 1),
                    Position         = UDim2.new(0, 8, 0, 0),
                    BackgroundColor3 = Library:T("OutlineFaint"),
                    BorderSizePixel  = 0,
                    Parent           = create("Frame", {
                        Size = UDim2.new(1, 0, 0, 5),
                        BackgroundTransparency = 1,
                        Parent = sf,
                    })
                })
                Library:Themify(div, "BackgroundColor3", "OutlineFaint")
            end

            table.insert(tab.Panels, panel)
            return panel
        end -- panel()

        table.insert(self.Tabs, tab)
        return tab
    end -- tab()

    table.insert(Library.Windows, win)
    return win
end -- CreateWindow()

----------------------------------------------------------------
-- PLAYER LIST (Misc Tab special widget)
----------------------------------------------------------------
function Library:CreatePlayerList(parent)
    -- parent: a Frame to put the player list into

    local container = create("Frame", {
        Size              = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent            = parent,
    })

    -- search bar + refresh button
    local topBar = create("Frame", {
        Size             = UDim2.new(1, 0, 0, 24),
        BackgroundColor3 = self:T("Surface"),
        BorderSizePixel  = 0,
        Parent           = container,
    })
    makeCorner(topBar, 3)
    self:Themify(topBar, "BackgroundColor3", "Surface")

    local searchBox = create("TextBox", {
        Size              = UDim2.new(1, -70, 1, -4),
        Position          = UDim2.new(0, 6, 0, 2),
        BackgroundTransparency = 1,
        Text              = "",
        PlaceholderText   = "Search Here",
        TextColor3        = self:T("Text"),
        PlaceholderColor3 = self:T("TextDim"),
        TextSize          = 11,
        Font              = Enum.Font.Gotham,
        TextXAlignment    = Enum.TextXAlignment.Left,
        ClearTextOnFocus  = false,
        Parent            = topBar,
    })
    self:Themify(searchBox, "TextColor3",       "Text")
    self:Themify(searchBox, "PlaceholderColor3","TextDim")

    local refreshBtn = create("TextButton", {
        Size              = UDim2.new(0, 60, 1, -4),
        Position          = UDim2.new(1, -62, 0, 2),
        BackgroundColor3  = self:T("Elevated"),
        BorderSizePixel   = 0,
        Text              = "Refresh",
        TextColor3        = self:T("TextAccent"),
        TextSize          = 11,
        Font              = Enum.Font.Gotham,
        AutoButtonColor   = false,
        Parent            = topBar,
    })
    makeCorner(refreshBtn, 3)
    self:Themify(refreshBtn, "BackgroundColor3", "Elevated")
    self:Themify(refreshBtn, "TextColor3",       "TextAccent")

    -- column headers
    local colHeader = create("Frame", {
        Size             = UDim2.new(1, 0, 0, 18),
        Position         = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = self:T("Elevated"),
        BorderSizePixel  = 0,
        Parent           = container,
    })
    self:Themify(colHeader, "BackgroundColor3", "Elevated")

    local function colLbl(text, xScale, xOffset)
        local l = create("TextLabel", {
            Size              = UDim2.new(0.33, 0, 1, 0),
            Position          = UDim2.new(xScale, xOffset, 0, 0),
            BackgroundTransparency = 1,
            Text              = text,
            TextColor3        = self:T("TextDim"),
            TextSize          = 10,
            Font              = Enum.Font.GothamBold,
            TextXAlignment    = Enum.TextXAlignment.Left,
            Parent            = colHeader,
        })
        self:Themify(l, "TextColor3", "TextDim")
    end
    colLbl("Name",     0,    8)
    colLbl("UserId",   0.35, 0)
    colLbl("Priority", 0.72, 0)

    -- player scroll
    local scroll = create("ScrollingFrame", {
        Size              = UDim2.new(1, 0, 1, -120),
        Position          = UDim2.new(0, 0, 0, 44),
        BackgroundTransparency = 1,
        BorderSizePixel   = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self:T("Accent"),
        CanvasSize        = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent            = container,
    })
    self:Themify(scroll, "ScrollBarImageColor3", "Accent")

    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 1),
        Parent    = scroll,
    })

    -- player info card
    local infoCard = create("Frame", {
        Size             = UDim2.new(0.45, 0, 0, 70),
        Position         = UDim2.new(0, 0, 1, -72),
        BackgroundColor3 = self:T("Surface"),
        BorderSizePixel  = 0,
        Parent           = container,
    })
    makeCorner(infoCard, 3)
    makeStroke(infoCard, 1, self:T("Outline"))
    self:Themify(infoCard, "BackgroundColor3", "Surface")

    -- avatar placeholder
    local ava = create("Frame", {
        Size             = UDim2.new(0, 48, 0, 48),
        Position         = UDim2.new(0, 8, 0.5, -24),
        BackgroundColor3 = self:T("Elevated"),
        BorderSizePixel  = 0,
        Parent           = infoCard,
    })
    makeCorner(ava, 4)
    self:Themify(ava, "BackgroundColor3", "Elevated")

    local infoText = create("TextLabel", {
        Size              = UDim2.new(1, -70, 1, -8),
        Position          = UDim2.new(0, 64, 0, 4),
        BackgroundTransparency = 1,
        Text              = "Name: ???\nUserId: ???\nCreated: ???\nIs-BBOT: ???",
        TextColor3        = self:T("TextDim"),
        TextSize          = 10,
        Font              = Enum.Font.Gotham,
        TextXAlignment    = Enum.TextXAlignment.Left,
        TextYAlignment    = Enum.TextYAlignment.Top,
        RichText          = true,
        Parent            = infoCard,
    })
    self:Themify(infoText, "TextColor3", "TextDim")

    -- priority dropdown for selected player
    local priDrop = create("TextButton", {
        Size              = UDim2.new(0.5, -4, 0, 20),
        Position          = UDim2.new(0.5, 2, 1, -72),
        BackgroundColor3  = self:T("Elevated"),
        BorderSizePixel   = 0,
        Text              = "Priority: None  ▾",
        TextColor3        = self:T("TextDim"),
        TextSize          = 11,
        Font              = Enum.Font.Gotham,
        AutoButtonColor   = false,
        Parent            = container,
    })
    makeCorner(priDrop, 3)
    makeStroke(priDrop, 1, self:T("Outline"))
    self:Themify(priDrop, "BackgroundColor3", "Elevated")
    self:Themify(priDrop, "TextColor3",       "TextDim")

    -- player tags storage
    local playerTags = {}  -- [userId] = "None" | "Friendly" | "Enemy"
    local selectedPlayer = nil

    local function getTagColor(tag)
        if tag == "Friendly" then return self:T("Friendly") end
        if tag == "Enemy"    then return self:T("Enemy")    end
        return self:T("Text")
    end

    local function buildRows(filter)
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local name = plr.Name
                if not filter or filter == "" or name:lower():find(filter:lower(), 1, true) then
                    local uid   = tostring(plr.UserId)
                    local tag   = playerTags[plr.UserId] or "None"
                    local tagColor = getTagColor(tag)

                    local pRow = create("TextButton", {
                        Size              = UDim2.new(1, 0, 0, 18),
                        BackgroundColor3  = self:T("Surface"),
                        BorderSizePixel   = 0,
                        Text              = "",
                        AutoButtonColor   = false,
                        Parent            = scroll,
                    })
                    self:Themify(pRow, "BackgroundColor3", "Surface")

                    local nameLbl = create("TextLabel", {
                        Size              = UDim2.new(0.35, 0, 1, 0),
                        Position          = UDim2.new(0, 8, 0, 0),
                        BackgroundTransparency = 1,
                        Text              = name,
                        TextColor3        = tagColor,
                        TextSize          = 10,
                        Font              = Enum.Font.Gotham,
                        TextXAlignment    = Enum.TextXAlignment.Left,
                        Parent            = pRow,
                    })

                    local uidLbl = create("TextLabel", {
                        Size              = UDim2.new(0.35, 0, 1, 0),
                        Position          = UDim2.new(0.35, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Text              = uid,
                        TextColor3        = self:T("TextDim"),
                        TextSize          = 10,
                        Font              = Enum.Font.Gotham,
                        TextXAlignment    = Enum.TextXAlignment.Left,
                        Parent            = pRow,
                    })
                    self:Themify(uidLbl, "TextColor3", "TextDim")

                    local tagLbl = create("TextLabel", {
                        Size              = UDim2.new(0.28, 0, 1, 0),
                        Position          = UDim2.new(0.72, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Text              = tag,
                        TextColor3        = tagColor,
                        TextSize          = 10,
                        Font              = Enum.Font.Gotham,
                        TextXAlignment    = Enum.TextXAlignment.Left,
                        Parent            = pRow,
                    })

                    -- hover
                    conn(pRow.MouseEnter, function()
                        tween(pRow, { BackgroundColor3 = self:T("Elevated") }, 0.08)
                    end)
                    conn(pRow.MouseLeave, function()
                        tween(pRow, { BackgroundColor3 = self:T("Surface") }, 0.08)
                    end)

                    -- select
                    conn(pRow.MouseButton1Click, function()
                        selectedPlayer = plr
                        -- update info card
                        local age = "???"
                        pcall(function()
                            local info = Players:GetPlayerInfoAsync(plr.UserId)
                            age = tostring(info.MembershipType)
                        end)
                        infoText.Text = string.format(
                            "<b>Name:</b> %s\n<b>UserId:</b> %s\n<b>Created:</b> ???\n<b>Is-BBOT:</b> %s",
                            plr.DisplayName, uid,
                            tostring(getgenv()._SW_Utils ~= nil)
                        )
                        priDrop.Text = "Priority: " .. (playerTags[plr.UserId] or "None") .. "  ▾"
                    end)
                end
            end
        end
    end

    -- priority picker
    conn(priDrop.MouseButton1Click, function()
        if not selectedPlayer then return end
        local opts = {"None", "Friendly", "Enemy"}
        local current = playerTags[selectedPlayer.UserId] or "None"
        local idx = table.find(opts, current) or 1
        idx = (idx % #opts) + 1
        local next = opts[idx]
        playerTags[selectedPlayer.UserId] = next
        priDrop.Text = "Priority: " .. next .. "  ▾"
        buildRows(searchBox.Text)
        -- expose globally
        if not Library.Flags.PlayerTags then Library.Flags.PlayerTags = {} end
        Library.Flags.PlayerTags[selectedPlayer.UserId] = next
    end)

    conn(refreshBtn.MouseButton1Click, function() buildRows(searchBox.Text) end)
    conn(searchBox:GetPropertyChangedSignal("Text"), function() buildRows(searchBox.Text) end)

    -- auto refresh on player join/leave
    conn(Players.PlayerAdded,   function() buildRows(searchBox.Text) end)
    conn(Players.PlayerRemoving,function() buildRows(searchBox.Text) end)

    buildRows("")

    return {
        GetTags    = function() return playerTags end,
        GetTag     = function(userId) return playerTags[userId] or "None" end,
        Refresh    = function() buildRows(searchBox.Text) end,
    }
end

----------------------------------------------------------------
-- UNLOAD
----------------------------------------------------------------
function Library:Unload()
    self.Unloaded = true
    for _, c in ipairs(self.Connections) do
        pcall(function() c:Disconnect() end)
    end
    ScreenGui:Destroy()
    getgenv()._BBotLibV3 = nil
end

----------------------------------------------------------------
-- EXPOSE
----------------------------------------------------------------
getgenv()._BBotLibV3 = Library
return Library
