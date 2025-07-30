local function ChamsModule()
    local module = {
        enabled = false,
        teamBased = true,
        refreshInterval = 1, -- Обновлять каждую секунду
        teamColors = {
            ["Terrorists"] = Color3.fromRGB(255, 200, 0),  -- Желтый для T
            ["Counter-Terrorists"] = Color3.fromRGB(0, 150, 255),  -- Синий для CT
            defaultEnemy = Color3.fromRGB(255, 0, 0)  -- Красный для неизвестных команд
        },
        outlineColor = Color3.fromRGB(255, 255, 255),  -- Белая обводка
        fillTransparency = 0.8,  -- Прозрачность
        refreshConnection = nil,
        playerConnections = {}
    }

    local function applyChams(player)
        if not player or not player.Character then return end
        
        local success, _ = pcall(function()
            local character = player.Character
            local teamColor
            
            if module.teamBased and player.Team then
                teamColor = module.teamColors[player.Team.Name] or module.teamColors.defaultEnemy
            else
                teamColor = module.teamColors.defaultEnemy
            end
            
            local highlight = character:FindFirstChildOfClass("Highlight")
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Parent = character
            end
            
            highlight.OutlineColor = module.outlineColor
            highlight.FillColor = teamColor
            highlight.FillTransparency = module.fillTransparency
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Enabled = module.enabled
        end)
    end

    local function refreshAllPlayers()
        if not module.enabled then return end
        
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                applyChams(player)
            end
        end
    end

    local function setupPlayer(player)
        if player == game.Players.LocalPlayer then return end
        
        -- Удаляем старые соединения, если они есть
        if module.playerConnections[player] then
            for _, conn in pairs(module.playerConnections[player]) do
                conn:Disconnect()
            end
            module.playerConnections[player] = nil
        end
        
        module.playerConnections[player] = {}
        
        -- Добавляем новые соединения
        table.insert(module.playerConnections[player], player.CharacterAdded:Connect(function()
            repeat task.wait() until player.Character and player.Character:FindFirstChild("Humanoid")
            applyChams(player)
        end))
        
        table.insert(module.playerConnections[player], player:GetPropertyChangedSignal("Team"):Connect(function()
            applyChams(player)
        end))
        
        if player.Character then
            applyChams(player)
        end
    end

    local function init()
        -- Настройка автообновления
        if module.refreshConnection then
            module.refreshConnection:Disconnect()
        end
        
        module.refreshConnection = game:GetService("RunService").Heartbeat:Connect(function()
            refreshAllPlayers()
        end)
        
        -- Настройка игроков
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            setupPlayer(player)
        end
        
        game:GetService("Players").PlayerAdded:Connect(setupPlayer)
        
        game:GetService("Players").PlayerRemoving:Connect(function(player)
            if module.playerConnections[player] then
                for _, conn in pairs(module.playerConnections[player]) do
                    conn:Disconnect()
                end
                module.playerConnections[player] = nil
            end
        end)
    end

    local function Enable()
        if module.enabled then return end
        module.enabled = true
        init()
        refreshAllPlayers()
    end

    local function Disable()
        if not module.enabled then return end
        module.enabled = false
        
        if module.refreshConnection then
            module.refreshConnection:Disconnect()
            module.refreshConnection = nil
        end
        
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character then
                local highlight = player.Character:FindFirstChildOfClass("Highlight")
                if highlight then
                    highlight.Enabled = false
                end
            end
        end
    end

    return {
        Toggle = function(state)
            if state then
                Enable()
            else
                Disable()
            end
        end,
        SetTeamBased = function(state)
            module.teamBased = state
            refreshAllPlayers()
        end,
        enabled = module.enabled
    }
end

return ChamsModule()
