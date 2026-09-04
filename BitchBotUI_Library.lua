--[[
    BitchBot UI Library — ScreenGui port of original BBOT v2 menu
    Original Drawing look/behavior → native ScreenGui (accurate clicks)
    Option API compatible with original: menu:GetVal(tab, group, name)

    loadstring(game:HttpGet("..."))()
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local GuiService       = game:GetService("GuiService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- Original type IDs (kept for compatibility)
local TOGGLE, KEYBIND, DROPBOX, COMBOBOX, SLIDER, BUTTON, TEXTBOX, COLORPICKER =
    5, 6, 7, 8, 10, 11, 12, 13

local function RGB(r, g, b) return Color3.fromRGB(r, g, b) end
local function clamp(n, a, b)
    if n < a then return a elseif n > b then return b else return n end
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
    if not key then return "None" end
    local s = tostring(key)
    local n = s:match("KeyCode%.(.+)") or s:match("UserInputType%.(.+)") or s
    n = n:gsub("Keypad", "")
    if n == "Unknown" then return "None" end
    return KEY_NAMES[n] or n
end

local function Create(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then o[k] = v end
    end
    if props and props.Parent then o.Parent = props.Parent end
    return o
end

local function stroke(p, c, t)
    return Create("UIStroke", {
        Color = c or RGB(0,0,0),
        Thickness = t or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = p,
    })
end

-- ============================================================
-- Library
-- ============================================================
local Library = {}
Library.__index = Library
Library.TOGGLE = TOGGLE
Library.KEYBIND = KEYBIND
Library.DROPBOX = DROPBOX
Library.COMBOBOX = COMBOBOX
Library.SLIDER = SLIDER
Library.BUTTON = BUTTON
Library.TEXTBOX = TEXTBOX

local notifHost

function Library.Notify(msg, dur)
    dur = dur or 2.5
    if not notifHost or not notifHost.Parent then
        notifHost = Create("ScreenGui", {
            Name = "BBNotify", ResetOnSpawn = false, DisplayOrder = 10000,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent = (gethui and gethui()) or CoreGui,
        })
    end
    local f = Create("Frame", {
        BackgroundColor3 = RGB(20,20,20), BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 22),
        Position = UDim2.new(0, 48, 0, 36 + (#notifHost:GetChildren() * 26)),
        Parent = notifHost,
    })
    stroke(f, RGB(0,0,0), 1)
    Create("Frame", { BackgroundColor3 = RGB(155,155,255), BorderSizePixel = 0,
        Size = UDim2.new(0, 2, 1, 0), Parent = f })
    Create("TextLabel", {
        BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 13,
        TextColor3 = RGB(255,255,255), Text = "  " .. tostring(msg) .. "  ",
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0,0,1,0),
        Position = UDim2.new(0, 6, 0, 0), Parent = f,
    })
    task.delay(dur, function() if f then f:Destroy() end end)
end

function Library.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Library)

    self.w = opts.width or 500
    self.h = opts.height or 600
    self.menuName = opts.menuName or "Bitch Bot"
    self.keybind = opts.keybind or Enum.KeyCode.RightShift
    self.accent = opts.accent or RGB(155, 155, 255)
    if type(self.accent) == "table" then
        self.accent = RGB(self.accent[1], self.accent[2], self.accent[3])
    end
    self.open = true
    self.unloaded = false
    self.activetab = 1
    self.tabs = {}
    self.options = {}       -- [tab][group][name] = storage (original-like)
    self.connections = {}
    self.openDropdown = nil
    self.listeningKey = nil
    self.columns = { left = 16, right = nil, width = nil }

    local host = (gethui and gethui()) or CoreGui
    self.gui = Create("ScreenGui", {
        Name = "BitchBotUI", ResetOnSpawn = false, DisplayOrder = 9990,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = host,
    })

    local vs = Camera.ViewportSize
    self.window = Create("Frame", {
        Name = "Window", BackgroundColor3 = RGB(20,20,20), BorderSizePixel = 0,
        Size = UDim2.new(0, self.w, 0, self.h),
        Position = UDim2.new(0, math.floor(vs.X/2 - self.w/2), 0, math.floor(vs.Y/2 - self.h/2)),
        Parent = self.gui,
    })
    stroke(self.window, RGB(0,0,0), 1)

    -- outer accent (original double line)
    Create("Frame", { BackgroundColor3 = self.accent, BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 1), Position = UDim2.new(0, 2, 0, 2), Parent = self.window })
    Create("Frame", {
        BackgroundColor3 = Color3.new(math.max(0,self.accent.R-0.27), math.max(0,self.accent.G-0.48), math.max(0,self.accent.B-0.52)),
        BorderSizePixel = 0, Size = UDim2.new(1, -4, 0, 1), Position = UDim2.new(0, 2, 0, 3), Parent = self.window })

    -- title bar
    self.titleBar = Create("TextButton", {
        BackgroundColor3 = RGB(30,30,30), BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 18), Position = UDim2.new(0, 2, 0, 5),
        Text = "", AutoButtonColor = false, Parent = self.window,
    })
    Create("TextLabel", {
        BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 13,
        TextColor3 = RGB(255,255,255), Text = self.menuName,
        Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 6, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = self.titleBar,
    })

    -- inner panel (tabs + content) matching original inset
    self.inner = Create("Frame", {
        BackgroundColor3 = RGB(30,30,30), BorderSizePixel = 0,
        Size = UDim2.new(1, -16, 1, -36), Position = UDim2.new(0, 8, 0, 24),
        Parent = self.window,
    })
    stroke(self.inner, RGB(0,0,0), 1)
    Create("Frame", { BackgroundColor3 = self.accent, BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, 1), Position = UDim2.new(0, 1, 0, 1), Parent = self.inner })
    Create("Frame", {
        BackgroundColor3 = Color3.new(math.max(0,self.accent.R-0.27), math.max(0,self.accent.G-0.48), math.max(0,self.accent.B-0.52)),
        BorderSizePixel = 0, Size = UDim2.new(1, -2, 0, 1), Position = UDim2.new(0, 1, 0, 2), Parent = self.inner })

    self.tabBar = Create("Frame", {
        BackgroundColor3 = RGB(35,35,35), BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 28), Position = UDim2.new(0, 2, 0, 4),
        Parent = self.inner,
    })

    self.content = Create("Frame", {
        BackgroundColor3 = RGB(15,15,15), BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 1, -36), Position = UDim2.new(0, 2, 0, 34),
        ClipsDescendants = true, Parent = self.inner,
    })
    stroke(self.content, RGB(0,0,0), 1)

    Create("TextLabel", {
        BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
        TextColor3 = RGB(100,100,100), Text = "bbot.gg",
        Size = UDim2.new(0, 50, 0, 14), Position = UDim2.new(1, -56, 1, -16),
        Parent = self.window,
    })

    -- watermark
    self.watermark = Create("Frame", {
        BackgroundColor3 = RGB(15,15,15), BorderSizePixel = 0,
        Size = UDim2.new(0, 220, 0, 22), Position = UDim2.new(0, 10, 0, 10),
        Parent = self.gui,
    })
    stroke(self.watermark, RGB(0,0,0), 1)
    Create("Frame", { BackgroundColor3 = self.accent, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 2), Parent = self.watermark })
    self.watermarkText = Create("TextLabel", {
        BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 13,
        TextColor3 = RGB(255,255,255),
        Text = "Bitch Bot | " .. LocalPlayer.Name,
        Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 8, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = self.watermark,
    })

    self.columns.width = math.floor((self.w - 40) / 2)
    self.columns.right = self.columns.left + self.columns.width + 8

    self:SetupDrag()
    self:SetupKeys()
    return self
end

function Library:SetupDrag()
    local dragging, startM, startP
    self.connections[#self.connections+1] = self.titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; startM = inp.Position; startP = self.window.Position
        end
    end)
    self.connections[#self.connections+1] = self.titleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    self.connections[#self.connections+1] = UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - startM
            self.window.Position = UDim2.new(startP.X.Scale, startP.X.Offset + d.X, startP.Y.Scale, startP.Y.Offset + d.Y)
        end
    end)
end

function Library:SetupKeys()
    self.connections[#self.connections+1] = UserInputService.InputBegan:Connect(function(inp)
        if self.unloaded then return end
        if inp.KeyCode == self.keybind then
            self:SetVisible(not self.open)
            Library.Notify(self.open and "Menu opened" or "Menu closed")
            return
        end
        if self.listeningKey and inp.KeyCode and inp.KeyCode ~= Enum.KeyCode.Unknown then
            local opt = self.listeningKey
            opt[1] = inp.KeyCode
            if opt._label then opt._label.Text = keyName(inp.KeyCode) end
            self.listeningKey = nil
            Library.Notify("Key = " .. keyName(inp.KeyCode))
        end
    end)
end

function Library:SetVisible(v)
    self.open = v
    self.window.Visible = v
end

-- ============================================================
-- Original-style API
-- ============================================================
function Library:AddTab(name)
    local tab = { name = name, groups = {}, index = #self.tabs + 1 }
    self.tabs[#self.tabs + 1] = tab
    self.options[name] = {}
    return tab
end

function Library:AddGroup(tab, opts)
    opts = opts or {}
    local g = {
        name = opts.name or "Group",
        side = opts.side or opts.autopos or "left",
        autofill = opts.autofill,
        height = opts.height,
        content = {}, -- option defs
    }
    tab.groups[#tab.groups + 1] = g
    self.options[tab.name][g.name] = {}
    return g
end

-- storage format mirrors original:
-- toggle:  [1]=value, [2]=type, ...
-- slider:  [1]=value, [2]=type
-- dropbox: [1]=index, [2]=type, [6]=values
function Library:AddToggle(group, opts)
    local o = {
        type = TOGGLE,
        name = opts.name or "Toggle",
        value = opts.value and true or false,
        extra = opts.extra, -- { type = KEYBIND, key = Enum... }
        unsafe = opts.unsafe,
        callback = opts.callback,
        tooltip = opts.tooltip,
    }
    group.content[#group.content + 1] = o
    return o
end

function Library:AddSlider(group, opts)
    local o = {
        type = SLIDER,
        name = opts.name or "Slider",
        value = opts.value or 0,
        minvalue = opts.min or opts.minvalue or 0,
        maxvalue = opts.max or opts.maxvalue or 100,
        stradd = opts.stradd or "",
        callback = opts.callback,
    }
    group.content[#group.content + 1] = o
    return o
end

function Library:AddDropbox(group, opts)
    local o = {
        type = DROPBOX,
        name = opts.name or "Dropbox",
        value = opts.value or 1,
        values = opts.values or { "A", "B" },
        callback = opts.callback,
    }
    group.content[#group.content + 1] = o
    return o
end

function Library:AddCombobox(group, opts)
    local o = {
        type = COMBOBOX,
        name = opts.name or "Combo",
        value = opts.value or {}, -- multi select indices set
        values = opts.values or { "A", "B" },
        callback = opts.callback,
    }
    group.content[#group.content + 1] = o
    return o
end

function Library:AddButton(group, opts)
    local o = {
        type = BUTTON,
        name = opts.name or "Button",
        callback = opts.callback,
    }
    group.content[#group.content + 1] = o
    return o
end

function Library:AddKeybind(group, opts)
    local o = {
        type = KEYBIND,
        name = opts.name or "Key",
        key = opts.key or opts.value or Enum.KeyCode.E,
        callback = opts.callback,
    }
    group.content[#group.content + 1] = o
    return o
end

function Library:AddTextbox(group, opts)
    local o = {
        type = TEXTBOX,
        name = opts.name or "Text",
        text = opts.text or opts.value or "",
        callback = opts.callback,
    }
    group.content[#group.content + 1] = o
    return o
end

-- Original GetVal / SetVal
function Library:GetVal(tab, group, name)
    local t = self.options[tab]
    if not t then return nil end
    local g = t[group]
    if not g then return nil end
    local o = g[name]
    if not o then return nil end
    return o[1]
end

function Library:SetVal(tab, group, name, val)
    local t = self.options[tab]
    if not t then return end
    local g = t[group]
    if not g then return end
    local o = g[name]
    if not o then return end
    o[1] = val
    if o._refresh then pcall(o._refresh, val) end
end

function Library:GetKey(tab, group, name)
    local t = self.options[tab]
    if not t then return nil end
    local g = t[group]
    if not g then return nil end
    local o = g[name]
    if not o or not o[5] then return nil end
    return o[5][1]
end

-- ============================================================
-- Build UI
-- ============================================================
function Library:Init()
    self:BuildTabButtons()
    for _, tab in ipairs(self.tabs) do
        self:BuildTabPage(tab)
    end
    self:SwitchTab(1)
    Library.Notify("UI loaded")
end

function Library:BuildTabButtons()
    local n = math.max(#self.tabs, 1)
    for i, tab in ipairs(self.tabs) do
        local btn = Create("TextButton", {
            BackgroundColor3 = RGB(40,40,40), BorderSizePixel = 0,
            Size = UDim2.new(1/n, -1, 1, 0),
            Position = UDim2.new((i-1)/n, 0, 0, 0),
            Font = Enum.Font.Code, TextSize = 13,
            TextColor3 = RGB(200,200,200), Text = tab.name,
            AutoButtonColor = false, Parent = self.tabBar,
        })
        local under = Create("Frame", {
            BackgroundColor3 = self.accent, BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2),
            Visible = false, Parent = btn,
        })
        tab._btn, tab._under = btn, under
        btn.MouseButton1Click:Connect(function() self:SwitchTab(i) end)
    end
end

function Library:SwitchTab(idx)
    if idx < 1 or idx > #self.tabs then return end
    self:CloseDropdown()
    self.activetab = idx
    for i, tab in ipairs(self.tabs) do
        local on = (i == idx)
        if tab._page then tab._page.Visible = on end
        if tab._under then tab._under.Visible = on end
        if tab._btn then
            tab._btn.BackgroundColor3 = on and RGB(25,25,25) or RGB(40,40,40)
            tab._btn.TextColor3 = on and RGB(255,255,255) or RGB(180,180,180)
        end
    end
end

function Library:CoolBox(parent, title)
    local box = Create("Frame", {
        BackgroundColor3 = RGB(20,20,20), BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent,
    })
    stroke(box, RGB(0,0,0), 1)
    Create("Frame", { BackgroundColor3 = self.accent, BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 1), Position = UDim2.new(0, 2, 0, 2), Parent = box })
    Create("Frame", {
        BackgroundColor3 = Color3.new(math.max(0,self.accent.R-0.27), math.max(0,self.accent.G-0.48), math.max(0,self.accent.B-0.52)),
        BorderSizePixel = 0, Size = UDim2.new(1, -4, 0, 1), Position = UDim2.new(0, 2, 0, 3), Parent = box })
    Create("TextLabel", {
        BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 13,
        TextColor3 = RGB(255,255,255), Text = title,
        Size = UDim2.new(1, -12, 0, 18), Position = UDim2.new(0, 6, 0, 5),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = box,
    })
    local body = Create("Frame", {
        Name = "Body", BackgroundTransparency = 1,
        Size = UDim2.new(1, -12, 0, 0), Position = UDim2.new(0, 6, 0, 24),
        AutomaticSize = Enum.AutomaticSize.Y, Parent = box,
    })
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3), Parent = body })
    Create("UIPadding", { PaddingBottom = UDim.new(0, 8), Parent = box })
    return box, body
end

function Library:BuildTabPage(tab)
    local page = Create("ScrollingFrame", {
        Name = tab.name, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.accent, BorderSizePixel = 0,
        Visible = false, Parent = self.content,
    })
    tab._page = page

    local left = Create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(0.5, -6, 0, 0),
        Position = UDim2.new(0, 4, 0, 4), AutomaticSize = Enum.AutomaticSize.Y, Parent = page,
    })
    local right = Create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(0.5, -6, 0, 0),
        Position = UDim2.new(0.5, 2, 0, 4), AutomaticSize = Enum.AutomaticSize.Y, Parent = page,
    })
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = left })
    Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = right })

    if tab.name == "Settings" then
        local pl = self:BuildPlayerList(page)
        left.Position = UDim2.new(0, 4, 0, 208)
        right.Position = UDim2.new(0.5, 2, 0, 208)
    end

    for _, group in ipairs(tab.groups) do
        if group.name == "Player List" then continue end
        local col = (group.side == "right") and right or left
        local box, body = self:CoolBox(col, group.name)
        for _, def in ipairs(group.content) do
            self:BuildOption(tab, group, def, body)
        end
    end
end

function Library:BuildOption(tab, group, def, body)
    local store = {}
    self.options[tab.name][group.name][def.name] = store
    store[2] = def.type

    if def.type == TOGGLE then
        store[1] = def.value
        local row = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Parent = body })
        local box = Create("TextButton", {
            BackgroundColor3 = def.value and self.accent or RGB(40,40,40),
            BorderSizePixel = 0, Size = UDim2.new(0, 12, 0, 12),
            Position = UDim2.new(0, 0, 0.5, -6), Text = "", AutoButtonColor = false, Parent = row,
        })
        stroke(box, RGB(0,0,0), 1)
        Create("TextLabel", {
            BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 13,
            TextColor3 = def.unsafe and RGB(255,100,100) or RGB(255,255,255),
            Text = def.name, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 18, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
        })
        store._refresh = function(v) box.BackgroundColor3 = v and self.accent or RGB(40,40,40) end
        box.MouseButton1Click:Connect(function()
            store[1] = not store[1]
            store._refresh(store[1])
            if def.callback then pcall(def.callback, store[1]) end
        end)
        -- extra keybind on toggle (original pattern)
        if def.extra and def.extra.type == KEYBIND then
            store[5] = { def.extra.key, KEYBIND }
            store[5][1] = def.extra.key
            local kb = Create("TextButton", {
                BackgroundColor3 = RGB(30,30,30), BorderSizePixel = 0,
                Size = UDim2.new(0, 44, 0, 16), Position = UDim2.new(1, -44, 0.5, -8),
                Font = Enum.Font.Code, TextSize = 12, TextColor3 = RGB(255,255,255),
                Text = keyName(def.extra.key), AutoButtonColor = false, Parent = row,
            })
            stroke(kb, RGB(0,0,0), 1)
            store[5]._label = kb
            kb.MouseButton1Click:Connect(function()
                self.listeningKey = store[5]
                kb.Text = "..."
            end)
        end

    elseif def.type == SLIDER then
        store[1] = def.value
        local row = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Parent = body })
        Create("TextLabel", {
            BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 13,
            TextColor3 = RGB(255,255,255), Text = def.name,
            Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
        })
        local track = Create("Frame", {
            BackgroundColor3 = RGB(30,30,30), BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0, 16), Parent = row,
        })
        stroke(track, RGB(0,0,0), 1)
        local fill = Create("Frame", { BackgroundColor3 = self.accent, BorderSizePixel = 0,
            Size = UDim2.new(0, 0, 1, 0), Parent = track })
        local lbl = Create("TextLabel", {
            BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
            TextColor3 = RGB(255,255,255),
            Text = tostring(math.floor(def.value+0.5)) .. (def.stradd or ""),
            Size = UDim2.new(1, 0, 1, 0), Parent = track,
        })
        local function apply(v)
            store[1] = v
            local pct = (v - def.minvalue) / math.max(def.maxvalue - def.minvalue, 1)
            fill.Size = UDim2.new(clamp(pct, 0, 1), 0, 1, 0)
            lbl.Text = tostring(math.floor(v + 0.5)) .. (def.stradd or "")
        end
        store._refresh = apply
        apply(def.value)
        local sliding = false
        track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = true
                local rel = clamp((inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                apply(def.minvalue + rel * (def.maxvalue - def.minvalue))
            end
        end)
        track.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = false
                if def.callback then pcall(def.callback, store[1]) end
            end
        end)
        self.connections[#self.connections+1] = UserInputService.InputChanged:Connect(function(inp)
            if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = clamp((inp.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                apply(def.minvalue + rel * (def.maxvalue - def.minvalue))
            end
        end)

    elseif def.type == DROPBOX then
        store[1] = def.value
        store[6] = def.values
        local row = Create("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), ZIndex = 5, Parent = body,
        })
        Create("TextLabel", {
            BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 13,
            TextColor3 = RGB(255,255,255), Text = def.name,
            Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
        })
        local btn = Create("TextButton", {
            BackgroundColor3 = RGB(30,30,30), BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 16),
            Font = Enum.Font.Code, TextSize = 13, TextColor3 = RGB(255,255,255),
            Text = "  " .. tostring(def.values[def.value] or "?"),
            TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, Parent = row,
        })
        stroke(btn, RGB(0,0,0), 1)
        Create("TextLabel", {
            BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 13,
            TextColor3 = RGB(180,180,180), Text = "-", Size = UDim2.new(0, 16, 1, 0),
            Position = UDim2.new(1, -18, 0, 0), Parent = btn,
        })
        local drop = Create("Frame", {
            BackgroundColor3 = RGB(25,25,25), BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, #def.values * 18),
            Position = UDim2.new(0, 0, 0, 36), Visible = false, ZIndex = 60, Parent = row,
        })
        stroke(drop, RGB(0,0,0), 1)
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = drop })
        for i, name in ipairs(def.values) do
            local it = Create("TextButton", {
                BackgroundColor3 = RGB(25,25,25), BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.Code, TextSize = 13,
                TextColor3 = RGB(255,255,255), Text = "  " .. name,
                TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 61, Parent = drop,
            })
            it.MouseButton1Click:Connect(function()
                store[1] = i
                btn.Text = "  " .. name
                if def.callback then pcall(def.callback, i) end
                self:CloseDropdown()
            end)
            it.MouseEnter:Connect(function() it.BackgroundColor3 = self.accent end)
            it.MouseLeave:Connect(function() it.BackgroundColor3 = RGB(25,25,25) end)
        end
        store._drop = drop
        store._refresh = function(v)
            btn.Text = "  " .. tostring(def.values[v] or "?")
        end
        btn.MouseButton1Click:Connect(function()
            if self.openDropdown == store then
                self:CloseDropdown()
            else
                self:CloseDropdown()
                drop.Visible = true
                self.openDropdown = store
            end
        end)

    elseif def.type == BUTTON then
        store[1] = false
        local btn = Create("TextButton", {
            BackgroundColor3 = RGB(35,35,35), BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 22), Font = Enum.Font.Code, TextSize = 13,
            TextColor3 = RGB(255,255,255), Text = def.name, AutoButtonColor = false, Parent = body,
        })
        stroke(btn, RGB(0,0,0), 1)
        btn.MouseButton1Click:Connect(function()
            if def.callback then pcall(def.callback) else Library.Notify(def.name) end
        end)

    elseif def.type == KEYBIND then
        store[1] = def.key
        local row = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), Parent = body })
        local kb = Create("TextButton", {
            BackgroundColor3 = RGB(30,30,30), BorderSizePixel = 0,
            Size = UDim2.new(0, 44, 0, 16), Font = Enum.Font.Code, TextSize = 12,
            TextColor3 = RGB(255,255,255), Text = keyName(def.key), AutoButtonColor = false, Parent = row,
        })
        stroke(kb, RGB(0,0,0), 1)
        Create("TextLabel", {
            BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 13,
            TextColor3 = RGB(255,255,255), Text = def.name,
            Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 50, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
        })
        store._label = kb
        store._refresh = function(v) kb.Text = keyName(v) end
        kb.MouseButton1Click:Connect(function()
            self.listeningKey = store
            kb.Text = "..."
        end)

    elseif def.type == TEXTBOX then
        store[1] = def.text
        local box = Create("TextBox", {
            BackgroundColor3 = RGB(30,30,30), BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 22), Font = Enum.Font.Code, TextSize = 13,
            TextColor3 = RGB(255,255,255), Text = def.text, PlaceholderText = def.name,
            ClearTextOnFocus = false, Parent = body,
        })
        stroke(box, RGB(0,0,0), 1)
        box.FocusLost:Connect(function()
            store[1] = box.Text
            if def.callback then pcall(def.callback, box.Text) end
        end)
        store._refresh = function(v) box.Text = tostring(v) end
    end
end

function Library:CloseDropdown()
    if self.openDropdown and self.openDropdown._drop then
        self.openDropdown._drop.Visible = false
    end
    self.openDropdown = nil
end

function Library:BuildPlayerList(page)
    local box = Create("Frame", {
        BackgroundColor3 = RGB(20,20,20), BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 196), Position = UDim2.new(0, 4, 0, 4), Parent = page,
    })
    stroke(box, RGB(0,0,0), 1)
    Create("Frame", { BackgroundColor3 = self.accent, BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 1), Position = UDim2.new(0, 2, 0, 2), Parent = box })
    Create("TextLabel", {
        BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 13,
        TextColor3 = RGB(255,255,255), Text = "Player List",
        Size = UDim2.new(1, -12, 0, 18), Position = UDim2.new(0, 6, 0, 5),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = box,
    })
    local head = Create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -12, 0, 16),
        Position = UDim2.new(0, 6, 0, 24), Parent = box,
    })
    for i, t in ipairs({"Name", "Team", "Status"}) do
        Create("TextLabel", {
            BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
            TextColor3 = RGB(180,180,180), Text = t,
            Size = UDim2.new(1/3, 0, 1, 0), Position = UDim2.new((i-1)/3, 0, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = head,
        })
    end
    local rows = {}
    for i = 1, 6 do
        local row = Create("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, -12, 0, 20),
            Position = UDim2.new(0, 6, 0, 42 + (i-1)*22), Parent = box,
        })
        local cells = {}
        for c = 1, 3 do
            cells[c] = Create("TextLabel", {
                BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
                TextColor3 = RGB(255,255,255), Text = "",
                Size = UDim2.new(1/3, 0, 1, 0), Position = UDim2.new((c-1)/3, 0, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
            })
        end
        rows[i] = cells
    end
    self._plRows = rows
    local function refresh()
        local list = Players:GetPlayers()
        for i = 1, 6 do
            local p = list[i]
            if p then
                rows[i][1].Text = p.Name
                rows[i][2].Text = p.Team and p.Team.Name or "None"
                rows[i][3].Text = (p == LocalPlayer) and "You" or "None"
            else
                rows[i][1].Text, rows[i][2].Text, rows[i][3].Text = "", "", ""
            end
        end
    end
    refresh()
    self.connections[#self.connections+1] = Players.PlayerAdded:Connect(function() task.defer(refresh) end)
    self.connections[#self.connections+1] = Players.PlayerRemoving:Connect(function() task.defer(refresh) end)
    return box
end

function Library:Unload()
    self.unloaded = true
    for _, c in ipairs(self.connections) do pcall(function() c:Disconnect() end) end
    self.connections = {}
    if self.gui then self.gui:Destroy() end
    if notifHost then notifHost:Destroy() notifHost = nil end
end

return Library
