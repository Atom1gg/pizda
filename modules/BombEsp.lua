local function BombESPModule()
    local module = {
        enabled = false,
        color = Color3.fromRGB(255, 0, 0)
    }

    local function CreateESP(bomb)
        local billboard = Instance.new("BillboardGui", bomb)
        billboard.Size = UDim2.new(4, 0, 6, 0)
        billboard.AlwaysOnTop = true
        
        local frame = Instance.new("Frame", billboard)
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = module.color
        frame.BackgroundTransparency = 0.5
        frame.BorderSizePixel = 0
        
        local text = Instance.new("TextLabel", billboard)
        text.Size = UDim2.new(1, 0, 0.2, 0)
        text.Position = UDim2.new(0, 0, 0, -20)
        text.Text = "BOMB"
        text.TextColor3 = module.color
        text.BackgroundTransparency = 1
        text.TextSize = 14
        
        return billboard
    end

    local function Enable()
        if module.enabled then return end
        
        -- Check existing bomb
        if workspace:FindFirstChild("C4") then
            module.esp = CreateESP(workspace.C4)
        end
        
        -- Listen for new bomb
        module.connection = workspace.ChildAdded:Connect(function(child)
            if child.Name == "C4" then
                module.esp = CreateESP(child)
            end
        end)
        
        module.enabled = true
    end

    local function Disable()
        if not module.enabled then return end
        if module.connection then
            module.connection:Disconnect()
        end
        if module.esp then
            module.esp:Destroy()
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
            if module.esp then
                module.esp.Frame.BackgroundColor3 = color
                module.esp.TextLabel.TextColor3 = color
            end
        end,
        enabled = module.enabled
    }
end

return BombESPModule()