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
    Direction = "directional", -- "directional", "directional 2", "forward"
    EdgeJump = false
}

local Jitter = false
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

-- Основная логика Bunny Hop
local function BunnyHop()
    if not Settings.Enabled then return end
    
    -- Если персонаж не существует или умер - пытаемся обновить ссылки
    if not Character or not Humanoid or not RootPart or not Humanoid:IsDescendantOf(workspace) then
        if not UpdateCharacter() then return end
    end

    -- Проверяем состояние персонажа
    if Humanoid:GetState() == Enum.HumanoidStateType.Dead then return end

    BodyVelocity:Destroy()
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
    
    -- Bunny Hop Logic
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        local add = 0
        if Settings.Direction == "directional" or Settings.Direction == "directional 2" then
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
        BodyVelocity.Velocity = Vector3.new(rot.LookVector.X, 0, rot.LookVector.Z) * Settings.Speed
        
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

return {
    Toggle = Toggle,
    SetSpeed = function(value) Settings.Speed = value end,
    SetDirection = function(value) Settings.Direction = value end,
    SetEdgeJump = function(state) Settings.EdgeJump = state end
}
