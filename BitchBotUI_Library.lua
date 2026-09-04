local Library = {}
Library.__index = Library

-- ========================
-- CONSTANTS
-- ========================
local COLOR = 1
local COLOR1 = 2
local COLOR2 = 3
local COMBOBOX = 4
local TOGGLE = 5
local KEYBIND = 6
local DROPBOX = 7
local COLORPICKER = 8
local DOUBLE_COLORPICKERS = 9
local SLIDER = 10
local BUTTON = 11
local LIST = 12
local IMAGE = 13
local TEXTBOX = 14

-- ========================
-- SERVICES
-- ========================
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local HttpService = game:GetService("HttpService")

-- ========================
-- UTILS
-- ========================
local function RGB(r, g, b)
    return Color3.fromRGB(math.clamp(r or 255, 0, 255), math.clamp(g or 255, 0, 255), math.clamp(b or 255, 0, 255))
end

local function clamp(n, min, max)
    return math.max(min, math.min(max, n))
end

local function map(n, oldMin, oldMax, min, max)
    return (n - oldMin) / (oldMax - oldMin) * (max - min) + min
end

local function round(num, places)
    local mult = 10 ^ (places or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local n = {}
    for k, v in pairs(t) do
        n[k] = deepCopy(v)
    end
    return n
end

-- ========================
-- DRAWING SYSTEM
-- ========================
local Draw = {}
local allRender = {}

function Draw:UnRender()
    for _, group in pairs(allRender) do
        for _, obj in pairs(group) do
            if obj and type(obj) ~= "number" and pcall(function() return obj.__OBJECT_EXISTS end) then
                pcall(function() obj:Remove() end)
            end
        end
    end
    table.clear(allRender)
end

function Draw:OutlinedRect(visible, x, y, w, h, color, group)
    local obj = Drawing.new("Square")
    obj.Visible = visible
    obj.Position = Vector2.new(x, y)
    obj.Size = Vector2.new(w, h)
    obj.Color = RGB(color[1], color[2], color[3])
    obj.Filled = false
    obj.Thickness = 1
    obj.Transparency = (color[4] or 255) / 255
    table.insert(group, obj)
    if not table.find(allRender, group) then table.insert(allRender, group) end
    return obj
end

function Draw:FilledRect(visible, x, y, w, h, color, group)
    local obj = Drawing.new("Square")
    obj.Visible = visible
    obj.Position = Vector2.new(x, y)
    obj.Size = Vector2.new(w, h)
    obj.Color = RGB(color[1], color[2], color[3])
    obj.Filled = true
    obj.Thickness = 0
    obj.Transparency = (color[4] or 255) / 255
    table.insert(group, obj)
    if not table.find(allRender, group) then table.insert(allRender, group) end
    return obj
end

function Draw:Line(visible, thickness, x1, y1, x2, y2, color, group)
    local obj = Drawing.new("Line")
    obj.Visible = visible
    obj.Thickness = thickness or 1
    obj.From = Vector2.new(x1, y1)
    obj.To = Vector2.new(x2, y2)
    obj.Color = RGB(color[1], color[2], color[3])
    obj.Transparency = (color[4] or 255) / 255
    table.insert(group, obj)
    if not table.find(allRender, group) then table.insert(allRender, group) end
    return obj
end

function Draw:Text(text, font, visible, x, y, size, centered, color, group)
    local obj = Drawing.new("Text")
    obj.Text = tostring(text)
    obj.Visible = visible
    obj.Position = Vector2.new(x, y)
    obj.Size = size or 13
    obj.Center = centered or false
    obj.Color = RGB(color[1], color[2], color[3])
    obj.Transparency = (color[4] or 255) / 255
    obj.Outline = false
    obj.Font = font or 2
    table.insert(group, obj)
    if not table.find(allRender, group) then table.insert(allRender, group) end
    return obj
end

function Draw:OutlinedText(text, font, visible, x, y, size, centered, color, outlineColor, group)
    local obj = Drawing.new("Text")
    obj.Text = tostring(text)
    obj.Visible = visible
    obj.Position = Vector2.new(x, y)
    obj.Size = size or 13
    obj.Center = centered or false
    obj.Color = RGB(color[1], color[2], color[3])
    obj.Transparency = (color[4] or 255) / 255
    obj.Outline = true
    obj.OutlineColor = RGB(outlineColor[1] or 0, outlineColor[2] or 0, outlineColor[3] or 0)
    obj.Font = font or 2
    table.insert(group, obj)
    if not table.find(allRender, group) then table.insert(allRender, group) end
    return obj
end

function Draw:Image(visible, data, x, y, w, h, transparency, group)
    local obj = Drawing.new("Image")
    obj.Visible = visible
    obj.Position = Vector2.new(x, y)
    obj.Size = Vector2.new(w, h)
    obj.Transparency = transparency or 1
    if data then obj.Data = data end
    table.insert(group, obj)
    if not table.find(allRender, group) then table.insert(allRender, group) end
    return obj
end

function Draw:Circle(visible, x, y, radius, thickness, sides, color, group)
    local obj = Drawing.new("Circle")
    obj.Position = Vector2.new(x, y)
    obj.Visible = visible
    obj.Radius = radius
    obj.Thickness = thickness or 1
    obj.NumSides = sides or 32
    obj.Transparency = (color[4] or 255) / 255
    obj.Filled = false
    obj.Color = RGB(color[1], color[2], color[3])
    table.insert(group, obj)
    if not table.find(allRender, group) then table.insert(allRender, group) end
    return obj
end

function Draw:FilledCircle(visible, x, y, radius, thickness, sides, color, group)
    local obj = Drawing.new("Circle")
    obj.Position = Vector2.new(x, y)
    obj.Visible = visible
    obj.Radius = radius
    obj.Thickness = thickness or 1
    obj.NumSides = sides or 32
    obj.Transparency = (color[4] or 255) / 255
    obj.Filled = true
    obj.Color = RGB(color[1], color[2], color[3])
    table.insert(group, obj)
    if not table.find(allRender, group) then table.insert(allRender, group) end
    return obj
end

-- Menu relative
function Draw:MenuOutlinedRect(menu, visible, x, y, w, h, color, group)
    local obj = Draw:OutlinedRect(visible, x + menu.x, y + menu.y, w, h, color, group)
    table.insert(menu.postable, {obj, x, y})
    return obj
end

function Draw:MenuFilledRect(menu, visible, x, y, w, h, color, group)
    local obj = Draw:FilledRect(visible, x + menu.x, y + menu.y, w, h, color, group)
    table.insert(menu.postable, {obj, x, y})
    return obj
end

function Draw:MenuBigText(menu, text, visible, centered, x, y, group)
    local obj = Draw:OutlinedText(text, 2, visible, x + menu.x, y + menu.y, 13, centered, {255,255,255,255}, {0,0,0}, group)
    table.insert(menu.postable, {obj, x, y})
    return obj
end

function Draw:MenuImage(menu, visible, data, x, y, w, h, transparency, group)
    local obj = Draw:Image(visible, data, x + menu.x, y + menu.y, w, h, transparency, group)
    table.insert(menu.postable, {obj, x, y})
    return obj
end

-- ========================
-- NOTIFICATIONS
-- ========================
local notes = {}
local NotifLogs = {}

local function CreateDrawingObject(typ, col)
    local d = Drawing.new(typ)
    d.Visible = true
    d.Transparency = 1
    d.Color = col
    return d
end

local function CreateRect(w, h, filled, col)
    local s = CreateDrawingObject("Square", col)
    s.Filled = filled
    s.Thickness = 1
    s.Position = Vector2.new()
    s.Size = Vector2.new(w, h)
    return s
end

local function CreateText(txt)
    local s = CreateDrawingObject("Text", Color3.new(1,1,1))
    s.Text = txt
    s.Size = 13
    s.Center = false
    s.Outline = true
    s.Position = Vector2.new()
    s.Font = 2
    return s
end

function Library.CreateNotification(text, customColor)
    table.insert(NotifLogs, string.format("[%s]: %s", os.date("%X"), text))

    local gap = 25
    local width = 18
    local alpha = 255
    local time = 0
    local estep = 0
    local eestep = 0.02
    local insety = 0

    local Note = {
        enabled = true,
        targetPos = Vector2.new(50, 33),
        size = Vector2.new(200, width),
        drawings = {
            outline = CreateRect(202, width + 2, false, Color3.new(0,0,0)),
            fade = CreateRect(202, width + 2, false, Color3.new(0,0,0)),
        },
        Remove = function(self)
            for _, d in pairs(self.drawings) do
                if d and d.Remove then pcall(function() d:Remove() end) end
            end
            self.enabled = false
        end,
        Update = function(self, num, listLength, dt)
            local pos = self.targetPos
            local indexOffset = (listLength - num) * gap
            if insety < indexOffset then
                insety = insety - (insety - indexOffset) * 0.2
            else
                insety = indexOffset
            end

            local tpos = Vector2.new(
                pos.x - self.size.x / math.max(time, 0.01) - map(alpha, 0, 255, self.size.x, 0),
                pos.y + insety
            )
            self.pos = tpos

            local locRect = {
                x = math.ceil(tpos.x),
                y = math.ceil(tpos.y),
                w = math.floor(self.size.x - map(255 - alpha, 0, 255, 0, 70)),
                h = self.size.y,
            }

            local fade = math.clamp(math.min(time * 12, alpha), 0, 255)

            if self.enabled then
                local linenum = 1
                for i, drawing in pairs(self.drawings) do
                    drawing.Transparency = fade / 255
                    if type(i) == "number" then
                        drawing.Position = Vector2.new(locRect.x + 1, locRect.y + i)
                        drawing.Size = Vector2.new(locRect.w - 2, 1)
                    elseif i == "text" then
                        drawing.Position = tpos + Vector2.new(6, 2)
                    elseif i == "outline" then
                        drawing.Position = Vector2.new(locRect.x, locRect.y)
                        drawing.Size = Vector2.new(locRect.w, locRect.h)
                    elseif i == "fade" then
                        drawing.Position = Vector2.new(locRect.x - 1, locRect.y - 1)
                        drawing.Size = Vector2.new(locRect.w + 2, locRect.h + 2)
                        drawing.Transparency = math.max((200 - fade) / 255 / 3, 0.4)
                    elseif tostring(i):find("line") then
                        drawing.Position = Vector2.new(locRect.x + linenum, locRect.y + 1)
                        linenum += 1
                    end
                end
                time += estep * dt * 128
                estep += eestep * dt * 64
            end
        end,
        Fade = function(self, num, len, dt)
            if self.pos and (self.pos.x > self.targetPos.x - 0.2 * len or self.fading) then
                if not self.fading then estep = 0 end
                self.fading = true
                alpha -= estep / 4 * len * dt * 50
                eestep += 0.01 * dt * 100
            end
            if alpha <= 0 then
                self:Remove()
            end
        end,
    }

    for i = 1, Note.size.y - 2 do
        local c = 0.28 - i / 80
        Note.drawings[i] = CreateRect(200, 1, true, Color3.new(c, c, c))
    end

    local accent = customColor or Color3.fromRGB(100, 100, 225)
    Note.drawings.text = CreateText(text)
    if Note.drawings.text.TextBounds and Note.drawings.text.TextBounds.X + 7 > Note.size.x then
        Note.size = Vector2.new(Note.drawings.text.TextBounds.X + 7, Note.size.y)
    end
    Note.drawings.line = CreateRect(1, Note.size.y - 2, true, accent)
    Note.drawings.line1 = CreateRect(1, Note.size.y - 2, true, accent)

    table.insert(notes, Note)
end

RunService.RenderStepped:Connect(function(dt)
    for k = #notes, 1, -1 do
        if not (notes[k] and notes[k].enabled) then
            table.remove(notes, k)
        end
    end
    local length = #notes
    for k = 1, length do
        local note = notes[k]
        if note then
            note:Update(k, length, dt)
            if k <= math.ceil(length / 10) or note.fading then
                note:Fade(k, length, dt)
            end
        end
    end
end)

-- ========================
-- RELATIONS SYSTEM
-- ========================
local Relations = {
    friends = {},
    priority = {},
}

local function UnpackRelations()
    local path = "bitchbot/relations.bb"
    if isfile and isfile(path) then
        local str = readfile(path)
        if str and not str:find("bb:{{") then
            local friendsStart = str:find("friends:")
            local priorityStart = str:find("\npriority:")
            if friendsStart and priorityStart then
                local friendList = str:sub(friendsStart + 8, priorityStart - 1)
                local priorityList = str:sub(priorityStart + 10)
                for name in friendList:gmatch("[^,]+") do
                    name = name:match("^%s*(.-)%s*$")
                    if name ~= "" and not table.find(Relations.friends, name) then
                        table.insert(Relations.friends, name)
                    end
                end
                for name in priorityList:gmatch("[^,]+") do
                    name = name:match("^%s*(.-)%s*$")
                    if name ~= "" and not table.find(Relations.priority, name) then
                        table.insert(Relations.priority, name)
                    end
                end
            end
        end
    end
    if not table.find(Relations.friends, LocalPlayer.Name) then
        table.insert(Relations.friends, LocalPlayer.Name)
    end
end

local function WriteRelations()
    local str = "friends:"
    for _, v in ipairs(Relations.friends) do
        str ..= tostring(v) .. ","
    end
    str ..= "\npriority:"
    for _, v in ipairs(Relations.priority) do
        str ..= tostring(v) .. ","
    end
    if writefile then
        if not isfolder("bitchbot") then makefolder("bitchbot") end
        writefile("bitchbot/relations.bb", str)
    end
end

-- ========================
-- CONFIG SYSTEM
-- ========================
local Configs = {}

local function EnsureFolders(gameName)
    if not isfolder then return end
    if not isfolder("bitchbot") then makefolder("bitchbot") end
    if not isfolder("bitchbot/" .. gameName) then makefolder("bitchbot/" .. gameName) end
end

local function GetConfigs(gameName)
    local result = {}
    if not listfiles then return result end
    EnsureFolders(gameName)
    local dir = "bitchbot/" .. gameName
    for _, path in ipairs(listfiles(dir) or {}) do
        local name = path:match("([^/\\]+)%.bb$")
        if name then
            table.insert(result, name)
            Configs[name] = path
        end
    end
    if #result == 0 then
        writefile(dir .. "/Default.bb", "{}")
        table.insert(result, "Default")
        Configs["Default"] = dir .. "/Default.bb"
    end
    return result
end

local function SaveConfig(menu, name, gameName)
    if not writefile then
        Library.CreateNotification("writefile not available")
        return false
    end
    EnsureFolders(gameName)
    local data = {
        values = menu.values or {},
        friends = Relations.friends,
        priority = Relations.priority,
        accent = menu.mc,
    }
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if success then
        writefile("bitchbot/" .. gameName .. "/" .. name .. ".bb", encoded)
        Library.CreateNotification("Config saved: " .. name)
        return true
    else
        Library.CreateNotification("Failed to encode config")
        return false
    end
end

local function LoadConfig(menu, name, gameName)
    if not readfile or not isfile then
        Library.CreateNotification("Filesystem not available")
        return false
    end
    local path = "bitchbot/" .. gameName .. "/" .. name .. ".bb"
    if not isfile(path) then
        Library.CreateNotification("Config not found: " .. name)
        return false
    end
    local content = readfile(path)
    local success, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if success and type(data) == "table" then
        if data.values then
            menu.values = data.values
        end
        if data.friends then
            Relations.friends = data.friends
        end
        if data.priority then
            Relations.priority = data.priority
        end
        if data.accent then
            menu.mc = data.accent
        end
        Library.CreateNotification("Config loaded: " .. name)
        return true
    else
        Library.CreateNotification("Failed to decode config")
        return false
    end
end

local function DeleteConfig(name, gameName)
    if not delfile then return false end
    local path = "bitchbot/" .. gameName .. "/" .. name .. ".bb"
    if isfile(path) then
        delfile(path)
        Library.CreateNotification("Config deleted: " .. name)
        return true
    end
    return false
end

-- ========================
-- MENU CLASS
-- ========================
function Library.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Library)

    self.w = opts.width or 520
    self.h = opts.height or 620
    self.x = math.floor((Camera.ViewportSize.X / 2) - (self.w / 2))
    self.y = math.floor((Camera.ViewportSize.Y / 2) - (self.h / 2))
    self.open = true
    self.fading = false
    self.fadestart = 0
    self.activetab = 1
    self.mousedown = false
    self.dragging = false
    self.dragOffset = Vector2.new()
    self.mc = opts.accent or {155, 155, 255}
    self.options = {}
    self.values = {}
    self.connections = {}
    self.postable = {}
    self.tabnames = {}
    self.unloaded = false
    self.gameName = opts.gameName or "Universal"
    self.menuName = opts.menuName or "Bitch Bot"
    self.keybind = opts.keybind or Enum.KeyCode.Delete

    self.columns = {
        width = math.floor((self.w - 40) / 2),
        left = 17,
        right = math.floor((self.w - 20) / 2) + 13,
    }

    -- Watermark
    self.watermark = {
        text = self.menuName .. " | " .. (opts.username or "user") .. " | " .. os.date("%b. %d, %Y"),
        pos = Vector2.new(20, 10),
        visible = true,
        objects = {},
    }

    -- Player list state
    self.selectedPlayer = nil
    self.playerListData = {}

    -- Initialize folders & relations
    EnsureFolders(self.gameName)
    UnpackRelations()
    WriteRelations()

    self:CreateWatermark()
    self:SetupInput()

    return self
end

function Library:CreateWatermark()
    local wm = self.watermark
    local objects = {}
    local width = (#wm.text * 7) + 14
    local height = 20

    Draw:FilledRect(true, wm.pos.x, wm.pos.y + 1, width, 2, {self.mc[1]-40, self.mc[2]-40, self.mc[3]-40, 255}, objects)
    Draw:FilledRect(true, wm.pos.x, wm.pos.y, width, 2, {self.mc[1], self.mc[2], self.mc[3], 255}, objects)
    for i = 0, height - 4 do
        local c = 50 - i * 1.7
        Draw:FilledRect(true, wm.pos.x, wm.pos.y + 3 + i, width, 1, {c, c, c, 255}, objects)
    end
    Draw:OutlinedRect(true, wm.pos.x, wm.pos.y, width, height, {0,0,0,255}, objects)
    Draw:OutlinedRect(true, wm.pos.x - 1, wm.pos.y - 1, width + 2, height + 2, {0,0,0,100}, objects)
    Draw:OutlinedText(wm.text, 2, true, wm.pos.x + 6, wm.pos.y + 3, 13, false, {255,255,255,255}, {0,0,0}, objects)

    wm.objects = objects
    wm.width = width
    wm.height = height
end

function Library:UpdateWatermark()
    local wm = self.watermark
    if not wm.visible then
        for _, o in pairs(wm.objects) do o.Visible = false end
        return
    end
    for _, o in pairs(wm.objects) do o.Visible = true end
end

function Library:SetupInput()
    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == self.keybind then
            self.open = not self.open
            Library.CreateNotification(self.open and "Menu opened" or "Menu closed")
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.mousedown = true
            if self.open then
                local mx, my = Mouse.X, Mouse.Y
                if mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + 25 then
                    self.dragging = true
                    self.dragOffset = Vector2.new(mx - self.x, my - self.y)
                end
            end
        end
    end))

    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.mousedown = false
            self.dragging = false
        end
    end))

    table.insert(self.connections, RunService.RenderStepped:Connect(function()
        if self.unloaded then return end
        if self.dragging then
            self.x = Mouse.X - self.dragOffset.X
            self.y = Mouse.Y - self.dragOffset.Y
            self:UpdatePositions()
        end
        self:UpdateWatermark()
    end))
end

function Library:UpdatePositions()
    for _, entry in ipairs(self.postable) do
        local obj, ox, oy = entry[1], entry[2], entry[3]
        if obj and obj.Position then
            obj.Position = Vector2.new(self.x + ox, self.y + oy)
        end
    end
end

function Library:GetVal(tab, group, option, typ)
    local key = table.concat({tab or "", group or "", option or ""}, "/")
    local val = self.values[key]
    if typ == COLOR and type(val) == "table" then
        return RGB(val[1], val[2], val[3])
    end
    return val
end

function Library:SetVal(tab, group, option, value)
    local key = table.concat({tab or "", group or "", option or ""}, "/")
    self.values[key] = value
end

function Library:IsFriend(name)
    return table.find(Relations.friends, name) ~= nil
end

function Library:IsPriority(name)
    return table.find(Relations.priority, name) ~= nil
end

function Library:AddFriend(name)
    if not table.find(Relations.friends, name) then
        table.insert(Relations.friends, name)
        WriteRelations()
    end
end

function Library:RemoveFriend(name)
    local idx = table.find(Relations.friends, name)
    if idx then
        table.remove(Relations.friends, idx)
        WriteRelations()
    end
end

function Library:AddPriority(name)
    if not table.find(Relations.priority, name) then
        table.insert(Relations.priority, name)
        WriteRelations()
    end
end

function Library:RemovePriority(name)
    local idx = table.find(Relations.priority, name)
    if idx then
        table.remove(Relations.priority, idx)
        WriteRelations()
    end
end

function Library:GetFriends()
    return Relations.friends
end

function Library:GetPriority()
    return Relations.priority
end

-- Simple control builders (expandable)
function Library:AddToggle(tab, group, name, default, callback)
    local key = tab .. "/" .. group .. "/" .. name
    self.values[key] = default or false
    -- In a full render system you would create the visual here
    -- For now we store the value and allow GetVal/SetVal
    if callback then
        -- store callback if needed
    end
    return function()
        return self.values[key]
    end
end

function Library:AddSlider(tab, group, name, default, min, max, callback)
    local key = tab .. "/" .. group .. "/" .. name
    self.values[key] = default or min
    return function()
        return self.values[key]
    end
end

function Library:SaveConfig(name)
    return SaveConfig(self, name or "Default", self.gameName)
end

function Library:LoadConfig(name)
    return LoadConfig(self, name or "Default", self.gameName)
end

function Library:DeleteConfig(name)
    return DeleteConfig(name or "Default", self.gameName)
end

function Library:GetConfigList()
    return GetConfigs(self.gameName)
end

function Library:Unload()
    self.unloaded = true
    Draw:UnRender()
    for _, conn in pairs(self.connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(self.connections)
    Library.CreateNotification("UI unloaded")
end

-- ========================
-- EXAMPLE USAGE / DEMO MENU
-- ========================
--[[
    Example of how to use the library:

    local UI = loadstring(game:HttpGet("..."))()  -- or require the module

    local menu = UI.new({
        width = 520,
        height = 620,
        accent = {155, 155, 255},
        menuName = "My Cheat",
        username = "dev",
        gameName = "Phantom Forces",
        keybind = Enum.KeyCode.RightShift,
    })

    -- Add some values
    menu:AddToggle("Legit", "Aim Assist", "Enabled", true)
    menu:AddSlider("Legit", "Aim Assist", "FOV", 30, 0, 180)
    menu:AddToggle("Rage", "Aimbot", "Enabled", false)

    -- Config
    menu:SaveConfig("MyConfig")
    menu:LoadConfig("MyConfig")

    -- Relations
    print(menu:IsFriend("SomePlayer"))
    menu:AddPriority("TargetPlayer")

    -- Notifications
    UI.CreateNotification("Library loaded!")

    -- Unload later
    -- menu:Unload()
]]

-- Auto demo notification when the library is required/executed
task.defer(function()
    Library.CreateNotification("BitchBot UI Library loaded (Potassium compatible)")
    Library.CreateNotification("Press the configured key to toggle menu (default Delete)")
end)

return Library
