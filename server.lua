local QBCore = exports['qb-core']:GetCoreObject()
local robberyCooldown = false
local robberyActive = false
local playerAttempts = {}
local playerCards = {} -- Variable para almacenar el tipo de tarjeta usada por cada jugador

RegisterServerEvent('robo_contenedores:usarTarjeta')
AddEventHandler('robo_contenedores:usarTarjeta', function()
    local src = source
    print("Evento usarTarjeta en el servidor recibido")
    if not robberyCooldown and not robberyActive then
        local Player = QBCore.Functions.GetPlayer(src)
        local tarjeta = nil

        if Player.Functions.GetItemByName('tchumane') then
            tarjeta = 'tchumane'
        elseif Player.Functions.GetItemByName('tcarmeria') then
            tarjeta = 'tcarmeria'
        elseif Player.Functions.GetItemByName('tcjoyeria') then
            tarjeta = 'tcjoyeria'
        end

        if tarjeta then
            -- Almacenar la tarjeta usada por el jugador y eliminarla del inventario
            playerCards[src] = tarjeta
            Player.Functions.RemoveItem(tarjeta, 1)
            TriggerClientEvent('robo_contenedores:iniciarMinijuego', src, tarjeta)
            TriggerClientEvent('QBCore:Notify', src, 'Se ha utilizado la tarjeta correctamente', 'success')
            TriggerEvent('robo_contenedores:notifyPolice')
            robberyActive = true
            playerAttempts[src] = 3 -- Establecer los intentos iniciales para el jugador
            print("Tarjeta usada: " .. tarjeta)
        else
            TriggerClientEvent('QBCore:Notify', src, 'No tienes la tarjeta correcta', 'error')
        end
    elseif robberyCooldown then
        TriggerClientEvent('QBCore:Notify', src, 'El robo está en cooldown, inténtalo más tarde', 'error')
    else
        TriggerClientEvent('robo_contenedores:reiniciarMinijuego', src, playerAttempts[src]) -- Reiniciar el minijuego
    end
end)

RegisterServerEvent('robo_contenedores:darItems')
AddEventHandler('robo_contenedores:darItems', function(items, count)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player then
        for _, item in pairs(items) do
            Player.Functions.AddItem(item, count)
        end
        TriggerClientEvent('QBCore:Notify', src, 'Has recibido tus ítems', 'success')
        print("Ítems dados: " .. json.encode(items))
    end
end)

RegisterServerEvent('robo_contenedores:endRobbery')
AddEventHandler('robo_contenedores:endRobbery', function(success, fromCooldown)
    local src = source
    if success then
        TriggerClientEvent('QBCore:Notify', src, 'Robo completado', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Robo fallido', 'error')
        if fromCooldown then
            TriggerClientEvent('QBCore:Notify', src, 'El robo está en cooldown o ya hay un robo activo, inténtalo más tarde', 'error')
        end
    end
    robberyActive = false
    robberyCooldown = true
    playerAttempts[src] = nil
    playerCards[src] = nil -- Resetear la tarjeta usada por el jugador
    SetTimeout(1800000, function()
        robberyCooldown = false
        TriggerClientEvent('QBCore:Notify', -1, 'El robo está disponible nuevamente', 'success')
        print("Cooldown finalizado")
    end)
end)

RegisterServerEvent('robo_contenedores:notifyPolice')
AddEventHandler('robo_contenedores:notifyPolice', function()
    local players = QBCore.Functions.GetPlayers()
    for _, playerId in pairs(players) do
        local player = QBCore.Functions.GetPlayer(playerId)
        if player.PlayerData.job.name == "police" then
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 0, 0},
                multiline = true,
                args = {"[Seguridad]", "¡Están intentando acceder al puerto!"}
            })
            print("Notificación enviada a la policía, jugador: " .. playerId)
        end
    end
end)

RegisterServerEvent('robo_contenedores:abrirContenedor')
AddEventHandler('robo_contenedores:abrirContenedor', function(tarjeta)
    print("Evento abrirContenedor recibido con tarjeta: " .. tarjeta)
    TriggerClientEvent('robo_contenedores:abrirContenedor', source, tarjeta)
end)

RegisterServerEvent('robo_contenedores:minijuegoFallido')
AddEventHandler('robo_contenedores:minijuegoFallido', function()
    local src = source
    if playerAttempts[src] then
        playerAttempts[src] = playerAttempts[src] - 1
        if playerAttempts[src] <= 0 then
            TriggerEvent('robo_contenedores:endRobbery', false, true) -- Pasar true para indicar que se falló por intentos
        else
            TriggerClientEvent('robo_contenedores:reiniciarMinijuego', src, playerCards[src]) -- Reiniciar el minijuego con la tarjeta usada
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Error en la lógica de intentos. Robo fallido.', 'error')
        TriggerEvent('robo_contenedores:endRobbery', false)
    end
end)