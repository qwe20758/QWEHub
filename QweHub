local NotificationHolder = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Module.Lua"))() 
local Notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Client.Lua"))()
wait(0.1) 
Notification:Notify( 
    {Title = "Qwe Hub", Description = "正在验证白名单…"}, 
    {OutlineColor = Color3.fromRGB(80, 80, 80), Time = 5, Type = "image"}, 
    {Image = "rbxthumb://type=Asset&id=5107182114&w=150&h=150", ImageColor = Color3.fromRGB(255, 84, 84)} 
) 
wait(0.2) 

local WHITELIST = {
    ["yikokll"] = true,
    ["PlayerOne"] = true,
    ["PlayerTwo"] = true,
    ["GameMaster"] = true
}

-- 加载Orion库
local OrionLib
local success, err = pcall(function()
    OrionLib = loadstring(game:HttpGet("https://pastebin.com/raw/CXYajrg1"))()
end)
if not success or not OrionLib then
    warn("Orion库加载失败: " .. (err or "未知错误"))
    return
end

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 白名单验证（核心修改：验证玩家名称）
-- 注意：玩家名称区分大小写，需与实际昵称完全一致
if not WHITELIST[player.Name] then
    Notification:Notify( 
        {Title = "Qwe Hub", Description = "您未被列入白名单，请联系作者添加，您的信息以为您复制到粘贴板中\n您的昵称: " .. player.Name}, 
        {OutlineColor = Color3.fromRGB(80, 80, 80), Time = 20, Type = "image"}, 
        {Image = "rbxthumb://type=Asset&id=5107182114&w=150&h=150", ImageColor = Color3.fromRGB(255, 84, 84)} 
    ) 
    -- 执行未通过验证的操作（如退出）
    loadstring(game:HttpGet("https://pastebin.com/raw/Y757Akd6"))()   
    return
end

-- 验证通过：显示成功通知
Notification:Notify( 
    {Title = "验证成功", Description = "欢迎您，" .. player.Name}, 
    {OutlineColor = Color3.fromRGB(80, 80, 80), Time = 3, Type = "image"}, 
    {Image = "rbxthumb://type=Asset&id=5107182114&w=150&h=150", ImageColor = Color3.fromRGB(84, 255, 100)} 
) 

-- 工具函数：创建圆角
local function makeRound(obj, radius)
    if obj and obj:IsA("GuiObject") then
        local corner = Instance.new("UICorner")
        corner.CornerRadius = radius or UDim.new(0.5, 0)
        corner.Parent = obj
    end
end

-- 创建主窗口并加载核心功能
local function loadExternalScript(url)
    local success, result = pcall(function()
        local scriptContent = game:HttpGet(url, true)  -- 加载脚本内容
        loadstring(scriptContent)()  -- 执行脚本
        return true
    end)
    return success, result
end
               local OrionLib =loadstring(game:HttpGet("https://pastebin.com/raw/CXYajrg1"))()
local LBLG = Instance.new("ScreenGui", getParent)
local LBL = Instance.new("TextLabel", getParent)
local player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local currentSound = nil  -- 存储当前播放的音乐
local inputSoundId = ""  -- 临时存储输入的音乐ID
local currentVolume = 0.5  -- 记录当前音量（默认0.5）
local currentPlaybackSpeed = 1  -- 音乐倍速（默认1倍速）
local selectedPlayer = nil  -- 存储选中的玩家名称
local loopTeleportActive = false  -- 基础循环传送状态
local loopTeleportConnection = nil  -- 基础循环传送连接
local dirLoopActive = false  -- 方向循环传送状态
local dirLoopConnection = nil  -- 方向循环传送连接
local currentDir = "前"  -- 当前方向（默认前）
local followDistance = 5  -- 跟随距离（默认5 studs）
local isSpectating = false  -- 观战状态
local originalCameraType = Camera.CameraType  -- 原始相机类型
local originalCameraSubject = Camera.CameraSubject
local savedMusics = {
    {id = "1839246711", name = "JumpStyle"},
    {id = "1845918434", name = "义勇军进行曲"},
    {id = "1837879082", name = "彩虹瀑布"},
    {id = "593721301", name = "待开发"},
    {id = "1307863977", name = "待开发"}
}
-- 预设脚本列表（名称 + 链接）
local presetScripts = {
    {name = "XA脚本", url = "https://raw.gitcode.com/Xingtaiduan/Scripts/raw/main/Loader.lua"},  -- 替换为实际链接
    {name = "音乐播放器脚本", url = "https://pastebin.com/raw/你的音乐脚本链接"},  -- 替换为实际链接
    {name = "视角控制脚本", url = "https://pastebin.com/raw/你的视角脚本链接"},    -- 替换为实际链接
    {name = "自定义脚本1", url = "https://pastebin.com/raw/你的自定义链接1"},     -- 可添加更多
    {name = "自定义脚本2", url = "https://pastebin.com/raw/你的自定义链接2"}      -- 可添加更多
}
local selectedScript = nil  -- 当前选中的预设脚本

LBLG.Name = "LBLG"
LBLG.Parent = game.CoreGui
LBLG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LBLG.Enabled = true
LBL.Name = "LBL"
LBL.Parent = LBLG
LBL.BackgroundColor3 = Color3.new(1, 1, 1)
LBL.BackgroundTransparency = 1
LBL.BorderColor3 = Color3.new(0, 0, 0)
LBL.Position = UDim2.new(0.75,0,0.010,0)
LBL.Size = UDim2.new(0, 133, 0, 30)
LBL.Font = Enum.Font.GothamSemibold
LBL.Text = "TextLabel"
LBL.TextColor3 = Color3.new(1, 1, 1)
LBL.TextScaled = true
LBL.TextSize = 14
LBL.TextWrapped = true
LBL.Visible = true

local FpsLabel = LBL
local Heartbeat = game:GetService("RunService").Heartbeat
local LastIteration, Start
local FrameUpdateTable = { }

local function HeartbeatUpdate()
	LastIteration = tick()
	for Index = #FrameUpdateTable, 1, -1 do
		FrameUpdateTable[Index + 1] = (FrameUpdateTable[Index] >= LastIteration - 1) and FrameUpdateTable[Index] or nil
	end
	FrameUpdateTable[1] = LastIteration
	local CurrentFPS = (tick() - Start >= 1 and #FrameUpdateTable) or (#FrameUpdateTable / (tick() - Start))
	CurrentFPS = CurrentFPS - CurrentFPS % 1
	FpsLabel.Text = (""..os.date("")..""..os.date("")..""..os.date(""))
end
Start = tick()
Heartbeat:Connect(HeartbeatUpdate)
local Window = OrionLib:MakeWindow({Name = "Qwe Hub", HidePremium = false, SaveConfig = true,IntroText = "Qwe Hub", ConfigFolder = "Qwe Hub"})

local NotificationHolder = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Module.Lua"))() 
 local Notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Client.Lua"))()
 wait(0.1) 
 Notification:Notify( 
     {Title = "Qwe Hub", Description = "初始化成功"}, 
     {OutlineColor = Color3.fromRGB(80, 80, 80),Time = 5, Type = "image"}, 
     {Image = "http://www.roblox.com/asset/?id=4483345998", ImageColor = Color3.fromRGB(84, 255, 100)} 
 ) 
 wait(0.2) 
local about = Window:MakeTab({
    Name = "基本信息",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false

})

about:AddParagraph("用户名:"," "..game.Players.LocalPlayer.Name.."")
about:AddParagraph("用户ID", tostring(player.UserId))
about:AddParagraph("批量执行器:"," "..identifyexecutor().."")
about:AddParagraph("服务器ID"," "..game.GameId.."")
about:AddParagraph("白名单状态", "<font color='green'>已授权</font>")
  
    local about = Window:MakeTab({
    Name = "公告",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false

})

about:AddParagraph("此脚本为测试版")
about:AddParagraph("此脚本为半缝合脚本")
about:AddParagraph("首创功能较少请见谅")
about:AddParagraph("持续更新")

local Tab = Window:MakeTab({

    Name = "实用",

    Icon = "rbxassetid://4483345998",

    PremiumOnly = false

})

Tab:AddTextbox({

	Name = "移动速度设置",

	Default = "",

	TextDisappear = true,

	Callback = function(Value)

		while task.wait() do
game:GetService("Players").LocalPlayer.Character.Humanoid.WalkSpeed = Value
end

	end

})

Tab:AddTextbox({

	Name = "跳跃高度设置",

	Default = "",

	TextDisappear = true,

	Callback = function(Value)

		while task.wait() do
game:GetService("Players").LocalPlayer.Character.Humanoid.JumpPower = 1000
end

	end

})

Tab:AddTextbox({

	Name = "平滑移动速度设置",

	Default = "",

	TextDisappear = true,

	Callback = function(Value)

		local tspeed = Value
local hb = game:GetService("RunService").Heartbeat
local tpwalking = true
local player = game:GetService("Players")
local lplr = player.LocalPlayer
local chr = lplr.Character
local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
while tpwalking and hb:Wait() and chr and hum and hum.Parent do
  if hum.MoveDirection.Magnitude > 0 then
    if tspeed then
      chr:TranslateBy(hum.MoveDirection * tonumber(tspeed))
    else
      chr:TranslateBy(hum.MoveDirection)
    end
  end
end
end

})

Tab:AddTextbox({

	Name = "重力设置",

	Default = "",

	TextDisappear = true,

	Callback = function(Value)

		game.Workspace.Gravity = Value

	end

})

	Tab:AddTextbox({
	Name = "当前血量",
	Default = "",
	TextDisappear = true,
	Callback = function(Value)
		game.Players.LocalPlayer.Character.Humanoid.Health = Value
	end	 
})

    Tab:AddTextbox({
	Name = "相机最大缩放距离",
	Default = "",
	TextDisappear = true,
	Callback = function(Value)
		game.Players.LocalPlayer.CameraMaxZoomDistance = Value
	end	 
})

Tab:AddTextbox({
	Name = "相机视野角度",
	Default = "",
	TextDisappear = true,
	Callback = function(Value)
		workspace.CurrentCamera.FieldOfView = Value
	end	 
})

Tab:AddToggle({
    Name = "透视",
    Default = false,
    Callback = function(enabled)
        if enabled then
            -- 加载透视功能
            pcall(function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/Lucasfin000/SpaceHub/main/UESP'))()
                OrionLib:MakeNotification({Name = "成功", Content = "透视功能已开启", Time = 2})
            end)
        else
            
        end
    end,
    Color = Color3.fromRGB(128, 0, 128) -- 紫色标识
})

Tab:AddToggle({

	Name = "夜视",

	Default = false,

	Callback = function(Value)

		if Value then

		    game.Lighting.Ambient = Color3.new(1, 1, 1)

		else

		    game.Lighting.Ambient = Color3.new(0, 0, 0)

		end

	end

})

local Clipon = false
local Stepped

Tab:AddToggle({
    Name = "穿墙模式",
    Default = false,
    Callback = function(enabled)
        Clipon = enabled
        local Workspace = game:GetService("Workspace")
        local Players = game:GetService("Players")
        
        -- 断开已有连接
        if Stepped then
            Stepped:Disconnect()
        end
        
        if enabled then
            -- 开启穿墙：禁用角色碰撞
            Stepped = game:GetService("RunService").Stepped:Connect(function()
                if Clipon then
                    local playerChar = Workspace:FindFirstChild(Players.LocalPlayer.Name)
                    if playerChar then
                        for _, part in pairs(playerChar:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                else
                    Stepped:Disconnect()
                end
            end)
        else
            -- 关闭穿墙：恢复碰撞
            local playerChar = Workspace:FindFirstChild(Players.LocalPlayer.Name)
            if playerChar then
                for _, part in pairs(playerChar:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end,
    Color = Color3.fromRGB(128, 0, 128)
})

Tab:AddButton({
	Name = "玩家进入提示",
	Callback = function()
      	loadstring(game:HttpGet("https://raw.githubusercontent.com/boyscp/scriscriptsc/main/bbn.lua"))()
  	end
})

Tab:AddButton({

	Name = "飞行",

	Callback = function()
local NotificationHolder = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Module.Lua"))() 
 local Notification = loadstring(game:HttpGet("https://raw.githubusercontent.com/BocusLuke/UI/main/STX/Client.Lua"))()
 wait(0.5) 
 Notification:Notify( 
     {Title = "qwe Hub", Description = "欢迎使用"}, 
     {OutlineColor = Color3.fromRGB(80, 80, 80),Time = 5, Type = "image"}, 
     {Image = "http://www.roblox.com/asset/?id=4483345998", ImageColor = Color3.fromRGB(255, 84, 84)} 
 ) 
 wait(1) 
       loadstring(game:HttpGet("https://pastebin.com/raw/eL4u06fT"))() 

  	end    

})

Tab:AddButton({
	Name = "qwe传送玩家/添加传送点/scirpt",
	Callback = function()
       loadstring(game:HttpGet("https://pastebin.com/raw/LmTmvXzk"))()
  	end    
})

Tab:AddButton({
	Name = "铁拳",
	Callback = function()
       loadstring(game:HttpGet('https://raw.githubusercontent.com/0Ben1/fe/main/obf_rf6iQURzu1fqrytcnLBAvW34C9N55kS9g9G3CKz086rC47M6632sEd4ZZYB0AYgV.lua.txt'))()
  	end    
})

Tab:AddButton({
	Name = "FPS设置",
	Callback = function()
     loadstring(game:HttpGet("https://raw.githubusercontent.com/gclich/FPS-X-GUI/main/FPS_X.lua"))()
  	end    
})

local musicTab = Window:MakeTab({
    Name = "音乐专区",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

musicTab:AddTextbox({
    Name = "输入音乐ID",
    Default = "",
    TextDisappear = false,
    Callback = function(Value)
        inputSoundId = Value
        OrionLib:MakeNotification({Name = "已保存", Content = "音乐ID已更新", Time = 2})
    end
})

musicTab:AddButton({
    Name = "播放音乐",
    Callback = function()
        if currentSound then
            currentSound:Stop()
            currentSound:Destroy()
            currentSound = nil
        end
        
        local soundId = tonumber(inputSoundId)
        if soundId then
            currentSound = Instance.new("Sound")
            currentSound.SoundId = "rbxassetid://" .. soundId
            currentSound.Volume = currentVolume
            currentSound.PlaybackSpeed = currentPlaybackSpeed  -- 应用当前倍速
            currentSound.Looped = true
            currentSound.Parent = game.Workspace
            currentSound:Play()
            OrionLib:MakeNotification({
                Name = "播放成功",
                Content = "正在播放 ID: " .. soundId .. " | 音量: " .. currentVolume .. " | 倍速: " .. currentPlaybackSpeed .. "x",
                Time = 3
            })
        else
            OrionLib:MakeNotification({Name = "错误", Content = "请输入有效数字ID", Time = 3})
        end
    end
})

local Section = musicTab:AddSection({

	Name = "---------------------------------------预设音乐----------------------------------------------------------"

})

local function stopCurrentSound()
    if currentSound then
        currentSound:Stop()
        currentSound:Destroy()
        currentSound = nil
    end
end

local function playSelectedMusic()
    if not selectedMusic then
        OrionLib:MakeNotification({
            Name = "未选择音乐",
            Content = "请先从下拉框选择音乐",
            Time = 3
        })
        return
    end
    
    -- 播放选中的音乐
    local success, err = pcall(function()
        stopCurrentSound()  -- 先停止当前音乐
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. selectedMusic.id
        sound.Volume = currentVolume
        sound.PlaybackSpeed = currentPlaybackSpeed
        sound.Looped = true  -- 循环播放
        sound.Parent = game.Workspace
        sound:Play()
        currentSound = sound
        
        OrionLib:MakeNotification({
            Name = "播放中",
            Content = "当前音乐: " .. selectedMusic.name,
            Time = 3
        })
    end)
    
    if not success then
        OrionLib:MakeNotification({
            Name = "播放失败",
            Content = "音乐资源无法加载",
            Time = 3
        })
    end
end

-- 1. 预设音乐选择下拉框（仅选择，不自动播放）
local function getMusicOptions()
    local options = {}
    for _, music in ipairs(savedMusics) do
        table.insert(options, music.name)
    end
    return options
end

musicTab:AddDropdown({
    Name = "选择预设音乐",
    Options = getMusicOptions(),
    Default = "请选择音乐",
    Callback = function(selectedName)
        -- 查找选中的音乐信息
        for _, music in ipairs(savedMusics) do
            if music.name == selectedName then
                selectedMusic = music
                OrionLib:MakeNotification({
                    Name = "已选择",
                    Content = "待播放: " .. music.name,
                    Time = 2
                })
                break
            end
        end
    end
})

-- 2. 播放按钮（核心新增）
musicTab:AddButton({
    Name = "▶ 播放选中音乐",
    Callback = playSelectedMusic  -- 调用播放函数
})

local Section = musicTab:AddSection({

	Name = "---------------------------------------音乐设置----------------------------------------------------------"

})

musicTab:AddTextbox({
    Name = "音乐音量设置",
    Default = "0.5",
    TextDisappear = false,
    Callback = function(Value)
        local volume = tonumber(Value)
        if volume then
            volume = math.clamp(volume, 0, 100)
            currentVolume = volume
            if currentSound then currentSound.Volume = volume end
            OrionLib:MakeNotification({Name = "音量更新", Content = "当前音量: " .. currentVolume, Time = 2})
        else
            OrionLib:MakeNotification({Name = "错误", Content = "请输入0-100之间的数字", Time = 2})
        end
    end
})

-- 新增：音乐倍速设置
musicTab:AddTextbox({
    Name = "音乐倍速设置",
    Default = "1",
    TextDisappear = false,
    Callback = function(Value)
        local speed = tonumber(Value)
        if speed then
            speed = math.clamp(speed, 0.1, 5)  -- 限制倍速范围（0.1x到5x）
            currentPlaybackSpeed = speed
            if currentSound then currentSound.PlaybackSpeed = speed end  -- 实时生效
            OrionLib:MakeNotification({
                Name = "倍速更新",
                Content = "当前倍速: " .. currentPlaybackSpeed .. "x",
                Time = 2
            })
        else
            OrionLib:MakeNotification({
                Name = "错误",
                Content = "请输入0.1-5之间的数字",
                Time = 2
            })
        end
    end
})

musicTab:AddButton({
    Name = "显示当前音量与倍速",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "当前设置",
            Content = "音量: " .. currentVolume .. " | 倍速: " .. currentPlaybackSpeed .. "x",
            Time = 3
        })
    end
})

musicTab:AddButton({
    Name = "停止播放",
    Callback = function()
        if currentSound then
            currentSound:Stop()
            currentSound:Destroy()
            currentSound = nil
            OrionLib:MakeNotification({Name = "已停止", Content = "音乐已停止", Time = 2})
        else
            OrionLib:MakeNotification({Name = "提示", Content = "没有播放中的音乐", Time = 2})
        end
    end
})

musicTab:AddButton({

	Name = "停止播放的所有声音",	
	
	Callback = function()
	
-- 停止所有音乐/音效的函数
local function stopAllSounds()
    -- 遍历工作区(Workspace)中的所有Sound实例
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("Sound") then
            descendant:Stop() -- 停止播放
        end
    end
    
    -- 若有其他容器（如玩家背包等），可继续遍历
    -- 例如遍历玩家角色中的Sound
    game.Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            for _, descendant in ipairs(character:GetDescendants()) do
                if descendant:IsA("Sound") then
                    descendant:Stop()
                end
            end
        end)
    end)
end

-- 调用函数停止所有音乐
stopAllSounds()
	
	end

})

-- 传送玩家标签页（保持不变）
local teleportTab = Window:MakeTab({
    Name = "传送玩家",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- 生成玩家列表选项
local function getPlayerList()
    local players = {}
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player then  -- 排除自己
            table.insert(players, p.Name)
        end
    end
    return players
end

-- 玩家选择下拉框
teleportTab:AddDropdown({
    Name = "选择目标玩家",
    Options = getPlayerList(),
    Default = "请选择玩家",
    Callback = function(selected)
        selectedPlayer = selected
        OrionLib:MakeNotification({
            Name = "已选择",
            Content = "目标玩家: " .. selected,
            Time = 2
        })
    end
})

-- 单次传送按钮
teleportTab:AddButton({
    Name = "传送到选中玩家",
    Callback = function()
        if not selectedPlayer then
            OrionLib:MakeNotification({
                Name = "未选择玩家",
                Content = "请先从下拉框选择目标玩家",
                Time = 3
            })
            return
        end
        
        local targetPlayer = game.Players:FindFirstChild(selectedPlayer)
        if targetPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetCharacter = targetPlayer.Character
            if targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = targetCharacter.HumanoidRootPart.CFrame
                OrionLib:MakeNotification({
                    Name = "传送成功",
                    Content = "已传送到: " .. selectedPlayer,
                    Time = 3
                })
            else
                OrionLib:MakeNotification({
                    Name = "传送失败",
                    Content = selectedPlayer .. "的角色未加载",
                    Time = 3
                })
            end
        else
            OrionLib:MakeNotification({
                Name = "错误",
                Content = "目标玩家不存在或你的角色未加载",
                Time = 3
            })
        end
    end
})

-- 方向循环传送开关（支持上下方向）
teleportTab:AddToggle({
    Name = "锁定传送该玩家",
    Default = false,
    Callback = function(state)
        -- 关闭基础循环传送（避免冲突）
        if state and loopTeleportActive then
            loopTeleportActive = false
            loopTeleportConnection:Disconnect()
            OrionLib:MakeNotification({
                Name = "提示",
                Content = "已自动关闭重合循环传送",
                Time = 2
            })
        end
        
        dirLoopActive = state
        if state then
            if not selectedPlayer then
                OrionLib:MakeNotification({Name = "未选择玩家", Content = "请先选择目标玩家", Time = 3})
                dirLoopActive = false
                return false
            end
            
            dirLoopConnection = RunService.Heartbeat:Connect(function()
                local targetPlayer = game.Players:FindFirstChild(selectedPlayer)
                if targetPlayer and player.Character and player.Character.HumanoidRootPart and targetPlayer.Character and targetPlayer.Character.HumanoidRootPart then
                    local targetRoot = targetPlayer.Character.HumanoidRootPart
                    local offset = Vector3.new(0, 0, 0)
                    
                    -- 根据方向和距离计算偏移量
                    if currentDir == "前" then
                        offset = targetRoot.CFrame.LookVector * followDistance
                    elseif currentDir == "后" then
                        offset = -targetRoot.CFrame.LookVector * followDistance
                    elseif currentDir == "左" then
                        offset = -targetRoot.CFrame.RightVector * followDistance
                    elseif currentDir == "右" then
                        offset = targetRoot.CFrame.RightVector * followDistance
                    elseif currentDir == "上" then
                        offset = Vector3.new(0, followDistance, 0)
                    elseif currentDir == "下" then
                        offset = Vector3.new(0, -followDistance, 0)
                    end
                    
                    -- 应用偏移传送
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(targetRoot.Position + offset) * targetRoot.CFrame.Rotation
                else
                    if dirLoopActive then
                        dirLoopActive = false
                        dirLoopConnection:Disconnect()
                        OrionLib:MakeNotification({Name = "跟随停止", Content = "目标状态异常", Time = 3})
                    end
                end
            end)
            OrionLib:MakeNotification({
                Name = "方向跟随开启",
                Content = "已开始向" .. currentDir .. "方向跟随（距离: " .. followDistance .. "）",
                Time = 3
            })
        else
            if dirLoopConnection then
                dirLoopConnection:Disconnect()
                dirLoopConnection = nil
            end
        end
    end
})

teleportTab:AddDropdown({
    Name = "选择循环方向",
    Options = {"前", "后", "左", "右", "上", "下"},
    Default = "后",
    Callback = function(dir)
        currentDir = dir
        OrionLib:MakeNotification({
            Name = "方向已更新",
            Content = "当前方向: " .. dir,
            Time = 2
        })
    end
})

-- 距离设置文本框
teleportTab:AddTextbox({
    Name = "设置传送距离",
    Default = "5",
    TextDisappear = false,
    Callback = function(Value)
        local distance = tonumber(Value)
        if distance and distance > 0 then
            followDistance = distance
            OrionLib:MakeNotification({
                Name = "距离已更新",
                Content = "当前跟随距离: " .. followDistance .. " studs",
                Time = 2
            })
        else
            OrionLib:MakeNotification({
                Name = "错误",
                Content = "请输入正数",
                Time = 2
            })
        end
    end
})

-- 观看玩家视角开关
teleportTab:AddToggle({
    Name = "观看选中玩家视角",
    Default = false,
    Callback = function(state)
        isSpectating = state
        if state then
            if not selectedPlayer then
                OrionLib:MakeNotification({Name = "未选择玩家", Content = "请先选择目标玩家", Time = 3})
                isSpectating = false
                return false
            end
            
            local targetPlayer = game.Players:FindFirstChild(selectedPlayer)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid") then
                originalCameraType = Camera.CameraType
                originalCameraSubject = Camera.CameraSubject
                Camera.CameraType = Enum.CameraType.Custom
                Camera.CameraSubject = targetPlayer.Character.Humanoid
                OrionLib:MakeNotification({Name = "观战开启", Content = "正在观看: " .. selectedPlayer, Time = 3})
            else
                OrionLib:MakeNotification({Name = "观战失败", Content = "目标角色不完整", Time = 3})
                isSpectating = false
                return false
            end
        else
            Camera.CameraType = originalCameraType
            Camera.CameraSubject = originalCameraSubject
        end
    end
})

-- 刷新玩家列表按钮
teleportTab:AddButton({
    Name = "刷新玩家列表",
    Callback = function()
        local newPlayers = getPlayerList()
        teleportTab:Clear()
        -- 重新添加所有控件（逻辑与之前一致）
        OrionLib:MakeNotification({Name = "已刷新", Content = "玩家列表已更新", Time = 2})
    end
})

local Tab = Window:MakeTab({

	Name = "FE脚本专区",

	Icon = "rbxassetid://4483345998",

	PremiumOnly = false

})

Tab:AddButton({

	Name = "撸管r6",	
	
	Callback = function()
	
loadstring(game:HttpGet("https://pastefy.app/wa3v2Vgm/raw"))()

    end
    
})

Tab:AddButton({

	Name = "撸管r15",

	Callback = function()
	
loadstring(game:HttpGet("https://pastefy.app/YZoglOyJ/raw"))()

    end

})	

local loaderTab = Window:MakeTab({
    Name = "脚本加载",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- 1. 预设脚本下拉框（核心功能）
local function getScriptOptions()
    local options = {}
    for _, script in ipairs(presetScripts) do
        table.insert(options, script.name)  -- 显示脚本名称
    end
    return options
end

loaderTab:AddDropdown({
    Name = "选择脚本",
    Options = getScriptOptions(),
    Default = "请选择脚本",
    Callback = function(selectedName)
        -- 根据选择的名称查找对应的链接
        for _, script in ipairs(presetScripts) do
            if script.name == selectedName then
                selectedScript = script
                OrionLib:MakeNotification({
                    Name = "已选择",
                    Content = "选中脚本: " .. script.name,
                    Time = 2
                })
                break
            end
        end
    end
})

-- 3. 加载执行按钮
loaderTab:AddButton({
    Name = "执行",
    Callback = function()
        -- 优先使用预设脚本，无选中则使用自定义链接
        local targetUrl = nil
        local scriptName = nil
        
        if selectedScript then
            targetUrl = selectedScript.url
            scriptName = selectedScript.name
        elseif customUrl and customUrl ~= "" then
            targetUrl = customUrl
            scriptName = "自定义脚本"
        else
            OrionLib:MakeNotification({
                Name = "未选择脚本",
                Content = "请先选择预设脚本或输入自定义链接",
                Time = 3
            })
            return
        end
        
        -- 显示加载中提示
        OrionLib:MakeNotification({
            Name = "加载中",
            Content = "正在加载: " .. scriptName,
            Time = 5
        })
        
        -- 执行加载
        local success, err = loadExternalScript(targetUrl)
        if success then
            OrionLib:MakeNotification({
                Name = "加载成功",
                Content = scriptName .. "已执行",
                Time = 3
            })
        else
            OrionLib:MakeNotification({
                Name = "加载失败",
                Content = "错误: " .. tostring(err),
                Time = 5
            })
        end
    end

})         		

local Tab = Window:MakeTab({

	Name = "本地客户端修改",

	Icon = "rbxassetid://4483345998",

	PremiumOnly = false

})

local Section = Tab:AddSection({

	Name = "-----------------------------------仅供娱乐--别人不可见----------------------------------------------------------"
})

Tab:AddButton({

	Name = "天空",	
	
	Callback = function()
	
local s = Instance.new("Sky")
s.Name = "Sky"
s.Parent = game.Lighting
local skyboxID = 111479496264017
s.SkyboxBk = "http://www.roblox.com/asset/?id="..skyboxID
s.SkyboxDn = "http://www.roblox.com/asset/?id="..skyboxID
s.SkyboxFt = "http://www.roblox.com/asset/?id="..skyboxID
s.SkyboxLf = "http://www.roblox.com/asset/?id="..skyboxID
s.SkyboxRt = "http://www.roblox.com/asset/?id="..skyboxID
s.SkyboxUp = "http://www.roblox.com/asset/?id="..skyboxID
game.Lighting.TimeOfDay = 12

   end,
})

Tab:AddButton({

	Name = "垃圾贴花",

	Callback = function()
	
decalID = 111479496264017
function exPro(root)
for _, v in pairs(root:GetChildren()) do
if v:IsA("Decal") and v.Texture ~= "http://www.roblox.com/asset/?id="..decalID then
v.Parent = nil
elseif v:IsA("BasePart") then
v.Material = "Plastic"
v.Transparency = 0
local One = Instance.new("Decal", v)
local Two = Instance.new("Decal", v)
local Three = Instance.new("Decal", v)
local Four = Instance.new("Decal", v)
local Five = Instance.new("Decal", v)
local Six = Instance.new("Decal", v)
One.Texture = "http://www.roblox.com/asset/?id="..decalID
Two.Texture = "http://www.roblox.com/asset/?id="..decalID
Three.Texture = "http://www.roblox.com/asset/?id="..decalID
Four.Texture = "http://www.roblox.com/asset/?id="..decalID
Five.Texture = "http://www.roblox.com/asset/?id="..decalID
Six.Texture = "http://www.roblox.com/asset/?id="..decalID
One.Face = "Front"
Two.Face = "Back"
Three.Face = "Right"
Four.Face = "Left"
Five.Face = "Top"
Six.Face = "Bottom"
end
exPro(v)
end
end
function asdf(root)
for _, v in pairs(root:GetChildren()) do
asdf(v)
end
end
exPro(game.Workspace)
asdf(game.Workspace)
  
   end,
})

