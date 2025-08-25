-- Umbrella Hub - Complete Script with All Modules
local UI_LIB_URL = 'https://github.com/Atom1gg/pizda/raw/refs/heads/main/1.lua'
local UmbrellaHub = loadstring(game:HttpGet(UI_LIB_URL))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ================================
-- AUTO BHOP MODULE
-- ================================
local AutoBhopModule = {}
local Character
local Humanoid
local RootPart

local BodyVelocity = Instance.new("BodyVelocity")
BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
BodyVelocity.P = 1000

local BhopSettings = {
    Enabled = false,
    Speed = 30,
    Direction = "directional",
    EdgeJump = false,
    StrafeBoost = true,
    StrafeMultiplier = 1.5,
    StrafeSensitivity = 2.0
}

local lastCameraAngle = 0
local cameraRotationSpeed = 0
local bhopConnection

local function UpdateCharacter()
    Character = LocalPlayer.Character
    if Character then
        Humanoid = Character:WaitForChild("Humanoid")
        RootPart = Character:WaitForChild("HumanoidRootPart")
        return true
    end
    return false
end

local function CalculateCameraRotation()
    local currentCameraAngle = workspace.CurrentCamera.CFrame:ToEulerAnglesXYZ()
    local deltaAngle = math.deg(currentCameraAngle - lastCameraAngle)
    lastCameraAngle = currentCameraAngle
    cameraRotationSpeed = deltaAngle * BhopSettings.StrafeSensitivity
end

local function BunnyHop()
    if not BhopSettings.Enabled then return end
    
    if not Character or not Humanoid or not RootPart or not Humanoid:IsDescendantOf(workspace) then
        if not UpdateCharacter() then return end
    end

    if Humanoid:GetState() == Enum.HumanoidStateType.Dead then return end

    CalculateCameraRotation()

    BodyVelocity:Destroy()
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        local add = 0
        if BhopSettings.Direction == "directional" then
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then add = 90 end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then add = 180 end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then add = 270 end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) and UserInputService:IsKeyDown(Enum.KeyCode.W) then add = 45 end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) and UserInputService:IsKeyDown(Enum.KeyCode.W) then add = 315 end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) and UserInputService:IsKeyDown(Enum.KeyCode.S) then add = 225 end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) and UserInputService:IsKeyDown(Enum.KeyCode.S) then add = 145 end
        end
        
        local rot = CFrame.new(RootPart.Position, RootPart.Position + RootPart.CFrame.LookVector) * CFrame.Angles(0, math.rad(add), 0)
        BodyVelocity.Parent = RootPart
        Humanoid.Jump = true
        
        local speed = BhopSettings.Speed
        if BhopSettings.StrafeBoost and math.abs(cameraRotationSpeed) > 5 then
            speed = speed * BhopSettings.StrafeMultiplier
        end
        
        BodyVelocity.Velocity = Vector3.new(rot.LookVector.X, 0, rot.LookVector.Z) * speed
        
        if add == 0 and BhopSettings.Direction == "directional" and not UserInputService:IsKeyDown(Enum.KeyCode.W) then
            BodyVelocity:Destroy()
        end
    end
    
    if BhopSettings.EdgeJump then
        if Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
            coroutine.wrap(function()
                RunService.RenderStepped:Wait()
                if Humanoid and Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                    Humanoid:ChangeState("Jumping")
                end
            end)()
        end
    end
end

local function CharacterAdded(newCharacter)
    Character = newCharacter
    Humanoid = newCharacter:WaitForChild("Humanoid")
    RootPart = newCharacter:WaitForChild("HumanoidRootPart")
end

local function toggleBhop(state)
    BhopSettings.Enabled = state
    
    if state then
        if LocalPlayer.Character then
            CharacterAdded(LocalPlayer.Character)
        end
        LocalPlayer.CharacterAdded:Connect(CharacterAdded)
        bhopConnection = RunService.Heartbeat:Connect(BunnyHop)
    else
        if bhopConnection then
            bhopConnection:Disconnect()
            bhopConnection = nil
        end
        if BodyVelocity then
            BodyVelocity:Destroy()
        end
    end
end

-- ================================
-- CHAMS MODULE
-- ================================
local ChamsModule = {
    enabled = false,
    teamBased = true,
    refreshInterval = 1,
    teamColors = {
        ["Terrorists"] = Color3.fromRGB(255, 200, 0),
        ["Counter-Terrorists"] = Color3.fromRGB(0, 150, 255),
        defaultEnemy = Color3.fromRGB(255, 0, 0)
    },
    outlineColor = Color3.fromRGB(255, 255, 255),
    fillTransparency = 0.8,
    refreshConnection = nil,
    playerConnections = {}
}

local function applyChams(player)
    if not player or not player.Character then return end
    
    local highlight = player.Character:FindFirstChildOfClass("Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Parent = player.Character
    end
    
    highlight.OutlineColor = ChamsModule.outlineColor
    highlight.FillColor = ChamsModule.teamBased and 
                        (player.Team and ChamsModule.teamColors[player.Team.Name] or ChamsModule.teamColors.defaultEnemy) or 
                        ChamsModule.teamColors.defaultEnemy
    highlight.FillTransparency = ChamsModule.fillTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = ChamsModule.enabled
end

local function refreshAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            applyChams(player)
        end
    end
end

local function setupPlayer(player)
    if player == LocalPlayer then return end
    
    if ChamsModule.playerConnections[player] then
        for _, conn in pairs(ChamsModule.playerConnections[player]) do
            conn:Disconnect()
        end
    end
    
    ChamsModule.playerConnections[player] = {
        player.CharacterAdded:Connect(function(character)
            repeat task.wait() until character:FindFirstChild("Humanoid")
            applyChams(player)
        end),
        player:GetPropertyChangedSignal("Team"):Connect(function()
            applyChams(player)
        end)
    }
    
    if player.Character then
        applyChams(player)
    end
end

local function toggleChams(state)
    if state == ChamsModule.enabled then return end
    
    ChamsModule.enabled = state
    if state then
        if ChamsModule.refreshConnection then
            ChamsModule.refreshConnection:Disconnect()
        end
        
        ChamsModule.refreshConnection = RunService.Heartbeat:Connect(function()
            refreshAllPlayers()
        end)
        
        for _, player in ipairs(Players:GetPlayers()) do
            setupPlayer(player)
        end
    else
        if ChamsModule.refreshConnection then
            ChamsModule.refreshConnection:Disconnect()
            ChamsModule.refreshConnection = nil
        end
        
        for player, connections in pairs(ChamsModule.playerConnections) do
            for _, conn in pairs(connections) do
                conn:Disconnect()
            end
        end
        ChamsModule.playerConnections = {}
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                local highlight = player.Character:FindFirstChildOfClass("Highlight")
                if highlight then
                    highlight.Enabled = false
                end
            end
        end
    end
end

-- ================================
-- FOV CHANGER MODULE
-- ================================
local FovModule = {
    enabled = false,
    fov = 90,
    connection = nil
}

local function toggleFov(state)
    if state then
        if FovModule.enabled then return end
        
        local conn
        conn = RunService.RenderStepped:Connect(function()
            workspace.CurrentCamera.FieldOfView = FovModule.fov
        end)
        
        FovModule.connection = conn
        FovModule.enabled = true
    else
        if not FovModule.enabled then return end
        if FovModule.connection then
            FovModule.connection:Disconnect()
        end
        workspace.CurrentCamera.FieldOfView = 70
        FovModule.enabled = false
    end
end

-- ================================
-- ESP MODULE
-- ================================
local SkeletonESP = {
    Enabled = false,
    TeamColor = true,
    EnemyColor = Color3.fromRGB(255, 50, 50),
    AllyColor = Color3.fromRGB(50, 50, 255),
    Thickness = 1,
    ShowWeapon = true,
    ShowHealthBar = true,
    ShowName = true,
    ShowHead = true
}

-- Team colors
local TeamColors = {
    ["Counter-Terrorists"] = Color3.fromRGB(0, 150, 255), -- Синий для КТ
    ["Terrorists"] = Color3.fromRGB(255, 200, 0), -- Желтый для Т
    defaultEnemy = Color3.fromRGB(255, 0, 0) -- Красный для остальных
}

-- R15 bone structure
local R15_BONES = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"UpperTorso", "RightUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LowerTorso", "RightUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

-- R6 fallback bones
local R6_BONES = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

local WEAPON_ATTACHMENTS = {"RightHand", "LeftHand"}

local drawings = {}

local function CreateDrawing(type, props)
    local drawing = Drawing.new(type)
    for prop, value in pairs(props) do
        drawing[prop] = value
    end
    return drawing
end

local function GetRigType(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return humanoid.RigType
    end
    
    if character:FindFirstChild("UpperTorso") then
        return Enum.HumanoidRigType.R15
    elseif character:FindFirstChild("Torso") then
        return Enum.HumanoidRigType.R6
    end
    
    return Enum.HumanoidRigType.R6
end

local function GetPlayerColor(player)
    if SkeletonESP.TeamColor then
        if player.Team and TeamColors[player.Team.Name] then
            return TeamColors[player.Team.Name]
        else
            return TeamColors.defaultEnemy
        end
    else
        return SkeletonESP.EnemyColor
    end
end

local function GetEquippedWeapon(character)
    local equippedTool = character:FindFirstChild("EquippedTool")
    if equippedTool and equippedTool.Value then
        return equippedTool.Value
    end
    
    -- Fallback - check for tools
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name
    end
    
    return "None"
end

local function GetPlayerHealth(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return math.floor(humanoid.Health), math.floor(humanoid.MaxHealth)
    end
    return 0, 100
end

local function UpdateESP()
    -- Hide all drawings first
    for _, drawing in pairs(drawings) do
        drawing.Visible = false
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local rigType = GetRigType(character)
            local color = GetPlayerColor(player)
            local head = character:FindFirstChild("Head")
            
            if not head then continue end
            
            local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
            if not headOnScreen or headPos.Z <= 0 then continue end
            
            -- Draw head circle
            if SkeletonESP.ShowHead then
                local headKey = player.Name.."Head"
                if not drawings[headKey] then
                    drawings[headKey] = CreateDrawing("Circle", {
                        Color = color,
                        Thickness = SkeletonESP.Thickness,
                        Radius = 8,
                        Filled = false,
                        Visible = false
                    })
                end
                
                drawings[headKey].Position = Vector2.new(headPos.X, headPos.Y)
                drawings[headKey].Color = color
                drawings[headKey].Radius = 8
                drawings[headKey].Thickness = SkeletonESP.Thickness
                drawings[headKey].Visible = SkeletonESP.Enabled
            end
            
            -- Draw skeleton
            local bones = (rigType == Enum.HumanoidRigType.R15) and R15_BONES or R6_BONES
            
            for _, bonePair in ipairs(bones) do
                local part1 = character:FindFirstChild(bonePair[1])
                local part2 = character:FindFirstChild(bonePair[2])
                
                if part1 and part2 then
                    local key = player.Name..bonePair[1]..bonePair[2]
                    if not drawings[key] then
                        drawings[key] = CreateDrawing("Line", {
                            Thickness = SkeletonESP.Thickness,
                            Color = color,
                            Visible = false
                        })
                    end
                    
                    local pos1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
                    local pos2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)
                    
                    if onScreen1 and onScreen2 and pos1.Z > 0 and pos2.Z > 0 then
                        drawings[key].From = Vector2.new(pos1.X, pos1.Y)
                        drawings[key].To = Vector2.new(pos2.X, pos2.Y)
                        drawings[key].Visible = SkeletonESP.Enabled
                        drawings[key].Color = color
                        drawings[key].Thickness = SkeletonESP.Thickness
                    end
                end
            end
            
            -- Show name
            if SkeletonESP.ShowName then
                local nameKey = player.Name.."Name"
                if not drawings[nameKey] then
                    drawings[nameKey] = CreateDrawing("Text", {
                        Text = player.Name,
                        Size = 16,
                        Color = color,
                        Center = true,
                        Outline = true,
                        OutlineColor = Color3.fromRGB(0, 0, 0),
                        Visible = false
                    })
                end
                
                drawings[nameKey].Text = player.Name
                drawings[nameKey].Position = Vector2.new(headPos.X, headPos.Y - 35)
                drawings[nameKey].Color = color
                drawings[nameKey].Visible = SkeletonESP.Enabled
            end
            
            -- Show health bar (vertical, to the side)
            if SkeletonESP.ShowHealthBar then
                local currentHealth, maxHealth = GetPlayerHealth(character)
                local healthPercentage = currentHealth / maxHealth
                
                -- Health bar background (vertical)
                local healthBgKey = player.Name.."HealthBg"
                if not drawings[healthBgKey] then
                    drawings[healthBgKey] = CreateDrawing("Line", {
                        Thickness = 4,
                        Color = Color3.fromRGB(50, 50, 50),
                        Visible = false
                    })
                end
                
                drawings[healthBgKey].From = Vector2.new(headPos.X - 35, headPos.Y - 20)
                drawings[healthBgKey].To = Vector2.new(headPos.X - 35, headPos.Y + 30)
                drawings[healthBgKey].Visible = SkeletonESP.Enabled
                
                -- Health bar fill (vertical)
                local healthKey = player.Name.."Health"
                if not drawings[healthKey] then
                    drawings[healthKey] = CreateDrawing("Line", {
                        Thickness = 2,
                        Color = Color3.fromRGB(0, 255, 0),
                        Visible = false
                    })
                end
                
                local healthColor = Color3.fromRGB(
                    255 * (1 - healthPercentage),
                    255 * healthPercentage,
                    0
                )
                
                local healthHeight = 50 * healthPercentage
                drawings[healthKey].From = Vector2.new(headPos.X - 35, headPos.Y + 30)
                drawings[healthKey].To = Vector2.new(headPos.X - 35, headPos.Y + 30 - healthHeight)
                drawings[healthKey].Color = healthColor
                drawings[healthKey].Visible = SkeletonESP.Enabled
                
                -- Health text
                local healthTextKey = player.Name.."HealthText"
                if not drawings[healthTextKey] then
                    drawings[healthTextKey] = CreateDrawing("Text", {
                        Size = 12,
                        Color = Color3.fromRGB(255, 255, 255),
                        Center = true,
                        Outline = true,
                        OutlineColor = Color3.fromRGB(0, 0, 0),
                        Visible = false
                    })
                end
                
                drawings[healthTextKey].Text = tostring(currentHealth)
                drawings[healthTextKey].Position = Vector2.new(headPos.X - 50, headPos.Y + 5)
                drawings[healthTextKey].Visible = SkeletonESP.Enabled
            end
            
            -- Show weapon
            if SkeletonESP.ShowWeapon then
                local weapon = GetEquippedWeapon(character)
                local weaponKey = player.Name.."Weapon"
                if not drawings[weaponKey] then
                    drawings[weaponKey] = CreateDrawing("Text", {
                        Size = 14,
                        Color = color,
                        Center = true,
                        Outline = true,
                        OutlineColor = Color3.fromRGB(0, 0, 0),
                        Visible = false
                    })
                end
                
                drawings[weaponKey].Text = weapon
                drawings[weaponKey].Position = Vector2.new(headPos.X, headPos.Y - 50)
                drawings[weaponKey].Color = color
                drawings[weaponKey].Visible = SkeletonESP.Enabled
            end
            
            -- Show weapon lines (original weapon attachment lines)
            for _, attachName in ipairs(WEAPON_ATTACHMENTS) do
                local attach = character:FindFirstChild(attachName)
                if attach then
                    for _, child in ipairs(attach:GetChildren()) do
                        if child:IsA("BasePart") and child.Name ~= "Handle" then
                            local key = player.Name.."WeaponLine"..child.Name
                            if not drawings[key] then
                                drawings[key] = CreateDrawing("Line", {
                                    Thickness = SkeletonESP.Thickness,
                                    Color = color,
                                    Visible = false
                                })
                            end
                            
                            local handPos, handOnScreen = Camera:WorldToViewportPoint(attach.Position)
                            local weaponPos, weaponOnScreen = Camera:WorldToViewportPoint(child.Position)
                            
                            if handOnScreen and weaponOnScreen and handPos.Z > 0 and weaponPos.Z > 0 then
                                drawings[key].From = Vector2.new(handPos.X, handPos.Y)
                                drawings[key].To = Vector2.new(weaponPos.X, weaponPos.Y)
                                drawings[key].Visible = SkeletonESP.Enabled
                                drawings[key].Color = color
                                drawings[key].Thickness = SkeletonESP.Thickness
                            end
                        end
                    end
                end
            end
        end
    end
end

local function ClearDrawings()
    for _, drawing in pairs(drawings) do
        drawing:Remove()
    end
    drawings = {}
end

local espConnection
local function toggleESP(state)
    SkeletonESP.Enabled = state
    
    if state then
        if espConnection then espConnection:Disconnect() end
        espConnection = RunService.RenderStepped:Connect(UpdateESP)
    else
        if espConnection then
            espConnection:Disconnect()
            espConnection = nil
        end
        ClearDrawings()
    end
end

-- ================================
-- FAST PLANT MODULE
-- ================================
local FastPlantModule = {
    enabled = false,
    plantType = "Normal",
    connection = nil
}

local function GetSite()
    local spawnA = workspace.Map.SpawnPoints.C4Plant.Position
    local spawnB = workspace.Map.SpawnPoints.C4Plant2.Position
    local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
    
    if (playerPos - spawnA).Magnitude < (playerPos - spawnB).Magnitude then
        return "B"
    else
        return "A"
    end
end

local function toggleFastPlant(state)
    if state then
        if FastPlantModule.enabled then return end
        
        FastPlantModule.connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("EquippedTool") and char.EquippedTool.Value == "C4" then
                    if FastPlantModule.plantType == "Normal" then
                        game.ReplicatedStorage.Events.PlantC4:FireServer(
                            (char.HumanoidRootPart.CFrame + Vector3.new(0, -2, 0)) * CFrame.Angles(0, 0, 4),
                            GetSite()
                        )
                    else
                        game.ReplicatedStorage.Events.PlantC4:FireServer(
                            char.HumanoidRootPart.CFrame + Vector3.new(0, -6, 0),
                            ""
                        )
                    end
                end
            end
        end)
        
        FastPlantModule.enabled = true
    else
        if not FastPlantModule.enabled then return end
        if FastPlantModule.connection then
            FastPlantModule.connection:Disconnect()
        end
        FastPlantModule.enabled = false
    end
end

-- ================================
-- KILL SAY MODULE
-- ================================
local KillSayModule = {
    enabled = false,
    message = "ez get Umbrella.hub",
    connection = nil,
    lastKills = 0
}

local function OnKill()
    local currentKills = LocalPlayer:FindFirstChild("Kills") and LocalPlayer.Kills.Value or 0
    
    if currentKills > KillSayModule.lastKills then
        game:GetService("ReplicatedStorage").Events.PlayerChatted:FireServer(
            KillSayModule.message,
            false,
            "All",
            false,
            true
        )
    end
    KillSayModule.lastKills = currentKills
end

local function toggleKillSay(state)
    if state then
        if KillSayModule.enabled then return end
        
        KillSayModule.lastKills = LocalPlayer:FindFirstChild("Kills") and LocalPlayer.Kills.Value or 0
        
        KillSayModule.connection = LocalPlayer:GetPropertyChangedSignal("Kills"):Connect(OnKill)
        KillSayModule.enabled = true
    else
        if not KillSayModule.enabled then return end
        
        if KillSayModule.connection then
            KillSayModule.connection:Disconnect()
            KillSayModule.connection = nil
        end
        KillSayModule.enabled = false
    end
end

-- ================================
-- QUICK DEFUSE MODULE
-- ================================
local QuickDefuseModule = {
    enabled = false,
    defuseType = "Near",
    connection = nil
}

local function toggleQuickDefuse(state)
    if state then
        if QuickDefuseModule.enabled then return end
        
        QuickDefuseModule.connection = UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.E then
                if workspace:FindFirstChild("C4") then
                    if QuickDefuseModule.defuseType == "Near" then
                        if (LocalPlayer.Character.HumanoidRootPart.Position - workspace.C4.Position).Magnitude < 10 then
                            LocalPlayer.Backpack.Defuse:FireServer(workspace.C4)
                        end
                    else
                        LocalPlayer.Backpack.Defuse:FireServer(workspace.C4)
                    end
                end
            end
        end)
        
        QuickDefuseModule.enabled = true
    else
        if not QuickDefuseModule.enabled then return end
        if QuickDefuseModule.connection then
            QuickDefuseModule.connection:Disconnect()
        end
        QuickDefuseModule.enabled = false
    end
end

-- ================================
-- SILENT AIM MODULE
-- ================================
-- ================================
-- SILENT AIM MODULE (УЛУЧШЕННЫЙ)
-- ================================
local SilentAimModule = {}
local silentAimSettings = {
    CheckTeam = true,
    HeadChance = 80, -- Процент шанса попадания в голову
    FOVEnabled = true,
    FOV = 60,
    Enabled = false
}

local CurrentCamera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Фейковый FOV круг (не влияет на аим)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 0.5
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Visible = false

local fovUpdateConnection

local function UpdateFOVCircle()
    if silentAimSettings.FOVEnabled and silentAimSettings.Enabled then
        FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
        FOVCircle.Radius = silentAimSettings.FOV
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
end

local Ray_new = Ray.new
local Vector2_new = Vector2.new
local WorldToScreenPoint = CurrentCamera.WorldToScreenPoint
local FindFirstChild = game.FindFirstChild
local GetPlayers = Players.GetPlayers

local function FindTarget()
    if not silentAimSettings.Enabled then return nil end
    
    local MaxDist = math.huge
    local Closest = nil
    
    for _, Player in ipairs(GetPlayers(Players)) do
        if Player == LocalPlayer then continue end
        
        if silentAimSettings.CheckTeam and Player.Team == LocalPlayer.Team then continue end
        
        local Character = Player.Character
        if not Character then continue end
        
        -- Определяем цель на основе шанса попадания в голову
        local TargetPart
        local headChance = math.random(1, 100)
        if headChance <= silentAimSettings.HeadChance then
            TargetPart = FindFirstChild(Character, "Head")
        else
            TargetPart = FindFirstChild(Character, "UpperTorso") or FindFirstChild(Character, "HumanoidRootPart")
        end
        
        if not TargetPart then continue end
        
        local Pos, Vis = WorldToScreenPoint(CurrentCamera, TargetPart.Position)
        if not Vis then continue end
        
        local MousePos = Vector2_new(Mouse.X, Mouse.Y)
        local TheirPos = Vector2_new(Pos.X, Pos.Y)
        local Dist = (TheirPos - MousePos).Magnitude
        
        if Dist < MaxDist then
            MaxDist = Dist
            Closest = {Player = Player, Part = TargetPart}
        end
    end
    
    return Closest
end

local MT = getrawmetatable(game)
local OldNC = MT.__namecall
setreadonly(MT, false)

MT.__namecall = newcclosure(function(self, ...)
    local Args = {...}
    local Method = getnamecallmethod()
    
    if Method == "FindPartOnRayWithIgnoreList" and not checkcaller() and silentAimSettings.Enabled then
        local Target = FindTarget()
        if Target and Target.Part then
            local RayOrigin = CurrentCamera.CFrame.Position
            local RayDirection = (Target.Part.Position - RayOrigin).Unit * 1000
            Args[1] = Ray_new(RayOrigin, RayDirection)
            return OldNC(self, unpack(Args))
        end
    end
    
    return OldNC(self, ...)
end)

setreadonly(MT, true)

local function toggleSilentAim(state)
    silentAimSettings.Enabled = state
    
    if state then
        -- Запускаем обновление FOV круга
        if fovUpdateConnection then fovUpdateConnection:Disconnect() end
        fovUpdateConnection = RunService.RenderStepped:Connect(UpdateFOVCircle)
    else
        -- Останавливаем обновление FOV круга
        if fovUpdateConnection then
            fovUpdateConnection:Disconnect()
            fovUpdateConnection = nil
        end
        FOVCircle.Visible = false
    end
end

-- ================================
-- SPIN BOT MODULE
-- ================================
local SpinBotModule = {}
local spinCharacter
local spinHumanoid
local spinRootPart

local SpinSettings = {
    Enabled = false,
    Speed = 20,
    Angle = 0,
    AntiAim = true,
    SpinDead = true
}

local spinConnection

local function UpdateSpinCharacter()
    spinCharacter = LocalPlayer.Character
    if spinCharacter then
        spinHumanoid = spinCharacter:WaitForChild("Humanoid")
        spinRootPart = spinCharacter:WaitForChild("HumanoidRootPart")
        return true
    end
    return false
end

local function Spin()
    if not SpinSettings.Enabled then return end
    
    if not spinCharacter or not spinRootPart or not spinRootPart:IsDescendantOf(workspace) then
        if not UpdateSpinCharacter() then return end
    end

    if spinHumanoid and spinHumanoid:GetState() == Enum.HumanoidStateType.Dead and not SpinSettings.SpinDead then
        return
    end

    SpinSettings.Angle = (SpinSettings.Angle + SpinSettings.Speed) % 360
    local CFrameSpin = CFrame.new(spinRootPart.Position) * CFrame.Angles(0, math.rad(SpinSettings.Angle), 0)
    
    if SpinSettings.AntiAim then
        CFrameSpin = CFrameSpin * CFrame.Angles(math.rad(-90), 0, 0)
    end
    
    spinRootPart.CFrame = CFrameSpin
end

local function SpinCharacterAdded(newCharacter)
    spinCharacter = newCharacter
    spinHumanoid = newCharacter:WaitForChild("Humanoid")
    spinRootPart = newCharacter:WaitForChild("HumanoidRootPart")
end

local function toggleSpinBot(state)
    SpinSettings.Enabled = state
    
    if state then
        if LocalPlayer.Character then
            SpinCharacterAdded(LocalPlayer.Character)
        end
        LocalPlayer.CharacterAdded:Connect(SpinCharacterAdded)
        spinConnection = RunService.Heartbeat:Connect(Spin)
    else
        if spinConnection then
            spinConnection:Disconnect()
            spinConnection = nil
        end
        if spinRootPart and spinRootPart:IsDescendantOf(workspace) then
            spinRootPart.CFrame = CFrame.new(spinRootPart.Position, spinRootPart.Position + Vector3.new(0, 0, -1))
        end
    end
end

-- ================================
-- THIRD PERSON MODULE
-- ================================
local ThirdPersonModule = {
    enabled = false,
    distance = 5,
    updateConnection = nil
}

local function updateThirdPerson()
    if ThirdPersonModule.enabled then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = ThirdPersonModule.distance
        LocalPlayer.CameraMinZoomDistance = ThirdPersonModule.distance
    end
end

local function toggleThirdPerson(state)
    if state then
        if ThirdPersonModule.enabled then return end
        
        ThirdPersonModule.enabled = true
        updateThirdPerson()
        
        -- Постоянное обновление третьего лица
        if ThirdPersonModule.updateConnection then
            ThirdPersonModule.updateConnection:Disconnect()
        end
        ThirdPersonModule.updateConnection = RunService.Heartbeat:Connect(updateThirdPerson)
        
        -- Обновление при респавне
        LocalPlayer.CharacterAdded:Connect(function()
            if ThirdPersonModule.enabled then
                task.wait(0.1)
                updateThirdPerson()
            end
        end)
        
    else
        if not ThirdPersonModule.enabled then return end
        
        ThirdPersonModule.enabled = false
        
        if ThirdPersonModule.updateConnection then
            ThirdPersonModule.updateConnection:Disconnect()
            ThirdPersonModule.updateConnection = nil
        end
        
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
        LocalPlayer.CameraMaxZoomDistance = 0.5
        LocalPlayer.CameraMinZoomDistance = 0.5
    end
end

-- ================================
-- INFINITE AMMO MODULE
-- ================================
local InfiniteAmmoModule = {
    enabled = false,
    connection = nil
}

local function setupInfiniteAmmo()
    if InfiniteAmmoModule.connection then
        InfiniteAmmoModule.connection:Disconnect()
    end
    
    InfiniteAmmoModule.connection = RunService.Heartbeat:Connect(function()
        if not InfiniteAmmoModule.enabled or not LocalPlayer.Character then return end
        
        -- Поиск клиентских переменных боеприпасов
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" then
                -- Основные патроны
                if rawget(v, "ammocount") and type(v.ammocount) == "number" and v.ammocount < 999999 then
                    v.ammocount = 999999
                end
                
                if rawget(v, "primarystored") and type(v.primarystored) == "number" and v.primarystored < 999999 then
                    v.primarystored = 999999
                end
                
                -- Вторичные патроны
                if rawget(v, "ammocount2") and type(v.ammocount2) == "number" and v.ammocount2 < 999999 then
                    v.ammocount2 = 999999
                end
                
                if rawget(v, "secondarystored") and type(v.secondarystored) == "number" and v.secondarystored < 999999 then
                    v.secondarystored = 999999
                end
            end
        end
        
        -- Модификация оружия в инвентаре и руках
        if LocalPlayer.Character:FindFirstChild("Gun") then
            local gun = LocalPlayer.Character.Gun
            if gun:FindFirstChild("Ammo") and gun.Ammo.Value < 999 then
                gun.Ammo.Value = 999
            end
            if gun:FindFirstChild("StoredAmmo") and gun.StoredAmmo.Value < 999 then
                gun.StoredAmmo.Value = 999
            end
        end
        
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("StoredAmmo") then
                tool.StoredAmmo.Value = 999
            end
        end
    end)
end

local function toggleInfiniteAmmo(state)
    if state == InfiniteAmmoModule.enabled then return end
    
    InfiniteAmmoModule.enabled = state
    if state then
        setupInfiniteAmmo()
    else
        if InfiniteAmmoModule.connection then
            InfiniteAmmoModule.connection:Disconnect()
            InfiniteAmmoModule.connection = nil
        end
    end
end

-- ================================
-- RAPID FIRE MODULE
-- ================================
local RapidFireModule = {
    enabled = false,
    fireRateMultiplier = 5.0,
    originalFireRates = {},
    connection = nil
}

local function modifyWeaponFireRate(gun)
    if not gun or not RapidFireModule.enabled then return end
    
    local gunName = gun.Name
    if not RapidFireModule.originalFireRates[gunName] then
        -- Сохраняем оригинальную скорострельность
        if gun:FindFirstChild("FireRate") then
            RapidFireModule.originalFireRates[gunName] = gun.FireRate.Value
        elseif gun:FindFirstChild("Firerate") then
            RapidFireModule.originalFireRates[gunName] = gun.Firerate.Value
        end
    end
    
    -- Устанавливаем повышенную скорострельность
    if gun:FindFirstChild("FireRate") then
        gun.FireRate.Value = (RapidFireModule.originalFireRates[gunName] or 0.1) * RapidFireModule.fireRateMultiplier
    elseif gun:FindFirstChild("Firerate") then
        gun.Firerate.Value = (RapidFireModule.originalFireRates[gunName] or 0.1) * RapidFireModule.fireRateMultiplier
    end
    
    -- Отключаем задержки между выстрелами
    if gun:FindFirstChild("Auto") then
        gun.Auto.Value = true
    end
end

local function setupRapidFire()
    if RapidFireModule.connection then
        RapidFireModule.connection:Disconnect()
    end
    
    RapidFireModule.connection = RunService.Heartbeat:Connect(function()
        if not RapidFireModule.enabled or not LocalPlayer.Character then return end
        
        -- Модифицируем текущее оружие
        if LocalPlayer.Character:FindFirstChild("Gun") then
            modifyWeaponFireRate(LocalPlayer.Character.Gun)
        end
        
        -- Модифицируем оружие в инвентаре
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                modifyWeaponFireRate(tool)
            end
        end
    end)
end

local function toggleRapidFire(state)
    if state == RapidFireModule.enabled then return end
    
    RapidFireModule.enabled = state
    if state then
        setupRapidFire()
    else
        if RapidFireModule.connection then
            RapidFireModule.connection:Disconnect()
            RapidFireModule.connection = nil
        end
        
        -- Восстановление оригинальных значений
        for gunName, originalRate in pairs(RapidFireModule.originalFireRates) do
            local gun = workspace:FindFirstChild(gunName) or LocalPlayer.Backpack:FindFirstChild(gunName) or LocalPlayer.Character:FindFirstChild(gunName)
            if gun then
                if gun:FindFirstChild("FireRate") then
                    gun.FireRate.Value = originalRate
                elseif gun:FindFirstChild("Firerate") then
                    gun.Firerate.Value = originalRate
                end
            end
        end
    end
end


-- ================================
-- PENETRATION MODULE (ИСПРАВЛЕННЫЙ)
-- ================================
local PenetrationModule = {
    enabled = false,
    maxPenetration = 100,
    maxObstacles = 4
}

-- Глобальные переменные
local Ignore2 = {workspace.Debris, workspace.Ray_Ignore}
local Multipliers = {
    Head = 4.0,
    UpperTorso = 1.0,
    LowerTorso = 1.0,
    LeftUpperArm = 0.5,
    RightUpperArm = 0.5,
    LeftLowerArm = 0.5,
    RightLowerArm = 0.5,
    LeftHand = 0.5,
    RightHand = 0.5,
    LeftUpperLeg = 0.5,
    RightUpperLeg = 0.5,
    LeftLowerLeg = 0.5,
    RightLowerLeg = 0.5,
    LeftFoot = 0.5,
    RightFoot = 0.5
}

-- Проверяем, не инициализировали ли мы уже метатаблицу
if not _G.PenetrationMetaTableInitialized then
    _G.PenetrationMetaTableInitialized = true
    
    local mt = getrawmetatable(game)
    local oldNC = mt.__namecall
    local oldIndex = mt.__index
    
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        if method == "FindPartOnRayWithIgnoreList" and args[2] and type(args[2]) == "table" and args[2][1] == workspace.Debris then
            if PenetrationModule.enabled then
                -- Создаем копию таблицы, а не изменяем оригинальную
                local newIgnoreList = {unpack(args[2])}
                table.insert(newIgnoreList, workspace.Map)
                args[2] = newIgnoreList
            end
            return oldNC(self, unpack(args))
        end
        
        return oldNC(self, ...)
    end)

    mt.__index = newcclosure(function(self, key)
        if key == "Value" then
            if self.Name == "Penetration" and PenetrationModule.enabled then
                return PenetrationModule.maxPenetration
            end
        end
        return oldIndex(self, key)
    end)

    setreadonly(mt, true)
end

-- Функция для расчета проникающей способности
local function CalculatePenetration(origin, targetPart, gunPenetration)
    if not PenetrationModule.enabled then return false, 1.0 end
    
    local hits = {}
    local ignoreList = {unpack(Ignore2)}
    local endHit, hit, pos
    local penetrationValue = gunPenetration * 0.01
    
    local direction = (targetPart.Position - origin).unit
    local distance = (targetPart.Position - origin).magnitude
    local ray = Ray.new(origin, direction * distance)
    
    repeat
        hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList, false, true)
        if hit and hit.Parent then
            if Multipliers[hit.Name] then
                endHit = hit
            else
                table.insert(ignoreList, hit)
                table.insert(hits, {
                    Position = pos,
                    Hit = hit,
                    Thickness = (hit.Size.X + hit.Size.Y + hit.Size.Z) / 3
                })
            end
        end
    until endHit or #hits >= PenetrationModule.maxObstacles or not hit
    
    -- Расчет уменьшения урона на основе толщины препятствий
    local damageMultiplier = 1.0
    if #hits > 0 then
        for _, obstacle in ipairs(hits) do
            local thicknessFactor = math.clamp(obstacle.Thickness / 5, 0.1, 0.8)
            damageMultiplier = damageMultiplier * (1 - thicknessFactor * (1 - penetrationValue))
        end
    end
    
    return endHit and #hits > 0, math.clamp(damageMultiplier, 0.1, 1.0)
end

-- Функция для использования в других модулях
local function togglePenetration(state)
    PenetrationModule.enabled = state
end

-- ================================
-- BOMB ESP MODULE
-- ================================
local BombESPModule = {
    enabled = false,
    color = Color3.fromRGB(255, 0, 0),
    transparency = 0.5,
    showText = true,
    highlights = {},
    textLabels = {},
    connections = {},
    bombTimer = 40,
    bombPlanted = false
}

local function CreateBombESP(bomb)
    -- Проверяем, поставлена ли бомба
    local isPlanted = bomb:FindFirstChild("Planted") and bomb.Planted.Value
    
    -- Создаем highlight
    local highlight = Instance.new("Highlight")
    highlight.FillColor = BombESPModule.color
    highlight.FillTransparency = BombESPModule.transparency
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = bomb
    
    -- Создаем BillboardGui для текста только если включено отображение текста
    local billboard
    if BombESPModule.showText then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "BombESPGui"
        billboard.Size = UDim2.new(0, 200, 0, 60)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.Adornee = bomb
        billboard.Parent = bomb
        
        -- Фон для текста
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        frame.Parent = billboard
        
        -- Скругляем углы
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = frame
        
        -- Обводка
        local stroke = Instance.new("UIStroke")
        stroke.Color = BombESPModule.color
        stroke.Thickness = 2
        stroke.Parent = frame
        
        -- Основной текст
        local titleText = Instance.new("TextLabel")
        titleText.Size = UDim2.new(1, 0, 0.5, 0)
        titleText.Position = UDim2.new(0, 0, 0, 0)
        titleText.Text = isPlanted and "BOMB PLANTED" or "C4 DROPPED"
        titleText.TextColor3 = BombESPModule.color
        titleText.TextScaled = true
        titleText.TextStrokeTransparency = 0
        titleText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        titleText.BackgroundTransparency = 1
        titleText.Font = Enum.Font.GothamBold
        titleText.Parent = frame
        
        -- Таймер (только если бомба поставлена)
        local timerText = Instance.new("TextLabel")
        timerText.Size = UDim2.new(1, 0, 0.5, 0)
        timerText.Position = UDim2.new(0, 0, 0.5, 0)
        timerText.Text = isPlanted and "40.0s" or ""
        timerText.TextColor3 = Color3.fromRGB(255, 255, 0)
        timerText.TextScaled = true
        timerText.TextStrokeTransparency = 0
        timerText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        timerText.BackgroundTransparency = 1
        timerText.Font = Enum.Font.GothamBold
        timerText.Parent = frame
        
        -- Сохраняем ссылки
        BombESPModule.textLabels[bomb] = {titleText, timerText, frame, billboard}
        
        -- Запускаем таймер если бомба поставлена
        if isPlanted then
            local startTime = tick()
            
            local function updateTimer()
                while bomb.Parent and BombESPModule.enabled do
                    local elapsed = tick() - startTime
                    local remaining = math.max(0, 40 - elapsed)
                    
                    -- Обновляем текст таймера
                    timerText.Text = string.format("%.1fs", remaining)
                    
                    -- Меняем цвета в зависимости от времени
                    if remaining <= 10 then
                        timerText.TextColor3 = Color3.fromRGB(255, 0, 0)
                        titleText.TextColor3 = Color3.fromRGB(255, 0, 0)
                        stroke.Color = Color3.fromRGB(255, 0, 0)
                    elseif remaining <= 20 then
                        timerText.TextColor3 = Color3.fromRGB(255, 165, 0)
                        titleText.TextColor3 = Color3.fromRGB(255, 100, 0)
                        stroke.Color = Color3.fromRGB(255, 165, 0)
                    else
                        timerText.TextColor3 = Color3.fromRGB(255, 255, 0)
                        titleText.TextColor3 = BombESPModule.color
                        stroke.Color = BombESPModule.color
                    end
                    
                    if remaining <= 0 then
                        timerText.Text = "BOOM!"
                        break
                    end
                    
                    wait(0.1)
                end
            end
            
            coroutine.wrap(updateTimer)()
        end
    end
    
    -- Сохраняем ссылки
    BombESPModule.highlights[bomb] = highlight
end

local function RemoveBombESP(bomb)
    if BombESPModule.highlights[bomb] then
        BombESPModule.highlights[bomb]:Destroy()
        BombESPModule.highlights[bomb] = nil
    end
    
    if BombESPModule.textLabels[bomb] then
        for _, label in pairs(BombESPModule.textLabels[bomb]) do
            if label and label.Parent then
                label:Destroy()
            end
        end
        BombESPModule.textLabels[bomb] = nil
    end
end

local function CheckForBombs()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj.Name == "C4" or obj.Name == "Bomb") and not BombESPModule.highlights[obj] then
            CreateBombESP(obj)
        end
    end
end

local function OnBombStateChanged(bomb)
    if BombESPModule.highlights[bomb] then
        RemoveBombESP(bomb)
        CreateBombESP(bomb)
    end
end

local function toggleBombESP(state)
    BombESPModule.enabled = state
    
    if state then
        -- Ищем существующие бомбы
        CheckForBombs()
        
        -- Следим за новыми бомбами
        BombESPModule.connections.childAdded = workspace.DescendantAdded:Connect(function(child)
            if (child.Name == "C4" or child.Name == "Bomb") and BombESPModule.enabled then
                wait(0.1)
                CreateBombESP(child)
            end
        end)
        
        -- Следим за удалением бомб
        BombESPModule.connections.childRemoved = workspace.DescendantRemoving:Connect(function(child)
            if (child.Name == "C4" or child.Name == "Bomb") and BombESPModule.highlights[child] then
                RemoveBombESP(child)
            end
        end)
        
        -- Следим за изменением состояния бомбы
        BombESPModule.connections.bombState = workspace.ChildChanged:Connect(function(child)
            if (child.Name == "C4" or child.Name == "Bomb") and child:FindFirstChild("Planted") then
                OnBombStateChanged(child)
            end
        end)
        
    else
        -- Отключаем все соединения
        for name, connection in pairs(BombESPModule.connections) do
            if connection then
                connection:Disconnect()
            end
        end
        BombESPModule.connections = {}
        
        -- Удаляем все ESP элементы
        for bomb, _ in pairs(BombESPModule.highlights) do
            RemoveBombESP(bomb)
        end
    end
end
-- ================================
-- GRENADE TRAJECTORY MODULE
-- ================================
local GrenadeTrajectory = {
    Enabled = false,
    Color = Color3.fromRGB(255, 50, 50),
    Transparency = 0.7,
    Thickness = 0.5,
    Parts = {},
    Connection = nil
}

local function CreateTrajectoryPart()
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = GrenadeTrajectory.Color
    part.Transparency = GrenadeTrajectory.Transparency
    part.Size = Vector3.new(GrenadeTrajectory.Thickness, GrenadeTrajectory.Thickness, GrenadeTrajectory.Thickness)
    part.Shape = Enum.PartType.Ball
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    table.insert(GrenadeTrajectory.Parts, part)
    return part
end

local function ClearTrajectory()
    for _, part in ipairs(GrenadeTrajectory.Parts) do
        if part then
            part:Destroy()
        end
    end
    GrenadeTrajectory.Parts = {}
end

local function CalculateTrajectory(startPos, velocity, gravity, steps, timeStep)
    local points = {}
    
    for i = 1, steps do
        local t = i * timeStep
        local displacement = velocity * t + 0.5 * gravity * t * t
        local position = startPos + displacement
        
        -- Проверяем коллизии
        local ray = Ray.new(startPos, displacement)
        local hit, hitPos = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, workspace.Ray_Ignore})
        
        if hit then
            table.insert(points, hitPos)
            break
        else
            table.insert(points, position)
        end
    end
    
    return points
end

local function OnGrenadeThrown(grenade)
    if not GrenadeTrajectory.Enabled or not grenade:IsA("BasePart") then return end
    
    ClearTrajectory()
    
    local gravity = workspace.Gravity * Vector3.new(0, -1, 0)
    local conn
    
    conn = RunService.Heartbeat:Connect(function()
        if not grenade or not grenade.Parent or not GrenadeTrajectory.Enabled then
            conn:Disconnect()
            task.delay(2, ClearTrajectory)
            return
        end
        
        local velocity = grenade.AssemblyLinearVelocity
        local points = CalculateTrajectory(
            grenade.Position,
            velocity,
            gravity,
            30,
            0.1
        )
        
        -- Обновляем или создаем части траектории
        for i, point in ipairs(points) do
            if not GrenadeTrajectory.Parts[i] then
                GrenadeTrajectory.Parts[i] = CreateTrajectoryPart()
            end
            GrenadeTrajectory.Parts[i].Position = point
            GrenadeTrajectory.Parts[i].Parent = workspace
        end
        
        -- Удаляем лишние части
        for i = #points + 1, #GrenadeTrajectory.Parts do
            if GrenadeTrajectory.Parts[i] then
                GrenadeTrajectory.Parts[i]:Destroy()
                GrenadeTrajectory.Parts[i] = nil
            end
        end
    end)
end

local function toggleGrenadeTrajectory(state)
    GrenadeTrajectory.Enabled = state
    
    if state then
        if GrenadeTrajectory.Connection then
            GrenadeTrajectory.Connection:Disconnect()
        end
        
        GrenadeTrajectory.Connection = workspace.ChildAdded:Connect(function(child)
            if child.Name == "Grenade" and child:IsA("BasePart") then
                OnGrenadeThrown(child)
            end
        end)
        
        -- Проверяем существующие гранаты
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name == "Grenade" and child:IsA("BasePart") then
                OnGrenadeThrown(child)
            end
        end
    else
        if GrenadeTrajectory.Connection then
            GrenadeTrajectory.Connection:Disconnect()
            GrenadeTrajectory.Connection = nil
        end
        ClearTrajectory()
    end
end

-- ================================
-- REGISTER CATEGORIES
-- ================================

UmbrellaHub.api:setCategories({
    {name = "Server", icon = "http://www.roblox.com/asset/?id=103577523623326"},
    {name = "World", icon = "http://www.roblox.com/asset/?id=136613041915472"},
    {name = "Player", icon = "http://www.roblox.com/asset/?id=85568792810849"},
    {name = "Utility", icon = "http://www.roblox.com/asset/?id=124280107087786"},
    {name = "Combat", icon = "http://www.roblox.com/asset/?id=109730932565942"}
})

-- ================================
-- MODULE REGISTRATION
-- ================================

-- PLAYER MODULES

UmbrellaHub.api:registerModule("Player", {
    name = "Auto Bhop",
    enabled = false,
    callback = function(enabled)
        toggleBhop(enabled)
    end
})

UmbrellaHub.api:registerModule("Player", {
    name = "Third Person",
    enabled = false,
    callback = function(enabled)
        toggleThirdPerson(enabled)
    end
})

-- COMBAT MODULES
UmbrellaHub.api:registerModule("Combat", {
    name = "Silent Aim",
    enabled = false,
    callback = function(enabled)
        toggleSilentAim(enabled)
    end
})

UmbrellaHub.api:registerModule("Combat", {
    name = "Spin Bot",
    enabled = false,
    callback = function(enabled)
        toggleSpinBot(enabled)
    end
})

UmbrellaHub.api:registerModule("Combat", {
    name = "Fast Plant",
    enabled = false,
    callback = function(enabled)
        toggleFastPlant(enabled)
    end
})

UmbrellaHub.api:registerModule("Combat", {
    name = "Quick Defuse",
    enabled = false,
    callback = function(enabled)
        toggleQuickDefuse(enabled)
    end
})

-- WORLD MODULES
UmbrellaHub.api:registerModule("World", {
    name = "FOV Changer",
    enabled = false,
    callback = function(enabled)
        toggleFov(enabled)
    end
})

UmbrellaHub.api:registerModule("World", {
    name = "Chams",
    enabled = false,
    callback = function(enabled)
        toggleChams(enabled)
    end
})

UmbrellaHub.api:registerModule("World", {
    name = "ESP",
    enabled = false,
    callback = function(enabled)
        toggleESP(enabled)
    end
})

UmbrellaHub.api:registerModule("World", {
    name = "Bomb ESP",
    enabled = false,
    callback = function(enabled)
        toggleBombESP(enabled)
    end
})

UmbrellaHub.api:registerModule("World", {
    name = "Grenade Trajectory",
    enabled = false,
    callback = function(enabled)
        toggleGrenadeTrajectory(enabled)
    end
})

-- UTILITY MODULES
UmbrellaHub.api:registerModule("Utility", {
    name = "Kill Say",
    enabled = false,
    callback = function(enabled)
        toggleKillSay(enabled)
    end
})

UmbrellaHub.api:registerModule("Combat", {
    name = "Penetration",
    enabled = false,
    callback = function(enabled)
        togglePenetration(enabled)
    end
})

UmbrellaHub.api:registerModule("Combat", {
    name = "Infinite Ammo",
    enabled = false,
    callback = function(enabled)
        toggleInfiniteAmmo(enabled)
    end
})

-- Регистрация модуля Rapid Fire
UmbrellaHub.api:registerModule("Combat", {
    name = "Rapid Fire",
    enabled = false,
    callback = function(enabled)
        toggleRapidFire(enabled)
    end
})


-- ================================
-- SETTINGS REGISTRATION
-- ================================

UmbrellaHub.api:registerSettings("Penetration", {
    {
        name = "Max Penetration",
        type = "slider",
        min = 50,
        max = 200,
        default = 100,
        callback = function(value)
            PenetrationModule.maxPenetration = value
        end
    },
    {
        name = "Max Obstacles",
        type = "slider",
        min = 1,
        max = 8,
        default = 4,
        callback = function(value)
            PenetrationModule.maxObstacles = value
        end
    }
})

-- Настройки Infinite Ammo
UmbrellaHub.api:registerSettings("Infinite Ammo", {
    {
        name = "Primary Ammo",
        type = "slider",
        min = 100,
        max = 999999,
        default = 999999,
        callback = function(value)
            -- Значение устанавливается автоматически в модуле
        end
    },
    {
        name = "Secondary Ammo",
        type = "slider",
        min = 100,
        max = 999999,
        default = 999999,
        callback = function(value)
            -- Значение устанавливается автоматически в модуле
        end
    }
})

-- Настройки Rapid Fire
UmbrellaHub.api:registerSettings("Rapid Fire", {
    {
        name = "Fire Rate Multiplier",
        type = "slider",
        min = 1,
        max = 10,
        default = 5,
        isPercentage = false,
        callback = function(value)
            RapidFireModule.fireRateMultiplier = value
        end
    }
})

-- Auto Bhop Settings
UmbrellaHub.api:registerSettings("Auto Bhop", {
    {
        name = "Speed",
        type = "slider",
        min = 20,
        max = 100,
        default = 30,
        callback = function(value)
            BhopSettings.Speed = value
        end
    },
    {
        name = "Direction",
        type = "dropdown",
        options = {"directional", "forward"},
        default = "directional",
        callback = function(value)
            BhopSettings.Direction = value
        end
    },
    {
        name = "Edge Jump",
        type = "toggle",
        default = false,
        callback = function(value)
            BhopSettings.EdgeJump = value
        end
    },
    {
        name = "Strafe Boost",
        type = "toggle",
        default = true,
        callback = function(value)
            BhopSettings.StrafeBoost = value
        end
    },
    {
        name = "Strafe Multiplier",
        type = "slider",
        min = 1,
        max = 3,
        default = 1.5,
        isPercentage = true,
        callback = function(value)
            BhopSettings.StrafeMultiplier = value / 100
        end
    }
})

-- Third Person Settings
UmbrellaHub.api:registerSettings("Third Person", {
    {
        name = "Distance",
        type = "slider",
        min = 3,
        max = 20,
        default = 5,
        callback = function(value)
            ThirdPersonModule.distance = value
            if ThirdPersonModule.enabled then
                LocalPlayer.CameraMaxZoomDistance = value
                LocalPlayer.CameraMinZoomDistance = value
            end
        end
    }
})

-- Silent Aim Settings
UmbrellaHub.api:registerSettings("Silent Aim", {
    {
        name = "Team Check",
        type = "toggle",
        default = true,
        callback = function(value)
            silentAimSettings.CheckTeam = value
        end
    },
    {
        name = "Head Chance",
        type = "slider",
        min = 0,
        max = 100,
        default = 80,
        isPercentage = true,
        callback = function(value)
            silentAimSettings.HeadChance = value
        end
    },
    {
        name = "Enable FOV",
        type = "toggle",
        default = true,
        callback = function(value)
            silentAimSettings.FOVEnabled = value
            if not value then
                FOVCircle.Visible = false
            end
        end
    },
    {
        name = "FOV",
        type = "slider",
        min = 10,
        max = 200,
        default = 60,
        callback = function(value)
            silentAimSettings.FOV = value
        end
    }
})

-- Spin Bot Settings
UmbrellaHub.api:registerSettings("Spin Bot", {
    {
        name = "Speed",
        type = "slider",
        min = 1,
        max = 100,
        default = 20,
        callback = function(value)
            SpinSettings.Speed = value
        end
    },
    {
        name = "Anti Aim",
        type = "toggle",
        default = true,
        callback = function(value)
            SpinSettings.AntiAim = value
        end
    },
    {
        name = "Spin When Dead",
        type = "toggle",
        default = true,
        callback = function(value)
            SpinSettings.SpinDead = value
        end
    }
})

-- Fast Plant Settings
UmbrellaHub.api:registerSettings("Fast Plant", {
    {
        name = "Plant Type",
        type = "dropdown",
        options = {"Normal", "Anti def."},
        default = "Normal",
        callback = function(value)
            FastPlantModule.plantType = value
        end
    }
})

-- Quick Defuse Settings
UmbrellaHub.api:registerSettings("Quick Defuse", {
    {
        name = "Defuse Type",
        type = "dropdown",
        options = {"Near", "Anywhere"},
        default = "Near",
        callback = function(value)
            QuickDefuseModule.defuseType = value
        end
    }
})

-- FOV Changer Settings
UmbrellaHub.api:registerSettings("FOV Changer", {
    {
        name = "FOV",
        type = "slider",
        min = 30,
        max = 120,
        default = 90,
        callback = function(value)
            FovModule.fov = value
            if FovModule.enabled then
                workspace.CurrentCamera.FieldOfView = value
            end
        end
    }
})

-- Chams Settings
UmbrellaHub.api:registerSettings("Chams", {
    {
        name = "Team Based",
        type = "toggle",
        default = true,
        callback = function(value)
            ChamsModule.teamBased = value
            if ChamsModule.enabled then
                refreshAllPlayers()
            end
        end
    },
    {
        name = "Transparency",
        type = "slider",
        min = 0,
        max = 100,
        default = 80,
        isPercentage = true,
        callback = function(value)
            ChamsModule.fillTransparency = value / 100
            if ChamsModule.enabled then
                refreshAllPlayers()
            end
        end
    }
})

-- ESP Settings
UmbrellaHub.api:registerSettings("ESP", {
    {
        name = "Team Color",
        type = "toggle",
        default = true,
        callback = function(value)
            SkeletonESP.TeamColor = value
        end
    },
    {
        name = "Show Health Bar",
        type = "toggle", 
        default = true,
        callback = function(value)
            SkeletonESP.ShowHealthBar = value
        end
    },
    {
        name = "Show Name",
        type = "toggle",
        default = true,
        callback = function(value)
            SkeletonESP.ShowName = value
        end
    },
    {
        name = "Show Head",
        type = "toggle",
        default = true,
        callback = function(value)
            SkeletonESP.ShowHead = value
        end
    },
    {
        name = "Thickness",
        type = "slider",
        min = 1,
        max = 5,
        default = 1,
        callback = function(value)
            SkeletonESP.Thickness = value
        end
    },
    {
        name = "Show Weapon",
        type = "toggle",
        default = true,
        callback = function(value)
            SkeletonESP.ShowWeapon = value
        end
    }
})

-- Bomb ESP Settings
UmbrellaHub.api:registerSettings("Bomb ESP", {
    {
        name = "Show Text",
        type = "toggle",
        default = true,
        callback = function(value)
            BombESPModule.showText = value
            -- Обновляем видимость текста для всех бомб
            for bomb, labels in pairs(BombESPModule.textLabels) do
                if bomb and bomb.Parent and labels[4] then
                    labels[4].Enabled = value
                end
            end
        end
    },
    {
        name = "Transparency",
        type = "slider",
        min = 0,
        max = 100,
        default = 50,
        isPercentage = true,
        callback = function(value)
            BombESPModule.transparency = value / 100
            for bomb, highlight in pairs(BombESPModule.highlights) do
                if bomb and bomb.Parent then
                    highlight.FillTransparency = BombESPModule.transparency
                end
            end
        end
    }
})

-- Grenade Trajectory Settings
UmbrellaHub.api:registerSettings("Grenade Trajectory", {
    {
        name = "Transparency",
        type = "slider",
        min = 0,
        max = 100,
        default = 70,
        isPercentage = true,
        callback = function(value)
            GrenadeTrajectory.Transparency = value / 100
            for _, part in ipairs(GrenadeTrajectory.Parts) do
                if part then
                    part.Transparency = GrenadeTrajectory.Transparency
                end
            end
        end
    },
    {
        name = "Thickness",
        type = "slider",
        min = 0.1,
        max = 2,
        default = 0.5,
        callback = function(value)
            GrenadeTrajectory.Thickness = value
            for _, part in ipairs(GrenadeTrajectory.Parts) do
                if part then
                    part.Size = Vector3.new(value, value, value)
                end
            end
        end
    }
})

-- Kill Say Settings
UmbrellaHub.api:registerSettings("Kill Say", {
    {
        name = "Message",
        type = "textfield",
        default = "ez get Umbrella.hub",
        placeholder = "Enter your message...",
        callback = function(value)
            KillSayModule.message = value
        end
    }
})

-- Инициализируем UI
UmbrellaHub.init()
