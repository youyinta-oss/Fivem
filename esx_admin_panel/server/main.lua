-- 服务端核心逻辑
-- 玩家管理、Discord Webhook、NUI 事件处理

AdminPanel = AdminPanel or {}

-- ============================================
-- Discord Webhook
-- ============================================

--- 发送 Discord Webhook 消息
--- @param type string Webhook 类型 (ban/kick/audit)
--- @param message string 消息内容
function SendDiscordWebhook(type, message)
    local url = Config.Webhooks[type]
    if not url or url == '' then return end

    local color = Config.WebhookColors[type] or Config.WebhookColors.default

    local embed = {{
        ['title'] = 'ESX Admin Panel',
        ['description'] = message,
        ['color'] = color,
        ['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        ['footer'] = { ['text'] = 'ESX Admin Panel v1.0.0' },
    }}

    PerformHttpRequest(url, function(err, text, headers)
        if Config.Debug then
            print(('[Admin Panel] Webhook %s response: %s'):format(type, err))
        end
    end, 'POST', json.encode({
        username = 'ESX Admin Bot',
        embeds = embed,
    }), { ['Content-Type'] = 'application/json' })
end

-- ============================================
-- 国际化辅助
-- ============================================

function _U(key, ...)
    if Locales[Config.Locale] and Locales[Config.Locale][key] then
        return string.format(Locales[Config.Locale][key], ...)
    end
    return key
end

-- ============================================
-- 玩家管理事件
-- ============================================

-- 获取在线玩家列表
ESX.RegisterServerCallback('esx_admin_panel:getPlayers', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not CheckPermission(xPlayer, 'players.list') then return cb(nil) end

    local players = {}
    local xPlayers = ESX.GetPlayers()

    for _, v in ipairs(xPlayers) do
        table.insert(players, {
            id = v.source,
            name = v.getName(),
            identifier = v.getIdentifier(),
            group = v.getGroup(),
            job = v.getJob().label,
            jobGrade = v.getJob().grade_label,
            money = v.getMoney(),
            bank = v.getAccount('bank').money,
            blackMoney = v.getAccount('black_money').money,
            ping = GetPlayerPing(v.source),
        })
    end

    cb(players)
end)

-- 获取单个玩家详细信息
ESX.RegisterServerCallback('esx_admin_panel:getPlayerDetails', function(source, cb, targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not CheckPermission(xPlayer, 'players.list') then return cb(nil) end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then return cb(nil) end

    local inventory = {}
    for _, item in ipairs(target.getInventory()) do
        if item.count > 0 then
            table.insert(inventory, {
                name = item.name,
                label = item.label,
                count = item.count,
            })
        end
    end

    local weapons = {}
    for _, weapon in ipairs(target.getLoadout()) do
        table.insert(weapons, {
            name = weapon.name,
            label = weapon.label,
            ammo = weapon.ammo,
        })
    end

    cb({
        id = target.source,
        name = target.getName(),
        identifier = target.getIdentifier(),
        group = target.getGroup(),
        job = target.getJob(),
        money = target.getMoney(),
        bank = target.getAccount('bank').money,
        blackMoney = target.getAccount('black_money').money,
        inventory = inventory,
        weapons = weapons,
        ping = GetPlayerPing(target.source),
        coords = target.getCoords(),
    })
end)

-- 踢出玩家（NUI 触发）
RegisterNetEvent('esx_admin_panel:kickPlayer')
AddEventHandler('esx_admin_panel:kickPlayer', function(targetId, reason)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'player.kick') then return end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        admin.showNotification(_U('player_not_found'))
        return
    end

    if not CanTargetGroup(admin.getGroup(), target.getGroup()) then
        admin.showNotification(_U('permission_denied'))
        return
    end

    DropPlayer(targetId, '\n❌ ' .. _U('player_kicked', '', reason or '无理由'))
    admin.showNotification(_U('player_kicked', target.getName(), reason or '无理由'))
    AuditLog(admin, 'player.kick', string.format('踢出 %s，理由: %s', target.getName(), reason or '无理由'), target)
    SendDiscordWebhook('kick', string.format('**踢出通知**\n管理员: %s\n玩家: %s\n理由: %s',
        admin.getName(), target.getName(), reason or '无理由'))
end)

-- 冻结/解冻玩家（NUI 触发）
RegisterNetEvent('esx_admin_panel:freezePlayer')
AddEventHandler('esx_admin_panel:freezePlayer', function(targetId, toggle)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'player.freeze') then return end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        admin.showNotification(_U('player_not_found'))
        return
    end

    TriggerClientEvent('esx_admin_panel:toggleFreeze', targetId, toggle)
    local statusText = toggle and _U('player_frozen', target.getName()) or _U('player_unfrozen', target.getName())
    admin.showNotification(statusText)
    AuditLog(admin, 'player.freeze', statusText, target)
end)

-- 传送（NUI 触发）
RegisterNetEvent('esx_admin_panel:teleportToPlayer')
AddEventHandler('esx_admin_panel:teleportToPlayer', function(targetId)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'player.teleport') then return end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        admin.showNotification(_U('player_not_found'))
        return
    end

    local targetCoords = target.getCoords()
    TriggerClientEvent('esx_admin_panel:teleportToPlayer', src, targetCoords)
    admin.showNotification(_U('player_teleported', target.getName()))
    AuditLog(admin, 'player.teleport', string.format('传送到 %s', target.getName()), target)
end)

-- 召唤（NUI 触发）
RegisterNetEvent('esx_admin_panel:bringPlayer')
AddEventHandler('esx_admin_panel:bringPlayer', function(targetId)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'player.teleport') then return end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        admin.showNotification(_U('player_not_found'))
        return
    end

    if not CanTargetGroup(admin.getGroup(), target.getGroup()) then
        admin.showNotification(_U('permission_denied'))
        return
    end

    local adminCoords = admin.getCoords()
    TriggerClientEvent('esx_admin_panel:teleportToPlayer', targetId, adminCoords)
    admin.showNotification(_U('player_brought', target.getName()))
    AuditLog(admin, 'player.bring', string.format('召唤 %s', target.getName()), target)
end)

-- 禁言（NUI 触发）
RegisterNetEvent('esx_admin_panel:mutePlayer')
AddEventHandler('esx_admin_panel:mutePlayer', function(targetId, toggle)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'player.mute') then return end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        admin.showNotification(_U('player_not_found'))
        return
    end

    TriggerClientEvent('esx_admin_panel:toggleMute', targetId, toggle)
    local statusText = toggle and _U('player_muted', target.getName()) or _U('player_unmuted', target.getName())
    admin.showNotification(statusText)
    AuditLog(admin, 'player.mute', statusText, target)
end)

-- 设置金钱（NUI 触发）
RegisterNetEvent('esx_admin_panel:setMoney')
AddEventHandler('esx_admin_panel:setMoney', function(targetId, account, amount)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'player.money.set') then return end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        admin.showNotification(_U('player_not_found'))
        return
    end

    if account ~= 'money' and account ~= 'bank' and account ~= 'black_money' then
        admin.showNotification(_U('money_invalid_type'))
        return
    end

    target.setAccountMoney(account, amount)
    admin.showNotification(_U('money_set', target.getName(), account, amount))
    AuditLog(admin, 'player.money.set', string.format('设置 %s 的 %s 为 $%d', target.getName(), account, amount), target)
end)

-- 给予金钱（NUI 触发）
RegisterNetEvent('esx_admin_panel:giveMoney')
AddEventHandler('esx_admin_panel:giveMoney', function(targetId, account, amount)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'player.money.give') then return end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        admin.showNotification(_U('player_not_found'))
        return
    end

    if account ~= 'money' and account ~= 'bank' and account ~= 'black_money' then
        admin.showNotification(_U('money_invalid_type'))
        return
    end

    target.addAccountMoney(account, amount)
    admin.showNotification(_U('money_given', target.getName(), amount, account))
    AuditLog(admin, 'player.money.give', string.format('给予 %s $%d (%s)', target.getName(), amount, account), target)
end)

-- 设置职业（NUI 触发）
RegisterNetEvent('esx_admin_panel:setJob')
AddEventHandler('esx_admin_panel:setJob', function(targetId, job, grade)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'player.job.set') then return end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        admin.showNotification(_U('player_not_found'))
        return
    end

    target.setJob(job, grade)
    admin.showNotification(_U('job_set', target.getName(), job, grade))
    AuditLog(admin, 'player.job.set', string.format('设置 %s 的职业为 %s - %d', target.getName(), job, grade), target)
end)

-- 旁观（NUI 触发）
RegisterNetEvent('esx_admin_panel:spectatePlayer')
AddEventHandler('esx_admin_panel:spectatePlayer', function(targetId)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'player.spectate') then return end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        admin.showNotification(_U('player_not_found'))
        return
    end

    TriggerClientEvent('esx_admin_panel:spectatePlayer', src, targetId)
    admin.showNotification(_U('player_spectating', target.getName()))
    AuditLog(admin, 'player.spectate', string.format('旁观 %s', target.getName()), target)
end)

-- 生成车辆（NUI 触发）
RegisterNetEvent('esx_admin_panel:spawnVehicle')
AddEventHandler('esx_admin_panel:spawnVehicle', function(model)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'vehicle.spawn') then return end

    TriggerClientEvent('esx_admin_panel:spawnVehicle', src, model)
    admin.showNotification(_U('vehicle_spawned', model))
    AuditLogSimple(admin, 'vehicle.spawn', string.format('生成车辆 %s', model))
end)

-- 删除车辆（NUI 触发）
RegisterNetEvent('esx_admin_panel:deleteVehicle')
AddEventHandler('esx_admin_panel:deleteVehicle', function()
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'vehicle.delete') then return end

    TriggerClientEvent('esx_admin_panel:deleteVehicle', src)
    admin.showNotification(_U('vehicle_deleted'))
    AuditLogSimple(admin, 'vehicle.delete', '删除附近车辆')
end)

-- 天气设置（NUI 触发）
RegisterNetEvent('esx_admin_panel:setWeather')
AddEventHandler('esx_admin_panel:setWeather', function(weatherType)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'world.weather') then return end

    TriggerClientEvent('esx_admin_panel:setWeather', -1, weatherType)
    admin.showNotification(_U('weather_set', weatherType))
    AuditLogSimple(admin, 'world.weather', string.format('设置天气为 %s', weatherType))
end)

-- 时间设置（NUI 触发）
RegisterNetEvent('esx_admin_panel:setTime')
AddEventHandler('esx_admin_panel:setTime', function(hour, minute)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'world.time') then return end

    TriggerClientEvent('esx_admin_panel:setTime', -1, hour, minute)
    admin.showNotification(_U('time_set', hour, minute))
    AuditLogSimple(admin, 'world.time', string.format('设置时间为 %02d:%02d', hour, minute))
end)

-- 穿墙（NUI 触发）
RegisterNetEvent('esx_admin_panel:toggleNoclip')
AddEventHandler('esx_admin_panel:toggleNoclip', function()
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'world.noclip') then return end

    TriggerClientEvent('esx_admin_panel:toggleNoclip', src)
end)

-- 无敌（NUI 触发）
RegisterNetEvent('esx_admin_panel:toggleGodmode')
AddEventHandler('esx_admin_panel:toggleGodmode', function()
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'world.godmode') then return end

    TriggerClientEvent('esx_admin_panel:toggleGodmode', src)
end)

-- 公告（NUI 触发）
RegisterNetEvent('esx_admin_panel:announce')
AddEventHandler('esx_admin_panel:announce', function(message)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'server.announce') then return end

    TriggerClientEvent('esx_admin_panel:announce', -1, message)
    AuditLogSimple(admin, 'server.announce', string.format('公告: %s', message))
end)

-- 资源管理（NUI 触发）
RegisterNetEvent('esx_admin_panel:manageResource')
AddEventHandler('esx_admin_panel:manageResource', function(action, resourceName)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not CheckPermission(admin, 'resource.' .. action) then return end

    if action == 'start' then
        StartResource(resourceName)
        admin.showNotification(_U('resource_started', resourceName))
    elseif action == 'stop' then
        StopResource(resourceName)
        admin.showNotification(_U('resource_stopped', resourceName))
    elseif action == 'restart' then
        StopResource(resourceName)
        Wait(500)
        StartResource(resourceName)
        admin.showNotification(_U('resource_restarted', resourceName))
    end

    AuditLogSimple(admin, 'resource.' .. action, string.format('%s 资源 %s', action, resourceName))
end)

-- ============================================
-- 调试
-- ============================================

if Config.Debug then
    RegisterCommand('admin_debug', function(source, args)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end

        print(('[Admin Panel] Debug - Player: %s, Group: %s, Permissions: %s'):format(
            xPlayer.getName(),
            xPlayer.getGroup(),
            json.encode(GetAllPermissions(xPlayer.getGroup()))
        ))
    end, false)
end
