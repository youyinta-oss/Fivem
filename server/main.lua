local tempPermissions = {}

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `vehicle_tunes` (
          `id` INT AUTO_INCREMENT PRIMARY KEY,
          `identifier` VARCHAR(50) NOT NULL,
          `vehicle_hash` VARCHAR(20) NOT NULL,
          `tune_name` VARCHAR(100) NOT NULL,
          `tune_data` JSON NOT NULL,
          `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          INDEX idx_identifier (`identifier`),
          INDEX idx_vehicle (`vehicle_hash`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

RegisterCommand('granttune', function(source, args)
    local adminSource = source
    
    if not IsPlayerAceAllowed(adminSource, 'tuning.admin') then
        TriggerClientEvent('tuning:notify', adminSource, '你没有权限执行此指令')
        return
    end
    
    if #args < 1 then
        TriggerClientEvent('tuning:notify', adminSource, '使用方法: /granttune [玩家ID]')
        return
    end
    
    local targetId = tonumber(args[1])
    
    if not targetId or not DoesPlayerExist(targetId) then
        TriggerClientEvent('tuning:notify', adminSource, '无效的玩家ID')
        return
    end
    
    tempPermissions[targetId] = true
    TriggerClientEvent('tuning:notify', targetId, '你已获得临时调车权限')
    TriggerClientEvent('tuning:notify', adminSource, '已给与玩家 ' .. targetId .. ' 临时调车权限')
end, true)

RegisterCommand('tune', function(source)
    if IsPlayerAceAllowed(source, 'tuning.admin') or tempPermissions[source] then
        TriggerClientEvent('tuning:openUI', source)
    else
        TriggerClientEvent('tuning:notify', source, '你没有调车权限')
    end
end, false)

RegisterNetEvent('tuning:saveTune')
AddEventHandler('tuning:saveTune', function(tuneName, vehicleHash, tuneData)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if not identifier then
        return
    end
    
    MySQL.insert.await('INSERT INTO vehicle_tunes (identifier, vehicle_hash, tune_name, tune_data) VALUES (?, ?, ?, ?)', {
        identifier,
        vehicleHash,
        tuneName,
        json.encode(tuneData)
    })
    
    TriggerClientEvent('tuning:notify', source, '调车方案已保存: ' .. tuneName)
end)

RegisterNetEvent('tuning:getTunes')
AddEventHandler('tuning:getTunes', function(vehicleHash)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if not identifier then
        return
    end
    
    local tunes = MySQL.query.await('SELECT id, tune_name, tune_data FROM vehicle_tunes WHERE identifier = ? AND vehicle_hash = ?', {
        identifier,
        vehicleHash
    })
    
    local result = {}
    for _, tune in ipairs(tunes) do
        table.insert(result, {
            id = tune.id,
            name = tune.tune_name,
            data = json.decode(tune.tune_data)
        })
    end
    
    TriggerClientEvent('tuning:receiveTunes', source, result)
end)

RegisterNetEvent('tuning:deleteTune')
AddEventHandler('tuning:deleteTune', function(tuneId)
    local source = source
    local identifier = GetPlayerIdentifier(source, 0)
    
    if not identifier then
        return
    end
    
    MySQL.query.await('DELETE FROM vehicle_tunes WHERE id = ? AND identifier = ?', {
        tuneId,
        identifier
    })
    
    TriggerClientEvent('tuning:notify', source, '调车方案已删除')
end)

function DoesPlayerExist(playerId)
    for _, id in ipairs(GetPlayers()) do
        if tonumber(id) == playerId then
            return true
        end
    end
    return false
end
