-- Umbrella UI Library (Full) — with integrated toggle-bind & per-player save
-- Base: user's 123.txt (kept full), changes are annotated with ">>> CHANGED" comments.

local player = game:GetService("Players").LocalPlayer
local existingUI = player.PlayerGui:FindFirstChild("MyUI")
if existingUI then
    existingUI:Destroy()
end

local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

_G.mainFrame = nil
_G.isGUIVisible = false
_G.keySystemPassed = false

local activeCategoryLabel
local moduleNameLabel
local slashLabel
local openDropdowns = {}

-- Style
local ACCENT_COLOR = Color3.fromRGB(255, 75, 75)
local TEXT_COLOR   = Color3.fromRGB(200, 200, 200)
local BG_COLOR     = Color3.fromRGB(20, 20, 22)
local DARK_BG      = Color3.fromRGB(15, 15, 17)
local ELEMENT_COLOR= Color3.fromRGB(30, 30, 32)

-- >>> CHANGED: added savedKeybinds; everything else preserved
local API = {
    modules = {},
    settings = {},
    callbacks = {},
    savedSettings = {},
    savedModuleStates = {},
    savedKeybinds = {} -- [moduleName] = "KeyCodeName"
}

-- >>> CHANGED: per-player save path helpers
local function getSaveFolder()
    local folder = "UmbrellaHub"
    if not isfolder or not createfolder then
        return folder -- fallback if env has only writefile
    end
    if not isfolder(folder) then
        pcall(function() createfolder(folder) end)
    end
    return folder
end

local function getSavePath()
    local folder = getSaveFolder()
    local nick = tostring(player and player.Name or "Player")
    local filename = "Umbrella_" .. nick .. ".json"
    return folder .. "/" .. filename
end

local function closeAllDropdowns(except)
    for _, dropdown in pairs(openDropdowns) do
        if dropdown ~= except and dropdown.Close then
            dropdown:Close()
        end
    end
    openDropdowns = {}
    if except then
        table.insert(openDropdowns, except)
    end
end

-- =======================
-- Saving / Loading
-- =======================
local function saveSettings()
    local success, err = pcall(function()
        local dataToSave = {
            settings      = API.savedSettings,
            moduleStates  = API.savedModuleStates,
            keybinds      = API.savedKeybinds  -- >>> CHANGED
        }
        local path = getSavePath()            -- >>> CHANGED
        writefile(path, HttpService:JSONEncode(dataToSave))
    end)
    if not success then
        warn("Failed to save settings:", err)
    end
end

local function loadSettings()
    local success, result = pcall(function()
        local path = getSavePath()            -- >>> CHANGED
        if isfile and isfile(path) then
            return HttpService:JSONDecode(readfile(path))
        end
        return {}
    end)
    if success and result then
        API.savedSettings     = result.settings or {}
        API.savedModuleStates = result.moduleStates or {}
        API.savedKeybinds     = result.keybinds or {} -- >>> CHANGED
    else
        warn("Failed to load settings:", result)
        API.savedSettings, API.savedModuleStates, API.savedKeybinds = {}, {}, {} -- >>> CHANGED
    end
end

loadSettings()

-- =======================
-- Notifications
-- =======================
local notificationsGui = Instance.new("ScreenGui")
notificationsGui.Name = "UmbrellaNotifications"
notificationsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notificationsGui.Parent = player:WaitForChild("PlayerGui")

local notificationsFrame = Instance.new("Frame")
notificationsFrame.Size = UDim2.new(0, 300, 0, 200)
notificationsFrame.Position = UDim2.new(0.5, -150, 0.1, 0)
notificationsFrame.BackgroundTransparency = 1
notificationsFrame.Parent = notificationsGui

local notificationsLayout = Instance.new("UIListLayout")
notificationsLayout.Padding = UDim.new(0, 10)
notificationsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
notificationsLayout.Parent = notificationsFrame

local activeNotifications = 0
local maxNotifications = 3

local function showNotification(text, color, duration)
    if activeNotifications >= maxNotifications then return end
    
    activeNotifications += 1
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 280, 0, 40)
    notification.BackgroundColor3 = ELEMENT_COLOR
    notification.BackgroundTransparency = 1
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = notification
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -10)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.Text = text
    label.TextColor3 = color or TEXT_COLOR
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 14
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = notification
    
    notification.Parent = notificationsFrame
    
    local tweenIn = TweenService:Create(notification, TweenInfo.new(0.3), {BackgroundTransparency = 0})
    tweenIn:Play()
    
    task.delay(duration or 3, function()
        local tweenOut = TweenService:Create(notification, TweenInfo.new(0.3), {BackgroundTransparency = 1})
        tweenOut:Play()
        tweenOut.Completed:Wait()
        notification:Destroy()
        activeNotifications -= 1
    end)
end

-- =======================
-- Key System (kept)
-- =======================
local function createKeySystem()
    local gui = Instance.new("ScreenGui")
    gui.Name = "PremiumLoader"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 240, 0, 140)
    mainFrame.Position = UDim2.new(0.5, -120, 0.5, -70)
    mainFrame.BackgroundColor3 = DARK_BG
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    local icon = Instance.new("ImageLabel")
    icon.Name = "LoaderIcon"
    icon.Image = "http://www.roblox.com/asset/?id=95285379105237"
    icon.Size = UDim2.new(0, 70, 0, 70)
    icon.Position = UDim2.new(0.5, -5, 0.3, 0)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.BackgroundTransparency = 1
    icon.Parent = mainFrame

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(0.8, 0, 0, 5)
    progressBar.Position = UDim2.new(0.1, 0, 0.65, 0)
    progressBar.BackgroundColor3 = ELEMENT_COLOR
    progressBar.Parent = mainFrame

    local progressCorner = Instance.new("UICorner")
    progressCorner.CornerRadius = UDim.new(0, 3)
    progressCorner.Parent = progressBar

    local progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = ACCENT_COLOR
    progressFill.Parent = progressBar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = progressFill

    local keyInput = Instance.new("TextBox")
    keyInput.Size = UDim2.new(0.8, 0, 0, 40)
    keyInput.Position = UDim2.new(0.1, 0, 0.55, -12)
    keyInput.BackgroundColor3 = ELEMENT_COLOR
    keyInput.TextColor3 = TEXT_COLOR
    keyInput.Text = ""
    keyInput.PlaceholderText = "Enter access key..."
    keyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    keyInput.Font = Enum.Font.Gotham
    keyInput.TextSize = 14
    keyInput.Visible = false
    keyInput.Parent = mainFrame

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = keyInput

    local function createButton(name, posX)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.35, 0, 0, 36)
        btn.Position = UDim2.new(posX, 0, 0.8, -15)
        btn.Text = name
        btn.TextColor3 = name == "Confirm" and Color3.new(1,1,1) or ACCENT_COLOR
        btn.BackgroundColor3 = name == "Confirm" and ACCENT_COLOR or ELEMENT_COLOR
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.AutoButtonColor = false
        btn.Visible = false
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.Parent = mainFrame
        return btn
    end

    local btnGetKey = createButton("Get key", 0.1)
    local btnConfirm = createButton("Confirm", 0.55)

    local currentTween = nil
    local isAnimating = false

    local function spinIcon(direction, callback)
        if currentTween then
            currentTween:Cancel()
        end
        local rot = direction == "left" and 360 or -360
        currentTween = TweenService:Create(icon, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Rotation = rot})
        currentTween:Play()
        if callback then
            currentTween.Completed:Connect(callback)
        end
    end

    local function startIconLoop()
        if isAnimating then return end
        isAnimating = true
        coroutine.wrap(function()
            while isAnimating do
                spinIcon("left")
                task.wait(2)
                if not isAnimating then break end
                spinIcon("right") 
                task.wait(2)
            end
        end)()
    end

    local function stopIconLoop()
        isAnimating = false
        if currentTween then currentTween:Cancel() end
    end

    coroutine.wrap(function()
        local fillTween = TweenService:Create(progressFill, TweenInfo.new(2, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)})
        fillTween:Play()
        
        spinIcon("left", function()
            spinIcon("right", function()
                local expandTween = TweenService:Create(mainFrame, TweenInfo.new(0.5), {Size = UDim2.new(0, 240, 0, 220)})
                expandTween:Play()
                expandTween.Completed:Wait()
                
                local hideProgress = TweenService:Create(progressBar, TweenInfo.new(0.3), {BackgroundTransparency = 1})
                local hideFill = TweenService:Create(progressFill, TweenInfo.new(0.3), {BackgroundTransparency = 1})
                hideProgress:Play(); hideFill:Play(); hideProgress.Completed:Wait()
                
                keyInput.Visible = true
                btnGetKey.Visible = true
                btnConfirm.Visible = true
                
                TweenService:Create(keyInput,  TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
                TweenService:Create(btnGetKey,  TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
                TweenService:Create(btnConfirm, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
                
                task.wait(0.5)
                startIconLoop()
            end)
        end)
    end)()

    btnGetKey.MouseEnter:Connect(function() 
        TweenService:Create(btnGetKey, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45,45,47)}):Play()
    end)
    btnGetKey.MouseLeave:Connect(function() 
        TweenService:Create(btnGetKey, TweenInfo.new(0.2), {BackgroundColor3 = ELEMENT_COLOR}):Play()
    end)
    btnGetKey.MouseButton1Click:Connect(function()
        setclipboard("https://discord.gg/hjXQM4X3vq")
        showNotification("Discord link copied to clipboard!", Color3.fromRGB(100, 255, 100))
    end)

    btnConfirm.MouseEnter:Connect(function() 
        TweenService:Create(btnConfirm, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 90, 90)}):Play()
    end)
    btnConfirm.MouseLeave:Connect(function() 
        TweenService:Create(btnConfirm, TweenInfo.new(0.2), {BackgroundColor3 = ACCENT_COLOR}):Play()
    end)
    btnConfirm.MouseButton1Click:Connect(function()
        if keyInput.Text == "UmbrellaHub2025" then
            showNotification("Access granted! Loading...", Color3.fromRGB(100, 255, 100))
            task.wait(1)
            TweenService:Create(mainFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
            for _, child in pairs(mainFrame:GetChildren()) do
                if child:IsA("GuiObject") then
                    TweenService:Create(child, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
                    if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                        TweenService:Create(child, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
                    elseif child:IsA("ImageLabel") then
                        TweenService:Create(child, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
                    end
                end
            end
            task.wait(0.5)
            stopIconLoop()
            mainFrame:Destroy()
            task.wait(2.5)
            if gui and gui.Parent then gui:Destroy() end
            _G.keySystemPassed = true
            createMainUI()
        else
            showNotification("Invalid key! Try again.", ACCENT_COLOR)
            keyInput.Text = ""
        end
    end)

    gui.AncestryChanged:Connect(function()
        if not gui.Parent then stopIconLoop() end
    end)
end

-- =======================
-- Registering modules/settings
-- =======================

-- >>> CHANGED: helper to apply module state + callbacks + optional UI refresh
local function applyModuleState(moduleName, enabled, fromBind)
    API.savedModuleStates[moduleName] = enabled
    saveSettings()

    -- propagate to actual module object
    for category, modules in pairs(API.modules) do
        for _, module in ipairs(modules) do
            if module.name == moduleName then
                module.enabled = enabled
                if module.callback then
                    pcall(module.callback, enabled)
                end
                -- callbacks map (optional)
                local cbs = API.callbacks[moduleName]
                if cbs then
                    if enabled and cbs.onEnable then pcall(cbs.onEnable) end
                    if (not enabled) and cbs.onDisable then pcall(cbs.onDisable) end
                end
            end
        end
    end

    local msg = ("%s: %s"):format(moduleName, enabled and "Enabled" or "Disabled")
    if fromBind then
        showNotification(msg, enabled and Color3.fromRGB(100,255,100) or ACCENT_COLOR, 2.5)
    end
end

-- >>> CHANGED: single place to save keybind
local function saveModuleBind(moduleName, keyName)
    API.savedKeybinds[moduleName] = keyName
    saveSettings()
end

function API:registerModule(category, moduleData)
    self.modules[category] = self.modules[category] or {}

    -- >>> CHANGED: autorun setting table if absent, inject Enabled toggle WITH integrated bind
    if not self.settings[moduleData.name] then
        local defaultEnabled = moduleData.enabled or false
        local defaultBind = (API.savedKeybinds[moduleData.name]) or "None"

        self.settings[moduleData.name] = {
            settings = {
                {
                    name = "Enabled",
                    type = "toggle",
                    default = defaultEnabled,
                    hasBind = true,         -- <<< flag for integrated bind UI
                    bindName = "Bind",      -- label inside pill
                    defaultBind = defaultBind,
                    callback = function(value)
                        applyModuleState(moduleData.name, value, false)
                    end,
                    onBindChanged = function(keyName)
                        saveModuleBind(moduleData.name, keyName)
                    end
                }
            }
        }
    end

    table.insert(self.modules[category], moduleData)

    -- load saved state (if exists) and auto-apply
    if self.savedModuleStates[moduleData.name] ~= nil then
        moduleData.enabled = self.savedModuleStates[moduleData.name]
        if moduleData.enabled and moduleData.callback then
            pcall(moduleData.callback, true)
        end
    end
end

function API:registerSettings(moduleName, settingsTable)
    self.settings[moduleName] = {settings = settingsTable}
    if API.savedSettings[moduleName] then
        for _, setting in ipairs(settingsTable) do
            if API.savedSettings[moduleName][setting.name] ~= nil then
                setting.default = API.savedSettings[moduleName][setting.name]
                if setting.callback then
                    pcall(setting.callback, setting.default)
                end
            end
        end
    end
end

local moduleSystem = {
    activeCategory = nil,
    activeModule = nil,
    activeModuleName = nil,
    modules = API.modules
}

local moduleSettings = API.settings

-- =======================
-- Tween helpers
-- =======================
local function tweenColor(object, property, targetColor, duration)
    local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, tweenInfo, {[property] = targetColor})
    tween:Play()
    return tween
end

local function tweenTransparency(object, property, targetValue, duration)
    local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, tweenInfo, {[property] = targetValue})
    tween:Play()
    return tween
end

local function tweenSize(object, property, targetSize, duration)
    local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, tweenInfo, {[property] = targetSize})
    tween:Play()
    return tween
end

local function clearSettingsContainer()
    local settingsContainer = _G.mainFrame:FindFirstChild("SettingsContainer")
    if settingsContainer then
        for _, child in pairs(settingsContainer:GetChildren()) do
            if not child:IsA("UICorner") then
                child:Destroy()
            end
        end
        settingsContainer.BackgroundTransparency = 1
        settingsContainer.Size = UDim2.new(0, 615, 0, 0)
    end
end

local function createScrollableContainer(parent, size, position, padding)
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = size
    scrollFrame.Position = position
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 0
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = parent
    
    local scrollBar = Instance.new("Frame")
    scrollBar.Size = UDim2.new(0, 4, 1, 0)
    scrollBar.Position = UDim2.new(1, -4, 0, 0)
    scrollBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    scrollBar.BorderSizePixel = 0
    scrollBar.Transparency = 1
    scrollBar.Parent = scrollFrame
    
    local scrollBarCorner = Instance.new("UICorner")
    scrollBarCorner.CornerRadius = UDim.new(1, 0)
    scrollBarCorner.Parent = scrollBar
    
    local scrollBarFill = Instance.new("Frame")
    scrollBarFill.Size = UDim2.new(1, 0, 0, 0)
    scrollBarFill.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    scrollBarFill.BorderSizePixel = 0
    scrollBarFill.Parent = scrollBar
    
    local scrollBarFillCorner = Instance.new("UICorner")
    scrollBarFillCorner.CornerRadius = UDim.new(1, 0)
    scrollBarFillCorner.Parent = scrollBarFill
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = scrollFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = padding
    layout.Parent = container
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
        local visibleRatio = scrollFrame.AbsoluteWindowSize.Y / math.max(1, scrollFrame.CanvasSize.Y.Offset)
        scrollBarFill.Size = UDim2.new(1, 0, visibleRatio, 0)
    end)
    
    scrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local denom = (scrollFrame.CanvasSize.Y.Offset - scrollFrame.AbsoluteWindowSize.Y)
        local positionRatio = denom > 0 and (scrollFrame.CanvasPosition.Y / denom) or 0
        scrollBarFill.Position = UDim2.new(0, 0, positionRatio * (1 - scrollBarFill.Size.Y.Scale), 0)
    end)
    
    scrollFrame.MouseEnter:Connect(function()
        tweenTransparency(scrollBar, "Transparency", 0.5)
    end)
    scrollFrame.MouseLeave:Connect(function()
        tweenTransparency(scrollBar, "Transparency", 1)
    end)
    
    return scrollFrame, container
end

-- =======================
-- Setting elements
-- =======================

local function createDropDown(parent, setting, position)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 50)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Text = setting.name
    label.TextColor3 = Color3.fromRGB(142, 142, 142)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 22
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = frame

    local dropDownButton = Instance.new("TextButton")
    dropDownButton.Size = UDim2.new(0, 120, 0, 30)
    dropDownButton.Position = UDim2.new(0.6, 10, 0.5, -15)
    dropDownButton.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    dropDownButton.BorderSizePixel = 0
    dropDownButton.AutoButtonColor = false
    dropDownButton.Text = ""
    dropDownButton.Parent = frame

    local dropDownCorner = Instance.new("UICorner")
    dropDownCorner.CornerRadius = UDim.new(0, 4)
    dropDownCorner.Parent = dropDownButton

    local selectedText = Instance.new("TextLabel")
    selectedText.Size = UDim2.new(1, -10, 1, 0)
    selectedText.Position = UDim2.new(0, 5, 0, 0)
    selectedText.BackgroundTransparency = 1
    selectedText.Text = setting.default or "Select..."
    selectedText.TextColor3 = Color3.fromRGB(200, 200, 200)
    selectedText.Font = Enum.Font.SourceSans
    selectedText.TextSize = 18
    selectedText.TextXAlignment = Enum.TextXAlignment.Left
    selectedText.TextTruncate = Enum.TextTruncate.AtEnd
    selectedText.Parent = dropDownButton

    local dropDownMenu = Instance.new("Frame")
    dropDownMenu.Size = UDim2.new(0, 0, 0, 0)
    dropDownMenu.AnchorPoint = Vector2.new(0.5, 0.5)
    dropDownMenu.Position = UDim2.new(0.5, 0, 0.5, 0)
    dropDownMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    dropDownMenu.BorderSizePixel = 0
    dropDownMenu.ClipsDescendants = true
    dropDownMenu.Visible = false
    dropDownMenu.ZIndex = 100
    dropDownMenu.Parent = dropDownButton

    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 6)
    menuCorner.Parent = dropDownMenu

    local menuLayout = Instance.new("UIListLayout")
    menuLayout.Padding = UDim.new(0, 5)
    menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    menuLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    menuLayout.Parent = dropDownMenu

    local isOpen = false

    local function updateMenu()
        for _, child in ipairs(dropDownMenu:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, option in ipairs(setting.options) do
            local optionButton = Instance.new("TextButton")
            optionButton.Size = UDim2.new(1, -10, 0, 30)
            optionButton.BackgroundColor3 = Color3.fromRGB(30, 30, 32)
            optionButton.BorderSizePixel = 0
            optionButton.AutoButtonColor = true
            optionButton.Text = option
            optionButton.Font = Enum.Font.SourceSans
            optionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
            optionButton.TextSize = 18
            optionButton.Parent = dropDownMenu

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = optionButton

            optionButton.MouseButton1Click:Connect(function()
                selectedText.Text = option
                API.savedSettings[setting.moduleName] = API.savedSettings[setting.moduleName] or {}
                API.savedSettings[setting.moduleName][setting.name] = option
                saveSettings()
                if setting.callback then setting.callback(option) end
                frame:Close()
            end)
        end
    end

    function frame:Close()
        if isOpen then
            isOpen = false
            TweenService:Create(dropDownMenu, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 0, 0, 0)
            }):Play()
            task.delay(0.25, function() dropDownMenu.Visible = false end)
        end
    end

    local function toggleMenu()
        isOpen = not isOpen
        if isOpen then
            closeAllDropdowns(frame)
            updateMenu()
            dropDownMenu.Visible = true
            TweenService:Create(dropDownMenu, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 150, 0, math.min(#setting.options * 35, 150))
            }):Play()
        else
            frame:Close()
        end
    end

    dropDownButton.MouseButton1Click:Connect(toggleMenu)
    return frame
end

local function createTextField(parent, setting, position)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 50)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Text = setting.name
    label.TextColor3 = Color3.fromRGB(142, 142, 142)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 22
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = frame

    local textBoxBackground = Instance.new("Frame")
    textBoxBackground.Size = UDim2.new(0, 120, 0, 30)
    textBoxBackground.Position = UDim2.new(0.7, 280, 0.5, -15)
    textBoxBackground.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    textBoxBackground.BorderSizePixel = 0
    textBoxBackground.Parent = frame

    local textBoxCorner = Instance.new("UICorner")
    textBoxCorner.CornerRadius = UDim.new(0, 4)
    textBoxCorner.Parent = textBoxBackground

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -10, 1, -4)
    textBox.Position = UDim2.new(0, 5, 0, 2)
    textBox.BackgroundTransparency = 1
    textBox.Text = setting.default or ""
    textBox.TextColor3 = Color3.fromRGB(200, 200, 200)
    textBox.Font = Enum.Font.SourceSans
    textBox.TextSize = 18
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.PlaceholderText = setting.placeholder or ""
    textBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    textBox.Parent = textBoxBackground

    local function updateValue()
        API.savedSettings[setting.moduleName] = API.savedSettings[setting.moduleName] or {}
        API.savedSettings[setting.moduleName][setting.name] = textBox.Text
        saveSettings()
        if setting.callback then setting.callback(textBox.Text) end
    end

    textBox.FocusLost:Connect(function() updateValue() end)
    return frame
end

local function createSlider(parent, setting, position)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 600, 0, 40)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.2, 10)
    label.Position = UDim2.new(0, 10, 0.3, -10)
    label.Text = setting.name
    label.TextColor3 = Color3.fromRGB(142, 142, 142)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 22
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = frame

    local valueDisplay = Instance.new("TextLabel")
    valueDisplay.Size = UDim2.new(1, 0, 0.2, 0)
    valueDisplay.Position = UDim2.new(0, -5, 0.3, -5)
    valueDisplay.Text = tostring(setting.default) .. (setting.isPercentage and "%" or "")
    valueDisplay.TextColor3 = Color3.fromRGB(142, 142, 142)
    valueDisplay.Font = Enum.Font.SourceSans
    valueDisplay.TextSize = 22
    valueDisplay.TextXAlignment = Enum.TextXAlignment.Right
    valueDisplay.BackgroundTransparency = 1
    valueDisplay.Parent = frame

    local sliderBackground = Instance.new("Frame")
    sliderBackground.Size = UDim2.new(1, -11, 0, 6)
    sliderBackground.Position = UDim2.new(0, 10, 0.6, -3)
    sliderBackground.BackgroundColor3 = Color3.fromRGB(142, 142, 142)
    sliderBackground.BorderSizePixel = 0
    sliderBackground.Parent = frame

    local sliderActive = Instance.new("Frame")
    sliderActive.Size = UDim2.new((setting.default - setting.min) / (setting.max - setting.min), 0, 1, 0)
    sliderActive.BackgroundColor3 = ACCENT_COLOR
    sliderActive.BorderSizePixel = 0
    sliderActive.Parent = sliderBackground

    local sliderBackgroundCorner = Instance.new("UICorner")
    sliderBackgroundCorner.CornerRadius = UDim.new(0, 4)
    sliderBackgroundCorner.Parent = sliderBackground

    local sliderActiveCorner = Instance.new("UICorner") 
    sliderActiveCorner.CornerRadius = UDim.new(0, 4)
    sliderActiveCorner.Parent = sliderActive

    local sliderCircle = Instance.new("Frame")
    sliderCircle.Size = UDim2.new(0, 12, 0, 12)
    sliderCircle.Position = UDim2.new((setting.default - setting.min) / (setting.max - setting.min), -6, 0.5, -6)
    sliderCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderCircle.BorderSizePixel = 0
    sliderCircle.Parent = sliderBackground

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = sliderCircle

    local dragging = false
    local debounceTime = 0

    local function updateSlider(value)
        local relativePos = (value - setting.min) / (setting.max - setting.min)
        sliderCircle.Position = UDim2.new(relativePos, -6, 0.5, -6)
        sliderActive.Size = UDim2.new(relativePos, 0, 1, 0)
        valueDisplay.Text = tostring(value) .. (setting.isPercentage and "%" or "")
        
        local currentTime = tick()
        debounceTime = currentTime
        task.delay(0.5, function()
            if debounceTime == currentTime then
                API.savedSettings[setting.moduleName] = API.savedSettings[setting.moduleName] or {}
                API.savedSettings[setting.moduleName][setting.name] = value
                saveSettings()
            end
        end)
        if setting.callback then setting.callback(value) end
    end

    sliderCircle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            sliderCircle:TweenSize(UDim2.new(0, 15, 0, 15), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        end
    end)
    sliderCircle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            sliderCircle:TweenSize(UDim2.new(0, 12, 0, 12), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = input.Position.X
            local sliderStart = sliderBackground.AbsolutePosition.X
            local sliderEnd = sliderStart + sliderBackground.AbsoluteSize.X
            local newX = math.clamp(mousePos, sliderStart, sliderEnd)
            local relativePos = (newX - sliderStart) / sliderBackground.AbsoluteSize.X
            local newValue = math.floor(relativePos * (setting.max - setting.min) + setting.min)
            updateSlider(newValue)
        end
    end)

    updateSlider(setting.default)
    return frame
end

-- >>> CHANGED: Toggle with integrated bind pill (only when setting.hasBind == true)
local function createToggle(parent, setting, position)
    local outerFrame = Instance.new("Frame")
    outerFrame.Size = UDim2.new(0, 280, 0, 50)
    outerFrame.Position = position
    outerFrame.BackgroundTransparency = 1
    outerFrame.BorderSizePixel = 0
    outerFrame.Parent = parent

    local enableLabel = Instance.new("TextLabel")
    enableLabel.Size = UDim2.new(0.6, 0, 1, 0)
    enableLabel.Position = UDim2.new(0, 10, 0, 0)
    enableLabel.Text = setting.name
    enableLabel.TextColor3 = Color3.fromRGB(142, 142, 142)
    enableLabel.Font = Enum.Font.SourceSansBold
    enableLabel.TextSize = 22
    enableLabel.TextXAlignment = Enum.TextXAlignment.Left
    enableLabel.BackgroundTransparency = 1
    enableLabel.Parent = outerFrame

    local switchTrack = Instance.new("Frame")
    switchTrack.Size = UDim2.new(0, 40, 0, 20)
    switchTrack.Position = UDim2.new(0.6, 30, 0.5, -10)
    switchTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    switchTrack.BorderSizePixel = 0
    switchTrack.Parent = outerFrame

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = switchTrack

    local switchCircle = Instance.new("Frame")
    switchCircle.Size = UDim2.new(0, 18, 0, 18)
    switchCircle.Position = UDim2.new(0, 1, 0, 1)
    switchCircle.BackgroundColor3 = Color3.fromRGB(142, 142, 142)
    switchCircle.BorderSizePixel = 0
    switchCircle.Parent = switchTrack

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = switchCircle

    local isEnabled = setting.default == true

    local function paintState()
        if isEnabled then
            switchCircle.Position = UDim2.new(1, -19, 0, 1)
            switchCircle.BackgroundColor3 = ACCENT_COLOR
        else
            switchCircle.Position = UDim2.new(0, 1, 0, 1)
            switchCircle.BackgroundColor3 = Color3.fromRGB(142, 142, 142)
        end
    end
    paintState()

    local function commitEnabled(newValue, fromUi)
        isEnabled = newValue
        paintState()
        API.savedSettings[setting.moduleName] = API.savedSettings[setting.moduleName] or {}
        API.savedSettings[setting.moduleName][setting.name] = isEnabled
        saveSettings()
        if setting.callback then setting.callback(isEnabled) end
        -- >>> CHANGED: keep module state as single source of truth
        applyModuleState(setting.moduleName, isEnabled, false)
    end

    switchTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            commitEnabled(not isEnabled, true)
        end
    end)

    -- >>> CHANGED: Integrated bind pill (only if hasBind)
    if setting.hasBind then
        local pill = Instance.new("TextButton")
        pill.AutoButtonColor = false
        pill.Size = UDim2.new(0, 90, 0, 22)
        pill.Position = UDim2.new(1, 10, 0.5, -11)
        pill.BackgroundColor3 = Color3.fromRGB(20,20,22)
        pill.BorderSizePixel = 0
        pill.Text = ""
        pill.Parent = outerFrame

        local pillCorner = Instance.new("UICorner")
        pillCorner.CornerRadius = UDim.new(1, 0)
        pillCorner.Parent = pill

        local pillLabel = Instance.new("TextLabel")
        pillLabel.Size = UDim2.new(1, -12, 1, 0)
        pillLabel.Position = UDim2.new(0, 6, 0, 0)
        pillLabel.BackgroundTransparency = 1
        local initialKey = setting.defaultBind or "None"
        pillLabel.Text = (setting.bindName or "Bind") .. ": " .. initialKey
        pillLabel.TextColor3 = TEXT_COLOR
        pillLabel.Font = Enum.Font.SourceSans
        pillLabel.TextSize = 18
        pillLabel.TextXAlignment = Enum.TextXAlignment.Left
        pillLabel.Parent = pill

        local listening = false
        local function setKeyName(name)
            pillLabel.Text = (setting.bindName or "Bind") .. ": " .. name
            API.savedKeybinds[setting.moduleName] = name
            saveSettings()
            if setting.onBindChanged then
                pcall(setting.onBindChanged, name)
            end
        end

        pill.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            pillLabel.Text = (setting.bindName or "Bind") .. ": ..."
            local conn; conn = UIS.InputBegan:Connect(function(input, gp)
                if gp then return end
                -- ignore text boxes to avoid stealing typing
                if UIS:GetFocusedTextBox() then return end

                local key = input.KeyCode
                -- Mouse buttons or Unknown -> ignore, except Backspace to clear
                if key == Enum.KeyCode.Unknown then return end

                if key == Enum.KeyCode.Backspace then
                    setKeyName("None")
                else
                    setKeyName(key.Name)
                end
                if conn then conn:Disconnect() end
                listening = false
            end)
        end)
    end

    return outerFrame
end

function API:saveSettings() saveSettings() end

function API:loadSettings()
    loadSettings()
    -- apply saved module states
    for moduleName, enabled in pairs(self.savedModuleStates) do
        for category, modules in pairs(self.modules) do
            for _, module in ipairs(modules) do
                if module.name == moduleName then
                    module.enabled = enabled
                    if enabled and module.callback then pcall(module.callback, true) end
                    break
                end
            end
        end
    end
    -- load other settings
    for moduleName, settings in pairs(self.settings) do
        if self.savedSettings[moduleName] then
            for _, setting in ipairs(settings.settings) do
                local saved = self.savedSettings[moduleName][setting.name]
                if saved ~= nil then
                    setting.default = saved
                    if setting.callback then pcall(setting.callback, saved) end
                end
                -- >>> CHANGED: propagate saved bind to pill label where applicable
                if setting.hasBind then
                    setting.defaultBind = API.savedKeybinds[moduleName] or setting.defaultBind or "None"
                end
            end
        else
            -- still propagate saved bind from keybinds even if no other settings saved
            local cfg = self.settings[moduleName]
            if cfg and cfg.settings then
                for _, st in ipairs(cfg.settings) do
                    if st.hasBind then
                        st.defaultBind = API.savedKeybinds[moduleName] or st.defaultBind or "None"
                    end
                end
            end
        end
    end
end

-- >>> CHANGED: single function used everywhere to flip module (so visuals stay consistent)
local function saveModuleState(moduleName, enabled)
    applyModuleState(moduleName, enabled, false)
end

-- =======================
-- Settings rendering
-- =======================
local function showModuleSettings(moduleName)
    clearSettingsContainer()
    API:loadSettings()
    
    local settingsContainer = _G.mainFrame:FindFirstChild("SettingsContainer")
    if not settingsContainer then return end
    
    local settings = API.settings[moduleName] or moduleSettings[moduleName]
    if not settings or not settings.settings or #settings.settings == 0 then
        return
    end
    
    settingsContainer.BackgroundTransparency = 0
    settingsContainer.Size = UDim2.new(0, 615, 1, -110)
    
    local scrollFrame, container = createScrollableContainer(
        settingsContainer,
        UDim2.new(1, -10, 1, -10),
        UDim2.new(0, 5, 0, 5),
        UDim.new(0, 5)
    )
    
    local yOffset = 0
    for _, setting in ipairs(settings.settings) do
        setting.moduleName = moduleName
        if setting.type == "slider" then
            createSlider(container, setting, UDim2.new(0, 0, 0, yOffset))
            yOffset = yOffset + 15
        elseif setting.type == "toggle" then
            createToggle(container, setting, UDim2.new(0, 0, 0, yOffset))
            yOffset = yOffset + 5
        elseif setting.type == "textfield" then
            createTextField(container, setting, UDim2.new(0, 0, 0, yOffset))
            yOffset = yOffset + 5
        elseif setting.type == "dropdown" then
            createDropDown(container, setting, UDim2.new(0, 0, 0, yOffset))
            yOffset = yOffset + 5
        end
    end
end

-- =======================
-- Module list
-- =======================

-- >>> CHANGED: do NOT toggle module on click; only select & show settings.
local function createModuleButton(parent, moduleData)
    local moduleButton = Instance.new("Frame")
    moduleButton.Size = UDim2.new(1, -20, 0, 40)
    moduleButton.Position = UDim2.new(0, 10, 0, 0)
    moduleButton.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
    moduleButton.BorderSizePixel = 0
    moduleButton.Parent = parent

    local moduleCorner = Instance.new("UICorner")
    moduleCorner.CornerRadius = UDim.new(0, 6)
    moduleCorner.Parent = moduleButton

    local activeLine = Instance.new("Frame")
    activeLine.Size = UDim2.new(0, 2, 0, 0)
    activeLine.Position = UDim2.new(0, 0, 0.5, 0)
    activeLine.AnchorPoint = Vector2.new(0, 0.5)
    activeLine.BackgroundColor3 = ACCENT_COLOR
    activeLine.BorderSizePixel = 0
    activeLine.Transparency = 1
    activeLine.Parent = moduleButton

    local moduleName = Instance.new("TextLabel")
    moduleName.Size = UDim2.new(1, -20, 1, 0)
    moduleName.Position = UDim2.new(0, 10, 0, 0)
    moduleName.BackgroundTransparency = 1
    moduleName.Text = moduleData.name
    moduleName.TextColor3 = Color3.fromRGB(150, 153, 163)
    moduleName.TextXAlignment = Enum.TextXAlignment.Left
    moduleName.Font = Enum.Font.Gotham
    moduleName.TextSize = 18
    moduleName.Parent = moduleButton

    local textGradient = Instance.new("UIGradient")
    textGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    textGradient.Parent = moduleName

    local clickDetector = Instance.new("TextButton")
    clickDetector.Size = UDim2.new(1, 0, 1, 0)
    clickDetector.Position = UDim2.new(0, 0, 0, 0)
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.ZIndex = 10
    clickDetector.Parent = moduleButton

    local function paintSelected(selected)
        if selected then
            tweenColor(moduleButton, "BackgroundColor3", Color3.fromRGB(22, 28, 30))
            tweenColor(moduleName, "TextColor3", ACCENT_COLOR)
            activeLine.Transparency = 0
            tweenSize(activeLine, "Size", UDim2.new(0, 2, 1, -20))
        else
            tweenColor(moduleButton, "BackgroundColor3", Color3.fromRGB(15, 15, 17))
            tweenColor(moduleName, "TextColor3", Color3.fromRGB(150, 153, 163))
            tweenTransparency(activeLine, "Transparency", 1)
            tweenSize(activeLine, "Size", UDim2.new(0, 2, 0, 0))
        end
    end

    clickDetector.MouseEnter:Connect(function()
        if moduleSystem.activeModuleName ~= moduleData.name then
            tweenColor(moduleButton, "BackgroundColor3", Color3.fromRGB(20, 20, 22), 0.15)
            tweenColor(moduleName, "TextColor3", Color3.fromRGB(180, 183, 193), 0.15)
        end
    end)
    clickDetector.MouseLeave:Connect(function()
        if moduleSystem.activeModuleName ~= moduleData.name then
            tweenColor(moduleButton, "BackgroundColor3", Color3.fromRGB(15, 15, 17), 0.15)
            tweenColor(moduleName, "TextColor3", Color3.fromRGB(150, 153, 163), 0.15)
        end
    end)

    clickDetector.MouseButton1Click:Connect(function()
        -- deselect others
        for _, otherButton in pairs(parent:GetChildren()) do
            if otherButton:IsA("Frame") and otherButton ~= moduleButton then
                local otherLine = otherButton:FindFirstChild("Frame")
                local otherText = otherButton:FindFirstChild("TextLabel")
                if otherLine then 
                    tweenTransparency(otherLine, "Transparency", 1)
                    tweenSize(otherLine, "Size", UDim2.new(0, 2, 0, 0))
                end
                if otherText then 
                    tweenColor(otherText, "TextColor3", Color3.fromRGB(150, 153, 163)) 
                end
                tweenColor(otherButton, "BackgroundColor3", Color3.fromRGB(15, 15, 17))
            end
        end

        -- select this one (no state toggle)
        moduleSystem.activeModuleName = moduleData.name
        slashLabel.Visible = true
        moduleNameLabel.Text = moduleData.name
        tweenColor(moduleNameLabel, "TextColor3", ACCENT_COLOR)
        paintSelected(true)
        showModuleSettings(moduleData.name)
    end)

    -- keep visual "enabled highlight" for already-enabled module when list renders
    if moduleData.name == moduleSystem.activeModuleName then
        paintSelected(true)
    end

    return moduleButton
end

local function updateModuleList(moduleFrame, categoryName)
    for _, child in pairs(moduleFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end

    local categoryModules = API.modules[categoryName] or moduleSystem.modules[categoryName]
    if categoryModules then
        for index, moduleData in ipairs(categoryModules) do
            local moduleButton = createModuleButton(moduleFrame, moduleData)
            moduleButton:SetAttribute("ModuleIndex", index)
            moduleButton.Parent = moduleFrame
        end
    end
end

-- =======================
-- GUI toggle
-- =======================
local function toggleGUI()
    if not _G.keySystemPassed or not _G.mainFrame then return end
    _G.isGUIVisible = not _G.isGUIVisible
    if _G.isGUIVisible then
        _G.mainFrame.Visible = true
        TweenService:Create(_G.mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 900, 0, 600),
            Position = UDim2.new(0.5, -450, 0.5, -300)
        }):Play()
    else
        TweenService:Create(_G.mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        task.wait(0.3)
        _G.mainFrame.Visible = false
        showNotification("Press Left Alt to open GUI", Color3.fromRGB(100, 255, 100), 2)
    end
end

local function createToggleButton()
    if not _G.keySystemPassed then return end
    
    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "UmbrellaToggle"
    toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    toggleGui.Parent = player:WaitForChild("PlayerGui")
    
    local toggleButton = Instance.new("ImageButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 50, 0, 50)
    toggleButton.Position = UDim2.new(0, 20, 0, 20)
    toggleButton.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
    toggleButton.Image = "http://www.roblox.com/asset/?id=95285379105237"
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = toggleGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toggleButton
    
    toggleButton.MouseEnter:Connect(function()
        TweenService:Create(toggleButton, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 55, 0, 55),
            BackgroundColor3 = Color3.fromRGB(22, 28, 30)
        }):Play()
    end)
    toggleButton.MouseLeave:Connect(function()
        TweenService:Create(toggleButton, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 50, 0, 50),
            BackgroundColor3 = Color3.fromRGB(15, 15, 17)
        }):Play()
    end)
    toggleButton.MouseButton1Click:Connect(function() toggleGUI() end)

    -- drag
    local dragging, dragStart, startPos = false, nil, nil
    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = toggleButton.Position
        end
    end)
    toggleButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            toggleButton.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- open GUI with LeftAlt
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        toggleGUI()
    end
end)

-- =======================
-- Main UI (kept)
-- =======================
function createMainUI()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MyUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = mainFrame

    local dragging = false
    local dragStart
    local startPos

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 60)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundTransparency = 1
    topBar.Parent = mainFrame

    local function updateDrag(input)
        local delta = input.Position - dragStart
        local position = UDim2.new(
            startPos.X.Scale,
            math.floor(startPos.X.Offset + delta.X),
            startPos.Y.Scale,
            math.floor(startPos.Y.Offset + delta.Y)
        )
        TweenService:Create(mainFrame, TweenInfo.new(0.1), {Position = position}):Play()
    end

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            local connection
            connection = UIS.InputEnded:Connect(function(inputEnd)
                if inputEnd.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateDrag(input)
        end
    end)
    
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Size = UDim2.new(0, 75, 1, -6)
    categoryFrame.Position = UDim2.new(0, 3, 0, 3)
    categoryFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
    categoryFrame.BorderSizePixel = 0
    categoryFrame.Parent = mainFrame

    local categoryList = Instance.new("ScrollingFrame")
    categoryList.Size = UDim2.new(1, 0, 1, 0)
    categoryList.Position = UDim2.new(0, 12, 0, 100)
    categoryList.BackgroundTransparency = 1
    categoryList.ScrollBarThickness = 0
    categoryList.CanvasSize = UDim2.new(0, 0, 0, 500)
    categoryList.Parent = categoryFrame

    local categoryLayout = Instance.new("UIListLayout")
    categoryLayout.Padding = UDim.new(0, 30)
    categoryLayout.Parent = categoryList

    local ModuleFrame = Instance.new("Frame")
    ModuleFrame.Size = UDim2.new(0, 150, 1, -6)
    ModuleFrame.Position = UDim2.new(0, 80, 0, 3)
    ModuleFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
    ModuleFrame.BorderSizePixel = 0
    ModuleFrame.Parent = mainFrame

    local moduleList = Instance.new("ScrollingFrame")
    moduleList.Size = UDim2.new(1, 0, 1, -50)
    moduleList.Position = UDim2.new(0, 10, 0, 100)
    moduleList.BackgroundTransparency = 1
    moduleList.ScrollBarThickness = 0
    moduleList.CanvasSize = UDim2.new(0, 0, 0, 500)
    moduleList.Parent = ModuleFrame

    local moduleLayout = Instance.new("UIListLayout")
    moduleLayout.Padding = UDim.new(0, 10)
    moduleLayout.Parent = moduleList

    local activeCategory = nil

    activeCategoryLabel = Instance.new("TextLabel")
    activeCategoryLabel.Size = UDim2.new(0, 300, 0, 50)
    activeCategoryLabel.Position = UDim2.new(0.5, -350, 0.5, -280)
    activeCategoryLabel.BackgroundTransparency = 1
    activeCategoryLabel.Text = ""
    activeCategoryLabel.TextSize = 22
    activeCategoryLabel.Font = Enum.Font.Gotham
    activeCategoryLabel.TextColor3 = Color3.fromRGB(150, 153, 163)
    activeCategoryLabel.TextXAlignment = Enum.TextXAlignment.Left
    activeCategoryLabel.Parent = mainFrame

    slashLabel = Instance.new("TextLabel")
    slashLabel.Size = UDim2.new(0, 20, 0, 50)
    slashLabel.Position = UDim2.new(0.5, -205, 0.5, -280)
    slashLabel.BackgroundTransparency = 1
    slashLabel.Text = "/"
    slashLabel.TextSize = 22
    slashLabel.Font = Enum.Font.Gotham
    slashLabel.TextColor3 = Color3.fromRGB(150, 153, 163)
    slashLabel.TextXAlignment = Enum.TextXAlignment.Left
    slashLabel.Visible = false
    slashLabel.Parent = mainFrame

    moduleNameLabel = Instance.new("TextLabel")
    moduleNameLabel.Size = UDim2.new(0, 300, 0, 50)
    moduleNameLabel.Position = UDim2.new(0.5, -190, 0.5, -280)
    moduleNameLabel.BackgroundTransparency = 1
    moduleNameLabel.Text = ""
    moduleNameLabel.TextSize = 22
    moduleNameLabel.Font = Enum.Font.Gotham
    moduleNameLabel.TextColor3 = ACCENT_COLOR
    moduleNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    moduleNameLabel.Parent = mainFrame

    local UmbrellaIcon = Instance.new("ImageLabel")
    UmbrellaIcon.Size = UDim2.new(0, 50, 0, 50)
    UmbrellaIcon.Position = UDim2.new(0.5, -435, 0.5, -290)
    UmbrellaIcon.BackgroundTransparency = 1
    UmbrellaIcon.Image = "http://www.roblox.com/asset/?id=95285379105237"
    UmbrellaIcon.Parent = mainFrame
    
    local function addCategory(icon, name)
        local categoryButton = Instance.new("Frame")
        categoryButton.Size = UDim2.new(0, 50, 0, 50)
        categoryButton.Position = UDim2.new(0, 5, 0, 5)
        categoryButton.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
        categoryButton.BorderSizePixel = 0
        categoryButton.Parent = categoryList

        local categoryCorner = Instance.new("UICorner")
        categoryCorner.CornerRadius = UDim.new(0, 8)
        categoryCorner.Parent = categoryButton

        local iconImage = Instance.new("ImageLabel")
        iconImage.Size = UDim2.new(0, 30, 0, 30)
        iconImage.Position = UDim2.new(0.5, -15, 0.5, -15)
        iconImage.BackgroundTransparency = 1
        iconImage.Image = icon
        iconImage.ImageColor3 = Color3.fromRGB(150, 150, 150)
        iconImage.Parent = categoryButton

        local redLine = Instance.new("Frame")
        redLine.Size = UDim2.new(0, 2, 0, 0)
        redLine.Position = UDim2.new(0, 0, 0.5, 0)
        redLine.AnchorPoint = Vector2.new(0, 0.5)
        redLine.BackgroundColor3 = ACCENT_COLOR
        redLine.Transparency = 1
        redLine.Parent = categoryButton

        local clickDetector = Instance.new("TextButton")
        clickDetector.Size = UDim2.new(1, 0, 1, 0)
        clickDetector.BackgroundTransparency = 1
        clickDetector.Text = ""
        clickDetector.Parent = categoryButton

        clickDetector.MouseEnter:Connect(function()
            if activeCategory ~= categoryButton then
                tweenColor(iconImage, "ImageColor3", Color3.fromRGB(200, 200, 200), 0.15)
            end
        end)
        clickDetector.MouseLeave:Connect(function()
            if activeCategory ~= categoryButton then
                tweenColor(iconImage, "ImageColor3", Color3.fromRGB(150, 150, 150), 0.15)
            end
        end)

        clickDetector.MouseButton1Click:Connect(function()
            if activeCategory == categoryButton then return end

            if activeCategory then
                local prevIcon = activeCategory:FindFirstChild("ImageLabel")
                local prevLine = activeCategory:FindFirstChild("Frame")
                if prevIcon then tweenColor(prevIcon, "ImageColor3", Color3.fromRGB(150, 150, 150)) end
                if prevLine then
                    tweenTransparency(prevLine, "Transparency", 1)
                    tweenSize(prevLine, "Size", UDim2.new(0, 2, 0, 0))
                end
                tweenColor(activeCategory, "BackgroundColor3", Color3.fromRGB(15, 15, 17))
            end

            activeCategory = categoryButton
            moduleSystem.activeCategory = name

            tweenColor(categoryButton, "BackgroundColor3", Color3.fromRGB(22, 28, 30))
            tweenColor(iconImage, "ImageColor3", ACCENT_COLOR)
            redLine.Transparency = 0
            tweenSize(redLine, "Size", UDim2.new(0, 2, 0, 20))

            activeCategoryLabel.Text = name
            slashLabel.Visible = false
            moduleNameLabel.Text = ""
            clearSettingsContainer()
            updateModuleList(moduleList, name)
        end)
    end

    addCategory("http://www.roblox.com/asset/?id=103577523623326", "Server")
    addCategory("http://www.roblox.com/asset/?id=136613041915472", "World")
    addCategory("http://www.roblox.com/asset/?id=85568792810849", "Player")
    addCategory("http://www.roblox.com/asset/?id=124280107087786", "Utility")
    addCategory("http://www.roblox.com/asset/?id=109730932565942", "Combat")
    
    local settingsContainer = Instance.new("Frame")
    settingsContainer.Name = "SettingsContainer"
    settingsContainer.Size = UDim2.new(0, 615, 0, 0)
    settingsContainer.Position = UDim2.new(0, 257, 0, 90)
    settingsContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
    settingsContainer.BackgroundTransparency = 1
    settingsContainer.Parent = mainFrame

    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 8)
    settingsCorner.Parent = settingsContainer

    _G.mainFrame = mainFrame
    _G.isGUIVisible = true
    
    mainFrame.Visible = true
    TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 900, 0, 600),
        Position = UDim2.new(0.5, -450, 0.5, -300)
    }):Play()
    
    -- Создаем кнопку переключения после создания основного UI
    task.wait(0.5)
    createToggleButton()
end

function API:registerCallback(moduleName, callbacks)
    self.callbacks[moduleName] = callbacks
end

local function init(config)
    if config and config.moduleSystem then
        for k,v in pairs(config.moduleSystem) do
            moduleSystem[k] = v
        end
    end

    if config and config.moduleSettings then
        for k,v in pairs(config.moduleSettings) do
            API.settings[k] = v
            moduleSettings[k] = v
        end
    end

    -- Сначала показываем ключ систему
    if not _G.keySystemPassed then
        createKeySystem()
    else
        -- Если ключ уже пройден, сразу создаем основной UI
        createMainUI()
    end
    
    API:loadSettings()
end

return {
    init = init,
    api = API
}
