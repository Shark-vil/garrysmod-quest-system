player.GetAllOmit = function(plyOmit)
    local players = {}
    for _, ply in pairs(player.GetAll()) do
        if ply ~= plyOmit then
            table.insert(players, ply)
        end
    end
    return players
end