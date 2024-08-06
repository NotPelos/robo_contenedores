fx_version 'cerulean'
game 'gta5'

author 'TuNombre'
description 'Robo a Contenedores con Minijuego de Swipe'
version '1.0.0'

client_scripts {
    'client.lua',
    'config.lua'
}

server_scripts {
    'server.lua',
    'config.lua'
}

ui_page 'html/minigame.html'

files {
    'html/minigame.html',
    'html/minigame.css',
    'html/minigame.js'
}

dependencies {
    'qb-core'
}
