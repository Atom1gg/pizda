local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local GrenadeTrajectory = {
    Enabled = false,
    Color = Color3.fromRGB(255, 50, 50),
    Transparency = 0.7,
    Thickness = 0.5,
    Parts = {},
    Connection = nil
}

local function CreatePart()
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
        part:Destroy()
    end
    GrenadeTrajectory.Parts = {}
end

local function CalculateTrajectory(startPos, velocity, gravity, steps)
    local points = {}
    local timeStep = 0.1
    
    for i = 1, steps do
        local t = i * timeStep
        local displacement = velocity * t + 0.5 * gravity * t * t
        local position = startPos + displacement
        table.insert(points, position)
    end
    
    return points
end

local function OnGrenadeThrown(grenade)
    if not GrenadeTrajectory.Enabled then return end
    
    ClearTrajectory()
    
    local gravity = workspace.Gravity * Vector3.new(0, -1, 0)
    local lastPos = grenade.Position
    
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not grenade or not grenade.Parent then
            conn:Disconnect()
            task.delay(2, ClearTrajectory)
            return
        end
        
        local velocity = grenade.AssemblyLinearVelocity
        local points = CalculateTrajectory(
            grenade.Position,
            velocity,
            gravity,
            50
        )
        
        for i, point in ipairs(points) do
            if not GrenadeTrajectory.Parts[i] then
                GrenadeTrajectory.Parts[i] = CreatePart()
            end
            GrenadeTrajectory.Parts[i].Position = point
            GrenadeTrajectory.Parts[i].Parent = workspace
        end
        
        lastPos = grenade.Position
    end)
end

local function Initialize()
    if GrenadeTrajectory.Connection then
        GrenadeTrajectory.Connection:Disconnect()
    end
    
    if GrenadeTrajectory.Enabled then
        GrenadeTrajectory.Connection = workspace.ChildAdded:Connect(function(child)
            if child.Name == "Grenade" then
                OnGrenadeThrown(child)
            end
        end)
    end
end

return {
    Toggle = function(state)
        GrenadeTrajectory.Enabled = state
        Initialize()
        if not state then ClearTrajectory() end
    end,
    SetColor = function(color)
        GrenadeTrajectory.Color = color
        for _, part in ipairs(GrenadeTrajectory.Parts) do
            part.Color = color
        end
    end,
    SetTransparency = function(transparency)
        GrenadeTrajectory.Transparency = transparency
        for _, part in ipairs(GrenadeTrajectory.Parts) do
            part.Transparency = transparency
        end
    end,
    SetThickness = function(thickness)
        GrenadeTrajectory.Thickness = thickness
        for _, part in ipairs(GrenadeTrajectory.Parts) do
            part.Size = Vector3.new(thickness, thickness, thickness)
        end
    end
}
