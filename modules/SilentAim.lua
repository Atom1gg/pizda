local function SilentAimModule()
    local module = {
        enabled = false,
        headOnly = true, -- Новый параметр для выбора между головой и торсом
        hitChance = 100,
        originalMT = nil,
        originalNC = nil,
        originalIDX = nil
    }

    local CurrentCamera = workspace.CurrentCamera
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()

    local function ClosestPlayer()
        local MaxDist, Closest = math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if player.Team == LocalPlayer.Team then continue end
            if not player.Character then continue end
            
            local targetPart = module.headOnly and player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart")
            if not targetPart then continue end
            
            local Pos, Vis = CurrentCamera:WorldToScreenPoint(targetPart.Position)
            if not Vis then continue end
            
            local MousePos = Vector2.new(Mouse.X, Mouse.Y)
            local TheirPos = Vector2.new(Pos.X, Pos.Y)
            local Dist = (TheirPos - MousePos).Magnitude
            
            if Dist < MaxDist then
                MaxDist = Dist
                Closest = player
            end
        end
        return Closest
    end

    local function Enable()
        if module.enabled then return end
        
        local MT = getrawmetatable(game)
        module.originalMT = MT
        module.originalNC = MT.__namecall
        module.originalIDX = MT.__index
        
        setreadonly(MT, false)
        
        MT.__namecall = newcclosure(function(self, ...)
            local Args, Method = {...}, getnamecallmethod()
            
            if Method == "FindPartOnRayWithIgnoreList" and not checkcaller() then
                if math.random(1, 100) > module.hitChance then
                    return module.originalNC(self, ...)
                end
                
                local CP = ClosestPlayer()
                if CP and CP.Character then
                    local targetPart = module.headOnly and CP.Character:FindFirstChild("Head") or CP.Character:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        Args[1] = Ray.new(CurrentCamera.CFrame.Position, (targetPart.Position - CurrentCamera.CFrame.Position).Unit * 1000)
                        return module.originalNC(self, unpack(Args))
                    end
                end
            end
            return module.originalNC(self, ...)
        end)
        
        MT.__index = newcclosure(function(self, K)
            if K == "Clips" then
                return workspace.Map
            end
            return module.originalIDX(self, K)
        end)
        
        setreadonly(MT, true)
        module.enabled = true
    end

    local function Disable()
        if not module.enabled then return end
        
        if module.originalMT then
            setreadonly(module.originalMT, false)
            module.originalMT.__namecall = module.originalNC
            module.originalMT.__index = module.originalIDX
            setreadonly(module.originalMT, true)
        end
        
        module.enabled = false
    end

    return {
        Toggle = function(state)
            if state then
                Enable()
            else
                Disable()
            end
        end,
        SetHeadOnly = function(state)
            module.headOnly = state
        end,
        SetHitChance = function(value)
            module.hitChance = value
        end,
        enabled = module.enabled
    }
end

return SilentAimModule()
