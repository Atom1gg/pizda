local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character
local Humanoid
local RootPart

local Settings = {
    Enabled = false,
    Speed = 20,
    Angle = 0,
    AntiAim = true,
    SpinDead = true -- Крутиться даже после смерти
}

local Connection

-- Обновляем ссылки на персонажа
local function UpdateCharacter()
    Character = LocalPlayer.Character
    if Character then
        Humanoid = Character:WaitForChild("Humanoid")
        RootPart = Character:WaitForChild("HumanoidRootPart")
        return true
    end
    return false
end

-- Основная логика вращения
local function Spin()
    if not Settings.Enabled then return end
    
    -- Обновляем ссылки, если персонаж изменился/переродился
    if not Character or not RootPart or not RootPart:IsDescendantOf(workspace) then
        if not UpdateCharacter() then return end
    end

    -- Не крутимся, если персонаж мертв и SpinDead выключен
    if Humanoid and Humanoid:GetState() == Enum.HumanoidStateType.Dead and not Settings.SpinDead then
        return
    end

    -- Вычисляем вращение
    Settings.Angle = (Settings.Angle + Settings.Speed) % 360
    local CFrameSpin = CFrame.new(RootPart.Position) * CFrame.Angles(0, math.rad(Settings.Angle), 0)
    
    -- Добавляем Anti-Aim (наклон головы)
    if Settings.AntiAim then
        CFrameSpin = CFrameSpin * CFrame.Angles(math.rad(-90), 0, 0)
    end
    
    -- Применяем вращение
    RootPart.CFrame = CFrameSpin
end

-- Обработчик изменения персонажа
local function CharacterAdded(newCharacter)
    Character = newCharacter
    Humanoid = newCharacter:WaitForChild("Humanoid")
    RootPart = newCharacter:WaitForChild("HumanoidRootPart")
end

-- Включение/выключение
local function Toggle(state)
    Settings.Enabled = state
    
    if state then
        -- Подключаемся к текущему персонажу
        if LocalPlayer.Character then
            CharacterAdded(LocalPlayer.Character)
        end
        -- Слушаем появление нового персонажа
        LocalPlayer.CharacterAdded:Connect(CharacterAdded)
        -- Запускаем вращение
        Connection = RunService.Heartbeat:Connect(Spin)
    else
        -- Отключаем всё
        if Connection then
            Connection:Disconnect()
            Connection = nil
        end
        -- Возвращаем нормальное положение
        if RootPart and RootPart:IsDescendantOf(workspace) then
            RootPart.CFrame = CFrame.new(RootPart.Position, RootPart.Position + Vector3.new(0, 0, -1))
        end
    end
end

return {
    Toggle = Toggle,
    SetSpeed = function(value) Settings.Speed = value end,
    SetAntiAim = function(state) Settings.AntiAim = state end,
    SetSpinDead = function(state) Settings.SpinDead = state end -- Новая функция
}
