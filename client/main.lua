local isUIOpen = false
local originalHandling = nil
local currentVehicle = nil

RegisterNetEvent('tuning:openUI')
AddEventHandler('tuning:openUI', function()
    local playerPed = PlayerPedId()
    currentVehicle = GetVehiclePedIsIn(playerPed, false)
    
    if not DoesEntityExist(currentVehicle) then
        TriggerEvent('tuning:notify', '你必须坐在车里才能打开调车面板')
        return
    end
    
    if not originalHandling then
        originalHandling = {}
        SaveOriginalHandling(currentVehicle)
    end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'open',
        vehicleModel = GetEntityModel(currentVehicle)
    })
    TriggerServerEvent('tuning:getTunes', GetEntityModel(currentVehicle))
end)

RegisterNetEvent('tuning:notify')
AddEventHandler('tuning:notify', function(message)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, false)
end)

RegisterNetEvent('tuning:receiveTunes')
AddEventHandler('tuning:receiveTunes', function(tunes)
    SendNUIMessage({
        type = 'loadTunes',
        tunes = tunes
    })
end)

RegisterNUICallback('closeUI', function(data, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'close'
    })
    cb('ok')
end)

RegisterNUICallback('applyTune', function(data, cb)
    ApplyTune(currentVehicle, data.tune)
    cb('ok')
end)

RegisterNUICallback('saveTune', function(data, cb)
    TriggerServerEvent('tuning:saveTune', data.name, data.vehicleHash, data.tune)
    cb('ok')
end)

RegisterNUICallback('deleteTune', function(data, cb)
    TriggerServerEvent('tuning:deleteTune', data.id)
    cb('ok')
end)

RegisterNUICallback('resetTune', function(data, cb)
    ResetHandling(currentVehicle)
    cb('ok')
end)

function SaveOriginalHandling(vehicle)
    originalHandling['mass'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fMass')
    originalHandling['initialDragCoeff'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDragCoeff')
    originalHandling['driveBiasFront'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDriveBiasFront')
    originalHandling['brakeForce'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce')
    originalHandling['brakeBiasFront'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeBiasFront')
    originalHandling['steeringLock'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSteeringLock')
    originalHandling['tractionCurveMax'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax')
    originalHandling['suspensionForce'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionForce')
    originalHandling['suspensionCompDamp'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionCompDamp')
    originalHandling['suspensionReboundDamp'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionReboundDamp')
    originalHandling['suspensionUpperLimit'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionUpperLimit')
    originalHandling['suspensionLowerLimit'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionLowerLimit')
    originalHandling['antiRollBarForce'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fAntiRollBarForce')
    originalHandling['acceleration'] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce')
end

function ApplyTune(vehicle, tune)
    if not DoesEntityExist(vehicle) then return end
    
    if tune.mass then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fMass', tune.mass) end
    if tune.initialDragCoeff then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDragCoeff', tune.initialDragCoeff) end
    if tune.driveBiasFront then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDriveBiasFront', tune.driveBiasFront) end
    if tune.brakeForce then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce', tune.brakeForce) end
    if tune.brakeBiasFront then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeBiasFront', tune.brakeBiasFront) end
    if tune.steeringLock then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSteeringLock', tune.steeringLock) end
    if tune.tractionCurveMax then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax', tune.tractionCurveMax) end
    if tune.suspensionForce then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionForce', tune.suspensionForce) end
    if tune.suspensionCompDamp then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionCompDamp', tune.suspensionCompDamp) end
    if tune.suspensionReboundDamp then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionReboundDamp', tune.suspensionReboundDamp) end
    if tune.suspensionUpperLimit then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionUpperLimit', tune.suspensionUpperLimit) end
    if tune.suspensionLowerLimit then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionLowerLimit', tune.suspensionLowerLimit) end
    if tune.antiRollBarForce then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fAntiRollBarForce', tune.antiRollBarForce) end
    if tune.acceleration then SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce', tune.acceleration) end
    
    RefreshVehiclePhysics(vehicle)
end

function ResetHandling(vehicle)
    if not DoesEntityExist(vehicle) or not originalHandling then return end
    
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fMass', originalHandling['mass'])
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDragCoeff', originalHandling['initialDragCoeff'])
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDriveBiasFront', originalHandling['driveBiasFront'])
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce', originalHandling['brakeForce'])
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeBiasFront', originalHandling['brakeBiasFront'])
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSteeringLock', originalHandling['steeringLock'])
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax', originalHandling['tractionCurveMax'])
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionForce', originalHandling['suspensionForce'])
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionCompDamp', originalHandling['suspensionCompDamp'])
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionReboundDamp', originalHandling['suspensionReboundDamp'])
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionUpperLimit', originalHandling['suspensionUpperLimit'])
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fSuspensionLowerLimit', originalHandling['suspensionLowerLimit'])
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fAntiRollBarForce', originalHandling['antiRollBarForce'])
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce', originalHandling['acceleration'])
    
    RefreshVehiclePhysics(vehicle)
end

function RefreshVehiclePhysics(vehicle)
    SetVehicleHandlingField(vehicle, 'CHandlingData', 'fWeaponDamageMult', GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fWeaponDamageMult'))
    SetVehicleDirtLevel(vehicle, GetVehicleDirtLevel(vehicle))
end

RegisterCommand('tune', function()
    TriggerEvent('tuning:openUI')
end, false)
