local GAMES = {
    CounterBlox = 301549746, -- Counter Blox
}

-- Проверка текущего PlaceId
if game.PlaceId == GAMES.CounterBlox then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/counterblox.lua"))()
else
    return
end
