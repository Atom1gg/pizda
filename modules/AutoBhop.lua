local function AutoBhopModule()
    local module = {
        enabled = false,
        jumpPower = 30,
        maxSpeed = 120,
        strafePower = 15,
        groundCheckOffset = Vector3.new(0, -1.5, 0),
        groundCheckRadius = 1,
        jumpCooldown = 0.2,
        lastJumpTime = 0
    }

    -- Локальные переменные
    local player = game:GetService("Players").LocalPlayer
    local character, humanoid, rootPart
    local runService = game:GetService("RunService")
    local inputService = game:GetService("UserInputService")
    local physicsService = game:GetService("PhysicsService")

    -- Физические параметры
    local currentSpeed = 0
    local lastYaw = 0
    local isOnGround = false
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    -- Инициализация персонажа
    local function initCharacter()
        character = player.Character or player.CharacterAdded:Wait()
        humanoid = character:WaitForChild("Humanoid")
        rootPart = character:WaitForChild("HumanoidRootPart")
        
        -- Настройка фильтра лучей
        raycastParams.FilterDescendantsInstances = {character}
        
        -- Сохраняем оригинальные параметры
        if not module.originalJumpPower then
            module.originalJumpPower = humanoid.JumpPower
        end
        if not module.originalWalkSpeed then
            module.originalWalkSpeed = humanoid.WalkSpeed
        end
    end

    -- Проверка нахождения на земле
    local function checkGround()
        if not rootPart then return false end
        local rayOrigin = rootPart.Position
        local rayDirection = module.groundCheckOffset
        local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        
        if raycastResult then
            local normal = raycastResult.Normal
            return normal.Y > 0.7 -- Угол нормали для определения "земли"
        end
        return false
    end

    -- Основная логика BHop
    local function updateBHop(dt)
        if not humanoid or not rootPart then return end
        
        -- Обновляем состояние нахождения на земле
        isOnGround = checkGround()
        
        -- Получаем направление движения
        local moveDirection = humanoid.MoveDirection
        local isMoving = moveDirection.Magnitude > 0
        
        -- Физика ускорения
        if isMoving and isOnGround then
            local yaw = math.atan2(moveDirection.X, moveDirection.Z)
            local yawDelta = (yaw - lastYaw + math.pi) % (2 * math.pi) - math.pi
            
            -- Ускорение при страфе
            if math.abs(yawDelta) > 0.1 then
                currentSpeed = math.min(currentSpeed + module.strafePower * math.abs(yawDelta), module.maxSpeed)
            else
                currentSpeed = math.max(currentSpeed - 5, module.originalWalkSpeed or 16)
            end
            
            lastYaw = yaw
        elseif not isOnGround then
            currentSpeed = math.max(currentSpeed - 2, module.originalWalkSpeed or 16)
        end
        
        -- Применяем скорость
        humanoid.WalkSpeed = currentSpeed
        
        -- Автопрыжок
        if isOnGround and (os.clock() - module.lastJumpTime) > module.jumpCooldown then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            module.lastJumpTime = os.clock()
        end
    end

    -- Включение/выключение
    local function enable()
        if module.enabled then return end
        
        initCharacter()
        humanoid.JumpPower = module.jumpPower
        
        module.connection = runService.Heartbeat:Connect(updateBHop)
        module.enabled = true
    end

    local function disable()
        if not module.enabled then return end
        
        if module.connection then
            module.connection:Disconnect()
        end
        
        if humanoid then
            humanoid.WalkSpeed = module.originalWalkSpeed or 16
            humanoid.JumpPower = module.originalJumpPower or 50
        end
        
        module.enabled = false
    end

    return {
        Toggle = function(state)
            if state then
                enable()
            else
                disable()
            end
        end,
        
        SetJumpPower = function(value)
            module.jumpPower = value
            if humanoid and module.enabled then
                humanoid.JumpPower = value
            end
        end,
        
        SetMaxSpeed = function(value)
            module.maxSpeed = value
        end,
        
        SetStrafePower = function(value)
            module.strafePower = value
        end,
        
        SetGroundCheck = function(offset, radius)
            module.groundCheckOffset = offset or Vector3.new(0, -1.5, 0)
            module.groundCheckRadius = radius or 1
        end,
        
        enabled = function()
            return module.enabled
        end
    }
end

return AutoBhopModule()
