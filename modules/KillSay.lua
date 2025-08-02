local KillSay = {
    Enabled = false,
    Message = "ez get Umbrella.hub", -- Сообщение по умолчанию
    Connection = nil
}

local function Initialize()
    -- Удаляем старое соединение если было
    if KillSay.Connection then
        KillSay.Connection:Disconnect()
        KillSay.Connection = nil
    end

    -- Создаем новое соединение если включено
    if KillSay.Enabled then
        KillSay.Connection = LocalPlayer.Status.Kills:GetPropertyChangedSignal("Value"):Connect(function(current)
            if current == 0 then return end
            game:GetService("ReplicatedStorage").Events.PlayerChatted:FireServer(
                KillSay.Message, -- Используем сохраненное сообщение
                false, 
                "Innocent", 
                false, 
                true
            )
        end)
    end
end

return {
    Toggle = function(state) 
        KillSay.Enabled = state
        Initialize()
    end,
    SetMessage = function(text)
        KillSay.Message = text
    end,
    GetMessage = function()
        return KillSay.Message
    end
}
