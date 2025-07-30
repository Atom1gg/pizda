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

-- Кэш функций
local Ray_new = Ray.new
local Vector2_new = Vector2.new
local WorldToScreenPoint = CurrentCamera.WorldToScreenPoint
local FindFirstChild = game.FindFirstChild
local GetPlayers = Players.GetPlayers

-- Поиск цели
local function FindTarget()
    local MaxDist = settings.MaxDistance
    local Closest = nil
    
    local LocalTeam = settings.CheckTeam and LocalPlayer.Team or nil
    
    for _, Player in ipairs(GetPlayers(Players)) do
        if Player == LocalPlayer then continue end
        
        if settings.CheckTeam then
            local PlayerTeam = Player.Team
            if PlayerTeam and LocalTeam and PlayerTeam == LocalTeam then continue end
        end
        
        local Character = Player.Character
        if not Character then continue end
        
        local TargetPart
        if settings.OnlyHead then
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

-- Хук метатаблицы
local MT = getrawmetatable(game)
local OldNC = MT.__namecall
local OldIDX = MT.__index

local function Hook()
    setreadonly(MT, false)
    
    MT.__namecall = newcclosure(function(self, ...)
        local Args = {...}
        local Method = getnamecallmethod()
        
        if settings.Enabled and Method == "FindPartOnRayWithIgnoreList" and not checkcaller() then
            local Target = FindTarget()
            
            if Target and Target.Part then
                local RayOrigin = CurrentCamera.CFrame.Position
                local RayDirection = (Target.Part.Position - RayOrigin).Unit * settings.MaxDistance
                Args[1] = Ray_new(RayOrigin, RayDirection)
                return OldNC(self, unpack(Args))
            end
        end
        
        return OldNC(self, ...)
    end)
    
    setreadonly(MT, true)
end

-- API модуля
function module.Enable()
    settings.Enabled = true
    Hook()
end

function module.Disable()
    settings.Enabled = false
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
