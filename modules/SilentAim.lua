-- modules/SilentAim.lua
local module = {}

-- Настройки по умолчанию
local settings = {
    CheckTeam = true,
    OnlyHead = true,
    MaxDistance = 1000,
    Enabled = false
}

-- Основные объекты
local CurrentCamera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Поиск цели
local function FindTarget()
    if not settings.Enabled then return nil end
    
    local MaxDist = settings.MaxDistance
    local Closest = nil
    
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player == LocalPlayer then continue end
        
        if settings.CheckTeam and Player.Team == LocalPlayer.Team then
            continue
        end
        
        local Character = Player.Character
        if not Character then continue end
        
        local TargetPart
        if settings.OnlyHead then
            TargetPart = Character:FindFirstChild("Head")
        else
            TargetPart = Character:FindFirstChild("HumanoidRootPart") or 
                        Character:FindFirstChild("UpperTorso") or
                        Character:FindFirstChild("LowerTorso")
        end
        
        if not TargetPart then continue end
        
        local Pos, Vis = CurrentCamera:WorldToScreenPoint(TargetPart.Position)
        if not Vis then continue end
        
        local MousePos = Vector2.new(Mouse.X, Mouse.Y)
        local TheirPos = Vector2.new(Pos.X, Pos.Y)
        local Dist = (TheirPos - MousePos).Magnitude
        
        if Dist < MaxDist then
            MaxDist = Dist
            Closest = {Player = Player, Part = TargetPart}
        end
    end
    
    return Closest
end

-- Хук метатаблицы
local MT = getrawmetatable(game)
local OldNC = MT.__namecall
local OldIDX = MT.__index

local function Hook()
    setreadonly(MT, false)
    
    MT.__namecall = newcclosure(function(self, ...)
        if not settings.Enabled then
            return OldNC(self, ...)
        end
        
        local Args = {...}
        local Method = getnamecallmethod()
        
        if (Method == "FindPartOnRayWithIgnoreList" or Method == "FindPartOnRay") and not checkcaller() then
            local Target = FindTarget()
            
            if Target and Target.Part then
                local RayOrigin = CurrentCamera.CFrame.Position
                local RayDirection = (Target.Part.Position - RayOrigin).Unit * settings.MaxDistance
                Args[1] = Ray.new(RayOrigin, RayDirection)
                Args[2] = {LocalPlayer.Character} -- Игнорируем себя
                return OldNC(self, unpack(Args))
            end
        end
        
        return OldNC(self, ...)
    end)
    
    setreadonly(MT, true)
end

-- API модуля
function module.Toggle(state)
    settings.Enabled = state
    if state then
        Hook()
    end
end

function module.SetTeamCheck(value)
    settings.CheckTeam = value
end

function module.SetOnlyHead(value)
    settings.OnlyHead = value
end

function module.SetMaxDistance(value)
    settings.MaxDistance = value
end

return module
