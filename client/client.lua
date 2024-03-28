local Proxy = module("vrp","lib/Proxy")
local Tunnel = module("vrp","lib/Tunnel")
local vRP = Proxy.getInterface("vRP")

vSERVER = Tunnel.getInterface(GetCurrentResourceName())

local Music = {}
local datasoundinfo = {}
local nuiaberto = false
local myjob = nil
local nomidaberto
local SoundsPlaying = {}


xSound = exports.xsound

Citizen.CreateThread(function()
	TriggerServerEvent("MusicLab:GetDate")
end)

RegisterNUICallback("action", function(data, cb)
	local _source = source
	local nameid = nomidaberto
	if IsPedInAnyVehicle(PlayerPedId(), false) then
		local veh = GetVehiclePedIsIn(PlayerPedId(),false)
		local plate = GetVehicleNumberPlateText(veh)
		nameid = plate
	end
	if data.action == "seturl" then
		SendNUIMessage({
			action = "changevidname",
			text = data.link,
		})
		SetUrl(data.link,nameid)
	elseif data.action == "play" then
		if xSound:soundExists(nameid) then
			if xSound:isPaused(nameid) then
				TriggerServerEvent("MusicLab:ChangeState", true, nameid)
				local esperar = 0
				while nuiaberto do
					Wait(1000)
					if xSound:isPlaying(nameid) then
						SendNUIMessage({
							action = "TimeVid",
							total = xSound:getMaxDuration(nameid),
							played = xSound:getTimeStamp(nameid),
						})
					else
						esperar = esperar +1
					end
					if esperar >= 5 then
						break
					end
				end
			end
		end
	elseif data.action == "pause" then
		if xSound:soundExists(nameid) then
			if xSound:isPlaying(nameid) then
				TriggerServerEvent("MusicLab:ChangeState", false, nameid)
			end
		end
	elseif data.action == "exit" then
		show()
	elseif data.action == "volume" then
		ApplySound(data.value,nameid)
	elseif data.action == "loop" then
		if xSound:soundExists(nameid) then
			datasoundinfo.loop = not xSound:isLooped(nameid)
			TriggerServerEvent("MusicLab:ChangeLoop",nameid,datasoundinfo.loop)
		else
			datasoundinfo.loop = not datasoundinfo.loop
		end
		if type(datasoundinfo.loop) ~= "table" then
			local loop = datasoundinfo.loop
			SendNUIMessage({
				action = "changeMusicLoop",
				loop = loop,
			})
		end
	elseif data.action == "setNewTime" then
		if xSound:soundExists(nameid) then
			TriggerServerEvent("MusicLab:ChangePosition", data.newTime, nameid)
		end
	elseif data.action == "getMusicExists" then
		if not xSound:soundExists(nameid) then
			SendNUIMessage({
				action = "NextMusic",
				value = true
			})
		end
	elseif data.action == "showLike" then
		TriggerServerEvent("MusicLab:showLike", data.url_id )
	elseif data.action == "liked" then
		TriggerServerEvent("MusicLab:liked", data.url_id, data.name, data.newIdBd )
	elseif data.action == "remLike" then
		TriggerServerEvent("MusicLab:remLike", data.url_id )
	elseif data.action == "reqBannerInfo" then
		TriggerServerEvent("MusicLab:reqBannerInfo")
	elseif data.action == "reqLikeList" then
		TriggerServerEvent("MusicLab:reqLikeList")
	elseif data.action == "showFooterLike" then
		TriggerServerEvent("MusicLab:footerLike", data.url_id )
	elseif data.action == "updatedLikeList" then
		TriggerServerEvent("MusicLab:updatedLike", data.listLike )
	elseif data.action == "addToHistory" then
		TriggerServerEvent("MusicLab:addToHistory", data.url_id, data.name, data.newIdBd )
	elseif data.action == "reqHistory" then
		TriggerServerEvent("MusicLab:reqHistory")
	elseif data.action == "createPlaylist" then
		TriggerServerEvent("MusicLab:createNewPlaylist")
	elseif data.action == "reqPlaylists" then
		TriggerServerEvent("MusicLab:reqPlaylists")
	elseif data.action == "reqPlaylists" then
		TriggerServerEvent("MusicLab:reqPlaylists")
	elseif data.action == "addToPlaylist" then
		TriggerServerEvent("MusicLab:addToPlaylist", data.playlistId, data.url_id, data.name, data.id)
	elseif data.action == "removeToPlaylist" then
		TriggerServerEvent("MusicLab:removeMusicFromPlaylist", data.id, data.playlistId)
	elseif data.action == "updatePlaylist" then
		TriggerServerEvent("MusicLab:updatePlaylistMusicList", data.playlist_id, data.updatedMusicList)
	elseif data.action == "editPlaylist" then
		TriggerServerEvent("MusicLab:editPlaylist", data.id, data.name, data.url_img)
	elseif data.action == "searchMusic" then
		TriggerServerEvent("MusicLab:searchMusic", data.musicQuery)
	elseif data.action == "deletePlaylist" then
		TriggerServerEvent("MusicLab:deletePlaylist", data.id)
	end
end)

function ApplySound(quanti,plate)
	local exis = false
	local som = datasoundinfo.volume
	if xSound:soundExists(plate) and xSound:isPlaying(plate) then
		exis = true
		som = xSound:getVolume(plate)
		datasoundinfo.volume = som
	end
	local vadi = quanti
	if vadi <= 1.01 and vadi >= -0.001 and exis then
		if vadi < 0.005 then
			vadi = 0.0
		end
		datasoundinfo.volume = vadi
		TriggerServerEvent("MusicLab:ChangeVolume", quanti, plate)
	end
end

function firstToUpper(str)
	return (str:gsub("^%l", string.upper))
end

function SetUrl(url,nid)
	local nome = nid
	if xSound:soundExists(nome) then
		if xSound:isLooped(nome) then
			datasoundinfo.loop = not xSound:isLooped(nome)
			TriggerServerEvent("MusicLab:ChangeLoop",nome,datasoundinfo.loop)
			if type(datasoundinfo.loop) ~= "table" then
				local loop = datasoundinfo.loop
				SendNUIMessage({
					action = "changeMusicLoop",
					loop = loop,
				})
			end
		end
		local newTime = xSound:getMaxDuration(nome)
			TriggerServerEvent("MusicLab:ChangePosition", newTime, nome)
			Citizen.Wait(500)
	end
	if url then
		local encontrad = false
		for i = 1, #Zones do
			local v = Zones[i]
			if v.name == nome then
				encontrad = true
			end
		end
		if encontrad then
			local vehdata = {}
			vehdata.name = nome
			vehdata.link = url
			vehdata.loop = datasoundinfo.loop
			if IsPedInAnyVehicle(PlayerPedId(), false) then
				vehdata.popo = NetworkGetNetworkIdFromEntity(GetVehiclePedIsIn(PlayerPedId(),false))
			end
			TriggerServerEvent("MusicLab:ModifyURL",vehdata)
		else
			if IsPedInAnyVehicle(PlayerPedId(), false) then
				local veh = GetVehiclePedIsIn(PlayerPedId(),false)
				local cordsveh = GetEntityCoords(veh)
				local netid = NetworkGetNetworkIdFromEntity(veh)
				local vehdata = {}
				vehdata.plate = nome
				vehdata.coords = cordsveh
				vehdata.link = url
				vehdata.popo = netid
				vehdata.volume = datasoundinfo.volume
				vehdata.loop = datasoundinfo.loop
				TriggerServerEvent("MusicLab:AddVehicle",vehdata)
			end
		end
	else
	
	end
	SendNUIMessage({
		action = "TimeVid",
	})
	if xSound:soundExists(nome) then
		SendNUIMessage({
			action = "TimeVid",
			total = xSound:getMaxDuration(nome),
			played = xSound:getTimeStamp(nome),
		})
	end
	local esperar = 0
	while nuiaberto do
		Wait(1000)
		if xSound:soundExists(nome) then
			if xSound:isPlaying(nome) then
				SendNUIMessage({
					action = "TimeVid",
					total = xSound:getMaxDuration(nome),
					played = xSound:getTimeStamp(nome),
				})
			else
				esperar = esperar +1
			end
		else
			esperar = esperar +1
		end
		if esperar >= 4 then
			break
		end
	end
end

local function toggleNuiFrame(shouldShow)
  SetNuiFocus(shouldShow, shouldShow)
  SendReactMessage('setVisible', shouldShow)
end

RegisterNetEvent("Music:ShowNui")
AddEventHandler("Music:ShowNui", function()
  show()
end)

local shown = false

RegisterNUICallback('hideFrame', function(_, cb)
  toggleNuiFrame(false)
	shown = false
	nuiaberto = false
	nomidaberto = nil
  debugPrint('Hide NUI frame')
  cb({})
end)

function show(nomecenas)
	shown = not shown
	local nome = nomecenas
	if IsPedInAnyVehicle(PlayerPedId(), false) then
		local veh = GetVehiclePedIsIn(PlayerPedId(),false)
		local plate = GetVehicleNumberPlateText(veh)
		nome = plate
	end
    if shown and nome then
		nuiaberto = true
		datasoundinfo = {volume = 0.2, loop = false}
		local linkurl = nil
		if xSound:soundExists(nome) then
			datasoundinfo.loop = xSound:isLooped(nome)
			if xSound:isPlaying(nome) then
				datasoundinfo.volume = xSound:getVolume(nome)
				linkurl = xSound:getLink(nome)
			end
		end
		SendNUIMessage({
			action = "changevidname",
			text = linkurl,
		})
			toggleNuiFrame(true)
		local volume = (datasoundinfo.volume*100)
		if type(datasoundinfo.loop) ~= "table" then
			local loop = datasoundinfo.loop
			SendNUIMessage({
				action = "changeMusicLoop",
				loop = loop,
			})
		end
		SendNUIMessage({
			action = "changeMusicVolume",
			volume = volume,
		})
		SendNUIMessage({
			action = "TimeVid",
			total = 0,
			played = 0,
		})
		if xSound:soundExists(nome) then
			SendNUIMessage({
				action = "TimeVid",
				total = xSound:getMaxDuration(nome),
				played = xSound:getTimeStamp(nome),
			})
		end
		local esperar = 0
		while nuiaberto do
			Wait(1000)
			if xSound:soundExists(nome) then
				if xSound:isPlaying(nome) and show then
					SendNUIMessage({
						action = "TimeVid",
						total = xSound:getMaxDuration(nome),
						played = xSound:getTimeStamp(nome),
					})
				else
					esperar = esperar +1
				end
			else
				esperar = esperar +1
			end
			if esperar >= 4 then
				break
			end
		end
    elseif nuiaberto then
		nomidaberto = nil
		nuiaberto = false
			toggleNuiFrame(false)
    else
		TriggerEvent("Notify", "negado", "Você não pode fazer isso agora",5000)
	end
end

Zones = {}

RegisterNetEvent("MusicLab:AddVehicle")
AddEventHandler("MusicLab:AddVehicle", function(data)
	table.insert(Zones, data)
	local v = data
	if xSound:soundExists(v.name) then
		xSound:Destroy(v.name)
	end
	local avancartodos = v.volume
	if not Config.PlayToEveryone and v.popo then
		avancartodos = 0.0
		local popodentro = GetVehiclePedIsIn(PlayerPedId(),false)
		local plate = GetVehicleNumberPlateText(popodentro)
		if plate == v.name then
			avancartodos = v.volume
		end
	end
	xSound:PlayUrlPos(v.name, v.deflink, avancartodos, v.coords, v.loop,{
		onPlayStart = function(event)
			xSound:setTimeStamp(v.name, v.deftime)
			xSound:Distance(v.name,v.range)
		end,
	})
	table.insert(SoundsPlaying, #Zones)
	StartMusicLoop(#Zones)
end)

RegisterNetEvent("MusicLab:ModifyURL")
AddEventHandler("MusicLab:ModifyURL", function(data)
	local v = data
	local avancartodos = v.volume
	if not Config.PlayToEveryone and v.popo then
		avancartodos = 0.0
		local popodentro = GetVehiclePedIsIn(PlayerPedId(),false)
		local plate = GetVehicleNumberPlateText(popodentro)
		if plate == v.name then
			avancartodos = v.volume
		end
	end
	if xSound:soundExists(v.name) then
		if not xSound:isDynamic(v.name) then
			xSound:setSoundDynamic(v.name,true)
		end
		Wait(100)
		xSound:setVolumeMax(v.name,0.0)
		xSound:setSoundURL(v.name, v.deflink)
		Wait(100)
		xSound:Position(v.name, v.coords)
		xSound:setSoundLoop(v.name,v.loop)
		Wait(200)
		xSound:setTimeStamp(v.name,0)
		xSound:setVolumeMax(v.name,avancartodos)
									 
	else
		xSound:PlayUrlPos(v.name, v.deflink, avancartodos, v.coords, v.loop, {
			onPlayStart = function(event)
				xSound:setTimeStamp(v.name, v.deftime)
				xSound:Distance(v.name,v.range)
			end,
		})
	end
	local iss = nil
	for i = 1, #Zones do
		local b = Zones[i]
		if v.name == b.name then
			if b.popo then
				iss = i
			end
			b.deflink = v.deflink
			b.deftime = 0
			b.isplaying = v.isplaying
			b.loop = v.loop
			if v.popo then
				b.popo = v.popo
			end
		end
	end
	local encontrads = false
	for i = 1, #SoundsPlaying do
		local v = SoundsPlaying[i]
		if v == iss then
			encontrads = true
		end
	end
	local esperar = 0
	while nuiaberto do
		Wait(1000)
		if xSound:soundExists(v.name) then
			local pped = PlayerPedId()
			local coordss = GetEntityCoords(pped)
			local geraldist = #(coordss-xSound:getPosition(v.name))
			if xSound:isPlaying(v.name) and (geraldist <= 3 or not v.popo) then
				SendNUIMessage({
					action = "TimeVid",
					total = xSound:getMaxDuration(v.name),
					played = xSound:getTimeStamp(v.name),
				})
			else
				esperar = esperar +1
			end
		else
			esperar = esperar +1
		end
		if esperar >= 4 then
			break
		end
	end
	if not encontrads and iss then
		table.insert(SoundsPlaying, iss)
		StartMusicLoop(iss)
	end
end)

RegisterNetEvent("MusicLab:searchMusicResult")
AddEventHandler("MusicLab:searchMusicResult", function(data)
	SendNUIMessage({
		action = "resSearchMusic",
		searchList = data
	})
end)

RegisterNetEvent("MusicLab:receiveAllPlaylists")
AddEventHandler("MusicLab:receiveAllPlaylists", function(data)
	SendNUIMessage({
		action = "resPlaylists",
		playlist = data
	})
end)

RegisterNetEvent("MusicLab:showBannerInfo")
AddEventHandler("MusicLab:showBannerInfo", function(data)
	SendNUIMessage({
		action = "resBanner",
		bannerInfo = data
	})
end)

RegisterNetEvent("MusicLab:showHistory")
AddEventHandler("MusicLab:showHistory", function(data)
	SendNUIMessage({
		action = "resHistory",
		listLike = data
	})
end)

RegisterNetEvent("MusicLab:showLikeList")
AddEventHandler("MusicLab:showLikeList", function(data)
	SendNUIMessage({
		action = "resLikeList",
		listLike = data
	})
end)

RegisterNetEvent("MusicLab:showFooterLike")
AddEventHandler("MusicLab:showFooterLike", function(data)
	SendNUIMessage({
		action = "footerLike",
		value = data
	})
end)

RegisterNetEvent("MusicLab:showRemLike")
AddEventHandler("MusicLab:showRemLike", function(url_id)
	SendNUIMessage({
		action = "remLikeMusic",
		url_id = url_id
	})
end)

RegisterNetEvent("MusicLab:showLike")
AddEventHandler("MusicLab:showLike", function(url_id)
	SendNUIMessage({
		action = "showLikeMusic",
		url_id = url_id
	})
end)

RegisterNetEvent("MusicLab:ChangeState")
AddEventHandler("MusicLab:ChangeState", function(tipo, nome)
	if tipo and xSound:soundExists(nome) then
		xSound:Resume(nome)
	elseif xSound:soundExists(nome) then
		xSound:Pause(nome)
	end
	local iss = nil
	for i = 1, #Zones do
		local v = Zones[i]
		if v.name == nome then
			if v.popo then
				iss = i
			end
			v.isplaying = tipo
		end
	end
	if tipo and iss then
		table.insert(SoundsPlaying, iss)
		StartMusicLoop(iss)
	elseif iss then
		for i = 1, #SoundsPlaying do
			local v = SoundsPlaying[i]
			if v == iss then
				table.remove(SoundsPlaying, i)
			end
		end
	end
end)

RegisterNetEvent("MusicLab:NewTimeMusic")
AddEventHandler("MusicLab:NewTimeMusic", function(quanti, nome)
	local tempapply
	for i = 1, #Zones do
		local v = Zones[i]
		if v.name == nome then
			v.deftime = quanti
			if v.deftime < 0 then
				v.deftime = 0
			end
			tempapply = v.deftime
		end
	end
	if xSound:soundExists(nome) then
		xSound:setTimeStamp(nome,tempapply)
	end
end)

RegisterNetEvent("MusicLab:setNewMuisic")
AddEventHandler("MusicLab:setNewMuisic", function(quanti, nome, link)
	local tempapply
	for i = 1, #Zones do
		local v = Zones[i]
		if v.name == nome then
			v.deftime = quanti
			if v.deftime < 0 then
				v.deftime = 0
			end
			tempapply = v.deftime
		end
	end
	if xSound:soundExists(nome) then
		xSound:setTimeStamp(nome,tempapply)
		
		SendNUIMessage({
			action = "changevidname",
			text = link,
		})

		SetUrl(link, nome)
	end
end)

RegisterNetEvent("MusicLab:ChangeLoop")
AddEventHandler("MusicLab:ChangeLoop", function(tipo, nome)
	if xSound:soundExists(nome) then
		xSound:setSoundLoop(nome,tipo)
	end
	for i = 1, #Zones do
		local v = Zones[i]
		if v.name == nome then
			v.loop = tipo
		end
	end
end)

RegisterNetEvent("MusicLab:ChangeVolume")
AddEventHandler("MusicLab:ChangeVolume", function(som, range, nome)
	local carroe
	local crds
    for i = 1, #Zones do
        local v = Zones[i]
        if nome == v.name then
            v.volume = som
            v.range = range
			carroe = v.popo
			crds = v.coords
        end
    end
	if xSound:soundExists(nome) then
		xSound:Distance(nome,range)
		if not carroe and crds then
			xSound:setVolumeMax(nome,som)
		end
	end
end)

function countTime()
    SetTimeout(2000, countTime)
    for i = 1, #Zones do
		local v = Zones[i]
		if v.isplaying then
			v.deftime = v.deftime + 2
		end
    end
end

SetTimeout(2000, countTime)

RegisterNetEvent("MusicLab:SendData")
AddEventHandler("MusicLab:SendData", function(data)
    Zones = data
    for i = 1, #Zones do
		local v = Zones[i]
		if v.isplaying then
			if xSound:soundExists(v.name) then
				xSound:Destroy(v.name)
			end
			local avancartodos = v.volume
			if not Config.PlayToEveryone and v.popo then
				avancartodos = 0.0
				local popodentro = GetVehiclePedIsIn(PlayerPedId(),false)
				local plate = GetVehicleNumberPlateText(popodentro)
				if plate == v.name then
					avancartodos = v.volume
				end
			end
			xSound:PlayUrlPos(v.name, v.deflink, avancartodos, v.coords, v.loop,
			{
				onPlayStart = function(event)
					xSound:setTimeStamp(v.name, v.deftime)
					xSound:Distance(v.name,v.range)
				end,
			})
			if v.popo then
				table.insert(SoundsPlaying, i)
				StartMusicLoop(i)
			end
		end
    end
end)

local plpedloop
local pploop
local coordsped

Citizen.CreateThread(function()
	local poschanged = true
	while true do
		Wait(500)
		plpedloop = PlayerPedId()
		pploop = GetVehiclePedIsIn(plpedloop,false)
		coordsped = GetEntityCoords(plpedloop)
	end
end)

function StartMusicLoop(i)
	while not xSound:soundExists(Zones[i].name) do
		Wait(10)
	end
	Citizen.CreateThread(function()
		local poschanged = true
		while true do
			local sleep = 100
			local v = Zones[i]
			if v == nil then
				return
			end
			if v.isplaying and xSound:soundExists(v.name) then
				local carrofound = false
				if NetworkDoesEntityExistWithNetworkId(v.popo)then
					local carro = NetworkGetEntityFromNetworkId(v.popo)
					if GetEntityType(carro) == 2 then
						if GetVehicleNumberPlateText(carro) == v.name then
							carrofound = true
							local cordsveh = GetEntityCoords(carro)
							local geraldist = #(cordsveh-coordsped)
							if geraldist <= v.range+50 then
								local avolume = xSound:getVolume(v.name)
								local dina = xSound:isDynamic(v.name)
								local getpos = v.coords
								local getposdif = #(getpos-cordsveh)
								if avolume <= 0.001 then
									sleep = 1000
								end
								if pploop == carro then
									if dina then
										xSound:setSoundDynamic(v.name,false)
									end
									if avolume ~= v.volume then
										xSound:setVolume(v.name,v.volume)
									end
									if getposdif >= 5.0 or poschanged then
										poschanged = false
										v.coords = cordsveh
										xSound:Position(v.name, cordsveh)
									else
										sleep = sleep+150
									end
								else	
									if not dina then
										xSound:setSoundDynamic(v.name,true)
									end
									if avolume ~= v.volume then
										xSound:setVolumeMax(v.name,v.volume)
									end
									if geraldist >= v.range+20 then
										sleep = (geraldist*100)/3
									end
									if sleep <= 10000 then
										local speedcar = GetEntitySpeed(carro)*3.6
										if speedcar <= 2.0 then
											sleep = sleep+2500
										elseif speedcar <= 5.0 then
											sleep = sleep+1000
										elseif speedcar <= 10.0 then
											sleep = sleep+100
										end
									end
									if getposdif >= 1.0 or poschanged then
										poschanged = false
										v.coords = cordsveh
										xSound:Position(v.name, cordsveh)
									else
										sleep = sleep+150
									end
								end
							else
								if not xSound:isDynamic(v.name) then
									xSound:setSoundDynamic(v.name,true)
								end
								xSound:setVolumeMax(v.name,0.0)
								if not poschanged then
									xSound:Position(v.name, vector3(350.0,0.0,-150.0))
									poschanged = true
								end
								sleep = (geraldist*100)/2
							end
						end
					end
				end
				if not carrofound then
					if not xSound:isDynamic(v.name) then
						xSound:setSoundDynamic(v.name,true)
					end
					--xSound:setVolumeMax(v.name,0.0)
					if not poschanged then
						xSound:Position(v.name, vector3(350.0,0.0,-150.0))
						poschanged = true
					end
					Wait(5000)
				end
			else
				if xSound:soundExists(v.name) then
					if not xSound:isDynamic(v.name) then
						xSound:setSoundDynamic(v.name,true)
					end
					xSound:setVolumeMax(v.name,0.0)
					if not poschanged then
						xSound:Position(v.name, vector3(350.0,0.0,-150.0))
						poschanged = true
					end
				end
				v.isplaying = false
				for j = 1, #SoundsPlaying do
					local k = SoundsPlaying[j]
					if k == i then
						table.remove(SoundsPlaying, j)
					end
				end
				break
			end
			if sleep > 10000 then
				sleep = 10000
			end
			Wait(sleep)
		end
	end)
end

Citizen.CreateThread(function()
	while true do
		local sleep = 2000
		local coords = GetEntityCoords(GetPlayerPed(math.floor(-1.0)))
		for i = 1, #Config.Zones do
			local v = Config.Zones[i]
			local distance = #(coords - v.changemusicblip)
			if distance <= 10 then
				sleep = 500
				if distance <= 3 then
					sleep = 5
					DrawText3D(v.changemusicblip.x, v.changemusicblip.y, v.changemusicblip.z, "[~y~E~w~] - Trocar música")
					if IsControlJustReleased(math.floor(0.0), math.floor(38.0)) then
						nomidaberto = v.name
						show(v.name)
						Wait(1000)
					end
				end
			end
		end
		Wait(sleep)
	end
end)

function DrawText3D(x, y, z, text,r,g,b,a)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)
	SetTextFont(math.floor(4.0))
	SetTextScale(0.35,0.35)
	SetTextColour(math.floor(255.0),math.floor(255.0),math.floor(255.0),math.floor(150.0))
	SetTextEntry("STRING")
	SetTextCentre(math.floor(1.0))
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text)) / math.floor(400.0)
	DrawRect(_x,_y+0.0125,0.01+factor,0.03,math.floor(50.0),math.floor(56.0),math.floor(73.0),math.floor(200.0))
end