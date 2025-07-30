local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

local Settings = {
    Enabled = false,
    Speed = 20, -- Скорость вращения (градусы в секунду)
    Angle = 0,
    AntiAim = true -- Наклон головы (можно отключить)
}

local function Spin()
    if not Settings.Enabled or not RootPart then return end
    
    Settings.Angle = (Settings.Angle + Settings.Speed) % 360
    
    local CFrameSpin = CFrame.new(RootPart.Position) * CFrame.Angles(0, math.rad(Settings.Angle), 0)
    
    if Settings.AntiAim then
        -- Наклон головы (можно настроить под себя)
        CFrameSpin = CFrameSpin * CFrame.Angles(math.rad(-90), 0, 0)
    end
    
    RootPart.CFrame = CFrameSpin
end

local Connection
local function Toggle(state)
    Settings.Enabled = state
    if state then
        Connection = RunService.Heartbeat:Connect(Spin)
    else
        if Connection then
            Connection:Disconnect()
            -- Возвращаем нормальный поворот
            if RootPart then
                RootPart.CFrame = CFrame.new(RootPart.Position, RootPart.Position + Vector3.new(0, 0, -1))
            end
        end
    end
end

return {
    Toggle = Toggle,
    SetSpeed = function(value) Settings.Speed = value end,
    SetAntiAim = function(state) Settings.AntiAim = state end
}
