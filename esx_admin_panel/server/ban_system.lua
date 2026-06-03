-- 封禁系统
-- 支持永久/定时封禁、离线封禁、自动拦截、解封

AdminPanel = AdminPanel or {}

--- 检查玩家是否被封禁
--- @param identifier string 玩家标识符
--- @param callback function 回调函数(banData|nil)
function CheckBan(identifier, callback)
    MySQL.Async.fetchAll(
        'SELECT * FROM admin_bans WHERE identifier = @id AND unbanned_at IS NULL AND (expire_date IS NULL OR expire_date > NOW())',
        { ['@id'] = identifier },
        function(results)
            if results and #results > 0 then
                callback(results[1])
            else
                callback(nil)
            end
        end
    )
end

--- 执行封禁
--- @param admin xPlayer 执行封禁的管理员
--- @param targetId number 目标玩家 ID
--- @param duration number 封禁天数（0=永久）
--- @param reason string 封禁理由
function BanPlayer(admin, targetId, duration, reason)
    if not CheckPermission(admin, 'player.ban') then return end
    if not CheckCooldown(admin.source) then return end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        admin.showNotification(_U('player_not_found'))
        return
    end

    -- 防止封禁同级或更高级管理员
    if not CanTargetGroup(admin.getGroup(), target.getGroup()) then
        admin.showNotification(_U('permission_denied'))
        return
    end

    local identifier = target.getIdentifier()
    local expireDate = nil
    if duration > 0 then
        expireDate = os.date('%Y-%m-%d %H:%M:%S', os.time() + duration * 86400)
    end

    local durationText = duration == 0 and _U('ban_permanent') or _U('ban_days', duration)

    MySQL.Async.insert(
        'INSERT INTO admin_bans (identifier, player_name, reason, banned_by, banner_identifier, ban_duration, expire_date) VALUES (@id, @name, @reason, @admin, @adminId, @duration, @expire)',
        {
            ['@id'] = identifier,
            ['@name'] = target.getName(),
            ['@reason'] = reason,
            ['@admin'] = admin.getName(),
            ['@adminId'] = admin.getIdentifier(),
            ['@duration'] = duration,
            ['@expire'] = expireDate,
        },
        function(_)
            local kickReason = _U('kick_ban_reason', reason, expireDate or _U('ban_permanent'), admin.getName())
            DropPlayer(targetId, '\n' .. kickReason)

            admin.showNotification(_U('player_banned', target.getName(), durationText, reason))
            AuditLog(admin, 'player.ban', string.format('封禁 %s，时长: %s，理由: %s', target.getName(), durationText, reason), target)
            SendDiscordWebhook('ban', string.format('**封禁通知**\n管理员: %s\n玩家: %s\n时长: %s\n理由: %s',
                admin.getName(), target.getName(), durationText, reason))
        end
    )
end

--- 离线封禁（通过标识符）
--- @param admin xPlayer 执行封禁的管理员
--- @param identifier string 目标标识符
--- @param playerName string 目标玩家名称
--- @param duration number 封禁天数
--- @param reason string 封禁理由
function BanOffline(admin, identifier, playerName, duration, reason)
    if not CheckPermission(admin, 'player.ban') then return end
    if not CheckCooldown(admin.source) then return end

    local expireDate = nil
    if duration > 0 then
        expireDate = os.date('%Y-%m-%d %H:%M:%S', os.time() + duration * 86400)
    end

    local durationText = duration == 0 and _U('ban_permanent') or _U('ban_days', duration)

    MySQL.Async.insert(
        'INSERT INTO admin_bans (identifier, player_name, reason, banned_by, banner_identifier, ban_duration, expire_date) VALUES (@id, @name, @reason, @admin, @adminId, @duration, @expire)',
        {
            ['@id'] = identifier,
            ['@name'] = playerName or 'Unknown',
            ['@reason'] = reason,
            ['@admin'] = admin.getName(),
            ['@adminId'] = admin.getIdentifier(),
            ['@duration'] = duration,
            ['@expire'] = expireDate,
        },
        function(_)
            admin.showNotification(_U('player_banned', playerName or identifier, durationText, reason))
            AuditLog(admin, 'player.ban', string.format('离线封禁 %s (%s)，时长: %s，理由: %s', playerName or 'Unknown', identifier, durationText, reason))
            SendDiscordWebhook('ban', string.format('**离线封禁通知**\n管理员: %s\n玩家: %s (%s)\n时长: %s\n理由: %s',
                admin.getName(), playerName or 'Unknown', identifier, durationText, reason))
        end
    )
end

--- 解封
--- @param admin xPlayer 执行解封的管理员
--- @param banId number 封禁记录 ID
function UnbanPlayer(admin, banId)
    if not CheckPermission(admin, 'player.unban') then return end

    MySQL.Async.fetchAll('SELECT * FROM admin_bans WHERE id = @id', { ['@id'] = banId }, function(results)
        if not results or #results == 0 then
            admin.showNotification(_U('ban_not_found'))
            return
        end

        MySQL.Async.execute(
            'UPDATE admin_bans SET unbanned_by = @admin, unbanned_at = NOW(), unban_reason = @reason WHERE id = @id',
            {
                ['@admin'] = admin.getName(),
                ['@reason'] = '管理员解封',
                ['@id'] = banId,
            },
            function(_)
                local ban = results[1]
                admin.showNotification(_U('player_unbanned', ban.identifier))
                AuditLog(admin, 'player.unban', string.format('解封 %s (%s)', ban.player_name, ban.identifier))
                SendDiscordWebhook('audit', string.format('**解封通知**\n管理员: %s\n玩家: %s (%s)',
                    admin.getName(), ban.player_name, ban.identifier))
            end
        )
    end)
end

-- 玩家连接时检查封禁状态
AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    deferrals.defer()
    local identifiers = GetPlayerIdentifiers(source)
    local license = nil

    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, string.len('license:')) == 'license:' then
            license = id
            break
        end
    end

    if not license then
        deferrals.done()
        return
    end

    CheckBan(license, function(banData)
        if banData then
            local expireText = banData.expire_date and banData.expire_date or _U('ban_permanent')
            deferrals.done(string.format('\n🚫 %s\n\n%s: %s\n%s\n%s: %s',
                _U('kick_ban_reason', '', '', ''),
                '理由', banData.reason,
                expireText,
                '管理员', banData.banned_by
            ))
        else
            deferrals.done()
        end
    end)
end)

-- 网络事件：封禁玩家
RegisterNetEvent('esx_admin_panel:banPlayer')
AddEventHandler('esx_admin_panel:banPlayer', function(targetId, duration, reason)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    if not reason or reason == '' then
        admin.showNotification('封禁理由不能为空')
        return
    end
    BanPlayer(admin, targetId, duration, reason)
end)

-- 网络事件：解封
RegisterNetEvent('esx_admin_panel:unbanPlayer')
AddEventHandler('esx_admin_panel:unbanPlayer', function(banId)
    local src = source
    local admin = ESX.GetPlayerFromId(src)
    if not admin then return end
    UnbanPlayer(admin, banId)
end)

-- 服务端回调：获取封禁列表
ESX.RegisterServerCallback('esx_admin_panel:getBans', function(source, cb, filters)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not CheckPermission(xPlayer, 'player.ban') and not CheckPermission(xPlayer, 'player.unban') then
        return cb(nil)
    end

    local query = 'SELECT * FROM admin_bans WHERE 1=1'
    local params = {}

    -- 默认只显示未解封的
    if not filters or not filters.showUnbanned then
        query = query .. ' AND unbanned_at IS NULL'
    end

    if filters and filters.search then
        query = query .. ' AND (player_name LIKE @search OR identifier LIKE @search OR reason LIKE @search)'
        params['@search'] = '%' .. filters.search .. '%'
    end

    query = query .. ' ORDER BY created_at DESC LIMIT 100'

    MySQL.Async.fetchAll(query, params, function(results)
        cb(results)
    end)
end)
