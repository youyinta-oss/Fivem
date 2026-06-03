-- 客户端主逻辑
-- NUI 界面管理、快捷键、客户端事件处理

local isPanelOpen = false
local isNoclip = false
local isGodmode = false
local isFrozen = false
local isMuted = false
local isSpectating = false
local spectateTarget = nil
local lastSpectateCoords = nil

-- ============================================
-- 面板开关
-- ============================================

RegisterCommand('adminpanel', function()
    TogglePanel()
end, false)

RegisterKeyMapping('adminpanel', '打开管理面板', 'keyboard', Config.AdminKey)

function TogglePanel()
    isPanelOpen = not isPanelOpen
    SetNuiFocus(isPanelOpen, isPanelOpen)

    if isPanelOpen then
        ESX.TriggerServerCallback('esx_admin_panel:getPermissions', function(permData)
            ESX.TriggerServerCallback('esx_admin_panel:getPlayers', function(players)
                SendNUIMessage({
                    action = 'open',
                    players = players,
                    permissions = permData,
                    config = {
                        banDurations = Config.BanDurations,
                        weatherTypes = Config.WeatherTypes,
                    },
                })
            end)
        end)
    else
        SendNUIMessage({ action = 'close' })
    end
end

-- ============================================
-- NUI 回调
-- ============================================

RegisterNUICallback('closePanel', function(_, cb)
    isPanelOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('refreshPlayers', function(_, cb)
    ESX.TriggerServerCallback('esx_admin_panel:getPlayers', function(players)
        cb(players)
    end)
end)

RegisterNUICallback('getPlayerDetails', function(data, cb)
    ESX.TriggerServerCallback('esx_admin_panel:getPlayerDetails', function(details)
        cb(details)
    end, data.targetId)
end)

RegisterNUICallback('kickPlayer', function(data, cb)
    TriggerServerEvent('esx_admin_panel:kickPlayer', data.targetId, data.reason)
    cb('ok')
end)

RegisterNUICallback('freezePlayer', function(data, cb)
    TriggerServerEvent('esx_admin_panel:freezePlayer', data.targetId, data.toggle)
    cb('ok')
end)

RegisterNUICallback('teleportToPlayer', function(data, cb)
    TriggerServerEvent('esx_admin_panel:teleportToPlayer', data.targetId)
    cb('ok')
end)

RegisterNUICallback('bringPlayer', function(data, cb)
    TriggerServerEvent('esx_admin_panel:bringPlayer', data.targetId)
    cb('ok')
end)

RegisterNUICallback('mutePlayer', function(data, cb)
    TriggerServerEvent('esx_admin_panel:mutePlayer', data.targetId, data.toggle)
    cb('ok')
end)

RegisterNUICallback('banPlayer', function(data, cb)
    TriggerServerEvent('esx_admin_panel:banPlayer', data.targetId, data.duration, data.reason)
    cb('ok')
end)

RegisterNUICallback('unbanPlayer', function(data, cb)
    TriggerServerEvent('esx_admin_panel:unbanPlayer', data.banId)
    cb('ok')
end)

RegisterNUICallback('getBans', function(data, cb)
    ESX.TriggerServerCallback('esx_admin_panel:getBans', function(bans)
        cb(bans)
    end, data.filters or {})
end)

RegisterNUICallback('setMoney', function(data, cb)
    TriggerServerEvent('esx_admin_panel:setMoney', data.targetId, data.account, data.amount)
    cb('ok')
end)

RegisterNUICallback('giveMoney', function(data, cb)
    TriggerServerEvent('esx_admin_panel:giveMoney', data.targetId, data.account, data.amount)
    cb('ok')
end)

RegisterNUICallback('setJob', function(data, cb)
    TriggerServerEvent('esx_admin_panel:setJob', data.targetId, data.job, data.grade)
    cb('ok')
end)

RegisterNUICallback('spectatePlayer', function(data, cb)
    TriggerServerEvent('esx_admin_panel:spectatePlayer', data.targetId)
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('esx_admin_panel:spawnVehicle', data.model)
    cb('ok')
end)

RegisterNUICallback('deleteVehicle', function(_, cb)
    TriggerServerEvent('esx_admin_panel:deleteVehicle')
    cb('ok')
end)

RegisterNUICallback('setWeather', function(data, cb)
    TriggerServerEvent('esx_admin_panel:setWeather', data.weatherType)
    cb('ok')
end)

RegisterNUICallback('setTime', function(data, cb)
    TriggerServerEvent('esx_admin_panel:setTime', data.hour, data.minute)
    cb('ok')
end)

RegisterNUICallback('toggleNoclip', function(_, cb)
    TriggerServerEvent('esx_admin_panel:toggleNoclip')
    cb('ok')
end)

RegisterNUICallback('toggleGodmode', function(_, cb)
    TriggerServerEvent('esx_admin_panel:toggleGodmode')
    cb('ok')
end)

RegisterNUICallback('announce', function(data, cb)
    TriggerServerEvent('esx_admin_panel:announce', data.message)
    cb('ok')
end)

RegisterNUICallback('manageResource', function(data, cb)
    TriggerServerEvent('esx_admin_panel:manageResource', data.action, data.resource)
    cb('ok')
end)

RegisterNUICallback('getAuditLogs', function(data, cb)
    ESX.TriggerServerCallback('esx_admin_panel:getAuditLogs', function(logs)
        cb(logs)
    end, data.filters or {})
end)

RegisterNUICallback('getResourceStatus', function(_, cb)
    ESX.TriggerServerCallback('esx_admin_panel:getResourceStatus', function(status)
        cb(status)
    end)
end)

-- ============================================
-- 客户端事件处理
-- ============================================

-- 冻结/解冻
RegisterNetEvent('esx_admin_panel:toggleFreeze')
AddEventHandler('esx_admin_panel:toggleFreeze', function(toggle)
    isFrozen = toggle
    local playerPed = PlayerPedId()

    if isFrozen then
        FreezeEntityPosition(playerPed, true)
    else
        FreezeEntityPosition(playerPed, false)
    end
end)

-- 传送
RegisterNetEvent('esx_admin_panel:teleportToPlayer')
AddEventHandler('esx_admin_panel:teleportToPlayer', function(coords)
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z)
end)

-- 禁言
RegisterNetEvent('esx_admin_panel:toggleMute')
AddEventHandler('esx_admin_panel:toggleMute', function(toggle)
    isMuted = toggle
    -- 禁言通过阻止聊天消息实现
end)

-- 旁观
RegisterNetEvent('esx_admin_panel:spectatePlayer')
AddEventHandler('esx_admin_panel:spectatePlayer', function(targetId)
    if isSpectating then
        StopSpectating()
        return
    end

    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if not targetPed or targetPed == 0 then
        ESX.ShowNotification('无法旁观该玩家')
        return
    end

    local playerPed = PlayerPedId()
    lastSpectateCoords = GetEntityCoords(playerPed)

    NetworkSetInSpectatorMode(true, targetPed)
    isSpectating = true
    spectateTarget = targetId
end)

function StopSpectating()
    if not isSpectating then return end

    local playerPed = PlayerPedId()
    NetworkSetInSpectatorMode(false, 0)

    if lastSpectateCoords then
        SetEntityCoords(playerPed, lastSpectateCoords.x, lastSpectateCoords.y, lastSpectateCoords.z)
        lastSpectateCoords = nil
    end

    isSpectating = false
    spectateTarget = nil
    ESX.ShowNotification(_U('player_spectate_stop'))
end

-- 生成车辆
RegisterNetEvent('esx_admin_panel:spawnVehicle')
AddEventHandler('esx_admin_panel:spawnVehicle', function(model)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    local hash = GetHashKey(model)
    RequestModel(hash)

    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end

    if not HasModelLoaded(hash) then
        ESX.ShowNotification('无法加载车辆模型: ' .. model)
        return
    end

    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetModelAsNoLongerNeeded(hash)

    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
end)

-- 删除车辆
RegisterNetEvent('esx_admin_panel:deleteVehicle')
AddEventHandler('esx_admin_panel:deleteVehicle', function()
    local vehicle = AdminClient.GetClosestVehicle(5.0)
    if vehicle then
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
    else
        ESX.ShowNotification(_U('vehicle_not_found'))
    end
end)

-- 设置天气
RegisterNetEvent('esx_admin_panel:setWeather')
AddEventHandler('esx_admin_panel:setWeather', function(weatherType)
    SetWeatherTypeOverTime(weatherType, 15.0)
end)

-- 设置时间
RegisterNetEvent('esx_admin_panel:setTime')
AddEventHandler('esx_admin_panel:setTime', function(hour, minute)
    NetworkOverrideClockTime(hour, minute, 0)
end)

-- 穿墙模式
RegisterNetEvent('esx_admin_panel:toggleNoclip')
AddEventHandler('esx_admin_panel:toggleNoclip', function()
    isNoclip = not isNoclip
    local playerPed = PlayerPedId()

    if isNoclip then
        SetEntityInvincible(playerPed, true)
        SetEntityVisible(playerPed, false, false)
        SetEntityCollision(playerPed, false, false)
        FreezeEntityPosition(playerPed, true)
        ESX.ShowNotification(_U('noclip_enabled'))
    else
        SetEntityInvincible(playerPed, false)
        SetEntityVisible(playerPed, true, false)
        SetEntityCollision(playerPed, true, true)
        FreezeEntityPosition(playerPed, false)
        ESX.ShowNotification(_U('noclip_disabled'))
    end
end)

-- 穿墙移动循环
CreateThread(function()
    local noclipSpeed = 2.0
    while true do
        Wait(0)
        if isNoclip then
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)

            local dx, dy, dz = 0.0, 0.0, 0.0

            if IsControlPressed(1, 32) then -- W
                dx = dx + math.sin(math.rad(heading)) * noclipSpeed
                dy = dy - math.cos(math.rad(heading)) * noclipSpeed
            end
            if IsControlPressed(1, 33) then -- S
                dx = dx - math.sin(math.rad(heading)) * noclipSpeed
                dy = dy + math.cos(math.rad(heading)) * noclipSpeed
            end
            if IsControlPressed(1, 34) then -- A
                dx = dx - math.cos(math.rad(heading)) * noclipSpeed
                dy = dy - math.sin(math.rad(heading)) * noclipSpeed
            end
            if IsControlPressed(1, 35) then -- D
                dx = dx + math.cos(math.rad(heading)) * noclipSpeed
                dy = dy + math.sin(math.rad(heading)) * noclipSpeed
            end
            if IsControlPressed(1, 21) then -- Shift
                dz = dz + noclipSpeed
            end
            if IsControlPressed(1, 36) then -- Ctrl
                dz = dz - noclipSpeed
            end

            -- 滚轮调速
            if IsControlJustPressed(1, 17) then -- Scroll up
                noclipSpeed = math.min(noclipSpeed + 1.0, 20.0)
            end
            if IsControlJustPressed(1, 16) then -- Scroll down
                noclipSpeed = math.max(noclipSpeed - 1.0, 0.5)
            end

            SetEntityCoords(playerPed, coords.x + dx, coords.y + dy, coords.z + dz, false, false, false, false)
            SetEntityHeading(playerPed, heading + GetDisabledControlNormal(0, 1) * -5.0)
        else
            Wait(500)
        end
    end
end)

-- 无敌模式
RegisterNetEvent('esx_admin_panel:toggleGodmode')
AddEventHandler('esx_admin_panel:toggleGodmode', function()
    isGodmode = not isGodmode
    local playerPed = PlayerPedId()

    if isGodmode then
        SetEntityInvincible(playerPed, true)
        ESX.ShowNotification(_U('godmode_enabled'))
    else
        SetEntityInvincible(playerPed, false)
        ESX.ShowNotification(_U('godmode_disabled'))
    end
end)

-- 公告
RegisterNetEvent('esx_admin_panel:announce')
AddEventHandler('esx_admin_panel:announce', function(message)
    ESX.ShowAdvancedNotification(_U('announce'), '', message, 'CHAR_MP_FM_CONTACT', 1)
end)

-- ============================================
-- 禁言聊天拦截
-- ============================================

AddEventHandler('chatMessage', function(source, name, message)
    if isMuted then
        CancelEvent()
        ESX.ShowNotification('你已被禁言，无法发送消息')
    end
end)

-- ============================================
-- 面板关闭时清理
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isPanelOpen then
            SetNuiFocus(false, false)
        end
        if isNoclip then
            local playerPed = PlayerPedId()
            SetEntityInvincible(playerPed, false)
            SetEntityVisible(playerPed, true, false)
            SetEntityCollision(playerPed, true, true)
            FreezeEntityPosition(playerPed, false)
        end
        if isGodmode then
            SetEntityInvincible(PlayerPedId(), false)
        end
        if isFrozen then
            FreezeEntityPosition(PlayerPedId(), false)
        end
    end
end)
