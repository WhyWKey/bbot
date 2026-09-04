--[[
    BitchBot UI Library (ScreenGui rewrite)
    v2 look + structure, ScreenGui hit-testing (accurate clicks like v3)
    Compatible with Potassium / UNC

    local Library = loadstring(game:HttpGet("..."))()
    local menu = Library.new({...})
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer
local Mouse            = LocalPlayer:GetMouse()
local Camera           = workspace.CurrentCamera

local Library = {}
Library.__index = Library

local TOGGLE, SLIDER, DROPBOX, BUTTON, KEYBIND, TEXTBOX =
    "toggle", "slider", "dropbox", "button", "keybind", "textbox"

Library.TOGGLE = TOGGLE
Library.SLIDER = SLIDER
Library.DROPBOX = DROPBOX
Library.BUTTON = BUTTON
Library.KEYBIND = KEYBIND
Library.TEXTBOX = TEXTBOX

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

local function clamp(n, a, b)
    if n < a then return a end
    if n > b then return b end
    return n
end

local KEY_NAMES = {
    One="1",Two="2",Three="3",Four="4",Five="5",Six="6",Seven="7",Eight="8",Nine="9",Zero="0",
    LeftBracket="[",RightBracket="]",Semicolon=";",BackSlash="\\",Slash="/",Minus="-",Equals="=",
    Return="Enter",Backquote="`",CapsLock="Caps",LeftShift="LShift",RightShift="RShift",
    LeftControl="LCtrl",RightControl="RCtrl",LeftAlt="LAlt",RightAlt="RAlt",Backspace="Back",
    PageUp="PgUp",PageDown="PgDown",Delete="Del",Insert="Ins",Space="Space",Tab="Tab",Escape="Esc",
    MouseButton1="MB1",MouseButton2="MB2",MouseButton3="MB3",
}

local function keyName(key)
    if key == nil then return "None" end
    local s = tostring(key)
    local name = s:match("KeyCode%.(.+)") or s:match("UserInputType%.(.+)") or s
    name = name:gsub("Keypad", "")
    if name == "Unknown" then return "None" end
    return KEY_NAMES[name] or name
end

-- ============================================================
-- Instance helpers
-- ============================================================
local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            obj[k] = v
        end
    end
    if props and props.Parent then
        obj.Parent = props.Parent
    end
    return obj
end

local function corner(parent, r)
    return Create("UICorner", { CornerRadius = UDim.new(0, r or 0), Parent = parent })
end

local function stroke(parent, color, thickness)
    return Create("UIStroke", {
        Color = color or rgb(0, 0, 0),
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function pad(parent, t, b, l, r)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or 0),
        Parent = parent,
    })
end

-- ============================================================
-- Notifications
-- ============================================================
local notifGui
local notifList = {}

local function ensureNotifGui()
    if notifGui and notifGui.Parent then return notifGui end
    notifGui = Create("ScreenGui", {
        Name = "BBNotify",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9999,
        Parent = (gethui and gethui()) or CoreGui,
    })
    return notifGui
end

function Library.Notify(text, duration)
    duration = duration or 3
    local gui = ensureNotifGui()
    local frame = Create("Frame", {
        Name = "Note",
        BackgroundColor3 = rgb(20, 20, 20),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        Position = UDim2.new(0, 50, 0, 40 + (#notifList * 28)),
        Parent = gui,
    })
    stroke(frame, rgb(0, 0, 0), 1)
    local accent = Create("Frame", {
        BackgroundColor3 = rgb(155, 155, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 2, 1, 0),
        Parent = frame,
    })
    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = rgb(255, 255, 255),
        Text = tostring(text),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })
    pad(frame, 0, 0, 0, 12)
    table.insert(notifList, frame)
    task.delay(duration, function()
        if frame then frame:Destroy() end
        local i = table.find(notifList, frame)
        if i then table.remove(notifList, i) end
        for idx, f in ipairs(notifList) do
            f.Position = UDim2.new(0, 50, 0, 40 + ((idx - 1) * 28))
        end
    end)
end

-- ============================================================
-- Library.new
-- ============================================================
function Library.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Library)

    self.w = opts.width or 500
    self.h = opts.height or 600
    self.accent = opts.accent or Color3.fromRGB(155, 155, 255)
    if typeof(self.accent) ~= "Color3" and type(self.accent) == "table" then
        self.accent = rgb(self.accent[1], self.accent[2], self.accent[3])
    end
    self.menuName = opts.menuName or "Bitch Bot"
    self.keybind = opts.keybind or Enum.KeyCode.RightShift
    self.open = true
    self.unloaded = false
    self.activetab = 1
    self.tabs = {}
    self.values = {}
    self.connections = {}
    self.openDropdown = nil
    self.watermarkVisible = true

    -- ScreenGui root
    local host = (gethui and gethui()) or CoreGui
    self.gui = Create("ScreenGui", {
        Name = "BitchBotUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9990,
        Parent = host,
    })

    local screen = Camera.ViewportSize
    self.window = Create("Frame", {
        Name = "Window",
        BackgroundColor3 = rgb(15, 15, 15),
        BorderSizePixel = 0,
        Size = UDim2.new(0, self.w, 0, self.h),
        Position = UDim2.new(0, math.floor(screen.X / 2 - self.w / 2), 0, math.floor(screen.Y / 2 - self.h / 2)),
        Parent = self.gui,
    })
    stroke(self.window, rgb(0, 0, 0), 1)

    -- accent top lines (v2 style)
    Create("Frame", {
        BackgroundColor3 = self.accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 1),
        Position = UDim2.new(0, 2, 0, 2),
        Parent = self.window,
    })
    Create("Frame", {
        BackgroundColor3 = Color3.new(
            math.max(0, self.accent.R - 68/255),
            math.max(0, self.accent.G - 123/255),
            math.max(0, self.accent.B - 132/255)
        ),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 1),
        Position = UDim2.new(0, 2, 0, 3),
        Parent = self.window,
    })

    -- title bar (drag)
    self.titleBar = Create("TextButton", {
        Name = "TitleBar",
        BackgroundColor3 = rgb(25, 25, 25),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 20),
        Position = UDim2.new(0, 2, 0, 5),
        Text = "",
        AutoButtonColor = false,
        Parent = self.window,
    })
    self.titleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = rgb(255, 255, 255),
        Text = self.menuName,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.titleBar,
    })

    -- tab bar
    self.tabBar = Create("Frame", {
        Name = "TabBar",
        BackgroundColor3 = rgb(30, 30, 30),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -14, 0, 22),
        Position = UDim2.new(0, 7, 0, 28),
        Parent = self.window,
    })
    stroke(self.tabBar, rgb(0, 0, 0), 1)

    -- content area
    self.content = Create("Frame", {
        Name = "Content",
        BackgroundColor3 = rgb(15, 15, 15),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -22, 1, -78),
        Position = UDim2.new(0, 11, 0, 54),
        ClipsDescendants = true,
        Parent = self.window,
    })
    stroke(self.content, rgb(0, 0, 0), 1)
    Create("Frame", {
        BackgroundColor3 = rgb(10, 10, 10),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 1, -2),
        Position = UDim2.new(0, 1, 0, 1),
        Parent = self.content,
    }).Name = "Inner"

    self.contentInner = self.content:FindFirstChild("Inner")

    -- footer
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextColor3 = rgb(100, 100, 100),
        Text = "bbot.gg",
        Size = UDim2.new(0, 60, 0, 16),
        Position = UDim2.new(1, -68, 1, -18),
        Parent = self.window,
    })

    -- watermark
    self.watermark = Create("Frame", {
        Name = "Watermark",
        BackgroundColor3 = rgb(15, 15, 15),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 200, 0, 22),
        Position = UDim2.new(0, 10, 0, 10),
        Parent = self.gui,
    })
    stroke(self.watermark, rgb(0, 0, 0), 1)
    Create("Frame", {
        BackgroundColor3 = self.accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2),
        Parent = self.watermark,
    })
    self.watermarkText = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = rgb(255, 255, 255),
        Text = "Bitch Bot | " .. LocalPlayer.Name,
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.watermark,
    })

    self:SetupDrag()
    self:SetupInput()

    return self
end

function Library:SetupDrag()
    local dragging = false
    local startMouse, startPos

    self.connections[#self.connections + 1] = self.titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startMouse = input.Position
            startPos = self.window.Position
        end
    end)
    self.connections[#self.connections + 1] = self.titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    self.connections[#self.connections + 1] = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startMouse
            self.window.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Library:SetupInput()
    self.connections[#self.connections + 1] = UserInputService.InputBegan:Connect(function(input, gpe)
        if self.unloaded then return end
        if input.KeyCode == self.keybind then
            self:SetVisible(not self.open)
            Library.Notify(self.open and "Menu opened" or "Menu closed")
            return
        end
        if self.listeningKey and input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
            local opt = self.listeningKey
            opt.value = input.KeyCode
            opt.listening = false
            if opt.keyLabel then opt.keyLabel.Text = keyName(opt.value) end
            self:SetVal(opt.tabName, opt.groupName, opt.name, opt.value)
            self.listeningKey = nil
            Library.Notify(opt.name .. " = " .. keyName(opt.value))
        end
    end)
end

function Library:SetVisible(v)
    self.open = v
    self.window.Visible = v
end

-- ============================================================
-- Tabs / Groups / Options
-- ============================================================
function Library:AddTab(name)
    local tab = {
        name = name,
        groups = {},
        index = #self.tabs + 1,
        button = nil,
        page = nil,
    }
    self.tabs[#self.tabs + 1] = tab
    self.values[name] = {}
    return tab
end

function Library:AddGroup(tab, opts)
    opts = opts or {}
    local group = {
        name = opts.name or "Group",
        side = opts.side or "left",
        autofill = opts.autofill,
        height = opts.height,
        options = {},
        frame = nil,
    }
    tab.groups[#tab.groups + 1] = group
    self.values[tab.name][group.name] = {}
    return group
end

function Library:AddToggle(group, opts)
    local o = {
        type = TOGGLE,
        name = opts.name or "Toggle",
        value = opts.value and true or false,
        callback = opts.callback,
        keybind = opts.keybind,
    }
    group.options[#group.options + 1] = o
    return o
end

function Library:AddSlider(group, opts)
    local o = {
        type = SLIDER,
        name = opts.name or "Slider",
        value = opts.value or 0,
        min = opts.min or 0,
        max = opts.max or 100,
        stradd = opts.stradd or "",
        callback = opts.callback,
    }
    group.options[#group.options + 1] = o
    return o
end

function Library:AddDropbox(group, opts)
    local o = {
        type = DROPBOX,
        name = opts.name or "Dropbox",
        value = opts.value or 1,
        values = opts.values or {"A", "B"},
        callback = opts.callback,
        open = false,
    }
    group.options[#group.options + 1] = o
    return o
end

function Library:AddButton(group, opts)
    local o = {
        type = BUTTON,
        name = opts.name or "Button",
        callback = opts.callback,
    }
    group.options[#group.options + 1] = o
    return o
end

function Library:AddKeybind(group, opts)
    local o = {
        type = KEYBIND,
        name = opts.name or "Key",
        value = opts.key or opts.value or Enum.KeyCode.E,
        callback = opts.callback,
        listening = false,
    }
    group.options[#group.options + 1] = o
    return o
end

function Library:AddTextbox(group, opts)
    local o = {
        type = TEXTBOX,
        name = opts.name or "Text",
        value = opts.text or opts.value or "",
        callback = opts.callback,
    }
    group.options[#group.options + 1] = o
    return o
end

function Library:GetVal(tab, group, name)
    local t = self.values[tab]
    if not t then return nil end
    local g = t[group]
    if not g then return nil end
    return g[name]
end

function Library:SetVal(tab, group, name, val)
    self.values[tab] = self.values[tab] or {}
    self.values[tab][group] = self.values[tab][group] or {}
    self.values[tab][group][name] = val
end

-- ============================================================
-- Build
-- ============================================================
function Library:Init()
    self:BuildTabs()
    for _, tab in ipairs(self.tabs) do
        self:BuildPage(tab)
    end
    self:SwitchTab(1)
    Library.Notify("UI loaded")
end

function Library:BuildTabs()
    local n = math.max(#self.tabs, 1)
    local tabW = 1 / n
    for i, tab in ipairs(self.tabs) do
        local btn = Create("TextButton", {
            Name = tab.name,
            BackgroundColor3 = rgb(35, 35, 35),
            BorderSizePixel = 0,
            Size = UDim2.new(tabW, -1, 1, 0),
            Position = UDim2.new((i - 1) * tabW, 0, 0, 0),
            Font = Enum.Font.Code,
            TextSize = 13,
            TextColor3 = rgb(200, 200, 200),
            Text = tab.name,
            AutoButtonColor = false,
            Parent = self.tabBar,
        })
        local under = Create("Frame", {
            Name = "Underline",
            BackgroundColor3 = self.accent,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 2),
            Position = UDim2.new(0, 0, 1, -2),
            Visible = false,
            Parent = btn,
        })
        tab.button = btn
        tab.underline = under
        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(i)
        end)
    end
end

function Library:SwitchTab(idx)
    if idx < 1 or idx > #self.tabs then return end
    self:CloseDropdown()
    self.activetab = idx
    for i, tab in ipairs(self.tabs) do
        local on = (i == idx)
        if tab.page then tab.page.Visible = on end
        if tab.underline then tab.underline.Visible = on end
        if tab.button then
            tab.button.BackgroundColor3 = on and rgb(25, 25, 25) or rgb(35, 35, 35)
            tab.button.TextColor3 = on and rgb(255, 255, 255) or rgb(180, 180, 180)
        end
    end
end

function Library:BuildPage(tab)
    local page = Create("Frame", {
        Name = tab.name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
        Parent = self.contentInner,
    })
    tab.page = page

    local leftCol = Create("Frame", {
        Name = "Left",
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -6, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        Parent = page,
    })
    local rightCol = Create("Frame", {
        Name = "Right",
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -6, 1, -8),
        Position = UDim2.new(0.5, 2, 0, 4),
        Parent = page,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = leftCol,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = rightCol,
    })

    -- Player List full width on Settings
    if tab.name == "Settings" then
        local pl = self:BuildPlayerListFrame(page)
        pl.LayoutOrder = 0
        -- shift columns down
        leftCol.Position = UDim2.new(0, 4, 0, 210)
        rightCol.Position = UDim2.new(0.5, 2, 0, 210)
        leftCol.Size = UDim2.new(0.5, -6, 1, -218)
        rightCol.Size = UDim2.new(0.5, -6, 1, -218)
    end

    for _, group in ipairs(tab.groups) do
        if group.name == "Player List" then
            continue
        end
        local parent = (group.side == "right") and rightCol or leftCol
        self:BuildGroupFrame(tab, group, parent)
    end
end

function Library:CoolBoxFrame(parent, title, height)
    local box = Create("Frame", {
        BackgroundColor3 = rgb(20, 20, 20),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 100),
        AutomaticSize = height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
        Parent = parent,
    })
    stroke(box, rgb(0, 0, 0), 1)
    -- accent lines
    Create("Frame", {
        BackgroundColor3 = self.accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 1),
        Position = UDim2.new(0, 2, 0, 2),
        Parent = box,
    })
    Create("Frame", {
        BackgroundColor3 = Color3.new(
            math.max(0, self.accent.R - 68/255),
            math.max(0, self.accent.G - 123/255),
            math.max(0, self.accent.B - 132/255)
        ),
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 1),
        Position = UDim2.new(0, 2, 0, 3),
        Parent = box,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = rgb(255, 255, 255),
        Text = title,
        Size = UDim2.new(1, -12, 0, 18),
        Position = UDim2.new(0, 6, 0, 5),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = box,
    })
    local body = Create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -12, 1, -28),
        Position = UDim2.new(0, 6, 0, 24),
        AutomaticSize = height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
        Parent = box,
    })
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = body,
    })
    if not height then
        pad(box, 0, 8, 0, 0)
    end
    return box, body
end

function Library:BuildGroupFrame(tab, group, parent)
    local box, body = self:CoolBoxFrame(parent, group.name, group.height)
    group.frame = box
    group.body = body

    for _, opt in ipairs(group.options) do
        self.values[tab.name][group.name][opt.name] = opt.value
        opt.tabName = tab.name
        opt.groupName = group.name
        if opt.type == TOGGLE then
            self:BuildToggleUI(body, opt)
        elseif opt.type == SLIDER then
            self:BuildSliderUI(body, opt)
        elseif opt.type == DROPBOX then
            self:BuildDropboxUI(body, opt)
        elseif opt.type == BUTTON then
            self:BuildButtonUI(body, opt)
        elseif opt.type == KEYBIND then
            self:BuildKeybindUI(body, opt)
        elseif opt.type == TEXTBOX then
            self:BuildTextboxUI(body, opt)
        end
    end
end

function Library:BuildToggleUI(parent, opt)
    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Parent = parent,
    })
    local box = Create("TextButton", {
        BackgroundColor3 = opt.value and self.accent or rgb(40, 40, 40),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 0, 0.5, -6),
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    stroke(box, rgb(0, 0, 0), 1)
    opt._box = box
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = rgb(255, 255, 255),
        Text = opt.name,
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    box.MouseButton1Click:Connect(function()
        opt.value = not opt.value
        box.BackgroundColor3 = opt.value and self.accent or rgb(40, 40, 40)
        self:SetVal(opt.tabName, opt.groupName, opt.name, opt.value)
        if opt.callback then pcall(opt.callback, opt.value) end
    end)
end

function Library:BuildSliderUI(parent, opt)
    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Parent = parent,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = rgb(255, 255, 255),
        Text = opt.name,
        Size = UDim2.new(1, 0, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local track = Create("Frame", {
        BackgroundColor3 = rgb(30, 30, 30),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 0, 16),
        Parent = row,
    })
    stroke(track, rgb(0, 0, 0), 1)
    local fill = Create("Frame", {
        BackgroundColor3 = self.accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        Parent = track,
    })
    local valLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextColor3 = rgb(255, 255, 255),
        Text = tostring(math.floor(opt.value + 0.5)) .. (opt.stradd or ""),
        Size = UDim2.new(1, 0, 1, 0),
        Parent = track,
    })
    opt._fill = fill
    opt._valLabel = valLabel

    local function setFromX(x)
        local rel = clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        opt.value = opt.min + rel * (opt.max - opt.min)
        local pct = (opt.value - opt.min) / math.max(opt.max - opt.min, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valLabel.Text = tostring(math.floor(opt.value + 0.5)) .. (opt.stradd or "")
        self:SetVal(opt.tabName, opt.groupName, opt.name, opt.value)
    end

    local sliding = false
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            setFromX(input.Position.X)
        end
    end)
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
            if opt.callback then pcall(opt.callback, opt.value) end
        end
    end)
    self.connections[#self.connections + 1] = UserInputService.InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromX(input.Position.X)
        end
    end)

    -- init fill
    local pct = (opt.value - opt.min) / math.max(opt.max - opt.min, 1)
    fill.Size = UDim2.new(pct, 0, 1, 0)
end

function Library:CloseDropdown()
    if self.openDropdown then
        local opt = self.openDropdown
        opt.open = false
        if opt._dropFrame then opt._dropFrame.Visible = false end
        self.openDropdown = nil
    end
end

function Library:BuildDropboxUI(parent, opt)
    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 5,
        Parent = parent,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = rgb(255, 255, 255),
        Text = opt.name,
        Size = UDim2.new(1, 0, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local btn = Create("TextButton", {
        BackgroundColor3 = rgb(30, 30, 30),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 16),
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = rgb(255, 255, 255),
        Text = "  " .. tostring(opt.values[opt.value] or "?"),
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        Parent = row,
    })
    stroke(btn, rgb(0, 0, 0), 1)
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = rgb(200, 200, 200),
        Text = "-",
        Size = UDim2.new(0, 16, 1, 0),
        Position = UDim2.new(1, -18, 0, 0),
        Parent = btn,
    })
    opt._btn = btn

    local drop = Create("Frame", {
        BackgroundColor3 = rgb(25, 25, 25),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, #opt.values * 18),
        Position = UDim2.new(0, 0, 0, 36),
        Visible = false,
        ZIndex = 50,
        Parent = row,
    })
    stroke(drop, rgb(0, 0, 0), 1)
    opt._dropFrame = drop
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = drop })

    for i, name in ipairs(opt.values) do
        local item = Create("TextButton", {
            BackgroundColor3 = rgb(25, 25, 25),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 18),
            Font = Enum.Font.Code,
            TextSize = 13,
            TextColor3 = rgb(255, 255, 255),
            Text = "  " .. tostring(name),
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ZIndex = 51,
            Parent = drop,
        })
        item.MouseButton1Click:Connect(function()
            opt.value = i
            btn.Text = "  " .. tostring(name)
            self:SetVal(opt.tabName, opt.groupName, opt.name, opt.value)
            if opt.callback then pcall(opt.callback, opt.value) end
            self:CloseDropdown()
        end)
        item.MouseEnter:Connect(function()
            item.BackgroundColor3 = self.accent
        end)
        item.MouseLeave:Connect(function()
            item.BackgroundColor3 = rgb(25, 25, 25)
        end)
    end

    btn.MouseButton1Click:Connect(function()
        if self.openDropdown == opt then
            self:CloseDropdown()
        else
            self:CloseDropdown()
            opt.open = true
            drop.Visible = true
            self.openDropdown = opt
        end
    end)
end

function Library:BuildButtonUI(parent, opt)
    local btn = Create("TextButton", {
        BackgroundColor3 = rgb(35, 35, 35),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = rgb(255, 255, 255),
        Text = opt.name,
        AutoButtonColor = false,
        Parent = parent,
    })
    stroke(btn, rgb(0, 0, 0), 1)
    btn.MouseButton1Click:Connect(function()
        if opt.callback then pcall(opt.callback) else Library.Notify("Clicked: " .. opt.name) end
    end)
end

function Library:BuildKeybindUI(parent, opt)
    local row = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Parent = parent,
    })
    local keyBtn = Create("TextButton", {
        BackgroundColor3 = rgb(30, 30, 30),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 44, 0, 16),
        Font = Enum.Font.Code,
        TextSize = 12,
        TextColor3 = rgb(255, 255, 255),
        Text = keyName(opt.value),
        AutoButtonColor = false,
        Parent = row,
    })
    stroke(keyBtn, rgb(0, 0, 0), 1)
    opt.keyLabel = keyBtn
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = rgb(255, 255, 255),
        Text = opt.name,
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 50, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    keyBtn.MouseButton1Click:Connect(function()
        opt.listening = true
        self.listeningKey = opt
        keyBtn.Text = "..."
        Library.Notify("Press a key for " .. opt.name)
    end)
end

function Library:BuildTextboxUI(parent, opt)
    local box = Create("TextBox", {
        BackgroundColor3 = rgb(30, 30, 30),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 22),
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = rgb(255, 255, 255),
        Text = opt.value,
        PlaceholderText = opt.name,
        ClearTextOnFocus = false,
        Parent = parent,
    })
    stroke(box, rgb(0, 0, 0), 1)
    box.FocusLost:Connect(function()
        opt.value = box.Text
        self:SetVal(opt.tabName, opt.groupName, opt.name, opt.value)
        if opt.callback then pcall(opt.callback, opt.value) end
    end)
end

function Library:BuildPlayerListFrame(page)
    local box, body = self:CoolBoxFrame(page, "Player List", 200)
    box.Size = UDim2.new(1, -8, 0, 200)
    box.Position = UDim2.new(0, 4, 0, 4)
    box.AutomaticSize = Enum.AutomaticSize.None

    -- header
    local header = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Parent = body,
    })
    for i, t in ipairs({"Name", "Team", "Status"}) do
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Font = Enum.Font.Code,
            TextSize = 12,
            TextColor3 = rgb(200, 200, 200),
            Text = t,
            Size = UDim2.new(1/3, 0, 1, 0),
            Position = UDim2.new((i - 1) / 3, 0, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = header,
        })
    end

    local rows = {}
    for i = 1, 6 do
        local row = Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = body,
        })
        local cells = {}
        for c = 1, 3 do
            cells[c] = Create("TextLabel", {
                BackgroundTransparency = 1,
                Font = Enum.Font.Code,
                TextSize = 12,
                TextColor3 = rgb(255, 255, 255),
                Text = "",
                Size = UDim2.new(1/3, 0, 1, 0),
                Position = UDim2.new((c - 1) / 3, 0, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })
        end
        rows[i] = cells
    end
    self.playerListRows = rows
    self:RefreshPlayerList()
    self.connections[#self.connections + 1] = Players.PlayerAdded:Connect(function()
        task.defer(function() self:RefreshPlayerList() end)
    end)
    self.connections[#self.connections + 1] = Players.PlayerRemoving:Connect(function()
        task.defer(function() self:RefreshPlayerList() end)
    end)
    return box
end

function Library:RefreshPlayerList()
    if not self.playerListRows then return end
    local list = Players:GetPlayers()
    for i = 1, #self.playerListRows do
        local p = list[i]
        local cells = self.playerListRows[i]
        if p then
            cells[1].Text = p.Name
            cells[2].Text = p.Team and p.Team.Name or "None"
            cells[3].Text = (p == LocalPlayer) and "You" or "None"
        else
            cells[1].Text, cells[2].Text, cells[3].Text = "", "", ""
        end
    end
end

function Library:Unload()
    self.unloaded = true
    for _, c in ipairs(self.connections) do
        pcall(function() c:Disconnect() end)
    end
    self.connections = {}
    if self.gui then self.gui:Destroy() end
    if notifGui then notifGui:Destroy() notifGui = nil end
end

return Library
