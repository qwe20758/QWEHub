-- ============================================================
-- Tetrax v0.5.4.3 - Library UI 1 适配版
-- 购买逻辑已替换为 Moon 版本（传送连发 3 次）
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- 加载必要模块
local devv = require(ReplicatedStorage:FindFirstChild("devv"))
local Signal = devv and devv.load("Signal")
local InvokeServer = Signal.InvokeServer
local item = devv and devv.load("v3item")
local Inventory = item.inventory
local GUID = devv and devv.load("GUID")
local RemoteStorage = ReplicatedStorage.devv and ReplicatedStorage.devv.remoteStorage
local Raycast = devv and devv.load("Raycast")
local FireServer = Signal.FireServer
local v3item = devv and devv.load("v3item")
local inventory = v3item.inventory

-- ============================================================
-- OhioJoin 内联模块
-- ============================================================
local OhioJoin = {}

local _FireServer = nil
local _busy = false

local StarterGui = game:GetService("StarterGui")

local function _notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = 3,
        })
    end)
end

function OhioJoin.SetFireServer(fn)
    if type(fn) ~= "function" then return false end
    _FireServer = fn
    return true
end

function OhioJoin.IsReady()
    return type(_FireServer) == "function"
end

function OhioJoin.ResolveUserId(raw)
    if raw == nil then return nil end
    local s = (type(raw) == "string") and raw or tostring(raw)
    s = s:gsub("^%s+", ""):gsub("%s+$", ""):gsub("^@", "")
    if s == "" then return nil end
    local n = tonumber(s)
    if n and n > 0 then return n end
    local ok, id = pcall(function()
        return Players:GetUserIdFromNameAsync(s)
    end)
    if ok and type(id) == "number" and id > 0 then return id end
    return nil
end

function OhioJoin.JoinPlayer(input)
    if _busy then
        _notify("Ohio", "请稍候…")
        return false
    end
    if not input or input == "" then
        _notify("Ohio", "请输入玩家名或 UserId")
        return false
    end
    if not OhioJoin.IsReady() then
        _notify("Ohio", "FireServer 不可用")
        return false
    end

    _busy = true
    task.spawn(function()
        local ok, err = pcall(function()
            local userId = OhioJoin.ResolveUserId(input)
            if not userId then
                _notify("Ohio", "未找到该用户: " .. tostring(input))
                return
            end
            _FireServer("joinServer", userId)
            _notify("Ohio", "已请求加入: " .. tostring(input) .. " (id=" .. userId .. ")")
        end)
        _busy = false
        if not ok then
            _notify("Ohio", "错误: " .. tostring(err))
        end
    end)
    return true
end

function OhioJoin.JoinVCServer()
    -- 通道 1：Signal.FireServer
    if OhioJoin.IsReady() then
        local ok, err = pcall(_FireServer, "teleportVC")
        if ok then
            _notify("Ohio", "已请求加入 VC 服务器")
            return true
        else
            _notify("Ohio", "Signal 失败，尝试 RemoteEvent: " .. tostring(err))
        end
    end

    -- 通道 2：直接找 RemoteEvent
    local ok2, err2 = pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            or ReplicatedStorage:FindFirstChild("RemoteStorage")
            or ReplicatedStorage
        local r = remotes:FindFirstChild("teleportVC")
        if r and r:IsA("RemoteEvent") then
            r:FireServer()
            return true
        end
        return false
    end)
    if ok2 and err2 ~= false then
        _notify("Ohio", "已通过 RemoteEvent 请求 VC")
        return true
    end

    _notify("Ohio", "VC 请求失败：找不到 teleportVC 通道")
    return false
end

-- 延迟注入，确保 FireServer 已定义
task.spawn(function()
    repeat task.wait() until FireServer
    OhioJoin.SetFireServer(FireServer)
end)

-- ============================================================
-- 【核心修改】购买逻辑（Moon 版：传送 + 连点 3 次 + 瞬回）
-- ============================================================

local selectedItemForBuy = nil
local isBuying = false
local autoBuyEnabled = false
local autoBuyInterval = 0.0001

local purchaseQueue = {}
local queueProcessing = false

local function hasItemInInventory(itemName)
    if not itemName then return false end
    for _, v in pairs(Inventory.items) do
        if v.name == itemName then
            return true
        end
    end
    return false
end

local function getItemPosition(itemName)
    local itemsOnSale = Workspace:FindFirstChild("ItemsOnSale")
    if not itemsOnSale then return nil end
    
    for _, targetItem in ipairs(itemsOnSale:GetChildren()) do
        if targetItem.Name == itemName then
            if targetItem:IsA("BasePart") then
                return targetItem.Position
            end
            if targetItem:IsA("Model") and targetItem.PrimaryPart then
                return targetItem.PrimaryPart.Position
            end
            for _, child in ipairs(targetItem:GetDescendants()) do
                if child:IsA("BasePart") then
                    return child.Position
                end
            end
        end
    end
    return nil
end

-- Moon 核心购买函数：瞬移 -> 连点 3 次 -> 瞬回
local function moonPurchase(itemName, isAmmo)
    if isBuying or not itemName then return false end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local pos = getItemPosition(itemName)
    
    -- 如果场景里没有卖这个物品，直接发请求尝试购买（兜底）
    if not pos then 
        if isAmmo then
            InvokeServer("attemptPurchaseAmmo", itemName)
        else
            InvokeServer("attemptPurchase", itemName)
        end
        return true
    end
    
    isBuying = true
    local originalCFrame = rootPart.CFrame
    
    -- 传送并连发 3 次
    for i = 1, 3 do
        rootPart.CFrame = CFrame.new(pos)
        if isAmmo then
            InvokeServer("attemptPurchaseAmmo", itemName)
        else
            InvokeServer("attemptPurchase", itemName)
        end
    end
    
    -- 瞬回
    rootPart.CFrame = originalCFrame
    isBuying = false
    return true
end

-- 公开购买函数
local function buyItem(itemName)
    if not itemName then return false end
    return moonPurchase(itemName, false)
end

local function buyAmmo(itemName)
    if not itemName then return false end
    return moonPurchase(itemName, true)
end

-- 购买队列处理
local function processPurchaseQueue()
    if queueProcessing then return end
    queueProcessing = true
    
    while #purchaseQueue > 0 do
        local request = table.remove(purchaseQueue, 1)
        if request and not hasItemInInventory(request.itemName) then
            if request.isAmmo then
                buyAmmo(request.itemName)
            else
                buyItem(request.itemName)
            end
            task.wait(autoBuyInterval)
        end
    end
    
    queueProcessing = false
end

local function requestPurchase(itemName, isAmmo)
    if not itemName then return end
    if hasItemInInventory(itemName) then return end
    
    table.insert(purchaseQueue, {
        itemName = itemName,
        isAmmo = isAmmo or false
    })
    
    task.spawn(processPurchaseQueue)
end

local function autoBuyLoop()
    while autoBuyEnabled do
        if selectedItemForBuy and not hasItemInInventory(selectedItemForBuy) then
            buyItem(selectedItemForBuy)
        end
        task.wait(autoBuyInterval)
    end
end

local function getItemList()
    local itemsOnSale = Workspace:FindFirstChild("ItemsOnSale")
    if not itemsOnSale then return {} end
    
    local list = {}
    local seen = {}
    
    for _, targetItem in ipairs(itemsOnSale:GetChildren()) do
        local name = targetItem.Name
        if not seen[name] then
            seen[name] = true
            table.insert(list, name)
        end
    end
    
    table.sort(list)
    return list
end

-- ============================================================
-- Tetrax 全局状态
-- ============================================================

Flags = {
    speed = 1,
    tpEnabled = true,
    jumpEnabled = false,
    hitMOD = "meleemegapunch",
    manualIntercept = false,
    killAura = false,
    autoStomp = false,
    autoGrab = false,
    bladeaura = false,
    attackRange = 100,
    fireRateBoost = false,
    noEquipAttack = false,
    constantTeleport = false,
    killAll = false,
    targetTeleport = false,
    selectedTarget = nil,
    selectedTargetName = "选择玩家",
    teleportDistance = 180,
    weaponType = "Brass Knuckles",
    autoEquip = false,
    autoBuyWeapon = false,
    autoPickMaterial = false,
    noAttackFriends = false,
    whitelistNames = {},
    whitelistIds = {},
    hiPart = "Tomahawk",
    autoVest = false,
    vestType = "Light Vest",
    autoHealth = false,
    healItem = "Bandage",
    autoMask = false,
    maskType = "Black Bandana",
    callPhone = false,
    arrestAura = false,
    arrestDistance = 30,
    arrestHealthThreshold = 5,
    killCountRequired = 2,  -- 默认击杀 2 次
}
-- ============================================================
-- 【Snow 击杀模块】移植自 snow源码.lua Ohio Combat
-- ============================================================

local SnowCombat = {
    targetPlayers = {},        -- 选中的目标（空=ALL）
    fbsx = "Tomahawk",         -- 击杀方式
    fbx = 0, fby = 0, fbz = 5, -- TP 偏移
    aurablade = false,         -- 自动击杀
    tpplayfb = false,          -- TP 玩家
    isBlinkActive = false,     -- 闪现
    bladeid = nil,             -- 粘性物 id
    lastAttack = 0,
    originalPosition = nil,
    blinkStartTime = 0,
    avoidPosition = Vector3.new(-23.943367, 53.9272232, -40.3150673),
    avoidRadius = 100,
}
-- ============================================================
-- Snow 自动购买 / 自动装备 Raygun
-- ============================================================
local snowAutoEquipRaygun = false   -- 开关状态（由 UI 控制）

-- 返回背包里指定名字的物品 guid（没有则 nil）
local function snowGetItemGuid(itemName)
    if not Inventory or not Inventory.items then return nil end
    for _, v in pairs(Inventory.items) do
        if v.name == itemName then
            return v.guid
        end
    end
    return nil
end

-- 自动购买：当前 fbsx 对应物品不在背包就 requestPurchase
local function snowEnsureKillItem()
    local itemName = (SnowCombat.fbsx == "Gun Kill") and "Raygun" or SnowCombat.fbsx
    if not itemName then return end
    if hasItemInInventory(itemName) then return end
    requestPurchase(itemName, false)
end

-- 自动装备 Raygun（仅 Gun Kill 模式）
local function snowAutoEquipRaygunTick()
    if not snowAutoEquipRaygun then return end
    if SnowCombat.fbsx ~= "Gun Kill" then return end

    -- 有就直接装备
    local guid = snowGetItemGuid("Raygun")
    if guid then
        FireServer("equip", guid)
        return
    end
    -- 没有就先购买（下一轮 Heartbeat 再装）
    requestPurchase("Raygun", false)
end

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- 弹道拖尾（与 Snow 一致）
local function snowCreateTrace(targetPos)
    local char = LocalPlayer.Character
    if not (char and char.PrimaryPart) then return end
    local S = char.PrimaryPart.Position + Vector3.new(math.random(-15,15), math.random(-15,15), math.random(-15,15))
    local mag = (targetPos - S).Magnitude
    local P = Instance.new("Part")
    P.Name, P.Anchored, P.CanCollide, P.CastShadow = "Trace", true, false, false
    P.Material, P.Color, P.Size = Enum.Material.Neon, Color3.fromHSV(tick() % 1, 0.8, 1), Vector3.new(0.15, 0.15, mag)
    P.CFrame, P.Parent = CFrame.lookAt(S, targetPos) * CFrame.new(0, 0, -mag/2), workspace
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://5633695679"
    sound.Parent = P
    sound:Play()
    Debris:AddItem(sound, 1)
    TweenService:Create(P, TweenInfo.new(1), {Transparency = 1, Size = Vector3.new(0, 0, mag)}):Play()
    Debris:AddItem(P, 1)
end

-- 装备并投掷击杀物（Gun Kill 时用 QweHub 的传送购买 Raygun）
local function snowThrow()
    if SnowCombat.fbsx == "Gun Kill" then
        -- 使用 QweHub 的 moonPurchase 传送购买 Raygun
        if not hasItemInInventory("Raygun") then
            requestPurchase("Raygun", false)
            task.wait(0.5)
        end
        for _, v in pairs(Inventory.items) do
            if v.name == "Raygun" then
                FireServer("equip", v.guid)
                break
            end
        end
        return
    end

    -- 其他投掷物：尝试购买（兜底），再 equip + throwSticky
    if not hasItemInInventory(SnowCombat.fbsx) then
        requestPurchase(SnowCombat.fbsx, false)
        task.wait(0.3)
    end
    local blade
    for _, v in pairs(Inventory.items) do
        if v.name == SnowCombat.fbsx then blade = v.guid; break end
    end
    if not blade then return end
    FireServer("equip", blade)
    task.wait(0.1)
    local _, id = InvokeServer("throwSticky", GUID(), SnowCombat.fbsx, blade, Vector3.zero, Vector3.zero)
    SnowCombat.bladeid = id
end

-- 目标筛选：判断某玩家是否在选中目标内
local function snowIsTarget(player)
    if #SnowCombat.targetPlayers == 0 then return true end
    if table.find(SnowCombat.targetPlayers, "ALL") then return true end
    return table.find(SnowCombat.targetPlayers, player.Name) ~= nil
end

-- 每帧光环 / TP / 闪现 主循环
RunService.Heartbeat:Connect(function()
    -- 自动击杀开启时，确保击杀物在背包（没有就购买）
    if SnowCombat.aurablade then
        snowEnsureKillItem()
    end

    -- 自动装备 Raygun（Gun Kill 模式）
    snowAutoEquipRaygunTick()

    if not (SnowCombat.aurablade or SnowCombat.tpplayfb) and not SnowCombat.isBlinkActive then return end

    local myChar = LocalPlayer.Character
    if not (myChar and myChar:FindFirstChild("HumanoidRootPart")) then return end
    local myRoot = myChar.HumanoidRootPart

    local target, dist = nil, math.huge
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and snowIsTarget(v)
            and v.Character and v.Character:FindFirstChild("HumanoidRootPart")
            and v.Character.Humanoid.Health > 0
            and not v.Character:FindFirstChildOfClass("ForceField")
            and not LocalPlayer:IsFriendsWith(v.UserId)
        then
            local targetPos = v.Character.HumanoidRootPart.Position
            if (targetPos - SnowCombat.avoidPosition).Magnitude <= SnowCombat.avoidRadius then continue end
            local mag = (myRoot.Position - targetPos).Magnitude
            if mag < dist then
                dist = mag
                target = v.Character.Head
            end
        end
    end

    if not target then return end
    local targetPos = target.Position
    local avoidDist = (targetPos - SnowCombat.avoidPosition).Magnitude

    -- TP玩家
    if SnowCombat.tpplayfb and avoidDist > SnowCombat.avoidRadius then
        myRoot.CFrame = target.CFrame * CFrame.new(SnowCombat.fbx, SnowCombat.fby, SnowCombat.fbz)
    end

    if SnowCombat.aurablade or SnowCombat.isBlinkActive then
        local currentTime = tick()
        local attackInterval = SnowCombat.isBlinkActive and 0
            or (SnowCombat.fbsx == "Gun Kill" and 0 or 0.1)
        local attackDist = (myRoot.Position - targetPos).Magnitude

        if currentTime - SnowCombat.lastAttack >= attackInterval
            and (SnowCombat.fbsx == "Gun Kill" or attackDist <= 200)
            and avoidDist > SnowCombat.avoidRadius
        then
            if SnowCombat.isBlinkActive then
                if not SnowCombat.originalPosition then
                    SnowCombat.originalPosition = myRoot.Position
                    myRoot.CFrame = CFrame.new(1000, 1000, 1000)
                    SnowCombat.blinkStartTime = currentTime
                    return
                elseif currentTime - SnowCombat.blinkStartTime >= math.random(1, 3) then
                    myRoot.CFrame = target.CFrame * CFrame.new(SnowCombat.fbx, SnowCombat.fby, SnowCombat.fbz)
                    if SnowCombat.fbsx == "Gun Kill" then
                        local item = v3item.GetEquipped(LocalPlayer)
                        if item and item.type == "Gun" then
                            SnowCombat.lastAttack = currentTime
                            if item.ammoManager and item.ammoManager.ammo > 0 then
                                local g = GUID()
                                snowCreateTrace(targetPos)
                                FireServer("replicateProjectiles", item.guid, {{g, target.CFrame}}, item.firemode)
                                FireServer("projectileHit", g, "player", {
                                    hitSize = target.Size, hitPart = target,
                                    pos = targetPos,
                                    hitPlayerId = Players:GetPlayerFromCharacter(target.Parent).UserId
                                })
                                item.ammoManager.ammo = item.ammoManager.ammo - 1
                            else
                                requestPurchase("Raygun", true)
                                FireServer("reload", item.guid)
                            end
                        end
                    elseif SnowCombat.bladeid then
                        SnowCombat.lastAttack = currentTime
                        snowCreateTrace(targetPos)
                        InvokeServer("hitSticky", SnowCombat.bladeid, target, target.CFrame, target.CFrame)
                    end
                    task.wait(0.05)
                    myRoot.CFrame = CFrame.new(SnowCombat.originalPosition)
                    SnowCombat.originalPosition = nil
                    SnowCombat.isBlinkActive = false
                end
            else
                if SnowCombat.fbsx == "Gun Kill" then
                    local item = v3item.GetEquipped(LocalPlayer)
                    if item and item.type == "Gun" then
                        SnowCombat.lastAttack = currentTime
                        if item.ammoManager and item.ammoManager.ammo > 0 then
                            local g = GUID()
                            snowCreateTrace(targetPos)
                            FireServer("replicateProjectiles", item.guid, {{g, target.CFrame}}, item.firemode)
                            FireServer("projectileHit", g, "player", {
                                hitSize = target.Size, hitPart = target,
                                pos = targetPos,
                                hitPlayerId = Players:GetPlayerFromCharacter(target.Parent).UserId
                            })
                            item.ammoManager.ammo = item.ammoManager.ammo - 1
                        else
                            requestPurchase("Raygun", true)
                            FireServer("reload", item.guid)
                        end
                    end
                elseif SnowCombat.bladeid then
                    SnowCombat.lastAttack = currentTime
                    snowCreateTrace(targetPos)
                    InvokeServer("hitSticky", SnowCombat.bladeid, target, target.CFrame, target.CFrame)
                end
            end
        end
    end
end)
local character, humanoid
local heartbeatConnection = nil
local jumpConnection = nil
local spinAngle = 0
local killAllSpinAngle = 0
local originalCameraSubject = nil
local currentTarget = nil
local constantTeleportTarget = nil
local lowHpThresholddd = 180
local spinSpeed = 30
local bladeaura = false
local rpgAttackDistance = 100
local hiPart = "Tomahawk"
local swingEvent = nil
local hitEvent = nil
local eventsFound = false
local currentTarget = nil

local function getClosestTarget()
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local myPos = root.Position
    local closest = nil
    local closestDist = 15
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local targetChar = player.Character
            if targetChar then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (targetRoot.Position - myPos).Magnitude
                    if dist <= closestDist then
                        closestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

local function findEvents()
    while not eventsFound do
        pcall(function()
            local rs = ReplicatedStorage:FindFirstChild("devv")
            if rs then
                rs = rs:FindFirstChild("remoteStorage")
                if rs then
                    swingEvent = rs:FindFirstChild("attackOfMeleeSwing")
                    hitEvent = rs:FindFirstChild("attackMeleeHit")
                    if swingEvent and hitEvent then
                        eventsFound = true
                    end
                end
            end
        end)
        if not eventsFound then task.wait(0.5) end
    end
end

task.spawn(findEvents)

-- ========== Tetrax 辅助函数 ==========
local function setupCharacter()
    character = LocalPlayer.Character
    if character then
        humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            repeat task.wait() until LocalPlayer.Character ~= nil
            setupCharacter()
            if Flags.tpEnabled then startTPWalk() end
        end)
    end
end

local function startTPWalk()
    if heartbeatConnection then heartbeatConnection:Disconnect() end
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if not Flags.tpEnabled or not character or not humanoid or humanoid.Health <= 0 then return end
        if humanoid.MoveDirection.Magnitude > 0 then
            local currentCFrame = character.PrimaryPart.CFrame
            local newPosition = currentCFrame.Position + (humanoid.MoveDirection * Flags.speed)
            character:SetPrimaryPartCFrame(CFrame.new(newPosition) * currentCFrame.Rotation)
        end
    end)
end

local function stopTPWalk()
    if heartbeatConnection then heartbeatConnection:Disconnect() end
    heartbeatConnection = nil
end

local function GetGuid(name)
    if not Inventory or not Inventory.items then return nil end
    for _, v in pairs(Inventory.items) do
        if v.name == name then
            return v.guid
        end
    end
    return nil
end

local function getOnlinePlayers()
    local list = {"选择玩家"}
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then table.insert(list, v.Name) end
    end
    return list
end

local function shouldNotAttack(player)
    if not player or player == LocalPlayer then return true end
    for _, name in pairs(Flags.whitelistNames) do
        if name == player.Name then return true end
    end
    for _, id in pairs(Flags.whitelistIds) do
        if id == player.UserId then return true end
    end
    if Flags.noAttackFriends then
        local success, isFriend = pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
        if success and isFriend then return true end
    end
    return false
end

local function updateConstantTarget()
    local players = {}
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then table.insert(players, v) end
    end
    if #players > 0 then
        constantTeleportTarget = players[math.random(1, #players)]
    end
end

local function getPoliceUniform()
    local originalCFrame = LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart.CFrame
    if not originalCFrame then return false, false end
    local serverFurniture = workspace:FindFirstChild("ServerFurniture")
    if not serverFurniture then return false, false end
    local foundUniform, foundHat = false, false
    for _, descendant in pairs(serverFurniture:GetDescendants()) do
        if descendant:IsA("Model") and descendant:GetAttribute("furnitureName") == "PoliceUniform" then
            if descendant.PrimaryPart then
                LocalPlayer.Character.HumanoidRootPart.CFrame = descendant.PrimaryPart.CFrame
                task.wait(0.3)
                local prompt = descendant:FindFirstChild("Handle") and descendant.Handle:FindFirstChild("ProximityPrompt")
                if prompt then fireproximityprompt(prompt) end
                task.wait(0.05)
                foundUniform = true
                break
            end
        end
    end
    for _, descendant in pairs(serverFurniture:GetDescendants()) do
        if descendant:IsA("Model") and descendant:GetAttribute("furnitureName") == "PoliceHat" then
            if descendant.PrimaryPart then
                LocalPlayer.Character.HumanoidRootPart.CFrame = descendant.PrimaryPart.CFrame
                task.wait(0.2)
                local prompt = descendant:FindFirstChild("Hitbox") and descendant.Hitbox:FindFirstChild("ProximityPrompt")
                if prompt then fireproximityprompt(prompt) end
                task.wait(0.05)
                foundHat = true
                break
            end
        end
    end
    LocalPlayer.Character.HumanoidRootPart.CFrame = originalCFrame
    return foundUniform, foundHat
end

local function getClownHat()
    local originalCFrame = LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart.CFrame
    if not originalCFrame then return false end
    local serverFurniture = workspace:FindFirstChild("ServerFurniture")
    if not serverFurniture then return false end
    for _, descendant in pairs(serverFurniture:GetDescendants()) do
        if descendant:GetAttribute("furnitureName") == "Clown" then
            local targetPos = descendant:GetPivot() * CFrame.new(0, 0, 3)
            LocalPlayer.Character.HumanoidRootPart.CFrame = targetPos
            task.wait(0.17)
            local prompt = descendant:FindFirstChild("Hitbox") and descendant.Hitbox:FindFirstChild("ProximityPrompt")
            if prompt then fireproximityprompt(prompt) end
            task.wait(0.17)
            LocalPlayer.Character.HumanoidRootPart.CFrame = originalCFrame
            return true
        end
    end
    LocalPlayer.Character.HumanoidRootPart.CFrame = originalCFrame
    return false
end

-- ========== Tetrax 战斧光环相关 ==========
local function hackthrow(plr, itemname, itemguid, velocity, epos)
    if plr ~= LocalPlayer then return end
    task.spawn(function()
        local throwGuid = GUID()
        local success, stickyId = InvokeServer("throwSticky", throwGuid, itemname, itemguid, velocity, epos)
        if not success then return end
        local dummyPart = Instance.new("Part")
        dummyPart.Size = Vector3.new(2, 2, 2)
        dummyPart.Position = epos
        dummyPart.Anchored = true
        dummyPart.Transparency = 1
        dummyPart.CanCollide = true
        dummyPart.Parent = workspace
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {plr.Character, workspace.Game.Local, workspace.Game.Drones}
        local dist = (epos - plr.Character.Head.Position).Magnitude
        local rayResult = workspace:Raycast(
            plr.Character.Head.Position,
            (epos - plr.Character.Head.Position).Unit * (dist + 5),
            rayParams
        )
        if rayResult and rayResult.Instance then
            local hitPart = rayResult.Instance
            local relativeHitCFrame = hitPart.CFrame:ToObjectSpace(CFrame.new(rayResult.Position, rayResult.Position + rayResult.Normal))
            local stickyCFrame = CFrame.new(rayResult.Position)
            if dummyPart.Parent then dummyPart:Destroy() end
            getgenv().throwargs = {
                "hitSticky",
                stickyId or throwGuid,
                hitPart,
                relativeHitCFrame,
                stickyCFrame,
            }
            InvokeServer("hitSticky", stickyId or throwGuid, hitPart, relativeHitCFrame, stickyCFrame)
        else
            if dummyPart.Parent then dummyPart:Destroy() end
        end
    end)
end

local function getinventory()
    return inventory.items
end

local function finditem(itemName)
    for guid, data in next, getinventory() do
        if data.name == itemName or data.type == itemName or data.subtype == itemName then
            return data
        end
    end
end

local function executebladekill(plr, head)
    if Flags.noEquipAttack and getgenv().throwargs then
        for i = 1, 2 do
            task.spawn(function()
                local argsCopy = {}
                for k, v in pairs(getgenv().throwargs) do
                    argsCopy[k] = v
                end
                argsCopy[3] = head
                InvokeServer(unpack(argsCopy))
            end)
        end
        return
    end

    if getgenv().throwargs then
        local currentItem = nil
        for guid, data in next, getinventory() do
            if data.equipped then
                currentItem = data
                break
            end
        end
        if currentItem then
            for i = 1, 2 do
                task.spawn(function()
                    local argsCopy = {}
                    for k, v in pairs(getgenv().throwargs) do
                        argsCopy[k] = v
                    end
                    argsCopy[3] = head
                    InvokeServer(unpack(argsCopy))
                end)
            end
        end
        return
    end

    local item = finditem(Flags.hiPart)
    if not item then return end

    FireServer("equip", item.guid)
    local rightHand = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("RightHand")
    if not rightHand then return end
    local spos = rightHand.Position
    local epos = head.Position
    local velocity = (epos - spos).Unit * ((spos - epos).Magnitude * 100)
    task.spawn(InvokeServer, "attemptPurchaseAmmo", Flags.hiPart)
    hackthrow(LocalPlayer, Flags.hiPart, item.guid, velocity, epos)
end

-- ========== Tetrax 后台循环 ==========
local function BypassRemotes()
    while true do
        task.wait(0.1)
        pcall(function()
            local signal = ReplicatedStorage:FindFirstChild("devv")
            if signal then
                signal = signal:FindFirstChild("client")
                if signal then
                    signal = signal:FindFirstChild("Helpers")
                    if signal then
                        signal = signal:FindFirstChild("remotes")
                        if signal then
                            signal = signal:FindFirstChild("Signal")
                            if signal then
                                local upvalues = getupvalue(require(signal).FireServer, 1)
                                if upvalues then
                                    for remoteName, remoteObj in pairs(upvalues) do
                                        remoteObj.Name = remoteName
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end

local function autoBypass()
    pcall(function()
        local devv = ReplicatedStorage:FindFirstChild("devv")
        if not devv then return end
        local remoteStorage = devv:FindFirstChild("remoteStorage")
        if not remoteStorage then return end
        local makeExplosion = remoteStorage:FindFirstChild("makeExplosion")
        if makeExplosion then
            makeExplosion:Destroy()
        end
    end)
end

local function antiGrab()
    local success, l = pcall(function() return require(ReplicatedStorage.devv).load end)
    if success and l then
        local replicator = l("ClientReplicator")
        if replicator and replicator.Get then
            if replicator.Get(LocalPlayer, "carried") == true then
                replicator.Set(LocalPlayer, "carried", false)
            end
        end
    end
end

local function antiRagdoll()
    if LocalPlayer:GetAttribute("isRagdoll") == true then
        local success, loadFunc = pcall(function() return require(ReplicatedStorage.devv).load end)
        if success and loadFunc then
            local ragdoll = loadFunc("ClientRagdoll")
            if ragdoll and ragdoll.SetRagdoll then
                task.spawn(ragdoll.SetRagdoll, LocalPlayer, false)
            end
        end
    end
end

local function silentBlock()
    local success, l = pcall(function() return require(ReplicatedStorage.devv).load end)
    if success and l then
        local replicator = l("ClientReplicator")
        if replicator and replicator.Set and replicator.Replicate then
            replicator.Set(LocalPlayer, "blocking", true)
            replicator.Replicate("blocking")
        end
    end
end

local function increaseFireRate()
    pcall(function()
        local itemSystem = require(ReplicatedStorage.devv).load("v3item")
        if itemSystem and itemSystem.inventory then
            for _, it in pairs(itemSystem.inventory.items) do
                if it then
                    it.fireDebounce = 0.0001
                    it.recoilAdd = 0
                    it.maxRecoil = 0
                    it.recoilDiminishFactor = 0
                    it.recoilFastDiminishFactor = 0
                    it.baseSpread = 0
                    it.baseAimSpread = 0
                    it.spread = 0
                    it.aimSpread = 0
                end
            end
        end
    end)
end

local pjyd
pjyd = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if method == "InvokeServer" and args[2] == true then
        args[2] = false
        return pjyd(self, unpack(args))
    end
    return pjyd(self, ...)
end)

local Hit = nil
local Kill = nil
local Items = {}
pcall(function()
    if workspace.ItemSpawns and workspace.ItemSpawns.items then
        Items = workspace.ItemSpawns.items:GetChildren() or {}
    end
end)

local Call
Call = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local args = {...}
    if self.Parent == RemoteStorage then
        if Flags.manualIntercept and args[1] == "player" and args[2] and args[2].hitPlayerId then
            args[2].meleeType = Flags.hitMOD
        end
        if #args ~= 0 then
            if args[2] ~= "Items" and table.find(Items, args[1]) then
                Buy = self
            elseif table.find({"prop", "player"}, args[1]) then
                Hit = self
            elseif typeof(args[1]) == "Instance" and args[1].ClassName == "Player" then
                Kill = self
            end
        end
    end
    return Call(self, ...)
end))

task.spawn(BypassRemotes)
task.spawn(autoBypass)

task.spawn(function()
    while true do
        pcall(antiGrab)
        task.wait(0.05)
    end
end)

task.spawn(function()
    while true do
        pcall(antiRagdoll)
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        pcall(silentBlock)
        task.wait(0.05)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local position = char.HumanoidRootPart.Position
                if position.Y < -150 then
                    char.HumanoidRootPart.CFrame = CFrame.new(1339.9090576171875, 6.044891357421875, -660.3264770507812)
                end
            end
        end)
    end
end)

LocalPlayer:SetAttribute("mobileDealer", true)
pcall(function()
    local mobileDealer = require(ReplicatedStorage.devv.shared.Indicies.mobileDealer)
    if mobileDealer then
        for category, items in pairs(mobileDealer) do
            for _, it in ipairs(items) do
                it.stock = 99
            end
        end
        if mobileDealer.Gun then
            table.insert(mobileDealer.Gun, {itemName = "Pulse Rifle", stock = 99})
            table.insert(mobileDealer.Gun, {itemName = "Unusual Money Printer", stock = 99})
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    setupCharacter()
end)
setupCharacter()

-- 功能循环
task.spawn(function()
    local killAuraDistance = 35
    while true do
        if Flags.killAura then
            pcall(function()
                if not eventsFound then return end
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    RunService.RenderStepped:Wait()
                    return
                end
                
                local currentHRP = LocalPlayer.Character.HumanoidRootPart
                
                for _, targetPlayer in pairs(Players:GetPlayers()) do
                    if shouldNotAttack(targetPlayer) then continue end
                    if targetPlayer == LocalPlayer then continue end
                    if not targetPlayer.Character then continue end
                    if targetPlayer.Character:FindFirstChild("ForceField") then continue end
                    
                    local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not targetHRP then continue end
                    
                    local targetHumanoid = targetPlayer.Character:FindFirstChild("Humanoid")
                    if not targetHumanoid then continue end
                    if targetHumanoid.Health <= 15 then continue end
                    
                    local distance = (currentHRP.Position - targetHRP.Position).Magnitude
                    if distance > killAuraDistance then continue end
                    
                    if hitEvent then
                        pcall(function()
                            hitEvent:FireServer("player", {
                                meleeType = Flags.hitMOD,
                                hitPlayerId = targetPlayer.UserId
                            })
                        end)
                    end
                end
            end)
        end
        RunService.RenderStepped:Wait()
    end
end)

task.spawn(function()
    while true do
        if Flags.autoStomp then
            pcall(function()
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    RunService.RenderStepped:Wait(0.1)
                    return
                end
                local lphumrootpart = LocalPlayer.Character.HumanoidRootPart
                for _, v in pairs(Players:GetPlayers()) do
                    if v == LocalPlayer then continue end
                    if shouldNotAttack(v) then continue end
                    if not v.Character then continue end
                    if v.Character:FindFirstChild("ForceField") then continue end
                    local vhumrootpart = v.Character:FindFirstChild("HumanoidRootPart")
                    if not vhumrootpart then continue end
                    local vhumanoid = v.Character:FindFirstChild("Humanoid")
                    if not vhumanoid then continue end
                    local dis = (lphumrootpart.Position - vhumrootpart.Position).Magnitude
                    if dis <= 55 and vhumanoid.Health < 35 then
                        if Signal then
                            pcall(function() Signal.FireServer("finish", v) end)
                        end
                    end
                end
            end)
        end
        RunService.RenderStepped:Wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if Flags.autoGrab then
            pcall(function()
                if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    RunService.Heartbeat:Wait()
                    return
                end
                local lphumrootpart = LocalPlayer.Character.HumanoidRootPart
                for _, v in pairs(Players:GetPlayers()) do
                    if v == LocalPlayer then continue end
                    if shouldNotAttack(v) then continue end
                    if not v.Character then continue end
                    if v.Character:FindFirstChild("ForceField") then continue end
                    local mp = v.Character:FindFirstChild("HumanoidRootPart")
                    if not mp then continue end
                    local hum = v.Character:FindFirstChild("Humanoid")
                    if not hum then continue end
                    local distance = (lphumrootpart.Position - mp.Position).magnitude
                    if hum.Health < 35 and distance <= 50 then
                        if Signal then
                            pcall(function() Signal.FireServer("grabPlayer", v) end)
                        end
                    end
                end
            end)
        end
        RunService.Heartbeat:Wait()
    end
end)

task.spawn(function()
    while true do
        if Flags.killAll then
            pcall(function()
                local LocalChar = LocalPlayer.Character
                if not LocalChar then RunService.Heartbeat:Wait(); return end
                local LocalHumanoid = LocalChar:FindFirstChild("Humanoid")
                local LocalRoot = LocalChar:FindFirstChild("HumanoidRootPart")
                if not LocalHumanoid or not LocalRoot then RunService.Heartbeat:Wait(); return end

                local validPlayers = {}
                for _, v in Players:GetPlayers() do
                    if v == LocalPlayer then continue end
                    if shouldNotAttack(v) then continue end
                    local Character = v.Character
                    if not Character then continue end
                    if Character:FindFirstChild("ForceField") then continue end
                    local Humanoid = Character:FindFirstChild("Humanoid")
                    if not Humanoid or Humanoid.Health <= 0 then continue end
                    local RootPart = Character:FindFirstChild("HumanoidRootPart")
                    if not RootPart then continue end
                    table.insert(validPlayers, {player = v, character = Character, humanoid = Humanoid, rootPart = RootPart})
                end

                if #validPlayers == 0 then RunService.Heartbeat:Wait(); return end

                local needNewTarget = false
                if not currentTarget then
                    needNewTarget = true
                else
                    local targetStillValid = false
                    for _, target in ipairs(validPlayers) do
                        if target.player == currentTarget.player then
                            targetStillValid = true
                            currentTarget = target
                            break
                        end
                    end
                    if not targetStillValid then needNewTarget = true end
                end

                if needNewTarget and #validPlayers > 0 then
                    local closestDist = math.huge
                    local closestTarget = nil
                    for _, target in ipairs(validPlayers) do
                        if target.rootPart then
                            local dist = (LocalRoot.Position - target.rootPart.Position).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                closestTarget = target
                            end
                        end
                    end
                    currentTarget = closestTarget
                    killAllSpinAngle = 0
                end

                if currentTarget and currentTarget.rootPart then
                    LocalHumanoid.Sit = false
                    killAllSpinAngle = killAllSpinAngle + spinSpeed
                    if killAllSpinAngle > math.pi * 2 then killAllSpinAngle = killAllSpinAngle - math.pi * 2 end
                    local targetPos = currentTarget.rootPart.Position
                    local offsetX = math.cos(killAllSpinAngle) * Flags.teleportDistance
                    local offsetZ = math.sin(killAllSpinAngle) * Flags.teleportDistance
                    local newPosition = Vector3.new(targetPos.X + offsetX, targetPos.Y + 5, targetPos.Z + offsetZ)
                    LocalRoot.CFrame = CFrame.new(newPosition, targetPos)
                end
            end)
        end
        RunService.Heartbeat:Wait()
    end
end)

task.spawn(function()
    while true do
        if Flags.targetTeleport and Flags.selectedTarget then
            pcall(function()
                local LocalChar = LocalPlayer.Character
                if not LocalChar then RunService.Heartbeat:Wait(); return end
                local LocalHumanoid = LocalChar:FindFirstChild("Humanoid")
                local LocalRoot = LocalChar:FindFirstChild("HumanoidRootPart")
                if not LocalHumanoid or not LocalRoot then RunService.Heartbeat:Wait(); return end

                local target = Flags.selectedTarget
                if not target then return end
                local targetChar = target.Character
                if not targetChar then return end
                if targetChar:FindFirstChild("ForceField") then return end
                local targetHumanoid = targetChar:FindFirstChild("Humanoid")
                if not targetHumanoid or targetHumanoid.Health <= 0 then return end
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if not targetRoot then return end

                if not originalCameraSubject then
                    originalCameraSubject = workspace.CurrentCamera.CameraSubject
                    workspace.CurrentCamera.CameraSubject = targetHumanoid
                    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
                end

                LocalHumanoid.Sit = false
                spinAngle = spinAngle + spinSpeed
                if spinAngle > math.pi * 2 then spinAngle = spinAngle - math.pi * 2 end
                local targetPos = targetRoot.Position
                local offsetX = math.cos(spinAngle) * Flags.teleportDistance
                local offsetZ = math.sin(spinAngle) * Flags.teleportDistance
                local newPosition = Vector3.new(targetPos.X + offsetX, targetPos.Y + 5, targetPos.Z + offsetZ)
                LocalRoot.CFrame = CFrame.new(newPosition, targetPos)
            end)
        end
        RunService.Heartbeat:Wait()
    end
end)

task.spawn(function()
    while true do
        if Flags.constantTeleport then
            pcall(function()
                if not constantTeleportTarget or not constantTeleportTarget.Character then
                    updateConstantTarget()
                    task.wait(0.5)
                    if not Flags.constantTeleport then return end
                end
                if constantTeleportTarget and constantTeleportTarget.Character then
                    local targetChar = constantTeleportTarget.Character
                    local targetPart = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso") or targetChar:FindFirstChild("Head")
                    local localChar = LocalPlayer.Character
                    if localChar then
                        local localPart = localChar:FindFirstChild("HumanoidRootPart") or localChar:FindFirstChild("Torso") or localChar:FindFirstChild("UpperTorso") or localChar:FindFirstChild("Head")
                        if targetPart and localPart then
                            local targetCFrame = localPart.CFrame + localPart.CFrame.LookVector * 2
                            targetPart.CFrame = targetCFrame
                        end
                    end
                end
            end)
            task.wait(0.1)
        else
            task.wait(0.1)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if Flags.bladeaura then
        pcall(function()
            local LocalChar = LocalPlayer.Character
            if not LocalChar then return end
            
            local HumanoidRootPart = LocalChar:FindFirstChild("HumanoidRootPart")
            if not HumanoidRootPart then return end
            
            local rootPos = HumanoidRootPart.Position
            local attackRange = Flags.attackRange or 100
            local rangeSquared = attackRange * attackRange

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr == LocalPlayer then continue end
                
                local char = plr.Character
                if not char then continue end
                if char:FindFirstChildOfClass("ForceField") then continue end
                
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then continue end
                
                local head = char:FindFirstChild("Head")
                if not head then continue end
                if shouldNotAttack(plr) then continue end
                
                local dx = rootPos.X - head.Position.X
                local dy = rootPos.Y - head.Position.Y
                local dz = rootPos.Z - head.Position.Z
                local distSquared = dx*dx + dy*dy + dz*dz
                
                if distSquared < rangeSquared then
                    executebladekill(plr, head)
                end
            end
        end)
    end
end)

task.spawn(function()
    while true do
        if Flags.fireRateBoost then
            pcall(increaseFireRate)
            task.wait(30)
        else
            task.wait(1)
        end
    end
end)

task.spawn(function()
    local targetItems = {"Electronics", "Weapon Parts"}
    while true do
        if Flags.autoPickMaterial then
            pcall(function()
                local character = LocalPlayer.Character
                if not character then task.wait(0.1); return end
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not rootPart then task.wait(0.1); return end
                local itemFolder = workspace:FindFirstChild("Game")
                if not itemFolder then task.wait(0.1); return end
                local entities = itemFolder:FindFirstChild("Entities")
                if not entities then task.wait(0.1); return end
                local itemPickup = entities:FindFirstChild("ItemPickup")
                if not itemPickup then task.wait(0.1); return end

                for _, l in pairs(itemPickup:GetChildren()) do
                    for _, v in pairs(l:GetChildren()) do
                        if v:IsA("MeshPart") or v:IsA("Part") then
                            local prompt = v:FindFirstChildOfClass("ProximityPrompt")
                            if prompt and table.find(targetItems, prompt.ObjectText) then
                                rootPart.CFrame = v.CFrame + Vector3.new(0, 2, 0)
                                prompt.RequiresLineOfSight = false
                                prompt.HoldDuration = 0
                                task.wait(0.05)
                                if fireproximityprompt then
                                    fireproximityprompt(prompt)
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.1)
        else
            task.wait(0.1)
        end
    end
end)

task.spawn(function()
    while true do
        if Flags.autoEquip and Signal and item and item.inventory and item.inventory.items then
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        local hasWeapon = false
                        for _, v in next, item.inventory.items do
                            if v.name == Flags.weaponType then
                                hasWeapon = true
                                Signal.FireServer("equip", v.guid)
                                break
                            end
                        end
                        if not hasWeapon and Flags.autoBuyWeapon then
                            requestPurchase(Flags.weaponType, false)
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

-- 11. 自动护甲 (Moon 逻辑)
task.spawn(function()
    while true do
        if Flags.autoVest then
            pcall(function()
                -- 1. 检查背包，没有就发起购买请求（加入队列）
                if not hasItemInInventory(Flags.vestType) then
                    requestPurchase(Flags.vestType, false)
                end
                
                -- 2. 检查是否存活
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if not humanoid or humanoid.Health <= 0 then return end

                -- 3. 检查属性/状态
                local armor = LocalPlayer:GetAttribute('armor')
                if armor == nil then armor = 0 end
                
                local isRagdoll = LocalPlayer:GetAttribute("isRagdoll") == true
                
                -- 4. 如果护甲低于 30（Moon 的阈值）或者完全没护甲，且未倒地
                if armor < 30 and not isRagdoll then
                    -- 优先穿选定的护甲
                    local targetVest = finditem(Flags.vestType)
                    
                    -- 如果没找到选定的，找背包里随便一个 Vest
                    if not targetVest then
                        for _, v in pairs(Inventory.items) do
                            if v.subtype == "vest" then
                                targetVest = v
                                break
                            end
                        end
                    end
                    
                    -- 执行穿戴与静默消耗
                    if targetVest then
                        FireServer("equip", targetVest.guid)
                        FireServer("useConsumable", targetVest.guid)
                        -- 静默删除，防止背包堵塞
                        FireServer("removeItem", targetVest.guid)
                    end
                end
            end)
        end
        RunService.Heartbeat:Wait()
    end
end)

-- 12. 自动回血 (Moon 逻辑)
task.spawn(function()
    while true do
        if Flags.autoHealth then
            pcall(function()
                -- 1. 检查背包，没有就发起购买请求（加入队列）
                if not hasItemInInventory(Flags.healItem) then
                    requestPurchase(Flags.healItem, false)
                end
                
                -- 2. 检查是否存活
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if not humanoid or humanoid.Health <= 0 then return end
                
                -- 3. 如果未满血，就吃血
                if humanoid.Health < humanoid.MaxHealth then
                    local healItemObj = finditem(Flags.healItem)
                    
                    if healItemObj then
                        FireServer("equip", healItemObj.guid)
                        FireServer("useConsumable", healItemObj.guid)
                        -- 静默删除，防止背包堵塞
                        FireServer("removeItem", healItemObj.guid)
                    end
                end
            end)
        end
        RunService.Heartbeat:Wait()
    end
end)

task.spawn(function()
    local originalPosition = nil
    local isTeleporting = false
    local lastCheck = 0
    local checkInterval = 0.5
    
    local maskBuyPositions = {
        ["Black Bandana"] = CFrame.new(605.8108520507812, 6.388720989227295, -1017.9218139648438),
        ["Surgeon Mask"] = CFrame.new(1158.7906494140625, 6.38798713684082, -975.1675415039062),
        ["Hockey Mask"] = CFrame.new(1438.619140625, 8.291711807250977, -143.85137939453125)
    }
    
    while true do
        if Flags.autoMask then
            pcall(function()
                if tick() - lastCheck < checkInterval then
                    return
                end
                lastCheck = tick()
                
                if isTeleporting then
                    return
                end
                
                local character = LocalPlayer.Character
                if not character then
                    RunService.Heartbeat:Wait()
                    return
                end
                
                local hasMaskEquipped = false
                for _, child in pairs(character:GetChildren()) do
                    if child.Name == Flags.maskType or child.Name == "Black Bandana" or child.Name == "Surgeon Mask" or child.Name == "Hockey Mask" then
                        hasMaskEquipped = true
                        break
                    end
                end
                
                if not hasMaskEquipped then
                    isTeleporting = true
                    
                    local hasMask = false
                    local maskGuid = nil
                    for i, v in next, Inventory.items do
                        if v.name == Flags.maskType or v.name == "Black Bandana" or v.name == "Surgeon Mask" or v.name == "Hockey Mask" then
                            hasMask = true
                            maskGuid = v.guid
                            break
                        end
                    end
                    
                    if hasMask then
                        FireServer("equip", maskGuid)
                        FireServer("wearMask", maskGuid)
                        isTeleporting = false
                        return
                    end
                    
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        originalPosition = rootPart.CFrame
                        
                        local buyPosition = maskBuyPositions[Flags.maskType] or maskBuyPositions["Black Bandana"]
                        rootPart.CFrame = buyPosition
                        
                        task.wait(0.3)
                        
                        local purchaseSuccess = false
                        for attempt = 1, 3 do
                            if purchaseSuccess then break end
                            pcall(function()
                                InvokeServer('attemptPurchase', Flags.maskType)
                                purchaseSuccess = true
                            end)
                            if not purchaseSuccess then
                                task.wait(0.2)
                            end
                        end
                        
                        task.wait(0.2)
                        
                        for i, v in next, Inventory.items do
                            if v.name == Flags.maskType or v.name == "Black Bandana" or v.name == "Surgeon Mask" or v.name == "Hockey Mask" then
                                FireServer("equip", v.guid)
                                FireServer("wearMask", v.guid)
                                break
                            end
                        end
                        
                        if originalPosition then
                            rootPart.CFrame = originalPosition
                            originalPosition = nil
                        end
                        
                        isTeleporting = false
                    else
                        isTeleporting = false
                    end
                end
            end)
        end
        RunService.Heartbeat:Wait()
    end
end)

task.spawn(function()
    while true do
        if Flags.callPhone then
            pcall(function()
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then
                        task.spawn(function()
                            local ok, id = Signal.InvokeServer("attemptCall", p.UserId)
                            if ok then
                                Signal.FireServer("sendPhoneAction", id, "hangup")
                            end
                        end)
                    end
                end
            end)
        end
        RunService.Heartbeat:Wait()
    end
end)

task.spawn(function()
    while true do
        if Flags.arrestAura then
            pcall(function()
                local character = LocalPlayer.Character
                if not character then RunService.Heartbeat:Wait(); return end
                local myRoot = character:FindFirstChild("HumanoidRootPart")
                if not myRoot then RunService.Heartbeat:Wait(); return end
                
                if not hasItemInInventory("Handcuffs") then
                    requestPurchase("Handcuffs", false)
                    task.wait(0.1)
                end
                
                local ClientReplicator = devv.load("ClientReplicator")
                
                for _, player in pairs(Players:GetPlayers()) do
                    if player == LocalPlayer then continue end
                    if not player.Character then continue end
                    
                    local hum = player.Character:FindFirstChild("Humanoid")
                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                    
                    if hum and root and hum.Health > 0 and hum.Health < Flags.arrestHealthThreshold then
                        local distance = (myRoot.Position - root.Position).Magnitude
                        if distance <= Flags.arrestDistance then
                            if not ClientReplicator.Get(player, "cuffed") then
                                for _, v in pairs(Inventory.items) do
                                    if v.name == "Handcuffs" then
                                        FireServer("equip", v.guid)
                                        FireServer("cuffPlayer", player)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        RunService.Heartbeat:Wait()
    end
end)

-- ============================================================
-- 加载 UI 库 (Library UI 1)
-- ============================================================

local library = loadstring(game:HttpGet("https://pastebin.com/raw/A2ds5g7y", true))()

-- ============================================================
-- 创建主窗口
-- ============================================================

local window = library:new("QELua V3 - 经典UI")

-- ============================================================
-- Tab 1: 购买
-- ============================================================
local BuyTab = window:Tab("购买")
local buySection = BuyTab:section("物品选择", true)

local itemList = getItemList()
local selectedItemForBuy = nil

local itemDropdown = buySection:Dropdown("选择物品", "Items", itemList, function(value)
    selectedItemForBuy = value
end)

buySection:Button("购买物品", function()
    if selectedItemForBuy then
        buyItem(selectedItemForBuy)
    end
end)

buySection:Button("购买子弹", function()
    if selectedItemForBuy then
        buyAmmo(selectedItemForBuy)
    end
end)

local autoBuySection = BuyTab:section("自动购买", true)

autoBuySection:Toggle("自动购买", "autoBuy", false, function(state)
    autoBuyEnabled = state
    if state then
        task.spawn(autoBuyLoop)
    end
end)

autoBuySection:Button("刷新物品列表", function()
    local newList = getItemList()
    itemDropdown:SetOptions(newList)
end)

-- ============================================================
-- Tab 2: 玩家
-- ============================================================
local PlayerTab = window:Tab("玩家")
local moveSection = PlayerTab:section("移动", true)

moveSection:Slider("加速设置", "SpeedSlider", 1, 1, 15, false, function(value)
    Flags.speed = value
end)

moveSection:Toggle("速度开关", "speed", true, function(value)
    Flags.tpEnabled = value
    if value then startTPWalk() else stopTPWalk() end
end)

moveSection:Toggle("连跳", "jump", false, function(value)
    Flags.jumpEnabled = value
    if value then
        jumpConnection = UserInputService.JumpRequest:Connect(function()
            if humanoid and humanoid.Health > 0 then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if jumpConnection then
            jumpConnection:Disconnect()
            jumpConnection = nil
        end
    end
end)

-- ============================================================
-- Tab 3: 战斗
-- ============================================================
local CombatTab = window:Tab("战斗")
local attackSection = CombatTab:section("攻击设置", true)

attackSection:Dropdown("超级拳", "hitMOD", {"超级拳", "普通拳", "跳踢", "普通踢", "超级挥击", "普通挥击"}, function(value)
    local modes = {
        ["超级拳"] = "meleemegapunch",
        ["普通拳"] = "meleepunch",
        ["跳踢"] = "meleejumpKick",
        ["普通踢"] = "meleekick",
        ["超级挥击"] = "meleemegaswing",
        ["普通挥击"] = "meleeswing"
    }
    Flags.hitMOD = modes[value] or "meleemegapunch"
end)

attackSection:Dropdown("选择投掷武器", "hiPart", {"Tomahawk", "Ninja Star"}, function(value)
    Flags.hiPart = value
    hiPart = value
end)

attackSection:Toggle("一击秒人", "manualIntercept", false, function(value)
    Flags.manualIntercept = value
end)

attackSection:Toggle("不装备直接攻击", "noEquipAttack", false, function(value)
    Flags.noEquipAttack = value
end)

attackSection:Toggle("全枪射速提升", "fireRateBoost", false, function(value)
    Flags.fireRateBoost = value
end)

local auraSection = CombatTab:section("光环", true)

auraSection:Toggle("杀戮光环", "killAura", false, function(value)
    Flags.killAura = value
end)

auraSection:Toggle("自动踩踏", "autoStomp", false, function(value)
    Flags.autoStomp = value
end)

auraSection:Toggle("自动抓取", "autoGrab", false, function(value)
    Flags.autoGrab = value
end)

auraSection:Toggle("自动复仇反击", "autoRevenge", true, function(value)
    Flags.autoRevenge = value
    -- 如果用户手动关闭了 UI 开关，立刻强制中止正在进行中的复仇
    if not value and isRevengeActive then
        stopRevenge("用户关闭开关")
    end
end)

auraSection:Slider("复仇击杀次数", "killCountRequired", 2, 1, 10, false, function(value)
    Flags.killCountRequired = value
end)

auraSection:Toggle("战斧光环", "bladeaura", false, function(value)
    Flags.bladeaura = value
end)

auraSection:Slider("攻击距离", "attackRange", 100, 1, 200, false, function(value)
    Flags.attackRange = value
    rpgAttackDistance = value
end)

local equipSection = CombatTab:section("自动装备", true)

equipSection:Toggle("持续传送玩家", "constantTeleport", false, function(value)
    Flags.constantTeleport = value
    if value then updateConstantTarget() end
end)

equipSection:Dropdown("指虎/武器", "weaponType", {"Brass Knuckles", "Fists", "Fireaxe", "Baton", "Baseball Bat", "Katana"}, function(value)
    Flags.weaponType = value
end)

equipSection:Toggle("自动装备", "autoEquip", false, function(value)
    Flags.autoEquip = value
end)

equipSection:Toggle("自动购买武器", "autoBuyWeapon", false, function(value)
    Flags.autoBuyWeapon = value
end)

local vestSection = CombatTab:section("自动护甲", true)

vestSection:Dropdown("护甲类型", "vestType", {"Light Vest", "Heavy Vest", "Military Vest", "EOD Vest"}, function(value)
    Flags.vestType = value
end)

vestSection:Toggle("自动护甲", "autoVest", false, function(value)
    Flags.autoVest = value
end)

local healSection = CombatTab:section("自动回血", true)

healSection:Dropdown("回血物品", "healItem", {"Bandage", "Chicken", "Cookie", "Taco"}, function(value)
    Flags.healItem = value
end)

healSection:Toggle("自动回血", "autoHealth", false, function(value)
    Flags.autoHealth = value
end)

local maskSection = CombatTab:section("自动口罩", true)

maskSection:Dropdown("口罩类型", "maskType", {"Black Bandana", "Surgeon Mask", "Hockey Mask"}, function(value)
    Flags.maskType = value
end)

maskSection:Toggle("自动口罩", "autoMask", false, function(value)
    Flags.autoMask = value
end)

local phoneSection = CombatTab:section("电话 & 逮捕", true)

phoneSection:Toggle("电话骚扰", "callPhone", false, function(value)
    Flags.callPhone = value
end)

phoneSection:Slider("逮捕距离", "arrestDistance", 30, 5, 100, false, function(value)
    Flags.arrestDistance = value
end)

phoneSection:Slider("血量阈值", "arrestHealthThreshold", 5, 1, 50, false, function(value)
    Flags.arrestHealthThreshold = value
end)

phoneSection:Toggle("逮捕光环", "arrestAura", false, function(value)
    Flags.arrestAura = value
end)

local uniformSection = CombatTab:section("制服", true)

uniformSection:Button("穿上警察制服", function()
    pcall(function()
        local uniformSuccess, hatSuccess = getPoliceUniform()
        if uniformSuccess and hatSuccess then
            print("✅ 已穿上警察制服+警帽")
        elseif uniformSuccess then
            print("✅ 穿上警察制服（未找到警帽）")
        else
            print("❌ 未找到警察制服")
        end
    end)
end)

uniformSection:Button("戴上小丑帽", function()
    pcall(function()
        local clownSuccess = getClownHat()
        if clownSuccess then
            print("✅ 已戴上小丑帽")
        else
            print("❌ 未找到小丑帽")
        end
    end)
end)
-- ============================================================
-- Tab: 击杀（移植自 Snow Ohio Combat）
-- ============================================================
local KillTab = window:Tab("击杀(Snow)")
local killTargetSection = KillTab:section("目标选择", true)

local function getSnowTargetList()
    local list = {"ALL"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    return list
end

-- 目标玩家（这里用单选下拉，ALL=全体；如需多选可重复添加多次）
local snowTargetDropdown = killTargetSection:Dropdown("目标玩家", "snowTarget", getSnowTargetList(), function(value)
    if value == "ALL" then
        SnowCombat.targetPlayers = {"ALL"}
    else
        SnowCombat.targetPlayers = {value}
    end
end)

-- 自动刷新 Snow 目标下拉（事件驱动）
local function updateSnowTargetDropdown()
    local playerNames = {"ALL"}
    local seen = {["ALL"] = true}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not seen[player.Name] then
            seen[player.Name] = true
            table.insert(playerNames, player.Name)
        end
    end
    pcall(function() snowTargetDropdown:SetOptions(playerNames) end)
end

updateSnowTargetDropdown()
Players.PlayerAdded:Connect(updateSnowTargetDropdown)
Players.PlayerRemoving:Connect(updateSnowTargetDropdown)

-- 击杀方式
killTargetSection:Dropdown("击杀方式", "snowKillMode",
    {"Ninja Star", "Tomahawk", "Banana Peel", "Snowball", "Gun Kill"},
    function(value)
        SnowCombat.fbsx = value
    end
)

-- 自动击杀
killTargetSection:Toggle("自动击杀", "snowAura", false, function(state)
    SnowCombat.aurablade = state
    if state then
        -- 开启时先确保击杀物在背包（没有则自动购买）
        snowEnsureKillItem()
        snowThrow()
    end
end)

killTargetSection:Toggle("自动装备 Raygun", "snowAutoEquipRaygun", false, function(state)
    snowAutoEquipRaygun = state
    if state then
        snowAutoEquipRaygunTick()  -- 立即尝试一次
    end
end)

-- 闪现
killTargetSection:Toggle("闪现", "snowBlink", false, function(state)
    SnowCombat.isBlinkActive = state
    if not state then SnowCombat.originalPosition = nil end
end)

-- TP玩家
killTargetSection:Toggle("TP玩家", "snowTpPlayer", false, function(state)
    SnowCombat.tpplayfb = state
end)

-- 偏移
local killOffsetSection = KillTab:section("TP 偏移", true)
killOffsetSection:Slider("X", "snowFbx", 0, -20, 20, false, function(v) SnowCombat.fbx = v end)
killOffsetSection:Slider("Y", "snowFby", 0, -20, 20, false, function(v) SnowCombat.fby = v end)
killOffsetSection:Slider("Z", "snowFbz", 5, -20, 20, false, function(v) SnowCombat.fbz = v end)

-- 刷新目标下拉（跟随在线玩家变化）
killTargetSection:Button("刷新目标列表", function()
    if snowTargetDropdown and snowTargetDropdown.SetOptions then
        snowTargetDropdown:SetOptions(getSnowTargetList())
    end
end)
-- ============================================================
-- Tab 4: 传送
-- ============================================================
local TeleportTab = window:Tab("传送")

local playerList = getOnlinePlayers()
local selectedTargetName = "选择玩家"

local playerDropdown = TeleportTab:section("目标选择", true):Dropdown("选择传送目标", "targetPlayer", playerList, function(value)
    selectedTargetName = value
    if value == "选择玩家" then
        Flags.selectedTarget = nil
    else
        for _, v in ipairs(Players:GetPlayers()) do
            if v.Name == value then
                Flags.selectedTarget = v
                break
            end
        end
    end
end)

-- 自动刷新传送目标下拉（事件驱动）
local function updatePlayerDropdown()
    local playerNames = {"选择玩家"}
    local seen = {["选择玩家"] = true}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not seen[player.Name] then
            seen[player.Name] = true
            table.insert(playerNames, player.Name)
        end
    end
    pcall(function() playerDropdown:SetOptions(playerNames) end)
end

updatePlayerDropdown()
Players.PlayerAdded:Connect(updatePlayerDropdown)
Players.PlayerRemoving:Connect(updatePlayerDropdown)

local teleportSection = TeleportTab:section("传送功能", true)

teleportSection:Toggle("传送所有人", "killAll", false, function(value)
    Flags.killAll = value
end)

teleportSection:Toggle("传送到选中目标", "targetTeleport", false, function(value)
    Flags.targetTeleport = value
    if not value then
        if originalCameraSubject then
            workspace.CurrentCamera.CameraSubject = originalCameraSubject
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            originalCameraSubject = nil
        end
        spinAngle = 0
    end
end)

teleportSection:Slider("传送距离", "teleportDistance", 180, 1, 190, false, function(value)
    Flags.teleportDistance = value
    lowHpThresholddd = value
end)

teleportSection:Button("回到自己视角", function()
    pcall(function()
        if originalCameraSubject then
            workspace.CurrentCamera.CameraSubject = originalCameraSubject
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            originalCameraSubject = nil
        else
            local LocalChar = LocalPlayer.Character
            if LocalChar then
                local LocalHumanoid = LocalChar:FindFirstChild("Humanoid")
                if LocalHumanoid then
                    workspace.CurrentCamera.CameraSubject = LocalHumanoid
                    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
                end
            end
        end
    end)
end)

-- ============================================================
-- 自动复仇反击模块 (动态击杀次数 + 踩踏 + 视角 + 拳头)
-- ============================================================
Flags.autoRevenge = true  -- 默认开启

local isRevengeActive = false
local revengeTarget = nil
local revengeKillCount = 0     -- 当前已击杀次数
local isTargetDead = false     -- 目标当前是否死亡
local deathTime = 0            -- 记录死亡时间用于超时放弃

local originalTpWalk = false
local originalHitMOD = "meleemegapunch"
local originalAutoStomp = false
local originalWeaponType = "Brass Knuckles"
local originalAutoEquip = false
local savedCameraSubject = nil
local savedCameraType = nil

-- 恢复原本状态的函数
local function stopRevenge(reason)
    if isRevengeActive then
        print("[复仇系统] 停止复仇: " .. tostring(reason) .. " (当前击杀数: " .. revengeKillCount .. ")")
        isRevengeActive = false
        revengeTarget = nil
        revengeKillCount = 0
        isTargetDead = false
        
        -- 1. 恢复原本的开关状态
        Flags.killAura = false
        Flags.autoStomp = originalAutoStomp 
        Flags.tpEnabled = originalTpWalk
        Flags.hitMOD = originalHitMOD
        
        -- 恢复原本的自动装备设置
        Flags.weaponType = originalWeaponType
        Flags.autoEquip = originalAutoEquip
        
        -- 2. 恢复视角到自己身上
        local cam = workspace.CurrentCamera
        if cam then
            local myChar = LocalPlayer.Character
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if myHum then
                cam.CameraSubject = myHum
                cam.CameraType = Enum.CameraType.Custom
            elseif savedCameraSubject then
                cam.CameraSubject = savedCameraSubject
                cam.CameraType = savedCameraType or Enum.CameraType.Custom
            end
        end
        savedCameraSubject = nil
        savedCameraType = nil
    end
end

-- 监听被杀事件
local killMessageEvent = ReplicatedStorage.devv.remoteStorage:FindFirstChild("killMessage")
if killMessageEvent then
    killMessageEvent.OnClientEvent:Connect(function(killerName, weaponName, distance)
        if not Flags.autoRevenge then return end
        if killerName == LocalPlayer.Name then return end
        
        local killer = Players:FindFirstChild(killerName)
        if killer then
            local requiredKills = Flags.killCountRequired or 2
            print("[复仇系统] 你被 " .. killerName .. " 击杀了！目标: 击杀他 " .. requiredKills .. " 次。")
            
            -- 如果已经在复仇中，先打断重置
            if isRevengeActive then stopRevenge("切换新目标") task.wait(0.1) end
            
            -- 记录当前状态以便恢复
            originalTpWalk = Flags.tpEnabled
            originalHitMOD = Flags.hitMOD
            originalAutoStomp = Flags.autoStomp
            originalWeaponType = Flags.weaponType
            originalAutoEquip = Flags.autoEquip
            
            -- 记录当前相机状态
            local cam = workspace.CurrentCamera
            if cam then
                savedCameraSubject = cam.CameraSubject
                savedCameraType = cam.CameraType
            end
            
            revengeTarget = killer
            revengeKillCount = 0
            isTargetDead = false
            isRevengeActive = true
            
            -- 强制配置：超级拳、开启光环、开启踩踏、开启传送
            Flags.hitMOD = "meleemegapunch" 
            Flags.killAura = true
            Flags.autoStomp = true
            Flags.tpEnabled = true
            
            -- 强制装备拳头
            Flags.weaponType = "Fists"
            Flags.autoEquip = true
            
            -- 复仇执行循环
            task.spawn(function()
                while isRevengeActive and revengeTarget do
                    task.wait(0.05)
                    
                    -- 如果用户中途关掉了开关，立刻中止
                    if not Flags.autoRevenge then
                        stopRevenge("开关被关闭")
                        break
                    end
                    
                    local char = LocalPlayer.Character
                    local targetChar = revengeTarget.Character
                    local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
                    
                    -- 【逻辑核心】处理目标死亡与复活
                    if not targetHum or targetHum.Health <= 0 then
                        if not isTargetDead then
                            -- 刚刚检测到死亡
                            isTargetDead = true
                            revengeKillCount = revengeKillCount + 1
                            deathTime = tick()
                            print("[复仇系统] 已击杀目标 " .. revengeKillCount .. " 次。")
                            
                            -- 动态读取需要的击杀次数
                            local needed = Flags.killCountRequired or 2
                            if revengeKillCount >= needed then
                                stopRevenge("已击杀目标 " .. needed .. " 次，复仇完成")
                                break
                            else
                                print("[复仇系统] 等待目标复活以进行第 " .. (revengeKillCount + 1) .. " 次击杀...")
                            end
                        else
                            -- 目标处于死亡等待复活状态
                            -- 如果等了 15 秒还没复活，或者目标退出了，就放弃
                            if tick() - deathTime > 15 or not revengeTarget.Parent then
                                stopRevenge("目标未复活或已退出游戏")
                                break
                            end
                        end
                    else
                        -- 目标活着
                        if isTargetDead then
                            -- 目标复活了，重置死亡标记，继续追杀
                            isTargetDead = false
                            print("[复仇系统] 目标已复活，继续执行第 " .. (revengeKillCount + 1) .. " 次击杀...")
                        end
                        
                        -- 实时锁定视角到目标
                        if cam then
                            cam.CameraSubject = targetHum
                            cam.CameraType = Enum.CameraType.Custom
                        end
                        
                        -- 传送到目标脚底下 10 格
                        if char and char:FindFirstChild("HumanoidRootPart") and targetChar:FindFirstChild("HumanoidRootPart") then
                            local targetRoot = targetChar.HumanoidRootPart
                            char.HumanoidRootPart.CFrame = CFrame.new(targetRoot.Position - Vector3.new(0, 10, 0))
                        end
                    end
                end
            end)
        end
    end)
end

teleportSection:Button("刷新玩家列表", function()
    local newList = getOnlinePlayers()
    playerDropdown:SetOptions(newList)
    print("✅ 玩家列表已刷新")
end)

-- ============================================================
-- Tab 5: 物品
-- ============================================================
local ItemsTab = window:Tab("物品")
local itemSection = ItemsTab:section("物品设置", true)

itemSection:Toggle("自动捡物品", "autoPickMaterial", false, function(value)
    Flags.autoPickMaterial = value
end)

-- ============================================================
-- Tab 6: 白名单
-- ============================================================
local WhitelistTab = window:Tab("白名单")
local whitelistSection = WhitelistTab:section("白名单管理", true)

local whitelistPlayers = {}
local function getWhitelistPlayerList()
    local list = {}
    for _, name in pairs(Flags.whitelistNames) do
        table.insert(list, name)
    end
    return list
end

local whitelistAddDropdown = whitelistSection:Dropdown("选择要添加的玩家", "addWhitelist", getOnlinePlayers(), function(value)
    if value and value ~= "选择玩家" then
        for _, v in ipairs(Players:GetPlayers()) do
            if v.Name == value and v ~= LocalPlayer then
                local alreadyExists = false
                for _, name in pairs(Flags.whitelistNames) do
                    if name == value then alreadyExists = true; break end
                end
                if not alreadyExists then
                    table.insert(Flags.whitelistNames, value)
                    table.insert(Flags.whitelistIds, v.UserId)
                    print("✅ 已添加 " .. value .. " 到白名单")
                end
            end
        end
    end
end)

-- 自动刷新白名单下拉（事件驱动）
local function updateWhitelistDropdown()
    local playerNames = {"选择玩家"}
    local seen = {["选择玩家"] = true}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not seen[player.Name] then
            seen[player.Name] = true
            table.insert(playerNames, player.Name)
        end
    end
    pcall(function() whitelistAddDropdown:SetOptions(playerNames) end)
end

updateWhitelistDropdown()
Players.PlayerAdded:Connect(updateWhitelistDropdown)
Players.PlayerRemoving:Connect(updateWhitelistDropdown)

whitelistSection:Button("清空白名单", function()
    Flags.whitelistNames = {}
    Flags.whitelistIds = {}
    print("✅ 白名单已清空")
end)

whitelistSection:Toggle("不攻击好友", "noAttackFriends", false, function(value)
    Flags.noAttackFriends = value
end)

-- ============================================================
-- Tab: Ohio（加入玩家 / 加入 VC）
-- ============================================================
local OhioTab = window:Tab("JoinPlayer")
local ohioSection = OhioTab:section("加入玩家", true)

local ohioInput = ""

local ohioTextbox = ohioSection:Textbox(
    "玩家名 / UserId / @name",
    "ohioInput",
    "输入玩家名或ID",   -- default 不能为 ""，否则 FocusLost 会回退
    function(text)
        -- 占位符不算有效输入
        if text ~= "输入玩家名或ID" then
            ohioInput = text
        else
            ohioInput = ""
        end
    end
)

ohioSection:Button("加入玩家", function()
    local input = ohioInput
    if input == nil or input == "" then
        StarterGui:SetCore("SendNotification", {
            Title = "Ohio",
            Text = "请输入玩家名或 UserId",
            Duration = 3,
        })
        return
    end
    OhioJoin.JoinPlayer(input)
end)

local ohioVcSection = OhioTab:section("VC 服务器", true)
ohioVcSection:Button("加入 VC 服务器", function()
    OhioJoin.JoinVCServer()
end)


-- ============================================================
-- UI 控制
-- ============================================================
local uiTab = window:Tab("UI")
local uiSection = uiTab:section("UI控制", true)

uiSection:Button("销毁 UI", function()
    game:GetService("CoreGui"):FindFirstChild("frosty"):Destroy()
end)

-- ============================================================
-- 脚本信息
-- ============================================================
local aboutTab = window:Tab("关于")
local aboutSection = aboutTab:section("脚本信息", true)

aboutSection:Label("脚本名称：QELua v3")
aboutSection:Label("版本：v0.5.4.3")
aboutSection:Label("作者：匿名")

-- 智能制作战斧（有Tomahawk后永久只制作不领取）
local craftRunning = true
local craftConnection = nil
local hasEverHadTomahawk = false

local function hasTomahawk()
    for _, item in pairs(inventory.items) do
        if item.name == "Tomahawk" then
            return true
        end
    end
    return false
end

craftConnection = RunService.Heartbeat:Connect(function()
    if not craftRunning then
        craftConnection:Disconnect()
        craftConnection = nil
        return
    end
    pcall(function()
        Signal.InvokeServer("beginCraft", 'TomahawkCraft')
        if not hasEverHadTomahawk then
            if hasTomahawk() then
                hasEverHadTomahawk = true
            else
                Signal.InvokeServer("claimCraft", 'TomahawkCraft')
            end
        end
    end)
end)

task.spawn(function()
    while craftRunning and task.wait(0.15) do
        pcall(function()
            Signal.InvokeServer("beginCraft", 'TomahawkCraft')
            if not hasEverHadTomahawk then
                if hasTomahawk() then
                    hasEverHadTomahawk = true
                else
                    Signal.InvokeServer("claimCraft", 'TomahawkCraft')
                end
            end
        end)
    end
end)

-- 停止：craftRunning = false

local DisassembleEvent = ReplicatedStorage:FindFirstChild("devv")
if DisassembleEvent then
    DisassembleEvent = DisassembleEvent:FindFirstChild("remoteStorage")
    if DisassembleEvent then
        DisassembleEvent = DisassembleEvent:FindFirstChild("craftingDisassemble")
    end
end

if not DisassembleEvent then return end

local function getM1911Guid()
    if not inventory or not inventory.items then return nil end
    for guid, data in pairs(inventory.items) do
        if data.name == "M1911" then
            return guid
        end
    end
    return nil
end

task.spawn(function()
    while true do
        pcall(function()
            local guid = getM1911Guid()
            if guid then
                DisassembleEvent:InvokeServer({ [guid] = 1 })
            end
        end)
        task.wait(0.5)
    end
end)
