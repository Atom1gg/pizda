local module = {}
local enabled = false
local spinSpeed = 20 -- Скорость вращения (градусов в кадр)

-- Локальные переменные
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local spinConnection = nil

-- Основная функция вращения
local function spinCharacter()
    if not enabled then return end
    
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
    end
end

-- Включение/выключение
function module.Toggle(state)
    enabled = state
    
    if enabled then
        -- Создаем соединение для вращения
        spinConnection = runService.RenderStepped:Connect(spinCharacter)
    else
        -- Отключаем вращение
        if spinConnection then
            spinConnection:Disconnect()
            spinConnection = nil
        end
    end
end

-- Настройка скорости
function module.SetSpeed(value)
    spinSpeed = value
end

return module