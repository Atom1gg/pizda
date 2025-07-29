local function QuickDefuseModule()
    local module = {
        enabled = false,
        defuseType = "Near" -- "Near" or "Anywhere"
    }

    local function Enable()
        if module.enabled then return end
        
        module.connection = game:GetService("UserInputService").InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.E then
                if workspace:FindFirstChild("C4") then
                    if module.defuseType == "Near" then
                        if (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - workspace.C4.Position).Magnitude < 10 then
                            game.Players.LocalPlayer.Backpack.Defuse:FireServer(workspace.C4)
                        end
                    else -- Anywhere
                        game.Players.LocalPlayer.Backpack.Defuse:FireServer(workspace.C4)
                    end
                end
            end
        end)
        
        module.enabled = true
    end

    local function Disable()
        if not module.enabled then return end
        if module.connection then
            module.connection:Disconnect()
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
        SetDefuseType = function(type)
            module.defuseType = type
        end,
        enabled = module.enabled
    }
end

return QuickDefuseModule()