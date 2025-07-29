local function AutoBhopModule()
    local module = {
        enabled = false,
        toggleKey = Enum.KeyCode.Space
    }

    local function Enable()
        if module.enabled then return end
        
        local conn
        conn = game:GetService("RunService").RenderStepped:Connect(function()
            if game:GetService("UserInputService"):IsKeyDown(module.toggleKey) then
                local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        
        module.connection = conn
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
        SetKey = function(key)
            module.toggleKey = key
        end,
        enabled = module.enabled
    }
end

return AutoBhopModule()