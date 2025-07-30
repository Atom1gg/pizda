local CurrentCamera = workspace.CurrentCamera
local Players = game.Players
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Settings
local HeadOnly = true

function ClosestPlayer()
    local MaxDist, Closest = math.huge
    for I,V in pairs(Players:GetPlayers()) do
        if V == LocalPlayer then continue end
        if V.Team == LocalPlayer.Team then continue end
        if not V.Character then continue end
        local Head = V.Character:FindFirstChild("Head")
        if not Head then continue end
        local Pos, Vis = CurrentCamera:WorldToScreenPoint(Head.Position)
        if not Vis then continue end
        local MousePos, TheirPos = Vector2.new(Mouse.X, Mouse.Y), Vector2.new(Pos.X, Pos.Y)
        local Dist = (TheirPos - MousePos).Magnitude
        if Dist < MaxDist then
            MaxDist = Dist
            Closest = V
        end
    end
    return Closest
end

local MT = getrawmetatable(game)
local OldNC = MT.__namecall
local OldIDX = MT.__index
setreadonly(MT, false)

MT.__namecall = newcclosure(function(self, ...)
    local Args, Method = {...}, getnamecallmethod()
    if Method == "FindPartOnRayWithIgnoreList" and not checkcaller() then
        local CP = ClosestPlayer()
        if CP and CP.Character then
            local TargetPart = CP.Character:FindFirstChild("Head") or (not HeadOnly and CP.Character:FindFirstChild("HumanoidRootPart"))
            if TargetPart then
                Args[1] = Ray.new(CurrentCamera.CFrame.Position, (TargetPart.Position - CurrentCamera.CFrame.Position).Unit * 1000)
                return OldNC(self, unpack(Args))
            end
        end
    end
    return OldNC(self, ...)
end)

MT.__index = newcclosure(function(self, K)
    if K == "Clips" then
        return workspace.Map
    end
    return OldIDX(self, K)
end)

setreadonly(MT, true)

return {
    Toggle = function(state)
        if not state then
            setreadonly(MT, false)
            MT.__namecall = OldNC
            MT.__index = OldIDX
            setreadonly(MT, true)
        else
            setreadonly(MT, false)
            MT.__namecall = newcclosure(function(self, ...)
                local Args, Method = {...}, getnamecallmethod()
                if Method == "FindPartOnRayWithIgnoreList" and not checkcaller() then
                    local CP = ClosestPlayer()
                    if CP and CP.Character then
                        local TargetPart = CP.Character:FindFirstChild("Head") or (not HeadOnly and CP.Character:FindFirstChild("HumanoidRootPart"))
                        if TargetPart then
                            Args[1] = Ray.new(CurrentCamera.CFrame.Position, (TargetPart.Position - CurrentCamera.CFrame.Position).Unit * 1000)
                            return OldNC(self, unpack(Args))
                        end
                    end
                end
                return OldNC(self, ...)
            end)
            MT.__index = newcclosure(function(self, K)
                if K == "Clips" then
                    return workspace.Map
                end
                return OldIDX(self, K)
            end)
            setreadonly(MT, true)
        end
    end,
    
    SetHeadOnly = function(state)
        HeadOnly = state
    end
}
