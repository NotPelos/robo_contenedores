local QBCore = exports['qb-core']:GetCoreObject()
local interacting = false
local robberyActive = false
local boxesLeft = 0
local display = false
local containerObj = nil
local containerObj2 = nil  -- Variable para el nuevo prop
local hashVerja1 = 1286392437
local coordsVerja1 = vector3(10.64241, -2542.214, 5.043662)
local hashVerja2 = 1286392437
local coordsVerja2 = vector3(22.89276, -2524.72, 5.043661)
local objVerja1 = nil
local objVerja2 = nil
local maxAttempts = 3
local attemptsLeft = maxAttempts

-- Definición de la función SetDisplay
function SetDisplay(bool)
    display = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = "ui",
        status = bool,
    })
    print("SetDisplay llamado con estado: " .. tostring(bool))
end

SetDisplay(false)

RegisterNUICallback("swipeSuccess", function(data, cb)
    SetDisplay(false)
    print("Minijuego completado con éxito, tarjeta: " .. data.tarjeta)
    attemptsLeft = maxAttempts
    TriggerServerEvent('robo_contenedores:abrirContenedor', data.tarjeta)
    cb('ok')
end)

RegisterNUICallback("swipeFail", function(data, cb)
    SetDisplay(false)
    attemptsLeft = attemptsLeft - 1
    if attemptsLeft > 0 then
        QBCore.Functions.Notify('Robo fallido, te quedan ' .. attemptsLeft .. ' intentos', 'error')
        TriggerServerEvent('robo_contenedores:minijuegoFallido')
        Citizen.Wait(2000)
        TriggerServerEvent('robo_contenedores:reiniciarMinijuego', data.tarjeta)
    else
        QBCore.Functions.Notify('Robo fallido, has agotado todos los intentos', 'error')
        TriggerServerEvent('robo_contenedores:endRobbery', false)
        attemptsLeft = maxAttempts
    end
    cb('ok')
end)

RegisterNetEvent('robo_contenedores:iniciarMinijuego')
AddEventHandler('robo_contenedores:iniciarMinijuego', function(tarjeta)
    SendNUIMessage({
        type = "setTarjeta",
        tarjeta = tarjeta
    })
    SetDisplay(true)
    print("Minijuego iniciado con tarjeta: " .. tarjeta)
end)

RegisterNetEvent('robo_contenedores:usarTarjeta')
AddEventHandler('robo_contenedores:usarTarjeta', function()
    print("Evento usarTarjeta recibido")
    TriggerServerEvent('robo_contenedores:usarTarjeta')
end)

exports['qb-target']:AddBoxZone("container_point", vector3(21.071319580078, -2530.6882324219, 6.0397591590881), 1, 1, {
    name = "container_point",
    heading = 0,
    debugPoly = false,
    minZ = 5.0,
    maxZ = 7.0
}, {
    options = {
        {
            event = "robo_contenedores:usarTarjeta",
            icon = "fas fa-id-card",
            label = "Introducir tarjeta",
        },
    },
    distance = 2.0
})

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        objVerja1 = GetClosestObjectOfType(coordsVerja1.x, coordsVerja1.y, coordsVerja1.z, 5.0, hashVerja1, false, false, false)
        if DoesEntityExist(objVerja1) then
            FreezeEntityPosition(objVerja1, true)
            break
        end
    end

    while true do
        Citizen.Wait(100)
        objVerja2 = GetClosestObjectOfType(coordsVerja2.x, coordsVerja2.y, coordsVerja2.z, 5.0, hashVerja2, false, false, false)
        if DoesEntityExist(objVerja2) then
            FreezeEntityPosition(objVerja2, true)
            break
        end
    end
end)

local function ClearAreaAroundVerjas(radius)
    ClearAreaOfPeds(coordsVerja1.x, coordsVerja1.y, coordsVerja1.z, radius, 1)
    ClearAreaOfPeds(coordsVerja2.x, coordsVerja2.y, coordsVerja2.z, radius, 1)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        ClearAreaAroundVerjas(10.0)
    end
end)

RegisterNetEvent('robo_contenedores:abrirContenedor')
AddEventHandler('robo_contenedores:abrirContenedor', function(tarjeta)
    print("Intentando abrir contenedor con tarjeta: " .. tarjeta)

    local contenedor = Config.Contenedores[tarjeta]

    if contenedor then
        robberyActive = true
        boxesLeft = #contenedor

        if DoesEntityExist(objVerja1) then
            FreezeEntityPosition(objVerja1, false)
        end

        if DoesEntityExist(objVerja2) then
            FreezeEntityPosition(objVerja2, false)
        end

        local containerModel = GetHashKey("prop_container_ld")
        local containerModel2 = GetHashKey("prop_container_ld2")

        RequestModel(containerModel)
        RequestModel(containerModel2)

        while not HasModelLoaded(containerModel) or not HasModelLoaded(containerModel2) do
            Wait(1)
        end

        local containerCoords = vector3(-10.13572883606, -2496.5756835938, 6.0067768096924)
        local containerCoords2 = vector3(-10.13572883606, -2496.5756835938, 4.2)
        local containerHeading = 54.7

        print("Spawneando contenedor en: " .. containerCoords.x .. ", " .. containerCoords.y .. ", " .. containerCoords.z)
        containerObj = CreateObject(containerModel, containerCoords.x, containerCoords.y, containerCoords.z, true, false, true)
        SetEntityHeading(containerObj, containerHeading)
        PlaceObjectOnGroundProperly(containerObj)
        SetModelAsNoLongerNeeded(containerModel)
        SetEntityAsMissionEntity(containerObj, true, true)
        SetEntityVisible(containerObj, false, 0) -- Hacer invisible el contenedor original
        FreezeEntityPosition(containerObj, true)

        containerObj2 = CreateObject(containerModel2, containerCoords2.x, containerCoords2.y, containerCoords2.z, true, false, true)
        SetEntityHeading(containerObj2, containerHeading)
        PlaceObjectOnGroundProperly(containerObj2)
        SetModelAsNoLongerNeeded(containerModel2)
        SetEntityAsMissionEntity(containerObj2, true, true)
        FreezeEntityPosition(containerObj2, true)

        Citizen.CreateThread(function()
            Citizen.Wait(600000)
            if robberyActive then
                QBCore.Functions.Notify('Robo fallido, se acabó el tiempo', 'error')
                robberyActive = false
                if DoesEntityExist(objVerja1) then
                    FreezeEntityPosition(objVerja1, true)
                end
                if DoesEntityExist(objVerja2) then
                    FreezeEntityPosition(objVerja2, true)
                end
                TriggerServerEvent('robo_contenedores:endRobbery', false)
            end
        end)

        exports['qb-target']:AddBoxZone("blowtorch_point", vector3(-4.7743968963623, -2500.3364257812, 6.0067791938782), 1, 1, {
            name = "blowtorch_point",
            heading = 0,
            debugPoly = false,
            minZ = 5.0,
            maxZ = 7.0
        }, {
            options = {
                {
                    event = "robo_contenedores:usarSoplete",
                    icon = "fas fa-fire",
                    label = "Usar soplete",
                },
            },
            distance = 2.0
        })
        for _, caja in pairs(contenedor) do
            local cajaCoords = caja.coords
            local model = GetHashKey("ch_prop_ch_case_sm_01x")
            RequestModel(model)

            while not HasModelLoaded(model) do
                Wait(1)
            end

            print("Spawneando caja en: " .. cajaCoords.x .. ", " .. cajaCoords.y .. ", " .. cajaCoords.z)
            local obj = CreateObject(model, cajaCoords.x, cajaCoords.y, cajaCoords.z, true, false, true)
            PlaceObjectOnGroundProperly(obj)
            SetModelAsNoLongerNeeded(model)
            SetEntityAsMissionEntity(obj, true, true)

            exports['qb-target']:AddEntityZone("box_" .. obj, obj, {
                name = "box_" .. obj,
                debugPoly = false,
                useZ = true
            }, {
                options = {
                    {
                        event = "robo_contenedores:abrirCaja",
                        icon = "fas fa-box-open",
                        label = "Abrir caja",
                        caja = caja,
                        entity = obj,
                        zone = "box_" .. obj
                    },
                },
                distance = 2.0
            })
        end
    else
        QBCore.Functions.Notify('No se encontró el contenedor correspondiente a la tarjeta', 'error')
    end
end)

RegisterNetEvent('robo_contenedores:abrirCaja')
AddEventHandler('robo_contenedores:abrirCaja', function(data)
    if not interacting then
        interacting = true
        local ped = PlayerPedId()
        exports['rpemotes']:EmoteCommandStart('medic')
        QBCore.Functions.Progressbar("open_box", "Abriendo caja...", 300, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
            ClearPedTasks(ped)
            exports['rpemotes']:EmoteCancel()
            TriggerServerEvent('robo_contenedores:darItems', data.caja.items, data.caja.count)
            DeleteObject(data.entity)
            exports['qb-target']:RemoveZone(data.zone)
            interacting = false
            boxesLeft = boxesLeft - 1
            print("Caja abierta, quedan: " .. boxesLeft .. " cajas")
            if boxesLeft <= 0 then
                QBCore.Functions.Notify('Robo completado. Tienes 1 minuto para salir o la verja se cerrará', 'success')
                robberyActive = false
                TriggerServerEvent('robo_contenedores:endRobbery', true)
                
                Citizen.CreateThread(function()
                    Citizen.Wait(300000)
                    if containerObj then
                        DeleteObject(containerObj)
                        containerObj = nil
                        print("Contenedor eliminado después de 5 minutos")
                    end
                end)

                Citizen.CreateThread(function()
                    Citizen.Wait(60000)
                    if DoesEntityExist(objVerja1) then
                        FreezeEntityPosition(objVerja1, true)
                    end
                    if DoesEntityExist(objVerja2) then
                        FreezeEntityPosition(objVerja2, true)
                        QBCore.Functions.Notify('La verja se ha cerrado', 'error')
                    end
                end)
            end
        end, function()
            ClearPedTasks(ped)
            exports['rpemotes']:EmoteCancel()
            QBCore.Functions.Notify("Cancelado", "error")
            interacting = false
        end)
    end
end)

RegisterNetEvent('robo_contenedores:reiniciarMinijuego')
AddEventHandler('robo_contenedores:reiniciarMinijuego', function(tarjeta)
    Citizen.Wait(1000)
    TriggerEvent('robo_contenedores:iniciarMinijuego', tarjeta)
end)

RegisterNetEvent('robo_contenedores:usarSoplete')
AddEventHandler('robo_contenedores:usarSoplete', function()
    if not interacting then
        interacting = true
        local ped = PlayerPedId()
        local path = {
            vector3(-5.74, -2500.91, 6.88),
            vector3(-5.74, -2500.91, 6.12),
            vector3(-4.82, -2499.60, 6.12),
            vector3(-4.82, -2499.60, 6.88)
        }

        Citizen.CreateThread(function()
            for i, point in ipairs(path) do
                TaskGoStraightToCoord(ped, point, 1.0, 20000, 0.0, 0)
                local timeout = GetGameTimer() + 1000
                while Vdist(GetEntityCoords(ped), point) > 0.1 and GetGameTimer() < timeout do
                    Citizen.Wait(100)
                end

                ClearPedTasks(ped)
                TaskStartScenarioInPlace(ped, "WORLD_HUMAN_WELDING", 0, true)
                Citizen.Wait(5000)  -- Ajusta el tiempo de la animación si es necesario
                ClearPedTasks(ped)
            end

            DeleteObject(soplete)
            exports['rpemotes']:EmoteCommandStart('kick3')
            Citizen.Wait(3000)
            DeleteObject(containerObj2)
            SetEntityVisible(containerObj, true, 0)
            QBCore.Functions.Notify('Has abierto el contenedor', 'success')
            interacting = false
        end)
    end
end)

local aimMode = false

RegisterCommand('toggleaimcoords', function()
    aimMode = not aimMode
    if aimMode then
        QBCore.Functions.Notify("Aim coordinates mode enabled. Aim and shoot to get coordinates.", 'success')
    else
        QBCore.Functions.Notify("Aim coordinates mode disabled.", 'error')
    end
end, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if aimMode then
            local ped = PlayerPedId()
            if IsPedArmed(ped, 4) and IsPlayerFreeAiming(PlayerId()) then
                local result, targetCoords = GetPedLastWeaponImpactCoord(ped)
                if result then
                    DrawMarker(1, targetCoords.x, targetCoords.y, targetCoords.z, 0, 0, 0, 0, 0, 0, 0.2, 0.2, 0.2, 255, 0, 0, 255, false, false, 2, true, nil, nil, false)
                    QBCore.Functions.Notify(string.format("Aim coordinates: vector3(%.2f, %.2f, %.2f)", targetCoords.x, targetCoords.y, targetCoords.z), 'success')
                    print(string.format("Aim coordinates: vector3(%.2f, %.2f, %.2f)", targetCoords.x, targetCoords.y, targetCoords.z))
                end
            end
        end
    end
end)
