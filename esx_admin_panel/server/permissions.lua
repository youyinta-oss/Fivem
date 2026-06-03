-- 权限系统
-- 提供权限校验、冷却控制等核心功能

AdminPanel = AdminPanel or {}
AdminPanel.Cooldowns = {} -- source -> { count, lastAction }

--- 检查玩家是否拥有指定权限
--- @param xPlayer table ESX 玩家对象
--- @param permission string 权限标识
--- @return boolean
function HasPermission(xPlayer, permission)
    if not xPlayer then return false end

    local group = xPlayer.getGroup()
    if not group then return false end

    local groupPerms = Config.Permissions[group]
    if not groupPerms then return false end

    -- 直接匹配
    for _, perm in ipairs(groupPerms) do
        if perm == permission then
            return true
        end
    end

    -- 继承匹配
    if Config.InheritPermissions then
        local playerLevel = 0
        for i, g in ipairs(Config.PermissionHierarchy) do
            if g == group then
                playerLevel = i
                break
            end
        end

        for i = 1, playerLevel do
            local perms = Config.PermissionHierarchy[i] and Config.Permissions[Config.PermissionHierarchy[i]]
            if perms then
                for _, perm in ipairs(perms) do
                    if perm == permission then
                        return true
                    end
                end
            end
        end
    end

    return false
end

--- 检查权限并返回错误提示（用于命令）
--- @param xPlayer table ESX 玩家对象
--- @param permission string 权限标识
--- @return boolean 是否有权限
function CheckPermission(xPlayer, permission)
    if not xPlayer then
        return false
    end

    if not HasPermission(xPlayer, permission) then
        xPlayer.showNotification(_U('permission_denied'))
        return false
    end

    return true
end

--- 高危操作冷却检查
--- @param source number 玩家 source
--- @return boolean 是否可以执行
function CheckCooldown(source)
    local now = os.time()
    local cd = AdminPanel.Cooldowns[source]

    if not cd then
        AdminPanel.Cooldowns[source] = { count = 1, lastAction = now }
        return true
    end

    local elapsed = now - cd.lastAction

    -- 冷却期已过，重置
    if elapsed >= Config.CooldownHighRisk then
        AdminPanel.Cooldowns[source] = { count = 1, lastAction = now }
        return true
    end

    -- 冷却期内
    if cd.count >= Config.MaxHighRiskActions then
        local remaining = Config.CooldownHighRisk - elapsed
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.showNotification(_U('cooldown_active', remaining))
        end
        return false
    end

    cd.count = cd.count + 1
    cd.lastAction = now
    return true
end

--- 获取玩家权限组级别
--- @param group string 权限组名称
--- @return number 级别（0-4）
function GetGroupLevel(group)
    for i, g in ipairs(Config.PermissionHierarchy) do
        if g == group then
            return i
        end
    end
    return 0
end

--- 检查管理员是否可以操作目标玩家（防止低级管理员操作高级管理员）
--- @param adminGroup string 管理员权限组
--- @param targetGroup string 目标权限组
--- @return boolean
function CanTargetGroup(adminGroup, targetGroup)
    return GetGroupLevel(adminGroup) > GetGroupLevel(targetGroup)
end

--- 获取指定权限组的所有权限（含继承）
--- @param group string 权限组名称
--- @return table 权限列表
function GetAllPermissions(group)
    local allPerms = {}
    local seen = {}

    if Config.InheritPermissions then
        local groupLevel = GetGroupLevel(group)
        for i = 1, groupLevel do
            local g = Config.PermissionHierarchy[i]
            local perms = Config.Permissions[g]
            if perms then
                for _, perm in ipairs(perms) do
                    if not seen[perm] then
                        seen[perm] = true
                        table.insert(allPerms, perm)
                    end
                end
            end
        end
    else
        local perms = Config.Permissions[group]
        if perms then
            for _, perm in ipairs(perms) do
                if not seen[perm] then
                    seen[perm] = true
                    table.insert(allPerms, perm)
                end
            end
        end
    end

    return allPerms
end

-- 清理离线玩家的冷却数据
AddEventHandler('playerDropped', function()
    AdminPanel.Cooldowns[source] = nil
end)

-- 服务端回调：检查权限
ESX.RegisterServerCallback('esx_admin_panel:checkPermission', function(source, cb, permission)
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(HasPermission(xPlayer, permission))
end)

-- 服务端回调：获取当前玩家所有权限
ESX.RegisterServerCallback('esx_admin_panel:getPermissions', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end

    local group = xPlayer.getGroup()
    cb({
        group = group,
        permissions = GetAllPermissions(group),
        level = GetGroupLevel(group),
    })
end)
