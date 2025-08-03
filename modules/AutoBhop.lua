local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character
local Humanoid
local RootPart

local BodyVelocity = Instance.new("BodyVelocity")
BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
BodyVelocity.P = 1000

local Settings = {
    Enabled = false,
    Speed = 30,
    Direction = "directional", -- "directional", "forward"
    EdgeJump = false,
    StrafeBoost = true,
    StrafeMultiplier = 1.5,
    StrafeSensitivity = 2.0
}

local lastCameraAngle = 0
local cameraRotationSpeed = 0
local Connection

-- Функция для обновления ссылок на персонажа
local function UpdateCharacter()
    Character = LocalPlayer.Character
    if Character then
        Humanoid = Character:WaitForChild("Humanoid")
        RootPart = Character:WaitForChild("HumanoidRootPart")
        return true
    end
    return false
end

-- Функция для расчета скорости поворота камеры
local function CalculateCameraRotation()
    local currentCameraAngle = workspace.CurrentCamera.CFrame:ToEulerAnglesXYZ()
    local deltaAngle = math.deg(currentCameraAngle - lastCameraAngle)
    lastCameraAngle = currentCameraAngle
    cameraRotationSpeed = deltaAngle * Settings.StrafeSensitivity
end

-- Основная логика Bunny Hop
local function BunnyHop()
    if not Settings.Enabled then return end
    
    -- Если персонаж не существует или умер - пытаемся обновить ссылки
    if not Character or not Humanoid or not RootPart or not Humanoid:IsDescendantOf(workspace) then
        if not UpdateCharacter() then return end
    end

    -- Проверяем состояние персонажа
    if Humanoid:GetState() == Enum.HumanoidStateType.Dead then return end

    -- Рассчитываем скорость поворота камеры
    CalculateCameraRotation()

    BodyVelocity:Destroy()
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    
    -- Bunny Hop Logic
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        local add = 0
        if Settings.Direction == "directional" then
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
        
        local speed = Settings.Speed
        -- Применяем ускорение от стрейфа
        if Settings.StrafeBoost and math.abs(cameraRotationSpeed) > 5 then
            speed = speed * Settings.StrafeMultiplier
        end
        
        BodyVelocity.Velocity = Vector3.new(rot.LookVector.X, 0, rot.LookVector.Z) * speed
        
        if add == 0 and Settings.Direction == "directional" and not UserInputService:IsKeyDown(Enum.KeyCode.W) then
            BodyVelocity:Destroy()
        end
    end
    
    -- Edge Jump Logic
    if Settings.EdgeJump then
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

-- Обработчик изменения персонажа
local function CharacterAdded(newCharacter)
    Character = newCharacter
    Humanoid = newCharacter:WaitForChild("Humanoid")
    RootPart = newCharacter:WaitForChild("HumanoidRootPart")
end

-- Включение/выключение модуля
local function Toggle(state)
    Settings.Enabled = state
    
    if state then
        -- Подключаемся к текущему персонажу
        if LocalPlayer.Character then
            CharacterAdded(LocalPlayer.Character)
        end
        -- Слушаем появление нового персонажа
        LocalPlayer.CharacterAdded:Connect(CharacterAdded)
        -- Запускаем основной цикл
        Connection = RunService.Heartbeat:Connect(BunnyHop)
    else
        -- Отключаем всё
        if Connection then
            Connection:Disconnect()
            Connection = nil
        end
        if BodyVelocity then
            BodyVelocity:Destroy()
        end
    end
end

-- Обновленные настройки для UI
return {
    Toggle = Toggle,
    SetSpeed = function(value) Settings.Speed = value end,
    SetDirection = function(value) Settings.Direction = value end,
    SetEdgeJump = function(state) Settings.EdgeJump = state end,
    SetStrafeBoost = function(state) Settings.StrafeBoost = state end,
    SetStrafeMultiplier = function(value) Settings.StrafeMultiplier = value end,
    SetStrafeSensitivity = function(value) Settings.StrafeSensitivity = value end
}
