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

-- список поддерживаемых игр
local GAMES = {
    [1480424328]  = {name = "Counter Blox Unranked", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/counterblox.lua"},
    [301549746]   = {name = "Counter Blox", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/counterblox.lua"},
    [6360478118]  = {name = "GPO Universe Hub", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/grandpieceonline"},
    [11424731604] = {name = "GPO Battle Royale", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/grandpieceonline"},
    [3978370137]  = {name = "GPO Main Sea 1", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/grandpieceonline"},
}

-- твой вебхук
local WEBHOOK_URL = "https://discordapp.com/api/webhooks/1410324453975658668/61-dJPlKwlAQzfjFcKtdMH2aCyCtvVN1MsE-X_dR55TBFE2L_5APBUcgf9B1P7U6AKK5"

-- отправка в дискорд
local function sendToDiscord(msg)
    local HttpService = game:GetService("HttpService")
    local data = HttpService:JSONEncode({content = msg})

    local req = (syn and syn.request) or (http and http.request) or (http_request) or (request)
    if req then
        req({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = data
        })
    end
end

-- логика проверки
local player = game.Players.LocalPlayer
local info = GAMES[game.PlaceId]

if info then
    sendToDiscord("✅ " .. player.Name .. " (".. player.UserId ..") заинжектил UmbrellaHub в игру: **" .. info.name .. "** (PlaceId: " .. game.PlaceId .. ")\nИнжектор: **" .. executor .. "**")
    loadstring(game:HttpGet(info.url))()
else
    sendToDiscord("❌ " .. player.Name .. " (".. player.UserId ..") пытался заинжектить UmbrellaHub в неподдерживаемую игру (PlaceId: " .. game.PlaceId .. ")\nИнжектор: **" .. executor .. "**")
    player:Kick("UmbrellaHub does not support this game.")
end
