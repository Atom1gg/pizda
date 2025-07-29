local function FastPlantModule()
    local module = {
        enabled = false,
        plantType = "Normal" -- "Normal" or "Anti def."
    }

    local function GetSite()
        local spawnA = workspace.Map.SpawnPoints.C4Plant.Position
        local spawnB = workspace.Map.SpawnPoints.C4Plant2.Position
        local playerPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
        
        if (playerPos - spawnA).Magnitude < (playerPos - spawnB).Magnitude then
            return "B"
        else
            return "A"
        end
    end

    local function Enable()
        if module.enabled then return end
        
        module.connection = game:GetService("UserInputService").InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("EquippedTool") and char.EquippedTool.Value == "C4" then
                    if module.plantType == "Normal" then
                        game.ReplicatedStorage.Events.PlantC4:FireServer(
                            (char.HumanoidRootPart.CFrame + Vector3.new(0, -2, 0)) * CFrame.Angles(0, 0, 4),
                            GetSite()
                        )
                    else -- Anti def.
                        game.ReplicatedStorage.Events.PlantC4:FireServer(
                            char.HumanoidRootPart.CFrame + Vector3.new(0, -6, 0),
                            ""
                        )
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
        SetPlantType = function(type)
            module.plantType = type
        end,
        enabled = module.enabled
    }
end

return FastPlantModule()