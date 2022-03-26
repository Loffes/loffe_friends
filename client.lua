local identifier
local friends = {}
local nearbyFriends = {}

CreateThread(function()
    while not NetworkIsSessionStarted() do 
        Wait(500) 
    end

    if Config.Framework == "esx" then
        local ESX
        while not ESX do 
            TriggerEvent("esx:getSharedObject", function(obj) 
                ESX = obj 
            end)
            Wait(500)
        end
        while not ESX.GetPlayerData() or not ESX.GetPlayerData().job do
            Wait(500)
        end

        ESX.UI.HUD.SetDisplay(0.0)
    end

    lib = exports.loaf_lib:GetLib()

    if Config.Command then
        RegisterCommand(Config.Command, OpenNUI)
    end

    identifier = lib.TriggerCallbackSync("loffe_friends:get_identifier")

    for _, v in pairs(lib.TriggerCallbackSync("loffe_friends:get_friends")) do
        local id, name
        if v.identifier_1 == identifier then
            id = v.identifier_2
            name = v.name_2
        else
            id = v.identifier_1
            name = v.name_1
        end
        friends[id] = name
        SendNUIMessage({
            message = "add",
            friend = {
                id = id,
                name = name,
                date = v.date
            }
        })
    end

    for _, v in pairs(lib.TriggerCallbackSync("loffe_friends:get_sent")) do
        SendNUIMessage({
            message = "add",
            sentRequest = {
                id = v.sent_to,
                name = v.sent_to_name
            }
        })
    end

    for _, v in pairs(lib.TriggerCallbackSync("loffe_friends:get_requests")) do
        SendNUIMessage({
            message = "add",
            request = {
                id = v.sender,
                name = v.sender_name
            }
        })
    end

    while true do
        Wait(500)
        local nearby = {}
        for _, player in pairs(GetActivePlayers()) do
            if player == PlayerId() then
                goto continue
            end

            local src = GetPlayerServerId(player)
            local plyIdentifier = Player(src).state.identifier
            if not plyIdentifier or not friends[plyIdentifier] or #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(GetPlayerPed(player))) > 15.0 then
                goto continue
            end

            BeginTextCommandGetWidth("STRING")
            AddTextComponentSubstringPlayerName(friends[plyIdentifier])
            SetTextScale(0.35, 0.35)
            SetTextFont(4)

            table.insert(nearby, {
                ped = GetPlayerPed(player),
                name = friends[plyIdentifier],
                width = EndTextCommandGetWidth(1) + 0.0015,
                height = GetRenderedCharacterHeight(0.35, 4) * 1.2
            })
            
            ::continue::
        end
        nearbyFriends = nearby
        collectgarbage()
    end
end)

CreateThread(function()
    while true do
        Wait(0)

        if #nearbyFriends == 0 then
            Wait(500)
        end

        local selfCoords = GetEntityCoords(PlayerPedId())
        for _, v in pairs(nearbyFriends) do
            local boneCoords = GetPedBoneCoords(v.ped, 12844, 0.3, 0.0, 0.0)
            if #(boneCoords - selfCoords) <= 7.5 then
                SetDrawOrigin(boneCoords.x, boneCoords.y, boneCoords.z)

                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(v.name)
                SetTextScale(0.35, 0.35)
                SetTextCentre(1)
                SetTextFont(4)
                EndTextCommandDisplayText(0.0, 0.0)
            
                DrawRect(0.0, v.height/2, v.width, v.height, 45, 45, 45, 150)
            
                ClearDrawOrigin()
            end
        end
    end
end)

-- NUI CALLBACKS
local isOpen

function OpenNUI()
    isOpen = true
    TriggerScreenblurFadeIn(0)
    SetNuiFocus(true, true)
    SendNUIMessage({
        message = "open"
    })
end

function CloseNUI()
    isOpen = false
    SendNUIMessage({
        message = "close"
    })
    SetNuiFocus(false, false)
    TriggerScreenblurFadeOut(0)
end

RegisterNUICallback("close", CloseNUI)

RegisterNetEvent("loffe_friends:received_request", function(sender, name)
    SendNUIMessage({
        message = "add",
        request = {
            id = sender,
            name = name
        }
    })
end)

-- ADD FRIEND
RegisterNUICallback("send_request", function(id, cb)
    lib.TriggerCallback("loffe_friends:send_request", function(sent, name, id)
        cb({
            added = sent,
            name = name,
            id = id
        })
    end, id)
end)

RegisterNUICallback("cancel_request", function(id, cb)
    lib.TriggerCallback("loffe_friends:cancel_request", function(cancelled)
        cb(cancelled)
    end, id)
end)

RegisterNetEvent("loffe_friends:remove_sent", function(id)
    SendNUIMessage({
        message = "remove",
        sentRequest = id
    })
end)

-- FRIEND REQUESTS
RegisterNUICallback("accept_request", function(id, cb)
    lib.TriggerCallback("loffe_friends:accept_request", function(accepted)
        cb(accepted)
    end, id)
end)

RegisterNUICallback("deny_request", function(id, cb)
    lib.TriggerCallback("loffe_friends:deny_request", function(denied)
        cb(denied)
    end, id)
end)

RegisterNetEvent("loffe_friends:remove_request", function(id)
    SendNUIMessage({
        message = "remove",
        request = id
    })
end)

-- FRIENDLIST
RegisterNUICallback("remove_friend", function(id, cb)
    lib.TriggerCallback("loffe_friends:remove_friend", function(accepted)
        if accepted then
            friends[id] = nil
        end
        cb(accepted)
    end, id)
end)

RegisterNetEvent("loffe_friends:remove_friend", function(id)
    friends[id] = nil
    SendNUIMessage({
        message = "remove",
        friend = id
    })
end)

RegisterNetEvent("loffe_friends:add_friend", function(id, name, date)
    friends[id] = name
    SendNUIMessage({
        message = "add",
        friend = {
            id = id,
            name = name,
            date = date
        }
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and isOpen then
        SetNuiFocus(true, true)
        TriggerScreenblurFadeOut(0)
    end
end)