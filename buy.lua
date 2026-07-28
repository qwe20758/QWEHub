-- ============================================================
-- 购买功能 (纯逻辑版)
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 加载必要模块
local devv = require(ReplicatedStorage:FindFirstChild("devv"))
local Signal = devv and devv.load("Signal")
local InvokeServer = Signal.InvokeServer
local item = devv and devv.load("v3item")
local Inventory = item.inventory

-- ============================================================
-- 配置
-- ============================================================

local config = {
    autoBuyEnabled = false,
    autoBuyInterval = 0.0001,
    selectedItem = nil,
    isBuying = false,
}

-- ============================================================
-- 核心函数
-- ============================================================

-- 检查背包是否有该物品
local function hasItemInInventory(itemName)
    if not itemName then return false end
    for _, v in pairs(Inventory.items) do
        if v.name == itemName then
            return true
        end
    end
    return false
end

-- 获取物品位置
local function getItemPosition(itemName)
    local itemsOnSale = Workspace:FindFirstChild("ItemsOnSale")
    if not itemsOnSale then return nil end
    
    for _, item in ipairs(itemsOnSale:GetChildren()) do
        if item.Name == itemName then
            if item:IsA("BasePart") then
                return item.Position, item.CFrame
            end
            if item:IsA("Model") and item.PrimaryPart then
                return item.PrimaryPart.Position, item.PrimaryPart.CFrame
            end
            for _, child in ipairs(item:GetDescendants()) do
                if child:IsA("BasePart") then
                    return child.Position, child.CFrame
                end
            end
        end
    end
    return nil, nil
end

-- 瞬移瞬回购买
local function purchaseWithTeleport(itemName, isAmmo)
    if config.isBuying or not itemName then return false end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local pos = getItemPosition(itemName)
    if not pos then return false end
    
    config.isBuying = true
    local originalCFrame = rootPart.CFrame
    
    -- 瞬移
    rootPart.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
    
    -- 购买
    if isAmmo then
        InvokeServer("attemptPurchaseAmmo", itemName)
    else
        InvokeServer("attemptPurchase", itemName)
    end
    
    -- 瞬回
    rootPart.CFrame = originalCFrame
    
    config.isBuying = false
    return true
end

-- 购买物品
local function buyItem(itemName)
    if not itemName then return false end
    return purchaseWithTeleport(itemName, false)
end

-- 购买弹药
local function buyAmmo(itemName)
    if not itemName then return false end
    return purchaseWithTeleport(itemName, true)
end

-- 获取物品列表
local function getItemList()
    local itemsOnSale = Workspace:FindFirstChild("ItemsOnSale")
    if not itemsOnSale then return {} end
    
    local list = {}
    local seen = {}
    
    for _, item in ipairs(itemsOnSale:GetChildren()) do
        local name = item.Name
        if not seen[name] then
            seen[name] = true
            table.insert(list, name)
        end
    end
    
    table.sort(list)
    return list
end

-- 自动购买循环
local function autoBuyLoop()
    while config.autoBuyEnabled do
        if config.selectedItem and not hasItemInInventory(config.selectedItem) then
            buyItem(config.selectedItem)
        end
        task.wait(config.autoBuyInterval)
    end
end

-- ============================================================
-- 公开API
-- ============================================================

local BuyModule = {
    -- 购买函数
    buyItem = buyItem,
    buyAmmo = buyAmmo,
    
    -- 工具函数
    getItemList = getItemList,
    hasItemInInventory = hasItemInInventory,
    
    -- 自动购买控制
    AutoBuy = {
        -- 开启/关闭
        toggle = function(state)
            config.autoBuyEnabled = state
            if state then
                task.spawn(autoBuyLoop)
            end
        end,
        
        -- 设置目标物品
        setItem = function(itemName)
            config.selectedItem = itemName
        end,
        
        -- 获取当前状态
        isEnabled = function()
            return config.autoBuyEnabled
        end,
        
        -- 获取当前目标
        getItem = function()
            return config.selectedItem
        end,
        
        -- 设置间隔时间
        setInterval = function(interval)
            config.autoBuyInterval = interval
        end,
        
        -- 获取间隔时间
        getInterval = function()
            return config.autoBuyInterval
        end,
    },
    
    -- 状态检查
    isBuying = function()
        return config.isBuying
    end,
}

return BuyModule