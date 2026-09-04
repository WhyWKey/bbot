local Library = {}
Library.__index = Library

-- ============================================================
-- CONSTANTS (match original)
-- ============================================================
Library.COLOR               = 1
Library.COLOR1              = 2
Library.COLOR2              = 3
Library.COMBOBOX            = 4
Library.TOGGLE              = 5
Library.KEYBIND             = 6
Library.DROPBOX             = 7
Library.COLORPICKER         = 8
Library.DOUBLE_COLORPICKERS = 9
Library.SLIDER              = 10
Library.BUTTON              = 11
Library.LIST                = 12
Library.IMAGE               = 13
Library.TEXTBOX             = 14

local COLOR, COLOR1, COLOR2 = 1, 2, 3
local COMBOBOX, TOGGLE, KEYBIND = 4, 5, 6
local DROPBOX, COLORPICKER, DOUBLE_COLORPICKERS = 7, 8, 9
local SLIDER, BUTTON, LIST, IMAGE, TEXTBOX = 10, 11, 12, 13, 14

-- ============================================================
-- SERVICES
-- ============================================================
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer
local Mouse            = LocalPlayer:GetMouse()
local Camera           = workspace.CurrentCamera

-- ============================================================
-- UTILS
-- ============================================================
local function RGB(r, g, b)
    return Color3.fromRGB(
        math.clamp(tonumber(r) or 255, 0, 255),
        math.clamp(tonumber(g) or 255, 0, 255),
        math.clamp(tonumber(b) or 255, 0, 255)
    )
end

local function clamp(n, lo, hi)
    return math.max(lo, math.min(hi, n))
end

local function map(n, a, b, c, d)
    return (n - a) / (b - a) * (d - c) + c
end

local function ColorRange(value, ranges)
    if value <= ranges[1].start then return ranges[1].color end
    if value >= ranges[#ranges].start then return ranges[#ranges].color end
    local selected = #ranges
    for i = 1, #ranges - 1 do
        if value < ranges[i + 1].start then selected = i break end
    end
    local minC, maxC = ranges[selected], ranges[selected + 1]
    local t = (value - minC.start) / (maxC.start - minC.start)
    return Color3.new(
        minC.color.R + (maxC.color.R - minC.color.R) * t,
        minC.color.G + (maxC.color.G - minC.color.G) * t,
        minC.color.B + (maxC.color.B - minC.color.B) * t
    )
end

local function KeyEnumToName(key)
    if key == nil then return "None" end
    local s = tostring(key)
    local name = s:match("KeyCode%.(.+)") or s:match("UserInputType%.(.+)") or "None"
    local remap = {
        LeftShift = "LShift", RightShift = "RShift",
        LeftControl = "LCtrl", RightControl = "RCtrl",
        LeftAlt = "LAlt", RightAlt = "RAlt",
        Backspace = "Back", Return = "Enter",
        One="1",Two="2",Three="3",Four="4",Five="5",
        Six="6",Seven="7",Eight="8",Nine="9",Zero="0",
    }
    return remap[name] or name
end

-- ============================================================
-- DRAWING SYSTEM
-- ============================================================
local Draw = {}
local allRender = {}

function Draw:UnRender()
    for _, group in pairs(allRender) do
        for _, obj in pairs(group) do
            if type(obj) ~= "number" and obj then
                pcall(function() obj:Remove() end)
            end
        end
    end
    table.clear(allRender)
end

local function track(group)
    if not table.find(allRender, group) then
        table.insert(allRender, group)
    end
end

function Draw:OutlinedRect(vis, x, y, w, h, col, group)
    local o = Drawing.new("Square")
    o.Visible = vis
    o.Position = Vector2.new(x, y)
    o.Size = Vector2.new(w, h)
    o.Color = RGB(col[1], col[2], col[3])
    o.Filled = false
    o.Thickness = 1
    o.Transparency = (col[4] or 255) / 255
    table.insert(group, o)
    track(group)
    return o
end

function Draw:FilledRect(vis, x, y, w, h, col, group)
    local o = Drawing.new("Square")
    o.Visible = vis
    o.Position = Vector2.new(x, y)
    o.Size = Vector2.new(w, h)
    o.Color = RGB(col[1], col[2], col[3])
    o.Filled = true
    o.Thickness = 0
    o.Transparency = (col[4] or 255) / 255
    table.insert(group, o)
    track(group)
    return o
end

function Draw:Line(vis, thick, x1, y1, x2, y2, col, group)
    local o = Drawing.new("Line")
    o.Visible = vis
    o.Thickness = thick or 1
    o.From = Vector2.new(x1, y1)
    o.To = Vector2.new(x2, y2)
    o.Color = RGB(col[1], col[2], col[3])
    o.Transparency = (col[4] or 255) / 255
    table.insert(group, o)
    track(group)
    return o
end

function Draw:Text(txt, font, vis, x, y, size, center, col, group)
    local o = Drawing.new("Text")
    o.Text = tostring(txt)
    o.Visible = vis
    o.Position = Vector2.new(x, y)
    o.Size = size or 13
    o.Center = center or false
    o.Color = RGB(col[1], col[2], col[3])
    o.Transparency = (col[4] or 255) / 255
    o.Outline = false
    o.Font = font or 2
    table.insert(group, o)
    track(group)
    return o
end

function Draw:OutlinedText(txt, font, vis, x, y, size, center, col, ocol, group)
    local o = Drawing.new("Text")
    o.Text = tostring(txt)
    o.Visible = vis
    o.Position = Vector2.new(x, y)
    o.Size = size or 13
    o.Center = center or false
    o.Color = RGB(col[1], col[2], col[3])
    o.Transparency = (col[4] or 255) / 255
    o.Outline = true
    o.OutlineColor = RGB(ocol[1] or 0, ocol[2] or 0, ocol[3] or 0)
    o.Font = font or 2
    table.insert(group, o)
    track(group)
    return o
end

function Draw:Image(vis, data, x, y, w, h, trans, group)
    local o = Drawing.new("Image")
    o.Visible = vis
    o.Position = Vector2.new(x, y)
    o.Size = Vector2.new(w, h)
    o.Transparency = trans or 1
    if data then o.Data = data end
    table.insert(group, o)
    track(group)
    return o
end

function Draw:Circle(vis, x, y, r, thick, sides, col, group)
    local o = Drawing.new("Circle")
    o.Position = Vector2.new(x, y)
    o.Visible = vis
    o.Radius = r
    o.Thickness = thick or 1
    o.NumSides = sides or 32
    o.Transparency = (col[4] or 255) / 255
    o.Filled = false
    o.Color = RGB(col[1], col[2], col[3])
    table.insert(group, o)
    track(group)
    return o
end

function Draw:FilledCircle(vis, x, y, r, thick, sides, col, group)
    local o = Drawing.new("Circle")
    o.Position = Vector2.new(x, y)
    o.Visible = vis
    o.Radius = r
    o.Thickness = thick or 1
    o.NumSides = sides or 32
    o.Transparency = (col[4] or 255) / 255
    o.Filled = true
    o.Color = RGB(col[1], col[2], col[3])
    table.insert(group, o)
    track(group)
    return o
end

-- Menu-relative
function Draw:MenuOutlinedRect(menu, vis, x, y, w, h, col, group)
    local o = Draw:OutlinedRect(vis, x + menu.x, y + menu.y, w, h, col, group)
    table.insert(menu.postable, {o, x, y})
    return o
end

function Draw:MenuFilledRect(menu, vis, x, y, w, h, col, group)
    local o = Draw:FilledRect(vis, x + menu.x, y + menu.y, w, h, col, group)
    table.insert(menu.postable, {o, x, y})
    return o
end

function Draw:MenuBigText(menu, txt, vis, center, x, y, group)
    local o = Draw:OutlinedText(txt, 2, vis, x + menu.x, y + menu.y, 13, center,
        {255,255,255,255}, {0,0,0}, group)
    table.insert(menu.postable, {o, x, y})
    return o
end

function Draw:MenuImage(menu, vis, data, x, y, w, h, trans, group)
    local o = Draw:Image(vis, data, x + menu.x, y + menu.y, w, h, trans, group)
    table.insert(menu.postable, {o, x, y})
    return o
end

-- High-level control drawers
function Draw:CoolBox(menu, name, x, y, w, h, group)
    Draw:MenuOutlinedRect(menu, true, x, y, w, h, {0,0,0,255}, group)
    Draw:MenuOutlinedRect(menu, true, x+1, y+1, w-2, h-2, {20,20,20,255}, group)
    Draw:MenuOutlinedRect(menu, true, x+2, y+2, w-3, 1, {menu.mc[1], menu.mc[2], menu.mc[3], 255}, group)
    Draw:MenuOutlinedRect(menu, true, x+2, y+3, w-3, 1, {
        math.max(0, menu.mc[1]-68), math.max(0, menu.mc[2]-123), math.max(0, menu.mc[3]-132), 255
    }, group)
    Draw:MenuOutlinedRect(menu, true, x+2, y+4, w-3, 1, {20,20,20,255}, group)
    for i = 0, 7 do
        local c = ColorRange(i, {
            {start=0, color=RGB(45,45,45)},
            {start=7, color=RGB(35,35,35)}
        })
        Draw:MenuFilledRect(menu, true, x+2, y+5+(i*2), w-4, 2, {c.R*255, c.G*255, c.B*255, 255}, group)
    end
    Draw:MenuBigText(menu, name, true, false, x+6, y+5, group)
end

function Draw:Toggle(menu, name, value, x, y, group)
    Draw:MenuOutlinedRect(menu, true, x, y, 12, 12, {30,30,30,255}, group)
    Draw:MenuOutlinedRect(menu, true, x+1, y+1, 10, 10, {0,0,0,255}, group)
    local boxes = {}
    for i = 0, 3 do
        local col = value and ColorRange(i, {
            {start=0, color=RGB(menu.mc[1], menu.mc[2], menu.mc[3])},
            {start=3, color=RGB(menu.mc[1]-40, menu.mc[2]-40, menu.mc[3]-40)}
        }) or ColorRange(i, {
            {start=0, color=RGB(50,50,50)},
            {start=3, color=RGB(30,30,30)}
        })
        local r = Draw:MenuFilledRect(menu, true, x+2, y+2+(i*2), 8, 2, {col.R*255, col.G*255, col.B*255, 255}, group)
        table.insert(boxes, r)
    end
    local txt = Draw:MenuBigText(menu, name, true, false, x+16, y-1, group)
    return {boxes = boxes, text = txt}
end

function Draw:Slider(menu, name, value, minv, maxv, stradd, x, y, length, group)
    Draw:MenuBigText(menu, name, true, false, x, y-3, group)
    for i = 0, 3 do
        local c = ColorRange(i, {{start=0, color=RGB(50,50,50)}, {start=3, color=RGB(30,30,30)}})
        Draw:MenuFilledRect(menu, true, x+2, y+14+(i*2), length-4, 2, {c.R*255, c.G*255, c.B*255, 255}, group)
    end
    local fill = {}
    local pct = clamp((value - minv) / math.max(maxv - minv, 1), 0, 1)
    for i = 0, 3 do
        local c = ColorRange(i, {
            {start=0, color=RGB(menu.mc[1], menu.mc[2], menu.mc[3])},
            {start=3, color=RGB(menu.mc[1]-40, menu.mc[2]-40, menu.mc[3]-40)}
        })
        local r = Draw:MenuFilledRect(menu, true, x+2, y+14+(i*2), (length-4)*pct, 2, {c.R*255, c.G*255, c.B*255, 255}, group)
        table.insert(fill, r)
    end
    Draw:MenuOutlinedRect(menu, true, x, y+12, length, 12, {30,30,30,255}, group)
    Draw:MenuOutlinedRect(menu, true, x+1, y+13, length-2, 10, {0,0,0,255}, group)
    local label = Draw:MenuBigText(menu, tostring(value)..(stradd or ""), true, true, x+length*0.5, y+11, group)
    return {fill = fill, label = label}
end

function Draw:Dropbox(menu, name, value, values, x, y, length, group)
    Draw:MenuBigText(menu, name, true, false, x, y-3, group)
    for i = 0, 7 do
        local c = ColorRange(i, {{start=0, color=RGB(50,50,50)}, {start=7, color=RGB(35,35,35)}})
        Draw:MenuFilledRect(menu, true, x+2, y+14+(i*2), length-4, 2, {c.R*255, c.G*255, c.B*255, 255}, group)
    end
    Draw:MenuOutlinedRect(menu, true, x, y+12, length, 22, {30,30,30,255}, group)
    Draw:MenuOutlinedRect(menu, true, x+1, y+13, length-2, 20, {0,0,0,255}, group)
    local txt = Draw:MenuBigText(menu, tostring(values[value] or "?"), true, false, x+6, y+16, group)
    Draw:MenuBigText(menu, "-", true, false, x-17+length, y+16, group)
    return {text = txt}
end

function Draw:Button(menu, name, x, y, length, group)
    local fills = {}
    for i = 0, 8 do
        local c = ColorRange(i, {{start=0, color=RGB(50,50,50)}, {start=8, color=RGB(35,35,35)}})
        local r = Draw:MenuFilledRect(menu, true, x+2, y+2+(i*2), length-4, 2, {c.R*255, c.G*255, c.B*255, 255}, group)
        table.insert(fills, r)
    end
    Draw:MenuOutlinedRect(menu, true, x, y, length, 22, {30,30,30,255}, group)
    Draw:MenuOutlinedRect(menu, true, x+1, y+1, length-2, 20, {0,0,0,255}, group)
    local txt = Draw:MenuBigText(menu, name, true, true, x+math.floor(length*0.5), y+4, group)
    return {fills = fills, text = txt}
end

function Draw:Keybind(menu, key, x, y, group)
    Draw:MenuFilledRect(menu, true, x, y, 44, 16, {25,25,25,255}, group)
    local txt = Draw:MenuBigText(menu, KeyEnumToName(key), true, true, x+22, y+1, group)
    Draw:MenuOutlinedRect(menu, true, x, y, 44, 16, {30,30,30,255}, group)
    Draw:MenuOutlinedRect(menu, true, x+1, y+1, 42, 14, {0,0,0,255}, group)
    return {text = txt}
end

function Draw:ColorPicker(menu, color, x, y, group)
    Draw:MenuOutlinedRect(menu, true, x, y, 28, 14, {30,30,30,255}, group)
    Draw:MenuOutlinedRect(menu, true, x+1, y+1, 26, 12, {0,0,0,255}, group)
    local fill = Draw:MenuFilledRect(menu, true, x+2, y+2, 24, 10, {color[1], color[2], color[3], 255}, group)
    Draw:MenuOutlinedRect(menu, true, x+2, y+2, 24, 10, {color[1]-40, color[2]-40, color[3]-40, 255}, group)
    return {fill = fill}
end

function Draw:TextBox(menu, text, x, y, length, group)
    for i = 0, 8 do
        local c = ColorRange(i, {{start=0, color=RGB(50,50,50)}, {start=8, color=RGB(35,35,35)}})
        Draw:MenuFilledRect(menu, true, x+2, y+2+(i*2), length-4, 2, {c.R*255, c.G*255, c.B*255, 255}, group)
    end
    Draw:MenuOutlinedRect(menu, true, x, y, length, 22, {30,30,30,255}, group)
    Draw:MenuOutlinedRect(menu, true, x+1, y+1, length-2, 20, {0,0,0,255}, group)
    local txt = Draw:MenuBigText(menu, text, true, false, x+6, y+4, group)
    return {text = txt}
end

function Draw:List(menu, headers, x, y, length, maxRows, columns, group)
    for i, h in ipairs(headers) do
        Draw:MenuBigText(menu, h, true, false,
            (math.floor(length/columns)*i) - math.floor(length/columns) + 30, y-3, group)
    end
    Draw:MenuOutlinedRect(menu, true, x, y+12, length, 22*maxRows+4, {30,30,30,255}, group)
    Draw:MenuOutlinedRect(menu, true, x+1, y+13, length-2, 22*maxRows+2, {0,0,0,255}, group)

    local rows, words = {}, {}
    for i = 1, maxRows do
        rows[i], words[i] = {}, {}
        if i ~= maxRows then
            table.insert(rows[i], Draw:MenuOutlinedRect(menu, true, x+4, (y+13)+(22*i), length-8, 2, {20,20,20,255}, group))
        end
        for c = 1, columns do
            table.insert(words[i], Draw:MenuBigText(menu, "", true, false,
                (x + math.floor(length/columns)*c) - math.floor(length/columns) + 5,
                (y+13)+(22*i)-16, group))
        end
    end
    return {rows = rows, words = words}
end

Library.Draw = Draw

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
local notes = {}
local NotifLogs = {}

local function CObj(typ, col)
    local d = Drawing.new(typ)
    d.Visible = true
    d.Transparency = 1
    d.Color = col
    return d
end

local function CRect(w, h, filled, col)
    local s = CObj("Square", col)
    s.Filled = filled
    s.Thickness = 1
    s.Position = Vector2.new()
    s.Size = Vector2.new(w, h)
    return s
end

local function CText(txt)
    local s = CObj("Text", Color3.new(1,1,1))
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
    local gap, width, alpha, time, estep, eestep, insety = 25, 18, 255, 0, 0, 0.02, 0

    local Note = {
        enabled = true,
        targetPos = Vector2.new(50, 33),
        size = Vector2.new(200, width),
        drawings = {
            outline = CRect(202, width+2, false, Color3.new(0,0,0)),
            fade    = CRect(202, width+2, false, Color3.new(0,0,0)),
        },
        Remove = function(self)
            for _, d in pairs(self.drawings) do
                if d and d.Remove then pcall(function() d:Remove() end) end
            end
            self.enabled = false
        end,
        Update = function(self, num, len, dt)
            local pos = self.targetPos
            local idxOff = (len - num) * gap
            if insety < idxOff then insety = insety - (insety - idxOff)*0.2 else insety = idxOff end
            local tpos = Vector2.new(
                pos.x - self.size.x / math.max(time, 0.01) - map(alpha, 0, 255, self.size.x, 0),
                pos.y + insety
            )
            self.pos = tpos
            local lr = {
                x = math.ceil(tpos.x), y = math.ceil(tpos.y),
                w = math.floor(self.size.x - map(255-alpha, 0, 255, 0, 70)),
                h = self.size.y
            }
            local fade = math.clamp(math.min(time*12, alpha), 0, 255)
            if self.enabled then
                local ln = 1
                for i, d in pairs(self.drawings) do
                    d.Transparency = fade / 255
                    if type(i) == "number" then
                        d.Position = Vector2.new(lr.x+1, lr.y+i)
                        d.Size = Vector2.new(lr.w-2, 1)
                    elseif i == "text" then
                        d.Position = tpos + Vector2.new(6, 2)
                    elseif i == "outline" then
                        d.Position = Vector2.new(lr.x, lr.y)
                        d.Size = Vector2.new(lr.w, lr.h)
                    elseif i == "fade" then
                        d.Position = Vector2.new(lr.x-1, lr.y-1)
                        d.Size = Vector2.new(lr.w+2, lr.h+2)
                        d.Transparency = math.max((200-fade)/255/3, 0.4)
                    elseif tostring(i):find("line") then
                        d.Position = Vector2.new(lr.x + ln, lr.y + 1)
                        ln += 1
                    end
                end
                time += estep * dt * 128
                estep += eestep * dt * 64
            end
        end,
        Fade = function(self, num, len, dt)
            if self.pos and (self.pos.x > self.targetPos.x - 0.2*len or self.fading) then
                if not self.fading then estep = 0 end
                self.fading = true
                alpha -= estep/4 * len * dt * 50
                eestep += 0.01 * dt * 100
            end
            if alpha <= 0 then self:Remove() end
        end,
    }

    for i = 1, Note.size.y-2 do
        local c = 0.28 - i/80
        Note.drawings[i] = CRect(200, 1, true, Color3.new(c,c,c))
    end
    local accent = customColor or Color3.fromRGB(100,100,225)
    Note.drawings.text = CText(text)
    if Note.drawings.text.TextBounds and Note.drawings.text.TextBounds.X + 7 > Note.size.x then
        Note.size = Vector2.new(Note.drawings.text.TextBounds.X + 7, Note.size.y)
    end
    Note.drawings.line  = CRect(1, Note.size.y-2, true, accent)
    Note.drawings.line1 = CRect(1, Note.size.y-2, true, accent)
    table.insert(notes, Note)
end

RunService.RenderStepped:Connect(function(dt)
    for k = #notes, 1, -1 do
        if not (notes[k] and notes[k].enabled) then table.remove(notes, k) end
    end
    local len = #notes
    for k = 1, len do
        local n = notes[k]
        if n then
            n:Update(k, len, dt)
            if k <= math.ceil(len/10) or n.fading then n:Fade(k, len, dt) end
        end
    end
end)

-- ============================================================
-- RELATIONS
-- ============================================================
local Relations = { friends = {}, priority = {} }

local function UnpackRelations()
    if not (isfile and isfile("bitchbot/relations.bb")) then return end
    local str = readfile("bitchbot/relations.bb")
    if not str or str:find("bb:{{") then return end
    local fs, ps = str:find("friends:"), str:find("\npriority:")
    if not (fs and ps) then return end
    for name in str:sub(fs+8, ps-1):gmatch("[^,]+") do
        name = name:match("^%s*(.-)%s*$")
        if name ~= "" and not table.find(Relations.friends, name) then
            table.insert(Relations.friends, name)
        end
    end
    for name in str:sub(ps+10):gmatch("[^,]+") do
        name = name:match("^%s*(.-)%s*$")
        if name ~= "" and not table.find(Relations.priority, name) then
            table.insert(Relations.priority, name)
        end
    end
    if not table.find(Relations.friends, LocalPlayer.Name) then
        table.insert(Relations.friends, LocalPlayer.Name)
    end
end

local function WriteRelations()
    local s = "friends:"
    for _, v in ipairs(Relations.friends) do s ..= tostring(v) .. "," end
    s ..= "\npriority:"
    for _, v in ipairs(Relations.priority) do s ..= tostring(v) .. "," end
    if writefile then
        if not isfolder("bitchbot") then makefolder("bitchbot") end
        writefile("bitchbot/relations.bb", s)
    end
end

-- ============================================================
-- CONFIG SYSTEM
-- ============================================================
local function EnsureFolders(gameName)
    if not isfolder then return end
    if not isfolder("bitchbot") then makefolder("bitchbot") end
    if not isfolder("bitchbot/" .. gameName) then makefolder("bitchbot/" .. gameName) end
end

local function GetConfigs(gameName)
    local res = {}
    if not listfiles then return res end
    EnsureFolders(gameName)
    for _, path in ipairs(listfiles("bitchbot/" .. gameName) or {}) do
        local name = path:match("([^/\\]+)%.bb$")
        if name then table.insert(res, name) end
    end
    if #res == 0 then
        pcall(writefile, "bitchbot/" .. gameName .. "/Default.bb", "{}")
        table.insert(res, "Default")
    end
    return res
end

local function SaveConfig(menu, name, gameName)
    if not writefile then
        Library.CreateNotification("writefile unavailable")
        return false
    end
    EnsureFolders(gameName)
    local data = {
        values   = menu.values or {},
        friends  = Relations.friends,
        priority = Relations.priority,
        accent   = menu.mc,
        menuName = menu.menuName,
    }
    local ok, enc = pcall(HttpService.JSONEncode, HttpService, data)
    if ok then
        writefile("bitchbot/" .. gameName .. "/" .. name .. ".bb", enc)
        Library.CreateNotification("Saved config: " .. name)
        return true
    end
    Library.CreateNotification("Config encode failed")
    return false
end

local function LoadConfig(menu, name, gameName)
    if not (readfile and isfile) then
        Library.CreateNotification("Filesystem unavailable")
        return false
    end
    local path = "bitchbot/" .. gameName .. "/" .. name .. ".bb"
    if not isfile(path) then
        Library.CreateNotification("Config not found: " .. name)
        return false
    end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, readfile(path))
    if ok and type(data) == "table" then
        if data.values   then menu.values = data.values end
        if data.friends  then Relations.friends = data.friends end
        if data.priority then Relations.priority = data.priority end
        if data.accent   then menu.mc = data.accent end
        if data.menuName then menu.menuName = data.menuName end
        Library.CreateNotification("Loaded config: " .. name)
        return true
    end
    Library.CreateNotification("Config decode failed")
    return false
end

local function DeleteConfig(name, gameName)
    if not delfile then return false end
    local path = "bitchbot/" .. gameName .. "/" .. name .. ".bb"
    if isfile(path) then
        delfile(path)
        Library.CreateNotification("Deleted config: " .. name)
        return true
    end
    return false
end

-- ============================================================
-- MENU CLASS
-- ============================================================
function Library.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Library)

    self.w          = opts.width or 520
    self.h          = opts.height or 620
    self.x          = math.floor((Camera.ViewportSize.X/2) - (self.w/2))
    self.y          = math.floor((Camera.ViewportSize.Y/2) - (self.h/2))
    self.open       = true
    self.fading     = false
    self.activetab  = 1
    self.mousedown  = false
    self.dragging   = false
    self.dragOffset = Vector2.new()
    self.mc         = opts.accent or {155, 155, 255}
    self.options    = {}
    self.values     = {}
    self.connections= {}
    self.postable   = {}
    self.tabnames   = {}
    self.tabs       = {}
    self.drawGroup  = {}
    self.unloaded   = false
    self.gameName   = opts.gameName or "Universal"
    self.menuName   = opts.menuName or "Bitch Bot"
    self.keybind    = opts.keybind or Enum.KeyCode.Delete
    self.username   = opts.username or "user"
    self.selectedPlayer = nil
    self.playerListVisual = nil

    self.columns = {
        width = math.floor((self.w - 40) / 2),
        left  = 17,
        right = math.floor((self.w - 20) / 2) + 13,
    }

    self.watermark = {
        text    = self.menuName .. " | " .. self.username .. " | " .. os.date("%b. %d, %Y"),
        pos     = Vector2.new(20, 10),
        visible = true,
        objects = {},
    }

    EnsureFolders(self.gameName)
    UnpackRelations()
    WriteRelations()

    self:BuildBase()
    self:CreateWatermark()
    self:SetupInput()

    return self
end

function Library:BuildBase()
    local g = self.drawGroup
    Draw:MenuOutlinedRect(self, true, 0, 0, self.w, self.h, {0,0,0,255}, g)
    Draw:MenuOutlinedRect(self, true, 1, 1, self.w-2, self.h-2, {20,20,20,255}, g)
    Draw:MenuOutlinedRect(self, true, 2, 2, self.w-3, 1, {self.mc[1], self.mc[2], self.mc[3], 255}, g)
    Draw:MenuOutlinedRect(self, true, 2, 3, self.w-3, 1, {
        math.max(0,self.mc[1]-68), math.max(0,self.mc[2]-123), math.max(0,self.mc[3]-132), 255
    }, g)
    Draw:MenuOutlinedRect(self, true, 2, 4, self.w-3, 1, {20,20,20,255}, g)
    for i = 0, 19 do
        local c = ColorRange(i, {{start=0, color=RGB(50,50,50)}, {start=20, color=RGB(35,35,35)}})
        Draw:MenuFilledRect(self, true, 2, 5+i, self.w-4, 1, {c.R*255, c.G*255, c.B*255, 255}, g)
    end
    Draw:MenuFilledRect(self, true, 2, 25, self.w-4, self.h-27, {35,35,35,255}, g)
    Draw:MenuBigText(self, self.menuName, true, false, 6, 6, g)
end

function Library:CreateWatermark()
    local wm = self.watermark
    local objs = {}
    local width = (#wm.text * 7) + 14
    local height = 20
    Draw:FilledRect(true, wm.pos.x, wm.pos.y+1, width, 2, {self.mc[1]-40, self.mc[2]-40, self.mc[3]-40, 255}, objs)
    Draw:FilledRect(true, wm.pos.x, wm.pos.y, width, 2, {self.mc[1], self.mc[2], self.mc[3], 255}, objs)
    for i = 0, height-4 do
        local c = 50 - i*1.7
        Draw:FilledRect(true, wm.pos.x, wm.pos.y+3+i, width, 1, {c, c, c, 255}, objs)
    end
    Draw:OutlinedRect(true, wm.pos.x, wm.pos.y, width, height, {0,0,0,255}, objs)
    Draw:OutlinedRect(true, wm.pos.x-1, wm.pos.y-1, width+2, height+2, {0,0,0,100}, objs)
    Draw:OutlinedText(wm.text, 2, true, wm.pos.x+6, wm.pos.y+3, 13, false, {255,255,255,255}, {0,0,0}, objs)
    wm.objects = objs
end

function Library:UpdateWatermarkVisibility()
    for _, o in pairs(self.watermark.objects) do
        o.Visible = self.watermark.visible and true
    end
end

function Library:SetupInput()
    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or self.unloaded then return end
        if input.KeyCode == self.keybind then
            self.open = not self.open
            for _, o in pairs(self.drawGroup) do
                if o.Visible ~= nil then o.Visible = self.open end
            end
            Library.CreateNotification(self.open and "Menu opened" or "Menu closed")
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.mousedown = true
            if self.open then
                local mx, my = Mouse.X, Mouse.Y
                if mx >= self.x and mx <= self.x+self.w and my >= self.y and my <= self.y+25 then
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
        self:UpdateWatermarkVisibility()
    end))
end

function Library:UpdatePositions()
    for _, e in ipairs(self.postable) do
        local obj, ox, oy = e[1], e[2], e[3]
        if obj and obj.Position then
            obj.Position = Vector2.new(self.x + ox, self.y + oy)
        end
    end
end

-- Value API
function Library:GetVal(tab, group, option, typ)
    local key = (tab or "") .. "/" .. (group or "") .. "/" .. (option or "")
    local v = self.values[key]
    if typ == COLOR and type(v) == "table" then
        return RGB(v[1], v[2], v[3])
    end
    return v
end

function Library:SetVal(tab, group, option, value)
    local key = (tab or "") .. "/" .. (group or "") .. "/" .. (option or "")
    self.values[key] = value
end

-- Relations API
function Library:IsFriend(name)   return table.find(Relations.friends, name) ~= nil end
function Library:IsPriority(name) return table.find(Relations.priority, name) ~= nil end

function Library:AddFriend(name)
    if not table.find(Relations.friends, name) then
        table.insert(Relations.friends, name)
        WriteRelations()
    end
end

function Library:RemoveFriend(name)
    local i = table.find(Relations.friends, name)
    if i then table.remove(Relations.friends, i) WriteRelations() end
end

function Library:AddPriority(name)
    if not table.find(Relations.priority, name) then
        table.insert(Relations.priority, name)
        WriteRelations()
    end
end

function Library:RemovePriority(name)
    local i = table.find(Relations.priority, name)
    if i then table.remove(Relations.priority, i) WriteRelations() end
end

function Library:GetFriends()  return Relations.friends end
function Library:GetPriority() return Relations.priority end

-- Config API
function Library:SaveConfig(name)   return SaveConfig(self, name or "Default", self.gameName) end
function Library:LoadConfig(name)   return LoadConfig(self, name or "Default", self.gameName) end
function Library:DeleteConfig(name) return DeleteConfig(name or "Default", self.gameName) end
function Library:GetConfigList()    return GetConfigs(self.gameName) end

-- ============================================================
-- INITIALIZE (original style)
-- ============================================================
function Library:Initialize(menutable)
    if type(menutable) ~= "table" then return end
    self.tabs = menutable
    self.tabnames = {}
    for i, tab in ipairs(menutable) do
        self.tabnames[i] = tab.name
    end

    -- Tab buttons
    local tabX = 6
    for i, tab in ipairs(menutable) do
        local btn = Draw:MenuBigText(self, tab.name, true, false, tabX, 28, self.drawGroup)
        btn.Color = (i == self.activetab) and RGB(255,255,255) or RGB(170,170,170)
        tabX = tabX + (btn.TextBounds and btn.TextBounds.X or 40) + 12
    end

    -- Active tab content
    local active = menutable[self.activetab]
    if not active or not active.content then return end

    local yLeft, yRight = 55, 55
    for _, group in ipairs(active.content) do
        local isLeft = (group.autopos == "left") or (group.x == self.columns.left)
        local gx = isLeft and self.columns.left or self.columns.right
        local gy = isLeft and yLeft or yRight
        local gw = group.width or self.columns.width
        local gh = group.height or 140

        local title = type(group.name) == "table" and group.name[1] or (group.name or "Group")
        Draw:CoolBox(self, title, gx, gy, gw, gh, self.drawGroup)

        local cy = gy + 28
        local content = group.content or (group[1] and group[1].content) or {}
        for _, ctrl in ipairs(content) do
            local gname = type(group.name) == "table" and group.name[1] or (group.name or "")
            local key = (active.name or "") .. "/" .. gname .. "/" .. (ctrl.name or "")

            local typ = ctrl.type
            if typ == TOGGLE or typ == "toggle" then
                self.values[key] = ctrl.value or false
                Draw:Toggle(self, ctrl.name or "Toggle", self.values[key], gx+8, cy, self.drawGroup)
                cy = cy + 20
            elseif typ == SLIDER or typ == "slider" then
                self.values[key] = ctrl.value or ctrl.minvalue or 0
                Draw:Slider(self, ctrl.name or "Slider", self.values[key],
                    ctrl.minvalue or 0, ctrl.maxvalue or 100, ctrl.stradd or "",
                    gx+8, cy, gw-20, self.drawGroup)
                cy = cy + 34
            elseif typ == DROPBOX or typ == "dropbox" then
                self.values[key] = ctrl.value or 1
                Draw:Dropbox(self, ctrl.name or "Dropbox", self.values[key],
                    ctrl.values or {"A","B"}, gx+8, cy, gw-20, self.drawGroup)
                cy = cy + 42
            elseif typ == BUTTON or typ == "button" then
                Draw:Button(self, ctrl.name or "Button", gx+8, cy, gw-20, self.drawGroup)
                cy = cy + 28
            elseif typ == TEXTBOX or typ == "textbox" then
                self.values[key] = ctrl.text or ""
                Draw:TextBox(self, self.values[key], gx+8, cy, gw-20, self.drawGroup)
                cy = cy + 28
            elseif typ == KEYBIND or typ == "keybind" then
                Draw:Keybind(self, ctrl.key, gx+8, cy, self.drawGroup)
                cy = cy + 22
            elseif typ == COLORPICKER or typ == "colorpicker" then
                local col = ctrl.color or {255,255,255}
                self.values[key] = col
                Draw:ColorPicker(self, col, gx+8, cy, self.drawGroup)
                cy = cy + 20
            end
        end

        if isLeft then yLeft = gy + gh + 8 else yRight = gy + gh + 8 end
    end

    Library.CreateNotification("Menu initialized (" .. #menutable .. " tabs)")
end

-- ============================================================
-- PLAYER LIST
-- ============================================================
function Library:BuildPlayerList(x, y, w, h)
    local g = self.drawGroup
    Draw:CoolBox(self, "Player List", x, y, w, h, g)
    local list = Draw:List(self, {"Name", "Team", "Status"}, x+6, y+22, w-12, 8, 3, g)
    self.playerListVisual = list
    Draw:Dropbox(self, "Status", 1, {"None", "Friend", "Priority"}, x+6, y+h-70, 160, g)
    Draw:Button(self, "Apply", x+180, y+h-55, 70, g)
    Draw:Button(self, "Spectate", x+260, y+h-55, 80, g)
    self:RefreshPlayerList()
end

function Library:RefreshPlayerList()
    if not self.playerListVisual then return end
    local words = self.playerListVisual.words
    local players = Players:GetPlayers()
    table.sort(players, function(a, b) return a.Name < b.Name end)

    for i = 1, 8 do
        local p = players[i]
        if p and words[i] then
            local status, scol = "None", RGB(255,255,255)
            if p == LocalPlayer then
                status, scol = "Local", RGB(66,135,245)
            elseif self:IsFriend(p.Name) then
                status, scol = "Friend", RGB(0,255,0)
            elseif self:IsPriority(p.Name) then
                status, scol = "Priority", RGB(255,210,0)
            end
            if words[i][1] then words[i][1].Text = p.Name end
            if words[i][2] then
                words[i][2].Text = p.Team and p.Team.Name or "None"
                if p.Team then words[i][2].Color = p.TeamColor.Color end
            end
            if words[i][3] then
                words[i][3].Text = status
                words[i][3].Color = scol
            end
        elseif words[i] then
            for c = 1, 3 do
                if words[i][c] then words[i][c].Text = "" end
            end
        end
    end
end

-- ============================================================
-- UNLOAD
-- ============================================================
function Library:Unload()
    self.unloaded = true
    Draw:UnRender()
    for _, c in pairs(self.connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(self.connections)
    Library.CreateNotification("UI unloaded")
end

return Library
