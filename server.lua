local lib = exports.loaf_lib:GetLib()

if Config.Framework == "esx" then
    local ESX
    TriggerEvent("esx:getSharedObject", function(esx)
        ESX = esx
    end)

    function GetIdentifier(source)
        return ESX.GetPlayerFromId(source)?.identifier
    end

    function GetPlayerFromIdentifier(identifier)
        return ESX.GetPlayerFromIdentifier(identifier)?.source
    end

    function GetName(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        local firstName, lastName
        if xPlayer.get and xPlayer.get("firstName") and xPlayer.get("lastName") then
            firstName = xPlayer.get("firstName")
            lastName = xPlayer.get("lastName")
        else
            local name = MySQL.Sync.fetchAll("SELECT `firstname`, `lastname` FROM `users` WHERE `identifier`=@identifier", {["@identifier"] = GetIdentifier(source)})
            firstName, lastName = name[1]?.firstname or GetPlayerName(source), name[1]?.lastname or ""
        end

        return ("%s %s"):format(firstName, lastName)
    end
end

lib.RegisterCallback("loffe_friends:get_identifier", function(source, cb)
    Player(source).state.identifier = GetIdentifier(source)
    cb(GetIdentifier(source))
end)

lib.RegisterCallback("loffe_friends:get_friends", function(source, cb)
    MySQL.Async.fetchAll("SELECT * FROM `friends` WHERE `identifier_1`=@identifier OR `identifier_2`=@identifier", {
        ["@identifier"] = GetIdentifier(source)
    }, cb)
end)

lib.RegisterCallback("loffe_friends:get_sent", function(source, cb)
    MySQL.Async.fetchAll("SELECT * FROM `friend_requests` WHERE `sender`=@identifier", {
        ["@identifier"] = GetIdentifier(source)
    }, cb)
end)

lib.RegisterCallback("loffe_friends:get_requests", function(source, cb)
    MySQL.Async.fetchAll("SELECT * FROM `friend_requests` WHERE `sent_to`=@identifier", {
        ["@identifier"] = GetIdentifier(source)
    }, cb)
end)

lib.RegisterCallback("loffe_friends:send_request", function(source, cb, id)
    if not GetPlayerName(id) or source == id then
        return false
    end

    local name, identifier = GetName(id), GetIdentifier(id)
    if not name or not identifier then
        return cb(false)
    end

    MySQL.Async.fetchScalar("SELECT `date` FROM `friends` WHERE (`identifier_1`=@identifier1 AND `identifier_2`=@identifier2) OR (`identifier_1`=@identifier2 AND `identifier_2`=@identifier1)", {
        ["@identifier1"] = identifier,
        ["@identifier2"] = GetIdentifier(source)
    }, function(res)
        if res then
            return cb(false)
        end
        
        MySQL.Async.fetchScalar("SELECT `sender` FROM `friend_requests` WHERE (`sender`=@identifier1 AND `sent_to`=@identifier2) OR (`sender`=@identifier2 AND `sent_to`=@identifier1)", {
            ["@identifier1"] = identifier,
            ["@identifier2"] = GetIdentifier(source)
        }, function(res)
            if res then
                return cb(false)
            end

            MySQL.Async.execute("INSERT INTO `friend_requests` (`sender`, `sent_to`, `sender_name`, `sent_to_name`) VALUES (@sender, @sent_to, @sender_name, @sent_to_name)", {
                ["@sender"] = GetIdentifier(source),
                ["@sent_to"] = identifier,
                ["@sender_name"] = GetName(source),
                ["@sent_to_name"] = name
            }, function()
                TriggerClientEvent("loffe_friends:received_request", id, GetIdentifier(source), GetName(source))
                cb(true, name, identifier)
            end)
        end)
    end)
end)

lib.RegisterCallback("loffe_friends:cancel_request", function(source, cb, identifier)
    local selfIdentifier = GetIdentifier(source)
    MySQL.Async.fetchScalar("SELECT `sent_to` FROM `friend_requests` WHERE `sender`=@selfIdentifier AND `sent_to`=@otherIdentifier", {
        ["@selfIdentifier"] = selfIdentifier,
        ["@otherIdentifier"] = identifier
    }, function(res)
        if not res then
            return cb(false)
        end
        
        MySQL.Async.execute("DELETE FROM `friend_requests` WHERE `sender`=@selfIdentifier AND `sent_to`=@otherIdentifier", {
            ["@selfIdentifier"] = selfIdentifier,
            ["@otherIdentifier"] = identifier
        })

        local sentSrc = GetPlayerFromIdentifier(res)
        if sentSrc then
            TriggerClientEvent("loffe_friends:remove_request", sentSrc, selfIdentifier)
        end

        cb(true)
    end)
end)

lib.RegisterCallback("loffe_friends:accept_request", function(source, cb, identifier)
    local selfIdentifier = GetIdentifier(source)
    MySQL.Async.fetchAll("SELECT `sender`, `sent_to`, `sender_name`, `sent_to_name` FROM `friend_requests` WHERE `sender`=@otherIdentifier AND `sent_to`=@selfIdentifier", {
        ["@selfIdentifier"] = selfIdentifier,
        ["@otherIdentifier"] = identifier
    }, function(res)
        if not res or not res[1] then
            return cb(false)
        end

        MySQL.Async.execute("DELETE FROM `friend_requests` WHERE `sender`=@otherIdentifier AND `sent_to`=@selfIdentifier", {
            ["@selfIdentifier"] = selfIdentifier,
            ["@otherIdentifier"] = identifier
        })

        MySQL.Async.execute("INSERT INTO `friends` (`identifier_1`, `identifier_2`, `name_1`, `name_2`) VALUES (@selfIdentifier, @otherIdentifier, @selfName, @otherName)", {
            ["@selfIdentifier"] = selfIdentifier,
            ["@otherIdentifier"] = identifier,
            ["@selfName"] = res[1].sent_to_name,
            ["@otherName"] = res[1].sender_name
        })

        local senderSrc = GetPlayerFromIdentifier(res[1].sender)
        if senderSrc then
            TriggerClientEvent("loffe_friends:remove_sent", senderSrc, selfIdentifier)

            TriggerClientEvent("loffe_friends:add_friend", senderSrc, res[1].sent_to, res[1].sent_to_name, os.time() * 1000)
        end

        TriggerClientEvent("loffe_friends:add_friend", source, res[1].sender, res[1].sender_name, os.time() * 1000)

        cb(true)
    end)
end)

lib.RegisterCallback("loffe_friends:deny_request", function(source, cb, identifier)
    local selfIdentifier = GetIdentifier(source)
    MySQL.Async.fetchAll("SELECT `sender`, `sent_to` FROM `friend_requests` WHERE `sender`=@otherIdentifier AND `sent_to`=@selfIdentifier", {
        ["@selfIdentifier"] = selfIdentifier,
        ["@otherIdentifier"] = identifier
    }, function(res)
        if not res or not res[1] then
            return cb(false)
        end

        MySQL.Async.execute("DELETE FROM `friend_requests` WHERE `sender`=@otherIdentifier AND `sent_to`=@selfIdentifier", {
            ["@selfIdentifier"] = selfIdentifier,
            ["@otherIdentifier"] = identifier
        })

        local senderSrc = GetPlayerFromIdentifier(res[1].sender)
        if senderSrc then
            TriggerClientEvent("loffe_friends:remove_sent", senderSrc, selfIdentifier)
        end
        cb(true)
    end)
end)

lib.RegisterCallback("loffe_friends:remove_friend", function(source, cb, identifier)
    local selfIdentifier = GetIdentifier(source)
    MySQL.Async.fetchAll("SELECT * FROM `friends` WHERE (`identifier_1`=@identifier1 AND `identifier_2`=@identifier2) OR (`identifier_1`=@identifier2 AND `identifier_2`=@identifier1)", {
        ["@identifier1"] = selfIdentifier,
        ["@identifier2"] = identifier
    }, function(res)
        if not res or not res[1] then
            return cb(false)
        end

        local data = res[1]
        local otherSrc
        if data.identifier_1 == selfIdentifier then
            otherSrc = GetPlayerFromIdentifier(data.identifier_2)
        else
            otherSrc = GetPlayerFromIdentifier(data.identifier_1)
        end
        if otherSrc then
            TriggerClientEvent("loffe_friends:remove_friend", otherSrc, selfIdentifier)
        end

        MySQL.Async.execute("DELETE FROM `friends` WHERE (`identifier_1`=@identifier1 AND `identifier_2`=@identifier2) OR (`identifier_1`=@identifier2 AND `identifier_2`=@identifier1)", {
            ["@identifier1"] = selfIdentifier,
            ["@identifier2"] = identifier
        })
        cb(true)
    end)
end)