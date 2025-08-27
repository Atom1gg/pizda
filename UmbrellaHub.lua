local GAMES = {
    [1480424328] = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/counterblox.lua", -- counterblox unranked
    [301549746]  = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/counterblox.lua", -- counterblox 
    [6360478118] = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/grandpieceonline", -- gpo universe hub
    [11424731604] = "https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/grandpieceonline", -- gpo battle royale
}

local scriptUrl = GAMES[game.PlaceId]
if scriptUrl then
    loadstring(game:HttpGet(scriptUrl))()
else
    game.Players.LocalPlayer:Kick("UmbrellaHub does not support this game.")
end
