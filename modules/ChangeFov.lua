local function ChangeFOVModule()
    local module = {
        enabled = false,
        fov = 90
    }

    local function Enable()
        if module.enabled then return end
        
        local conn
        conn = game:GetService("RunService").RenderStepped:Connect(function()
            game.Workspace.CurrentCamera.FieldOfView = module.fov
        end)
        
        module.connection = conn
        module.enabled = true
    end

    local function Disable()
        if not module.enabled then return end
        if module.connection then
            module.connection:Disconnect()
        end
        game.Workspace.CurrentCamera.FieldOfView = 70 -- Default FOV
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
        SetFOV = function(value)
            module.fov = value
            if module.enabled then
                game.Workspace.CurrentCamera.FieldOfView = value
            end
        end,
        enabled = module.enabled
    }
end

return ChangeFOVModule()