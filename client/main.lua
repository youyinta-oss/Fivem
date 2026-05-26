ESX = exports['es_extended']:getSharedObject()

local isUIOpen = false

RegisterNetEvent('gift_system:openUI')
AddEventHandler('gift_system:openUI', function()
    OpenUI()
end)

RegisterNetEvent('gift_system:openAdminUI')
AddEventHandler('gift_system:openAdminUI', function()
    OpenAdminUI()
end)

RegisterNetEvent('gift_system:notification')
AddEventHandler('gift_system:notification', function(message)
    ESX.ShowNotification(message)
end)

RegisterNetEvent('gift_system:newRedPacket')
AddEventHandler('gift_system:newRedPacket', function(packet)
    ESX.ShowNotification('有新的红包可以抢！')
end)

RegisterCommand('gift', function()
    OpenUI()
end, false)

RegisterCommand('giftadmin', function()
    OpenAdminUI()
end, true)

function OpenUI()
    if isUIOpen then return end
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openUI',
        config = Config
    })
    isUIOpen = true
end

function OpenAdminUI()
    if isUIOpen then return end
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openAdminUI',
        config = Config
    })
    isUIOpen = true
end

RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    isUIOpen = false
    cb('ok')
end)

RegisterNUICallback('getPlayers', function(data, cb)
    ESX.TriggerServerCallback('gift_system:getPlayers', function(players)
        cb(players)
    end)
end)

RegisterNUICallback('sendGift', function(data, cb)
    ESX.TriggerServerCallback('gift_system:sendGift', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('createRedPacket', function(data, cb)
    ESX.TriggerServerCallback('gift_system:createRedPacket', function(result)
        cb(result)
    end, data)
end)

RegisterNUICallback('getActiveRedPackets', function(data, cb)
    ESX.TriggerServerCallback('gift_system:getActiveRedPackets', function(packets)
        cb(packets)
    end)
end)

RegisterNUICallback('openRedPacket', function(data, cb)
    ESX.TriggerServerCallback('gift_system:openRedPacket', function(result)
        cb(result)
    end, data.packetId)
end)

RegisterNUICallback('getPlayerHistory', function(data, cb)
    ESX.TriggerServerCallback('gift_system:getPlayerHistory', function(history)
        cb(history)
    end, data.limit)
end)

RegisterNUICallback('getRedPacketRecords', function(data, cb)
    ESX.TriggerServerCallback('gift_system:getRedPacketRecords', function(records)
        cb(records)
    end, data.packetId)
end)

RegisterNUICallback('getAllGifts', function(data, cb)
    ESX.TriggerServerCallback('gift_system:getAllGifts', function(gifts)
        cb(gifts)
    end)
end)

RegisterNUICallback('getAllRedPackets', function(data, cb)
    ESX.TriggerServerCallback('gift_system:getAllRedPackets', function(packets)
        cb(packets)
    end)
end)
