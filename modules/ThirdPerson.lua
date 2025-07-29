local function ThirdPersonModule()
    local module = {
        enabled = false,
        toggleKey = Enum.KeyCode.H,
        distance = 5
    }

    local function Enable()
        if module.enabled then return end
        
        local player = game.Players.LocalPlayer
        player.CameraMode = Enum.CameraMode.Classic
        player.CameraMaxZoomDistance = module.distance
        player.CameraMinZoomDistance = module.distance
        
        module.enabled = true
    end

    local function Disable()
        if not module.enabled then return end
        
        local player = game.Players.LocalPlayer
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        player.CameraMaxZoomDistance = 0.5
        player.CameraMinZoomDistance = 0.5
        
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
        SetDistance = function(dist)
            module.distance = dist
            if module.enabled then
                game.Players.LocalPlayer.CameraMaxZoomDistance = dist
                game.Players.LocalPlayer.CameraMinZoomDistance = dist
            end
        end,
        SetKey = function(key)
            module.toggleKey = key
        end,
        enabled = module.enabled
    }
end

return ThirdPersonModule()