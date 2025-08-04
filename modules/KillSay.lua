local function KillSayModule()
    local module = {
        enabled = false,
        message = "ez get Umbrella.hub",
        connection = nil,
        lastKills = 0
    }

    local function OnKill()
        local player = game.Players.LocalPlayer
        local currentKills = player:FindFirstChild("Kills") and player.Kills.Value or 0
        
        -- Проверяем увеличение количества убийств
        if currentKills > module.lastKills then
            game:GetService("ReplicatedStorage").Events.PlayerChatted:FireServer(
                module.message,
                false,
                "All",
                false,
                true
            )
        end
        module.lastKills = currentKills
    end

    local function Enable()
        if module.enabled then return end
        
        local player = game.Players.LocalPlayer
        module.lastKills = player:FindFirstChild("Kills") and player.Kills.Value or 0
        
        module.connection = player:GetPropertyChangedSignal("Kills"):Connect(OnKill)
        module.enabled = true
    end

    local function Disable()
        if not module.enabled then return end
        
        if module.connection then
            module.connection:Disconnect()
            module.connection = nil
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
        SetMessage = function(text)
            module.message = text
        end,
        GetMessage = function()
            return module.message
        end,
        enabled = module.enabled
    }
end
