local GAMES = {
    [1480424328]  = {name = "Counter Blox Unranked", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/counterblox.lua"},
    [301549746]   = {name = "Counter Blox", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/counterblox.lua"},
    [6360478118]  = {name = "GPO Universe Hub", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/grandpieceonline"},
    [11424731604] = {name = "GPO Battle Royale", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/grandpieceonline"},
    [3978370137]  = {name = "GPO Main Sea 1", url = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/grandpieceonline"},
}

local WEBHOOK_URL = "https://discordapp.com/api/webhooks/1410324453975658668/61-dJPlKwlAQzfjFcKtdMH2aCyCtvVN1MsE-X_dR55TBFE2L_5APBUcgf9B1P7U6AKK5"

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
    else
    end
end

-- логика
local player = game.Players.LocalPlayer
local info = GAMES[game.PlaceId]

if info then
    sendToDiscord("✅ " .. player.Name .. " заинжектил UmbrellaHub в игру: **" .. info.name .. "** (PlaceId: " .. game.PlaceId .. ")")
    loadstring(game:HttpGet(info.url))()
else
    sendToDiscord("❌ " .. player.Name .. " пытался заинжектить UmbrellaHub в неподдерживаемую игру (PlaceId: " .. game.PlaceId .. ")")
    player:Kick("UmbrellaHub does not support this game.")
end
