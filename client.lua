local QBCore = exports['qb-core']:GetCoreObject()
local interacting = false
local robberyActive = false
local boxesLeft = 0
local display = false
local containerObj = nil  -- Variable para almacenar el objeto del contenedor
local containerObj2 = nil -- Variable para el segundo contenedor
local hashVerja1 = 1286392437  -- Hash del modelo de la verja 1
local coordsVerja1 = vector3(10.64241, -2542.214, 5.043662)  -- Coordenadas de la verja 1
local hashVerja2 = 1286392437  -- Hash del modelo de la verja 2
local coordsVerja2 = vector3(22.89276, -2524.72, 5.043661)  -- Coordenadas de la verja 2
local objVerja1 = nil -- Variable para almacenar el objeto de la verja 1
local objVerja2 = nil -- Variable para almacenar el objeto de la verja 2
local maxAttempts = 3  -- Máximo de intentos permitidos
local attemptsLeft = maxAttempts  -- Intentos restantes

-- Definición de la función SetDisplay
function SetDisplay(bool, uiType)
    display = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = uiType,
        status = bool
    })
    print("SetDisplay llamado con estado: " .. tostring(bool) .. ", tipo de UI: " .. uiType) -- Mensaje de depuración
end

-- Asegurarse de que la interfaz esté desactivada al inicio
SetDisplay(false, "ui")
SetDisplay(false, "soplete")

RegisterNUICallback("swipeSuccess", function(data, cb)
    SetDisplay(false, "ui")
    print("Minijuego completado con éxito, tarjeta: " .. data.tarjeta)
    attemptsLeft = maxAttempts
    TriggerServerEvent('robo_contenedores:abrirContenedor', data.tarjeta)
    cb('ok')
end)

RegisterNUICallback("swipeFail", function(data, cb)
    SetDisplay(false, "ui")
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

RegisterNUICallback("sopleteSuccess", function(data, cb)
    SetDisplay(false, "soplete")
    ClearPedTasksImmediately(PlayerPedId())
    exports['rpemotes']:EmoteCommandStart('kick3')
    Citizen.Wait(1000)
    DeleteObject(containerObj2)
    SetEntityVisible(containerObj, true, 0)
    QBCore.Functions.Notify('Has abierto el contenedor', 'success')
    interacting = false
    cb('ok')
end)

RegisterNUICallback("sopleteFail", function(data, cb)
    SetDisplay(false, "soplete")
    ClearPedTasksImmediately(PlayerPedId())
    QBCore.Functions.Notify('Has fallado el minijuego del soplete', 'error')
    interacting = false
    cb('ok')
end)

RegisterNetEvent('robo_contenedores:iniciarMinijuego')
AddEventHandler('robo_contenedores:iniciarMinijuego', function(tarjeta)
    SendNUIMessage({
        type = "setTarjeta",
        tarjeta = tarjeta
    })
    SetDisplay(true, "ui")
    print("Minijuego iniciado con tarjeta: " .. tarjeta)
end)

RegisterNetEvent('robo_contenedores:usarTarjeta')
AddEventHandler('robo_contenedores:usarTarjeta', function()
    print("Evento usarTarjeta recibido")
    TriggerServerEvent('robo_contenedores:usarTarjeta')
end)

RegisterNetEvent('robo_contenedores:usarSoplete')
AddEventHandler('robo_contenedores:usarSoplete', function()
    if not interacting then
        interacting = true
        local ped = PlayerPedId()
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_WELDING", 0, true)
        SetDisplay(true, "soplete")
    end
end)

-- Configurar el punto de objetivo usando qb-target
exports['qb-target']:AddBoxZone("container_point", vector3(21.071319580078,-2530.6882324219,6.0397591590881), 1, 1, {
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

-- Asegurarse de que las verjas estén cerradas por defecto al iniciar el script
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
        Citizen.Wait(1000) -- Espera 1 segundo antes de limpiar el área nuevamente
        ClearAreaAroundVerjas(20.0) -- Radio de 10 unidades para limpiar el área alrededor de las verjas
    end
end)

RegisterNetEvent('robo_contenedores:abrirContenedor')
AddEventHandler('robo_contenedores:abrirContenedor', function(tarjeta)
    print("Intentando abrir contenedor con tarjeta: " .. tarjeta) -- Depuración

    local contenedor = Config.Contenedores[tarjeta]

    if contenedor then
        robberyActive = true
        boxesLeft = #contenedor

        -- Abrir las verjas
        if DoesEntityExist(objVerja1) then
            FreezeEntityPosition(objVerja1, false) -- Congelar la posición después de cambiar el heading
        end

        if DoesEntityExist(objVerja2) then
            FreezeEntityPosition(objVerja2, false) -- Congelar la posición después de cambiar el heading
        end

        -- Spawnear el contenedor
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

        print("Spawneando contenedor en: " .. containerCoords.x .. ", " .. containerCoords.y .. ", " .. containerCoords.z) -- Depuración
        containerObj = CreateObject(containerModel, containerCoords.x, containerCoords.y, containerCoords.z, true, false, true)
        containerObj2 = CreateObject(containerModel2, containerCoords2.x, containerCoords2.y, containerCoords2.z, true, false, true)
        SetEntityHeading(containerObj, containerHeading)
        SetEntityHeading(containerObj2, containerHeading)
        PlaceObjectOnGroundProperly(containerObj)
        PlaceObjectOnGroundProperly(containerObj2)
        SetModelAsNoLongerNeeded(containerModel)
        SetModelAsNoLongerNeeded(containerModel2)
        SetEntityAsMissionEntity(containerObj, true, true)
        SetEntityAsMissionEntity(containerObj2, true, true)
        SetEntityVisible(containerObj, false, 0)

        -- Crear el punto de objetivo para usar soplete
        exports['qb-target']:AddBoxZone("soplete_point", vector3(-4.7743968963623, -2500.3364257812, 6.0067791938782), 1, 1, {
            name = "soplete_point",
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

        Citizen.CreateThread(function()
            Citizen.Wait(600000) -- 10 minutos en milisegundos
            if robberyActive then
                QBCore.Functions.Notify('Robo fallido, se acabó el tiempo', 'error')
                robberyActive = false
                -- Cerrar las verjas si el tiempo se acaba
                if DoesEntityExist(objVerja1) then
                    FreezeEntityPosition(objVerja1, true) -- Congelar la posición después de cambiar el heading
                end
                if DoesEntityExist(objVerja2) then
                    FreezeEntityPosition(objVerja2, true) -- Congelar la posición después de cambiar el heading
                end
                TriggerServerEvent('robo_contenedores:endRobbery', false)
            end
        end)

        for _, caja in pairs(contenedor) do
            local cajaCoords = caja.coords

            -- Crear objeto caja en las coordenadas especificadas
            local model = GetHashKey("ch_prop_ch_case_sm_01x") -- Usa un modelo de caja adecuado
            RequestModel(model)

            while not HasModelLoaded(model) do
                Wait(1)
            end

            print("Spawneando caja en: " .. cajaCoords.x .. ", " .. cajaCoords.y .. ", " .. cajaCoords.z) -- Depuración
            local obj = CreateObject(model, cajaCoords.x, cajaCoords.y, cajaCoords.z, true, false, true)
            PlaceObjectOnGroundProperly(obj)
            SetModelAsNoLongerNeeded(model)
            SetEntityAsMissionEntity(obj, true, true)

            -- Configurar el punto de objetivo para abrir las cajas usando qb-target
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
                        caja = caja, -- Pasar la caja como un parámetro
                        entity = obj,
                        zone = "box_" .. obj -- Añadir la zona para eliminarla después
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
        exports['rpemotes']:EmoteCommandStart('medic') -- Iniciar animación
        QBCore.Functions.Progressbar("open_box", "Abriendo caja...", 300, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function() -- Done
            ClearPedTasks(ped)
            exports['rpemotes']:EmoteCancel() -- Cancelar animación
            TriggerServerEvent('robo_contenedores:darItems', data.caja.items, data.caja.count)
            DeleteObject(data.entity)
            exports['qb-target']:RemoveZone(data.zone) -- Eliminar la zona de objetivo
            interacting = false
            boxesLeft = boxesLeft - 1
            print("Caja abierta, quedan: " .. boxesLeft .. " cajas") -- Depuración
            if boxesLeft <= 0 then
                QBCore.Functions.Notify('Robo completado. Tienes 1 minuto para salir o la verja se cerrará', 'success')
                robberyActive = false
                TriggerServerEvent('robo_contenedores:endRobbery', true)
                
                -- Eliminar el contenedor después de 5 minutos
                Citizen.CreateThread(function()
                    Citizen.Wait(300000) -- 5 minutos en milisegundos
                    if containerObj then
                        DeleteObject(containerObj)
                        containerObj = nil
                        print("Contenedor eliminado después de 5 minutos") -- Depuración
                    end
                end)

                -- Cerrar las verjas después de 1 minuto
                Citizen.CreateThread(function()
                    Citizen.Wait(60000) -- 1 minuto en milisegundos
                    if DoesEntityExist(objVerja1) then
                        FreezeEntityPosition(objVerja1, true) -- Congelar la posición después de cambiar el heading
                    end
                    if DoesEntityExist(objVerja2) then
                        FreezeEntityPosition(objVerja2, true) -- Congelar la posición después de cambiar el heading
                        QBCore.Functions.Notify('La verja se ha cerrado', 'error')
                    end
                end)
            end
        end, function() -- Cancel
            ClearPedTasks(ped)
            exports['rpemotes']:EmoteCancel() -- Cancelar animación
            QBCore.Functions.Notify("Cancelado", "error")
            interacting = false
        end)
    end
end)

RegisterNetEvent('robo_contenedores:reiniciarMinijuego')
AddEventHandler('robo_contenedores:reiniciarMinijuego', function(tarjeta)
    Citizen.Wait(1000) -- Esperar 2 segundos antes de reiniciar el minijuego
    TriggerEvent('robo_contenedores:iniciarMinijuego', tarjeta)
end)
