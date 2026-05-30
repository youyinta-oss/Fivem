fx_version 'cerulean'
game 'gta5'

author 'Tuning System'
description 'Standalone Real-time Vehicle Tuning System'
version '1.0.0'

shared_script '@oxmysql/lib/MySQL.lua'

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
