-- 客户端工具函数

AdminClient = AdminClient or {}

--- 通知辅助
--- @param message string 消息内容
function AdminClient.Notify(message)
    ESX.ShowNotification(message)
end

--- 绘制 3D 文本
--- @param coords vector3 坐标
--- @param text string 文本内容
function AdminClient.Draw3DText(coords, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

--- 获取玩家瞄准的实体
--- @return number|nil 实体 ID
function AdminClient.GetAimedEntity()
    local _, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
    return entity
end

--- 获取最近车辆
--- @param maxDistance number 最大距离
--- @return number|nil 车辆实体
function AdminClient.GetClosestVehicle(maxDistance)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    maxDistance = maxDistance or 5.0

    local closestVehicle = nil
    local closestDistance = maxDistance

    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(playerCoords - vehicleCoords)

        if distance < closestDistance then
            closestDistance = distance
            closestVehicle = vehicle
        end
    end

    return closestVehicle
end

--- 格式化金钱
--- @param amount number 金额
--- @return string 格式化后的字符串
function AdminClient.FormatMoney(amount)
    local formatted = tostring(amount)
    local k = 0
    while true do
        formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return '$' .. formatted
end
