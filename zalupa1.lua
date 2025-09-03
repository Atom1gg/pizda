local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Atom1gg/Umbrella/refs/heads/main/Notify.lua"))()
end)

local player = game:GetService("Players").LocalPlayer
if not player then
    player = game:GetService("Players"):GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = game:GetService("Players").LocalPlayer
end
local existingUI = player.PlayerGui:FindFirstChild("MyUI")
if existingUI then
    existingUI:Destroy()
end

local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

_G.mainFrame = nil
_G.isGUIVisible = false

local activeCategoryLabel
local moduleNameLabel
local slashLabel

-- Настройки стиля для ключ системы
local ACCENT_COLOR = Color3.fromRGB(255, 75, 75)
local TEXT_COLOR = Color3.fromRGB(200, 200, 200)
local BG_COLOR = Color3.fromRGB(20, 20, 22)
local DARK_BG = Color3.fromRGB(15, 15, 17)
local ELEMENT_COLOR = Color3.fromRGB(30, 30, 32)

-- ИСПРАВЛЕНО: Z-Index константы для правильной иерархии
local ZINDEX = {
    BASE = 1000,              -- Базовый Z-Index для UI
    MAIN_FRAME = 1001,        -- Основная рамка
    NOTIFICATIONS = 2000,     -- Нотификации (самые высокие)
    DROPDOWNS = 5000,         -- Выпадающие списки
    TOGGLE_BUTTON = 1800      -- Кнопка переключения
}

local API = {
    modules = {},
    settings = {},
    callbacks = {},
    savedSettings = {},
    savedModuleStates = {},
    isInitialized = false,  -- ДОБАВЛЕНО
    pendingCallbacks = {}   -- ДОБАВЛЕНО
}

-- Система сохранения настроек с папкой пользователя
local function getPlayerDataPath()
    local playerName = player.Name
    return "Umbrella/User_" .. playerName .. ".json"
end

local function saveSettings()
    local success, err = pcall(function()
        local dataToSave = {
            settings = API.savedSettings,
            moduleStates = API.savedModuleStates
        }
        
        if not isfolder("Umbrella") then
            makefolder("Umbrella")
        end
        
        local filePath = getPlayerDataPath()
        writefile(filePath, HttpService:JSONEncode(dataToSave))
    end)
    if not success then
        warn("Failed to save settings:", err)
    end
end

local function applyModuleSettings(moduleName)
    if API.settings[moduleName] and API.savedSettings[moduleName] then
        for _, setting in ipairs(API.settings[moduleName].settings) do
            if setting.name ~= "Enabled" and setting.callback then
                local savedValue = API.savedSettings[moduleName][setting.name]
                if savedValue ~= nil then
                    pcall(setting.callback, savedValue)
                end
            end
        end
    end
end

local function loadSettings()
    local success, result = pcall(function()
        local filePath = getPlayerDataPath()
        if isfile(filePath) then
            return HttpService:JSONDecode(readfile(filePath))
        end
        return {}
    end)
    if success and result then
        API.savedSettings = result.settings or {}
        API.savedModuleStates = result.moduleStates or {}
    else
        warn("Failed to load settings:", result)
        API.savedSettings = {}
        API.savedModuleStates = {}
    end
end

loadSettings()

-- УЛУЧШЕННАЯ СИСТЕМА НОТИФИКАЦИЙ
local notificationsGui = Instance.new("ScreenGui")
notificationsGui.Name = "UmbrellaNotifications"
notificationsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notificationsGui.DisplayOrder = ZINDEX.NOTIFICATIONS -- ИСПРАВЛЕНО: Высокий приоритет отображения
notificationsGui.Parent = player:WaitForChild("PlayerGui")

local notificationsFrame = Instance.new("Frame")
notificationsFrame.Size = UDim2.new(0, 350, 0, 400)
notificationsFrame.Position = UDim2.new(1, -370, 0, 20)
notificationsFrame.BackgroundTransparency = 1
notificationsFrame.ZIndex = ZINDEX.NOTIFICATIONS
notificationsFrame.Parent = notificationsGui

local notificationsLayout = Instance.new("UIListLayout")
notificationsLayout.Padding = UDim.new(0, 8)
notificationsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
notificationsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notificationsLayout.SortOrder = Enum.SortOrder.LayoutOrder
notificationsLayout.Parent = notificationsFrame

local activeNotifications = 0
local maxNotifications = 5

-- УЛУЧШЕННАЯ ФУНКЦИЯ НОТИФИКАЦИЙ
local function showNotification(text, notificationType, duration)
    if activeNotifications >= maxNotifications then return end
    
    activeNotifications += 1
    
    -- Типы нотификаций
    local types = {
        success = {
            color = Color3.fromRGB(46, 204, 113),
            icon = "✓",
            bgColor = Color3.fromRGB(39, 174, 96)
        },
        error = {
            color = Color3.fromRGB(231, 76, 60),
            icon = "✗",
            bgColor = Color3.fromRGB(192, 57, 43)
        },
        warning = {
            color = Color3.fromRGB(241, 196, 15),
            icon = "⚠",
            bgColor = Color3.fromRGB(243, 156, 18)
        },
        info = {
            color = Color3.fromRGB(52, 152, 219),
            icon = "ⓘ",
            bgColor = Color3.fromRGB(41, 128, 185)
        }
    }
    
    local notifType = types[notificationType] or types.info
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 330, 0, 60)
    notification.BackgroundColor3 = Color3.fromRGB(25, 25, 27)
    notification.BackgroundTransparency = 0
    notification.BorderSizePixel = 0
    notification.ZIndex = ZINDEX.NOTIFICATIONS + 1
    notification.LayoutOrder = -tick() -- Новые сверху
    
    -- Градиент фона
    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 37)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 27))
    })
    bgGradient.Rotation = 45
    bgGradient.Parent = notification
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    -- Цветная полоса слева
    local colorBar = Instance.new("Frame")
    colorBar.Size = UDim2.new(0, 4, 1, 0)
    colorBar.Position = UDim2.new(0, 0, 0, 0)
    colorBar.BackgroundColor3 = notifType.color
    colorBar.BorderSizePixel = 0
    colorBar.ZIndex = notification.ZIndex + 1
    colorBar.Parent = notification
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 8)
    barCorner.Parent = colorBar
    
    -- Иконка
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 0, 30)
    iconLabel.Position = UDim2.new(0, 15, 0.5, -15)
    iconLabel.Text = notifType.icon
    iconLabel.TextColor3 = notifType.color
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 24
    iconLabel.BackgroundTransparency = 1
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    iconLabel.ZIndex = notification.ZIndex + 1
    iconLabel.Parent = notification
    
    -- Основной текст
    local mainLabel = Instance.new("TextLabel")
    mainLabel.Size = UDim2.new(1, -60, 0, 25)
    mainLabel.Position = UDim2.new(0, 50, 0, 8)
    mainLabel.Text = text
    mainLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainLabel.Font = Enum.Font.GothamMedium
    mainLabel.TextSize = 14
    mainLabel.BackgroundTransparency = 1
    mainLabel.TextXAlignment = Enum.TextXAlignment.Left
    mainLabel.TextTruncate = Enum.TextTruncate.AtEnd
    mainLabel.ZIndex = notification.ZIndex + 1
    mainLabel.Parent = notification
    
    -- Время
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, -60, 0, 15)
    timeLabel.Position = UDim2.new(0, 50, 0, 35)
    timeLabel.Text = os.date("%H:%M:%S")
    timeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 11
    timeLabel.BackgroundTransparency = 1
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.ZIndex = notification.ZIndex + 1
    timeLabel.Parent = notification
    
    -- Прогресс-бар для времени
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, 0, 0, 2)
    progressBg.Position = UDim2.new(0, 0, 1, -2)
    progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBg.BorderSizePixel = 0
    progressBg.ZIndex = notification.ZIndex + 1
    progressBg.Parent = notification
    
    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BackgroundColor3 = notifType.color
    progressBar.BorderSizePixel = 0
    progressBar.ZIndex = progressBg.ZIndex + 1
    progressBar.Parent = progressBg
    
    notification.Parent = notificationsFrame
    
    -- Анимация появления
    notification.Position = UDim2.new(1, 50, 0, 0)
    notification.BackgroundTransparency = 1
    mainLabel.TextTransparency = 1
    timeLabel.TextTransparency = 1
    iconLabel.TextTransparency = 1
    colorBar.BackgroundTransparency = 1
    progressBg.BackgroundTransparency = 1
    progressBar.BackgroundTransparency = 1
    
    local tweenIn = TweenService:Create(notification, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0
    })
    
    local textTweenIn = TweenService:Create(mainLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {
        TextTransparency = 0
    })
    
    local timeTweenIn = TweenService:Create(timeLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.15), {
        TextTransparency = 0
    })
    
    local iconTweenIn = TweenService:Create(iconLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.05), {
        TextTransparency = 0
    })
    
    local colorTweenIn = TweenService:Create(colorBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.1), {
        BackgroundTransparency = 0
    })
    
    local progBgTweenIn = TweenService:Create(progressBg, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {
        BackgroundTransparency = 0
    })
    
    local progBarTweenIn = TweenService:Create(progressBar, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {
        BackgroundTransparency = 0
    })
    
    tweenIn:Play()
    textTweenIn:Play()
    timeTweenIn:Play()
    iconTweenIn:Play()
    colorTweenIn:Play()
    progBgTweenIn:Play()
    progBarTweenIn:Play()
    
    -- Анимация прогресс-бара
    local progressTween = TweenService:Create(progressBar, TweenInfo.new(duration or 4, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0)
    })
    progressTween:Play()
    
    -- Автоматическое скрытие
    task.delay(duration or 4, function()
        local tweenOut = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 50, 0, 0),
            BackgroundTransparency = 1
        })
        
        local textTweenOut = TweenService:Create(mainLabel, TweenInfo.new(0.2), {TextTransparency = 1})
        local timeTweenOut = TweenService:Create(timeLabel, TweenInfo.new(0.2), {TextTransparency = 1})
        local iconTweenOut = TweenService:Create(iconLabel, TweenInfo.new(0.2), {TextTransparency = 1})
        local colorTweenOut = TweenService:Create(colorBar, TweenInfo.new(0.2), {BackgroundTransparency = 1})
        local progTweenOut = TweenService:Create(progressBg, TweenInfo.new(0.2), {BackgroundTransparency = 1})
        
        tweenOut:Play()
        textTweenOut:Play()
        timeTweenOut:Play()
        iconTweenOut:Play()
        colorTweenOut:Play()
        progTweenOut:Play()
        
        tweenOut.Completed:Wait()
        notification:Destroy()
        activeNotifications -= 1
    end)
end

function API:registerModule(category, moduleData)
    self.modules[category] = self.modules[category] or {}
    table.insert(self.modules[category], moduleData)
    
    if self.savedModuleStates[moduleData.name] ~= nil then
        moduleData.enabled = self.savedModuleStates[moduleData.name]
        if moduleData.enabled and moduleData.callback then
            pcall(moduleData.callback, true)
        end
    end
end

function API:registerSettings(moduleName, settingsTable)
    -- Находим модуль для получения его callback
    local moduleData = nil
    for category, modules in pairs(self.modules) do
        for _, module in ipairs(modules) do
            if module.name == moduleName then
                moduleData = module
                break
            end
        end
        if moduleData then break end
    end
    
    -- Создаем переключатель Enabled с правильным callback
    local enabledToggle = {
        name = "Enabled",
        type = "toggle",
        default = moduleData and moduleData.enabled or false,
        callback = function(value)
            if moduleData then
                moduleData.enabled = value
                self.savedModuleStates[moduleName] = value
                saveSettings()
                if moduleData.callback then
                    pcall(moduleData.callback, value)
                end
            end
        end
    }
    
    -- ИСПРАВЛЕНО: Пользовательские настройки идут первыми
    local allSettings = {}
    for _, setting in ipairs(settingsTable) do
        table.insert(allSettings, setting)
    end
    table.insert(allSettings, enabledToggle) -- Enabled добавляется в конец
    
    self.settings[moduleName] = {settings = allSettings}
    
    -- Загружаем сохраненные значения
    if self.savedSettings[moduleName] then
        for _, setting in ipairs(allSettings) do
            local savedValue = self.savedSettings[moduleName][setting.name]
            if savedValue ~= nil then
                setting.default = savedValue
                
                -- ИСПРАВЛЕНО: Отложенное применение callback'ов
                if setting.callback then
                    if self.isInitialized then
                        pcall(setting.callback, savedValue)
                    else
                        -- Добавляем в очередь для применения после инициализации
                        table.insert(self.pendingCallbacks, function()
                            pcall(setting.callback, savedValue)
                        end)
                    end
                end
            end
        end
    end
    
    -- Загружаем состояние модуля
    if self.savedModuleStates[moduleName] ~= nil then
        enabledToggle.default = self.savedModuleStates[moduleName]
        if moduleData then
            moduleData.enabled = self.savedModuleStates[moduleName]
        end
    end
end

-- ДОБАВЛЕНО: Функция для применения отложенных callback'ов
function API:applyPendingCallbacks()
    self.isInitialized = true
    for _, callback in ipairs(self.pendingCallbacks) do
        callback()
    end
    self.pendingCallbacks = {}
end


local moduleSystem = {
    activeCategory = nil,
    activeModule = nil,
    activeModuleName = nil,
    modules = API.modules
}

local moduleSettings = API.settings

local function tweenColor(object, property, targetColor, duration)
    local tweenInfo = TweenInfo.new(
        duration or 0.2,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, tweenInfo, {[property] = targetColor})
    tween:Play()
    return tween
end

local function tweenTransparency(object, property, targetValue, duration)
    local tweenInfo = TweenInfo.new(
        duration or 0.2,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(object, tweenInfo, {[property] = targetValue})
    tween:Play()
    return tween
end

local function tweenSize(object, property, targetSize, duration)
    local tweenInfo = TweenInfo.new(
        duration or 0.2,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
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
    scrollFrame.ZIndex = parent.ZIndex + 1
    scrollFrame.Parent = parent
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.ZIndex = scrollFrame.ZIndex + 1
    container.Parent = scrollFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = padding
    layout.Parent = container
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
    end)
    
    return scrollFrame, container
end

local function createDropDown(parent, setting, position)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 50)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.ZIndex = 50
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Text = setting.name or "Dropdown"
    label.TextColor3 = Color3.fromRGB(142, 142, 142)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 22
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.ZIndex = frame.ZIndex + 1
    label.Parent = frame

    local dropDownButton = Instance.new("TextButton")
    dropDownButton.Size = UDim2.new(0, 120, 0, 30)
    dropDownButton.Position = UDim2.new(0.6, 310, 0.5, -15)
    dropDownButton.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    dropDownButton.BorderSizePixel = 0
    dropDownButton.AutoButtonColor = false
    dropDownButton.Text = ""
    dropDownButton.ZIndex = frame.ZIndex + 2
    dropDownButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = dropDownButton

    local selectedText = Instance.new("TextLabel")
    selectedText.Size = UDim2.new(1, -10, 1, 0)
    selectedText.Position = UDim2.new(0, 8, 0, 0)
    selectedText.BackgroundTransparency = 1
    selectedText.Text = setting.default or "Select..."
    selectedText.TextColor3 = Color3.fromRGB(200, 200, 200)
    selectedText.Font = Enum.Font.SourceSans
    selectedText.TextSize = 16
    selectedText.TextXAlignment = Enum.TextXAlignment.Center
    selectedText.ZIndex = dropDownButton.ZIndex + 1
    selectedText.Parent = dropDownButton

    -- Dropdown menu - Ð¤ÐžÐ Ð”Ð ÐžÐŸÐ”ÐÐ£ÐÐ
    local dropDownMenu = Instance.new("Frame")
    dropDownMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 22) -- Ð¦Ð’Ð•Ð¢ Ð¤ÐžÐÐ Ð”Ð ÐžÐŸÐ”ÐÐ£ÐÐ
    dropDownMenu.BorderSizePixel = 0
    dropDownMenu.Visible = false
    dropDownMenu.ClipsDescendants = true
    dropDownMenu.ZIndex = 1000000
    dropDownMenu.Parent = player.PlayerGui:FindFirstChild("MyUI")

    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 6)
    menuCorner.Parent = dropDownMenu

    local optionsContainer = Instance.new("Frame")
    optionsContainer.Size = UDim2.new(1, -10, 1, -10)
    optionsContainer.Position = UDim2.new(0, 5, 0, 5)
    optionsContainer.BackgroundTransparency = 1
    optionsContainer.ZIndex = dropDownMenu.ZIndex
    optionsContainer.Parent = dropDownMenu

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = optionsContainer

    local isOpen = false
    local animating = false
    local clickConn = nil

    local function closeMenu()
        if isOpen and not animating then
            animating = true
            isOpen = false

            local buttonPos = dropDownButton.AbsolutePosition
            local buttonSize = dropDownButton.AbsoluteSize
            local center = UDim2.new(0, buttonPos.X + buttonSize.X/2, 0, buttonPos.Y + buttonSize.Y/2)

            local tween = TweenService:Create(dropDownMenu, TweenInfo.new(0.2), {
                Size = UDim2.new(0, 0, 0, 0),
                Position = center
            })
            tween:Play()
            tween.Completed:Connect(function()
                dropDownMenu.Visible = false
                animating = false
                if clickConn then
                    clickConn:Disconnect()
                    clickConn = nil
                end
            end)
        end
    end

    local function openMenu()
        if not isOpen and not animating then
            animating = true
            isOpen = true

            -- ÐžÑ‡Ð¸Ñ‰Ð°ÐµÐ¼ Ð¿Ñ€ÐµÐ´Ñ‹Ð´ÑƒÑ‰Ð¸Ðµ Ð¾Ð¿Ñ†Ð¸Ð¸
            for _, child in ipairs(optionsContainer:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end

            -- Ð¡Ð¾Ð·Ð´Ð°ÐµÐ¼ Ð½Ð¾Ð²Ñ‹Ðµ Ð¾Ð¿Ñ†Ð¸Ð¸
            for _, option in ipairs(setting.options or {}) do
                local optionButton = Instance.new("TextButton")
                optionButton.Size = UDim2.new(1, 0, 0, 28)
                optionButton.BackgroundColor3 = Color3.fromRGB(20, 20, 22) -- Ð¦Ð²ÐµÑ‚ ÐºÐ½Ð¾Ð¿Ð¾Ðº
                optionButton.Text = option
                optionButton.TextColor3 = Color3.fromRGB(200, 200, 200)
                optionButton.Font = Enum.Font.SourceSans
                optionButton.TextSize = 16
                optionButton.AutoButtonColor = false
                optionButton.ZIndex = optionsContainer.ZIndex + 1
                optionButton.Parent = optionsContainer

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 4)
                corner.Parent = optionButton

                -- Ð¥Ð¾Ð²ÐµÑ€ ÑÑ„Ñ„ÐµÐºÑ‚
                optionButton.MouseEnter:Connect(function()
                    if selectedText.Text ~= option then
                        TweenService:Create(optionButton, TweenInfo.new(0.2), {
                            BackgroundColor3 = Color3.fromRGB(30, 30, 32)
                        }):Play()
                    end
                end)

                optionButton.MouseLeave:Connect(function()
                    if selectedText.Text ~= option then
                        TweenService:Create(optionButton, TweenInfo.new(0.2), {
                            BackgroundColor3 = Color3.fromRGB(20, 20, 22)
                        }):Play()
                    end
                end)

                optionButton.MouseButton1Click:Connect(function()
                    selectedText.Text = option
                    selectedText.TextColor3 = Color3.fromRGB(255, 75, 75)
                    
                    if setting.callback then 
                        setting.callback(option) 
                    end
                    
                    if not API.savedSettings[setting.moduleName] then
                        API.savedSettings[setting.moduleName] = {}
                    end
                    API.savedSettings[setting.moduleName][setting.name] = option
                    saveSettings()
                    
                    closeMenu() -- Ð—ÐÐšÐ Ð«Ð’ÐÐ•Ðœ ÐŸÐžÐ¡Ð›Ð• Ð’Ð«Ð‘ÐžÐ Ð
                end)

                if selectedText.Text == option then
                    optionButton.BackgroundColor3 = Color3.fromRGB(22, 28, 30)
                    optionButton.TextColor3 = Color3.fromRGB(255, 75, 75)
                end
            end

            dropDownMenu.Visible = true

            local buttonPos = dropDownButton.AbsolutePosition
            local buttonSize = dropDownButton.AbsoluteSize
            local center = UDim2.new(0, buttonPos.X + buttonSize.X/2, 0, buttonPos.Y + buttonSize.Y/2)

            local targetWidth = 140
            local targetHeight = math.min(#setting.options * 32, 200)

            dropDownMenu.Size = UDim2.new(0, 0, 0, 0)
            dropDownMenu.Position = center

            local targetPos = UDim2.new(0, buttonPos.X + buttonSize.X/2 - targetWidth/2, 0, buttonPos.Y + buttonSize.Y/2 - targetHeight/2)

            local tween = TweenService:Create(dropDownMenu, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, targetWidth, 0, targetHeight),
                Position = targetPos
            })
            tween:Play()
            tween.Completed:Connect(function()
                animating = false
            end)

            -- Ð—Ð°ÐºÑ€Ñ‹Ñ‚Ð¸Ðµ Ð¿Ñ€Ð¸ ÐºÐ»Ð¸ÐºÐµ Ð²Ð½Ðµ
            if clickConn then
                clickConn:Disconnect()
            end
            
            clickConn = UIS.InputBegan:Connect(function(input, gameProcessed)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mousePos = input.Position
                    local menuAbsPos = dropDownMenu.AbsolutePosition
                    local menuAbsSize = dropDownMenu.AbsoluteSize
                    local buttonAbsPos = dropDownButton.AbsolutePosition
                    local buttonAbsSize = dropDownButton.AbsoluteSize
                    
                    local isClickOutsideMenu = not (mousePos.X >= menuAbsPos.X and mousePos.X <= menuAbsPos.X + menuAbsSize.X and
                                                   mousePos.Y >= menuAbsPos.Y and mousePos.Y <= menuAbsPos.Y + menuAbsSize.Y)
                    
                    local isClickOutsideButton = not (mousePos.X >= buttonAbsPos.X and mousePos.X <= buttonAbsPos.X + buttonAbsSize.X and
                                                     mousePos.Y >= buttonAbsPos.Y and mousePos.Y <= buttonAbsPos.Y + buttonAbsSize.Y)
                    
                    if isClickOutsideMenu and isClickOutsideButton then
                        closeMenu()
                    end
                end
            end)
        else
            closeMenu()
        end
    end

    dropDownButton.MouseButton1Click:Connect(openMenu)

    local function updateMenuPosition()
        if isOpen and not animating then
            local buttonPos = dropDownButton.AbsolutePosition
            local buttonSize = dropDownButton.AbsoluteSize
            local targetWidth = 140
            local targetHeight = math.min(#setting.options * 32, 200)
            
            local targetPos = UDim2.new(
                0, buttonPos.X + buttonSize.X/2 - targetWidth/2,
                0, buttonPos.Y + buttonSize.Y/2 - targetHeight/2
            )
            
            dropDownMenu.Position = targetPos
        end
    end

    _G.mainFrame:GetPropertyChangedSignal("Position"):Connect(updateMenuPosition)
    _G.mainFrame:GetPropertyChangedSignal("Size"):Connect(updateMenuPosition)

    return frame
end

local function createButton(parent, setting, position)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 50)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.ZIndex = parent.ZIndex + 1
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
    label.ZIndex = frame.ZIndex + 1
    label.Parent = frame

    local buttonBackground = Instance.new("TextButton")
    buttonBackground.Size = UDim2.new(0, 120, 0, 30)
    buttonBackground.Position = UDim2.new(0.6, 312, 0.5, -15)
    buttonBackground.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
    buttonBackground.BorderSizePixel = 0
    buttonBackground.Text = setting.text or "Click"
    buttonBackground.TextColor3 = Color3.fromRGB(200, 200, 200)
    buttonBackground.Font = Enum.Font.SourceSansBold
    buttonBackground.TextSize = 18
    buttonBackground.AutoButtonColor = false
    buttonBackground.ZIndex = frame.ZIndex + 1
    buttonBackground.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = buttonBackground

    -- Hover эффекты
    buttonBackground.MouseEnter:Connect(function()
        TweenService:Create(buttonBackground, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(30, 30, 32)
        }):Play()
    end)

    buttonBackground.MouseLeave:Connect(function()
        TweenService:Create(buttonBackground, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(20, 20, 22)
        }):Play()
    end)

    -- Нажатие
    buttonBackground.MouseButton1Click:Connect(function()
        if setting.callback then
            setting.callback()
        end
    end)

    return frame
end


local function createTextField(parent, setting, position)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 50)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.ZIndex = parent.ZIndex + 1
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
    label.ZIndex = frame.ZIndex + 1
    label.Parent = frame

    local textBoxBackground = Instance.new("Frame")
    textBoxBackground.Size = UDim2.new(0, 120, 0, 30)
    textBoxBackground.Position = UDim2.new(0.6, 312, 0.5, -15)
    textBoxBackground.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    textBoxBackground.BorderSizePixel = 0
    textBoxBackground.ClipsDescendants = true 
    textBoxBackground.ZIndex = frame.ZIndex + 1
    textBoxBackground.Parent = frame

    local textBoxCorner = Instance.new("UICorner")
    textBoxCorner.CornerRadius = UDim.new(0, 4)
    textBoxCorner.Parent = textBoxBackground

    local currentValue = setting.default or ""
    if API.savedSettings[setting.moduleName] and API.savedSettings[setting.moduleName][setting.name] ~= nil then
        currentValue = API.savedSettings[setting.moduleName][setting.name]
    end

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -10, 1, -4)
    textBox.Position = UDim2.new(0, 5, 0, 2)
    textBox.BackgroundTransparency = 1
    textBox.Text = currentValue
    textBox.TextColor3 = Color3.fromRGB(200, 200, 200)
    textBox.Font = Enum.Font.SourceSans
    textBox.TextSize = 18
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.PlaceholderText = setting.placeholder or ""
    textBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    textBox.TextTruncate = Enum.TextTruncate.AtEnd
    textBox.ZIndex = textBoxBackground.ZIndex + 1
    textBox.Parent = textBoxBackground

    local textGradient = Instance.new("UIGradient")
    textGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0),
        NumberSequenceKeypoint.new(1, 0.7)
    })
    textGradient.Rotation = 0
    textGradient.Parent = textBox

    local function updateValue()
        if not API.savedSettings[setting.moduleName] then
            API.savedSettings[setting.moduleName] = {}
        end
        API.savedSettings[setting.moduleName][setting.name] = textBox.Text
        saveSettings()
        
        if setting.callback then
            setting.callback(textBox.Text)
        end
    end

    textBox.FocusLost:Connect(function()
        updateValue()
    end)

    textBox.MouseEnter:Connect(function()
        TweenService:Create(textBoxBackground, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        }):Play()
    end)

    textBox.MouseLeave:Connect(function()
        if not textBox:IsFocused() then
            TweenService:Create(textBoxBackground, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            }):Play()
        end
    end)

    textBox.Focused:Connect(function()
        TweenService:Create(textBoxBackground, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        }):Play()
        textGradient.Enabled = false
    end)

    textBox.FocusLost:Connect(function()
        TweenService:Create(textBoxBackground, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        }):Play()
        textGradient.Enabled = true
        updateValue()
    end)

    return frame
end

local function createSlider(parent, setting, position)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 600, 0, 40)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.ZIndex = parent.ZIndex + 1
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
    label.ZIndex = frame.ZIndex + 1
    label.Parent = frame

    local currentValue = setting.default
    if API.savedSettings[setting.moduleName] and API.savedSettings[setting.moduleName][setting.name] ~= nil then
        currentValue = API.savedSettings[setting.moduleName][setting.name]
    end

    local valueDisplay = Instance.new("TextLabel")
    valueDisplay.Size = UDim2.new(1, 0, 0.2, 0)
    valueDisplay.Position = UDim2.new(0, -5, 0.3, -5)
    valueDisplay.Text = tostring(currentValue) .. (setting.isPercentage and "%" or "")
    valueDisplay.TextColor3 = Color3.fromRGB(142, 142, 142)
    valueDisplay.Font = Enum.Font.SourceSans
    valueDisplay.TextSize = 22
    valueDisplay.TextXAlignment = Enum.TextXAlignment.Right
    valueDisplay.BackgroundTransparency = 1
    valueDisplay.ZIndex = frame.ZIndex + 1
    valueDisplay.Parent = frame

    local sliderBackground = Instance.new("Frame")
    sliderBackground.Size = UDim2.new(1, -11, 0, 6)
    sliderBackground.Position = UDim2.new(0, 10, 0.6, -3)
    sliderBackground.BackgroundColor3 = Color3.fromRGB(142, 142, 142)
    sliderBackground.BorderSizePixel = 0
    sliderBackground.ZIndex = frame.ZIndex + 1
    sliderBackground.Parent = frame

    local sliderActive = Instance.new("Frame")
    sliderActive.Size = UDim2.new((currentValue - setting.min) / (setting.max - setting.min), 0, 1, 0)
    sliderActive.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
    sliderActive.BorderSizePixel = 0
    sliderActive.ZIndex = sliderBackground.ZIndex + 1
    sliderActive.Parent = sliderBackground

    local sliderBackgroundCorner = Instance.new("UICorner")
    sliderBackgroundCorner.CornerRadius = UDim.new(0, 4)
    sliderBackgroundCorner.Parent = sliderBackground

    local sliderActiveCorner = Instance.new("UICorner") 
    sliderActiveCorner.CornerRadius = UDim.new(0, 4)
    sliderActiveCorner.Parent = sliderActive

    local sliderCircle = Instance.new("Frame")
    sliderCircle.Size = UDim2.new(0, 12, 0, 12)
    sliderCircle.Position = UDim2.new((currentValue - setting.min) / (setting.max - setting.min), -6, 0.5, -6)
    sliderCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderCircle.BorderSizePixel = 0
    sliderCircle.ZIndex = sliderBackground.ZIndex + 2
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
        
        if not API.savedSettings[setting.moduleName] then
            API.savedSettings[setting.moduleName] = {}
        end
        API.savedSettings[setting.moduleName][setting.name] = value
        
        local currentTime = tick()
        debounceTime = currentTime
        task.delay(0.5, function()
            if debounceTime == currentTime then
                saveSettings()
            end
        end)
        
        if setting.callback then
            setting.callback(value)
        end
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

    return frame
end

local function createToggle(parent, setting, position)
    local outerFrame = Instance.new("Frame")
    outerFrame.Size = UDim2.new(0, 280, 0, 50)
    outerFrame.Position = position
    outerFrame.BackgroundTransparency = 1
    outerFrame.BorderSizePixel = 0
    outerFrame.ZIndex = parent.ZIndex + 1
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
    enableLabel.ZIndex = outerFrame.ZIndex + 1
    enableLabel.Parent = outerFrame

    local switchTrack = Instance.new("Frame")
    switchTrack.Size = UDim2.new(0, 40, 0, 20)
    switchTrack.Position = UDim2.new(0.6, 390, 0.5, -10)
    switchTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    switchTrack.BorderSizePixel = 0
    switchTrack.ZIndex = outerFrame.ZIndex + 1
    switchTrack.Parent = outerFrame

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = switchTrack

    local switchCircle = Instance.new("Frame")
    switchCircle.Size = UDim2.new(0, 18, 0, 18)
    switchCircle.Position = UDim2.new(0, 1, 0, 1)
    switchCircle.BackgroundColor3 = Color3.fromRGB(142, 142, 142)
    switchCircle.BorderSizePixel = 0
    switchCircle.ZIndex = switchTrack.ZIndex + 1
    switchCircle.Parent = switchTrack

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = switchCircle

    local isEnabled = setting.default
    if API.savedSettings[setting.moduleName] and API.savedSettings[setting.moduleName][setting.name] ~= nil then
        isEnabled = API.savedSettings[setting.moduleName][setting.name]
    end

    local function setToggleState(newState)
        isEnabled = newState
        if isEnabled then
            switchCircle:TweenPosition(UDim2.new(1, -19, 0, 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
            switchCircle.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
        else
            switchCircle:TweenPosition(UDim2.new(0, 1, 0, 1), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
            switchCircle.BackgroundColor3 = Color3.fromRGB(142, 142, 142)
        end

        if not API.savedSettings[setting.moduleName] then
            API.savedSettings[setting.moduleName] = {}
        end
        API.savedSettings[setting.moduleName][setting.name] = isEnabled

        if setting.name == "Enabled" then
            API.savedModuleStates[setting.moduleName] = isEnabled
        end

        saveSettings()

        if setting.callback then
            pcall(setting.callback, isEnabled)
        end
    end

    setToggleState(isEnabled)

    switchTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            setToggleState(not isEnabled)
        end
    end)

    setting._setToggleState = setToggleState

    return outerFrame
end

function API:saveSettings()
    saveSettings()
end

function API:loadSettings()
    loadSettings()

    for moduleName, enabled in pairs(self.savedModuleStates) do
        for category, modules in pairs(self.modules) do
            for _, module in ipairs(modules) do
                if module.name == moduleName then
                    module.enabled = enabled
                    if module.callback then
                        pcall(module.callback, enabled)
                    end
                    break
                end
            end
        end
    end

    for moduleName, settings in pairs(self.settings) do
        if self.savedSettings[moduleName] then
            for _, setting in ipairs(settings.settings) do
                if self.savedSettings[moduleName][setting.name] ~= nil then
                    setting.default = self.savedSettings[moduleName][setting.name]
                end
            end
        end
    end
end

local function saveModuleState(moduleName, enabled)
    API.savedModuleStates[moduleName] = enabled
    saveSettings()

    for category, modules in pairs(API.modules) do
        for _, module in ipairs(modules) do
            if module.name == moduleName then
                module.enabled = enabled
                if module.callback then
                    pcall(module.callback, enabled)
                end
                break
            end
        end
    end
end

local function showModuleSettings(moduleName)
    clearSettingsContainer()
    
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
            local slider = createSlider(container, setting, UDim2.new(0, 0, 0, yOffset))
            yOffset = yOffset + 15
        elseif setting.type == "toggle" then
            local toggle = createToggle(container, setting, UDim2.new(0, 0, 0, yOffset))
            yOffset = yOffset + 5
        elseif setting.type == "textfield" then
            local textField = createTextField(container, setting, UDim2.new(0, 0, 0, yOffset))
            yOffset = yOffset + 5
        elseif setting.type == "dropdown" then
            local dropDown = createDropDown(container, setting, UDim2.new(0, 0, 0, yOffset))
            yOffset = yOffset + 5
        elseif setting.type == "button" then
            local button = createButton(container, setting, UDim2.new(0, 0, 0, yOffset))
            yOffset = yOffset + 5
        end
    end
end


local function createModuleButton(parent, moduleData)
    local moduleButton = Instance.new("Frame")
    moduleButton.Size = UDim2.new(1, -20, 0, 40)
    moduleButton.Position = UDim2.new(0, 10, 0, 0)
    moduleButton.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
    moduleButton.BorderSizePixel = 0
    moduleButton.ZIndex = parent.ZIndex + 1
    moduleButton.Parent = parent

    local moduleCorner = Instance.new("UICorner")
    moduleCorner.CornerRadius = UDim.new(0, 6)
    moduleCorner.Parent = moduleButton

    local activeLine = Instance.new("Frame")
    activeLine.Size = UDim2.new(0, 2, 0, 0)
    activeLine.Position = UDim2.new(0, 0, 0.5, 0)
    activeLine.AnchorPoint = Vector2.new(0, 0.5)
    activeLine.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
    activeLine.BorderSizePixel = 0
    activeLine.Transparency = 1
    activeLine.ZIndex = moduleButton.ZIndex + 1
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
    moduleName.ZIndex = moduleButton.ZIndex + 1
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
    clickDetector.BackgroundTransparency = 1
    clickDetector.Text = ""
    clickDetector.ZIndex = moduleButton.ZIndex + 2
    clickDetector.Parent = moduleButton

    clickDetector.MouseEnter:Connect(function()
        tweenColor(moduleButton, "BackgroundColor3", Color3.fromRGB(20, 20, 22), 0.15)
        tweenColor(moduleName, "TextColor3", Color3.fromRGB(180, 183, 193), 0.15)
    end)

    clickDetector.MouseLeave:Connect(function()
        if moduleSystem.activeModuleName == moduleData.name then
            tweenColor(moduleButton, "BackgroundColor3", Color3.fromRGB(22, 28, 30), 0.15)
            tweenColor(moduleName, "TextColor3", Color3.fromRGB(255, 75, 75), 0.15)
        else
            tweenColor(moduleButton, "BackgroundColor3", Color3.fromRGB(15, 15, 17), 0.15)
            tweenColor(moduleName, "TextColor3", Color3.fromRGB(150, 153, 163), 0.15)
        end
    end)

    clickDetector.MouseButton1Click:Connect(function()
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

        tweenColor(moduleButton, "BackgroundColor3", Color3.fromRGB(22, 28, 30))
        tweenColor(moduleName, "TextColor3", Color3.fromRGB(255, 75, 75))
        activeLine.Transparency = 0
        tweenSize(activeLine, "Size", UDim2.new(0, 2, 1, -20))

        slashLabel.Visible = true
        moduleNameLabel.Text = moduleData.name
        moduleNameLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
        moduleSystem.activeModuleName = moduleData.name
        showModuleSettings(moduleData.name)
    end)

    return moduleButton
end

local function updateModuleList(moduleFrame, categoryName)
    for _, child in pairs(moduleFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
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

-- ИСПРАВЛЕНО: Улучшенная функция для переключения видимости GUI с левым Ctrl
local function toggleGUI()
    if not _G.mainFrame then return end
    
    _G.isGUIVisible = not _G.isGUIVisible
    _G.mainFrame.Visible = _G.isGUIVisible
    
    if _G.isGUIVisible then
        showNotification("Press Left Ctrl to close GUI", "info", 2)
    else
        showNotification("Press Left Ctrl to open GUI", "success", 2)
    end
end

local function createToggleButton()
    if _G.toggleButtonCreated then return end
    
    _G.toggleButtonCreated = true
    
    local existingToggle = player.PlayerGui:FindFirstChild("UmbrellaToggle")
    if existingToggle then
        existingToggle:Destroy()
    end
    
    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "UmbrellaToggle"
    toggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    toggleGui.DisplayOrder = ZINDEX.TOGGLE_BUTTON -- ИСПРАВЛЕНО: Высокий Z-Index
    toggleGui.ResetOnSpawn = false
    toggleGui.Parent = player:WaitForChild("PlayerGui")
    
    local toggleButton = Instance.new("ImageButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 50, 0, 50)
    toggleButton.Position = UDim2.new(0, 20, 0, 20)
    toggleButton.BackgroundTransparency = 1
    toggleButton.Image = "http://www.roblox.com/asset/?id=95285379105237"
    toggleButton.BorderSizePixel = 0
    toggleButton.ZIndex = ZINDEX.TOGGLE_BUTTON + 1
    toggleButton.Parent = toggleGui
    
    toggleButton.MouseButton1Click:Connect(function()
        toggleGUI()
    end)
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = toggleButton.Position
        end
    end)
    
    toggleButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            toggleButton.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function createMainUI()
    local existingUI = player.PlayerGui:FindFirstChild("MyUI")
    if existingUI then
        existingUI:Destroy()
    end
    
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MyUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = ZINDEX.BASE -- ИСПРАВЛЕНО: Правильный DisplayOrder
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 900, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -450, 0.5, -300)
    mainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = true
    mainFrame.ZIndex = ZINDEX.MAIN_FRAME -- ИСПРАВЛЕНО: Правильный Z-Index
    mainFrame.Parent = screenGui

    local clickBlocker = Instance.new("TextButton")
    clickBlocker.Size = UDim2.new(1, 0, 1, 0)
    clickBlocker.BackgroundTransparency = 1
    clickBlocker.Text = ""
    clickBlocker.ZIndex = ZINDEX.MAIN_FRAME
    clickBlocker.Parent = mainFrame

    clickBlocker.MouseButton1Click:Connect(function() end)
    clickBlocker.MouseButton2Click:Connect(function() end)

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
    topBar.ZIndex = mainFrame.ZIndex + 1
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
    categoryFrame.ZIndex = mainFrame.ZIndex + 1
    categoryFrame.Parent = mainFrame

    local categoryList = Instance.new("ScrollingFrame")
    categoryList.Size = UDim2.new(1, 0, 1, 0)
    categoryList.Position = UDim2.new(0, 12, 0, 100)
    categoryList.BackgroundTransparency = 1
    categoryList.ScrollBarThickness = 0
    categoryList.CanvasSize = UDim2.new(0, 0, 0, 500)
    categoryList.ZIndex = categoryFrame.ZIndex + 1
    categoryList.Parent = categoryFrame

    local categoryLayout = Instance.new("UIListLayout")
    categoryLayout.Padding = UDim.new(0, 30)
    categoryLayout.Parent = categoryList

    local ModuleFrame = Instance.new("Frame")
    ModuleFrame.Size = UDim2.new(0, 150, 1, -6)
    ModuleFrame.Position = UDim2.new(0, 80, 0, 3)
    ModuleFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
    ModuleFrame.BorderSizePixel = 0
    ModuleFrame.ZIndex = mainFrame.ZIndex + 1
    ModuleFrame.Parent = mainFrame

    local moduleList = Instance.new("ScrollingFrame")
    moduleList.Size = UDim2.new(1, 0, 1, -50)
    moduleList.Position = UDim2.new(0, 10, 0, 100)
    moduleList.BackgroundTransparency = 1
    moduleList.ScrollBarThickness = 0
    moduleList.CanvasSize = UDim2.new(0, 0, 0, 500)
    moduleList.ZIndex = ModuleFrame.ZIndex + 1
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
    activeCategoryLabel.ZIndex = mainFrame.ZIndex + 2
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
    slashLabel.ZIndex = mainFrame.ZIndex + 2
    slashLabel.Parent = mainFrame

    moduleNameLabel = Instance.new("TextLabel")
    moduleNameLabel.Size = UDim2.new(0, 300, 0, 50)
    moduleNameLabel.Position = UDim2.new(0.5, -190, 0.5, -280)
    moduleNameLabel.BackgroundTransparency = 1
    moduleNameLabel.Text = ""
    moduleNameLabel.TextSize = 22
    moduleNameLabel.Font = Enum.Font.Gotham
    moduleNameLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
    moduleNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    moduleNameLabel.ZIndex = mainFrame.ZIndex + 2
    moduleNameLabel.Parent = mainFrame

    local UmbrellaIcon = Instance.new("ImageLabel")
    UmbrellaIcon.Size = UDim2.new(0, 50, 0, 50)
    UmbrellaIcon.Position = UDim2.new(0.5, -435, 0.5, -290)
    UmbrellaIcon.BackgroundTransparency = 1
    UmbrellaIcon.Image = "http://www.roblox.com/asset/?id=95285379105237"
    UmbrellaIcon.ZIndex = mainFrame.ZIndex + 2
    UmbrellaIcon.Parent = mainFrame
    
    local function addCategory(icon, name)
        local categoryButton = Instance.new("Frame")
        categoryButton.Size = UDim2.new(0, 50, 0, 50)
        categoryButton.Position = UDim2.new(0, 5, 0, 5)
        categoryButton.BackgroundColor3 = Color3.fromRGB(15, 15, 17)
        categoryButton.BorderSizePixel = 0
        categoryButton.ZIndex = categoryList.ZIndex + 1
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
        iconImage.ZIndex = categoryButton.ZIndex + 1
        iconImage.Parent = categoryButton

        local redLine = Instance.new("Frame")
        redLine.Size = UDim2.new(0, 2, 0, 0)
        redLine.Position = UDim2.new(0, 0, 0.5, 0)
        redLine.AnchorPoint = Vector2.new(0, 0.5)
        redLine.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
        redLine.Transparency = 1
        redLine.ZIndex = categoryButton.ZIndex + 1
        redLine.Parent = categoryButton

        local clickDetector = Instance.new("TextButton")
        clickDetector.Size = UDim2.new(1, 0, 1, 0)
        clickDetector.BackgroundTransparency = 1
        clickDetector.Text = ""
        clickDetector.ZIndex = categoryButton.ZIndex + 2
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

                if prevIcon then
                    tweenColor(prevIcon, "ImageColor3", Color3.fromRGB(150, 150, 150))
                end
                if prevLine then
                    tweenTransparency(prevLine, "Transparency", 1)
                    tweenSize(prevLine, "Size", UDim2.new(0, 2, 0, 0))
                end
                tweenColor(activeCategory, "BackgroundColor3", Color3.fromRGB(15, 15, 17))
            end

            activeCategory = categoryButton
            moduleSystem.activeCategory = name

            tweenColor(categoryButton, "BackgroundColor3", Color3.fromRGB(22, 28, 30))
            tweenColor(iconImage, "ImageColor3", Color3.fromRGB(255, 75, 75))

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
    settingsContainer.ZIndex = mainFrame.ZIndex + 1
    settingsContainer.Parent = mainFrame

    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 8)
    settingsCorner.Parent = settingsContainer

    _G.mainFrame = mainFrame
    _G.isGUIVisible = false
    
    createToggleButton()

    -- ИСПРАВЛЕНО: Горячая клавиша изменена на левый Ctrl
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.LeftControl then
            toggleGUI()
        end
    end)
    
    API:loadSettings()
    task.wait(0.1) -- небольшая задержка для завершения всех процессов
    API:applyPendingCallbacks()
end

function API:registerCallback(moduleName, callbacks)
    self.callbacks[moduleName] = callbacks
end

-- ДОБАВЛЕНО: Функция для показа нотификаций из внешнего кода
function API:showNotification(text, type, duration)
    showNotification(text, type or "info", duration or 3)
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

    createMainUI()
end

return {
    init = init,
    api = API
}
