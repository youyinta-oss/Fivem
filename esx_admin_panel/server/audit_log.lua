-- 审计日志系统
-- 记录所有管理员操作

AdminPanel = AdminPanel or {}

--- 记录审计日志
--- @param xPlayer table 执行操作的管理员
--- @param action string 操作标识
--- @param details string 操作详情
--- @param targetPlayer table|nil 目标玩家（可选）
function AuditLog(xPlayer, action, details, targetPlayer)
    if not xPlayer then return end

    MySQL.Async.insert(
        'INSERT INTO admin_audit_logs (admin_name, admin_identifier, action, details, target_player, target_identifier) VALUES (@name, @id, @action, @details, @tname, @tid)',
        {
            ['@name'] = xPlayer.getName(),
            ['@id'] = xPlayer.getIdentifier(),
            ['@action'] = action,
            ['@details'] = details or '',
            ['@tname'] = targetPlayer and targetPlayer.getName() or nil,
            ['@tid'] = targetPlayer and targetPlayer.getIdentifier() or nil,
        }
    )

    -- 发送审计 Webhook
    if Config.Webhooks.audit and Config.Webhooks.audit ~= '' then
        SendDiscordWebhook('audit', string.format('**%s** 执行了 `%s`\n%s',
            xPlayer.getName(), action, details or ''))
    end
end

--- 记录无目标玩家的审计日志（简化版）
--- @param xPlayer table 执行操作的管理员
--- @param action string 操作标识
--- @param details string 操作详情
function AuditLogSimple(xPlayer, action, details)
    AuditLog(xPlayer, action, details, nil)
end

-- 服务端回调：查询审计日志
ESX.RegisterServerCallback('esx_admin_panel:getAuditLogs', function(source, cb, filters)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not CheckPermission(xPlayer, 'audit.view') then return cb(nil) end

    local query = 'SELECT * FROM admin_audit_logs WHERE 1=1'
    local params = {}

    if filters and filters.admin then
        query = query .. ' AND admin_name = @admin'
        params['@admin'] = filters.admin
    end

    if filters and filters.action then
        query = query .. ' AND action = @action'
        params['@action'] = filters.action
    end

    if filters and filters.dateFrom then
        query = query .. ' AND created_at >= @dateFrom'
        params['@dateFrom'] = filters.dateFrom
    end

    if filters and filters.dateTo then
        query = query .. ' AND created_at <= @dateTo'
        params['@dateTo'] = filters.dateTo
    end

    query = query .. ' ORDER BY created_at DESC LIMIT 200'

    MySQL.Async.fetchAll(query, params, function(results)
        cb(results)
    end)
end)

-- 服务端回调：获取审计日志统计
ESX.RegisterServerCallback('esx_admin_panel:getAuditStats', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not CheckPermission(xPlayer, 'audit.view') then return cb(nil) end

    MySQL.Async.fetchAll('SELECT action, COUNT(*) as count FROM admin_audit_logs WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY) GROUP BY action ORDER BY count DESC LIMIT 10', {}, function(results)
        cb(results)
    end)
end)
