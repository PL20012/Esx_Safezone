fx_version 'adamant'
game 'gta5'

name        "SafeZone"
description "Safe Zone with PolyZone support — poly / box / circle / combo shapes"
author      "your name"

shared_scripts {
    'config.lua',
}

client_scripts {
    'client.lua',
}

files {
    'interface/index.html',
    'interface/style.css',
    'interface/index.js',
    'interface/sound/*.mp3',
}

ui_page 'interface/index.html'