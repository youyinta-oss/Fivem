-- 管理员命令注册
-- 所有命令都经过权限校验和审计记录

-- 踢出玩家
ESX.RegisterCommand('kick', 'mod', function(xPlayer, args, showError)
    local target = ESX.GetPlayerFromId(args.target)
    if not target then return showError(_U('player_not_found')) end

    if not CanTargetGroup(xPlayer.getGroup(), target.getGroup()) then
        return showError(_U('permission_denied'))
    end

    DropPlayer(args.target, '\n❌ ' .. _U('player_kicked', '', args.reason))
    xPlayer.showNotification(_U('player_kicked', target.getName(), args.reason))
    AuditLog(xPlayer, 'player.kick', string.format('踢出 %s，理由: %s', target.getName(), args.reason), target)
    SendDiscordWebhook('kick', string.format('**踢出通知**\n管理员: %s\n玩家: %s\n理由: %s',
        xPlayer.getName(), target.getName(), args.reason))
end, false, {
    help = '踢出指定玩家',
    arguments = {
        { name = 'target', help = '玩家ID', type = 'number' },
        { name = 'reason', help = '理由', type = 'string' },
    }
})

-- 冻结/解冻玩家
ESX.RegisterCommand('freeze', 'mod', function(xPlayer, args, showError)
    local target = ESX.GetPlayerFromId(args.target)
    if not target then return showError(_U('player_not_found')) end

    if not CanTargetGroup(xPlayer.getGroup(), target.getGroup()) then
        return showError(_U('permission_denied'))
    end

    local toggle = args.toggle == nil and true or args.toggle
    TriggerClientEvent('esx_admin_panel:toggleFreeze', args.target, toggle)

    local statusText = toggle and _U('player_frozen', target.getName()) or _U('player_unfrozen', target.getName())
    xPlayer.showNotification(statusText)
    AuditLog(xPlayer, 'player.freeze', statusText, target)
end, false, {
    help = '冻结/解冻玩家',
    arguments = {
        { name = 'target', help = '玩家ID', type = 'number' },
        { name = 'toggle', help = 'true/false', type = 'boolean' },
    }
})

-- 传送到玩家
ESX.RegisterCommand('tp', 'mod', function(xPlayer, args, showError)
    local target = ESX.GetPlayerFromId(args.target)
    if not target then return showError(_U('player_not_found')) end

    local targetCoords = target.getCoords()
    TriggerClientEvent('esx_admin_panel:teleportToPlayer', xPlayer.source, targetCoords)
    xPlayer.showNotification(_U('player_teleported', target.getName()))
    AuditLog(xPlayer, 'player.teleport', string.format('传送到 %s', target.getName()), target)
end, false, {
    help = '传送到指定玩家',
    arguments = {
        { name = 'target', help = '玩家ID', type = 'number' },
    }
})

-- 召唤玩家
ESX.RegisterCommand('bring', 'mod', function(xPlayer, args, showError)
    local target = ESX.GetPlayerFromId(args.target)
    if not target then return showError(_U('player_not_found')) end

    if not CanTargetGroup(xPlayer.getGroup(), target.getGroup()) then
        return showError(_U('permission_denied'))
    end

    local adminCoords = xPlayer.getCoords()
    TriggerClientEvent('esx_admin_panel:teleportToPlayer', args.target, adminCoords)
    xPlayer.showNotification(_U('player_brought', target.getName()))
    AuditLog(xPlayer, 'player.bring', string.format('召唤 %s', target.getName()), target)
end, false, {
    help = '将指定玩家召唤到身边',
    arguments = {
        { name = 'target', help = '玩家ID', type = 'number' },
    }
})

-- 封禁玩家
ESX.RegisterCommand('ban', 'admin', function(xPlayer, args, showError)
    if not args.reason or args.reason == '' then
        return showError('封禁理由不能为空')
    end

    BanPlayer(xPlayer, args.target, args.duration, args.reason)
end, false, {
    help = '封禁玩家',
    arguments = {
        { name = 'target', help = '玩家ID', type = 'number' },
        { name = 'duration', help = '天数 (0=永久)', type = 'number' },
        { name = 'reason', help = '理由', type = 'string' },
    }
})

-- 解封
ESX.RegisterCommand('unban', 'admin', function(xPlayer, args, showError)
    UnbanPlayer(xPlayer, args.banId)
end, false, {
    help = '解封玩家',
    arguments = {
        { name = 'banId', help = '封禁记录ID', type = 'number' },
    }
})

-- 设置金钱
ESX.RegisterCommand('setmoney', 'admin', function(xPlayer, args, showError)
    local target = ESX.GetPlayerFromId(args.target)
    if not target then return showError(_U('player_not_found')) end

    local moneyType = args.type or 'money'
    if moneyType ~= 'money' and moneyType ~= 'bank' and moneyType ~= 'black_money' then
        return showError(_U('money_invalid_type'))
    end

    target.setAccountMoney(moneyType, args.amount)
    xPlayer.showNotification(_U('money_set', target.getName(), moneyType, args.amount))
    AuditLog(xPlayer, 'player.money.set', string.format('设置 %s 的 %s 为 $%d', target.getName(), moneyType, args.amount), target)
end, false, {
    help = '设置玩家金钱',
    arguments = {
        { name = 'target', help = '玩家ID', type = 'number' },
        { name = 'type', help = 'money/bank/black_money', type = 'string' },
        { name = 'amount', help = '金额', type = 'number' },
    }
})

-- 给予金钱
ESX.RegisterCommand('givemoney', 'admin', function(xPlayer, args, showError)
    local target = ESX.GetPlayerFromId(args.target)
    if not target then return showError(_U('player_not_found')) end

    local moneyType = args.type or 'money'
    if moneyType ~= 'money' and moneyType ~= 'bank' and moneyType ~= 'black_money' then
        return showError(_U('money_invalid_type'))
    end

    target.addAccountMoney(moneyType, args.amount)
    xPlayer.showNotification(_U('money_given', target.getName(), args.amount, moneyType))
    AuditLog(xPlayer, 'player.money.give', string.format('给予 %s $%d (%s)', target.getName(), args.amount, moneyType), target)
end, false, {
    help = '给予玩家金钱',
    arguments = {
        { name = 'target', help = '玩家ID', type = 'number' },
        { name = 'type', help = 'money/bank/black_money', type = 'string' },
        { name = 'amount', help = '金额', type = 'number' },
    }
})

-- 设置职业
ESX.RegisterCommand('setjob', 'admin', function(xPlayer, args, showError)
    local target = ESX.GetPlayerFromId(args.target)
    if not target then return showError(_U('player_not_found')) end

    target.setJob(args.job, args.grade)
    xPlayer.showNotification(_U('job_set', target.getName(), args.job, args.grade))
    AuditLog(xPlayer, 'player.job.set', string.format('设置 %s 的职业为 %s - %d', target.getName(), args.job, args.grade), target)
end, false, {
    help = '设置玩家职业',
    arguments = {
        { name = 'target', help = '玩家ID', type = 'number' },
        { name = 'job', help = '职业名称', type = 'string' },
        { name = 'grade', help = '职业等级', type = 'number' },
    }
})

-- 设置权限组
ESX.RegisterCommand('setgroup', 'superadmin', function(xPlayer, args, showError)
    local target = ESX.GetPlayerFromId(args.target)
    if not target then return showError(_U('player_not_found')) end

    -- 检查管理员级别是否高于目标
    if not CanTargetGroup(xPlayer.getGroup(), args.group) then
        return showError(_U('permission_denied'))
    end

    target.setGroup(args.group)
    xPlayer.showNotification(string.format('已将 %s 的权限组设置为 %s', target.getName(), args.group))
    AuditLog(xPlayer, 'player.group.set', string.format('设置 %s 的权限组为 %s', target.getName(), args.group), target)
end, false, {
    help = '设置玩家权限组',
    arguments = {
        { name = 'target', help = '玩家ID', type = 'number' },
        { name = 'group', help = '权限组 (user/helper/mod/admin/superadmin)', type = 'string' },
    }
})

-- 生成车辆
ESX.RegisterCommand('car', 'admin', function(xPlayer, args, showError)
    TriggerClientEvent('esx_admin_panel:spawnVehicle', xPlayer.source, args.model)
    xPlayer.showNotification(_U('vehicle_spawned', args.model))
    AuditLogSimple(xPlayer, 'vehicle.spawn', string.format('生成车辆 %s', args.model))
end, false, {
    help = '生成指定车辆',
    arguments = {
        { name = 'model', help = '车辆模型名称', type = 'string' },
    }
})

-- 删除车辆
ESX.RegisterCommand('dv', 'admin', function(xPlayer, args, showError)
    TriggerClientEvent('esx_admin_panel:deleteVehicle', xPlayer.source)
    xPlayer.showNotification(_U('vehicle_deleted'))
    AuditLogSimple(xPlayer, 'vehicle.delete', '删除附近车辆')
end, false, {
    help = '删除附近车辆',
    arguments = {}
})

-- 设置天气
ESX.RegisterCommand('weather', 'admin', function(xPlayer, args, showError)
    local validWeather = false
    for _, w in ipairs(Config.WeatherTypes) do
        if w == args.weatherType then
            validWeather = true
            break
        end
    end

    if not validWeather then
        return showError('无效的天气类型')
    end

    TriggerClientEvent('esx_admin_panel:setWeather', -1, args.weatherType)
    xPlayer.showNotification(_U('weather_set', args.weatherType))
    AuditLogSimple(xPlayer, 'world.weather', string.format('设置天气为 %s', args.weatherType))
end, false, {
    help = '设置天气',
    arguments = {
        { name = 'weatherType', help = '天气类型', type = 'string' },
    }
})

-- 设置时间
ESX.RegisterCommand('time', 'admin', function(xPlayer, args, showError)
    local hour = math.clamp(args.hour, 0, 23)
    local minute = args.minute and math.clamp(args.minute, 0, 59) or 0

    TriggerClientEvent('esx_admin_panel:setTime', -1, hour, minute)
    xPlayer.showNotification(_U('time_set', hour, minute))
    AuditLogSimple(xPlayer, 'world.time', string.format('设置时间为 %02d:%02d', hour, minute))
end, false, {
    help = '设置时间',
    arguments = {
        { name = 'hour', help = '小时 (0-23)', type = 'number' },
        { name = 'minute', help = '分钟 (0-59)', type = 'number' },
    }
})

-- 穿墙模式
ESX.RegisterCommand('noclip', 'admin', function(xPlayer, args, showError)
    TriggerClientEvent('esx_admin_panel:toggleNoclip', xPlayer.source)
end, false, {
    help = '切换穿墙模式',
    arguments = {}
})

-- 无敌模式
ESX.RegisterCommand('god', 'superadmin', function(xPlayer, args, showError)
    TriggerClientEvent('esx_admin_panel:toggleGodmode', xPlayer.source)
end, false, {
    help = '切换无敌模式',
    arguments = {}
})

-- 服务器公告
ESX.RegisterCommand('announce', 'admin', function(xPlayer, args, showError)
    TriggerClientEvent('esx_admin_panel:announce', -1, args.message)
    AuditLogSimple(xPlayer, 'server.announce', string.format('公告: %s', args.message))
end, false, {
    help = '发送服务器公告',
    arguments = {
        { name = 'message', help = '公告内容', type = 'string' },
    }
})

-- 旁观玩家
ESX.RegisterCommand('spectate', 'mod', function(xPlayer, args, showError)
    local target = ESX.GetPlayerFromId(args.target)
    if not target then return showError(_U('player_not_found')) end

    TriggerClientEvent('esx_admin_panel:spectatePlayer', xPlayer.source, args.target)
    xPlayer.showNotification(_U('player_spectating', target.getName()))
    AuditLog(xPlayer, 'player.spectate', string.format('旁观 %s', target.getName()), target)
end, false, {
    help = '旁观指定玩家',
    arguments = {
        { name = 'target', help = '玩家ID', type = 'number' },
    }
})

-- 禁言/解禁言
ESX.RegisterCommand('mute', 'mod', function(xPlayer, args, showError)
    local target = ESX.GetPlayerFromId(args.target)
    if not target then return showError(_U('player_not_found')) end

    if not CanTargetGroup(xPlayer.getGroup(), target.getGroup()) then
        return showError(_U('permission_denied'))
    end

    local toggle = args.toggle == nil and true or args.toggle
    TriggerClientEvent('esx_admin_panel:toggleMute', args.target, toggle)

    local statusText = toggle and _U('player_muted', target.getName()) or _U('player_unmuted', target.getName())
    xPlayer.showNotification(statusText)
    AuditLog(xPlayer, 'player.mute', statusText, target)
end, false, {
    help = '禁言/解禁言玩家',
    arguments = {
        { name = 'target', help = '玩家ID', type = 'number' },
        { name = 'toggle', help = 'true/false', type = 'boolean' },
    }
})

-- 资源管理命令
ESX.RegisterCommand('resstart', 'superadmin', function(xPlayer, args, showError)
    StopResource(args.resource)
    StartResource(args.resource)
    xPlayer.showNotification(_U('resource_restarted', args.resource))
    AuditLogSimple(xPlayer, 'resource.restart', string.format('重启资源 %s', args.resource))
end, false, {
    help = '重启指定资源',
    arguments = {
        { name = 'resource', help = '资源名称', type = 'string' },
    }
})

ESX.RegisterCommand('resstop', 'superadmin', function(xPlayer, args, showError)
    StopResource(args.resource)
    xPlayer.showNotification(_U('resource_stopped', args.resource))
    AuditLogSimple(xPlayer, 'resource.stop', string.format('停止资源 %s', args.resource))
end, false, {
    help = '停止指定资源',
    arguments = {
        { name = 'resource', help = '资源名称', type = 'string' },
    }
})

ESX.RegisterCommand('resstart', 'superadmin', function(xPlayer, args, showError)
    StartResource(args.resource)
    xPlayer.showNotification(_U('resource_started', args.resource))
    AuditLogSimple(xPlayer, 'resource.start', string.format('启动资源 %s', args.resource))
end, false, {
    help = '启动指定资源',
    arguments = {
        { name = 'resource', help = '资源名称', type = 'string' },
    }
})
