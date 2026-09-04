--[[
    BitchBot UI Library (Interactive)
    Working Drawing UI for Potassium / UNC executors
    https://docs.potassium.pro/

    Fully interactive: toggles, sliders, dropdowns, tabs.
]]

local Library = {}
Library.__index = Library

Library.COLOR, Library.COLOR1, Library.COLOR2 = 1, 2, 3
Library.COMBOBOX, Library.TOGGLE, Library.KEYBIND = 4, 5, 6
Library.DROPBOX, Library.COLORPICKER, Library.DOUBLE_COLORPICKERS = 7, 8, 9
Library.SLIDER, Library.BUTTON, Library.LIST = 10, 11, 12
Library.IMAGE, Library.TEXTBOX = 13, 14

local TOGGLE, SLIDER, DROPBOX, BUTTON, TEXTBOX = 5, 10, 7, 11, 14

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local function RGB(r,g,b) return Color3.fromRGB(math.clamp(r or 255,0,255), math.clamp(g or 255,0,255), math.clamp(b or 255,0,255)) end
local function clamp(n,lo,hi) return math.max(lo, math.min(hi, n)) end
local function map(n,a,b,c,d) return (n-a)/(b-a)*(d-c)+c end
local function ColorRange(value, ranges)
    if value <= ranges[1].start then return ranges[1].color end
    if value >= ranges[#ranges].start then return ranges[#ranges].color end
    local selected = #ranges
    for i = 1, #ranges-1 do if value < ranges[i+1].start then selected = i break end end
    local minC, maxC = ranges[selected], ranges[selected+1]
    local t = (value - minC.start) / (maxC.start - minC.start)
    return Color3.new(minC.color.R+(maxC.color.R-minC.color.R)*t, minC.color.G+(maxC.color.G-minC.color.G)*t, minC.color.B+(maxC.color.B-minC.color.B)*t)
end
local function mouseIn(x,y,w,h,mx,my) return mx>=x and mx<=x+w and my>=y and my<=y+h end

local Draw, allRender = {}, {}
function Draw:UnRender()
    for _,group in pairs(allRender) do for _,obj in pairs(group) do if type(obj)~="number" and obj then pcall(function() obj:Remove() end) end end end
    table.clear(allRender)
end
local function track(g) if not table.find(allRender,g) then table.insert(allRender,g) end end

function Draw:OutlinedRect(vis,x,y,w,h,col,g)
    local o=Drawing.new("Square"); o.Visible=vis; o.Position=Vector2.new(x,y); o.Size=Vector2.new(w,h)
    o.Color=RGB(col[1],col[2],col[3]); o.Filled=false; o.Thickness=1; o.Transparency=(col[4] or 255)/255
    table.insert(g,o); track(g); return o
end
function Draw:FilledRect(vis,x,y,w,h,col,g)
    local o=Drawing.new("Square"); o.Visible=vis; o.Position=Vector2.new(x,y); o.Size=Vector2.new(w,h)
    o.Color=RGB(col[1],col[2],col[3]); o.Filled=true; o.Thickness=0; o.Transparency=(col[4] or 255)/255
    table.insert(g,o); track(g); return o
end
function Draw:OutlinedText(txt,font,vis,x,y,size,center,col,ocol,g)
    local o=Drawing.new("Text"); o.Text=tostring(txt); o.Visible=vis; o.Position=Vector2.new(x,y)
    o.Size=size or 13; o.Center=center or false; o.Color=RGB(col[1],col[2],col[3]); o.Transparency=(col[4] or 255)/255
    o.Outline=true; o.OutlineColor=RGB(ocol[1] or 0,ocol[2] or 0,ocol[3] or 0); o.Font=font or 2
    table.insert(g,o); track(g); return o
end
function Draw:MenuOutlinedRect(menu,vis,x,y,w,h,col,g)
    local o=Draw:OutlinedRect(vis,x+menu.x,y+menu.y,w,h,col,g); table.insert(menu.postable,{o,x,y}); return o
end
function Draw:MenuFilledRect(menu,vis,x,y,w,h,col,g)
    local o=Draw:FilledRect(vis,x+menu.x,y+menu.y,w,h,col,g); table.insert(menu.postable,{o,x,y}); return o
end
function Draw:MenuBigText(menu,txt,vis,center,x,y,g)
    local o=Draw:OutlinedText(txt,2,vis,x+menu.x,y+menu.y,13,center,{255,255,255,255},{0,0,0},g)
    table.insert(menu.postable,{o,x,y}); return o
end
function Draw:CoolBox(menu,name,x,y,w,h,g)
    Draw:MenuOutlinedRect(menu,true,x,y,w,h,{0,0,0,255},g)
    Draw:MenuOutlinedRect(menu,true,x+1,y+1,w-2,h-2,{20,20,20,255},g)
    Draw:MenuOutlinedRect(menu,true,x+2,y+2,w-3,1,{menu.mc[1],menu.mc[2],menu.mc[3],255},g)
    Draw:MenuOutlinedRect(menu,true,x+2,y+3,w-3,1,{math.max(0,menu.mc[1]-68),math.max(0,menu.mc[2]-123),math.max(0,menu.mc[3]-132),255},g)
    Draw:MenuOutlinedRect(menu,true,x+2,y+4,w-3,1,{20,20,20,255},g)
    for i=0,7 do local c=ColorRange(i,{{start=0,color=RGB(45,45,45)},{start=7,color=RGB(35,35,35)}}); Draw:MenuFilledRect(menu,true,x+2,y+5+i*2,w-4,2,{c.R*255,c.G*255,c.B*255,255},g) end
    Draw:MenuBigText(menu,name,true,false,x+6,y+5,g)
end
Library.Draw = Draw

-- Notifications (abbreviated for size)
local notes = {}
local function CObj(typ,col) local d=Drawing.new(typ); d.Visible=true; d.Transparency=1; d.Color=col; return d end
local function CRect(w,h,f,col) local s=CObj("Square",col); s.Filled=f; s.Thickness=1; s.Position=Vector2.new(); s.Size=Vector2.new(w,h); return s end
local function CText(t) local s=CObj("Text",Color3.new(1,1,1)); s.Text=t; s.Size=13; s.Center=false; s.Outline=true; s.Position=Vector2.new(); s.Font=2; return s end

function Library.CreateNotification(text, customColor)
    local gap,width,alpha,time,estep,eestep,insety = 25,18,255,0,0,0.02,0
    local Note = {enabled=true, targetPos=Vector2.new(50,33), size=Vector2.new(200,width),
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
                if not self.fading then estep=0 end; self.fading=true; alpha-=estep/4*len*dt*50; eestep+=0.01*dt*100
            end
            if alpha<=0 then self:Remove() end
        end}
    for i=1,Note.size.y-2 do local c=0.28-i/80; Note.drawings[i]=CRect(200,1,true,Color3.new(c,c,c)) end
    local accent=customColor or Color3.fromRGB(100,100,225)
    Note.drawings.text=CText(text)
    if Note.drawings.text.TextBounds and Note.drawings.text.TextBounds.X+7>Note.size.x then Note.size=Vector2.new(Note.drawings.text.TextBounds.X+7,Note.size.y) end
    Note.drawings.line=CRect(1,Note.size.y-2,true,accent); Note.drawings.line1=CRect(1,Note.size.y-2,true,accent)
    table.insert(notes,Note)
end
RunService.RenderStepped:Connect(function(dt)
    for k=#notes,1,-1 do if not(notes[k] and notes[k].enabled) then table.remove(notes,k) end end
    local len=#notes; for k=1,len do local n=notes[k]; if n then n:Update(k,len,dt); if k<=math.ceil(len/10) or n.fading then n:Fade(k,len,dt) end end end
end)

-- Relations + Config (kept short)
local Relations={friends={},priority={}}
local function UnpackRelations()
    if not(isfile and isfile("bitchbot/relations.bb")) then return end
    local str=readfile("bitchbot/relations.bb"); if not str or str:find("bb:{{") then return end
    local fs,ps=str:find("friends:"),str:find("\npriority:"); if not(fs and ps) then return end
    for name in str:sub(fs+8,ps-1):gmatch("[^,]+") do name=name:match("^%s*(.-)%s*$"); if name~="" and not table.find(Relations.friends,name) then table.insert(Relations.friends,name) end end
    for name in str:sub(ps+10):gmatch("[^,]+") do name=name:match("^%s*(.-)%s*$"); if name~="" and not table.find(Relations.priority,name) then table.insert(Relations.priority,name) end end
    if not table.find(Relations.friends,LocalPlayer.Name) then table.insert(Relations.friends,LocalPlayer.Name) end
end
local function WriteRelations()
    local s="friends:"; for _,v in ipairs(Relations.friends) do s..=tostring(v).."," end; s..="\npriority:"; for _,v in ipairs(Relations.priority) do s..=tostring(v).."," end
    if writefile then if not isfolder("bitchbot") then makefolder("bitchbot") end; writefile("bitchbot/relations.bb",s) end
end
local function EnsureFolders(gn) if not isfolder then return end; if not isfolder("bitchbot") then makefolder("bitchbot") end; if not isfolder("bitchbot/"..gn) then makefolder("bitchbot/"..gn) end end
local function GetConfigs(gn)
    local res={}; if not listfiles then return res end; EnsureFolders(gn)
    for _,path in ipairs(listfiles("bitchbot/"..gn) or {}) do local name=path:match("([^/\\\\]+)%.bb$"); if name then table.insert(res,name) end end
    if #res==0 then pcall(writefile,"bitchbot/"..gn.."/Default.bb","{}"); table.insert(res,"Default") end; return res
end
local function SaveConfig(menu,name,gn)
    if not writefile then Library.CreateNotification("writefile unavailable") return false end; EnsureFolders(gn)
    local data={values=menu.values or {},friends=Relations.friends,priority=Relations.priority,accent=menu.mc}
    local ok,enc=pcall(HttpService.JSONEncode,HttpService,data)
    if ok then writefile("bitchbot/"..gn.."/"..name..".bb",enc); Library.CreateNotification("Saved: "..name); return true end
    Library.CreateNotification("Encode failed"); return false
end
local function LoadConfig(menu,name,gn)
    if not(readfile and isfile) then Library.CreateNotification("No filesystem") return false end
    local path="bitchbot/"..gn.."/"..name..".bb"; if not isfile(path) then Library.CreateNotification("Not found") return false end
    local ok,data=pcall(HttpService.JSONDecode,HttpService,readfile(path))
    if ok and type(data)=="table" then
        if data.values then menu.values=data.values end; if data.friends then Relations.friends=data.friends end
        if data.priority then Relations.priority=data.priority end; if data.accent then menu.mc=data.accent end
        Library.CreateNotification("Loaded: "..name); return true
    end; Library.CreateNotification("Decode failed"); return false
end
local function DeleteConfig(name,gn)
    if not delfile then return false end; local path="bitchbot/"..gn.."/"..name..".bb"
    if isfile(path) then delfile(path); Library.CreateNotification("Deleted: "..name); return true end; return false
end


-- Menu class
function Library.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Library)
    self.w = opts.width or 500
    self.h = opts.height or 600
    self.x = math.floor((Camera.ViewportSize.X/2) - (self.w/2))
    self.y = math.floor((Camera.ViewportSize.Y/2) - (self.h/2))
    self.open = true
    self.activetab = 1
    self.mousedown = false
    self.dragging = false
    self.dragOffset = Vector2.new()
    self.mc = opts.accent or {155,155,255}
    self.values = {}
    self.connections = {}
    self.postable = {}
    self.tabnames = {}
    self.tabs = {}
    self.drawGroup = {}
    self.controls = {}
    self.tabButtons = {}
    self.tabContent = {}
    self.openDropdown = nil
    self.activeSlider = nil
    self.unloaded = false
    self.gameName = opts.gameName or "Universal"
    self.menuName = opts.menuName or "Bitch Bot"
    self.keybind = opts.keybind or Enum.KeyCode.Delete
    self.username = opts.username or "user"
    self.playerListVisual = nil
    self.playerListMaxRows = 6
    self.columns = {width = math.floor((self.w-40)/2), left = 17, right = math.floor((self.w-20)/2)+13}
    self.watermark = {text = self.menuName.." | "..self.username.." | "..os.date("%b. %d, %Y"), pos = Vector2.new(20,10), visible = true, objects = {}}
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
    Draw:MenuOutlinedRect(self,true,0,0,self.w,self.h,{0,0,0,255},g)
    Draw:MenuOutlinedRect(self,true,1,1,self.w-2,self.h-2,{20,20,20,255},g)
    Draw:MenuOutlinedRect(self,true,2,2,self.w-3,1,{self.mc[1],self.mc[2],self.mc[3],255},g)
    Draw:MenuOutlinedRect(self,true,2,3,self.w-3,1,{math.max(0,self.mc[1]-68),math.max(0,self.mc[2]-123),math.max(0,self.mc[3]-132),255},g)
    Draw:MenuOutlinedRect(self,true,2,4,self.w-3,1,{20,20,20,255},g)
    for i=0,19 do
        local c = ColorRange(i,{{start=0,color=RGB(50,50,50)},{start=20,color=RGB(35,35,35)}})
        Draw:MenuFilledRect(self,true,2,5+i,self.w-4,1,{c.R*255,c.G*255,c.B*255,255},g)
    end
    Draw:MenuFilledRect(self,true,2,25,self.w-4,self.h-27,{35,35,35,255},g)
    Draw:MenuBigText(self,self.menuName,true,false,6,6,g)
end

function Library:CreateWatermark()
    local wm = self.watermark
    local objs = {}
    local width = (#wm.text*7)+14
    local height = 20
    Draw:FilledRect(true,wm.pos.x,wm.pos.y+1,width,2,{self.mc[1]-40,self.mc[2]-40,self.mc[3]-40,255},objs)
    Draw:FilledRect(true,wm.pos.x,wm.pos.y,width,2,{self.mc[1],self.mc[2],self.mc[3],255},objs)
    for i=0,height-4 do
        local c = 50-i*1.7
        Draw:FilledRect(true,wm.pos.x,wm.pos.y+3+i,width,1,{c,c,c,255},objs)
    end
    Draw:OutlinedRect(true,wm.pos.x,wm.pos.y,width,height,{0,0,0,255},objs)
    Draw:OutlinedRect(true,wm.pos.x-1,wm.pos.y-1,width+2,height+2,{0,0,0,100},objs)
    Draw:OutlinedText(wm.text,2,true,wm.pos.x+6,wm.pos.y+3,13,false,{255,255,255,255},{0,0,0},objs)
    wm.objects = objs
end

function Library:UpdatePositions()
    for _,e in ipairs(self.postable) do
        local obj,ox,oy = e[1],e[2],e[3]
        if obj and obj.Position then obj.Position = Vector2.new(self.x+ox, self.y+oy) end
    end
end

function Library:SetVisible(vis)
    for _,o in pairs(self.drawGroup) do if o.Visible ~= nil then o.Visible = vis end end
    for tabIdx, content in pairs(self.tabContent) do
        local show = vis and (tabIdx == self.activetab)
        for _,o in pairs(content) do if o.Visible ~= nil then o.Visible = show end end
    end
end

function Library:UpdateToggleVisual(ctrl)
    for i,box in ipairs(ctrl.boxes) do
        local col = ctrl.value and ColorRange(i-1,{
            {start=0,color=RGB(self.mc[1],self.mc[2],self.mc[3])},
            {start=3,color=RGB(self.mc[1]-40,self.mc[2]-40,self.mc[3]-40)}
        }) or ColorRange(i-1,{{start=0,color=RGB(50,50,50)},{start=3,color=RGB(30,30,30)}})
        box.Color = col
    end
end

function Library:UpdateSliderVisual(ctrl)
    local pct = clamp((ctrl.value-ctrl.min)/math.max(ctrl.max-ctrl.min,1),0,1)
    for _,r in ipairs(ctrl.fill) do r.Size = Vector2.new((ctrl.length-4)*pct, 2) end
    if ctrl.label then ctrl.label.Text = tostring(math.floor(ctrl.value+0.5))..ctrl.stradd end
end

function Library:SetDropdownOpen(ctrl, open)
    ctrl.open = open
    for _,item in ipairs(ctrl.items) do
        item.bg.Visible = open and (ctrl.tab == self.activetab) and self.open
        item.text.Visible = open and (ctrl.tab == self.activetab) and self.open
    end
    if open then self.openDropdown = ctrl elseif self.openDropdown == ctrl then self.openDropdown = nil end
end

function Library:Initialize(menutable)
    if type(menutable) ~= "table" then return end
    self.tabs = menutable
    self.tabnames = {}
    self.controls = {}
    self.tabButtons = {}
    self.tabContent = {}

    local tabX = 6
    for i,tab in ipairs(menutable) do
        self.tabnames[i] = tab.name
        local btn = Draw:MenuBigText(self, tab.name, true, false, tabX, 28, self.drawGroup)
        btn.Color = (i == self.activetab) and RGB(255,255,255) or RGB(170,170,170)
        local tw = (btn.TextBounds and btn.TextBounds.X) or 40
        table.insert(self.tabButtons, {index=i, x=tabX, y=28, w=tw+8, h=16, text=btn})
        tabX = tabX + tw + 12
    end

    for tabIdx, tab in ipairs(menutable) do
        local contentGroup = {}
        self.tabContent[tabIdx] = contentGroup
        local visible = (tabIdx == self.activetab)

        if tab.content then
            local yLeft, yRight = 55, 55
            for _, group in ipairs(tab.content) do
                local isLeft = (group.autopos == "left") or (group.x == self.columns.left)
                local gx = group.x or (isLeft and self.columns.left or self.columns.right)
                local gy = group.y or (isLeft and yLeft or yRight)
                local gw = group.width or self.columns.width
                local gh = group.height or 140
                local title = type(group.name) == "table" and table.concat(group.name, "  ") or (group.name or "Group")

                local function mOutline(vis,x,y,w,h,col)
                    local o = Draw:OutlinedRect(vis, x+self.x, y+self.y, w,h, col, contentGroup)
                    table.insert(self.postable, {o,x,y}); return o
                end
                local function mFill(vis,x,y,w,h,col)
                    local o = Draw:FilledRect(vis, x+self.x, y+self.y, w,h, col, contentGroup)
                    table.insert(self.postable, {o,x,y}); return o
                end
                local function mText(txt,vis,center,x,y)
                    local o = Draw:OutlinedText(txt,2,vis, x+self.x,y+self.y,13,center,{255,255,255,255},{0,0,0}, contentGroup)
                    table.insert(self.postable, {o,x,y}); return o
                end

                mOutline(visible,gx,gy,gw,gh,{0,0,0,255})
                mOutline(visible,gx+1,gy+1,gw-2,gh-2,{20,20,20,255})
                mOutline(visible,gx+2,gy+2,gw-3,1,{self.mc[1],self.mc[2],self.mc[3],255})
                mOutline(visible,gx+2,gy+3,gw-3,1,{math.max(0,self.mc[1]-68),math.max(0,self.mc[2]-123),math.max(0,self.mc[3]-132),255})
                mOutline(visible,gx+2,gy+4,gw-3,1,{20,20,20,255})
                for i=0,7 do
                    local c = ColorRange(i,{{start=0,color=RGB(45,45,45)},{start=7,color=RGB(35,35,35)}})
                    mFill(visible,gx+2,gy+5+i*2,gw-4,2,{c.R*255,c.G*255,c.B*255,255})
                end
                mText(title, visible, false, gx+6, gy+5)

                local cy = gy + 28
                local content = group.content or {}
                local gname = type(group.name) == "table" and group.name[1] or (group.name or "")

                for _, ctrl in ipairs(content) do
                    local key = (tab.name or "").."/"..gname.."/"..(ctrl.name or "")
                    local typ = ctrl.type

                    if typ == TOGGLE or typ == "toggle" then
                        self.values[key] = ctrl.value or false
                        mOutline(visible, gx+8, cy, 12, 12, {30,30,30,255})
                        mOutline(visible, gx+9, cy+1, 10, 10, {0,0,0,255})
                        local boxes = {}
                        for i=0,3 do
                            local col = (ctrl.value) and ColorRange(i,{
                                {start=0,color=RGB(self.mc[1],self.mc[2],self.mc[3])},
                                {start=3,color=RGB(self.mc[1]-40,self.mc[2]-40,self.mc[3]-40)}
                            }) or ColorRange(i,{{start=0,color=RGB(50,50,50)},{start=3,color=RGB(30,30,30)}})
                            table.insert(boxes, mFill(visible, gx+10, cy+2+i*2, 8, 2, {col.R*255,col.G*255,col.B*255,255}))
                        end
                        mText(ctrl.name or "Toggle", visible, false, gx+24, cy-1)
                        table.insert(self.controls, {type="toggle", key=key, tab=tabIdx, x=gx+8, y=cy, w=12, h=12, boxes=boxes, value=ctrl.value or false})
                        cy = cy + 20

                    elseif typ == SLIDER or typ == "slider" then
                        local val = ctrl.value or ctrl.minvalue or 0
                        local minv, maxv = ctrl.minvalue or 0, ctrl.maxvalue or 100
                        local stradd = ctrl.stradd or ""
                        local length = gw - 20
                        self.values[key] = val
                        mText(ctrl.name or "Slider", visible, false, gx+8, cy-3)
                        for i=0,3 do
                            local c = ColorRange(i,{{start=0,color=RGB(50,50,50)},{start=3,color=RGB(30,30,30)}})
                            mFill(visible, gx+10, cy+14+i*2, length-4, 2, {c.R*255,c.G*255,c.B*255,255})
                        end
                        local fill = {}
                        local pct = clamp((val-minv)/math.max(maxv-minv,1),0,1)
                        for i=0,3 do
                            local c = ColorRange(i,{
                                {start=0,color=RGB(self.mc[1],self.mc[2],self.mc[3])},
                                {start=3,color=RGB(self.mc[1]-40,self.mc[2]-40,self.mc[3]-40)}
                            })
                            table.insert(fill, mFill(visible, gx+10, cy+14+i*2, (length-4)*pct, 2, {c.R*255,c.G*255,c.B*255,255}))
                        end
                        mOutline(visible, gx+8, cy+12, length, 12, {30,30,30,255})
                        mOutline(visible, gx+9, cy+13, length-2, 10, {0,0,0,255})
                        local label = mText(tostring(val)..stradd, visible, true, gx+8+length*0.5, cy+11)
                        table.insert(self.controls, {type="slider", key=key, tab=tabIdx, x=gx+8, y=cy+12, w=length, h=12, fill=fill, label=label, value=val, min=minv, max=maxv, stradd=stradd, length=length})
                        cy = cy + 34

                    elseif typ == DROPBOX or typ == "dropbox" then
                        local val = ctrl.value or 1
                        local values = ctrl.values or {"A","B"}
                        local length = gw - 20
                        self.values[key] = val
                        mText(ctrl.name or "Dropbox", visible, false, gx+8, cy-3)
                        for i=0,7 do
                            local c = ColorRange(i,{{start=0,color=RGB(50,50,50)},{start=7,color=RGB(35,35,35)}})
                            mFill(visible, gx+10, cy+14+i*2, length-4, 2, {c.R*255,c.G*255,c.B*255,255})
                        end
                        mOutline(visible, gx+8, cy+12, length, 22, {30,30,30,255})
                        mOutline(visible, gx+9, cy+13, length-2, 20, {0,0,0,255})
                        local txt = mText(tostring(values[val] or "?"), visible, false, gx+14, cy+16)
                        mText("-", visible, false, gx+8+length-17, cy+16)
                        local dropItems = {}
                        for i,v in ipairs(values) do
                            local iy = cy+34+(i-1)*18
                            local bg = mFill(false, gx+8, iy, length, 18, {25,25,25,255})
                            local t = mText(tostring(v), false, false, gx+14, iy+2)
                            table.insert(dropItems, {bg=bg, text=t, y=iy, value=i, x=gx+8, w=length, h=18})
                        end
                        table.insert(self.controls, {type="dropbox", key=key, tab=tabIdx, x=gx+8, y=cy+12, w=length, h=22, text=txt, values=values, value=val, open=false, items=dropItems, length=length})
                        cy = cy + 42

                    elseif typ == BUTTON or typ == "button" then
                        local length = gw - 20
                        for i=0,8 do
                            local c = ColorRange(i,{{start=0,color=RGB(50,50,50)},{start=8,color=RGB(35,35,35)}})
                            mFill(visible, gx+10, cy+2+i*2, length-4, 2, {c.R*255,c.G*255,c.B*255,255})
                        end
                        mOutline(visible, gx+8, cy, length, 22, {30,30,30,255})
                        mOutline(visible, gx+9, cy+1, length-2, 20, {0,0,0,255})
                        mText(ctrl.name or "Button", visible, true, gx+8+math.floor(length*0.5), cy+4)
                        table.insert(self.controls, {type="button", key=key, tab=tabIdx, x=gx+8, y=cy, w=length, h=22, callback=ctrl.callback})
                        cy = cy + 28

                    elseif typ == TEXTBOX or typ == "textbox" then
                        local length = gw - 20
                        local txtval = ctrl.text or ""
                        self.values[key] = txtval
                        for i=0,8 do
                            local c = ColorRange(i,{{start=0,color=RGB(50,50,50)},{start=8,color=RGB(35,35,35)}})
                            mFill(visible, gx+10, cy+2+i*2, length-4, 2, {c.R*255,c.G*255,c.B*255,255})
                        end
                        mOutline(visible, gx+8, cy, length, 22, {30,30,30,255})
                        mOutline(visible, gx+9, cy+1, length-2, 20, {0,0,0,255})
                        local txt = mText(txtval, visible, false, gx+14, cy+4)
                        table.insert(self.controls, {type="textbox", key=key, tab=tabIdx, x=gx+8, y=cy, w=length, h=22, text=txt, value=txtval})
                        cy = cy + 28
                    end
                end
                if not group.y then
                    if isLeft then yLeft = gy+gh+8 else yRight = gy+gh+8 end
                end
            end
        end
        if not visible then
            for _,o in pairs(contentGroup) do if o.Visible ~= nil then o.Visible = false end end
        end
    end
    Library.CreateNotification("Menu ready ("..#menutable.." tabs)")
end

function Library:SwitchTab(idx)
    if idx < 1 or idx > #self.tabs then return end
    if self.openDropdown then self:SetDropdownOpen(self.openDropdown, false) end
    self.activetab = idx
    for _,tb in ipairs(self.tabButtons) do
        if tb.text then tb.text.Color = (tb.index == idx) and RGB(255,255,255) or RGB(170,170,170) end
    end
    for tabIdx, content in pairs(self.tabContent) do
        local show = (tabIdx == idx) and self.open
        for _,o in pairs(content) do if o.Visible ~= nil then o.Visible = show end end
    end
    for _,ctrl in ipairs(self.controls) do
        if ctrl.type == "dropbox" then
            for _,item in ipairs(ctrl.items) do item.bg.Visible = false; item.text.Visible = false end
            ctrl.open = false
        end
    end
end

function Library:SetupInput()
    table.insert(self.connections, UserInputService.InputBegan:Connect(function(input, gpe)
        if self.unloaded then return end
        if input.KeyCode == self.keybind then
            self.open = not self.open
            self:SetVisible(self.open)
            Library.CreateNotification(self.open and "Menu opened" or "Menu closed")
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not self.open then return end
        local mx, my = Mouse.X, Mouse.Y
        self.mousedown = true

        if mouseIn(self.x, self.y, self.w, 25, mx, my) then
            self.dragging = true
            self.dragOffset = Vector2.new(mx - self.x, my - self.y)
            return
        end

        for _,tb in ipairs(self.tabButtons) do
            if mouseIn(self.x+tb.x, self.y+tb.y, tb.w, tb.h, mx, my) then
                self:SwitchTab(tb.index)
                return
            end
        end

        if self.openDropdown then
            local dd = self.openDropdown
            for _,item in ipairs(dd.items) do
                if mouseIn(self.x+item.x, self.y+item.y, item.w, item.h, mx, my) then
                    dd.value = item.value
                    self.values[dd.key] = item.value
                    if dd.text then dd.text.Text = tostring(dd.values[item.value]) end
                    self:SetDropdownOpen(dd, false)
                    return
                end
            end
            if not mouseIn(self.x+dd.x, self.y+dd.y, dd.w, dd.h, mx, my) then
                self:SetDropdownOpen(dd, false)
            end
        end

        for _,ctrl in ipairs(self.controls) do
            if ctrl.tab ~= self.activetab then continue end
            if ctrl.type == "toggle" and mouseIn(self.x+ctrl.x, self.y+ctrl.y, ctrl.w+100, ctrl.h, mx, my) then
                ctrl.value = not ctrl.value
                self.values[ctrl.key] = ctrl.value
                self:UpdateToggleVisual(ctrl)
                return
            elseif ctrl.type == "slider" and mouseIn(self.x+ctrl.x, self.y+ctrl.y, ctrl.w, ctrl.h, mx, my) then
                self.activeSlider = ctrl
                local rel = clamp((mx - (self.x+ctrl.x)) / ctrl.w, 0, 1)
                ctrl.value = ctrl.min + rel * (ctrl.max - ctrl.min)
                self.values[ctrl.key] = ctrl.value
                self:UpdateSliderVisual(ctrl)
                return
            elseif ctrl.type == "dropbox" and mouseIn(self.x+ctrl.x, self.y+ctrl.y, ctrl.w, ctrl.h, mx, my) then
                if self.openDropdown and self.openDropdown ~= ctrl then self:SetDropdownOpen(self.openDropdown, false) end
                self:SetDropdownOpen(ctrl, not ctrl.open)
                return
            elseif ctrl.type == "button" and mouseIn(self.x+ctrl.x, self.y+ctrl.y, ctrl.w, ctrl.h, mx, my) then
                if ctrl.callback then pcall(ctrl.callback)
                else
                    local k = ctrl.key or ""
                    if k:find("Save Config") then self:SaveConfig(tostring(self.values["Settings/Configuration/Config Name"] or "Default"))
                    elseif k:find("Load Config") then self:LoadConfig(tostring(self.values["Settings/Configuration/Config Name"] or "Default"))
                    elseif k:find("Delete Config") then self:DeleteConfig(tostring(self.values["Settings/Configuration/Config Name"] or "Default"))
                    elseif k:find("Unload") then self:Unload()
                    else Library.CreateNotification("Clicked: "..(ctrl.key or "Button")) end
                end
                return
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
            local ctrl = self.activeSlider
            local mx = Mouse.X
            local rel = clamp((mx - (self.x+ctrl.x)) / ctrl.w, 0, 1)
            ctrl.value = ctrl.min + rel * (ctrl.max - ctrl.min)
            self.values[ctrl.key] = ctrl.value
            self:UpdateSliderVisual(ctrl)
        end
    end))

    table.insert(self.connections, RunService.RenderStepped:Connect(function()
        if self.unloaded then return end
        if self.dragging then
            self.x = Mouse.X - self.dragOffset.X
            self.y = Mouse.Y - self.dragOffset.Y
            self:UpdatePositions()
        end
        for _,o in pairs(self.watermark.objects) do o.Visible = self.watermark.visible end
    end))
end

function Library:GetVal(t,g,o) return self.values[(t or "").."/"..(g or "").."/"..(o or "")] end
function Library:SetVal(t,g,o,v) self.values[(t or "").."/"..(g or "").."/"..(o or "")] = v end
function Library:IsFriend(n) return table.find(Relations.friends,n) ~= nil end
function Library:IsPriority(n) return table.find(Relations.priority,n) ~= nil end
function Library:AddFriend(n) if not table.find(Relations.friends,n) then table.insert(Relations.friends,n) WriteRelations() end end
function Library:RemoveFriend(n) local i=table.find(Relations.friends,n) if i then table.remove(Relations.friends,i) WriteRelations() end end
function Library:AddPriority(n) if not table.find(Relations.priority,n) then table.insert(Relations.priority,n) WriteRelations() end end
function Library:RemovePriority(n) local i=table.find(Relations.priority,n) if i then table.remove(Relations.priority,i) WriteRelations() end end
function Library:GetFriends() return Relations.friends end
function Library:GetPriority() return Relations.priority end
function Library:SaveConfig(n) return SaveConfig(self, n or "Default", self.gameName) end
function Library:LoadConfig(n) return LoadConfig(self, n or "Default", self.gameName) end
function Library:DeleteConfig(n) return DeleteConfig(n or "Default", self.gameName) end
function Library:GetConfigList() return GetConfigs(self.gameName) end

function Library:BuildPlayerList(x, y, w, h, tabIndex)
    -- tabIndex: optional, if provided the player list only shows on that tab
    tabIndex = tabIndex or self.activetab
    local g = self.tabContent[tabIndex] or self.drawGroup
    local visible = (tabIndex == self.activetab) and self.open

    local function mOutline(vis, ox, oy, ow, oh, col)
        local o = Draw:OutlinedRect(vis, ox+self.x, oy+self.y, ow, oh, col, g)
        table.insert(self.postable, {o, ox, oy})
        return o
    end
    local function mFill(vis, ox, oy, ow, oh, col)
        local o = Draw:FilledRect(vis, ox+self.x, oy+self.y, ow, oh, col, g)
        table.insert(self.postable, {o, ox, oy})
        return o
    end
    local function mText(txt, vis, center, ox, oy)
        local o = Draw:OutlinedText(txt, 2, vis, ox+self.x, oy+self.y, 13, center, {255,255,255,255}, {0,0,0}, g)
        table.insert(self.postable, {o, ox, oy})
        return o
    end

    -- CoolBox
    mOutline(visible, x, y, w, h, {0,0,0,255})
    mOutline(visible, x+1, y+1, w-2, h-2, {20,20,20,255})
    mOutline(visible, x+2, y+2, w-3, 1, {self.mc[1], self.mc[2], self.mc[3], 255})
    mOutline(visible, x+2, y+3, w-3, 1, {math.max(0,self.mc[1]-68), math.max(0,self.mc[2]-123), math.max(0,self.mc[3]-132), 255})
    mOutline(visible, x+2, y+4, w-3, 1, {20,20,20,255})
    for i=0,7 do
        local c = ColorRange(i, {{start=0,color=RGB(45,45,45)},{start=7,color=RGB(35,35,35)}})
        mFill(visible, x+2, y+5+i*2, w-4, 2, {c.R*255, c.G*255, c.B*255, 255})
    end
    mText("Player List", visible, false, x+6, y+5)

    local maxRows = math.max(3, math.floor((h - 100) / 22))
    self.playerListMaxRows = maxRows

    mText("Name", visible, false, x+10, y+22)
    mText("Team", visible, false, x+math.floor(w/3)+10, y+22)
    mText("Status", visible, false, x+math.floor(2*w/3)+10, y+22)
    mOutline(visible, x+6, y+38, w-12, 22*maxRows+4, {30,30,30,255})

    local words = {}
    for i = 1, maxRows do
        words[i] = {}
        local iy = y + 42 + (i-1)*22
        words[i][1] = mText("", visible, false, x+10, iy)
        words[i][2] = mText("", visible, false, x+math.floor(w/3)+10, iy)
        words[i][3] = mText("", visible, false, x+math.floor(2*w/3)+10, iy)
        if i < maxRows then mOutline(visible, x+8, iy+18, w-16, 1, {20,20,20,255}) end
    end
    self.playerListVisual = {words = words}
    self.playerListTab = tabIndex

    -- Bottom controls: status + buttons (like original)
    local by = y + h - 48
    mText("Player Status", visible, false, x + w - 180, by - 18)
    -- simple dropbox visual for status
    mOutline(visible, x + w - 180, by, 100, 20, {30,30,30,255})
    mFill(visible, x + w - 179, by + 1, 98, 18, {25,25,25,255})
    mText("None", visible, false, x + w - 174, by + 3)
    -- buttons
    mOutline(visible, x + w - 70, by, 60, 20, {30,30,30,255})
    mFill(visible, x + w - 69, by + 1, 58, 18, {35,35,35,255})
    mText("Spectate", visible, true, x + w - 40, by + 3)

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
            if p == LocalPlayer then status, scol = "Local", RGB(66,135,245)
            elseif self:IsFriend(p.Name) then status, scol = "Friend", RGB(0,255,0)
            elseif self:IsPriority(p.Name) then status, scol = "Priority", RGB(255,210,0) end
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
    for _,c in pairs(self.connections) do pcall(function() c:Disconnect() end) end
    table.clear(self.connections)
    Library.CreateNotification("UI unloaded")
end

return Library
