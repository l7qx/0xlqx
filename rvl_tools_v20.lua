

local plrs = game:GetService("Players")
local run = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local ws = game:GetService("Workspace")
local lt = game:GetService("Lighting")
local hs = game:GetService("HttpService")
local tps = game:GetService("TeleportService")

local lp = plrs.LocalPlayer
local cam = ws.CurrentCamera
local baseFov = cam.FieldOfView or 70
local mouse = lp:GetMouse()
local touch = uis.TouchEnabled and not uis.KeyboardEnabled
if cam.ViewportSize.X <= 0 then repeat task.wait() until cam.ViewportSize.X > 0 end

local G = (getgenv and getgenv()) or _G
G.__rvl4_gen = (G.__rvl4_gen or 0) + 1
local myGen = G.__rvl4_gen
local function alive() return G.__rvl4_gen == myGen end

local cfg = {
    aim = { on = false, fov = 140, sm = .35, team = true, wall = false, part = "Head", pred = .14, sticky = true, always = false, ragebot = false, prio = "クロスヘア", cyclekey = "T" },
    sil = { on = false, chance = 100, headchance = 0, fov = 250 },
    trg = { on = false, fov = 10, delay = 70, ads = false, mode = "連射", head = false },
    esp = { on = true, chams = true, box = true, name = true, wp = true, hp = true, dist = true, trc = false, tline = false, skel = false, max = 900 },
    fly = { on = false, spd = 48 },
    void = { on = false },
    spd = { on = false, val = 26 },
    jmp = { on = false, val = 70 },
    noc = false,
    infj = false, bhop = false, fpsb = false, afk = false,
    xhair = { on = false },
    hb = { on = false, size = 6, part = "両方" },
    vis = { fb = false, nf = false },
    camf = { on = false, val = 100 },
    combat = { norecoil = false, nospread = false, auto = false, rapid = false, reload = false, equip = false, ammo = false },
    misc = {},
}

local cfFile = "rvl_tools_v3.json"
pcall(function()
    if isfile and isfile("rvl_tools_prof.json") then
        local d = hs:JSONDecode(readfile("rvl_tools_prof.json"))
        if d and (d.prof == 2 or d.prof == 3) then
            cfFile = "rvl_tools_v3_p" .. d.prof .. ".json"
            cfg.misc.prof = d.prof
        end
    end
end)
local function save()
    pcall(function() if writefile then writefile(cfFile, hs:JSONEncode(cfg)) end end)
end
local function load()
    pcall(function()
        if isfile and isfile(cfFile) then
            local d = hs:JSONDecode(readfile(cfFile))
            if type(d) ~= "table" then return end
            for k, v in pairs(d) do
                local key = (k == "cam") and "camf" or k
                if type(v) == "table" and type(cfg[key]) == "table" then
                    for k2, v2 in pairs(v) do
                        if cfg[key][k2] ~= nil and type(v2) == type(cfg[key][k2]) then cfg[key][k2] = v2 end
                    end
                elseif cfg[key] ~= nil and type(v) == type(cfg[key]) then
                    cfg[key] = v
                end
            end
        end
    end)
end
load()
local function sanitize()
    local parts = { Head = true, HumanoidRootPart = true, UpperTorso = true, Closest = true }
    if not parts[cfg.aim.part] then cfg.aim.part = "Head" end
    local prios = { ["クロスヘア"] = true, ["低HP"] = true, ["近距離"] = true }
    if not prios[cfg.aim.prio] then cfg.aim.prio = "クロスヘア" end
    local function cl(v, d, mn, mx) return math.clamp(tonumber(v) or d, mn, mx) end
    cfg.aim.fov = cl(cfg.aim.fov, 140, 20, 700)
    cfg.aim.sm = cl(cfg.aim.sm, .35, .05, 1)
    cfg.aim.pred = cl(cfg.aim.pred, .14, 0, .3)
    cfg.sil.chance = cl(cfg.sil.chance, 100, 10, 100)
    cfg.sil.headchance = cl(cfg.sil.headchance, 0, 0, 100)
    cfg.sil.fov = cl(cfg.sil.fov, 250, 30, 700)
    if cfg.trg.mode ~= "連射" and cfg.trg.mode ~= "単発" then cfg.trg.mode = "連射" end
    local cks = { T = true, Q = true, V = true, ["なし"] = true }
    if not cks[cfg.aim.cyclekey] then cfg.aim.cyclekey = "T" end
    if cfg.hb.part ~= "両方" and cfg.hb.part ~= "頭" and cfg.hb.part ~= "胴体" then cfg.hb.part = "両方" end
    cfg.trg.fov = cl(cfg.trg.fov, 10, 2, 60)
    cfg.trg.delay = cl(cfg.trg.delay, 70, 0, 300)
    cfg.esp.max = cl(cfg.esp.max, 900, 100, 5000)
    cfg.hb.size = cl(cfg.hb.size, 6, 2, 20)
    cfg.camf.val = cl(cfg.camf.val, 100, 60, 130)
    cfg.misc.prof = math.clamp(math.floor(tonumber(cfg.misc.prof) or 1), 1, 3)
    cfg.fly.spd = cl(cfg.fly.spd, 48, 10, 300)
    cfg.spd.val = cl(cfg.spd.val, 26, 16, 200)
    cfg.jmp.val = cl(cfg.jmp.val, 70, 50, 500)
end
sanitize()
G.__rvl4_cfg = cfg

local conns = {}
local function bind(ev, fn)
    local c = ev:Connect(fn)
    table.insert(conns, c)
    return c
end

local spawnPos = {}
local spawnAt = {}
do
local function record(plr)
    local c = plr.Character
    if not c then return end

    task.delay(.15, function()
        if not alive() then return end
        local r = c:FindFirstChild("HumanoidRootPart")
        if not (r and r.Parent) then return end
        local first = r.Position
        spawnPos[plr] = first
        spawnAt[plr] = os.clock()
        task.delay(.7, function()
            if not alive() then return end
            local r2 = c:FindFirstChild("HumanoidRootPart")
            if r2 and r2.Parent and (r2.Position - first).Magnitude > 10 then
                spawnPos[plr] = r2.Position
            end
        end)
    end)
end

local function watch(plr)
    bind(plr.CharacterAdded, function()
        spawnPos[plr] = nil
        spawnAt[plr] = nil
        record(plr)
    end)
    record(plr)
end

bind(plrs.PlayerAdded, watch)
for _, p in ipairs(plrs:GetPlayers()) do watch(p) end
end

local teamActive, teamsInUse
do
local cActive, cInUse, cAt = false, false, 0
local function scanTeams()
    local now = os.clock()
    if now - cAt < .5 then return end
    cAt = now
    cActive, cInUse = false, false
    local t = lp.Team
    if t then cInUse = true end
    for _, p in ipairs(plrs:GetPlayers()) do
        if p.Team then
            cInUse = true
            if t and p ~= lp and p.Team ~= t then cActive = true end
        end
    end
end
function teamActive() scanTeams() return cActive end
function teamsInUse() scanTeams() return cInUse end
end

local charCache = {}
local frameId = 0
local function getChar(p)
    local c = p.Character
    if not c or not c.Parent then charCache[p] = nil return nil end
    local cc = charCache[p]
    if cc and cc.c == c and cc.hum and cc.hum.Parent then
        if not cc.head or not cc.head.Parent then cc.head = c:FindFirstChild("Head") end
        if not cc.root or not cc.root.Parent then cc.root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") end
        if not cc.upper or not cc.upper.Parent then cc.upper = c:FindFirstChild("UpperTorso") end
        return cc
    end
    cc = {
        c = c,
        hum = c:FindFirstChildOfClass("Humanoid"),
        head = c:FindFirstChild("Head"),
        root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"),
        upper = c:FindFirstChild("UpperTorso"),
    }
    charCache[p] = cc
    return cc
end

local function isEnemy(p)
    if p == lp then return false end
    local cc = getChar(p)
    if not cc or not cc.hum or cc.hum.Health <= 0 then return false end
    if cfg.aim.team then
        if teamActive() and p.Team == lp.Team then return false end
        if teamsInUse() then
            local sp = spawnPos[p]
            local mySp = spawnPos[lp]
            if sp and mySp and spawnAt[p] and os.clock() - spawnAt[p] < 6 and (sp - mySp).Magnitude < 38 then return false end
        end
    end
    return true
end

local function origin()
    if touch then return Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2) end
    return uis:GetMouseLocation()
end

local function partOf(p)
    local cc = getChar(p)
    if not cc then return end
    if cc._pf == frameId then return cc._pp end
    local want = cfg.aim.part
    local r
    if want == "Closest" then
        local o = origin()
        local bestP, bestD = nil, math.huge
        for _, cand in ipairs({ cc.head, cc.root, cc.upper }) do
            if cand then
                local s, on = cam:WorldToViewportPoint(cand.Position)
                if on and s.Z > 0 then
                    local d = (Vector2.new(s.X, s.Y) - o).Magnitude
                    if d < bestD then bestP, bestD = cand, d end
                end
            end
        end
        r = bestP or cc.head or cc.root
    elseif want == "Head" then r = cc.head or cc.root
    elseif want == "HumanoidRootPart" then r = cc.root or cc.head
    elseif want == "UpperTorso" then r = cc.upper or cc.root or cc.head
    else r = cc.c:FindFirstChild(want) or cc.head or cc.root end
    cc._pf, cc._pp = frameId, r
    return r
end
local function rootOf(p)
    local cc = getChar(p)
    return cc and cc.root
end

local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
local visCache = {}
local visible
do
local visChar = nil
function visible(p)
    local now = os.clock()
    local vc = visCache[p]
    if vc and now - vc.t < .08 then return vc.v end
    local t = partOf(p)
    local res = false
    if t then
        local me = lp.Character
        if me then
            if visChar ~= me then visChar = me rp.FilterDescendantsInstances = { me } end
            local o = cam.CFrame.Position
            local r = ws:Raycast(o, t.Position - o, rp)
            res = (not r) or r.Instance:IsDescendantOf(t.Parent)
        end
    end
    visCache[p] = { t = now, v = res }
    return res
end
end

local ownUi = {}
local function hitsOwnUi(pos)
    for _, b in ipairs(ownUi) do
        if b.Visible ~= false then
            local ap, as = b.AbsolutePosition, b.AbsoluteSize
            if pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y then return true end
        end
    end
    return false
end
local rightTouch = {}
local rightTouchN = 0
if touch then
    bind(uis.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.Touch and i.Position.X > cam.ViewportSize.X * .35 and not hitsOwnUi(i.Position) then
            if not rightTouch[i] then rightTouch[i] = true rightTouchN = rightTouchN + 1 end
        end
    end)
    bind(uis.InputChanged, function(i)
        if rightTouch[i] and (i.UserInputState == Enum.UserInputState.End or i.UserInputState == Enum.UserInputState.Cancel) then
            rightTouch[i] = nil rightTouchN = math.max(rightTouchN - 1, 0)
        end
    end)
    bind(uis.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.Touch and rightTouch[i] then
            rightTouch[i] = nil rightTouchN = math.max(rightTouchN - 1, 0)
        end
    end)
end
local function touchAimActive() return rightTouchN > 0 end

local velCache = setmetatable({}, { __mode = "k" })
local function smoothVel(p, root)
    local v = root.AssemblyLinearVelocity or Vector3.zero
    local now = os.clock()
    local e = velCache[root]
    if e and e.f == frameId then return e.v, e.a end
    if e then
        e.f = frameId
        local dtv = math.max(now - e.t, .001)
        local acc = (v - e.raw) / dtv
        if acc.Magnitude > 220 then acc = acc.Unit * 220 end
        e.a = e.a:Lerp(acc, .3)
        e.raw = v
        e.t = now
        v = e.v:Lerp(v, .35)
        e.v = v
        return v, e.a
    end
    velCache[root] = { v = v, raw = v, a = Vector3.zero, t = now, f = frameId }
    return v, Vector3.zero
end
local function predictedPos(p, part)
    if cfg.aim.pred <= 0 then return part.Position end
    local root = rootOf(p)
    local v, a
    if root then v, a = smoothVel(p, root) else v, a = part.AssemblyLinearVelocity or Vector3.zero, Vector3.zero end
    local t = cfg.aim.pred
    return part.Position + Vector3.new(v.X, 0, v.Z) * t + Vector3.new(a.X, 0, a.Z) * (t * t * .5) + Vector3.new(0, v.Y * t * .5 + a.Y * t * t * .25, 0)
end

local locked = nil
local curTarget, curPart, curPos, curTrg, curTrgP = nil, nil, nil, false, nil
local candBuf = {}
local cycSkip = nil
local rollOk = true
local silPart, silPos = nil, nil
local refreshTarget
do
local rollAt, headOk = 0, false
function refreshTarget()
    local needAim = cfg.aim.on or cfg.sil.on or cfg.aim.ragebot
    local needTrg = cfg.trg.on
    if not needAim and not needTrg then
        curTarget, curPart, curPos, curTrg, curTrgP = nil, nil, nil, false, nil
        silPart, silPos = nil, nil
        locked = nil
        cycSkip = nil
        return
    end
    local o = origin()
    local fov = cfg.aim.ragebot and 2000 or ((cfg.aim.on or cfg.aim.ragebot) and cfg.aim.fov or cfg.sil.fov)
    local best, bd, bs, lockD, trgHit, trgD = nil, math.huge, math.huge, nil, false, math.huge
    local prio = cfg.aim.prio
    local reach = math.max(fov, needTrg and cfg.trg.fov or 0)
    local cand, candN = candBuf, 0
    for _, p in ipairs(plrs:GetPlayers()) do
        if isEnemy(p) then
            local t = partOf(p)
            if t then
                local s, on = cam:WorldToViewportPoint(t.Position)
                if on and s.Z > 0 then
                    local d = (Vector2.new(s.X, s.Y) - o).Magnitude
                    if d <= reach then
                        candN = candN + 1
                        local e = cand[candN]
                        if not e then e = {} cand[candN] = e end
                        e.p, e.d = p, d
                    end
                    if needTrg then
                        local td = d
                        if cfg.trg.head then
                            local cc = getChar(p)
                            local hp2 = cc and cc.head
                            if hp2 and hp2 ~= t then
                                local s2, on2 = cam:WorldToViewportPoint(hp2.Position)
                                if on2 and s2.Z > 0 then td = (Vector2.new(s2.X, s2.Y) - o).Magnitude else td = math.huge end
                            end
                        end
                        if td <= cfg.trg.fov and td < trgD then trgD = td trgHit = true curTrgP = p end
                    end
                    if needAim and d <= fov then
                        if p == locked then lockD = d end
                        local score = d
                        if prio == "低HP" then
                            local cc = getChar(p)
                            score = (cc and cc.hum and cc.hum.Health) or 9999
                        elseif prio == "近距離" then
                            score = (t.Position - cam.CFrame.Position).Magnitude
                        end
                        if p ~= cycSkip and score < bs then best, bs, bd = p, score, d end
                    end
                end
            end
        end
    end
    if needAim and cfg.aim.sticky and locked and locked ~= best and locked ~= cycSkip and lockD and lockD <= fov * 1.5 then
        if (not best or bd > lockD * .55) and isEnemy(locked) then best = locked end
    end
    if needAim and best and cfg.aim.wall and not visible(best) then
        local nb, nd = nil, math.huge
        for i = 1, candN do
            local c = cand[i]
            if c.p ~= best and c.d <= fov and c.d < nd and visible(c.p) then nb, nd = c.p, c.d end
        end
        best = nb
    end
    if needTrg and trgHit and cfg.aim.wall then
        local anyVis, nd2 = false, math.huge
        for i = 1, candN do
            local c = cand[i]
            if c.d <= cfg.trg.fov and c.d < nd2 and visible(c.p) then anyVis = true nd2 = c.d curTrgP = c.p end
        end
        trgHit = anyVis
    end
    if os.clock() - rollAt > .12 then
        rollAt = os.clock()
        rollOk = math.random() * 100 < (cfg.sil.chance or 100)
        headOk = math.random() * 100 < (cfg.sil.headchance or 0)
    end
    curTrg = trgHit
    if not trgHit then curTrgP = nil end
    curTarget = best
    if best then
        locked = best
        curPart = partOf(best)
        curPos = curPart and predictedPos(best, curPart) or nil
        silPart, silPos = curPart, curPos
        if cfg.sil.on and headOk then
            local cc = getChar(best)
            if cc and cc.head and cc.head ~= curPart then
                silPart = cc.head
                silPos = predictedPos(best, cc.head)
            end
        end
    else
        curPart, curPos = nil, nil
        silPart, silPos = nil, nil
        locked = nil
    end
    cycSkip = nil
end
end

if not G.__rvl4_silent then
    G.__rvl4_silent = true
    G.__rvl4_state = {}
    pcall(function()
        if not (getrawmetatable and hookmetamethod and checkcaller) then return end
        local wrap = newcclosure or function(f) return f end
        local mt = getrawmetatable(game)
        local old = mt.__index
        hookmetamethod(game, "__index", wrap(function(s, k)

            if not checkcaller() and s == mouse and (k == "Hit" or k == "Target" or k == "UnitRay") then
                local c4 = G.__rvl4_cfg
                local st = G.__rvl4_state
                if c4 and c4.sil.on and st.part and st.pos and st.rollOk ~= false then
                    if k == "Hit" then return CFrame.new(st.pos) end
                    if k == "Target" then return st.part end
                    if k == "UnitRay" then
                        local co = ws.CurrentCamera.CFrame.Position
                        return Ray.new(co, (st.pos - co).Unit)
                    end
                end
            end
            return old(s, k)
        end))
    end)
end

local function targetDeflecting(p)
    if not p then return false end
    local cc = getChar(p)
    if not cc then return false end
    local tool = cc.c:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local n = string.lower(tool.Name)
    if string.find(n, "katana") or string.find(n, "shield") then
        return tool:GetAttribute("CanDeflect") ~= false
    end
    return false
end

if not G.__rvl4_namecall then
    G.__rvl4_namecall = true
    pcall(function()
        if not (getrawmetatable and hookmetamethod and checkcaller) then return end
        local wrap = newcclosure or function(f) return f end
        local mt = getrawmetatable(game)
        local oldnc = mt.__namecall
        hookmetamethod(game, "__namecall", wrap(function(s, ...)
            local method = getnamecallmethod and getnamecallmethod() or ""
            if not checkcaller() and s == ws and (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") then
                local c4 = G.__rvl4_cfg
                local st = G.__rvl4_state
                if c4 and c4.sil.on and st and st.part and st.pos and st.rollOk ~= false then
                    local cc2 = ws.CurrentCamera
                    local cp = cc2 and cc2.CFrame.Position
                    if cp then
                        local args = { ... }
                        if method == "Raycast" and typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" and (args[1] - cp).Magnitude < 6 then
                            args[2] = (st.pos - args[1]).Unit * args[2].Magnitude
                            return oldnc(s, table.unpack(args))
                        elseif method ~= "Raycast" and typeof(args[1]) == "Ray" and (args[1].Origin - cp).Magnitude < 6 then
                            local r0 = args[1]
                            args[1] = Ray.new(r0.Origin, (st.pos - r0.Origin).Unit * r0.Direction.Magnitude)
                            return oldnc(s, table.unpack(args))
                        end
                    end
                end
            end
            if not checkcaller() and s == ws.CurrentCamera and (method == "ViewportPointToRay" or method == "ScreenPointToRay") then
                local c4 = G.__rvl4_cfg
                local st = G.__rvl4_state
                if c4 and c4.sil.on and st and st.part and st.pos and st.rollOk ~= false then
                    local cp = s.CFrame.Position
                    return Ray.new(cp, (st.pos - cp).Unit * 1000)
                end
            end
            return oldnc(s, ...)
        end))
    end)
end

local fovD, tLineD = nil, nil
pcall(function()
    if Drawing then
        tLineD = Drawing.new("Line")
        tLineD.Thickness = 1
        tLineD.Color = Color3.fromRGB(255, 84, 84)
        tLineD.Transparency = .7
        tLineD.Visible = false
        fovD = Drawing.new("Circle")
        fovD.Thickness = 1
        fovD.Color = Color3.fromRGB(255, 255, 255)
        fovD.Transparency = .85
        fovD.NumSides = 64
        fovD.Filled = false
    end
end)

local afPressed = false
local flyBV, flyBG, upHeld, dnHeld
do
local lastClick = 0
local trgNext = .07
local lastTrgP = nil
local lastSafe, lastSafeAt = nil, 0
local MELEE = { "katana", "scythe", "fist", "shield", "knife" }
local function myMelee()
    local c = lp.Character
    local tool = c and c:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local n = string.lower(tool.Name)
    for _, w in ipairs(MELEE) do if string.find(n, w) then return true end end
    return false
end

bind(run.RenderStepped, function(dt)
    if not alive() then return end
    frameId = frameId + 1
    dt = math.clamp(dt or .016, .001, .1)

    refreshTarget()
    if G.__rvl4_state then G.__rvl4_state.part = silPart G.__rvl4_state.pos = silPos G.__rvl4_state.rollOk = rollOk end


    if cfg.aim.on and curPart and curPos then
        local aiming = cfg.aim.ragebot or cfg.aim.always or touch and touchAimActive() or (not touch and uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
        if aiming then
            local s = cfg.aim.ragebot and math.max(cfg.aim.sm, .85) or cfg.aim.sm
            s = math.clamp(s, .02, 1)
            local a = 1 - (1 - s) ^ (dt * 60)
            if (curPos - cam.CFrame.Position).Magnitude > .25 then
                local goal = CFrame.new(cam.CFrame.Position, curPos)
                cam.CFrame = cam.CFrame:Lerp(goal, a)
            end
        end
    end


    if cfg.trg.on and curTrg and not targetDeflecting(curTrgP) and not myMelee() and (cfg.trg.mode ~= "単発" or curTrgP ~= lastTrgP) and os.clock() - lastClick >= trgNext then
        local gate
        if touch then gate = touchAimActive()
        else gate = not cfg.trg.ads or uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
        if gate then
            lastClick = os.clock()
            lastTrgP = curTrgP
            local base = (cfg.trg.delay or 70) / 1000
            trgNext = base
            pcall(function() if mouse1click then mouse1click() end end)
        end
    end
    if not curTrg then lastTrgP = nil end


    local fireWant = false
    if curTarget and not targetDeflecting(curTarget) and not myMelee() then
        if cfg.aim.ragebot then
            fireWant = not cfg.aim.wall or visible(curTarget)
        elseif cfg.combat.auto then
            if touch then fireWant = touchAimActive()
            else fireWant = uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
        end
    end
    if fireWant and not afPressed and mouse1press then
        afPressed = true pcall(function() mouse1press() end)
    elseif not fireWant and afPressed then
        afPressed = false pcall(function() if mouse1release then mouse1release() end end)
    end


    if fovD then
        fovD.Visible = cfg.aim.on or cfg.sil.on or cfg.aim.ragebot
        fovD.Position = origin()
        fovD.Radius = (cfg.aim.on or cfg.aim.ragebot) and cfg.aim.fov or cfg.sil.fov
        fovD.Color = curTarget and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 255, 255)
    end


    if tLineD then
        if cfg.esp.tline and curPart and (cfg.aim.on or cfg.sil.on) then
            local s, on = cam:WorldToViewportPoint(curPart.Position)
            if on and s.Z > 0 then
                tLineD.Visible = true
                tLineD.From = origin()
                tLineD.To = Vector2.new(s.X, s.Y)
            else
                tLineD.Visible = false
            end
        else
            tLineD.Visible = false
        end
    end


    if cfg.fly.on and flyBV and flyBG then
        local c = lp.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h then
            local look = cam.CFrame.LookVector
            local right = cam.CFrame.RightVector
            local f, r, u = 0, 0, 0
            if touch then
                local md = h.MoveDirection
                local horiz = Vector3.new(md.X, 0, md.Z)
                local vert = ((upHeld and 1 or 0) - (dnHeld and 1 or 0)) * cfg.fly.spd
                flyBV.Velocity = flyBV.Velocity:Lerp(horiz * cfg.fly.spd + Vector3.new(0, vert, 0), 1 - math.exp(-dt * 10))
                flyBG.CFrame = cam.CFrame
            else
                if uis:IsKeyDown(Enum.KeyCode.W) then f = f + 1 end
                if uis:IsKeyDown(Enum.KeyCode.S) then f = f - 1 end
                if uis:IsKeyDown(Enum.KeyCode.A) then r = r - 1 end
                if uis:IsKeyDown(Enum.KeyCode.D) then r = r + 1 end
                if uis:IsKeyDown(Enum.KeyCode.Space) then u = u + 1 end
                if uis:IsKeyDown(Enum.KeyCode.LeftShift) then u = u - 1 end
                if upHeld then u = u + 1 end
                if dnHeld then u = u - 1 end
                local dir = look * f + right * r + Vector3.new(0, u, 0)
                if dir.Magnitude > 1 then dir = dir.Unit end
                flyBV.Velocity = flyBV.Velocity:Lerp(dir * cfg.fly.spd, 1 - math.exp(-dt * 10))
                flyBG.CFrame = cam.CFrame
            end
        end
    end



    if cfg.void.on then
        local mc = lp.Character
        local mr = mc and (mc:FindFirstChild("HumanoidRootPart") or mc:FindFirstChild("Torso"))
        local mh = mc and mc:FindFirstChildOfClass("Humanoid")
        if mr and mh then
            if mh.FloorMaterial ~= Enum.Material.Air and mr.Position.Y > -40 then
                if os.clock() - lastSafeAt > .5 then lastSafe, lastSafeAt = mr.Position, os.clock() end
            elseif mr.Position.Y < -100 and lastSafe and (lastSafe - mr.Position).Magnitude < 1500 then
                mr.Position = lastSafe + Vector3.new(0, 3, 0)
                mr.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end

    if cfg.camf.on then cam.FieldOfView = cfg.camf.val end
end)
end

local function setFly(on)
    local c = lp.Character
    local r = c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
    if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
    if on and r then
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = r
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBG.P = 8000
        flyBG.Parent = r
    end
end

local hlCache = {}
local bbCache = {}

local function makeBB(p)
    local c = p.Character
    local head = c and c:FindFirstChild("Head")
    if not head then return end
    if bbCache[p] then pcall(function() bbCache[p].gui:Destroy() end) end
    local g = Instance.new("BillboardGui")
    g.Name = "rvl_bb"
    g.Size = UDim2.new(0, 150, 0, 42)
    g.StudsOffset = Vector3.new(0, 2.8, 0)
    g.AlwaysOnTop = true
    g.MaxDistance = cfg.esp.max
    g.Adornee = head
    g.Enabled = false
    g.Parent = head
    local nm = Instance.new("TextLabel")
    nm.BackgroundTransparency = 1
    nm.Size = UDim2.new(1, 0, 0, 16)
    nm.Font = Enum.Font.BuilderSansBold
    nm.TextSize = 12
    nm.TextStrokeTransparency = .4
    nm.TextColor3 = Color3.fromRGB(255, 255, 255)
    nm.Parent = g
    local wp = Instance.new("TextLabel")
    wp.BackgroundTransparency = 1
    wp.Position = UDim2.new(0, 0, 0, 16)
    wp.Size = UDim2.new(1, 0, 0, 14)
    wp.Font = Enum.Font.BuilderSans
    wp.TextSize = 11
    wp.TextColor3 = Color3.fromRGB(210, 210, 210)
    wp.TextStrokeTransparency = .5
    wp.Parent = g
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 60, 0, 4)
    bg.Position = UDim2.new(.5, -30, 1, -4)
    bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    bg.BorderSizePixel = 0
    bg.Parent = g
    local fg = Instance.new("Frame")
    fg.Size = UDim2.new(1, 0, 1, 0)
    fg.BackgroundColor3 = Color3.fromRGB(0, 255, 110)
    fg.BorderSizePixel = 0
    fg.Parent = bg
    bbCache[p] = { gui = g, name = nm, wp = wp, bar = fg, head = head, bg = bg }
end

local function espTick()
    for _, p in ipairs(plrs:GetPlayers()) do
        if p == lp then

        else
            local c = p.Character
            local enemy = c and cfg.esp.on and isEnemy(p)

            local h = hlCache[p]
            if c and enemy and cfg.esp.chams then
                if not h or h.Parent ~= c then
                    if h then pcall(function() h:Destroy() end) end
                    h = Instance.new("Highlight")
                    h.Name = "rvl"
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.FillColor = Color3.fromRGB(255, 70, 70)
                    h.OutlineColor = Color3.fromRGB(255, 160, 160)
                    h.FillTransparency = .55
                    h.Parent = c
                    hlCache[p] = h
                end
                h.Enabled = true
            elseif h then
                h.Enabled = false
            end

            local cc = c and getChar(p)
            local head = cc and cc.head
            local b = bbCache[p]
            if not c or not head then
                if b then b.gui.Enabled = false end
            else
                if not b or b.head ~= head or not b.gui.Parent then makeBB(p) b = bbCache[p] end
                if b then
                    local hum = cc and cc.hum
                    local dist = (head.Position - cam.CFrame.Position).Magnitude
                    local show = enemy and hum and hum.Health > 0 and dist <= cfg.esp.max
                    b.gui.Enabled = show and true or false
                    b.gui.MaxDistance = cfg.esp.max
                    if show then
                        local tool = c:FindFirstChildOfClass("Tool")
                        local nameTxt = cfg.esp.name and (p.DisplayName ~= "" and p.DisplayName or p.Name) or ""
                        if cfg.esp.dist then nameTxt = nameTxt .. " [" .. math.floor(dist) .. "]" end
                        if b._n ~= nameTxt then b._n = nameTxt b.name.Text = nameTxt end
                        local wpTxt = cfg.esp.wp and (tool and tool.Name or "") or ""
                        if b._w ~= wpTxt then b._w = wpTxt b.wp.Text = wpTxt end
                        if b._h ~= cfg.esp.hp then b._h = cfg.esp.hp b.bg.Visible = cfg.esp.hp end
                        local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        if not b._f or math.abs(b._f - frac) > .01 then
                            b._f = frac
                            b.bar.Size = UDim2.new(frac, 0, 1, 0)
                            b.bar.BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - frac)), math.floor(255 * frac), 40)
                        end
                        local wantH = cfg.esp.hp and 42 or 34
                        if b._s ~= wantH then b._s = wantH b.gui.Size = UDim2.new(0, 150, 0, wantH) end
                    end
                end
            end
        end
    end
end

local dc = {}
local killDraw
do
local r15 = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local r6 = {
    { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
    { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}
local UP3, DN3 = Vector3.new(0, 3, 0), Vector3.new(0, -3, 0)
local function makeDraw()
    local d = {}
    d.box = Drawing.new("Square") d.box.Thickness = 1 d.box.Filled = false
    d.dist = Drawing.new("Text") d.dist.Size = 12 d.dist.Center = true d.dist.Outline = true
    d.trc = Drawing.new("Line") d.trc.Thickness = 1
    d.bones = {}
    for i = 1, 16 do
        local l = Drawing.new("Line")
        l.Thickness = 1 l.Transparency = .65
        d.bones[i] = l
    end
    return d
end
killDraw = function(p)
    local d = dc[p]
    if not d then return end
    for _, v in pairs(d) do
        if type(v) == "table" then
            for _, o in ipairs(v) do pcall(function() o:Remove() end) end
        else
            pcall(function() v:Remove() end)
        end
    end
    dc[p] = nil
end
local function hideDraw(d)
    d.box.Visible = false d.dist.Visible = false d.trc.Visible = false
    for _, l in ipairs(d.bones) do l.Visible = false end
end
local function drawTick()
    for _, p in ipairs(plrs:GetPlayers()) do
        if p == lp then
            if dc[p] then killDraw(p) end
        else
            local d = dc[p]
            if not d then d = makeDraw() dc[p] = d end
            local c = p.Character
            local r = c and rootOf(p)
            local show = cfg.esp.on and r and isEnemy(p)
            local dist = 0
            if show then
                dist = (r.Position - cam.CFrame.Position).Magnitude
                if dist > cfg.esp.max then show = false end
            end
            if show then
                local t, ton = cam:WorldToViewportPoint(r.Position + UP3)
                local b, bon = cam:WorldToViewportPoint(r.Position + DN3)
                if ton and bon and t.Z > 0 and b.Z > 0 then
                    local hgt = math.abs(b.Y - t.Y)
                    local wid = math.max(hgt * .6, 22)
                    local x = t.X - wid / 2
                    local y = t.Y
                    d.box.Visible = cfg.esp.box
                    d.box.Size = Vector2.new(wid, hgt)
                    d.box.Position = Vector2.new(x, y)
                    d.box.Color = Color3.fromRGB(255, 70, 70)
                    d.dist.Visible = cfg.esp.dist
                    d.dist.Text = "[" .. math.floor(dist) .. "]"
                    d.dist.Position = Vector2.new(x + wid / 2, y + hgt + 2)
                    d.dist.Color = Color3.fromRGB(230, 230, 230)
                    d.trc.Visible = cfg.esp.trc
                    d.trc.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                    d.trc.To = Vector2.new(x + wid / 2, y + hgt)
                    d.trc.Color = Color3.fromRGB(255, 70, 70)
                    if cfg.esp.skel then
                        local pairsList = c:FindFirstChild("UpperTorso") and r15 or r6
                        for idx, pair in ipairs(pairsList) do
                            local l = d.bones[idx]
                            local drawn = false
                            local a = c:FindFirstChild(pair[1])
                            local b2 = c:FindFirstChild(pair[2])
                            if l and a and b2 then
                                local s1, o1 = cam:WorldToViewportPoint(a.Position)
                                local s2, o2 = cam:WorldToViewportPoint(b2.Position)
                                if o1 and o2 and s1.Z > 0 and s2.Z > 0 then
                                    l.Visible = true
                                    l.From = Vector2.new(s1.X, s1.Y)
                                    l.To = Vector2.new(s2.X, s2.Y)
                                    l.Color = Color3.fromRGB(255, 140, 140)
                                    drawn = true
                                end
                            end
                            if l and not drawn then l.Visible = false end
                        end
                        for j = #pairsList + 1, #d.bones do d.bones[j].Visible = false end
                    else
                        for _, l in ipairs(d.bones) do l.Visible = false end
                    end
                else
                    hideDraw(d)
                end
            else
                hideDraw(d)
            end
        end
    end
end
if Drawing then
    bind(run.RenderStepped, function() if alive() then drawTick() end end)
end
end

bind(plrs.PlayerRemoving, function(p)
    if hlCache[p] then pcall(function() hlCache[p]:Destroy() end) hlCache[p] = nil end
    if bbCache[p] then pcall(function() bbCache[p].gui:Destroy() end) bbCache[p] = nil end
    if dc[p] then killDraw(p) end
    spawnPos[p] = nil
    spawnAt[p] = nil
    charCache[p] = nil
    visCache[p] = nil
    if locked == p then locked = nil end
end)

local nocOrig = {}
local noclipTick
do
local nocParts, nocPartsAt, nocChar = nil, 0, nil
function noclipTick()
    local c = lp.Character
    if not c then return end
    if cfg.noc then
        if nocChar ~= c or not nocParts or os.clock() - nocPartsAt > 1 then
            nocChar, nocParts, nocPartsAt = c, {}, os.clock()
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then table.insert(nocParts, p) end
            end
        end
        for _, p in ipairs(nocParts) do
            if p.Parent then
                if nocOrig[p] == nil then nocOrig[p] = p.CanCollide end
                if p.CanCollide then p.CanCollide = false end
            end
        end
    elseif next(nocOrig) then
        for part, v in pairs(nocOrig) do pcall(function() part.CanCollide = v end) end
        nocOrig = {}
    end
end
end
local resetMove
local moveTick
do
local spdWas, spdDef = false, 16
local bhopAt = 0
local jmpWas, jmpDef, jmpUseDef = false, 50, true
function moveTick()
    local c = lp.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if not h then return end
    if cfg.spd.on then
        if not spdWas then spdDef = (h.WalkSpeed ~= cfg.spd.val) and h.WalkSpeed or 16 spdWas = true end
        if h.WalkSpeed ~= cfg.spd.val then h.WalkSpeed = cfg.spd.val end
    elseif spdWas then
        spdWas = false
        pcall(function() h.WalkSpeed = spdDef end)
    end
    if cfg.jmp.on then
        if not jmpWas then jmpDef = h.JumpPower jmpUseDef = h.UseJumpPower jmpWas = true end
        h.UseJumpPower = true
        if h.JumpPower ~= cfg.jmp.val then h.JumpPower = cfg.jmp.val end
    elseif jmpWas then
        jmpWas = false
        pcall(function() h.JumpPower = jmpDef h.UseJumpPower = jmpUseDef end)
    end
    if cfg.bhop then
        local now = os.clock()
        if now - bhopAt > .05 and h.FloorMaterial ~= Enum.Material.Air and h.MoveDirection.Magnitude > .1 then
            local want = touch or uis:IsKeyDown(Enum.KeyCode.Space)
            if want then bhopAt = now h.Jump = true end
        end
    end
end
function resetMove() spdWas, jmpWas = false, false end
end
bind(run.Stepped, function() if alive() then noclipTick() end end)
bind(run.Heartbeat, function() if alive() then moveTick() end end)
bind(uis.JumpRequest, function()
    if not alive() or not cfg.infj then return end
    local c = lp.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
end)

local hbOrig = {}
local hbOwner = {}
local function restoreHB()
    for part, o in pairs(hbOrig) do
        pcall(function()
            part.Size = o.s part.Transparency = o.t part.CanCollide = o.c
        end)
    end
    hbOrig = {}
    hbOwner = {}
end
local function hbTick()
    if not cfg.hb.on then
        if next(hbOrig) then restoreHB() end
        return
    end
    for _, p in ipairs(plrs:GetPlayers()) do
        if p ~= lp and isEnemy(p) then
            local cc = getChar(p)
            if cc then
                local plist = { cc.head, cc.root }
                if cfg.hb.part == "頭" then plist = { cc.head } elseif cfg.hb.part == "胴体" then plist = { cc.root } end
                for _, part in ipairs(plist) do
                    if part then
                        if not hbOrig[part] then
                            hbOrig[part] = { s = part.Size, t = part.Transparency, c = part.CanCollide }
                            hbOwner[part] = p
                        end
                        local sz = Vector3.new(cfg.hb.size, cfg.hb.size, cfg.hb.size)
                        if part.Size ~= sz then part.Size = sz end
                        part.Transparency = .6
                        part.CanCollide = false
                    end
                end
            end
        end
    end
    for part, o in pairs(hbOrig) do
        local owner = hbOwner[part]
        local want = true
        if owner then
            local cc2 = getChar(owner)
            if cc2 then
                if cfg.hb.part == "頭" and part == cc2.root then want = false end
                if cfg.hb.part == "胴体" and part == cc2.head then want = false end
            end
        end
        if not owner or not isEnemy(owner) or not want then
            pcall(function()
                part.Size = o.s part.Transparency = o.t part.CanCollide = o.c
            end)
            hbOrig[part] = nil
            hbOwner[part] = nil
        end
    end
end

local function combatTick()
    if cfg.combat.norecoil or cfg.combat.nospread then
        local c = lp.Character
        if c then
            for _, tool in ipairs(c:GetChildren()) do
                if tool:IsA("Tool") then
                    if cfg.combat.norecoil and tool:GetAttribute("Recoil") ~= 0 then
                        pcall(function() tool:SetAttribute("Recoil", 0) end)
                    end
                    if cfg.combat.nospread and tool:GetAttribute("Spread") ~= 0 then
                        pcall(function() tool:SetAttribute("Spread", 0) end)
                    end
                end
            end
        end
    end
end
local modsTick
local modStatTx
local probeLib
do
local wlib, wstats = nil, nil
local worig = {}
local wNextTry = 0
local WKEYS = { "ShootRecoil", "ShootSpread", "AimSpreadMultiplier", "ShootCooldown", "ReloadLength", "EmptyReloadLength", "EquipCooldown", "MaxAmmo", "MaxAmmoReserve", "Recoil", "Spread" }
local function collectStats(t, depth, out, seen)
    if type(t) ~= "table" or depth > 3 or seen[t] then return end
    seen[t] = true
    local has = false
    for _, k in ipairs(WKEYS) do if type(t[k]) == "number" then has = true break end end
    if has then table.insert(out, t) end
    for _, v in pairs(t) do
        if type(v) == "table" then collectStats(v, depth + 1, out, seen) end
    end
end
local lastModStat = ""
local function setModStat(txt)
    if txt == lastModStat then return end
    lastModStat = txt
    if modStatTx then pcall(function() modStatTx.Text = txt end) end
end
local function findLib()
    if wlib then return true end
    local now = os.clock()
    if now < wNextTry then return false end
    wNextTry = now + 5
    local cand = nil
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        for _, nm in ipairs({ "ItemLibrary", "ItemData", "WeaponData", "GunLibrary", "WeaponLibrary", "ItemDB", "Weapons" }) do
            local f = rs:FindFirstChild(nm, true)
            if f and f:IsA("ModuleScript") then cand = f break end
        end
        if not cand then
            pcall(function()
                local rf = game:GetService("ReplicatedFirst")
                for _, v in ipairs(rf:GetDescendants()) do
                    if v:IsA("ModuleScript") and string.find(v.Name, "ItemLibrary") then cand = v break end
                end
            end)
        end
        if not cand then
            for _, v in ipairs(rs:GetDescendants()) do
                if v:IsA("ModuleScript") and string.find(v.Name, "ItemLibrary") then cand = v break end
            end
        end
    end)
    if cand then pcall(function() wlib = require(cand) end) end
    if not wlib and getloadedmodules then
        pcall(function()
            for _, m in ipairs(getloadedmodules()) do
                if string.find(m.Name, "ItemLibrary") then wlib = require(m) break end
            end
        end)
    end
    if type(wlib) == "table" then
        local out = {}
        collectStats(wlib, 0, out, {})
        if #out > 0 then wstats = out return true end
    end
    wlib, wstats = nil, nil
    return false
end
local function wstore(t, k)
    local per = worig[t]
    if not per then per = {} worig[t] = per end
    if per[k] == nil then per[k] = t[k] end
    return per[k]
end
local function wset(t, k, v)
    if type(t[k]) ~= "number" then return end
    wstore(t, k)
    t[k] = v
end
local function modsActive()
    local c = cfg.combat
    return c.norecoil or c.nospread or c.rapid or c.reload or c.equip or c.ammo
end
function modsTick()
    if not modsActive() then
        if next(worig) then
            for t, per in pairs(worig) do
                for k, v in pairs(per) do pcall(function() t[k] = v end) end
            end
            worig = {}
        end
        setModStat("武器MOD: 待機中")
        return
    end
    if not findLib() then setModStat("武器MOD: ライブラリ未検出") return end
    local c = cfg.combat
    for _, t in ipairs(wstats) do
        if c.norecoil then wset(t, "ShootRecoil", 0) wset(t, "Recoil", 0) end
        if c.nospread then wset(t, "ShootSpread", 0) wset(t, "AimSpreadMultiplier", 0) wset(t, "Spread", 0) end
        if c.rapid and type(t.ShootCooldown) == "number" then t.ShootCooldown = wstore(t, "ShootCooldown") * .4 end
        if c.reload then wset(t, "ReloadLength", .01) wset(t, "EmptyReloadLength", .01) end
        if c.equip then wset(t, "EquipCooldown", .01) end
        if c.ammo then wset(t, "MaxAmmo", 9999) wset(t, "MaxAmmoReserve", 9999) end
    end
    setModStat("武器MOD: 適用中 (" .. #wstats .. "種)")
end
probeLib = function() return findLib() end
end

local baseShadow = lt.GlobalShadows
local function syncShadows()
    if cfg.vis.fb or cfg.fpsb then lt.GlobalShadows = false else lt.GlobalShadows = baseShadow end
end
local applyFps
do
local fpsOrig = nil
local fpsParts = {}
function applyFps()
    if cfg.fpsb then
        if fpsOrig then return end
        fpsOrig = true
        syncShadows()
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        task.spawn(function()
            for _, v in ipairs(ws:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                    if cfg.fpsb then table.insert(fpsParts, { v, v.Enabled }) v.Enabled = false end
                end
            end
        end)
    elseif fpsOrig then
        syncShadows()
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
        for _, pr in ipairs(fpsParts) do pcall(function() pr[1].Enabled = pr[2] end) end
        fpsParts = {}
        fpsOrig = nil
    end
end
end

local applyVis
do
local oAmb, oBri, oFogS, oFogE, oOut
function applyVis()
    if cfg.vis.fb then
        if not oAmb then oAmb = lt.Ambient oBri = lt.Brightness oOut = lt.OutdoorAmbient end
        lt.Ambient = Color3.fromRGB(180, 180, 180)
        lt.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        lt.Brightness = 2
        syncShadows()
    elseif oAmb then
        lt.Ambient = oAmb lt.Brightness = oBri lt.OutdoorAmbient = oOut oAmb = nil
        syncShadows()
    end
    if cfg.vis.nf then
        if not oFogE then oFogE = lt.FogEnd oFogS = lt.FogStart end
        lt.FogEnd = 1e9 lt.FogStart = 1e9
    elseif oFogE then
        lt.FogEnd = oFogE lt.FogStart = oFogS oFogE = nil
    end
end
end

task.spawn(function()
    while alive() do
        task.wait(touch and .15 or .1)
        if not alive() then break end
        pcall(espTick)
    end
end)
local afkClock = os.clock()
bind(uis.InputBegan, function() afkClock = os.clock() end)
task.spawn(function()
    local vu = game:GetService("VirtualUser")
    while alive() do
        task.wait(30)
        if not alive() then break end
        if cfg.afk and os.clock() - afkClock > 540 then
            afkClock = os.clock()
            pcall(function() vu:CaptureController() vu:ClickButton2(Vector2.new(0, 0)) end)
        end
    end
end)
task.spawn(function()
    while alive() do
        task.wait(.3)
        if not alive() then break end
        local nc = ws.CurrentCamera
        if nc and nc ~= cam then cam = nc end
        pcall(hbTick)
        pcall(combatTick)
        pcall(modsTick)
        pcall(applyFps)
        pcall(applyVis)
    end
end)

bind(lp.CharacterAdded, function()
    task.wait(.4)
    if not alive() then return end
    if cfg.fly.on then setFly(true) end
    nocOrig = {}
    resetMove()
end)

local tws = game:GetService("TweenService")
local function tw(obj, props, t)
    pcall(function()
        tws:Create(obj, TweenInfo.new(t or .18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end)
end

local C = {
    bg      = Color3.fromRGB(12, 12, 15),
    sidebar = Color3.fromRGB(16, 16, 20),
    card    = Color3.fromRGB(22, 22, 27),
    cardHi  = Color3.fromRGB(28, 28, 34),
    hover   = Color3.fromRGB(28, 28, 35),
    stroke  = Color3.fromRGB(38, 38, 46),
    text    = Color3.fromRGB(242, 242, 244),
    sub     = Color3.fromRGB(148, 148, 160),
    faint   = Color3.fromRGB(96, 96, 108),
    accent  = Color3.fromRGB(245, 245, 247),
    accentTx = Color3.fromRGB(12, 12, 14),
    track   = Color3.fromRGB(44, 44, 54),
    danger  = Color3.fromRGB(198, 74, 74),
    ok      = Color3.fromRGB(74, 190, 120),
    warn    = Color3.fromRGB(255, 84, 84),
}
local function corner(obj, r)
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 8) c.Parent = obj return c
end
local function stroke(obj, col, th)
    local s = Instance.new("UIStroke") s.Color = col or C.stroke s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border s.Parent = obj return s
end

local ui, main, side, pages, divV, statDot, statTx, fpsTx, minB, closeB, shadow, W, H, bar
local xhair, xhParts
do
local pg = lp:WaitForChild("PlayerGui")
local prev = pg:FindFirstChild("rvl_ui")
if prev then prev:Destroy() end

ui = Instance.new("ScreenGui")
ui.Name = "rvl_ui" ui.ResetOnSpawn = false ui.IgnoreGuiInset = true ui.DisplayOrder = 100
ui.Parent = pg

W = touch and math.min(384, cam.ViewportSize.X * .96) or 596
H = touch and math.min(560, cam.ViewportSize.Y * .8) or 408
local SBW = touch and 92 or 138
local ROWH = touch and 48 or 42

shadow = Instance.new("Frame")
shadow.Size = UDim2.new(0, W, 0, H) shadow.Position = UDim2.new(0, 18, 0, 22)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0) shadow.BackgroundTransparency = .45
shadow.BorderSizePixel = 0 shadow.Parent = ui
corner(shadow, 16)

main = Instance.new("Frame")
main.Size = UDim2.new(0, W, 0, H) main.Position = UDim2.new(0, 14, 0, 14)
main.BackgroundColor3 = C.bg main.BorderSizePixel = 0 main.Active = true
main.Parent = ui
table.insert(ownUi, main)
corner(main, 16) stroke(main)
local wg = Instance.new("UIGradient")
wg.Rotation = 90
wg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 27, 33)), ColorSequenceKeypoint.new(.45, Color3.fromRGB(16, 16, 20)), ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 13)) })
wg.Parent = main
local sheen = Instance.new("Frame")
sheen.Size = UDim2.new(1, -36, 0, 1) sheen.Position = UDim2.new(0, 18, 0, 0)
sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255) sheen.BackgroundTransparency = .88
sheen.BorderSizePixel = 0 sheen.ZIndex = 6 sheen.Parent = main

bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 54) bar.BackgroundTransparency = 1 bar.BorderSizePixel = 0 bar.Parent = main

local logo = Instance.new("Frame")
logo.Size = UDim2.new(0, 30, 0, 30) logo.Position = UDim2.new(0, 14, 0, 12)
logo.BackgroundColor3 = Color3.fromRGB(24, 24, 30) logo.BorderSizePixel = 0 logo.Parent = bar
corner(logo, 9) stroke(logo)
local lg = Instance.new("UIGradient")
lg.Rotation = 90
lg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 34, 42)), ColorSequenceKeypoint.new(1, Color3.fromRGB(17, 17, 21)) })
lg.Parent = logo
local ring = Instance.new("Frame")
ring.Size = UDim2.new(0, 16, 0, 16) ring.AnchorPoint = Vector2.new(.5, .5) ring.Position = UDim2.new(.5, 0, .5, 0)
ring.BackgroundTransparency = 1 ring.BorderSizePixel = 0 ring.Parent = logo
corner(ring, 8)
local rst = Instance.new("UIStroke")
rst.Color = C.accent rst.Thickness = 2 rst.Parent = ring
local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 4, 0, 4) dot.AnchorPoint = Vector2.new(.5, .5) dot.Position = UDim2.new(.5, 0, .5, 0)
dot.BackgroundColor3 = C.accent dot.BorderSizePixel = 0 dot.Parent = logo
corner(dot, 2)
local function tick(w, h, x, y)
    local t2 = Instance.new("Frame")
    t2.Size = UDim2.new(0, w, 0, h) t2.AnchorPoint = Vector2.new(.5, .5) t2.Position = UDim2.new(.5, x, .5, y)
    t2.BackgroundColor3 = C.accent t2.BorderSizePixel = 0 t2.Parent = logo
    corner(t2, 1)
    return t2
end
tick(2, 5, 0, -11) tick(2, 5, 0, 11) tick(5, 2, -11, 0) tick(5, 2, 11, 0)

local ttl = Instance.new("TextLabel")
ttl.Size = UDim2.new(0, 330, 0, 20) ttl.Position = UDim2.new(0, 54, 0, 17) ttl.BackgroundTransparency = 1
ttl.Text = "discord@kurudojindegomen" ttl.TextColor3 = C.text ttl.Font = Enum.Font.BuilderSansBold
ttl.TextSize = 15 ttl.TextXAlignment = Enum.TextXAlignment.Left ttl.Parent = bar

local function topBtn(txt, x, col, txcol)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, touch and 34 or 30, 0, touch and 34 or 30) b.Position = UDim2.new(1, x, 0, touch and 10 or 12) b.BackgroundColor3 = col
    b.BorderSizePixel = 0 b.Text = txt b.TextColor3 = txcol or C.sub b.Font = Enum.Font.BuilderSansBold
    b.TextSize = 14 b.AutoButtonColor = false b.Parent = bar
    corner(b, 9) stroke(b)
    return b
end
closeB = topBtn("×", -44, C.card, C.sub)
minB = topBtn("–", -82, C.card, C.sub)

local divH = Instance.new("Frame")
divH.Size = UDim2.new(1, 0, 0, 1) divH.Position = UDim2.new(0, 0, 0, 54)
divH.BackgroundColor3 = C.stroke divH.BorderSizePixel = 0 divH.Parent = main

side = Instance.new("Frame")
side.Size = UDim2.new(0, SBW, 1, -55) side.Position = UDim2.new(0, 0, 0, 55)
side.BackgroundColor3 = C.sidebar side.BorderSizePixel = 0 side.Parent = main
local sbg = Instance.new("UIGradient")
sbg.Rotation = 90
sbg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(21, 21, 26)), ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 15)) })
sbg.Parent = side
local sideLay = Instance.new("UIListLayout")
sideLay.Padding = UDim.new(0, 4) sideLay.SortOrder = Enum.SortOrder.LayoutOrder sideLay.Parent = side
local sidePad = Instance.new("UIPadding")
sidePad.PaddingTop = UDim.new(0, 12) sidePad.PaddingLeft = UDim.new(0, 10)
sidePad.PaddingRight = UDim.new(0, 10) sidePad.Parent = side
divV = Instance.new("Frame")
divV.Size = UDim2.new(0, 1, 1, -55) divV.Position = UDim2.new(0, SBW, 0, 55)
divV.BackgroundColor3 = C.stroke divV.BorderSizePixel = 0 divV.Parent = main

statDot = Instance.new("Frame")
statDot.Size = UDim2.new(0, 7, 0, 7) statDot.Position = UDim2.new(0, 16, 1, -30)
statDot.BackgroundColor3 = C.faint statDot.BorderSizePixel = 0 statDot.Parent = main
corner(statDot, 4)
statTx = Instance.new("TextLabel")
statTx.Size = UDim2.new(0, SBW - 28, 0, 14) statTx.Position = UDim2.new(0, 29, 1, -34)
statTx.BackgroundTransparency = 1 statTx.Text = "待機中" statTx.TextColor3 = C.sub
statTx.Font = Enum.Font.BuilderSans statTx.TextSize = 11 statTx.TextXAlignment = Enum.TextXAlignment.Left statTx.Parent = main
fpsTx = Instance.new("TextLabel")
fpsTx.Size = UDim2.new(0, 44, 0, 14) fpsTx.Position = UDim2.new(0, SBW - 56, 1, -54) fpsTx.BackgroundTransparency = 1
fpsTx.Text = "" fpsTx.TextColor3 = C.faint fpsTx.Font = Enum.Font.BuilderSans fpsTx.TextSize = 10
fpsTx.TextXAlignment = Enum.TextXAlignment.Right fpsTx.Parent = main

pages = Instance.new("Frame")
pages.Size = UDim2.new(1, -SBW - 1, 1, -55) pages.Position = UDim2.new(0, SBW + 1, 0, 55)
pages.BackgroundTransparency = 1 pages.BorderSizePixel = 0 pages.ClipsDescendants = true pages.Parent = main

local refreshers = {}
local function refreshAll()
    for _, fn in ipairs(refreshers) do pcall(fn) end
end
local savePend = false
local function markDirty()
    if savePend then return end
    savePend = true
    task.delay(1, function()
        savePend = false
        if alive() then save() end
    end)
end

local tabs = {}
local curTab = nil
local curPage = nil
local ord = 0
local tabOrder = 0

local function selectTab(id)
    curTab = id
    for tid, t in pairs(tabs) do
        local on = (tid == id)
        t.page.Visible = on
        tw(t.btn, { BackgroundColor3 = on and C.accent or C.sidebar })
        t.btn.TextColor3 = on and C.accentTx or C.sub
        if t.grad then t.grad.Enabled = on end
        if on then curPage = t.page ord = 0 end
    end
end

local function createTab(id, label)
    tabOrder = tabOrder + 1
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, touch and 40 or 34) b.BackgroundColor3 = C.sidebar b.BorderSizePixel = 0
    b.Text = label b.TextColor3 = C.sub b.Font = Enum.Font.BuilderSansBold
    b.TextSize = touch and 12 or 13 b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false b.LayoutOrder = tabOrder b.Parent = side
    corner(b, 8)
    local tg = Instance.new("UIGradient")
    tg.Rotation = 0
    tg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(206, 206, 216)) })
    tg.Enabled = false tg.Parent = b
    b.MouseEnter:Connect(function() if curTab ~= id then b.TextColor3 = C.text end end)
    b.MouseLeave:Connect(function() if curTab ~= id then b.TextColor3 = C.sub end end)
    local bp = Instance.new("UIPadding") bp.PaddingLeft = UDim.new(0, 12) bp.Parent = b

    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0) p.BackgroundTransparency = 1 p.BorderSizePixel = 0
    p.ScrollBarThickness = 3 p.ScrollBarImageColor3 = C.faint p.ScrollBarImageTransparency = .35
    p.CanvasSize = UDim2.new(0, 0, 0, 0) p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Visible = false p.Parent = pages
    local pl = Instance.new("UIListLayout") pl.Padding = UDim.new(0, 6) pl.SortOrder = Enum.SortOrder.LayoutOrder pl.Parent = p
    local pp = Instance.new("UIPadding")
    pp.PaddingTop = UDim.new(0, 12) pp.PaddingBottom = UDim.new(0, 12)
    pp.PaddingLeft = UDim.new(0, 12) pp.PaddingRight = UDim.new(0, 12) pp.Parent = p

    tabs[id] = { btn = b, page = p, grad = tg }
    b.Activated:Connect(function() selectTab(id) end)
    return p
end

local function sec(t)
    ord = ord + 1
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 16) f.BackgroundTransparency = 1 f.BorderSizePixel = 0
    f.LayoutOrder = ord f.Parent = curPage
    local accBar = Instance.new("Frame")
    accBar.Size = UDim2.new(0, 3, 0, 10) accBar.Position = UDim2.new(0, 1, .5, -5)
    accBar.BackgroundColor3 = C.accent accBar.BorderSizePixel = 0 accBar.Parent = f
    corner(accBar, 2)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 1, 0) l.Position = UDim2.new(0, 10, 0, 0) l.BackgroundTransparency = 1 l.Text = t
    l.TextColor3 = C.sub l.Font = Enum.Font.BuilderSansBold l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = f
end

local function rowBase(h)
    ord = ord + 1
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, h) f.BackgroundColor3 = C.card f.BorderSizePixel = 0
    f.LayoutOrder = ord f.Parent = curPage
    corner(f, 12) stroke(f)
    f.MouseEnter:Connect(function() tw(f, { BackgroundColor3 = C.hover }, .12) end)
    f.MouseLeave:Connect(function() tw(f, { BackgroundColor3 = C.card }, .12) end)
    return f
end
local function rowLabel(f, t, w)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -(w or 60), 1, 0) l.Position = UDim2.new(0, 14, 0, 0) l.BackgroundTransparency = 1
    l.Text = t l.TextColor3 = C.text l.Font = Enum.Font.BuilderSans
    l.TextSize = touch and 14 or 13 l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = f
    return l
end

local function tog(t, get, set)
    local f = rowBase(ROWH)
    rowLabel(f, t, 64)
    local halo = Instance.new("Frame")
    halo.Size = UDim2.new(0, 52, 0, 35) halo.AnchorPoint = Vector2.new(.5, .5) halo.Position = UDim2.new(1, -34, .5, 0)
    halo.BackgroundColor3 = C.accent halo.BackgroundTransparency = 1 halo.BorderSizePixel = 0 halo.Parent = f
    corner(halo, 17)
    local sw = Instance.new("Frame")
    sw.Size = UDim2.new(0, 40, 0, 23) sw.Position = UDim2.new(1, -54, .5, -12)
    sw.BackgroundColor3 = C.track sw.BorderSizePixel = 0 sw.Parent = f
    corner(sw, 12)
    local swg = Instance.new("UIGradient")
    swg.Rotation = 90
    swg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(196, 196, 206)) })
    swg.Enabled = false swg.Parent = sw
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 17, 0, 17) knob.AnchorPoint = Vector2.new(0, .5)
    knob.Position = UDim2.new(0, 3, .5, 0) knob.BackgroundColor3 = Color3.fromRGB(170, 170, 182)
    knob.BorderSizePixel = 0 knob.Parent = sw
    corner(knob, 9)
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0) hit.BackgroundTransparency = 1 hit.Text = ""
    hit.AutoButtonColor = false hit.ZIndex = 3 hit.Parent = f
    local function paint(anim)
        local v = get()
        swg.Enabled = v
        local props = { Position = UDim2.new(0, v and 20 or 3, .5, 0), BackgroundColor3 = v and C.accentTx or Color3.fromRGB(170, 170, 182) }
        if anim then
            tw(knob, props, .16) tw(sw, { BackgroundColor3 = v and C.accent or C.track }, .16)
            tw(halo, { BackgroundTransparency = v and .86 or 1 }, .25)
        else
            knob.Position = props.Position knob.BackgroundColor3 = props.BackgroundColor3
            sw.BackgroundColor3 = v and C.accent or C.track
            halo.BackgroundTransparency = v and .86 or 1
        end
    end
    paint(false)
    table.insert(refreshers, function() paint(true) end)
    hit.Activated:Connect(function() set(not get()) paint(true) markDirty() end)
end

local function num(t, get, set, mn, mx)
    local dec = ((mx - mn) <= 5) and 2 or 0
    local function fmt(v)
        if dec == 2 then return string.format("%.2f", v) end
        return tostring(math.floor(v + .5))
    end
    local function round(v)
        if dec == 2 then return math.floor(v * 100 + .5) / 100 end
        return math.floor(v + .5)
    end
    local f = rowBase(ROWH + 22)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -80, 0, 18) l.Position = UDim2.new(0, 14, 0, 8) l.BackgroundTransparency = 1
    l.Text = t l.TextColor3 = C.text l.Font = Enum.Font.BuilderSans
    l.TextSize = touch and 14 or 13 l.TextXAlignment = Enum.TextXAlignment.Left l.Parent = f
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 64, 0, 18) val.Position = UDim2.new(1, -78, 0, 8) val.BackgroundTransparency = 1
    val.Text = fmt(get()) val.TextColor3 = C.sub val.Font = Enum.Font.BuilderSansBold
    val.TextSize = 12 val.TextXAlignment = Enum.TextXAlignment.Right val.Parent = f

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 4) track.Position = UDim2.new(0, 14, 1, -18)
    track.BackgroundColor3 = C.track track.BorderSizePixel = 0 track.Parent = f
    corner(track, 2)
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = C.accent fill.BorderSizePixel = 0 fill.Parent = track
    corner(fill, 2)
    local fg = Instance.new("UIGradient")
    fg.Rotation = 0
    fg.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(208, 208, 218)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)) })
    fg.Parent = fill
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 13, 0, 13) knob.AnchorPoint = Vector2.new(.5, .5)
    knob.BackgroundColor3 = C.accent knob.BorderSizePixel = 0 knob.ZIndex = 2 knob.Parent = track
    corner(knob, 7) stroke(knob, Color3.fromRGB(8, 8, 10), 2)
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, -14, 0, 24) hit.Position = UDim2.new(0, 7, 1, -28)
    hit.BackgroundTransparency = 1 hit.Text = "" hit.AutoButtonColor = false hit.ZIndex = 3 hit.Parent = f

    local function paint()
        local v = math.clamp(get(), mn, mx)
        local frac = (v - mn) / math.max(mx - mn, .0001)
        fill.Size = UDim2.new(frac, 0, 1, 0)
        knob.Position = UDim2.new(frac, 0, .5, 0)
        val.Text = fmt(v)
    end
    paint()
    table.insert(refreshers, paint)

    local dragging = false
    local dragInput = nil
    local page = curPage
    local function apply(x)
        local ax = track.AbsolutePosition.X
        local aw = math.max(track.AbsoluteSize.X, 1)
        local frac = math.clamp((x - ax) / aw, 0, 1)
        set(round(mn + (mx - mn) * frac))
        paint()
        markDirty()
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = i
            if page then page.ScrollingEnabled = false end
            apply(i.Position.X)
        end
    end)
    bind(uis.InputChanged, function(i)
        if dragging and alive() and (i.UserInputType == Enum.UserInputType.MouseMovement or (i.UserInputType == Enum.UserInputType.Touch and i == dragInput)) then
            apply(i.Position.X)
        end
    end)
    bind(uis.InputEnded, function(i)
        if dragging and i == dragInput then
            dragging = false
            dragInput = nil
            if page then page.ScrollingEnabled = true end
        end
    end)
end

local function btn(t, fn, danger)
    local f = rowBase(ROWH - 4)
    f.BackgroundColor3 = danger and Color3.fromRGB(46, 24, 24) or C.card
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 1, 0) b.BackgroundTransparency = 1 b.Text = t
    b.TextColor3 = danger and Color3.fromRGB(240, 150, 150) or C.text
    b.Font = Enum.Font.BuilderSans b.TextSize = touch and 14 or 13 b.AutoButtonColor = false b.Parent = f
    b.Activated:Connect(fn)
    return b
end

local function cycleBtn(t, get, set, options)
    local f = rowBase(ROWH)
    rowLabel(f, t, 140)
    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 118, 1, 0) val.Position = UDim2.new(1, -132, 0, 0) val.BackgroundTransparency = 1
    val.TextColor3 = C.sub val.Font = Enum.Font.BuilderSansBold val.TextSize = 12
    val.TextXAlignment = Enum.TextXAlignment.Right val.Parent = f
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0) hit.BackgroundTransparency = 1 hit.Text = ""
    hit.AutoButtonColor = false hit.ZIndex = 3 hit.Parent = f
    local function paint() val.Text = tostring(get()) .. "  ›" end
    paint()
    table.insert(refreshers, paint)
    hit.Activated:Connect(function()
        local cur = get()
        local idx = 1
        for i, v in ipairs(options) do if v == cur then idx = i break end end
        set(options[idx % #options + 1])
        paint()
        markDirty()
    end)
end

xhair = Instance.new("Frame")
xhair.Size = UDim2.new(0, 20, 0, 20) xhair.AnchorPoint = Vector2.new(.5, .5) xhair.Position = UDim2.new(.5, 0, .5, 0)
xhair.BackgroundTransparency = 1 xhair.BorderSizePixel = 0 xhair.Visible = false xhair.ZIndex = 60 xhair.Parent = ui
xhParts = {}
local function xhRect(w, h, x, y)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, w, 0, h) f.AnchorPoint = Vector2.new(.5, .5) f.Position = UDim2.new(.5, x, .5, y)
    f.BackgroundColor3 = C.accent f.BorderSizePixel = 0 f.ZIndex = 60 f.Parent = xhair
    corner(f, 2) table.insert(xhParts, f) return f
end
xhRect(4, 4, 0, 0) xhRect(2, 6, 0, -8) xhRect(2, 6, 0, 8) xhRect(6, 2, -8, 0) xhRect(6, 2, 8, 0)

createTab("aim", "照準")
createTab("esp", "ESP")
createTab("combat", "戦闘")
createTab("move", "移動")
createTab("misc", "その他")
createTab("server", "サーバー")

selectTab("aim") curPage = tabs.aim.page ord = 0
sec("ターゲット")
tog("エイムボット", function() return cfg.aim.on end, function(v) cfg.aim.on = v end)
tog("サイレントエイム", function() return cfg.sil.on end, function(v) cfg.sil.on = v end)
tog("トリガーボット", function() return cfg.trg.on end, function(v) cfg.trg.on = v end)
cycleBtn("狙う部位", function() return cfg.aim.part end, function(v) cfg.aim.part = v end, { "Head", "HumanoidRootPart", "UpperTorso", "Closest" })
tog("常時エイム", function() return cfg.aim.always end, function(v) cfg.aim.always = v end)
cycleBtn("優先モード", function() return cfg.aim.prio end, function(v) cfg.aim.prio = v end, { "クロスヘア", "低HP", "近距離" })
cycleBtn("ターゲット切替キー", function() return cfg.aim.cyclekey end, function(v) cfg.aim.cyclekey = v end, { "T", "Q", "V", "なし" })
sec("調整")
num("FOV（視野）", function() return cfg.aim.fov end, function(v) cfg.aim.fov = v end, 20, 700)
num("なめらかさ", function() return cfg.aim.sm end, function(v) cfg.aim.sm = v end, 0.05, 1)
num("予測", function() return cfg.aim.pred end, function(v) cfg.aim.pred = v end, 0, 0.3)
num("命中率 %", function() return cfg.sil.chance end, function(v) cfg.sil.chance = v end, 10, 100)
num("頭部率 %", function() return cfg.sil.headchance end, function(v) cfg.sil.headchance = v end, 0, 100)
num("サイレントFOV", function() return cfg.sil.fov end, function(v) cfg.sil.fov = v end, 30, 700)
num("トリガーFOV", function() return cfg.trg.fov end, function(v) cfg.trg.fov = v end, 2, 60)
num("トリガー遅延 ms", function() return cfg.trg.delay end, function(v) cfg.trg.delay = v end, 0, 300)
tog("トリガー: エイム中のみ", function() return cfg.trg.ads end, function(v) cfg.trg.ads = v end)
cycleBtn("トリガー方式", function() return cfg.trg.mode end, function(v) cfg.trg.mode = v end, { "連射", "単発" })
tog("トリガー: 頭のみ", function() return cfg.trg.head end, function(v) cfg.trg.head = v end)
tog("スティッキー", function() return cfg.aim.sticky end, function(v) cfg.aim.sticky = v end)
tog("チーム判定", function() return cfg.aim.team end, function(v) cfg.aim.team = v end)
tog("壁判定", function() return cfg.aim.wall end, function(v) cfg.aim.wall = v end)
tog("レイジボット", function() return cfg.aim.ragebot end, function(v) cfg.aim.ragebot = v end)

selectTab("esp") curPage = tabs.esp.page ord = 0
sec("ESP")
tog("有効", function() return cfg.esp.on end, function(v) cfg.esp.on = v end)
tog("チャムス", function() return cfg.esp.chams end, function(v) cfg.esp.chams = v end)
tog("ボックス", function() return cfg.esp.box end, function(v) cfg.esp.box = v end)
tog("名前", function() return cfg.esp.name end, function(v) cfg.esp.name = v end)
tog("武器", function() return cfg.esp.wp end, function(v) cfg.esp.wp = v end)
tog("体力", function() return cfg.esp.hp end, function(v) cfg.esp.hp = v end)
tog("距離", function() return cfg.esp.dist end, function(v) cfg.esp.dist = v end)
tog("トレーサー", function() return cfg.esp.trc end, function(v) cfg.esp.trc = v end)
tog("スケルトン", function() return cfg.esp.skel end, function(v) cfg.esp.skel = v end)
tog("ターゲットライン", function() return cfg.esp.tline end, function(v) cfg.esp.tline = v end)
num("最大距離", function() return cfg.esp.max end, function(v) cfg.esp.max = v end, 100, 5000)

selectTab("combat") curPage = tabs.combat.page ord = 0
sec("戦闘")
tog("リコイルなし", function() return cfg.combat.norecoil end, function(v) cfg.combat.norecoil = v end)
tog("拡散なし", function() return cfg.combat.nospread end, function(v) cfg.combat.nospread = v end)
tog("オートファイア", function() return cfg.combat.auto end, function(v) cfg.combat.auto = v end)
sec("武器MOD")
tog("連射", function() return cfg.combat.rapid end, function(v) cfg.combat.rapid = v end)
tog("リロード高速", function() return cfg.combat.reload end, function(v) cfg.combat.reload = v end)
tog("持ち替え高速", function() return cfg.combat.equip end, function(v) cfg.combat.equip = v end)
tog("弾薬無限", function() return cfg.combat.ammo end, function(v) cfg.combat.ammo = v end)
do
    local f = rowBase(ROWH)
    modStatTx = rowLabel(f, "武器MOD: —", 10)
end
selectTab("move") curPage = tabs.move.page ord = 0
sec("移動")
tog("飛行", function() return cfg.fly.on end, function(v) cfg.fly.on = v setFly(v) end)
num("飛行速度", function() return cfg.fly.spd end, function(v) cfg.fly.spd = v end, 10, 300)
tog("速度", function() return cfg.spd.on end, function(v) cfg.spd.on = v end)
num("速度の値", function() return cfg.spd.val end, function(v) cfg.spd.val = v end, 16, 200)
tog("ジャンプ", function() return cfg.jmp.on end, function(v) cfg.jmp.on = v end)
num("ジャンプ力", function() return cfg.jmp.val end, function(v) cfg.jmp.val = v end, 50, 500)
tog("壁抜け", function() return cfg.noc end, function(v) cfg.noc = v end)
tog("無限ジャンプ", function() return cfg.infj end, function(v) cfg.infj = v end)
tog("バニーホップ", function() return cfg.bhop end, function(v) cfg.bhop = v end)
tog("落下防止（奈落レスキュー）", function() return cfg.void.on end, function(v) cfg.void.on = v end)

selectTab("misc") curPage = tabs.misc.page ord = 0
sec("その他")
tog("ヒットボックス拡大", function() return cfg.hb.on end, function(v) cfg.hb.on = v if not v then restoreHB() end end)
num("拡大サイズ", function() return cfg.hb.size end, function(v) cfg.hb.size = v end, 2, 20)
cycleBtn("拡大部位", function() return cfg.hb.part end, function(v) cfg.hb.part = v end, { "両方", "頭", "胴体" })
tog("FPSブースト", function() return cfg.fpsb end, function(v) cfg.fpsb = v applyFps() end)
tog("AFK防止", function() return cfg.afk end, function(v) cfg.afk = v end)
sec("画面")
tog("フルブライト", function() return cfg.vis.fb end, function(v) cfg.vis.fb = v applyVis() end)
tog("霧なし", function() return cfg.vis.nf end, function(v) cfg.vis.nf = v applyVis() end)
tog("カメラFOV", function() return cfg.camf.on end, function(v) cfg.camf.on = v if not v then cam.FieldOfView = baseFov end end)
num("FOVの値", function() return cfg.camf.val end, function(v) cfg.camf.val = v end, 60, 130)
tog("クロスヘア", function() return cfg.xhair.on end, function(v) cfg.xhair.on = v end)
local diagTx
btn("動作チェック", function()
    local hookOk = G.__rvl4_silent and G.__rvl4_namecall
    local drawOk = Drawing ~= nil
    local saveOk = writefile ~= nil
    local libOk = probeLib and probeLib()
    if diagTx then diagTx.Text = "フック " .. (hookOk and "OK" or "不可") .. " / 描画 " .. (drawOk and "OK" or "なし") .. " / 保存 " .. (saveOk and "OK" or "不可") .. " / ライブラリ " .. (libOk and "OK" or "未検出") end
end)
do
    local f = rowBase(ROWH)
    diagTx = rowLabel(f, "動作チェック結果がここに出ます", 10)
end

local function unload()
    G.__rvl4_gen = G.__rvl4_gen + 1
    if G.__rvl4_cfg then G.__rvl4_cfg.sil.on = false end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() setFly(false) end)
    if afPressed then pcall(function() if mouse1release then mouse1release() end end) afPressed = false end
    cfg.combat.norecoil = false cfg.combat.nospread = false cfg.combat.rapid = false
    cfg.combat.reload = false cfg.combat.equip = false cfg.combat.ammo = false
    pcall(modsTick)
    cfg.fpsb = false pcall(applyFps)
    restoreHB()
    cfg.noc = false noclipTick()
    cfg.spd.on = false cfg.jmp.on = false moveTick()
    cfg.vis.fb = false cfg.vis.nf = false applyVis()
    pcall(function() cam.FieldOfView = baseFov end)
    if fovD then pcall(function() fovD:Remove() end) end
    if tLineD then pcall(function() tLineD:Remove() end) end
    for p in pairs(dc) do killDraw(p) end
    for _, h in pairs(hlCache) do pcall(function() h:Destroy() end) end
    for _, b in pairs(bbCache) do pcall(function() b.gui:Destroy() end) end
    pcall(function() ui:Destroy() end)
end

selectTab("server") curPage = tabs.server.page ord = 0
sec("サーバー")
btn("再参加", function() pcall(function() tps:Teleport(game.PlaceId, lp) end) end)
btn("サーバー移動", function()
    pcall(function()
        local d = hs:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"))
        local list = {}
        for _, s in ipairs(d.data or {}) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then table.insert(list, s.id) end
        end
        if #list > 0 then tps:TeleportToPlaceInstance(game.PlaceId, list[math.random(#list)], lp) end
    end)
end)
sec("設定")
cycleBtn("プロファイル", function() return tostring(cfg.misc.prof or 1) end, function(v)
    save()
    cfg.misc.prof = tonumber(v)
    pcall(function() if writefile then writefile("rvl_tools_prof.json", hs:JSONEncode({ prof = cfg.misc.prof })) end end)
    cfFile = (v == "1") and "rvl_tools_v3.json" or "rvl_tools_v3_p" .. v .. ".json"
    load()
    sanitize()
    refreshAll()
    setFly(cfg.fly.on)
    if not cfg.hb.on then restoreHB() end
    applyVis()
    if not cfg.camf.on then cam.FieldOfView = baseFov end
end, { "1", "2", "3" })
btn("設定を保存", save)
btn("設定を読込", function()
    load()
    sanitize()
    refreshAll()
    setFly(cfg.fly.on)
    if not cfg.hb.on then restoreHB() end
    applyVis()
end)
sec("終了")
btn("完全終了", unload, true)

selectTab("aim")
end

local lastStat, lastHp, hitAt = "", nil, 0
local lastTgt = nil
local fpsSm, fpsAt = 0, 0
bind(run.RenderStepped, function(dt)
    if not alive() then return end
    if dt and dt > 0 then
        local fr = 1 / dt
        fpsSm = fpsSm == 0 and fr or fpsSm + (fr - fpsSm) * .05
        if os.clock() - fpsAt > .5 then
            fpsAt = os.clock()
            fpsTx.Text = math.floor(fpsSm + .5) .. " FPS"
        end
        statDot.BackgroundTransparency = curTarget and (.3 + .5 * math.abs(math.sin(os.clock() * 5))) or 0
    end
    local cc = curTarget and getChar(curTarget) or nil
    if cc and cc.hum then
        local hp = cc.hum.Health
        if lastTgt == curTarget and lastHp and hp < lastHp then hitAt = os.clock() end
        lastHp = hp
        lastTgt = curTarget
    else
        lastHp = nil
        lastTgt = nil
    end
    local s = curTarget and "ロック中" or "待機中"
    if s ~= lastStat then
        lastStat = s
        statTx.Text = s
        statDot.BackgroundColor3 = curTarget and C.warn or C.faint
    end
    xhair.Visible = cfg.xhair.on
    if cfg.xhair.on then
        local col = (os.clock() - hitAt < .09) and C.warn or C.accent
        for _, f in ipairs(xhParts) do f.BackgroundColor3 = col end
    end
end)

local drag, dStart, startPos, dragObj
local function syncShadow()
    shadow.Position = UDim2.new(0, main.Position.X.Offset + 4, 0, main.Position.Y.Offset + 8)
    shadow.Size = main.Size
end
bind(bar.InputBegan, function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true dragObj = i dStart = i.Position startPos = main.Position
    end
end)
bind(uis.InputChanged, function(i)
    if drag and i == dragObj and i.UserInputState == Enum.UserInputState.End then drag = false dragObj = nil end
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        syncShadow()
    end
end)

local mini = false
minB.Activated:Connect(function()
    mini = not mini
    local h = mini and 55 or H
    tw(main, { Size = UDim2.new(0, W, 0, h) }, .22)
    tw(shadow, { Size = UDim2.new(0, W, 0, h) }, .22)
    side.Visible = not mini pages.Visible = not mini divV.Visible = not mini
    statDot.Visible = not mini statTx.Visible = not mini fpsTx.Visible = not mini
    minB.Text = mini and "+" or "–"
end)
closeB.Activated:Connect(function() main.Visible = false shadow.Visible = false end)
bind(uis.InputBegan, function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.F6 then
        main.Visible = not main.Visible
        shadow.Visible = main.Visible
    end
end)

if touch then
    local function roundBtn(txt, y, col)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 58, 0, 58) b.Position = UDim2.new(1, -74, 1, y)
        b.BackgroundColor3 = C.card b.BackgroundTransparency = .15
        b.Text = txt b.TextColor3 = C.text b.Font = Enum.Font.BuilderSansBold b.TextSize = 24 b.Parent = ui
        corner(b, 29) stroke(b)
        return b
    end
    local up = roundBtn("↑", -162, C.card)
    local dn = roundBtn("↓", -94, C.card)
    local function hold(b, fn)
        bind(b.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.Touch then fn(true) end end)
        bind(b.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.Touch then fn(false) end end)
    end
    hold(up, function(v) upHeld = v end)
    hold(dn, function(v) dnHeld = v end)
    local cyc = roundBtn("次", -240, C.card)
    table.insert(ownUi, up) table.insert(ownUi, dn) table.insert(ownUi, cyc)
    cyc.Activated:Connect(function() if curTarget then cycSkip = curTarget end end)
    bind(run.RenderStepped, function()
        if not alive() then return end
        up.Visible = cfg.fly.on dn.Visible = cfg.fly.on
        cyc.Visible = (cfg.aim.on or cfg.sil.on or cfg.aim.ragebot) and cfg.aim.cyclekey ~= "なし"
    end)
    local mb = Instance.new("TextButton")
    mb.Size = UDim2.new(0, 46, 0, 46) mb.Position = UDim2.new(0, 10, 0, 10)
    mb.BackgroundColor3 = C.card mb.BackgroundTransparency = .1
    mb.Text = "≡" mb.TextColor3 = C.text mb.Font = Enum.Font.BuilderSansBold mb.TextSize = 22 mb.Parent = ui
    corner(mb, 12) stroke(mb)
    table.insert(ownUi, mb)
    mb.Activated:Connect(function()
        main.Visible = not main.Visible
        shadow.Visible = main.Visible
    end)
end

bind(uis.InputBegan, function(i, gp)
    if gp then return end
    local ck = cfg.aim.cyclekey
    if ck and ck ~= "なし" and i.KeyCode == Enum.KeyCode[ck] and curTarget then cycSkip = curTarget end
end)
bind(uis.InputBegan, function(i, p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.Insert then
        main.Visible = not main.Visible
        shadow.Visible = main.Visible
    end
end)

main.Size = UDim2.new(0, W * .94, 0, H * .94)
tw(main, { Size = UDim2.new(0, W, 0, H) }, .32)
