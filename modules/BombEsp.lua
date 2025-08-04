local function BombESPModule()
    local module = {
        enabled = false,
        color = Color3.fromRGB(255, 0, 0),
        transparency = 0.5,
        showText = true,
        highlight = nil,
        textLabel = nil
    }

    local function CreateESP(bomb)
        -- Создаем Highlight (Chams эффект)
        local highlight = Instance.new("Highlight")
        highlight.FillColor = module.color
        highlight.FillTransparency = module.transparency
        highlight.OutlineColor = module.color
        highlight.OutlineTransparency = 0
        highlight.Parent = bomb
        
        -- Создаем текст "BOMB"
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.Adornee = bomb
        billboard.Parent = bomb
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.Text = "BOMB"
        text.TextColor3 = Color3.new(1, 1, 1)
        text.TextScaled = true
        text.BackgroundTransparency = 1
        text.Visible = module.showText
        text.Parent = billboard
        
        module.highlight = highlight
        module.textLabel = text
    end

    local function UpdateESP()
        if module.highlight then
            module.highlight.FillColor = module.color
            module.highlight.OutlineColor = module.color
            module.highlight.FillTransparency = module.transparency
        end
        if module.textLabel then
            module.textLabel.Visible = module.showText
        end
    end

    local function Enable()
        if module.enabled then return end
        
        local bomb = workspace:FindFirstChild("C4") or workspace:FindFirstChild("Bomb")
        if bomb then
            CreateESP(bomb)
        end
        
        module.connection = workspace.ChildAdded:Connect(function(child)
            if child.Name == "C4" or child.Name == "Bomb" then
                CreateESP(child)
            end
        end)
        
        module.enabled = true
    end

    local function Disable()
        if not module.enabled then return end
        
        if module.connection then
            module.connection:Disconnect()
        end
        if module.highlight then
            module.highlight:Destroy()
        end
        if module.textLabel then
            module.textLabel:Destroy()
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
        SetColor = function(color)
            module.color = color
            UpdateESP()
        end,
        SetTransparency = function(transparency)
            module.transparency = transparency
            UpdateESP()
        end,
        SetTextVisibility = function(visible)
            module.showText = visible
            UpdateESP()
        end,
        enabled = module.enabled
    }
end
