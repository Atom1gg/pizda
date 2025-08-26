local GAMES = {
    MainGame = 1480424328, -- Главная игра
    Division = 301549746,  -- Подразделение (Counter Blox)
}

-- Проверка текущего PlaceId
if game.PlaceId == GAMES.MainGame then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/main_game.lua"))()
elseif game.PlaceId == GAMES.Division then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Atom1gg/pizda/refs/heads/main/games/counterblox.lua"))()
else
    return
end
