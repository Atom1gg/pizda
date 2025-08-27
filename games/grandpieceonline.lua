-- Umbrella Hub FULL
local UI_LIB_URL = 'https://github.com/Atom1gg/pizda/raw/refs/heads/main/1.lua'
local UmbrellaHub = loadstring(game:HttpGet(UI_LIB_URL))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ================================
-- SAFE MODULE
-- ================================
local SafeModule = {
    enabled = false,
    speedDetectionBypass = false,
    walkSpeedBypass = false,
    abilityProtection = false,
    waitHook = false,
    -- Сохраняем оригинальные функции для восстановления
    originalWait = nil,
    originalMetatable = nil
}

local function SetupSpeedDetectionBypass()
    if SafeModule.speedDetectionBypass then return end
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt,false)
        local oldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self,...)
            local method = getnamecallmethod()
            local args = {...}
            if method=="FireServer" and args[1]==10 then
                return 1
            end
            return oldNamecall(self,...)
        end)
        setreadonly(mt,true)
        SafeModule.speedDetectionBypass=true
    end)
end

local function SetupWalkSpeedBypass()
    if SafeModule.walkSpeedBypass then return end
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt,false)
        local oldIndex = mt.__index
        mt.__index = newcclosure(function(self,key)
            if key=="WalkSpeed" and self:IsA("Humanoid") then return 16 end
            return oldIndex(self,key)
        end)
        setreadonly(mt,true)
        SafeModule.walkSpeedBypass=true
    end)
end

local function SetupAbilityProtection()
    if SafeModule.abilityProtection then return end
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt,false)
        local oldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self,...)
            local method = getnamecallmethod()
            local args = {...}
            if method=="InvokeServer" and (args[1]=="Soru" or args[1]=="Geppo") then
                wait(0.2)
            end
            return oldNamecall(self,...)
        end)
        setreadonly(mt,true)
        SafeModule.abilityProtection=true
    end)
end

local function SetupWaitHook()
    if SafeModule.waitHook then return end
    pcall(function()
        if not SafeModule.originalWait then
            SafeModule.originalWait = wait
        end
        getgenv().wait=function(time)
            if SafeModule.enabled then 
                return SafeModule.originalWait(math.max(time or 0,0.1)) 
            end
            return SafeModule.originalWait(time)
        end
        SafeModule.waitHook=true
    end)
end

local function DisableSafeMode()
    -- Восстанавливаем wait функцию
    if SafeModule.originalWait then
        getgenv().wait = SafeModule.originalWait
    end
    
    -- Сбрасываем флаги
    SafeModule.speedDetectionBypass = false
    SafeModule.walkSpeedBypass = false
    SafeModule.abilityProtection = false
    SafeModule.waitHook = false
end

local function toggleSafeMode(state)
    SafeModule.enabled = state
    
    if state then
        -- Включаем все защиты
        SetupSpeedDetectionBypass()
        SetupWalkSpeedBypass()
        SetupAbilityProtection()
        SetupWaitHook()
        print("[Safe Mode] Включен - все защиты активированы")
    else
        -- Отключаем защиты
        DisableSafeMode()
        print("[Safe Mode] Отключен")
    end
end

--- ================================
-- WALK SPEED MODULE (BV Speed)
-- ================================
local WalkspeedModule = {
    Enabled = false,
    Speed = 16,
    BV = nil
}

local function SetupBV()
    if not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and not WalkspeedModule.BV then
        WalkspeedModule.BV = Instance.new("BodyVelocity", hrp)
        WalkspeedModule.BV.MaxForce = Vector3.new(9e9,0,9e9)
    end
end

local bvConnection
local function UpdateBV()
    if not WalkspeedModule.BV or not LocalPlayer.Character then return end
    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then
        WalkspeedModule.BV.Velocity = hum.MoveDirection * WalkspeedModule.Speed
    end
end

local function ToggleWalkspeed(state)
    WalkspeedModule.Enabled = state
    if state then
        SetupBV()
        if bvConnection then bvConnection:Disconnect() end
        bvConnection = RunService.RenderStepped:Connect(UpdateBV)
    else
        if bvConnection then bvConnection:Disconnect() bvConnection = nil end
        if WalkspeedModule.BV then WalkspeedModule.BV:Destroy() WalkspeedModule.BV = nil end
    end
end

-- ================================
-- CHEST ESP MODULE (Ð´Ð¾Ð±Ð°Ð²Ð»ÐµÐ½Ð¾ Ð² ÐºÐ°Ñ‚ÐµÐ³Ð¾Ñ€Ð¸ÑŽ World)
-- ================================
local ChestESP = {
    Enabled = false,
    ShowDistance = true,
    MaxDistance = 500,
    UpdateRate = 0.0001,
    BaseTextSize = 14,
    MinScale = 0.3,
    MaxScale = 2.5
}

local chestDrawings = {}
local chestData = {}
local colorStats = {}
local lastUpdateTime = 0
local effects = workspace:FindFirstChild("Effects")

local function CreateDrawing(type, props)
    local d = Drawing.new(type)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function LogChestColor(originalColor, chestType)
    local r, g, b = originalColor.R, originalColor.G, originalColor.B
    local colorKey = string.format("%.6f_%.6f_%.6f", r, g, b)
    
    if not colorStats[colorKey] then
        colorStats[colorKey] = {
            color = originalColor,
            type = chestType,
            count = 0
        }
    end
    
    colorStats[colorKey].count = colorStats[colorKey].count + 1
    
    print(string.format("Chest Color: %s | R:%.6f G:%.6f B:%.6f | Total: %d", 
        chestType, r, g, b, colorStats[colorKey].count))
end

local function ColorMatch(r1, g1, b1, r2, g2, b2, tolerance)
    tolerance = tolerance or 0.001
    return math.abs(r1 - r2) < tolerance and 
           math.abs(g1 - g2) < tolerance and 
           math.abs(b1 - b2) < tolerance
end

local function GetChestColorName(originalColor)
    local r, g, b = originalColor.R, originalColor.G, originalColor.B
    local chestType, espColor
    
    if ColorMatch(r, g, b, 0, 0, 0) then
        chestType = "LEGENDARY"
        espColor = Color3.fromRGB(255, 215, 0)
        return espColor, chestType
    end
    
    if ColorMatch(r, g, b, 0.639216, 0.635294, 0.647059) then
        chestType = "RARE"
        espColor = Color3.fromRGB(0, 162, 255)
    elseif ColorMatch(r, g, b, 1, 0.705882, 0.898039) then
        chestType = "MYTHIC"
        espColor = Color3.fromRGB(138, 43, 226)
    elseif ColorMatch(r, g, b, 0.423529, 0.345098, 0.294118) then
        chestType = "COMMON"
        espColor = Color3.fromRGB(139, 69, 19)
    elseif ColorMatch(r, g, b, 0.388235, 0.372549, 0.384313) then
        chestType = "UNCOMMON"
        espColor = Color3.fromRGB(192, 192, 192)
    elseif ColorMatch(r, g, b, 0.388235, 0.372549, 0.384314) then
        chestType = "UNCOMMON_2"
        espColor = Color3.fromRGB(160, 160, 160)
    else
        chestType = "UNKNOWN"
        espColor = Color3.fromRGB(255, 215, 0)
    end
    
    LogChestColor(originalColor, chestType)
    return espColor, chestType
end

local function GetPlayerPosition()
    local character = LocalPlayer and LocalPlayer.Character
    if not character then return nil end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    return humanoidRootPart and humanoidRootPart.Position
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function GetDistanceScale(distance)
    local scale = math.clamp(distance / 50, ChestESP.MinScale, ChestESP.MaxScale)
    return scale
end

local function GetChestScreenPosition(meshPart)
    local worldPos = meshPart.Position
    local screenPos, visible = Camera:WorldToViewportPoint(worldPos)
    
    if visible and screenPos.Z > 0 then
        return Vector2.new(screenPos.X, screenPos.Y), true
    end
    
    return nil, false
end

local function CreateChestESP(meshPart, groupName)
    local espColor, chestType = GetChestColorName(meshPart.Color)
    local chestId = groupName
    
    chestData[chestId] = {
        MeshPart = meshPart, 
        Type = chestType, 
        Color = espColor,
        LastUpdate = 0
    }
    
    chestDrawings[chestId] = {
        Text = CreateDrawing("Text", {
            Size = ChestESP.BaseTextSize, 
            Color = espColor, 
            Outline = true, 
            OutlineColor = Color3.new(0, 0, 0), 
            Center = true
        })
    }
end

local function RemoveChestESP(chestId)
    if chestDrawings[chestId] then
        for _, drawing in pairs(chestDrawings[chestId]) do 
            drawing:Remove() 
        end
        chestDrawings[chestId] = nil
    end
    chestData[chestId] = nil
end

local function UpdateChestESP()
    local currentTime = tick()
    if currentTime - lastUpdateTime < ChestESP.UpdateRate then return end
    lastUpdateTime = currentTime
    
    if not ChestESP.Enabled or not effects then return end
    
    local playerPos = GetPlayerPosition()
    if not playerPos then return end
    
    local toRemove = {}
    
    for chestId, drawings in pairs(chestDrawings) do
        local data = chestData[chestId]
        
        if not data or not data.MeshPart or not data.MeshPart.Parent then
            table.insert(toRemove, chestId)
            continue
        end
        
        local meshPart = data.MeshPart
        local distance = GetDistance(playerPos, meshPart.Position)
        
        if distance > ChestESP.MaxDistance then
            for _, drawing in pairs(drawings) do 
                drawing.Visible = false 
            end
            continue
        end
        
        local screenPos, visible = GetChestScreenPosition(meshPart)
        
        if not visible then
            for _, drawing in pairs(drawings) do 
                drawing.Visible = false 
            end
            continue
        end
        
        local scale = GetDistanceScale(distance)
        local textSize = math.max(10, math.floor(ChestESP.BaseTextSize * scale))
        
        drawings.Text.Text = ChestESP.ShowDistance and 
            string.format("%s [%dm]", data.Type, math.floor(distance)) or 
            data.Type
        drawings.Text.Size = textSize
        drawings.Text.Position = Vector2.new(screenPos.X, screenPos.Y)
        drawings.Text.Visible = ChestESP.Enabled
        drawings.Text.Color = data.Color
    end
    
    for _, chestId in ipairs(toRemove) do
        RemoveChestESP(chestId)
    end
end

local function FindNewChests()
    if not effects then return end
    
    for _, group in pairs(effects:GetChildren()) do
        if (group:IsA("Model") or group:IsA("Group")) and not chestData[group.Name] then
            local meshPart = group:FindFirstChildOfClass("MeshPart")
            if meshPart then
                local prompt = meshPart:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    CreateChestESP(meshPart, group.Name)
                end
            end
        end
    end
end

local function ToggleChestESP(state)
    ChestESP.Enabled = state
    if state then
    else
        for chestId, drawings in pairs(chestDrawings) do
            for _, drawing in pairs(drawings) do 
                drawing.Visible = false 
            end
        end
    end
end

-- Ð—Ð°Ð¿ÑƒÑÐºÐ°ÐµÐ¼ Ñ†Ð¸ÐºÐ»Ñ‹
spawn(function()
    while true do
        if ChestESP.Enabled and effects then
            FindNewChests()
        end
        wait(1)
    end
end)

RunService.Heartbeat:Connect(UpdateChestESP)

-- ================================
-- JUMP BOOST MODULE
-- ================================
local JumpBoostModule = {
    Enabled = false,
    Power = 50
}

RunService.RenderStepped:Connect(function()
    if JumpBoostModule.Enabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.JumpPower = JumpBoostModule.Power end
    end
end)

-- ================================
-- INFINITY JUMP MODULE
-- ================================
local InfinityJumpModule = {
    Enabled = false
}

UserInputService.JumpRequest:Connect(function()
    if InfinityJumpModule.Enabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
-- ================================
-- ИСПРАВЛЕННЫЙ ESP MODULE С ТВОЕЙ ЛОГИКОЙ
-- ================================
local ESP = {
    Enabled = false,
    ShowPlayers = true,
    ShowFruits = true,
    ShowName = true,
    ShowHealthBar = true,
    ShowPlayerBox = true, -- твоя фича с желтым квадратом
    Thickness = 1
}

local drawings = {}
local playerConnections = {}

-- Цвета по rarity (твоя логика)
local FruitRarityColors = {
    ["Common"] = Color3.fromRGB(255,255,255),
    ["Rare"] = Color3.fromRGB(173,216,230),
    ["Epic"] = Color3.fromRGB(176,196,222),
    ["Legendary"] = Color3.fromRGB(255,255,0),
    ["Mythical"] = Color3.fromRGB(216,191,216)
}

local Fruits = {
    ["Kilo-Kilo"]="Common",["Suke-Suke"]="Common",["Guru-Guru"]="Common",["Chiyu-Chiyu"]="Common",
    ["Bari-Bari"]="Rare",["Mero-Mero"]="Rare",["Horo-Horo"]="Rare",["Gomu-Gomu"]="Rare",["Bomu-Bomu"]="Rare",
    ["Yomi-Yomi"]="Epic",["Bane-Bane"]="Epic",["Kira-Kira"]="Epic",
    ["Zushi-Zushi"]="Legendary",["Gura-Gura"]="Legendary",["Suna-Suna"]="Legendary",["Hie-Hie"]="Legendary",
    ["Ito-Ito"]="Legendary",["Goro-Goro"]="Legendary",["Nikyu-Nikyu"]="Legendary",["Paw-Paw"]="Legendary",
    ["Mera-Mera"]="Legendary",["Kage-Kage"]="Legendary",["Magu-Magu"]="Legendary",["Pika-Pika"]="Legendary",
    ["Yami-Yami"]="Legendary",["Yuki-Yuki"]="Legendary",["Goru-Goru"]="Legendary",["Moku-Moku"]="Legendary",
    ["Tori-Tori"]="Mythical",["Mochi-Mochi"]="Mythical",["Ope-Ope"]="Mythical",["Doku-Doku"]="Mythical",
    ["Venom-Venom"]="Mythical",["Hito-Hito"]="Mythical",["Buddha-Buddha"]="Mythical",["Ryu-Ryu"]="Mythical",
    ["Pteranodon-Pteranodon"]="Mythical"
}

local R15_BONES={{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"UpperTorso","RightUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LowerTorso","RightUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local R6_BONES={{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}

local function CreateDrawing(type,props)
    local d = Drawing.new(type)
    for k,v in pairs(props) do d[k]=v end
    return d
end

local function GetRigType(character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then return hum.RigType end
    return character:FindFirstChild("UpperTorso") and Enum.HumanoidRigType.R15 or Enum.HumanoidRigType.R6
end

local function GetPlayerHealth(character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health, hum.MaxHealth end
    return 0,100
end

local function CleanPlayerDrawings(playerName)
    for key, drawing in pairs(drawings) do
        if string.find(key, playerName) then
            pcall(function() drawing:Remove() end)
            drawings[key] = nil
        end
    end
end

local function GetPlayerFruits(player)
    local fruits = {}
    pcall(function()
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for fruitName, rarity in pairs(Fruits) do
                local fruit = backpack:FindFirstChild(fruitName)
                if fruit then
                    table.insert(fruits, {name = fruitName, rarity = rarity})
                end
            end
        end
        if player.Character then
            for fruitName, rarity in pairs(Fruits) do
                local fruit = player.Character:FindFirstChild(fruitName)
                if fruit then
                    table.insert(fruits, {name = fruitName .. " (E)", rarity = rarity})
                end
            end
        end
    end)
    return fruits
end

-- ТВОЯ ФУНКЦИЯ: Получение bounding box для игрока (ИСПРАВЛЕННАЯ)
local function GetPlayerBoundingBox(character)
    local success, result = pcall(function()
        local parts = {}
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                table.insert(parts, part)
            end
        end
        
        if #parts == 0 then return nil end
        
        local minX, minY, minZ = math.huge, math.huge, math.huge
        local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
        
        for _, part in pairs(parts) do
            if part and part.Parent then -- дополнительная проверка
                local cf = part.CFrame
                local size = part.Size / 2
                
                local corners = {
                    cf * Vector3.new(size.X, size.Y, size.Z),
                    cf * Vector3.new(-size.X, size.Y, size.Z),
                    cf * Vector3.new(size.X, -size.Y, size.Z),
                    cf * Vector3.new(size.X, size.Y, -size.Z),
                    cf * Vector3.new(-size.X, -size.Y, size.Z),
                    cf * Vector3.new(-size.X, size.Y, -size.Z),
                    cf * Vector3.new(size.X, -size.Y, -size.Z),
                    cf * Vector3.new(-size.X, -size.Y, -size.Z)
                }
                
                for _, corner in pairs(corners) do
                    minX = math.min(minX, corner.X)
                    minY = math.min(minY, corner.Y)
                    minZ = math.min(minZ, corner.Z)
                    maxX = math.max(maxX, corner.X)
                    maxY = math.max(maxY, corner.Y)
                    maxZ = math.max(maxZ, corner.Z)
                end
            end
        end
        
        local center = Vector3.new((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2)
        local size = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
        
        return center, size
    end)
    
    if success then
        return result
    else
        return nil
    end
end

local function UpdateESP()
    pcall(function()
        for _, d in pairs(drawings) do d.Visible = false end
        if not ESP.Enabled then return end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local char = player.Character
                local head = char:FindFirstChild("Head")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                
                if not head or not hrp then continue end
                
                local headPos, headVisible = Camera:WorldToViewportPoint(head.Position)
                if not headVisible or headPos.Z <= 0 then continue end

                local rig = GetRigType(char)
                local skeletonColor = Color3.fromRGB(255, 255, 0)
                local yOffset = -45 -- ПОДНЯЛИ НИК ВЫШЕ

                -- ТВОЯ ЛОГИКА: Желтый квадрат вокруг игрока (ИСПРАВЛЕННАЯ)
                if ESP.ShowPlayerBox then
                    local center, size = GetPlayerBoundingBox(char)
                    if center and size then
                        local centerPos, centerVisible = Camera:WorldToViewportPoint(center)
                        if centerVisible and centerPos.Z > 0 then
                            -- Упрощенный bounding box - только основные линии
                            local corners = {}
                            pcall(function()
                                corners = {
                                    Camera:WorldToViewportPoint(center + Vector3.new(size.X/2, size.Y/2, 0)),
                                    Camera:WorldToViewportPoint(center + Vector3.new(-size.X/2, size.Y/2, 0)),
                                    Camera:WorldToViewportPoint(center + Vector3.new(size.X/2, -size.Y/2, 0)),
                                    Camera:WorldToViewportPoint(center + Vector3.new(-size.X/2, -size.Y/2, 0))
                                }
                            end)
                            
                            -- Рисуем простой прямоугольник (4 линии)
                            if #corners >= 4 then
                                local boxLines = {
                                    {1, 2}, {2, 4}, {4, 3}, {3, 1} -- соединяем углы
                                }
                                
                                for i, line in ipairs(boxLines) do
                                    local key = player.Name .. "_box_" .. i
                                    if not drawings[key] then
                                        drawings[key] = CreateDrawing("Line", {
                                            Thickness = 2,
                                            Color = Color3.fromRGB(255, 255, 0),
                                            Visible = false
                                        })
                                    end
                                    
                                    local p1, p2 = corners[line[1]], corners[line[2]]
                                    if p1 and p2 then
                                        drawings[key].From = Vector2.new(p1.X, p1.Y)
                                        drawings[key].To = Vector2.new(p2.X, p2.Y)
                                        drawings[key].Visible = true
                                    end
                                end
                            end
                        end
                    end
                end

                -- Skeleton ESP
                if ESP.ShowPlayers then
                    local bones = (rig == Enum.HumanoidRigType.R15) and R15_BONES or R6_BONES
                    for i, pair in ipairs(bones) do
                        local p1 = char:FindFirstChild(pair[1])
                        local p2 = char:FindFirstChild(pair[2])
                        if p1 and p2 then
                            local key = player.Name .. "_bone_" .. i
                            if not drawings[key] then
                                drawings[key] = CreateDrawing("Line", {
                                    Thickness = ESP.Thickness,
                                    Color = skeletonColor,
                                    Visible = false
                                })
                            end
                            local pos1, on1 = Camera:WorldToViewportPoint(p1.Position)
                            local pos2, on2 = Camera:WorldToViewportPoint(p2.Position)
                            if on1 and on2 and pos1.Z > 0 and pos2.Z > 0 then
                                drawings[key].From = Vector2.new(pos1.X, pos1.Y)
                                drawings[key].To = Vector2.new(pos2.X, pos2.Y)
                                drawings[key].Visible = true
                            end
                        end
                    end
                end

                -- Name ESP (ПОДНЯТ ВЫШЕ)
                if ESP.ShowName then
                    local key = player.Name .. "_name"
                    if not drawings[key] then
                        drawings[key] = CreateDrawing("Text", {
                            Text = player.Name,
                            Size = 18, -- УВЕЛИЧИЛИ НА 6 ПИКСЕЛЕЙ
                            Color = skeletonColor,
                            Center = true,
                            Outline = true,
                            OutlineColor = Color3.fromRGB(0, 0, 0),
                            Visible = false
                        })
                    end
                    drawings[key].Position = Vector2.new(headPos.X, headPos.Y + yOffset)
                    drawings[key].Visible = true
                    yOffset = yOffset - 22
                end

                -- ТВОЯ ЛОГИКА: Фрукты ESP
                if ESP.ShowFruits then
                    local fruits = GetPlayerFruits(player)
                    if #fruits == 0 then
                        -- Показываем [None] если нет фруктов
                        local key = player.Name .. "_fruit_none"
                        if not drawings[key] then
                            drawings[key] = CreateDrawing("Text", {
                                Size = 16,
                                Center = true,
                                Outline = true,
                                OutlineColor = Color3.fromRGB(0, 0, 0),
                                Visible = false
                            })
                        end
                        drawings[key].Text = "[None]"
                        drawings[key].Color = Color3.fromRGB(128, 128, 128) -- Серый цвет
                        drawings[key].Position = Vector2.new(headPos.X, headPos.Y + yOffset)
                        drawings[key].Visible = true
                        yOffset = yOffset - 20
                    else
                        -- Показываем фрукты как обычно
                        for i, fruitData in ipairs(fruits) do
                            local key = player.Name .. "_fruit_" .. i
                            if not drawings[key] then
                                drawings[key] = CreateDrawing("Text", {
                                    Size = 16, -- УВЕЛИЧИЛИ РАЗМЕР 
                                    Center = true,
                                    Outline = true,
                                    OutlineColor = Color3.fromRGB(0, 0, 0),
                                    Visible = false
                                })
                            end
                            drawings[key].Text = fruitData.name
                            drawings[key].Color = FruitRarityColors[fruitData.rarity] or Color3.fromRGB(255, 255, 255)
                            drawings[key].Position = Vector2.new(headPos.X, headPos.Y + yOffset)
                            drawings[key].Visible = true
                            yOffset = yOffset - 20
                        end
                    end
                end

                -- Health Bar ESP (ИМБОВЫЙ СТИЛЬ)
                if ESP.ShowHealthBar then
                    local cur, max = GetPlayerHealth(char)
                    local pct = math.clamp(cur / max, 0, 1)
                    
                    -- Получаем позицию ног игрока
                    local feetPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    
                    -- HP бар горизонтальный по длине игрока
                    local barWidth = 80 -- ширина бара
                    local barHeight = 8 -- толщина бара
                    
                    -- Background бар (горизонтальный)
                    local bgKey = player.Name .. "_hp_bg"
                    if not drawings[bgKey] then 
                        drawings[bgKey] = CreateDrawing("Line", {
                            Thickness = barHeight,
                            Color = Color3.fromRGB(50, 50, 50),
                            Visible = false
                        })
                    end
                    drawings[bgKey].From = Vector2.new(feetPos.X - barWidth/2, feetPos.Y + 20)
                    drawings[bgKey].To = Vector2.new(feetPos.X + barWidth/2, feetPos.Y + 20)
                    drawings[bgKey].Visible = true

                    -- Health Fill (горизонтальный)
                    local fillKey = player.Name .. "_hp_fill"
                    if not drawings[fillKey] then 
                        drawings[fillKey] = CreateDrawing("Line", {
                            Thickness = barHeight - 2,
                            Visible = false
                        })
                    end
                    local fillWidth = barWidth * pct
                    drawings[fillKey].From = Vector2.new(feetPos.X - barWidth/2, feetPos.Y + 20)
                    drawings[fillKey].To = Vector2.new(feetPos.X - barWidth/2 + fillWidth, feetPos.Y + 20)
                    drawings[fillKey].Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
                    drawings[fillKey].Visible = true

                    -- Health Text ПОД НОГАМИ (ИМБОВЫЙ ЭФФЕКТ)
                    local hpTextKey = player.Name .. "_hp_text"
                    if not drawings[hpTextKey] then 
                        drawings[hpTextKey] = CreateDrawing("Text", {
                            Size = 16,
                            Color = Color3.fromRGB(255, 255, 255),
                            Center = true,
                            Outline = true,
                            OutlineColor = Color3.fromRGB(0, 0, 0),
                            Visible = false
                        })
                    end
                    drawings[hpTextKey].Text = string.format("%d/%d HP", math.floor(cur), math.floor(max))
                    drawings[hpTextKey].Position = Vector2.new(feetPos.X, feetPos.Y + 35) -- ПОД НОГАМИ
                    drawings[hpTextKey].Visible = true
                end
            end
        end
    end)
end

-- ИСПРАВЛЕНЫ СОБЫТИЯ (без конфликтов)
local function SetupPlayerEvents()
    pcall(function()
        Players.PlayerRemoving:Connect(function(player)
            CleanPlayerDrawings(player.Name)
            if playerConnections[player] then
                for _, connection in pairs(playerConnections[player]) do
                    connection:Disconnect()
                end
                playerConnections[player] = nil
            end
        end)
        
        Players.PlayerAdded:Connect(function(player)
            playerConnections[player] = {}
            local function onCharacterAdded(character)
                wait(1)
                CleanPlayerDrawings(player.Name)
            end
            
            if player.Character then
                spawn(function() onCharacterAdded(player.Character) end)
            end
            
            table.insert(playerConnections[player], player.CharacterAdded:Connect(onCharacterAdded))
        end)
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not playerConnections[player] then
                playerConnections[player] = {}
                local function onCharacterAdded(character)
                    wait(1)
                    CleanPlayerDrawings(player.Name)
                end
                
                if player.Character then
                    spawn(function() onCharacterAdded(player.Character) end)
                end
                
                table.insert(playerConnections[player], player.CharacterAdded:Connect(onCharacterAdded))
            end
        end
    end)
end

local espConnection
local function toggleESP(state)
    ESP.Enabled = state
    if state then
        SetupPlayerEvents()
        if espConnection then espConnection:Disconnect() end
        espConnection = RunService.RenderStepped:Connect(UpdateESP)
        print("🔍 ESP включен")
    else
        if espConnection then 
            espConnection:Disconnect() 
            espConnection = nil 
        end
        
        for player, connections in pairs(playerConnections) do
            for _, connection in pairs(connections) do
                connection:Disconnect()
            end
        end
        playerConnections = {}
        
        for _, d in pairs(drawings) do 
            pcall(function() d:Remove() end) 
        end
        drawings = {}
        print("🔍 ESP выключен")
    end
end
-- ================================
-- SIMPLE NOCLIP MODULE
-- ================================
local Noclip = false
local NoclipConnection

-- Функция для включения/выключения NoClip
local function ToggleNoClip(state)
    Noclip = state
    
    if Noclip then
        
        if NoclipConnection then
            NoclipConnection:Disconnect()
        end
        
        NoclipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then
                        v.CanCollide = false
                    end
                end
            end
        end)
    else
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
        
        -- Восстанавливаем коллизии при выключении
        if LocalPlayer.Character then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.CanCollide = true
                end
            end
        end
    end
end

-- ================================
-- REGISTER MODULES
-- ================================
UmbrellaHub.api:registerModule("Server", {
    name = "Safe Mode", 
    enabled = false, 
    callback = toggleSafeMode
})

UmbrellaHub.api:registerModule("Player",{name="Walkspeed",enabled=false,callback=ToggleWalkspeed})
UmbrellaHub.api:registerModule("Player",{name="Jump Boost",enabled=false,callback=function(state) JumpBoostModule.Enabled=state end})
UmbrellaHub.api:registerModule("Player",{name="Infinity Jump",enabled=false,callback=function(state) InfinityJumpModule.Enabled=state end})
UmbrellaHub.api:registerModule("World",{name="ESP",enabled=false,callback=toggleESP})

UmbrellaHub.api:registerModule("Player", {
    name = "NoClip", 
    enabled = false, 
    callback = ToggleNoClip
})

UmbrellaHub.api:registerModule("World", {
    name = "Chest ESP", 
    enabled = false, 
    callback = ToggleChestESP
})

-- ================================
-- REGISTER SETTINGS
-- ================================
UmbrellaHub.api:registerSettings("Safe Mode",{

})

UmbrellaHub.api:registerSettings("Walkspeed",{
    {name="Walk Speed",type="slider",min=16,max=200,default=16,callback=function(v) WalkspeedModule.Speed=v end}
})

UmbrellaHub.api:registerSettings("Jump Boost",{
    {name="Jump Power",type="slider",min=20,max=200,default=50,callback=function(v) JumpBoostModule.Power=v end}
})

UmbrellaHub.api:registerSettings("NoClip", {
    -- Ð—Ð´ÐµÑÑŒ Ð¿ÑƒÑÑ‚Ð¾, Ð»Ð¸Ð±Ð° Ð°Ð²Ñ‚Ð¾Ð¼Ð°Ñ‚Ð¸Ñ‡ÐµÑÐºÐ¸ ÑÐ¾Ð·Ð´Ð°ÑÑ‚ toggle Ð¿ÐµÑ€ÐµÐºÐ»ÑŽÑ‡Ð°Ñ‚ÐµÐ»ÑŒ
})

-- Ð£Ð±Ñ€Ð°Ð» Ð»Ð¸ÑˆÐ½Ð¸Ð¹ toggle Ð´Ð»Ñ Infinity Jump (Ð¾Ð½ ÑƒÐ¶Ðµ ÑƒÐ¿Ñ€Ð°Ð²Ð»ÑÐµÑ‚ÑÑ Ñ‡ÐµÑ€ÐµÐ· Ð¼Ð¾Ð´ÑƒÐ»ÑŒ)
UmbrellaHub.api:registerSettings("Infinity Jump",{
    -- ÐÐ°ÑÑ‚Ñ€Ð¾Ð¹ÐºÐ¸ Ð½Ðµ Ð½ÑƒÐ¶Ð½Ñ‹, Ñ‚Ð°Ðº ÐºÐ°Ðº Ð¼Ð¾Ð´ÑƒÐ»ÑŒ ÑÐ°Ð¼ Ð¿Ð¾ ÑÐµÐ±Ðµ toggle
})

UmbrellaHub.api:registerSettings("ESP",{
    {name="Show Players",type="toggle",default=true,callback=function(val) ESP.ShowPlayers=val end},
    {name="Show Fruits",type="toggle",default=true,callback=function(val) ESP.ShowFruits=val end},
    {name="Show Names",type="toggle",default=true,callback=function(val) ESP.ShowName=val end},
    {name="Show HP",type="toggle",default=true,callback=function(val) ESP.ShowHealthBar=val end}
})

UmbrellaHub.api:registerSettings("Chest ESP", {
    {
        name = "Show Distance", 
        type = "toggle", 
        default = true, 
        callback = function(val) 
            ChestESP.ShowDistance = val 
        end
    },
    {
        name = "Max Distance", 
        type = "slider", 
        min = 100, 
        max = 2000, 
        default = 500, 
        callback = function(val) 
            ChestESP.MaxDistance = val 
        end
    },
    {
        name = "Max Scale", 
        type = "slider", 
        min = 1, 
        max = 5, 
        default = 3, 
        callback = function(val) 
            ChestESP.MaxScale = val 
        end
    },
    {
        name = "Text Size", 
        type = "slider", 
        min = 10, 
        max = 30, 
        default = 14, 
        callback = function(val) 
            ChestESP.BaseTextSize = val 
        end
    }
})

UmbrellaHub.init()
