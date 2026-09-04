--[[
    BitchBot UI Library - Faithful Extraction
    FAITHFUL_UI_V2  (fixed addFill + mouse)
    If you still see addFill boolean errors, you are loading an OLD copy.
    Based on original source patterns:
    - MouseInMenu with -36 Y offset (critical for clicks)
    - SetMenuPos / postable dragging
    - Original tab slot bar
    - Original Draw control styles
    - Working toggles, sliders, dropdowns, keybinds, tabs
]]

local Library = {}
Library.__index = Library

Library.COLOR, Library.COLOR1, Library.COLOR2 = 1, 2, 3
Library.COMBOBOX, Library.TOGGLE, Library.KEYBIND = 4, 5, 6
Library.DROPBOX, Library.COLORPICKER, Library.DOUBLE_COLORPICKERS = 7, 8, 9
Library.SLIDER, Library.BUTTON, Library.LIST = 10, 11, 12
Library.IMAGE, Library.TEXTBOX = 13, 14

local COLOR, TOGGLE, KEYBIND, DROPBOX = 1, 5, 6, 7
local COLORPICKER, SLIDER, BUTTON, TEXTBOX = 8, 10, 11, 14

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LOCAL_PLAYER = Players.LocalPlayer
local LOCAL_MOUSE = LOCAL_PLAYER:GetMouse()
local Camera = workspace.CurrentCamera

local function RGB(r,g,b) return Color3.fromRGB(math.clamp(r or 0,0,255), math.clamp(g or 0,0,255), math.clamp(b or 0,0,255)) end
local function clamp(a, lo, hi)
    if a > hi then return hi elseif a < lo then return lo else return a end
end
local function ColorRange(value, ranges)
    if value <= ranges[1].start then return ranges[1].color end
    if value >= ranges[#ranges].start then return ranges[#ranges].color end
    local selected = #ranges
    for i = 1, #ranges-1 do if value < ranges[i+1].start then selected = i break end end
    local minC, maxC = ranges[selected], ranges[selected+1]
    local lerpAmt = (value - minC.start) / (maxC.start - minC.start)
    return Color3.new(
        minC.color.R + (maxC.color.R - minC.color.R) * lerpAmt,
        minC.color.G + (maxC.color.G - minC.color.G) * lerpAmt,
        minC.color.B + (maxC.color.B - minC.color.B) * lerpAmt
    )
end

local keyNames = {
    LeftShift="LShift", RightShift="RShift", LeftControl="LCtrl", RightControl="RCtrl",
    LeftAlt="LAlt", RightAlt="RAlt", Backspace="Back", Return="Enter",
    One="1", Two="2", Three="3", Four="4", Five="5", Six="6", Seven="7", Eight="8", Nine="9", Zero="0",
    MouseButton1="MB1", MouseButton2="MB2", MouseButton3="MB3",
}
local function KeyEnumToName(key)
    if key == nil then return "None" end
    local s = tostring(key) .. "."
    s = s:gsub("%.", ",")
    local keyname, looptime = nil, 0
    for w in s:gmatch("(.-),") do
        looptime = looptime + 1
        if looptime == 3 then keyname = w end
    end
    if not keyname then return "None" end
    if string.match(keyname, "Keypad") then keyname = string.gsub(keyname, "Keypad", "") end
    if keyname == "Unknown" then return "None" end
    return keyNames[keyname] or keyname
end

-- ============================================================
-- DRAW (faithful to original)
-- ============================================================
local Draw = {}
local allrender = {}

function Draw:UnRender()
    for _, group in pairs(allrender) do
        for _, obj in pairs(group) do
            if obj and type(obj) ~= "number" and obj.__OBJECT_EXISTS then
                pcall(function() obj:Remove() end)
            end
        end
    end
    table.clear(allrender)
end

local function track(t)
    if not table.find(allrender, t) then table.insert(allrender, t) end
end

function Draw:OutlinedRect(visible, pos_x, pos_y, width, height, clr, tablename)
    local o = Drawing.new("Square")
    o.Visible = visible
    o.Position = Vector2.new(pos_x, pos_y)
    o.Size = Vector2.new(width, height)
    o.Color = RGB(clr[1], clr[2], clr[3])
    o.Filled = false
    o.Thickness = 1
    o.Transparency = (clr[4] or 255) / 255
    table.insert(tablename, o)
    track(tablename)
end

function Draw:FilledRect(visible, pos_x, pos_y, width, height, clr, tablename)
    local o = Drawing.new("Square")
    o.Visible = visible
    o.Position = Vector2.new(pos_x, pos_y)
    o.Size = Vector2.new(width, height)
    o.Color = RGB(clr[1], clr[2], clr[3])
    o.Filled = true
    o.Thickness = 0
    o.Transparency = (clr[4] or 255) / 255
    table.insert(tablename, o)
    track(tablename)
end

function Draw:OutlinedText(text, font, visible, pos_x, pos_y, size, centered, clr, clr2, tablename)
    local o = Drawing.new("Text")
    o.Text = tostring(text)
    o.Visible = visible
    o.Position = Vector2.new(pos_x, pos_y)
    o.Size = size or 13
    o.Center = centered or false
    o.Color = RGB(clr[1], clr[2], clr[3])
    o.Transparency = (clr[4] or 255) / 255
    o.Outline = true
    o.OutlineColor = RGB(clr2[1] or 0, clr2[2] or 0, clr2[3] or 0)
    o.Font = font or 2
    table.insert(tablename, o)
    track(tablename)
    return o
end

function Draw:MenuOutlinedRect(menu, visible, pos_x, pos_y, width, height, clr, tablename)
    Draw:OutlinedRect(visible, pos_x + menu.x, pos_y + menu.y, width, height, clr, tablename)
    table.insert(menu.postable, {tablename[#tablename], pos_x, pos_y})
end

function Draw:MenuFilledRect(menu, visible, pos_x, pos_y, width, height, clr, tablename)
    Draw:FilledRect(visible, pos_x + menu.x, pos_y + menu.y, width, height, clr, tablename)
    table.insert(menu.postable, {tablename[#tablename], pos_x, pos_y})
end

function Draw:MenuBigText(menu, text, visible, centered, pos_x, pos_y, tablename)
    local t = Draw:OutlinedText(text, 2, visible, pos_x + menu.x, pos_y + menu.y, 13, centered, {255,255,255,255}, {0,0,0}, tablename)
    table.insert(menu.postable, {tablename[#tablename], pos_x, pos_y})
    return t
end

function Draw:CoolBox(menu, name, x, y, width, height, tab)
    Draw:MenuOutlinedRect(menu, true, x, y, width, height, {0,0,0,255}, tab)
    Draw:MenuOutlinedRect(menu, true, x+1, y+1, width-2, height-2, {20,20,20,255}, tab)
    Draw:MenuOutlinedRect(menu, true, x+2, y+2, width-3, 1, {menu.mc[1], menu.mc[2], menu.mc[3], 255}, tab)
    table.insert(menu.clrs.norm, tab[#tab])
    Draw:MenuOutlinedRect(menu, true, x+2, y+3, width-3, 1, {math.max(0,menu.mc[1]-68), math.max(0,menu.mc[2]-123), math.max(0,menu.mc[3]-132), 255}, tab)
    table.insert(menu.clrs.dark, tab[#tab])
    Draw:MenuOutlinedRect(menu, true, x+2, y+4, width-3, 1, {20,20,20,255}, tab)
    for i = 0, 7 do
        Draw:MenuFilledRect(menu, true, x+2, y+5+(i*2), width-4, 2, {45,45,45,255}, tab)
        tab[#tab].Color = ColorRange(i, {
            {start=0, color=RGB(45,45,45)},
            {start=7, color=RGB(35,35,35)},
        })
    end
    Draw:MenuBigText(menu, name, true, false, x+6, y+5, tab)
end

function Draw:Toggle(menu, name, value, x, y, tab)
    Draw:MenuOutlinedRect(menu, true, x, y, 12, 12, {30,30,30,255}, tab)
    Draw:MenuOutlinedRect(menu, true, x+1, y+1, 10, 10, {0,0,0,255}, tab)
    local boxes = {}
    for i = 0, 3 do
        Draw:MenuFilledRect(menu, true, x+2, y+2+(i*2), 8, 2, {0,0,0,255}, tab)
        table.insert(boxes, tab[#tab])
        if value then
            tab[#tab].Color = ColorRange(i, {
                {start=0, color=RGB(menu.mc[1], menu.mc[2], menu.mc[3])},
                {start=3, color=RGB(menu.mc[1]-40, menu.mc[2]-40, menu.mc[3]-40)},
            })
        else
            tab[#tab].Color = ColorRange(i, {
                {start=0, color=RGB(50,50,50)},
                {start=3, color=RGB(30,30,30)},
            })
        end
    end
    Draw:MenuBigText(menu, name, true, false, x+16, y-1, tab)
    return boxes
end

function Draw:Keybind(menu, key, x, y, tab)
    local t = {}
    Draw:MenuFilledRect(menu, true, x, y, 44, 16, {25,25,25,255}, tab)
    Draw:MenuBigText(menu, KeyEnumToName(key), true, true, x+22, y+1, tab)
    table.insert(t, tab[#tab])
    Draw:MenuOutlinedRect(menu, true, x, y, 44, 16, {30,30,30,255}, tab)
    table.insert(t, tab[#tab])
    Draw:MenuOutlinedRect(menu, true, x+1, y+1, 42, 14, {0,0,0,255}, tab)
    return t
end

function Draw:Slider(menu, name, stradd, value, minvalue, maxvalue, x, y, length, tab)
    Draw:MenuBigText(menu, name, true, false, x, y-3, tab)
    for i = 0, 3 do
        Draw:MenuFilledRect(menu, true, x+2, y+14+(i*2), length-4, 2, {0,0,0,255}, tab)
        tab[#tab].Color = ColorRange(i, {
            {start=0, color=RGB(50,50,50)},
            {start=3, color=RGB(30,30,30)},
        })
    end
    local fill = {}
    local pct = clamp((value - minvalue) / math.max(maxvalue - minvalue, 1), 0, 1)
    for i = 0, 3 do
        Draw:MenuFilledRect(menu, true, x+2, y+14+(i*2), (length-4)*pct, 2, {0,0,0,255}, tab)
        tab[#tab].Color = ColorRange(i, {
            {start=0, color=RGB(menu.mc[1], menu.mc[2], menu.mc[3])},
            {start=3, color=RGB(menu.mc[1]-40, menu.mc[2]-40, menu.mc[3]-40)},
        })
        table.insert(fill, tab[#tab])
    end
    Draw:MenuOutlinedRect(menu, true, x, y+12, length, 12, {30,30,30,255}, tab)
    Draw:MenuOutlinedRect(menu, true, x+1, y+13, length-2, 10, {0,0,0,255}, tab)
    local label = Draw:MenuBigText(menu, tostring(value)..(stradd or ""), true, true, x + length*0.5, y+11, tab)
    return {fill = fill, label = label}
end

function Draw:Dropbox(menu, name, value, values, x, y, length, tab)
    local t = {}
    Draw:MenuBigText(menu, name, true, false, x, y-3, tab)
    for i = 0, 7 do
        Draw:MenuFilledRect(menu, true, x+2, y+14+(i*2), length-4, 2, {0,0,0,255}, tab)
        tab[#tab].Color = ColorRange(i, {
            {start=0, color=RGB(50,50,50)},
            {start=7, color=RGB(35,35,35)},
        })
    end
    Draw:MenuOutlinedRect(menu, true, x, y+12, length, 22, {30,30,30,255}, tab)
    Draw:MenuOutlinedRect(menu, true, x+1, y+13, length-2, 20, {0,0,0,255}, tab)
    Draw:MenuBigText(menu, tostring(values[value] or "?"), true, false, x+6, y+16, tab)
    table.insert(t, tab[#tab])
    Draw:MenuBigText(menu, "-", true, false, x-17+length, y+16, tab)
    table.insert(t, tab[#tab])
    return t
end

function Draw:Button(menu, name, x, y, length, tab)
    local t = {}
    for i = 0, 8 do
        Draw:MenuFilledRect(menu, true, x+2, y+2+(i*2), length-4, 2, {0,0,0,255}, tab)
        tab[#tab].Color = ColorRange(i, {
            {start=0, color=RGB(50,50,50)},
            {start=8, color=RGB(35,35,35)},
        })
        table.insert(t, tab[#tab])
    end
    Draw:MenuOutlinedRect(menu, true, x, y, length, 22, {30,30,30,255}, tab)
    Draw:MenuOutlinedRect(menu, true, x+1, y+1, length-2, 20, {0,0,0,255}, tab)
    Draw:MenuBigText(menu, name, true, true, x + math.floor(length*0.5), y+4, tab)
    return t
end

Library.Draw = Draw
Library.KeyEnumToName = KeyEnumToName

-- ============================================================
-- NOTIFICATIONS (simplified original)
-- ============================================================
local notes = {}
local function map(n,a,b,c,d) return (n-a)/(b-a)*(d-c)+c end
local function CObj(typ,col) local d=Drawing.new(typ); d.Visible=true; d.Transparency=1; d.Color=col; return d end
local function CRect(w,h,f,col) local s=CObj("Square",col); s.Filled=f; s.Thickness=1; s.Position=Vector2.new(); s.Size=Vector2.new(w,h); return s end
local function CText(t) local s=CObj("Text",Color3.new(1,1,1)); s.Text=t; s.Size=13; s.Center=false; s.Outline=true; s.Position=Vector2.new(); s.Font=2; return s end

function Library.CreateNotification(text)
    local gap, width, alpha, time, estep, eestep, insety = 25, 18, 255, 0, 0, 0.02, 0
    local Note = {
        enabled=true, targetPos=Vector2.new(50,33), size=Vector2.new(200,width),
        drawings={outline=CRect(202,width+2,false,Color3.new(0,0,0)), fade=CRect(202,width+2,false,Color3.new(0,0,0))},
        Remove=function(self) for _,d in pairs(self.drawings) do if d and d.Remove then pcall(function() d:Remove() end) end end; self.enabled=false end,
        Update=function(self,num,len,dt)
            local pos=self.targetPos; local idx=(len-num)*gap
            if insety<idx then insety=insety-(insety-idx)*0.2 else insety=idx end
            local tpos=Vector2.new(pos.x-self.size.x/math.max(time,0.01)-map(alpha,0,255,self.size.x,0), pos.y+insety)
            self.pos=tpos
            local lr={x=math.ceil(tpos.x),y=math.ceil(tpos.y),w=math.floor(self.size.x-map(255-alpha,0,255,0,70)),h=self.size.y}
            local fade=math.clamp(math.min(time*12,alpha),0,255)
            if self.enabled then
                local ln=1
                for i,d in pairs(self.drawings) do
                    d.Transparency=fade/255
                    if type(i)=="number" then d.Position=Vector2.new(lr.x+1,lr.y+i); d.Size=Vector2.new(lr.w-2,1)
                    elseif i=="text" then d.Position=tpos+Vector2.new(6,2)
                    elseif i=="outline" then d.Position=Vector2.new(lr.x,lr.y); d.Size=Vector2.new(lr.w,lr.h)
                    elseif i=="fade" then d.Position=Vector2.new(lr.x-1,lr.y-1); d.Size=Vector2.new(lr.w+2,lr.h+2); d.Transparency=math.max((200-fade)/255/3,0.4)
                    elseif tostring(i):find("line") then d.Position=Vector2.new(lr.x+ln,lr.y+1); ln+=1 end
                end
                time+=estep*dt*128; estep+=eestep*dt*64
            end
        end,
        Fade=function(self,num,len,dt)
            if self.pos and (self.pos.x>self.targetPos.x-0.2*len or self.fading) then
                if not self.fading then estep=0 end
                self.fading=true; alpha-=estep/4*len*dt*50; eestep+=0.01*dt*100
            end
            if alpha<=0 then self:Remove() end
        end,
    }
    for i=1,Note.size.y-2 do local c=0.28-i/80; Note.drawings[i]=CRect(200,1,true,Color3.new(c,c,c)) end
    Note.drawings.text=CText(text)
    if Note.drawings.text.TextBounds and Note.drawings.text.TextBounds.X+7>Note.size.x then
        Note.size=Vector2.new(Note.drawings.text.TextBounds.X+7, Note.size.y)
    end
    local accent=Color3.fromRGB(100,100,225)
    Note.drawings.line=CRect(1,Note.size.y-2,true,accent)
    Note.drawings.line1=CRect(1,Note.size.y-2,true,accent)
    table.insert(notes, Note)
end

RunService.RenderStepped:Connect(function(dt)
    for k=#notes,1,-1 do if not(notes[k] and notes[k].enabled) then table.remove(notes,k) end end
    local len=#notes
    for k=1,len do
        local n=notes[k]
        if n then n:Update(k,len,dt); if k<=math.ceil(len/10) or n.fading then n:Fade(k,len,dt) end end
    end
end)

-- ============================================================
-- MENU (faithful core)
-- ============================================================
function Library.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Library)

    local menuWidth = opts.width or 500
    local menuHeight = opts.height or 600
    local SCREEN = Camera.ViewportSize

    self.w = menuWidth
    self.h = menuHeight
    self.x = math.floor((SCREEN.X/2) - (menuWidth/2))
    self.y = math.floor((SCREEN.Y/2) - (menuHeight/2))
    self.columns = {
        width = math.floor((menuWidth - 40) / 2),
        left = 17,
        right = math.floor((menuWidth - 20) / 2) + 13,
    }
    self.activetab = 1
    self.open = true
    self.fading = false
    self.mousedown = false
    self.postable = {}
    self.options = {}
    self.clrs = {norm={}, dark={}, togz={}}
    self.mc = opts.accent or {155, 155, 255}
    self.connections = {}
    self.tabnames = {}
    self.keybinds = {}
    self.unloaded = false
    self.menuName = opts.menuName or "Bitch Bot"
    self.keybind = opts.keybind or Enum.KeyCode.RightShift
    self.gameName = opts.gameName or "Universal"
    self.username = opts.username or "dev"
    self.bbmenu = {}
    self.tabz = {}
    self.tabs = {}
    self.tabButtons = {}
    self.controls = {}
    self.openDropdown = nil
    self.activeSlider = nil
    self.dragging = false
    self.dragOffset = Vector2.new()
    self.mouseOffsetX = opts.mouseOffsetX or 0
    self.mouseOffsetY = opts.mouseOffsetY or 0
    self.playerListVisual = nil
    self.playerListMaxRows = 6
    self.watermark = {
        text = self.menuName.." | "..self.username.." | "..os.date("%b. %d, %Y"),
        pos = Vector2.new(20, 10),
        visible = true,
        objects = {},
    }

    self:BuildChrome()
    self:CreateWatermark()
    self:SetupInput()
    return self
end

-- Mouse position for Drawing API
-- Some executors need GuiInset subtracted; others don't.
-- self.mouseOffsetY can be tuned if clicks are still high/low.
local GuiService = game:GetService("GuiService")
local function getMouse(menu)
    local p = UserInputService:GetMouseLocation()
    local inset = GuiService:GetGuiInset()
    -- Drawing objects use top-left of viewport; GetMouseLocation is absolute.
    -- Subtract inset so Y lines up with Drawing on most executors.
    local ox = (menu and menu.mouseOffsetX) or 0
    local oy = (menu and menu.mouseOffsetY) or 0
    return p.X - inset.X + ox, p.Y - inset.Y + oy
end

function Library:MouseInMenu(x, y, width, height)
    local mx, my = getMouse(self)
    return mx > self.x + x
        and mx < self.x + x + width
        and my > self.y + y
        and my < self.y + y + height
end

function Library:MouseInArea(x, y, width, height)
    local mx, my = getMouse(self)
    return mx > x and mx < x + width and my > y and my < y + height
end

function Library:SetMenuPos(x, y)
    self.x = x
    self.y = y
    for _, v in pairs(self.postable) do
        if v[1] and v[1].Visible then
            v[1].Position = Vector2.new(x + v[2], y + v[3])
        end
    end
end

function Library:BuildChrome()
    local bbmenu = self.bbmenu
    -- Outer frame (original style)
    Draw:MenuOutlinedRect(self, true, 0, 0, self.w, self.h, {0,0,0,255}, bbmenu)
    Draw:MenuOutlinedRect(self, true, 1, 1, self.w-2, self.h-2, {20,20,20,255}, bbmenu)
    Draw:MenuOutlinedRect(self, true, 2, 2, self.w-3, 1, {self.mc[1], self.mc[2], self.mc[3], 255}, bbmenu)
    table.insert(self.clrs.norm, bbmenu[#bbmenu])
    Draw:MenuOutlinedRect(self, true, 2, 3, self.w-3, 1, {math.max(0,self.mc[1]-68), math.max(0,self.mc[2]-123), math.max(0,self.mc[3]-132), 255}, bbmenu)
    table.insert(self.clrs.dark, bbmenu[#bbmenu])
    Draw:MenuOutlinedRect(self, true, 2, 4, self.w-3, 1, {20,20,20,255}, bbmenu)
    for i = 0, 19 do
        Draw:MenuFilledRect(self, true, 2, 5+i, self.w-4, 1, {20,20,20,255}, bbmenu)
        bbmenu[#bbmenu].Color = ColorRange(i, {
            {start=0, color=RGB(50,50,50)},
            {start=20, color=RGB(35,35,35)},
        })
    end
    Draw:MenuFilledRect(self, true, 2, 25, self.w-4, self.h-27, {35,35,35,255}, bbmenu)
    Draw:MenuBigText(self, self.menuName, true, false, 6, 6, bbmenu)

    -- Inner content frame
    Draw:MenuOutlinedRect(self, true, 8, 22, self.w-16, self.h-30, {0,0,0,255}, bbmenu)
    Draw:MenuOutlinedRect(self, true, 9, 23, self.w-18, self.h-32, {20,20,20,255}, bbmenu)
    Draw:MenuOutlinedRect(self, true, 10, 24, self.w-19, 1, {self.mc[1], self.mc[2], self.mc[3], 255}, bbmenu)
    table.insert(self.clrs.norm, bbmenu[#bbmenu])
    Draw:MenuOutlinedRect(self, true, 10, 25, self.w-19, 1, {math.max(0,self.mc[1]-68), math.max(0,self.mc[2]-123), math.max(0,self.mc[3]-132), 255}, bbmenu)
    table.insert(self.clrs.dark, bbmenu[#bbmenu])
    Draw:MenuOutlinedRect(self, true, 10, 26, self.w-19, 1, {20,20,20,255}, bbmenu)
    for i = 0, 14 do
        Draw:MenuFilledRect(self, true, 10, 27+(i*2), self.w-20, 2, {45,45,45,255}, bbmenu)
        bbmenu[#bbmenu].Color = ColorRange(i, {
            {start=0, color=RGB(50,50,50)},
            {start=15, color=RGB(35,35,35)},
        })
    end
    Draw:MenuFilledRect(self, true, 10, 57, self.w-20, self.h-67, {35,35,35,255}, bbmenu)
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
        Draw:FilledRect(true, wm.pos.x, wm.pos.y+3+i, width, 1, {c,c,c,255}, objs)
    end
    Draw:OutlinedRect(true, wm.pos.x, wm.pos.y, width, height, {0,0,0,255}, objs)
    Draw:OutlinedRect(true, wm.pos.x-1, wm.pos.y-1, width+2, height+2, {0,0,0,100}, objs)
    Draw:OutlinedText(wm.text, 2, true, wm.pos.x+6, wm.pos.y+3, 13, false, {255,255,255,255}, {0,0,0}, objs)
    wm.objects = objs
end

function Library:UpdateToggleVisual(opt)
    local boxes = opt.boxes
    if not boxes then return end
    for i, box in ipairs(boxes) do
        if opt.value then
            box.Color = ColorRange(i-1, {
                {start=0, color=RGB(self.mc[1], self.mc[2], self.mc[3])},
                {start=3, color=RGB(self.mc[1]-40, self.mc[2]-40, self.mc[3]-40)},
            })
        else
            box.Color = ColorRange(i-1, {
                {start=0, color=RGB(50,50,50)},
                {start=3, color=RGB(30,30,30)},
            })
        end
    end
end

function Library:UpdateSliderVisual(opt)
    local pct = clamp((opt.value - opt.min) / math.max(opt.max - opt.min, 1), 0, 1)
    if opt.fill then
        for _, r in ipairs(opt.fill) do
            r.Size = Vector2.new((opt.length - 4) * pct, 2)
        end
    end
    if opt.label then
        opt.label.Text = tostring(math.floor(opt.value + 0.5)) .. (opt.stradd or "")
    end
end

function Library:Initialize(menutable)
    if type(menutable) ~= "table" then return end
    self.menutable = menutable
    self.options = {}
    self.controls = {}
    self.tabButtons = {}
    self.tabz = {}
    self.tabnames = {}

    local n = #menutable
    local tabW = (self.w - 20) / n

    -- Original full-width slot tabs
    for k, v in ipairs(menutable) do
        self.tabnames[k] = v.name
        self.tabz[k] = {}
        self.options[v.name] = {}

        local tx = 10 + ((k-1) * tabW)
        Draw:MenuFilledRect(self, true, tx, 27, tabW, 32, {30,30,30,255}, self.bbmenu)
        Draw:MenuOutlinedRect(self, true, tx, 27, tabW, 32, {0,0,0,255}, self.bbmenu)
        local label = Draw:MenuBigText(self, v.name, true, true, math.floor(tx + tabW*0.5), 35, self.bbmenu)
        label.Color = (k == self.activetab) and RGB(255,255,255) or RGB(170,170,170)

        table.insert(self.tabButtons, {
            index = k,
            x = tx, y = 27, w = tabW, h = 32,
            label = label,
        })
    end

    -- Active tab indicator bar (original barguy style)
    Draw:MenuOutlinedRect(self, true, 10, 59, self.w-20, self.h-69, {20,20,20,255}, self.bbmenu)
    Draw:MenuOutlinedRect(self, true, 11, 58, tabW-2, 2, {35,35,35,255}, self.bbmenu)
    self.tabBar = {obj = self.bbmenu[#self.bbmenu], post = self.postable[#self.postable]}

    -- Build content for each tab
    for tabIdx, tab in ipairs(menutable) do
        local visible = (tabIdx == self.activetab)
        local contentGroup = self.tabz[tabIdx]
        if tab.content then
            local yLeft, yRight = 68, 68
            for _, group in ipairs(tab.content) do
                local isLeft = (group.autopos == "left") or (group.x == self.columns.left)
                local gx = group.x or (isLeft and self.columns.left or self.columns.right)
                local gy = group.y or (isLeft and yLeft or yRight)
                local gw = group.width or self.columns.width
                local gh = group.height or 140
                local gname = type(group.name) == "table" and group.name[1] or (group.name or "Group")
                local title = type(group.name) == "table" and table.concat(group.name, "  ") or gname

                self.options[tab.name][gname] = self.options[tab.name][gname] or {}

                -- Draw into tab group with visibility
                local function addOutline(vx,vy,vw,vh,col)
                    Draw:OutlinedRect(visible, vx+self.x, vy+self.y, vw, vh, col, contentGroup)
                    table.insert(self.postable, {contentGroup[#contentGroup], vx, vy})
                end
                local function addFill(a,b,c,d,e,f)
                    local vx,vy,vw,vh,col
                    if type(a) == "boolean" then
                        -- legacy (visible, x, y, w, h, col)
                        vx,vy,vw,vh,col = b,c,d,e,f
                    else
                        vx,vy,vw,vh,col = a,b,c,d,e
                    end
                    if type(vx) ~= "number" or type(col) ~= "table" then return end
                    Draw:FilledRect(visible, vx+self.x, vy+self.y, vw, vh, col, contentGroup)
                    table.insert(self.postable, {contentGroup[#contentGroup], vx, vy})
                end
                local function addText(txt, center, vx, vy)
                    local o = Draw:OutlinedText(txt, 2, visible, vx+self.x, vy+self.y, 13, center, {255,255,255,255}, {0,0,0}, contentGroup)
                    table.insert(self.postable, {contentGroup[#contentGroup], vx, vy})
                    return o
                end

                -- CoolBox
                addOutline(gx, gy, gw, gh, {0,0,0,255})
                addOutline(gx+1, gy+1, gw-2, gh-2, {20,20,20,255})
                addOutline(gx+2, gy+2, gw-3, 1, {self.mc[1], self.mc[2], self.mc[3], 255})
                addOutline(gx+2, gy+3, gw-3, 1, {math.max(0,self.mc[1]-68), math.max(0,self.mc[2]-123), math.max(0,self.mc[3]-132), 255})
                addOutline(gx+2, gy+4, gw-3, 1, {20,20,20,255})
                for i=0,7 do
                    addFill(gx+2, gy+5+i*2, gw-4, 2, {45,45,45,255})
                    contentGroup[#contentGroup].Color = ColorRange(i, {{start=0,color=RGB(45,45,45)},{start=7,color=RGB(35,35,35)}})
                end
                addText(title, false, gx+6, gy+5)

                local cy = gy + 28
                for _, ctrl in ipairs(group.content or {}) do
                    local cname = ctrl.name or "Option"
                    local typ = ctrl.type
                    local opt = {}

                    if typ == TOGGLE or typ == "toggle" then
                        opt.value = ctrl.value or false
                        opt.type = TOGGLE
                        -- hitbox relative to menu
                        opt.hx, opt.hy, opt.hw, opt.hh = gx+8, cy, 120, 14
                        addOutline(gx+8, cy, 12, 12, {30,30,30,255})
                        addOutline(gx+9, cy+1, 10, 10, {0,0,0,255})
                        local boxes = {}
                        for i=0,3 do
                            addFill(gx+10, cy+2+i*2, 8, 2, {0,0,0,255})
                            table.insert(boxes, contentGroup[#contentGroup])
                            if opt.value then
                                contentGroup[#contentGroup].Color = ColorRange(i, {
                                    {start=0, color=RGB(self.mc[1],self.mc[2],self.mc[3])},
                                    {start=3, color=RGB(self.mc[1]-40,self.mc[2]-40,self.mc[3]-40)},
                                })
                            else
                                contentGroup[#contentGroup].Color = ColorRange(i, {
                                    {start=0, color=RGB(50,50,50)},
                                    {start=3, color=RGB(30,30,30)},
                                })
                            end
                        end
                        addText(cname, false, gx+24, cy-1)
                        opt.boxes = boxes
                        -- optional keybind next to toggle
                        if ctrl.keybind then
                            local kb = ctrl.keybind
                            opt.keybind = kb
                            opt.keybindVisual = true
                            -- small keybind box on the right
                            local kx = gx + gw - 52
                            addFill(kx, cy-1, 44, 16, {25,25,25,255})
                            local ktxt = addText(KeyEnumToName(kb), true, kx+22, cy+1)
                            addOutline(kx, cy-1, 44, 16, {30,30,30,255})
                            addOutline(kx+1, cy, 42, 14, {0,0,0,255})
                            opt.keybindText = ktxt
                            opt.keybindX, opt.keybindY = kx, cy-1
                        end
                        self.options[tab.name][gname][cname] = opt
                        table.insert(self.controls, {tab=tabIdx, tabName=tab.name, group=gname, name=cname, opt=opt})
                        cy = cy + 18

                    elseif typ == SLIDER or typ == "slider" then
                        local val = ctrl.value or ctrl.minvalue or 0
                        local minv = ctrl.minvalue or 0
                        local maxv = ctrl.maxvalue or 100
                        local stradd = ctrl.stradd or ""
                        local length = gw - 20
                        opt.value, opt.min, opt.max, opt.stradd, opt.length = val, minv, maxv, stradd, length
                        opt.type = SLIDER
                        opt.hx, opt.hy, opt.hw, opt.hh = gx+8, cy+12, length, 12
                        addText(cname, false, gx+8, cy-3)
                        for i=0,3 do
                            addFill(gx+10, cy+14+i*2, length-4, 2, {0,0,0,255})
                            contentGroup[#contentGroup].Color = ColorRange(i, {{start=0,color=RGB(50,50,50)},{start=3,color=RGB(30,30,30)}})
                        end
                        local fill = {}
                        local pct = clamp((val-minv)/math.max(maxv-minv,1),0,1)
                        for i=0,3 do
                            addFill(gx+10, cy+14+i*2, (length-4)*pct, 2, {0,0,0,255})
                            contentGroup[#contentGroup].Color = ColorRange(i, {
                                {start=0, color=RGB(self.mc[1],self.mc[2],self.mc[3])},
                                {start=3, color=RGB(self.mc[1]-40,self.mc[2]-40,self.mc[3]-40)},
                            })
                            table.insert(fill, contentGroup[#contentGroup])
                        end
                        addOutline(gx+8, cy+12, length, 12, {30,30,30,255})
                        addOutline(gx+9, cy+13, length-2, 10, {0,0,0,255})
                        local label = addText(tostring(val)..stradd, true, gx+8+length*0.5, cy+11)
                        opt.fill, opt.label = fill, label
                        self.options[tab.name][gname][cname] = opt
                        table.insert(self.controls, {tab=tabIdx, tabName=tab.name, group=gname, name=cname, opt=opt})
                        cy = cy + 34

                    elseif typ == DROPBOX or typ == "dropbox" then
                        local val = ctrl.value or 1
                        local values = ctrl.values or {"A","B"}
                        local length = gw - 20
                        opt.value, opt.values, opt.length = val, values, length
                        opt.type = DROPBOX
                        opt.hx, opt.hy, opt.hw, opt.hh = gx+8, cy+12, length, 22
                        opt.open = false
                        addText(cname, false, gx+8, cy-3)
                        for i=0,7 do
                            addFill(gx+10, cy+14+i*2, length-4, 2, {0,0,0,255})
                            contentGroup[#contentGroup].Color = ColorRange(i, {{start=0,color=RGB(50,50,50)},{start=7,color=RGB(35,35,35)}})
                        end
                        addOutline(gx+8, cy+12, length, 22, {30,30,30,255})
                        addOutline(gx+9, cy+13, length-2, 20, {0,0,0,255})
                        local txt = addText(tostring(values[val] or "?"), false, gx+14, cy+16)
                        addText("-", false, gx+8+length-17, cy+16)
                        opt.text = txt
                        -- dropdown items (hidden)
                        opt.items = {}
                        for i, vname in ipairs(values) do
                            local iy = cy + 34 + (i-1)*18
                            -- create hidden (start Visible=false after insert)
                            addFill(gx+8, iy, length, 18, {25,25,25,255})
                            local bg = contentGroup[#contentGroup]
                            bg.Visible = false
                            local it = addText(tostring(vname), false, gx+14, iy+2)
                            it.Visible = false
                            table.insert(opt.items, {bg=bg, text=it, x=gx+8, y=iy, w=length, h=18, value=i})
                        end
                        self.options[tab.name][gname][cname] = opt
                        table.insert(self.controls, {tab=tabIdx, tabName=tab.name, group=gname, name=cname, opt=opt})
                        cy = cy + 42

                    elseif typ == BUTTON or typ == "button" then
                        local length = gw - 20
                        opt.type = BUTTON
                        opt.hx, opt.hy, opt.hw, opt.hh = gx+8, cy, length, 22
                        opt.callback = ctrl.callback
                        for i=0,8 do
                            addFill(gx+10, cy+2+i*2, length-4, 2, {0,0,0,255})
                            contentGroup[#contentGroup].Color = ColorRange(i, {{start=0,color=RGB(50,50,50)},{start=8,color=RGB(35,35,35)}})
                        end
                        addOutline(gx+8, cy, length, 22, {30,30,30,255})
                        addOutline(gx+9, cy+1, length-2, 20, {0,0,0,255})
                        addText(cname, true, gx+8+math.floor(length*0.5), cy+4)
                        self.options[tab.name][gname][cname] = opt
                        table.insert(self.controls, {tab=tabIdx, tabName=tab.name, group=gname, name=cname, opt=opt})
                        cy = cy + 28

                    elseif typ == TEXTBOX or typ == "textbox" then
                        local length = gw - 20
                        opt.value = ctrl.text or ""
                        opt.type = TEXTBOX
                        opt.hx, opt.hy, opt.hw, opt.hh = gx+8, cy, length, 22
                        for i=0,8 do
                            addFill(gx+10, cy+2+i*2, length-4, 2, {0,0,0,255})
                            contentGroup[#contentGroup].Color = ColorRange(i, {{start=0,color=RGB(50,50,50)},{start=8,color=RGB(35,35,35)}})
                        end
                        addOutline(gx+8, cy, length, 22, {30,30,30,255})
                        addOutline(gx+9, cy+1, length-2, 20, {0,0,0,255})
                        local txt = addText(opt.value, false, gx+14, cy+4)
                        opt.text = txt
                        self.options[tab.name][gname][cname] = opt
                        table.insert(self.controls, {tab=tabIdx, tabName=tab.name, group=gname, name=cname, opt=opt})
                        cy = cy + 28

                    elseif typ == KEYBIND or typ == "keybind" then
                        opt.value = ctrl.key or Enum.KeyCode.Unknown
                        opt.type = KEYBIND
                        opt.hx, opt.hy, opt.hw, opt.hh = gx+8, cy, 44, 16
                        addFill(gx+8, cy, 44, 16, {25,25,25,255})
                        local ktxt = addText(KeyEnumToName(opt.value), true, gx+30, cy+1)
                        addOutline(gx+8, cy, 44, 16, {30,30,30,255})
                        addOutline(gx+9, cy+1, 42, 14, {0,0,0,255})
                        opt.text = ktxt
                        addText(cname, false, gx+56, cy)
                        self.options[tab.name][gname][cname] = opt
                        table.insert(self.controls, {tab=tabIdx, tabName=tab.name, group=gname, name=cname, opt=opt})
                        cy = cy + 22
                    end
                end

                if not group.y then
                    if isLeft then yLeft = gy + gh + 8 else yRight = gy + gh + 8 end
                end
            end
        end
        if not visible then
            for _, o in pairs(contentGroup) do
                if o.Visible ~= nil then o.Visible = false end
            end
        end
    end

    self:UpdateTabBar()
    Library.CreateNotification("Menu ready ("..n.." tabs)")
end

function Library:UpdateTabBar()
    local n = #self.tabButtons
    if n == 0 or not self.tabBar then return end
    local tabW = (self.w - 20) / n
    local slot = self.activetab
    local newX = (11 + ((tabW - 2) * (slot - 1))) + ((slot - 1) * 2)
    if self.tabBar.post then
        self.tabBar.post[2] = newX
    end
    if self.tabBar.obj then
        self.tabBar.obj.Position = Vector2.new(self.x + newX, self.y + 58)
        self.tabBar.obj.Size = Vector2.new(tabW - 2, 2)
    end
    for _, tb in ipairs(self.tabButtons) do
        if tb.label then
            tb.label.Color = (tb.index == self.activetab) and RGB(255,255,255) or RGB(170,170,170)
        end
    end
end

function Library:SwitchTab(idx)
    if idx < 1 or idx > #self.tabButtons then return end
    if self.openDropdown then self:CloseDropdown() end
    self.activetab = idx
    self:UpdateTabBar()
    for tabIdx, content in pairs(self.tabz) do
        local show = (tabIdx == idx) and self.open
        for _, o in pairs(content) do
            if o.Visible ~= nil then o.Visible = show end
        end
    end
    -- hide dropdown items
    for _, c in ipairs(self.controls) do
        if c.opt.type == DROPBOX and c.opt.items then
            for _, item in ipairs(c.opt.items) do
                item.bg.Visible = false
                item.text.Visible = false
            end
            c.opt.open = false
        end
    end
end

function Library:CloseDropdown()
    if not self.openDropdown then return end
    local opt = self.openDropdown
    opt.open = false
    if opt.items then
        for _, item in ipairs(opt.items) do
            item.bg.Visible = false
            item.text.Visible = false
        end
    end
    self.openDropdown = nil
end

function Library:OpenDropdown(opt)
    if self.openDropdown and self.openDropdown ~= opt then
        self:CloseDropdown()
    end
    opt.open = true
    self.openDropdown = opt
    if opt.items then
        for _, item in ipairs(opt.items) do
            item.bg.Visible = self.open
            item.text.Visible = self.open
        end
    end
end

function Library:SetVisible(vis)
    self.open = vis
    for _, o in pairs(self.bbmenu) do
        if o.Visible ~= nil then o.Visible = vis end
    end
    for tabIdx, content in pairs(self.tabz) do
        local show = vis and (tabIdx == self.activetab)
        for _, o in pairs(content) do
            if o.Visible ~= nil then o.Visible = show end
        end
    end
end

function Library:GetVal(tab, groupbox, name, extra)
    local t = self.options[tab]
    if not t then return nil end
    local g = t[groupbox]
    if not g then return nil end
    local opt = g[name]
    if not opt then return nil end
    if extra == COLOR or extra == KEYBIND then
        return opt.keybind or opt.value
    end
    return opt.value
end

function Library:SetVal(tab, groupbox, name, value)
    local t = self.options[tab]
    if not t then return end
    local g = t[groupbox]
    if not g then return end
    local opt = g[name]
    if not opt then return end
    opt.value = value
    if opt.type == TOGGLE then self:UpdateToggleVisual(opt)
    elseif opt.type == SLIDER then self:UpdateSliderVisual(opt)
    elseif opt.type == DROPBOX and opt.text and opt.values then
        opt.text.Text = tostring(opt.values[value] or "?")
    end
end

function Library:SetupInput()
    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if self.unloaded then return end

        -- Toggle menu
        if input.KeyCode == self.keybind then
            self:SetVisible(not self.open)
            Library.CreateNotification(self.open and "Menu opened" or "Menu closed")
            return
        end

        if not self.open then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        self.mousedown = true

        -- Drag window (title bar area)
        if self:MouseInMenu(0, 0, self.w, 25) then
            self.dragging = true
            local mx, my = getMouse(self)
            self.dragOffset = Vector2.new(mx - self.x, my - self.y)
            return
        end

        -- Tabs
        for _, tb in ipairs(self.tabButtons) do
            if self:MouseInMenu(tb.x, tb.y, tb.w, tb.h) then
                self:SwitchTab(tb.index)
                return
            end
        end

        -- Open dropdown item click
        if self.openDropdown then
            local opt = self.openDropdown
            for _, item in ipairs(opt.items or {}) do
                if self:MouseInMenu(item.x, item.y, item.w, item.h) then
                    opt.value = item.value
                    if opt.text and opt.values then
                        opt.text.Text = tostring(opt.values[item.value])
                    end
                    self:CloseDropdown()
                    return
                end
            end
            -- click outside closes
            if not self:MouseInMenu(opt.hx, opt.hy, opt.hw, opt.hh) then
                self:CloseDropdown()
            end
        end

        -- Controls on active tab
        for _, c in ipairs(self.controls) do
            if c.tab ~= self.activetab then continue end
            local opt = c.opt

            if opt.type == TOGGLE then
                if self:MouseInMenu(opt.hx, opt.hy, opt.hw, opt.hh) then
                    opt.value = not opt.value
                    self:UpdateToggleVisual(opt)
                    return
                end
            elseif opt.type == SLIDER then
                if self:MouseInMenu(opt.hx, opt.hy, opt.hw, opt.hh) then
                    self.activeSlider = opt
                    local mx = getMouse(self)
                    local rel = clamp((mx - (self.x + opt.hx)) / opt.hw, 0, 1)
                    opt.value = opt.min + rel * (opt.max - opt.min)
                    self:UpdateSliderVisual(opt)
                    return
                end
            elseif opt.type == DROPBOX then
                if self:MouseInMenu(opt.hx, opt.hy, opt.hw, opt.hh) then
                    if opt.open then self:CloseDropdown() else self:OpenDropdown(opt) end
                    return
                end
            elseif opt.type == BUTTON then
                if self:MouseInMenu(opt.hx, opt.hy, opt.hw, opt.hh) then
                    if opt.callback then
                        pcall(opt.callback)
                    else
                        Library.CreateNotification("Clicked: "..tostring(c.name))
                    end
                    return
                end
            elseif opt.type == KEYBIND then
                if self:MouseInMenu(opt.hx, opt.hy, opt.hw, opt.hh) then
                    opt.listening = true
                    if opt.text then opt.text.Text = "..." end
                    Library.CreateNotification("Press a key for "..tostring(c.name))
                    return
                end
            end
        end
    end))

    -- Keybind capture
    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if self.unloaded then return end
        for _, c in ipairs(self.controls) do
            local opt = c.opt
            if opt.type == KEYBIND and opt.listening then
                if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
                    opt.value = input.KeyCode
                    opt.listening = false
                    if opt.text then opt.text.Text = KeyEnumToName(opt.value) end
                    Library.CreateNotification(c.name.." = "..KeyEnumToName(opt.value))
                    return
                end
            end
        end
    end))

    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.mousedown = false
            self.dragging = false
            self.activeSlider = nil
        end
    end))

    table.insert(self.connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and self.activeSlider and self.mousedown then
            local opt = self.activeSlider
            local mx = getMouse(self)
            local rel = clamp((mx - (self.x + opt.hx)) / opt.hw, 0, 1)
            opt.value = opt.min + rel * (opt.max - opt.min)
            self:UpdateSliderVisual(opt)
        end
    end))

    table.insert(self.connections, RunService.RenderStepped:Connect(function()
        if self.unloaded then return end
        if self.dragging then
            local mx, my = getMouse(self)
            self:SetMenuPos(mx - self.dragOffset.X, my - self.dragOffset.Y)
        end
        for _, o in pairs(self.watermark.objects) do
            o.Visible = self.watermark.visible
        end
    end))
end

-- Player list
function Library:BuildPlayerList(x, y, w, h, tabIndex)
    tabIndex = tabIndex or self.activetab
    local g = self.tabz[tabIndex] or self.bbmenu
    local visible = (tabIndex == self.activetab) and self.open

    local function addOutline(vx,vy,vw,vh,col)
        Draw:OutlinedRect(visible, vx+self.x, vy+self.y, vw, vh, col, g)
        table.insert(self.postable, {g[#g], vx, vy})
    end
    local function addFill(a,b,c,d,e,f)
        local vx,vy,vw,vh,col
        if type(a) == "boolean" then vx,vy,vw,vh,col = b,c,d,e,f else vx,vy,vw,vh,col = a,b,c,d,e end
        if type(vx) ~= "number" or type(col) ~= "table" then return end
        Draw:FilledRect(visible, vx+self.x, vy+self.y, vw, vh, col, g)
        table.insert(self.postable, {g[#g], vx, vy})
    end
    local function addText(txt, center, vx, vy)
        local o = Draw:OutlinedText(txt, 2, visible, vx+self.x, vy+self.y, 13, center, {255,255,255,255}, {0,0,0}, g)
        table.insert(self.postable, {g[#g], vx, vy})
        return o
    end

    addOutline(x, y, w, h, {0,0,0,255})
    addOutline(x+1, y+1, w-2, h-2, {20,20,20,255})
    addOutline(x+2, y+2, w-3, 1, {self.mc[1], self.mc[2], self.mc[3], 255})
    addOutline(x+2, y+3, w-3, 1, {math.max(0,self.mc[1]-68), math.max(0,self.mc[2]-123), math.max(0,self.mc[3]-132), 255})
    addOutline(x+2, y+4, w-3, 1, {20,20,20,255})
    for i=0,7 do
        addFill(x+2, y+5+i*2, w-4, 2, {45,45,45,255})
        g[#g].Color = ColorRange(i, {{start=0,color=RGB(45,45,45)},{start=7,color=RGB(35,35,35)}})
    end
    addText("Player List", false, x+6, y+5)

    local maxRows = math.max(3, math.floor((h-90)/22))
    self.playerListMaxRows = maxRows
    addText("Name", false, x+10, y+22)
    addText("Team", false, x+math.floor(w/3)+10, y+22)
    addText("Status", false, x+math.floor(2*w/3)+10, y+22)
    addOutline(x+6, y+38, w-12, 22*maxRows+4, {30,30,30,255})

    local words = {}
    for i=1,maxRows do
        words[i] = {}
        local iy = y+42+(i-1)*22
        words[i][1] = addText("", false, x+10, iy)
        words[i][2] = addText("", false, x+math.floor(w/3)+10, iy)
        words[i][3] = addText("", false, x+math.floor(2*w/3)+10, iy)
        if i < maxRows then addOutline(x+8, iy+18, w-16, 1, {20,20,20,255}) end
    end
    self.playerListVisual = {words=words}
    self.playerListTab = tabIndex
    self:RefreshPlayerList()
end

function Library:RefreshPlayerList()
    if not self.playerListVisual then return end
    local words = self.playerListVisual.words
    local maxRows = self.playerListMaxRows or 6
    local players = Players:GetPlayers()
    table.sort(players, function(a,b) return a.Name < b.Name end)
    for i=1,maxRows do
        local p = players[i]
        if p and words[i] then
            local status, scol = "None", RGB(255,255,255)
            if p == LOCAL_PLAYER then status, scol = "Local", RGB(66,135,245) end
            if words[i][1] then words[i][1].Text = p.Name end
            if words[i][2] then
                words[i][2].Text = p.Team and p.Team.Name or "None"
                if p.Team then words[i][2].Color = p.TeamColor.Color end
            end
            if words[i][3] then words[i][3].Text = status; words[i][3].Color = scol end
        elseif words[i] then
            for c=1,3 do if words[i][c] then words[i][c].Text = "" end end
        end
    end
end

function Library:Unload()
    self.unloaded = true
    Draw:UnRender()
    for _, c in pairs(self.connections) do pcall(function() c:Disconnect() end) end
    table.clear(self.connections)
    Library.CreateNotification("UI unloaded")
end

return Library
