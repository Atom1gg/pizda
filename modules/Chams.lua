local function ChamsModule()
    local module = {
        enabled = false,
        teamBased = true,
        refreshInterval = 1,
        teamColors = {
            ["Terrorists"] = Color3.fromRGB(255, 200, 0),
            ["Counter-Terrorists"] = Color3.fromRGB(0, 150, 255),
            defaultEnemy = Color3.fromRGB(255, 0, 0)
        },
        outlineColor = Color3.fromRGB(255, 255, 255),
        fillTransparency = 0.8,
        refreshConnection = nil,
        playerConnections = {}
    }

    local function applyChams(player)
        if not player or not player.Character then return end
        
        local highlight = player.Character:FindFirstChildOfClass("Highlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Parent = player.Character
        end
        
        highlight.OutlineColor = module.outlineColor
        highlight.FillColor = module.teamBased and 
                            (player.Team and module.teamColors[player.Team.Name] or module.teamColors.defaultEnemy) or 
                            module.teamColors.defaultEnemy
        highlight.FillTransparency = module.fillTransparency
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = module.enabled -- Важно: используем текущее состояние
    end

    local function refreshAllPlayers()
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                applyChams(player)
            end
        end
    end

    local function setupPlayer(player)
        if player == game.Players.LocalPlayer then return end
        
        if module.playerConnections[player] then
            for _, conn in pairs(module.playerConnections[player]) do
                conn:Disconnect()
            end
        end
        
        module.playerConnections[player] = {
            player.CharacterAdded:Connect(function(character)
                repeat task.wait() until character:FindFirstChild("Humanoid")
                applyChams(player)
            end),
            player:GetPropertyChangedSignal("Team"):Connect(function()
                applyChams(player)
            end)
        }
        
        if player.Character then
            applyChams(player)
        end
    end

    local function init()
        if module.refreshConnection then
            module.refreshConnection:Disconnect()
        end
        
        module.refreshConnection = game:GetService("RunService").Heartbeat:Connect(function()
            refreshAllPlayers()
        end)
        
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            setupPlayer(player)
        end
    end

    local function cleanup()
        if module.refreshConnection then
            module.refreshConnection:Disconnect()
            module.refreshConnection = nil
        end
        
        for player, connections in pairs(module.playerConnections) do
            for _, conn in pairs(connections) do
                conn:Disconnect()
            end
        end
        module.playerConnections = {}
        
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            if player.Character then
                local highlight = player.Character:FindFirstChildOfClass("Highlight")
                if highlight then
                    highlight.Enabled = false
                end
            end
        end
    end

    return {
        Toggle = function(state)
            if state == module.enabled then return end
            
            module.enabled = state
            if state then
                init()
            else
                cleanup()
            end
        end,
        SetTeamBased = function(state)
            module.teamBased = state
            if module.enabled then
                refreshAllPlayers()
            end
        end,
        SetTransparency = function(value)
            module.fillTransparency = value
            if module.enabled then
                refreshAllPlayers()
            end
        end,
        enabled = function() return module.enabled end
    }
end

return ChamsModule()
