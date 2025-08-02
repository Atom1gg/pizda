local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local SkeletonESP = {
    Enabled = false,
    TeamColor = true, -- Используем цвет команды
    EnemyColor = Color3.fromRGB(255, 50, 50),
    AllyColor = Color3.fromRGB(50, 50, 255),
    Thickness = 1,
    ShowWeapon = true
}

local R6_BONES = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

local WEAPON_ATTACHMENTS = {
    "RightHand", -- Для большинства оружия
    "LeftHand"   -- Для ножей/гранат
}

local drawings = {}

local function CreateDrawing(type, props)
    local drawing = Drawing.new(type)
    for prop, value in pairs(props) do
        drawing[prop] = value
    end
    table.insert(drawings, drawing)
    return drawing
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R6 then continue end
            
            -- Определяем цвет
            local color = SkeletonESP.TeamColor and 
                         (player.Team == LocalPlayer.Team and SkeletonESP.AllyColor or SkeletonESP.EnemyColor) or
                         SkeletonESP.EnemyColor
            
            -- Рисуем скелет
            for _, bonePair in ipairs(R6_BONES) do
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
                    
                    local pos1 = Camera:WorldToViewportPoint(part1.Position)
                    local pos2 = Camera:WorldToViewportPoint(part2.Position)
                    
                    if pos1.Z > 0 and pos2.Z > 0 then
                        drawings[key].From = Vector2.new(pos1.X, pos1.Y)
                        drawings[key].To = Vector2.new(pos2.X, pos2.Y)
                        drawings[key].Visible = SkeletonESP.Enabled
                    else
                        drawings[key].Visible = false
                    end
                end
            end
            
            -- Рисуем оружие
            if SkeletonESP.ShowWeapon then
                for _, attachName in ipairs(WEAPON_ATTACHMENTS) do
                    local attach = character:FindFirstChild(attachName)
                    if attach then
                        for _, child in ipairs(attach:GetChildren()) do
                            if child:IsA("BasePart") and child.Name ~= "Handle" then
                                local key = player.Name.."Weapon"..child.Name
                                if not drawings[key] then
                                    drawings[key] = CreateDrawing("Line", {
                                        Thickness = SkeletonESP.Thickness,
                                        Color = color,
                                        Visible = false
                                    })
                                end
                                
                                local handPos = Camera:WorldToViewportPoint(attach.Position)
                                local weaponPos = Camera:WorldToViewportPoint(child.Position)
                                
                                if handPos.Z > 0 and weaponPos.Z > 0 then
                                    drawings[key].From = Vector2.new(handPos.X, handPos.Y)
                                    drawings[key].To = Vector2.new(weaponPos.X, weaponPos.Y)
                                    drawings[key].Visible = SkeletonESP.Enabled
                                else
                                    drawings[key].Visible = false
                                end
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

return {
    Toggle = function(state)
        SkeletonESP.Enabled = state
        if not state then ClearDrawings() end
    end,
    SetTeamColor = function(state)
        SkeletonESP.TeamColor = state
    end,
    SetThickness = function(value)
        SkeletonESP.Thickness = value
        for _, drawing in pairs(drawings) do
            if drawing.ClassName == "Line" then
                drawing.Thickness = value
            end
        end
    end,
    SetShowWeapon = function(state)
        SkeletonESP.ShowWeapon = state
    end
}
