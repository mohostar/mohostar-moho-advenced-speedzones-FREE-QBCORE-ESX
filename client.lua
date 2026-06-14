local QBCore = exports['qb-core']:GetCoreObject()
local activeZones = {}
local showZones = false
local PlayerJob = {}

local function SendNotify(msg, type)
    if GetResourceState('ox_lib') == 'started' then
        lib.notify({ title = 'SpeedZones', description = msg, type = type or 'inform' })
    elseif Config.Framework == 'qbcore' and QBCore then
        QBCore.Functions.Notify(msg, type)
    else
        SetNotificationTextEntry('STRING')
        AddTextComponentString(msg)
        DrawNotification(false, true)
    end
end

local function IsPointInOrientedBox(pt, center, heading, width, length, height)
    local rad = math.rad(-heading)
    local dx = pt.x - center.x
    local dy = pt.y - center.y
    local dz = pt.z - center.z
    
    if math.abs(dz) > height / 2.0 then return false end
    
    local rx = dx * math.cos(rad) - dy * math.sin(rad)
    local ry = dx * math.sin(rad) + dy * math.cos(rad)
    
    return math.abs(rx) <= (width / 2.0) and math.abs(ry) <= (length / 2.0)
end

local function GetBoxCorners(center, heading, width, length, height)
    local rad = math.rad(heading)
    local cosH = math.cos(rad)
    local sinH = math.sin(rad)
    local w2, l2, h2 = width/2, length/2, height/2
    
    local function getPoint(dx, dy, dz)
        return vector3(
            center.x + (dx * cosH - dy * sinH),
            center.y + (dx * sinH + dy * cosH),
            center.z + dz
        )
    end
    
    return {
        getPoint(-w2, -l2, -h2), getPoint(w2, -l2, -h2),
        getPoint(w2, l2, -h2), getPoint(-w2, l2, -h2),
        getPoint(-w2, -l2, h2), getPoint(w2, -l2, h2),
        getPoint(w2, l2, h2), getPoint(-w2, l2, h2)
    }
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
    QBCore.Functions.TriggerCallback('thehood_antispeed:server:getZones', function(result)
        activeZones = result or {}
    end)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

RegisterNetEvent('thehood_antispeed:client:updateZones', function(newZones)
    activeZones = newZones or {}
    if showZones then
        SendNUIMessage({ action = "updateZones", zones = activeZones })
    end
end)

CreateThread(function()
    Wait(1000)
    local pData = QBCore.Functions.GetPlayerData()
    if pData then PlayerJob = pData.job end
    
    QBCore.Functions.TriggerCallback('thehood_antispeed:server:getZones', function(result) if result then activeZones = result end end)
end)

CreateThread(function()
    local wasInZone = false
    local limitedVehicle = nil
    local currentLimit = 0
    local currentZoneName = ""
    local activeSlowdownEnd = 0
    local isWarningActive = false
    
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            local isExempt = (PlayerJob and Config.ExcludedJobs[PlayerJob.name] and PlayerJob.onduty)
            
            if not isExempt and GetPedInVehicleSeat(vehicle, -1) == ped then
                local coords = GetEntityCoords(ped)
                local inAnyZone = false
                
                for id, zone in pairs(activeZones) do
                    if zone.isActive ~= false then 
                        local zCoords = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
                        local dist = #(coords - zCoords)
                        
                        if dist < 150.0 then
                        sleep = 200
                        
                        local isInside = false
                        if zone.type == "sphere" then
                            isInside = (dist <= zone.radius)
                        elseif zone.type == "box" then
                            isInside = IsPointInOrientedBox(coords, zCoords, zone.heading, zone.width, zone.length, zone.height)
                        end
                        
                        if isInside then
                            inAnyZone = true
                            currentLimit = zone.speedLimit or Config.DefaultSpeedLimit
                            currentZoneName = zone.name or "Ismeretlen"
                            currentDuration = zone.duration or 2 
                            break
                        end
                    end
                    end
                end
                
                if inAnyZone then
                    sleep = 0
                    if not wasInZone then
                        limitedVehicle = vehicle
                        SetEntityMaxSpeed(limitedVehicle, currentLimit / 3.6)
                        wasInZone = true
                        activeSlowdownEnd = GetGameTimer() + (currentDuration * 1000) -- Dinamikus lassítás (ms)
                        if Config.EnableEntrySound then
                            PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", true)
                        end
                    end
                    
                    local currentSpeed = GetEntitySpeed(vehicle) * 3.6
                    
                    if GetGameTimer() < activeSlowdownEnd then
                        if Config.EnableWarningText then
                            if not isWarningActive then
                                SendNUIMessage({ action = "showWarning", lang = Config.Language or 'hu' })
                                isWarningActive = true
                            end
                        end
                        
                        if currentSpeed > currentLimit then
                            SetVehicleForwardSpeed(vehicle, currentLimit / 3.6)
                            if currentSpeed > currentLimit + 10.0 then
                                SetVehicleCheatPowerIncrease(vehicle, 0.0)
                                DisableControlAction(0, 71, true) -- Gázadás letiltása, ha nagyon gyorsan érkezik
                            end
                        end
                    else
                        if isWarningActive then
                            SendNUIMessage({ action = "hideWarning" })
                            isWarningActive = false
                        end
                        if currentSpeed > currentLimit + 5.0 then
                            SetVehicleForwardSpeed(vehicle, currentLimit / 3.6)
                        end
                    end
                else
                    if wasInZone then
                        if isWarningActive then
                            SendNUIMessage({ action = "hideWarning" })
                            isWarningActive = false
                        end
                        if DoesEntityExist(limitedVehicle) then
                            local maxSpeed = GetVehicleHandlingFloat(limitedVehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')
                            SetEntityMaxSpeed(limitedVehicle, maxSpeed)
                        end
                        wasInZone = false
                        limitedVehicle = nil
                    end
                end
            end
        else
            if wasInZone then
                if isWarningActive then
                    SendNUIMessage({ action = "hideWarning" })
                    isWarningActive = false
                end
                if DoesEntityExist(limitedVehicle) then
                    local maxSpeed = GetVehicleHandlingFloat(limitedVehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')
                    SetEntityMaxSpeed(limitedVehicle, maxSpeed)
                end
                wasInZone = false
                limitedVehicle = nil
            end
        end
        
        Wait(sleep)
    end
end)

RegisterNetEvent('thehood_antispeed:client:openMenu', function()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
        zones = activeZones,
        debug = showZones,
        defaultSpeed = Config.DefaultSpeedLimit
    })
end)

RegisterNUICallback('close', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('getCurrentCoords', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    cb({ x = coords.x, y = coords.y, z = coords.z, h = heading })
end)

RegisterNUICallback('createZone', function(data, cb)
    TriggerServerEvent('thehood_antispeed:server:addZone', data)
    SendNotify("Zóna sikeresen létrehozva!", "success")
    cb('ok')
end)

RegisterNUICallback('editZone', function(data, cb)
    TriggerServerEvent('thehood_antispeed:server:editZone', data.id, data.data)
    SendNotify("Zóna sikeresen módosítva!", "success")
    cb('ok')
end)

RegisterNUICallback('deleteZone', function(data, cb)
    TriggerServerEvent('thehood_antispeed:server:deleteZone', data.id)
    SendNotify("Zóna törölve.", "error")
    cb('ok')
end)

RegisterNUICallback('toggleZoneActive', function(data, cb)
    local zone = activeZones[data.id]
    if zone then
        zone.isActive = data.state
        TriggerServerEvent('thehood_antispeed:server:editZone', data.id, zone)
        SendNotify(data.state and "Zóna bekapcsolva" or "Zóna kikapcsolva", "success")
    end
    cb('ok')
end)

RegisterNUICallback('teleportZone', function(data, cb)
    local zone = activeZones[data.id]
    if zone then
        SetEntityCoords(PlayerPedId(), zone.coords.x, zone.coords.y, zone.coords.z)
    end
    SendNotify("Sikeresen odateleportáltál.", "success")
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    cb('ok')
end)

RegisterNUICallback('toggleDebug', function(data, cb)
    TriggerEvent('thehood_antispeed:client:toggleZones')
    cb(showZones)
end)

RegisterNUICallback('sendNotify', function(data, cb)
    SendNotify(data.msg, data.type)
    cb('ok')
end)

RegisterNUICallback('importZones', function(data, cb)
    TriggerServerEvent('thehood_antispeed:server:importZones', data)
    SendNotify("Zónák sikeresen importálva!", "success")
    cb('ok')
end)

RegisterNetEvent('thehood_antispeed:client:toggleZones', function()
    showZones = not showZones
    if showZones then
        SendNotify("Debug mód BEKAPCSOLVA", "success")
        CreateThread(function()
            while showZones do
                Wait(0)
                local pCoords = GetEntityCoords(PlayerPedId())
                for id, zone in pairs(activeZones) do
                    if zone.isActive ~= false then 
                        local zCoords = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
                        if #(pCoords - zCoords) < 150.0 then
                        if zone.type == "sphere" then
                            DrawMarker(28, zCoords.x, zCoords.y, zCoords.z, 0,0,0, 0,0,0, zone.radius * 2.0, zone.radius * 2.0, zone.radius * 2.0, 255, 0, 0, 100, false, false, 2, false, nil, nil, false)
                        elseif zone.type == "box" then
                            local c = GetBoxCorners(zCoords, zone.heading, zone.width, zone.length, zone.height)
                            local r, g, b, a = 150, 0, 255, 200
                            DrawLine(c[1], c[2], r,g,b,a) DrawLine(c[2], c[3], r,g,b,a) DrawLine(c[3], c[4], r,g,b,a) DrawLine(c[4], c[1], r,g,b,a)
                            DrawLine(c[5], c[6], r,g,b,a) DrawLine(c[6], c[7], r,g,b,a) DrawLine(c[7], c[8], r,g,b,a) DrawLine(c[8], c[5], r,g,b,a)
                            DrawLine(c[1], c[5], r,g,b,a) DrawLine(c[2], c[6], r,g,b,a) DrawLine(c[3], c[7], r,g,b,a) DrawLine(c[4], c[8], r,g,b,a)
                            DrawMarker(1, zCoords.x, zCoords.y, zCoords.z - 1.0, 0,0,0, 0,0,0, 0.5, 0.5, 0.5, 255, 255, 255, 150, false, false, 2, false, nil, nil, false)
                        end
                        end
                    end
                end
            end
        end)
    else
        SendNotify("Debug mód KIKAPCSOLVA", "info")
    end
end)