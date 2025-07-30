-- modules/SilentAim.lua
local module = {}

-- Настройки по умолчанию
local settings = {
    Enabled = false,
    TeamCheck = true,
    OnlyHead = true,
    FOVEnabled = true,
    FOVRadius = 180,
    MaxDistance = 1000,
    VisibleCheck = true
}

-- Отрисовка FOV круга
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Thickness = 1
fovCircle.Color = Color3.new(1, 1, 1) -- Белый цвет

local function UpdateFOVCircle()
    fovCircle.Visible = settings.Enabled and settings.FOVEnabled
    if fovCircle.Visible then
        fovCircle.Radius = settings.FOVRadius
        fovCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)
    end
end

-- Основные объекты
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Поиск цели
local function FindTarget()
    local bestTarget = nil
    local bestFOV = settings.FOVEnabled and settings.FOVRadius or math.huge
    local cameraPos = CurrentCamera.CFrame.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local character = player.Character
        if not character then continue end
        
        local targetPart = settings.OnlyHead and character:FindFirstChild("Head") 
                          or character:FindFirstChild("UpperTorso") 
                          or character:FindFirstChild("HumanoidRootPart")
        if not targetPart then continue end
        
        -- Проверка видимости
        if settings.VisibleCheck then
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {CurrentCamera, character}
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            
            local raycastResult = workspace:Raycast(
                cameraPos,
                (targetPart.Position - cameraPos).Unit * settings.MaxDistance,
                raycastParams
            )
            
            if raycastResult and raycastResult.Instance ~= targetPart then
                continue
            end
        end
        
        -- Проверка FOV
        local screenPos, onScreen = CurrentCamera:WorldToScreenPoint(targetPart.Position)
        if not onScreen then continue end
        
        local mousePos = Vector2.new(Mouse.X, Mouse.Y)
        local targetPos = Vector2.new(screenPos.X, screenPos.Y)
        local fov = (targetPos - mousePos).Magnitude
        
        if fov < bestFOV then
            bestFOV = fov
            bestTarget = {
                Player = player,
                Part = targetPart,
                Position = targetPart.Position
            }
        end
    end
    
    return bestTarget
end

-- Хук метатаблицы
local MT = getrawmetatable(game)
local OldNC = MT.__namecall
local OldIDX = MT.__index

local function Hook()
    setreadonly(MT, false)
    
    MT.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if settings.Enabled and method == "FindPartOnRayWithIgnoreList" and not checkcaller() then
            local target = FindTarget()
            if target then
                local origin = CurrentCamera.CFrame.Position
                local direction = (target.Position - origin).Unit * settings.MaxDistance
                args[1] = Ray.new(origin, direction)
                return OldNC(self, unpack(args))
            end
        end
        
        return OldNC(self, ...)
    end)
    
    setreadonly(MT, true)
end

-- Обновление FOV круга
game:GetService("RunService").RenderStepped:Connect(UpdateFOVCircle)

-- API модуля
function module.Enable(teamCheck, onlyHead, fovEnabled, fovRadius, maxDistance, visibleCheck)
    settings = {
        Enabled = true,
        TeamCheck = teamCheck,
        OnlyHead = onlyHead,
        FOVEnabled = fovEnabled,
        FOVRadius = fovRadius,
        MaxDistance = maxDistance,
        VisibleCheck = visibleCheck
    }
    Hook()
    UpdateFOVCircle()
end

function module.Disable()
    settings.Enabled = false
    fovCircle.Visible = false
end

-- Методы для изменения настроек
function module.SetTeamCheck(state)
    settings.TeamCheck = state
end

function module.SetOnlyHead(state)
    settings.OnlyHead = state
end

function module.SetFOVEnabled(state)
    settings.FOVEnabled = state
    UpdateFOVCircle()
end

function module.SetFOVRadius(value)
    settings.FOVRadius = value
    UpdateFOVCircle()
end

function module.SetMaxDistance(value)
    settings.MaxDistance = value
end

function module.SetVisibleCheck(state)
    settings.VisibleCheck = state
end

return module
