-- 资源监控模块
-- 监控服务器资源使用情况

AdminPanel = AdminPanel or {}

-- 获取服务器资源状态
ESX.RegisterServerCallback('esx_admin_panel:getResourceStatus', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not CheckPermission(xPlayer, 'resource.start') then return cb(nil) end

    local resources = {}
    local resourceCount = GetNumResources()

    for i = 0, resourceCount - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName then
            local state = GetResourceState(resourceName)
            table.insert(resources, {
                name = resourceName,
                state = state,
            })
        end
    end

    cb({
        resources = resources,
        totalResources = #resources,
        runningResources = #ESX.GetPlayers(), -- 在线玩家数
        uptime = os.time(), -- 服务器运行时间参考
    })
end)

-- 获取服务器性能指标
ESX.RegisterServerCallback('esx_admin_panel:getServerStats', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not CheckPermission(xPlayer, 'players.list') then return cb(nil) end

    local players = ESX.GetPlayers()
    local maxPlayers = GetConvar('sv_maxclients', '64')

    cb({
        onlinePlayers = #players,
        maxPlayers = tonumber(maxPlayers),
        uptime = os.time(),
    })
end)

-- 定时资源监控（可选）
if Config.ResourceMonitor.Enabled then
    CreateThread(function()
        while true do
            Wait(Config.ResourceMonitor.RefreshInterval)

            -- 检查资源状态变化
            local resourceCount = GetNumResources()
            local runningCount = 0

            for i = 0, resourceCount - 1 do
                local resourceName = GetResourceByFindIndex(i)
                if resourceName and GetResourceState(resourceName) == 'started' then
                    runningCount = runningCount + 1
                end
            end

            -- 可以在这里添加告警逻辑
            if Config.Debug then
                print(('[Admin Panel] Resources: %d total, %d running, %d players online'):format(
                    resourceCount, runningCount, #ESX.GetPlayers()))
            end
        end
    end)
end
