fx_version 'cerulean'
game 'gta5'

author 'xPelos ft.Abdon'
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

ui_page 'html/torpedo.html'

files {
    'html/torpedo.html',
    'html/minigame.css',
    'html/minigame.js',
    'html/soplete.css',
    'html/soplete.js',
}

dependencies {
    'qb-core'
}
