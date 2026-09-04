--[[
    BitchBot UI Library (clean rewrite)
    Style & behavior based on the original BBOT menu
    Compatible with Potassium / UNC Drawing API

    Usage:
        local Library = loadstring(...)()
        local menu = Library.new({ width=500, height=600, accent={155,155,255} })
        menu:AddTab("Legit")
        ...
        menu:Init()
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local GuiService        = game:GetService("GuiService")
local LocalPlayer       = Players.LocalPlayer
local Mouse             = LocalPlayer:GetMouse()
local Camera            = workspace.CurrentCamera

-- ============================================================
-- Types / constants
-- ============================================================
local TOGGLE, SLIDER, DROPBOX, BUTTON, KEYBIND, TEXTBOX, COMBOBOX =
    "toggle", "slider", "dropbox", "button", "keybind", "textbox", "combobox"

local RGB = Color3.fromRGB

local function clamp(n, a, b)
    if n < a then return a end
    if n > b then return b end
    return n
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function colorRange(value, ranges)
    if value <= ranges[1].start then return ranges[1].color end
    if value >= ranges[#ranges].start then return ranges[#ranges].color end
    local selected = #ranges
    for i = 1, #ranges - 1 do
        if value < ranges[i + 1].start then
            selected = i
            break
        end
    end
    local minC, maxC = ranges[selected], ranges[selected + 1]
    local t = (value - minC.start) / (maxC.start - minC.start)
    return Color3.new(
        lerp(minC.color.R, maxC.color.R, t),
        lerp(minC.color.G, maxC.color.G, t),
        lerp(minC.color.B, maxC.color.B, t)
    )
end

local KEY_NAMES = {
    One="1", Two="2", Three="3", Four="4", Five="5", Six="6", Seven="7", Eight="8", Nine="9", Zero="0",
    LeftBracket="[", RightBracket="]", Semicolon=";", BackSlash="\\", Slash="/", Minus="-", Equals="=",
    Return="Enter", Backquote="`", CapsLock="Caps", LeftShift="LShift", RightShift="RShift",
    LeftControl="LCtrl", RightControl="RCtrl", LeftAlt="LAlt", RightAlt="RAlt", Backspace="Back",
    PageUp="PgUp", PageDown="PgDown", Delete="Del", Insert="Ins", NumLock="NumL", Comma=",", Period=".",
    Space="Space", Tab="Tab", Escape="Esc",
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
-- Drawing helpers
-- ============================================================
local allDrawings = {}

local function track(list, obj)
    list[#list + 1] = obj
    allDrawings[#allDrawings + 1] = obj
    return obj
end

local function destroyDrawing(obj)
    if not obj then return end
    pcall(function()
        if obj.Remove then obj:Remove()
        elseif obj.Destroy then obj:Destroy() end
    end)
end

local Draw = {}

local function toColor3(color)
    if typeof(color) == "Color3" then
        return color
    end
    if type(color) == "table" then
        return RGB(color[1] or 255, color[2] or 255, color[3] or 255)
    end
    return RGB(255, 255, 255)
end

local function toAlpha(color, transparency)
    if transparency ~= nil then
        return transparency / 255
    end
    if type(color) == "table" and color[4] ~= nil then
        return color[4] / 255
    end
    return 1
end

function Draw.square(list, visible, x, y, w, h, color, filled, transparency)
    local o = Drawing.new("Square")
    o.Visible = visible
    o.Position = Vector2.new(x, y)
    o.Size = Vector2.new(w, h)
    o.Color = toColor3(color)
    o.Filled = filled and true or false
    o.Thickness = filled and 0 or 1
    o.Transparency = toAlpha(color, transparency)
    return track(list, o)
end

function Draw.text(list, text, visible, x, y, size, centered, color, outlineColor)
    local o = Drawing.new("Text")
    o.Visible = visible
    o.Text = tostring(text or "")
    o.Size = size or 13
    o.Center = centered and true or false
    o.Outline = true
    o.Font = 2
    o.Position = Vector2.new(x, y)
    o.Color = toColor3(color)
    if outlineColor then
        o.OutlineColor = toColor3(outlineColor)
    end
    o.Transparency = 1
    return track(list, o)
end

-- ============================================================
-- Notifications
-- ============================================================
local notes = {}
local noteConn

local function notify(msg)
    local width = 18
    local note = {
        enabled = true,
        fading = false,
        alpha = 255,
        time = 0,
        estep = 0,
        eestep = 0.02,
        insety = 0,
        target = Vector2.new(50, 33),
        size = Vector2.new(200, width),
        drawings = {},
    }
    local function rect(w, h, fill, col)
        local s = Drawing.new("Square")
        s.Visible = true
        s.Filled = fill
        s.Thickness = 1
        s.Color = col
        s.Size = Vector2.new(w, h)
        s.Position = Vector2.new()
        s.Transparency = 1
        allDrawings[#allDrawings + 1] = s
        return s
    end
    local function txt(t)
        local s = Drawing.new("Text")
        s.Visible = true
        s.Text = t
        s.Size = 13
        s.Font = 2
        s.Outline = true
        s.Color = RGB(255, 255, 255)
        s.Transparency = 1
        allDrawings[#allDrawings + 1] = s
        return s
    end
    note.drawings.outline = rect(202, width + 2, false, RGB(0, 0, 0))
    note.drawings.fade = rect(202, width + 2, false, RGB(0, 0, 0))
    for i = 1, width - 2 do
        local c = 0.28 - i / 80
        note.drawings[i] = rect(200, 1, true, Color3.new(c, c, c))
    end
    note.drawings.text = txt(tostring(msg))
    if note.drawings.text.TextBounds.X + 7 > note.size.X then
        note.size = Vector2.new(note.drawings.text.TextBounds.X + 7, note.size.Y)
    end
    note.drawings.line = rect(1, width - 2, true, RGB(155, 155, 255))
    note.drawings.line1 = rect(1, width - 2, true, RGB(87, 32, 123))
    notes[#notes + 1] = note

    if not noteConn then
        noteConn = RunService.RenderStepped:Connect(function(dt)
            for i = #notes, 1, -1 do
                if not notes[i].enabled then
                    table.remove(notes, i)
                end
            end
            local length = #notes
            for k, note in ipairs(notes) do
                if not note.enabled then continue end
                local gap = 25
                local indexOffset = (length - k) * gap
                if note.insety < indexOffset then
                    note.insety -= (note.insety - indexOffset) * 0.2
                else
                    note.insety = indexOffset
                end
                local size = note.size
                local tpos = Vector2.new(
                    note.target.X - size.X / math.max(note.time, 0.01) - (255 - note.alpha) / 255 * size.X,
                    note.target.Y + note.insety
                )
                note.pos = tpos
                local fade = math.min(note.time * 12, note.alpha)
                fade = clamp(fade, 0, 255)
                local locW = math.floor(size.X - (255 - note.alpha) / 255 * 70)
                local locX, locY = math.ceil(tpos.X), math.ceil(tpos.Y)
                for i, d in pairs(note.drawings) do
                    d.Transparency = fade / 255
                    if type(i) == "number" then
                        d.Position = Vector2.new(locX + 1, locY + i)
                        d.Size = Vector2.new(locW - 2, 1)
                    elseif i == "text" then
                        d.Position = tpos + Vector2.new(6, 2)
                    elseif i == "outline" then
                        d.Position = Vector2.new(locX, locY)
                        d.Size = Vector2.new(locW, size.Y)
                    elseif i == "fade" then
                        d.Position = Vector2.new(locX - 1, locY - 1)
                        d.Size = Vector2.new(locW + 2, size.Y + 2)
                        d.Transparency = math.max(0.4, (200 - fade) / 255 / 3)
                    elseif i == "line" then
                        d.Position = Vector2.new(locX + 1, locY + 1)
                    elseif i == "line1" then
                        d.Position = Vector2.new(locX + 2, locY + 1)
                    end
                end
                note.time += note.estep * dt * 128
                note.estep += note.eestep * dt * 64
                if k <= math.ceil(length / 10) or note.fading then
                    if tpos.X > note.target.X - 0.2 * length or note.fading then
                        if not note.fading then note.estep = 0 end
                        note.fading = true
                        note.alpha -= note.estep / 4 * length * dt * 50
                        note.eestep += 0.01 * dt * 100
                    end
                    if note.alpha <= 0 then
                        for _, d in pairs(note.drawings) do destroyDrawing(d) end
                        note.enabled = false
                    end
                end
            end
        end)
    end
end

-- ============================================================
-- Library
-- ============================================================
local Library = {}
Library.__index = Library
Library.TOGGLE = TOGGLE
Library.SLIDER = SLIDER
Library.DROPBOX = DROPBOX
Library.BUTTON = BUTTON
Library.KEYBIND = KEYBIND
Library.TEXTBOX = TEXTBOX
Library.COMBOBOX = COMBOBOX
Library.Notify = notify

function Library.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Library)

    local screen = Camera.ViewportSize
    self.w = opts.width or 500
    self.h = opts.height or 600
    self.x = math.floor(screen.X / 2 - self.w / 2)
    self.y = math.floor(screen.Y / 2 - self.h / 2)
    self.accent = opts.accent or {155, 155, 255}
    self.menuName = opts.menuName or "Bitch Bot"
    self.keybind = opts.keybind or Enum.KeyCode.RightShift
    self.open = true
    self.unloaded = false
    self.dragging = false
    self.dragOffset = Vector2.zero
    self.mousedown = false
    self.activetab = 1
    self.tabs = {}          -- { name, groups={}, drawings={}, buttons={} }
    self.controls = {}      -- flat list for input
    self.values = {}        -- [tab][group][name] = value
    self.postable = {}      -- {obj, relX, relY} for dragging
    self.connections = {}
    self.objects = {}       -- all chrome drawings
    self.openDropdown = nil
    self.activeSlider = nil
    self.listeningKey = nil
    self.watermark = { visible = true, objects = {} }
    self.playerList = nil

    -- Mouse: original BBOT used LOCAL_MOUSE with Y compared as menu.y - 36
    -- Drawing space ≈ Mouse.Y + GuiInset.Y on many clients; we expose modes.
    self.mouseMode = opts.mouseMode or "inset" -- v3-style GetMouseLocation - GuiInset
    self.mouseOffsetX = opts.mouseOffsetX or 0
    self.mouseOffsetY = opts.mouseOffsetY or 0

    return self
end

-- Cursor in Drawing coordinates
-- Reference: BBOT v3 (i77lhm) uses GetMouseLocation() - GuiInset for screen math.
-- Original v2 used LOCAL_MOUSE with Y+36 in hit tests.
function Library:GetCursor()
    local ox, oy = self.mouseOffsetX or 0, self.mouseOffsetY or 0
    local mode = self.mouseMode or "inset"

    if mode == "legacy" then
        -- Original v2: MouseInMenu compared LOCAL_MOUSE.y to menu.y - 36 + relY
        return Mouse.X + ox, Mouse.Y + 36 + oy
    elseif mode == "mouse" then
        -- Player:GetMouse() space (no inset) — same as v3 Instance hover
        return Mouse.X + ox, Mouse.Y + oy
    elseif mode == "raw" then
        local p = UserInputService:GetMouseLocation()
        return p.X + ox, p.Y + oy
    else
        -- default "inset": v3 colorpicker style — GetMouseLocation minus GuiInset
        local p = UserInputService:GetMouseLocation()
        local inset = GuiService:GetGuiInset()
        return p.X - inset.X + ox, p.Y - inset.Y + oy
    end
end

function Library:MouseIn(relX, relY, w, h)
    local mx, my = self:GetCursor()
    return mx > self.x + relX
        and mx < self.x + relX + w
        and my > self.y + relY
        and my < self.y + relY + h
end

function Library:AddPost(obj, relX, relY)
    self.postable[#self.postable + 1] = { obj, relX, relY }
end

function Library:SetPos(x, y)
    self.x, self.y = x, y
    for i = 1, #self.postable do
        local e = self.postable[i]
        if e[1] then
            pcall(function()
                e[1].Position = Vector2.new(x + e[2], y + e[3])
            end)
        end
    end
end

function Library:SyncPositions()
    self:SetPos(self.x, self.y)
end

-- Relative draw helpers (auto postable)
function Library:RFill(list, visible, rx, ry, w, h, col)
    local o = Draw.square(list, visible, self.x + rx, self.y + ry, w, h, col, true)
    self:AddPost(o, rx, ry)
    return o
end

function Library:ROutline(list, visible, rx, ry, w, h, col)
    local o = Draw.square(list, visible, self.x + rx, self.y + ry, w, h, col, false)
    self:AddPost(o, rx, ry)
    return o
end

function Library:RText(list, text, visible, rx, ry, centered, col)
    local o = Draw.text(list, text, visible, self.x + rx, self.y + ry, 13, centered, col or {255,255,255}, {0,0,0})
    self:AddPost(o, rx, ry)
    return o
end

function Library:CoolBox(list, visible, rx, ry, w, h, title)
    local ac = self.accent
    self:ROutline(list, visible, rx, ry, w, h, {0,0,0})
    self:ROutline(list, visible, rx+1, ry+1, w-2, h-2, {20,20,20})
    self:ROutline(list, visible, rx+2, ry+2, w-3, 1, {ac[1], ac[2], ac[3]})
    self:ROutline(list, visible, rx+2, ry+3, w-3, 1, {math.max(0,ac[1]-68), math.max(0,ac[2]-123), math.max(0,ac[3]-132)})
    self:ROutline(list, visible, rx+2, ry+4, w-3, 1, {20,20,20})
    for i = 0, 7 do
        local o = self:RFill(list, visible, rx+2, ry+5+i*2, w-4, 2, {45,45,45})
        o.Color = colorRange(i, {
            {start=0, color=RGB(50,50,50)},
            {start=7, color=RGB(35,35,35)},
        })
    end
    self:RText(list, title, visible, rx+6, ry+5, false)
end

-- ============================================================
-- Tabs / Groups / Options
-- ============================================================
function Library:AddTab(name)
    local tab = {
        name = name,
        groups = {},
        drawings = {},
        index = #self.tabs + 1,
    }
    self.tabs[#self.tabs + 1] = tab
    self.values[name] = self.values[name] or {}
    return tab
end

function Library:AddGroup(tab, opts)
    opts = opts or {}
    local group = {
        name = opts.name or "Group",
        side = opts.side or opts.autopos or "left", -- left | right
        width = opts.width,
        height = opts.height,
        autofill = opts.autofill,
        options = {},
        drawings = {},
    }
    tab.groups[#tab.groups + 1] = group
    self.values[tab.name][group.name] = self.values[tab.name][group.name] or {}
    return group
end

function Library:AddToggle(group, opts)
    local o = {
        type = TOGGLE,
        name = opts.name or "Toggle",
        value = opts.value and true or false,
        keybind = opts.keybind, -- optional Enum.KeyCode
        callback = opts.callback,
        drawings = {},
        hit = nil, -- {x,y,w,h} relative
    }
    group.options[#group.options + 1] = o
    return o
end

function Library:AddSlider(group, opts)
    local o = {
        type = SLIDER,
        name = opts.name or "Slider",
        value = opts.value or 0,
        min = opts.min or opts.minvalue or 0,
        max = opts.max or opts.maxvalue or 100,
        stradd = opts.stradd or "",
        decimal = opts.decimal,
        callback = opts.callback,
        drawings = {},
        hit = nil,
        fill = nil,
        label = nil,
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
        open = false,
        callback = opts.callback,
        drawings = {},
        items = {},
        hit = nil,
        text = nil,
    }
    group.options[#group.options + 1] = o
    return o
end

function Library:AddButton(group, opts)
    local o = {
        type = BUTTON,
        name = opts.name or "Button",
        callback = opts.callback,
        drawings = {},
        hit = nil,
    }
    group.options[#group.options + 1] = o
    return o
end

function Library:AddKeybind(group, opts)
    local o = {
        type = KEYBIND,
        name = opts.name or "Key",
        value = opts.key or opts.value or Enum.KeyCode.E,
        listening = false,
        callback = opts.callback,
        drawings = {},
        hit = nil,
        text = nil,
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
        drawings = {},
        hit = nil,
        text = nil,
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
-- Build UI
-- ============================================================
function Library:BuildChrome()
    local list = self.objects
    local ac = self.accent
    local w, h = self.w, self.h

    -- outer frames
    self:ROutline(list, true, 0, 0, w, h, {0,0,0})
    self:ROutline(list, true, 1, 1, w-2, h-2, {20,20,20})
    self:ROutline(list, true, 2, 2, w-3, 1, {ac[1],ac[2],ac[3]})
    self:ROutline(list, true, 2, 3, w-3, 1, {math.max(0,ac[1]-68), math.max(0,ac[2]-123), math.max(0,ac[3]-132)})
    self:ROutline(list, true, 2, 4, w-3, 1, {20,20,20})
    for i = 0, 19 do
        local o = self:RFill(list, true, 2, 5+i, w-4, 1, {20,20,20})
        o.Color = colorRange(i, {{start=0,color=RGB(50,50,50)},{start=20,color=RGB(35,35,35)}})
    end
    for i = 0, 19 do
        local o = self:RFill(list, true, 2, h-24+i, w-4, 1, {20,20,20})
        o.Color = colorRange(i, {{start=0,color=RGB(35,35,35)},{start=20,color=RGB(50,50,50)}})
    end
    self:ROutline(list, true, 7, 25, w-14, h-50, {0,0,0})
    self:ROutline(list, true, 8, 26, w-16, h-52, {40,40,40})
    for i = 0, 17 do
        local o = self:RFill(list, true, 9, 27+i, w-18, 1, {40,40,40})
        o.Color = colorRange(i, {{start=0,color=RGB(50,50,50)},{start=17,color=RGB(35,35,35)}})
    end
    self:ROutline(list, true, 9, 45, w-18, h-72, {0,0,0})
    self:ROutline(list, true, 10, 46, w-20, h-74, {20,20,20})
    self:ROutline(list, true, 11, 47, w-22, h-76, {10,10,10})
    self:RFill(list, true, 11, 47, w-22, h-76, {15,15,15})

    self:RText(list, self.menuName, true, 8, 6, false)
    self:RText(list, "bbot.gg", true, w - 52, h - 18, false, {100,100,100})
end

function Library:BuildTabs()
    local n = #self.tabs
    if n == 0 then return end
    local tabW = math.floor((self.w - 20) / n)
    self.tabButtons = {}
    for i, tab in ipairs(self.tabs) do
        local rx = 10 + (i - 1) * tabW
        local ry = 27
        local active = (i == self.activetab)
        -- tab bg strips
        for j = 0, 14 do
            local o = self:RFill(self.objects, true, rx, ry+1+j, tabW, 1, {40,40,40})
            if active then
                o.Color = colorRange(j, {{start=0,color=RGB(40,40,40)},{start=14,color=RGB(25,25,25)}})
            else
                o.Color = colorRange(j, {{start=0,color=RGB(45,45,45)},{start=14,color=RGB(35,35,35)}})
            end
            tab._bg = tab._bg or {}
            tab._bg[#tab._bg+1] = o
        end
        self:ROutline(self.objects, true, rx, ry, tabW, 16, {0,0,0})
        local label = self:RText(self.objects, tab.name, true, rx + math.floor(tabW/2), ry+1, true)
        tab._label = label
        self.tabButtons[#self.tabButtons+1] = { index=i, x=rx, y=ry, w=tabW, h=16 }
    end
    -- active underline
    local tb = self.tabButtons[self.activetab]
    if tb then
        self.tabUnderline = self:RFill(self.objects, true, tb.x, 42, tb.w, 2, self.accent)
    end
end

function Library:UpdateTabVisuals()
    for i, tab in ipairs(self.tabs) do
        local active = (i == self.activetab)
        if tab._bg then
            for j, o in ipairs(tab._bg) do
                if active then
                    o.Color = colorRange(j-1, {{start=0,color=RGB(40,40,40)},{start=14,color=RGB(25,25,25)}})
                else
                    o.Color = colorRange(j-1, {{start=0,color=RGB(45,45,45)},{start=14,color=RGB(35,35,35)}})
                end
            end
        end
        -- show/hide group drawings
        for _, g in ipairs(tab.groups) do
            for _, d in ipairs(g.drawings) do
                d.Visible = active and self.open
            end
            for _, opt in ipairs(g.options) do
                -- main control drawings
                for _, d in ipairs(opt.drawings) do
                    d.Visible = active and self.open
                end
                -- dropdown items: ONLY if this dropdown is open
                if opt.type == DROPBOX and opt.items then
                    local showItems = active and self.open and opt.open
                    for _, item in ipairs(opt.items) do
                        item.bg.Visible = showItems
                        item.text.Visible = showItems
                    end
                end
            end
        end
    end
    if self.tabUnderline and self.tabButtons[self.activetab] then
        local tb = self.tabButtons[self.activetab]
        -- update relative post entry: find underline in postable
        self.tabUnderline.Position = Vector2.new(self.x + tb.x, self.y + 42)
        for _, e in ipairs(self.postable) do
            if e[1] == self.tabUnderline then
                e[2], e[3] = tb.x, 42
            end
        end
    end
end

function Library:BuildGroup(tab, group)
    local visible = (tab.index == self.activetab)
    local colW = math.floor((self.w - 40) / 2)
    local gw = group.width or colW
    local isLeft = group.side == "left"
    -- stack groups per side
    group._stackY = group._stackY or 0
    local gx = isLeft and 16 or (16 + colW + 8)
    local gy = 56 + (group._yOffset or 0)
    -- measure content height
    local cy = 24
    for _, opt in ipairs(group.options) do
        if opt.type == TOGGLE or opt.type == KEYBIND then cy += 18
        elseif opt.type == SLIDER then cy += 30
        elseif opt.type == DROPBOX or opt.type == COMBOBOX then cy += 40
        elseif opt.type == BUTTON or opt.type == TEXTBOX then cy += 28
        else cy += 20 end
    end
    local gh = group.height or (group.autofill and (cy + 10) or math.max(cy + 10, 80))
    group.gx, group.gy, group.gw, group.gh = gx, gy, gw, gh

    self:CoolBox(group.drawings, visible, gx, gy, gw, gh, group.name)

    local y = gy + 22
    for _, opt in ipairs(group.options) do
        self.values[tab.name][group.name][opt.name] = opt.value
        if opt.type == TOGGLE then
            self:BuildToggle(tab, group, opt, gx, y, visible)
            y += 18
        elseif opt.type == SLIDER then
            self:BuildSlider(tab, group, opt, gx, y, gw, visible)
            y += 30
        elseif opt.type == DROPBOX then
            self:BuildDropbox(tab, group, opt, gx, y, gw, visible)
            y += 40
        elseif opt.type == BUTTON then
            self:BuildButton(tab, group, opt, gx, y, gw, visible)
            y += 28
        elseif opt.type == KEYBIND then
            self:BuildKeybind(tab, group, opt, gx, y, visible)
            y += 18
        elseif opt.type == TEXTBOX then
            self:BuildTextbox(tab, group, opt, gx, y, gw, visible)
            y += 28
        end
        self.controls[#self.controls+1] = { tab=tab.index, tabName=tab.name, group=group.name, opt=opt }
    end
    return gh + 8
end

function Library:BuildToggle(tab, group, opt, gx, y, visible)
    local list = opt.drawings
    self:ROutline(list, visible, gx+8, y, 12, 12, {30,30,30})
    self:ROutline(list, visible, gx+9, y+1, 10, 10, {0,0,0})
    local fills = {}
    for i = 0, 3 do
        local f = self:RFill(list, visible, gx+10, y+2+i*2, 8, 2, {0,0,0})
        fills[i+1] = f
    end
    opt._fills = fills
    self:UpdateToggleVisual(opt)
    self:RText(list, opt.name, visible, gx+24, y-1, false)
    opt.hit = { x=gx+7, y=y-1, w=20, h=14 }
    if opt.keybind then
        local kx = gx + group.gw - 52
        self:RFill(list, visible, kx, y-1, 44, 16, {25,25,25})
        self:ROutline(list, visible, kx, y-1, 44, 16, {30,30,30})
        self:ROutline(list, visible, kx+1, y, 42, 14, {0,0,0})
        opt._kbText = self:RText(list, keyName(opt.keybind), visible, kx+22, y+1, true)
    end
end

function Library:UpdateToggleVisual(opt)
    local on = opt.value
    local ac = self.accent
    for i, f in ipairs(opt._fills or {}) do
        if on then
            f.Color = colorRange(i-1, {
                {start=0, color=RGB(ac[1],ac[2],ac[3])},
                {start=3, color=RGB(math.max(0,ac[1]-50), math.max(0,ac[2]-50), math.max(0,ac[3]-50))},
            })
        else
            f.Color = colorRange(i-1, {
                {start=0, color=RGB(50,50,50)},
                {start=3, color=RGB(30,30,30)},
            })
        end
    end
end

function Library:BuildSlider(tab, group, opt, gx, y, gw, visible)
    local list = opt.drawings
    local length = gw - 16
    self:RText(list, opt.name, visible, gx+8, y-3, false)
    for i = 0, 3 do
        self:RFill(list, visible, gx+10, y+14+i*2, length-4, 2, {0,0,0})
    end
    local pct = (opt.value - opt.min) / math.max(opt.max - opt.min, 1)
    local fills = {}
    for i = 0, 3 do
        local f = self:RFill(list, visible, gx+10, y+14+i*2, (length-4)*pct, 2, {0,0,0})
        fills[i+1] = f
    end
    opt._fills = fills
    self:ROutline(list, visible, gx+8, y+12, length, 12, {30,30,30})
    self:ROutline(list, visible, gx+9, y+13, length-2, 10, {0,0,0})
    local valStr = opt.decimal and string.format("%."..tostring(opt.decimal):len().."f", opt.value) or tostring(math.floor(opt.value + 0.5))
    opt._label = self:RText(list, valStr .. (opt.stradd or ""), visible, gx+8+length*0.5, y+11, true)
    opt.hit = { x=gx+8, y=y+12, w=length, h=12 }
    self:UpdateSliderVisual(opt)
end

function Library:UpdateSliderVisual(opt)
    local pct = clamp((opt.value - opt.min) / math.max(opt.max - opt.min, 1), 0, 1)
    local ac = self.accent
    local full = (opt.hit and opt.hit.w or 100) - 4
    for i, f in ipairs(opt._fills or {}) do
        f.Size = Vector2.new(full * pct, 2)
        f.Color = colorRange(i-1, {
            {start=0, color=RGB(ac[1],ac[2],ac[3])},
            {start=3, color=RGB(math.max(0,ac[1]-50), math.max(0,ac[2]-50), math.max(0,ac[3]-50))},
        })
    end
    if opt._label then
        local v = opt.decimal and opt.value or math.floor(opt.value + 0.5)
        opt._label.Text = tostring(v) .. (opt.stradd or "")
    end
end

function Library:BuildDropbox(tab, group, opt, gx, y, gw, visible)
    local list = opt.drawings
    local length = gw - 16
    self:RText(list, opt.name, visible, gx+8, y-3, false)
    for i = 0, 7 do
        local o = self:RFill(list, visible, gx+10, y+14+i*2, length-4, 2, {0,0,0})
        o.Color = colorRange(i, {{start=0,color=RGB(50,50,50)},{start=7,color=RGB(35,35,35)}})
    end
    self:ROutline(list, visible, gx+8, y+12, length, 22, {30,30,30})
    self:ROutline(list, visible, gx+9, y+13, length-2, 20, {0,0,0})
    opt._text = self:RText(list, tostring(opt.values[opt.value] or "?"), visible, gx+14, y+16, false)
    self:RText(list, "-", visible, gx+8+length-17, y+16, false)
    opt.hit = { x=gx+8, y=y+12, w=length, h=22 }
    opt.open = false
    -- items ALWAYS start hidden; stored separately so tab show/hide won't force them on
    opt.items = {}
    for i, name in ipairs(opt.values) do
        local iy = y + 34 + (i-1)*18
        local bg = self:RFill(list, false, gx+8, iy, length, 18, {25,25,25})
        bg.Visible = false
        local tx = self:RText(list, tostring(name), false, gx+14, iy+2, false)
        tx.Visible = false
        opt.items[#opt.items+1] = { bg=bg, text=tx, x=gx+8, y=iy, w=length, h=18, value=i }
    end
end

function Library:OpenDropdown(opt)
    -- close any other open dropdown first
    if self.openDropdown and self.openDropdown ~= opt then
        self:CloseDropdown()
    end
    opt.open = true
    self.openDropdown = opt
    for _, item in ipairs(opt.items or {}) do
        item.bg.Visible = true
        item.text.Visible = true
    end
end

function Library:CloseDropdown()
    local opt = self.openDropdown
    if opt then
        opt.open = false
        for _, item in ipairs(opt.items or {}) do
            item.bg.Visible = false
            item.text.Visible = false
        end
    end
    -- also force-close every dropbox (safety)
    for _, c in ipairs(self.controls) do
        local o = c.opt
        if o.type == DROPBOX then
            o.open = false
            for _, item in ipairs(o.items or {}) do
                item.bg.Visible = false
                item.text.Visible = false
            end
        end
    end
    self.openDropdown = nil
end

function Library:BuildButton(tab, group, opt, gx, y, gw, visible)
    local list = opt.drawings
    local length = gw - 16
    for i = 0, 8 do
        local o = self:RFill(list, visible, gx+10, y+2+i*2, length-4, 2, {0,0,0})
        o.Color = colorRange(i, {{start=0,color=RGB(50,50,50)},{start=8,color=RGB(35,35,35)}})
    end
    self:ROutline(list, visible, gx+8, y, length, 22, {30,30,30})
    self:ROutline(list, visible, gx+9, y+1, length-2, 20, {0,0,0})
    self:RText(list, opt.name, visible, gx+8+math.floor(length*0.5), y+4, true)
    opt.hit = { x=gx+8, y=y, w=length, h=22 }
end

function Library:BuildKeybind(tab, group, opt, gx, y, visible)
    local list = opt.drawings
    self:RFill(list, visible, gx+8, y, 44, 16, {25,25,25})
    self:ROutline(list, visible, gx+8, y, 44, 16, {30,30,30})
    self:ROutline(list, visible, gx+9, y+1, 42, 14, {0,0,0})
    opt._text = self:RText(list, keyName(opt.value), visible, gx+30, y+1, true)
    self:RText(list, opt.name, visible, gx+56, y, false)
    opt.hit = { x=gx+8, y=y, w=44, h=16 }
end

function Library:BuildTextbox(tab, group, opt, gx, y, gw, visible)
    local list = opt.drawings
    local length = gw - 16
    for i = 0, 8 do
        local o = self:RFill(list, visible, gx+10, y+2+i*2, length-4, 2, {0,0,0})
        o.Color = colorRange(i, {{start=0,color=RGB(50,50,50)},{start=8,color=RGB(35,35,35)}})
    end
    self:ROutline(list, visible, gx+8, y, length, 22, {30,30,30})
    self:ROutline(list, visible, gx+9, y+1, length-2, 20, {0,0,0})
    opt._text = self:RText(list, opt.value, visible, gx+14, y+4, false)
    opt.hit = { x=gx+8, y=y, w=length, h=22 }
end

function Library:BuildWatermark()
    local list = self.watermark.objects
    local text = string.format("Bitch Bot | %s | %s", self.menuName, LocalPlayer.Name)
    local t = Draw.text(list, text, self.watermark.visible, 12, 8, 13, false, {255,255,255}, {0,0,0})
    local w = t.TextBounds.X + 14
    local bg = Draw.square(list, self.watermark.visible, 8, 4, w, 22, {15,15,15}, true)
    local ac = Draw.square(list, self.watermark.visible, 8, 4, w, 2, self.accent, true)
    -- restack text on top
    t.Position = Vector2.new(14, 8)
    self.watermark._text = t
end

function Library:BuildPlayerList(tab, group)
    local list = group.drawings
    local visible = (tab.index == self.activetab)
    local x, y, w, h = 16, 56, self.w - 32, 200
    group.gx, group.gy, group.gw, group.gh = x, y, w, h
    self:CoolBox(list, visible, x, y, w, h, "Player List")
    self:RText(list, "Name", visible, x+10, y+22, false)
    self:RText(list, "Team", visible, x+math.floor(w/3)+10, y+22, false)
    self:RText(list, "Status", visible, x+math.floor(2*w/3)+10, y+22, false)
    self:ROutline(list, visible, x+6, y+38, w-12, 22*6+4, {30,30,30})
    local rows = {}
    for i = 1, 6 do
        local iy = y + 42 + (i-1)*22
        local n = self:RText(list, "", visible, x+10, iy, false)
        local team = self:RText(list, "", visible, x+math.floor(w/3)+10, iy, false)
        local s = self:RText(list, "", visible, x+math.floor(2*w/3)+10, iy, false)
        rows[i] = {n, team, s}
        if i < 6 then self:ROutline(list, visible, x+8, iy+18, w-16, 1, {20,20,20}) end
    end
    self.playerList = { rows=rows, drawings=list }
    self:RefreshPlayerList()
    return 210 -- height used
end

function Library:RefreshPlayerList()
    if not self.playerList then return end
    local rows = self.playerList.rows
    local players = Players:GetPlayers()
    for i = 1, #rows do
        local p = players[i]
        if p then
            rows[i][1].Text = p.Name
            rows[i][2].Text = p.Team and p.Team.Name or "None"
            rows[i][3].Text = (p == LocalPlayer) and "You" or "None"
        else
            rows[i][1].Text = ""
            rows[i][2].Text = ""
            rows[i][3].Text = ""
        end
    end
end

function Library:LayoutTab(tab)
    local yLeft, yRight = 0, 0
    for _, group in ipairs(tab.groups) do
        if group.name == "Player List" then
            -- full-width block; push BOTH columns below it
            local h = self:BuildPlayerList(tab, group)
            yLeft = math.max(yLeft, h)
            yRight = math.max(yRight, h)
            continue
        end
        local isLeft = group.side == "left"
        group._yOffset = isLeft and yLeft or yRight
        local used = self:BuildGroup(tab, group)
        if isLeft then yLeft += used else yRight += used end
    end
end

function Library:Init()
    self:BuildChrome()
    self:BuildTabs()
    for _, tab in ipairs(self.tabs) do
        self:LayoutTab(tab)
    end
    self:BuildWatermark()
    self:UpdateTabVisuals()
    self:SetupInput()
    notify("UI loaded")
end

function Library:SwitchTab(idx)
    if idx < 1 or idx > #self.tabs then return end
    if self.openDropdown then self:CloseDropdown() end
    self.activetab = idx
    self:SyncPositions()
    self:UpdateTabVisuals()
end

function Library:SetVisible(v)
    self.open = v
    for _, o in ipairs(self.objects) do
        o.Visible = v
    end
    self:UpdateTabVisuals()
end

-- ============================================================
-- Input
-- ============================================================
function Library:SetupInput()
    self.connections[#self.connections+1] = UserInputService.InputBegan:Connect(function(input)
        if self.unloaded then return end

        if input.KeyCode == self.keybind then
            self:SetVisible(not self.open)
            notify(self.open and "Menu opened" or "Menu closed")
            return
        end

        -- keybind capture
        if self.listeningKey and input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
            local opt = self.listeningKey
            opt.value = input.KeyCode
            opt.listening = false
            if opt._text then opt._text.Text = keyName(opt.value) end
            self:SetVal(opt._tabName, opt._groupName, opt.name, opt.value)
            self.listeningKey = nil
            notify(opt.name .. " = " .. keyName(opt.value))
            return
        end

        if not self.open then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        self.mousedown = true

        -- Prefer the click's own position for this frame (most accurate)
        if input.Position then
            self._clickX = input.Position.X
            self._clickY = input.Position.Y
            if self.mouseMode == "legacy" then
                -- input.Position is typically already in inset-aware space;
                -- legacy drawing compares using Mouse.Y+36. Keep GetCursor for drag.
            end
        end

        -- drag
        if self:MouseIn(0, 0, self.w, 25) then
            local mx, my = self:GetCursor()
            self.dragging = true
            self.dragOffset = Vector2.new(mx - self.x, my - self.y)
            return
        end

        -- tabs
        for _, tb in ipairs(self.tabButtons or {}) do
            if self:MouseIn(tb.x, tb.y, tb.w, tb.h) then
                self:SwitchTab(tb.index)
                return
            end
        end

        -- dropdown items
        if self.openDropdown then
            local opt = self.openDropdown
            for _, item in ipairs(opt.items or {}) do
                if self:MouseIn(item.x, item.y, item.w, item.h) then
                    opt.value = item.value
                    if opt._text then opt._text.Text = tostring(opt.values[item.value]) end
                    self:SetVal(opt._tabName, opt._groupName, opt.name, opt.value)
                    if opt.callback then pcall(opt.callback, opt.value) end
                    self:CloseDropdown()
                    return
                end
            end
            if not self:MouseIn(opt.hit.x, opt.hit.y, opt.hit.w, opt.hit.h) then
                self:CloseDropdown()
            end
        end

        -- controls
        for _, c in ipairs(self.controls) do
            if c.tab ~= self.activetab then continue end
            local opt = c.opt
            local hit = opt.hit
            if not hit then continue end

            if opt.type == TOGGLE then
                if self:MouseIn(hit.x, hit.y, hit.w, hit.h) then
                    opt.value = not opt.value
                    self:UpdateToggleVisual(opt)
                    self:SetVal(c.tabName, c.group, opt.name, opt.value)
                    if opt.callback then pcall(opt.callback, opt.value) end
                    return
                end
            elseif opt.type == SLIDER then
                if self:MouseIn(hit.x, hit.y, hit.w, hit.h) then
                    self.activeSlider = opt
                    opt._tabName, opt._groupName = c.tabName, c.group
                    local mx = self:GetCursor()
                    local rel = clamp((mx - (self.x + hit.x)) / hit.w, 0, 1)
                    opt.value = opt.min + rel * (opt.max - opt.min)
                    self:UpdateSliderVisual(opt)
                    self:SetVal(c.tabName, c.group, opt.name, opt.value)
                    return
                end
            elseif opt.type == DROPBOX then
                if self:MouseIn(hit.x, hit.y, hit.w, hit.h) then
                    opt._tabName, opt._groupName = c.tabName, c.group
                    if opt.open then self:CloseDropdown() else self:OpenDropdown(opt) end
                    return
                end
            elseif opt.type == BUTTON then
                if self:MouseIn(hit.x, hit.y, hit.w, hit.h) then
                    if opt.callback then pcall(opt.callback) else notify("Clicked: " .. opt.name) end
                    return
                end
            elseif opt.type == KEYBIND then
                if self:MouseIn(hit.x, hit.y, hit.w, hit.h) then
                    opt.listening = true
                    opt._tabName, opt._groupName = c.tabName, c.group
                    self.listeningKey = opt
                    if opt._text then opt._text.Text = "..." end
                    notify("Press a key for " .. opt.name)
                    return
                end
            end
        end
    end)

    self.connections[#self.connections+1] = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.mousedown = false
            self.dragging = false
            if self.activeSlider then
                local opt = self.activeSlider
                self:SetVal(opt._tabName, opt._groupName, opt.name, opt.value)
                if opt.callback then pcall(opt.callback, opt.value) end
                self.activeSlider = nil
            end
        end
    end)

    self.connections[#self.connections+1] = UserInputService.InputChanged:Connect(function(input)
        if self.unloaded then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement and self.activeSlider and self.mousedown then
            local opt = self.activeSlider
            local hit = opt.hit
            local mx = self:GetCursor()
            local rel = clamp((mx - (self.x + hit.x)) / hit.w, 0, 1)
            opt.value = opt.min + rel * (opt.max - opt.min)
            self:UpdateSliderVisual(opt)
        end
    end)

    self.connections[#self.connections+1] = RunService.RenderStepped:Connect(function()
        if self.unloaded then return end
        if self.dragging then
            local mx, my = self:GetCursor()
            self:SetPos(mx - self.dragOffset.X, my - self.dragOffset.Y)
        end
        for _, o in ipairs(self.watermark.objects) do
            o.Visible = self.watermark.visible
        end
    end)

    self.connections[#self.connections+1] = Players.PlayerAdded:Connect(function()
        task.defer(function() self:RefreshPlayerList() end)
    end)
    self.connections[#self.connections+1] = Players.PlayerRemoving:Connect(function()
        task.defer(function() self:RefreshPlayerList() end)
    end)
end

function Library:Unload()
    self.unloaded = true
    for _, c in ipairs(self.connections) do
        pcall(function() c:Disconnect() end)
    end
    self.connections = {}
    for _, o in ipairs(allDrawings) do
        destroyDrawing(o)
    end
    allDrawings = {}
    if noteConn then pcall(function() noteConn:Disconnect() end) noteConn = nil end
end

return Library
