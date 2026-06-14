local QBCore = nil
local ESX = nil

if Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
end

local zones = {}

local function IsAuthorized(src)
    if src == 0 then return true end -- Konzolnak mindent szabad
    if Config.Framework == 'qbcore' then
        return QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god')
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and (xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin') then
            return true
        end
        return false
    end
end

local function GenerateUUID()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

CreateThread(function()
    local loadFile = LoadResourceFile(GetCurrentResourceName(), "lassitok.json")
    if loadFile then
        zones = json.decode(loadFile) or {}
    else
        SaveResourceFile(GetCurrentResourceName(), "lassitok.json", json.encode({}), -1)
    end
end)

if Config.Framework == 'qbcore' then
    QBCore.Functions.CreateCallback('thehood_antispeed:server:getZones', function(source, cb)
        cb(zones)
    end)
elseif Config.Framework == 'esx' then
    ESX.RegisterServerCallback('thehood_antispeed:server:getZones', function(source, cb)
        cb(zones)
    end)
end

RegisterNetEvent('thehood_antispeed:server:addZone', function(data)
    if not IsAuthorized(source) then return end
    local id = GenerateUUID()
    data.id = id
    zones[id] = data
    SaveResourceFile(GetCurrentResourceName(), "lassitok.json", json.encode(zones), -1)
    TriggerClientEvent('thehood_antispeed:client:updateZones', -1, zones)
end)

RegisterNetEvent('thehood_antispeed:server:editZone', function(id, data)
    if not IsAuthorized(source) then return end
    if zones[id] then
        data.id = id
        zones[id] = data
        SaveResourceFile(GetCurrentResourceName(), "lassitok.json", json.encode(zones), -1)
        TriggerClientEvent('thehood_antispeed:client:updateZones', -1, zones)
    end
end)

RegisterNetEvent('thehood_antispeed:server:deleteZone', function(id)
    if not IsAuthorized(source) then return end
    zones[id] = nil
    SaveResourceFile(GetCurrentResourceName(), "lassitok.json", json.encode(zones), -1)
    TriggerClientEvent('thehood_antispeed:client:updateZones', -1, zones)
end)

RegisterNetEvent('thehood_antispeed:server:importZones', function(importedData)
    if not IsAuthorized(source) then return end
    zones = importedData or {}
    SaveResourceFile(GetCurrentResourceName(), "lassitok.json", json.encode(zones), -1)
    TriggerClientEvent('thehood_antispeed:client:updateZones', -1, zones)
end)

if Config.Framework == 'qbcore' then
    QBCore.Commands.Add('speedzones', 'Lassító menü megnyitása', {}, false, function(source, args)
        if source == 0 then
            print("[Antispeed] Ezt a parancsot csak a jatekbol (kliensrol) lehet megnyitni, a szerver konzolbol nem!")
            return
        end
        TriggerClientEvent('thehood_antispeed:client:openMenu', source)
    end, 'admin')
elseif Config.Framework == 'esx' then
    ESX.RegisterCommand('speedzones', 'admin', function(xPlayer, args, showError)
        if xPlayer.source == 0 then
            print("[Antispeed] Ezt a parancsot csak a jatekbol (kliensrol) lehet megnyitni, a szerver konzolbol nem!")
            return
        end
        TriggerClientEvent('thehood_antispeed:client:openMenu', xPlayer.source)
    end, false, {help = 'Lassító menü megnyitása'})
end