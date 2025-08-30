-- ⚡ UmbrellaHub Loader с АНТИ-СЛИВОМ и АНТИ-ДЕБАГОМ ⚡

-- функция для получения имени инжектора
local function getExecutor()
    if identifyexecutor then
        return identifyexecutor()
    elseif getexecutorname then
        return getexecutorname()
    else
        return "Unknown"
    end
end

local executor = getExecutor()
local player = game.Players.LocalPlayer

-- список поддерживаемых игр
local GAMES = {
    [1480424328]  = {name = "Counter Blox Unranked", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/counterblox.lua"},
    [301549746]   = {name = "Counter Blox", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/counterblox.lua"},
    [6360478118]  = {name = "GPO Universe Hub", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/counterblox.lua"},
    [11424731604] = {name = "GPO Battle Royale", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/counterblox.lua"},
    [3978370137]  = {name = "GPO Main Sea 1", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/counterblox.lua"},
}

-- бич-инжекторы
local TRASH_EXECUTORS = {
    ["Xeno"] = true,
    ["JJSploit x Xeno"] = true,
    ["JJSploit"] = true,
}

-- твой вебхук
local WEBHOOK_URL = "https://discordapp.com/api/webhooks/1410324453975658668/61-dJPlKwlAQzfjFcKtdMH2aCyCtvVN1MsE-X_dR55TBFE2L_5APBUcgf9B1P7U6AKK5"

----------------------------------------------------------
-- АНТИ-СЛИВ И АНТИ-ДЕБАГ
----------------------------------------------------------

-- отправка в дискорд
local function sendToDiscord(msg)
    local HttpService = game:GetService("HttpService")
    local data = HttpService:JSONEncode({content = msg})

    local req = (syn and syn.request) or (http and http.request) or (http_request) or (request)
    if req then
        req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = data
        })
    end
end

-- что делать с крысой
local function punish(reason)
    sendToDiscord("⚠️ [ANTI-DEBUG] Игрок **" .. player.Name .. " ("..player.UserId..")** пытался " .. reason)
    player:Kick("dumb child trying to find something interesting?)))")
    task.wait(0.1)
    while true do end -- зависание
end

-- проверка аргументов
local function antiLeakCheck(...)
    local args = {...}
    for _, v in next, args do
        v = tostring(v)
        if v:find("https://") or v:find("http://") or v:find("webhook") then
            punish("дебажить/логнуть ссылки или вебхук")
        end
    end
end

-- хук опасных функций
local protectedFuncs = {print, warn, error, rconsoleprint, rconsolewarn, rconsoleerr, setclipboard}
for _, fn in next, protectedFuncs do
    if fn then
        local old
        old = hookfunction(fn, newcclosure(function(...)
            antiLeakCheck(...)
            return old(...)
        end))
    end
end

-- метатаблица для _G
setmetatable(_G, {
    __newindex = function(t, i, v)
        if tostring(i):lower():find("id") or tostring(i):lower():find("webhook") then
            punish("подменить глобальные переменные")
        end
        rawset(t, i, v)
    end
})

----------------------------------------------------------
-- ЛОГИКА ЗАПУСКА СКРИПТА
----------------------------------------------------------

local info = GAMES[game.PlaceId]

-- 1. Проверка игры
if not info then
    sendToDiscord("❌ " .. player.Name .. " (".. player.UserId ..") попытался заинжектить UmbrellaHub в неподдерживаемую игру (PlaceId: " .. game.PlaceId .. ")\nИнжектор: **" .. executor .. "**")
    return -- просто не грузим
end

-- 2. Проверка инжектора
if TRASH_EXECUTORS[executor] then
    sendToDiscord("🚫 " .. player.Name .. " (".. player.UserId ..") зашёл с бич-инжектором: **"..executor.."** в игру "..info.name.." (PlaceId: "..game.PlaceId..")")
    -- вместо кика грузим "лайт версию"
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/cbrofix.lua"))()
    return
end

-- 3. Всё норм → грузим основной скрипт
sendToDiscord("✅ " .. player.Name .. " (".. player.UserId ..") заинжектил UmbrellaHub в игру: **" .. info.name .. "** (PlaceId: " .. game.PlaceId .. ")\nИнжектор: **" .. executor .. "**")
loadstring(game:HttpGet(info.url))()
