local Proxy = module("vrp","lib/Proxy")
local Tunnel = module("vrp","lib/Tunnel")
local vRP = Proxy.getInterface("vRP")
local xSound = exports.xsound

mapreedev = {}
Tunnel.bindInterface(GetCurrentResourceName(), mapreedev)

RegisterCommand(Config.CommandVehicle, function(source,args,rawCommand)
    local user_id = vRP.getUserId(source)
    if user_id then
        if vRP.hasPermission(user_id, "admin") or vRP.hasPermission(user_id, "som") then
            TriggerClientEvent("Music:ShowNui",source)
        end
    end
end)

function mapreedev.GetMusic()
    return Config.Zones
end

RegisterNetEvent("MusicLab:searchMusic")
AddEventHandler("MusicLab:searchMusic", function(musicQuery)
    local source = source
    local baseUrl = "http://localhost:3000/search?music="

    local url = baseUrl .. musicQuery

    PerformHttpRequest(url, function(statusCode, data, headers)
        if statusCode >= 200 and statusCode <= 299 then
            local responseData = json.decode(data)
            
            TriggerClientEvent("MusicLab:searchMusicResult", source, responseData)
        else
            print("Erro na requisição HTTP: " .. statusCode)
        end
    end)
end)

RegisterNetEvent("MusicLab:deletePlaylist")
AddEventHandler("MusicLab:deletePlaylist", function(id)
    local user_id = vRP.getUserId(source)

    local query = MySQL.query.await("DELETE FROM music_playlist WHERE id = @id AND player_id = @playerId", {
        ["@id"] = id,
        ["@playerId"] = user_id
    })

    if query then
    else
        print("Erro ao deletar a playlist.")
    end
end)

RegisterNetEvent("MusicLab:editPlaylist")
AddEventHandler("MusicLab:editPlaylist", function(id, name, url_img)
    local user_id = vRP.getUserId(source)

    local query = MySQL.update.await("UPDATE music_playlist SET name = @name, url_img = @url_img WHERE id = @id AND player_id = @playerId", {
        ["@name"] = name,
        ["@url_img"] = url_img,
        ["@id"] = id,
        ["@playerId"] = user_id
    })

    if query then
    else
        print("Erro ao atualizar a playlist.")
    end
end)

RegisterNetEvent("MusicLab:updatePlaylistMusicList")
AddEventHandler("MusicLab:updatePlaylistMusicList", function(playlist_id, updatedMusicList)
    local user_id = vRP.getUserId(source)

    local updatedMusicData = json.decode(updatedMusicList)

    local querySelect = MySQL.query.await("SELECT player_id FROM music_playlist WHERE id = @playlistId", {
        ["@playlistId"] = playlist_id
    })

    if querySelect and #querySelect > 0 then
        local playlistOwnerId = querySelect[1].player_id

        if user_id == playlistOwnerId then
            local queryUpdate = MySQL.update.await("UPDATE music_playlist SET music_playlist = @updatedMusicData WHERE id = @playlistId", {
                ["@updatedMusicData"] = updatedMusicList,
                ["@playlistId"] = playlist_id
            })

            if queryUpdate then
            else
                print("Erro ao atualizar a lista de músicas da playlist.")
            end
        else
            print("O jogador atual não tem permissão para atualizar esta playlist.")
        end
    else
        print("Playlist não encontrada.")
    end
end)

RegisterNetEvent("MusicLab:removeMusicFromPlaylist")
AddEventHandler("MusicLab:removeMusicFromPlaylist", function(music_id, playlist_id)
    local querySelect = MySQL.query.await("SELECT music_playlist FROM music_playlist WHERE id = @playlistId", {
        ["@playlistId"] = playlist_id
    })

    if querySelect and #querySelect > 0 then
        local playlistData = querySelect[1]
        local music_playlist = json.decode(playlistData.music_playlist)

        for i, music in ipairs(music_playlist) do
            if music.id == music_id then
                table.remove(music_playlist, i)
                break
            end
        end

        local updatedMusicData = json.encode(music_playlist)
        local queryUpdate = MySQL.update.await("UPDATE music_playlist SET music_playlist = @updatedMusicData WHERE id = @playlistId", {
            ["@updatedMusicData"] = updatedMusicData,
            ["@playlistId"] = playlist_id
        })

        if queryUpdate then
        else
            print("Erro ao remover a música da playlist.")
        end
    else
        print("Playlist não encontrada.")
    end
end)


RegisterNetEvent("MusicLab:addToPlaylist")
AddEventHandler("MusicLab:addToPlaylist", function(playlistId, url_id, name, id)
    local user_id = vRP.getUserId(source)

    local querySelect = MySQL.query.await("SELECT music_playlist FROM music_playlist WHERE id = @playlistId AND player_id = @playerId", {
        ["@playlistId"] = playlistId,
        ["@playerId"] = user_id
    })
    
    if querySelect and #querySelect > 0 then
        local currentMusicData = json.decode(querySelect[1].music_playlist)

        local newMusicItem = {
            id = id,
            url_id = url_id,
            name = name
        }
        table.insert(currentMusicData, 1, newMusicItem)
        
        local newMusicDataJson = json.encode(currentMusicData)
        
        local queryUpdate = MySQL.update.await("UPDATE music_playlist SET music_playlist = @newMusicData WHERE id = @playlistId AND player_id = @playerId", {
            ["@newMusicData"] = newMusicDataJson,
            ["@playlistId"] = playlistId,
            ["@playerId"] = user_id
        })
        
        if queryUpdate > 0 then
        else
            print("Erro ao atualizar a playlist com a nova música.")
        end
    else
        print("Playlist não encontrada para o jogador.")
    end
end)


RegisterNetEvent("MusicLab:reqPlaylists")
AddEventHandler("MusicLab:reqPlaylists", function()
    local source = source
    local user_id = vRP.getUserId(source)
    local querySelect = MySQL.query.await("SELECT * FROM music_playlist WHERE player_id = @playerId", {
        ["@playerId"] = user_id
    })
    local playlists = {}
    
    for _, playlistData in ipairs(querySelect) do
        local playlist = {
            id = playlistData.id,
            name = playlistData.name,
            url_img = playlistData.url_img,
            music_playlist = json.decode(playlistData.music_playlist)
        }
        table.insert(playlists, playlist)
    end

    local newPlaylistJson = json.encode(playlists)
    TriggerClientEvent("MusicLab:receiveAllPlaylists", source, newPlaylistJson)
end)

RegisterNetEvent("MusicLab:createNewPlaylist")
AddEventHandler("MusicLab:createNewPlaylist", function()
    local source = source
    local user_id = vRP.getUserId(source)
    local defaultName = "Playlist"
    local defaultUrlImg = "https://images.unsplash.com/photo-1494232410401-ad00d5433cfa?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80"
    local musicData = {}

    local query = MySQL.insert.await("INSERT INTO music_playlist (player_id, name, url_img, music_playlist) VALUES (@playerId, @name, @urlImg, @musicData)", {
        ["@playerId"] = user_id,
        ["@name"] = defaultName,
        ["@urlImg"] = defaultUrlImg,
        ["@musicData"] = json.encode(musicData)
    })
    
    if query then
        local querySelect = MySQL.query.await("SELECT * FROM music_playlist WHERE player_id = @playerId", {
            ["@playerId"] = user_id
        })
        local playlists = {}
        
        for _, playlistData in ipairs(querySelect) do
            local playlist = {
                id = playlistData.id,
                name = playlistData.name,
                url_img = playlistData.url_img,
                music_playlist = json.decode(playlistData.music_playlist)
            }
            table.insert(playlists, playlist)
        end
    
        local newPlaylistJson = json.encode(playlists)
        TriggerClientEvent("MusicLab:receiveAllPlaylists", source, newPlaylistJson)
    else
        print("Erro ao criar uma nova playlist.")
    end
end)

RegisterNetEvent("MusicLab:reqHistory")
AddEventHandler("MusicLab:reqHistory", function()
    local source = source
    local user_id = vRP.getUserId(source)
    local queryForHistory = MySQL.query.await('SELECT music_history_list FROM music_history WHERE player_id = ?', {user_id})

    if queryForHistory and #queryForHistory > 0 then
        local currentHistory = json.decode(queryForHistory[1].music_history_list)
        local newHistoryJson = json.encode(currentHistory)

        if currentHistory and type(currentHistory) == "table" then
            TriggerClientEvent("MusicLab:showHistory", source, newHistoryJson)
        else
            print("Dados inválidos encontrados no histórico de músicas.")
        end
    else
        print("Histórico de músicas não encontrado para o jogador.")
    end
end)

RegisterNetEvent("MusicLab:addToHistory")
AddEventHandler("MusicLab:addToHistory", function(url_id, name, id)
    local user_id = vRP.getUserId(source)
    local queryForSave = MySQL.query.await('SELECT music_history_list FROM music_history WHERE player_id = ?', {user_id})

    if queryForSave and #queryForSave > 0 then
        local currentHistory = json.decode(queryForSave[1].music_history_list)

        local urlExists = false
        for i, historyItem in ipairs(currentHistory) do
            if historyItem.url_id == url_id then
                urlExists = true
                table.remove(currentHistory, i)
                break
            end
        end

        local newHistoryItem = {
            id = id,
            url_id = url_id,
            name = name
        }

        table.insert(currentHistory, 1, newHistoryItem)

        if #currentHistory > 20 then
            table.remove(currentHistory, 21)
        end

        local newHistoryJson = json.encode(currentHistory)

        local updateHistory = MySQL.update.await('UPDATE music_history SET music_history_list = ? WHERE player_id = ?', {newHistoryJson, user_id})

        if updateHistory > 0 then
        else
            print("Erro ao atualizar o histórico de músicas.")
        end
    else
        local newHistoryItem = {
            id = id,
            url_id = url_id,
            name = name
        }

        local newHistoryJson = json.encode({newHistoryItem})

        local insertHistory = MySQL.insert.await('INSERT INTO music_history (player_id, music_history_list) VALUES (?, ?)', {user_id, newHistoryJson})

        if insertHistory > 0 then
        else
            print("Erro ao inserir o histórico de músicas.")
        end
    end
end)

RegisterNetEvent("MusicLab:showLike")
AddEventHandler("MusicLab:showLike", function(url_id)
    local source = source
    local user_id = vRP.getUserId(source)
    local url_id_to_check = url_id
    local queryForCheck = MySQL.query.await('SELECT like_music_list FROM music_like_list WHERE player_id = ?', {user_id})

    if queryForCheck and #queryForCheck > 0 then
        local currentLikes = json.decode(queryForCheck[1].like_music_list)

        local isUrlIdInList = false
        for _, like in ipairs(currentLikes) do
            if like.url_id == url_id_to_check then
                isUrlIdInList = true
                break
            end
        end

        if isUrlIdInList then
            TriggerClientEvent("MusicLab:showLike", source,url_id_to_check)
        else
        end
    else
    end
end)

RegisterNetEvent("MusicLab:liked")
AddEventHandler("MusicLab:liked", function(url_id, name, id)
    local source = source
    local user_id = vRP.getUserId(source)
    local queryForSave = MySQL.query.await('SELECT like_music_list FROM music_like_list WHERE player_id = ?', {user_id})

    if queryForSave and #queryForSave > 0 then
        local currentLikes = json.decode(queryForSave[1].like_music_list)

        local newLike = {
            id = id,
            url_id = url_id,
            name = name
        }

        table.insert(currentLikes, 1, newLike)

        local newLikeJson = json.encode(currentLikes)

        local updateLiked = MySQL.update.await('UPDATE music_like_list SET like_music_list = ? WHERE player_id = ?', {newLikeJson, user_id})

        if updateLiked > 0 then
            TriggerClientEvent("MusicLab:showLike", source, url_id)
        else
            print("Erro ao atualizar a lista de músicas curtidas.")
        end
    else
        local newLike = {
            id = id,
            url_id = url_id,
            name = name
        }

        local newLikeJson = json.encode({newLike})

        local insertLike = MySQL.insert.await('INSERT INTO music_like_list (player_id, like_music_list) VALUES (?, ?)', {user_id, newLikeJson})

        if insertLike > 0 then
            TriggerClientEvent("MusicLab:showLike", source, url_id)
        else
            print("Erro ao inserir a lista de músicas curtidas.")
        end
    end
end)


RegisterNetEvent("MusicLab:remLike")
AddEventHandler("MusicLab:remLike", function(url_id)
    local source = source
    local user_id = vRP.getUserId(source)
    local queryForSave = MySQL.query.await('SELECT like_music_list FROM music_like_list WHERE player_id = ?', {user_id})

    if queryForSave and #queryForSave > 0 then
        local currentLikes = json.decode(queryForSave[1].like_music_list)

        local url_id_to_remove = url_id

        local index_to_remove = nil
        for i, like in ipairs(currentLikes) do
            if like.url_id == url_id_to_remove then
                index_to_remove = i
                break
            end
        end

        if index_to_remove then
            table.remove(currentLikes, index_to_remove)

            local newLikeJson = json.encode(currentLikes)

            local updateLiked = MySQL.update.await('UPDATE music_like_list SET like_music_list = ? WHERE player_id = ?', {newLikeJson, user_id})

            if updateLiked > 0 then
                TriggerClientEvent("MusicLab:showRemLike", source, url_id)
            else
                print("Erro ao atualizar a lista de músicas curtidas.")
            end
        else
            print("URL_ID não encontrado na lista de músicas curtidas.")
        end
    else
        print("Lista de músicas curtidas não encontrada para o jogador.")
    end
end)

RegisterNetEvent("MusicLab:footerLike")
AddEventHandler("MusicLab:footerLike", function(url_id)
    local source = source
    local user_id = vRP.getUserId(source)
    local queryForSave = MySQL.query.await('SELECT like_music_list FROM music_like_list WHERE player_id = ?', {user_id})

    if queryForSave and #queryForSave > 0 then
            local currentLikes = json.decode(queryForSave[1].like_music_list)
            local url_id_to_check = url_id

            local found = false
            for _, like in ipairs(currentLikes) do
                    if like.url_id == url_id_to_check then
                            found = true
                            break
                    end
            end

            TriggerClientEvent("MusicLab:showFooterLike", source, found)
    else
            print("Lista de músicas curtidas não encontrada para o jogador.")
    end
end)

RegisterNetEvent("MusicLab:updatedLike")
AddEventHandler("MusicLab:updatedLike", function(listLike)
    local user_id = vRP.getUserId(source)

    local currentLikes = json.decode(listLike)

    if currentLikes and type(currentLikes) == "table" then
        local newLikeJson = json.encode(currentLikes)
        local updateLiked = MySQL.update.await('UPDATE music_like_list SET like_music_list = ? WHERE player_id = ?', {newLikeJson, user_id})

        if updateLiked > 0 then
        else
            print("Erro ao atualizar a lista de músicas curtidas.")
        end
    else
        print("Dados inválidos encontrados na lista de músicas curtidas.")
    end
end)

RegisterNetEvent("MusicLab:reqBannerInfo")
AddEventHandler("MusicLab:reqBannerInfo", function()
    local source = source

    TriggerClientEvent("MusicLab:showBannerInfo", source, banner)
end)

RegisterNetEvent("MusicLab:reqLikeList")
AddEventHandler("MusicLab:reqLikeList", function()
    local source = source
    local user_id = vRP.getUserId(source)
    local queryForSave = MySQL.query.await('SELECT like_music_list FROM music_like_list WHERE player_id = ?', {user_id})

    if queryForSave and #queryForSave > 0 then
        local currentLikes = json.decode(queryForSave[1].like_music_list)
        local newLikeJson = json.encode(currentLikes)

        if currentLikes and type(currentLikes) == "table" then
            TriggerClientEvent("MusicLab:showLikeList", source, newLikeJson)
        else
            print("Dados inválidos encontrados na lista de músicas curtidas.")
        end
    else
        print("Lista de músicas curtidas não encontrada para o jogador.")
    end
end)


RegisterNetEvent("MusicLab:ChangeVolume")
AddEventHandler("MusicLab:ChangeVolume", function(vol, nome)
    local somafter = false
    local rangeafter = false
    for i = 1, #Config.Zones do
        local v = Config.Zones[i]
        if nome == v.name then
            local vadi = vol
            if vadi <= 1.01 and vadi >= -0.001 then
                            if vadi < 0.005 then
                                vadi = 0.0
                            end
                            if v.popo then
                                    v.range = (v.volume*Config.DistanceToVolume)
                            else
                    if vadi >= 0.05 then
                        v.range = (vadi*v.range)/v.volume
                    end
                end
                v.volume = vadi
                somafter = v.volume
                rangeafter = v.range
            end
        end
    end
    if somafter and rangeafter then
        TriggerClientEventForAllPlayers("MusicLab:ChangeVolume",somafter,rangeafter, nome)
    end
end)

RegisterNetEvent("MusicLab:ChangeLoop")
AddEventHandler("MusicLab:ChangeLoop", function(nome,tip)
    local loopstate
    for i = 1, #Config.Zones do
        local v = Config.Zones[i]
        if nome == v.name then
            v.loop = tip
            loopstate = v.loop
        end
    end
    if loopstate ~= nil then
        TriggerClientEventForAllPlayers("MusicLab:ChangeLoop",loopstate, nome)
    end
end)

RegisterNetEvent("MusicLab:ChangeState")
AddEventHandler("MusicLab:ChangeState", function(type, nome)
    for i = 1, #Config.Zones do
        local v = Config.Zones[i]
        if nome == v.name then
            v.isplaying = type
        end
    end
    TriggerClientEventForAllPlayers("MusicLab:ChangeState",type, nome)
end)

RegisterNetEvent("MusicLab:ChangePosition")
AddEventHandler("MusicLab:ChangePosition", function(quanti, nome)
    local players = GetPlayers()
    for i = 1, #Config.Zones do
        local v = Config.Zones[i]
        if nome == v.name then
            v.deftime = quanti
            if v.deftime < 0 then
                v.deftime = 0
            end
        end
    end
    TriggerClientEventForAllPlayers("MusicLab:NewTimeMusic",quanti, nome)
end)

RegisterNetEvent("MusicLab:setNewMuisic")
AddEventHandler("MusicLab:setNewMuisic", function(quanti, nome, link)
    for i = 1, #Config.Zones do
        local v = Config.Zones[i]
        if nome == v.name then
            v.deftime = quanti
            if v.deftime < 0 then
                v.deftime = 0
            end
        end
    end
    TriggerClientEventForAllPlayers("MusicLab:setNewMuisic",quanti, nome, link)
end)

RegisterNetEvent("MusicLab:ModifyURL")
AddEventHandler("MusicLab:ModifyURL", function(data)
    local _data = data
    local zena = false
    for i = 1, #Config.Zones do
        local v = Config.Zones[i]
        if _data.name == v.name then
            v.deflink = _data.link
            if _data.popo then
                v.popo = _data.popo
            end
            v.deftime = 0
            v.isplaying = true
            v.loop = _data.loop
            zena = v
        end
    end
    if zena then
        TriggerClientEventForAllPlayers("MusicLab:ModifyURL",zena)
    end
end)

function countTime()
    SetTimeout(1000, countTime)
    for i = 1, #Config.Zones do
        local v = Config.Zones[i]
        if v.isplaying then
            v.deftime = v.deftime + 1
        end
    end
end

SetTimeout(1000, countTime)

RegisterNetEvent('MusicLab:AddVehicle')
AddEventHandler("MusicLab:AddVehicle", function(vehdata)
    local Data = {}
    Data.name = vehdata.plate
    Data.coords = vehdata.coords
    Data.range = vehdata.volume * Config.DistanceToVolume
    Data.volume = vehdata.volume
    Data.deflink = vehdata.link
    Data.isplaying = true
    Data.loop = vehdata.loop
    Data.deftime = 0
    Data.popo = vehdata.popo
    table.insert(Config.Zones, Data)
    TriggerClientEventForAllPlayers('MusicLab:AddVehicle', Config.Zones[#Config.Zones])
end)

RegisterNetEvent('MusicLab:GetDate')
AddEventHandler('MusicLab:GetDate', function()
    TriggerClientEventForAllPlayers('MusicLab:SendData', Config.Zones)
end)

function TriggerClientEventForAllPlayers(event, ...)
    local players = GetPlayers()

    for _, player in pairs(players) do
        TriggerClientEvent(event, player, ...)
    end
end