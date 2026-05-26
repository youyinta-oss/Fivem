ESX = exports['es_extended']:getSharedObject()

local activeRedPackets = {}
local Database = {}
local GiftSystem = {}
local RedPacketSystem = {}

function LoadDatabase()
    local prefix = Config.Database.table_prefix

    function Database.Init()
        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `]] .. prefix .. [[gifts` (
                `id` INT NOT NULL AUTO_INCREMENT,
                `sender_identifier` VARCHAR(50) NOT NULL,
                `sender_name` VARCHAR(100) NOT NULL,
                `receiver_identifier` VARCHAR(50),
                `receiver_name` VARCHAR(100),
                `gift_type` VARCHAR(20) NOT NULL,
                `gift_data` TEXT NOT NULL,
                `message` TEXT,
                `is_global` TINYINT(1) DEFAULT 0,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])

        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `]] .. prefix .. [[redpackets` (
                `id` INT NOT NULL AUTO_INCREMENT,
                `creator_identifier` VARCHAR(50) NOT NULL,
                `creator_name` VARCHAR(100) NOT NULL,
                `packet_type` VARCHAR(20) NOT NULL,
                `packet_data` TEXT NOT NULL,
                `mode` VARCHAR(20) NOT NULL,
                `total_amount` INT NOT NULL,
                `count` INT NOT NULL,
                `opened_count` INT DEFAULT 0,
                `is_active` TINYINT(1) DEFAULT 1,
                `expires_at` TIMESTAMP,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])

        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `]] .. prefix .. [[redpacket_records` (
                `id` INT NOT NULL AUTO_INCREMENT,
                `redpacket_id` INT NOT NULL,
                `player_identifier` VARCHAR(50) NOT NULL,
                `player_name` VARCHAR(100) NOT NULL,
                `amount` INT NOT NULL,
                `opened_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                INDEX `idx_redpacket` (`redpacket_id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])

        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `]] .. prefix .. [[player_gifts` (
                `id` INT NOT NULL AUTO_INCREMENT,
                `gift_id` INT NOT NULL,
                `player_identifier` VARCHAR(50) NOT NULL,
                `player_name` VARCHAR(100) NOT NULL,
                `received_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                INDEX `idx_player` (`player_identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
    end

    function Database.CreateGift(senderId, senderName, receiverId, receiverName, giftType, giftData, message, isGlobal, callback)
        MySQL.Async.insert([[
            INSERT INTO `]] .. prefix .. [[gifts` 
            (sender_identifier, sender_name, receiver_identifier, receiver_name, gift_type, gift_data, message, is_global)
            VALUES (@senderId, @senderName, @receiverId, @receiverName, @giftType, @giftData, @message, @isGlobal)
        ]], {
            ['@senderId'] = senderId,
            ['@senderName'] = senderName,
            ['@receiverId'] = receiverId,
            ['@receiverName'] = receiverName,
            ['@giftType'] = giftType,
            ['@giftData'] = json.encode(giftData),
            ['@message'] = message,
            ['@isGlobal'] = isGlobal and 1 or 0
        }, function(insertId)
            if callback then callback(insertId) end
        end)
    end

    function Database.CreateRedPacket(creatorId, creatorName, packetType, packetData, mode, totalAmount, count, expiresAt, callback)
        MySQL.Async.insert([[
            INSERT INTO `]] .. prefix .. [[redpackets` 
            (creator_identifier, creator_name, packet_type, packet_data, mode, total_amount, count, expires_at)
            VALUES (@creatorId, @creatorName, @packetType, @packetData, @mode, @totalAmount, @count, @expiresAt)
        ]], {
            ['@creatorId'] = creatorId,
            ['@creatorName'] = creatorName,
            ['@packetType'] = packetType,
            ['@packetData'] = json.encode(packetData),
            ['@mode'] = mode,
            ['@totalAmount'] = totalAmount,
            ['@count'] = count,
            ['@expiresAt'] = expiresAt
        }, function(insertId)
            if callback then callback(insertId) end
        end)
    end

    function Database.GetActiveRedPackets(callback)
        MySQL.Async.fetchAll([[
            SELECT * FROM `]] .. prefix .. [[redpackets` 
            WHERE is_active = 1 AND (expires_at IS NULL OR expires_at > NOW())
        ]], {}, function(results)
            for _, v in ipairs(results) do
                v.packet_data = json.decode(v.packet_data)
            end
            if callback then callback(results) end
        end)
    end

    function Database.GetRedPacketById(id, callback)
        MySQL.Async.fetchAll([[
            SELECT * FROM `]] .. prefix .. [[redpackets` WHERE id = @id
        ]], { ['@id'] = id }, function(results)
            if #results > 0 then
                results[1].packet_data = json.decode(results[1].packet_data)
                if callback then callback(results[1]) end
            else
                if callback then callback(nil) end
            end
        end)
    end

    function Database.GetRedPacketRecords(packetId, callback)
        MySQL.Async.fetchAll([[
            SELECT * FROM `]] .. prefix .. [[redpacket_records` WHERE redpacket_id = @packetId
        ]], { ['@packetId'] = packetId }, function(results)
            if callback then callback(results) end
        end)
    end

    function Database.OpenRedPacket(packetId, playerId, playerName, amount, callback)
        MySQL.Async.insert([[
            INSERT INTO `]] .. prefix .. [[redpacket_records` 
            (redpacket_id, player_identifier, player_name, amount)
            VALUES (@packetId, @playerId, @playerName, @amount)
        ]], {
            ['@packetId'] = packetId,
            ['@playerId'] = playerId,
            ['@playerName'] = playerName,
            ['@amount'] = amount
        }, function(insertId)
            MySQL.Async.execute([[
                UPDATE `]] .. prefix .. [[redpackets` 
                SET opened_count = opened_count + 1, 
                    is_active = CASE WHEN opened_count + 1 >= count THEN 0 ELSE is_active END
                WHERE id = @packetId
            ]], { ['@packetId'] = packetId }, function()
                if callback then callback(insertId) end
            end)
        end)
    end

    function Database.HasPlayerOpenedRedPacket(packetId, playerId, callback)
        MySQL.Async.fetchScalar([[
            SELECT COUNT(*) FROM `]] .. prefix .. [[redpacket_records` 
            WHERE redpacket_id = @packetId AND player_identifier = @playerId
        ]], {
            ['@packetId'] = packetId,
            ['@playerId'] = playerId
        }, function(count)
            if callback then callback(count > 0) end
        end)
    end

    function Database.GetPlayerGiftHistory(identifier, limit, callback)
        MySQL.Async.fetchAll([[
            SELECT * FROM `]] .. prefix .. [[gifts` 
            WHERE receiver_identifier = @identifier OR is_global = 1
            ORDER BY created_at DESC LIMIT @limit
        ]], {
            ['@identifier'] = identifier,
            ['@limit'] = limit or 50
        }, function(results)
            for _, v in ipairs(results) do
                v.gift_data = json.decode(v.gift_data)
            end
            if callback then callback(results) end
        end)
    end

    function Database.GetAllGifts(callback)
        MySQL.Async.fetchAll([[
            SELECT * FROM `]] .. prefix .. [[gifts` ORDER BY created_at DESC
        ]], {}, function(results)
            for _, v in ipairs(results) do
                v.gift_data = json.decode(v.gift_data)
            end
            if callback then callback(results) end
        end)
    end

    function Database.GetAllRedPackets(callback)
        MySQL.Async.fetchAll([[
            SELECT * FROM `]] .. prefix .. [[redpackets` ORDER BY created_at DESC
        ]], {}, function(results)
            for _, v in ipairs(results) do
                v.packet_data = json.decode(v.packet_data)
            end
            if callback then callback(results) end
        end)
    end
end

function LoadGiftSystem()
    function GiftSystem.SendGift(senderId, senderName, targetType, targetId, targetName, giftType, giftData, message)
        local isGlobal = targetType == 'all'
        
        Database.CreateGift(
            senderId,
            senderName,
            not isGlobal and targetId or nil,
            not isGlobal and targetName or nil,
            giftType,
            giftData,
            message,
            isGlobal,
            function(giftId)
                if isGlobal then
                    GiftSystem.GiveGiftToAll(giftType, giftData, giftId)
                else
                    local xPlayer = ESX.GetPlayerFromIdentifier(targetId)
                    if xPlayer then
                        GiftSystem.GiveGiftToPlayer(xPlayer, giftType, giftData, giftId)
                        TriggerClientEvent('gift_system:notification', xPlayer.source, '你收到了来自 ' .. senderName .. ' 的礼物！')
                    end
                end
                TriggerClientEvent('gift_system:notification', -1, senderName .. ' 发送了' .. (isGlobal and '全服' or '给 ' .. targetName) .. '一份礼物！')
            end
        )
        
        return true, '礼物发送成功'
    end

    function GiftSystem.GiveGiftToPlayer(xPlayer, giftType, giftData, giftId)
        if giftType == 'item' then
            xPlayer.addInventoryItem(giftData.item, giftData.amount)
        elseif giftType == 'money' then
            xPlayer.addAccountMoney(giftData.account, giftData.amount)
        elseif giftType == 'weapon' then
            xPlayer.addWeapon(giftData.weapon, giftData.ammo or 1000)
        elseif giftType == 'vehicle' then
            local vehicleProps = giftData.props or {}
            local carplate = GeneratePlate()
            
            MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, stored, garage) VALUES (@owner, @plate, @vehicle, @stored, @garage)', {
                ['@owner'] = xPlayer.getIdentifier(),
                ['@plate'] = carplate,
                ['@vehicle'] = json.encode({model = GetHashKey(giftData.vehicle), plate = carplate}),
                ['@stored'] = 1,
                ['@garage'] = 'pillbox'
            }, function()
                TriggerClientEvent('gift_system:notification', xPlayer.source, '车辆已存到你的车库！')
            end)
        end
        
        MySQL.Async.execute('INSERT INTO `gift_system_player_gifts` (gift_id, player_identifier, player_name) VALUES (@giftId, @identifier, @name)', {
            ['@giftId'] = giftId,
            ['@identifier'] = xPlayer.getIdentifier(),
            ['@name'] = xPlayer.getName()
        })
    end

    function GiftSystem.GiveGiftToAll(giftType, giftData, giftId)
        local xPlayers = ESX.GetPlayers()
        for _, playerId in ipairs(xPlayers) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if xPlayer then
                GiftSystem.GiveGiftToPlayer(xPlayer, giftType, giftData, giftId)
            end
        end
    end
end

function LoadRedPacketSystem()
    function RedPacketSystem.CreateRedPacket(creatorId, creatorName, data)
        local expiresAt = nil
        if data.timeout then
            expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + data.timeout)
        end
        
        local totalAmount = data.totalAmount or data.count
        if data.mode == 'first_come' then
            totalAmount = (data.packetData.amount or 1) * data.count
        end
        
        local createdPacketId = 0
        Database.CreateRedPacket(
            creatorId,
            creatorName,
            data.packetType,
            data.packetData,
            data.mode,
            totalAmount,
            data.count,
            expiresAt,
            function(packetId)
                createdPacketId = packetId
            end
        )
        
        Wait(200)
        return true, '红包创建成功', createdPacketId
    end

    function RedPacketSystem.OpenRedPacket(packetId, playerId, playerName, xPlayer)
        local hasOpened = false
        Database.HasPlayerOpenedRedPacket(packetId, playerId, function(opened)
            hasOpened = opened
        end)
        
        Wait(100)
        
        if hasOpened then
            return false, '你已经抢过这个红包了', 0
        end
        
        local packet = nil
        Database.GetRedPacketById(packetId, function(result)
            packet = result
        end)
        
        Wait(100)
        
        if not packet then
            return false, '红包不存在', 0
        end
        
        if packet.opened_count >= packet.count then
            return false, '红包已被抢完', 0
        end
        
        local amount = RedPacketSystem.CalculateAmount(packet)
        
        RedPacketSystem.GiveRedPacketReward(xPlayer, packet.packet_type, packet.packet_data, amount)
        Database.OpenRedPacket(packetId, playerId, playerName, amount)
        
        TriggerClientEvent('gift_system:notification', -1, playerName .. ' 抢到了 ' .. amount .. '！')
        
        return true, '抢红包成功', amount
    end

    function RedPacketSystem.CalculateAmount(packet)
        local remaining = packet.count - packet.opened_count
        local remainingAmount = packet.total_amount
        
        Database.GetRedPacketRecords(packet.id, function(records)
            for _, record in ipairs(records) do
                remainingAmount = remainingAmount - record.amount
            end
        end)
        
        Wait(100)
        
        if packet.mode == 'equal' then
            return math.floor(remainingAmount / remaining)
        elseif packet.mode == 'first_come' then
            if packet.packet_type == 'item' or packet.packet_type == 'weapon' or packet.packet_type == 'vehicle' then
                return 1
            else
                return packet.packet_data.amount or 1
            end
        else
            if remaining == 1 then
                return remainingAmount
            end
            local max = math.floor(remainingAmount * 2 / remaining)
            return math.random(1, max)
        end
    end

    function RedPacketSystem.GiveRedPacketReward(xPlayer, packetType, packetData, amount)
        if packetType == 'item' then
            xPlayer.addInventoryItem(packetData.item, amount)
        elseif packetType == 'money' then
            xPlayer.addAccountMoney(packetData.account, amount)
        elseif packetType == 'weapon' then
            xPlayer.addWeapon(packetData.weapon, packetData.ammo or 1000)
        elseif packetType == 'vehicle' then
            local carplate = GeneratePlate()
            
            MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, stored, garage) VALUES (@owner, @plate, @vehicle, @stored, @garage)', {
                ['@owner'] = xPlayer.getIdentifier(),
                ['@plate'] = carplate,
                ['@vehicle'] = json.encode({model = GetHashKey(packetData.vehicle), plate = carplate}),
                ['@stored'] = 1,
                ['@garage'] = 'pillbox'
            }, function()
                TriggerClientEvent('gift_system:notification', xPlayer.source, '车辆已存到你的车库！')
            end)
        end
    end
end

function GeneratePlate()
    local plate = ''
    for i = 1, 8 do
        if i <= 4 then
            plate = plate .. string.char(math.random(65, 90))
        else
            plate = plate .. math.random(0, 9)
        end
    end
    return plate
end

function LoadActiveRedPackets()
    Database.GetActiveRedPackets(function(packets)
        activeRedPackets = {}
        for _, packet in ipairs(packets) do
            activeRedPackets[packet.id] = packet
        end
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    LoadDatabase()
    LoadGiftSystem()
    LoadRedPacketSystem()
    Database.Init()
    LoadActiveRedPackets()
end)

ESX.RegisterServerCallback('gift_system:getPlayers', function(source, cb)
    local xPlayers = ESX.GetPlayers()
    local players = {}
    for _, playerId in ipairs(xPlayers) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            table.insert(players, {
                id = playerId,
                identifier = xPlayer.getIdentifier(),
                name = xPlayer.getName()
            })
        end
    end
    cb(players)
end)

ESX.RegisterServerCallback('gift_system:sendGift', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({success = false, msg = '玩家不存在'}) return end

    local success, msg = GiftSystem.SendGift(
        xPlayer.getIdentifier(),
        xPlayer.getName(),
        data.targetType,
        data.targetId,
        data.targetName,
        data.giftType,
        data.giftData,
        data.message
    )

    cb({success = success, msg = msg})
end)

ESX.RegisterServerCallback('gift_system:createRedPacket', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({success = false, msg = '玩家不存在'}) return end

    local success, msg, packetId = RedPacketSystem.CreateRedPacket(
        xPlayer.getIdentifier(),
        xPlayer.getName(),
        data
    )

    if success and packetId then
        Database.GetRedPacketById(packetId, function(packet)
            if packet then
                activeRedPackets[packetId] = packet
                TriggerClientEvent('gift_system:newRedPacket', -1, packet)
            end
        end)
    end

    cb({success = success, msg = msg, packetId = packetId})
end)

ESX.RegisterServerCallback('gift_system:getActiveRedPackets', function(source, cb)
    local packets = {}
    for _, packet in pairs(activeRedPackets) do
        table.insert(packets, packet)
    end
    cb(packets)
end)

ESX.RegisterServerCallback('gift_system:openRedPacket', function(source, cb, packetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({success = false, msg = '玩家不存在'}) return end

    local success, msg, amount = RedPacketSystem.OpenRedPacket(
        packetId,
        xPlayer.getIdentifier(),
        xPlayer.getName(),
        xPlayer
    )

    if success then
        if activeRedPackets[packetId] then
            activeRedPackets[packetId].opened_count = activeRedPackets[packetId].opened_count + 1
            if activeRedPackets[packetId].opened_count >= activeRedPackets[packetId].count then
                activeRedPackets[packetId] = nil
            end
        end
    end

    cb({success = success, msg = msg, amount = amount})
end)

ESX.RegisterServerCallback('gift_system:getPlayerHistory', function(source, cb, limit)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({}) return end

    Database.GetPlayerGiftHistory(xPlayer.getIdentifier(), limit, cb)
end)

ESX.RegisterServerCallback('gift_system:getRedPacketRecords', function(source, cb, packetId)
    Database.GetRedPacketRecords(packetId, cb)
end)

ESX.RegisterServerCallback('gift_system:getAllGifts', function(source, cb)
    Database.GetAllGifts(cb)
end)

ESX.RegisterServerCallback('gift_system:getAllRedPackets', function(source, cb)
    Database.GetAllRedPackets(cb)
end)

RegisterCommand('giftadmin', function(source, args, rawCommand)
    TriggerClientEvent('gift_system:openAdminUI', source)
end, true)

RegisterCommand('gift', function(source, args, rawCommand)
    TriggerClientEvent('gift_system:openUI', source)
end, false)
