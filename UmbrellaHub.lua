local GAMES = {
    CounterBlox = 301549746, -- Counter Blox
}

-- Проверка текущего PlaceId
if game.PlaceId == GAMES.CounterBlox then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Atom1gg/pizda/main/loader.lua"))()
else
    return
end
