fx_version 'cerulean'
game 'gta5'

author 'Gift System'
description 'FiveM 赠礼系统 - 支持给玩家赠送物品、货币、武器、车辆，以及红包功能'
version '1.0.0'

lua54 'yes'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/main.lua'
}

client_scripts {
    'config.lua',
    'client/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/admin.html',
    'web/css/style.css',
    'web/js/admin.js',
    'web/js/user.js'
}

dependencies {
    'oxmysql',
    'es_extended'
}
