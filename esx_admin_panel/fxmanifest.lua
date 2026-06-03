fx_version 'cerulean'
game 'gta5'

description 'ESX 综合管理面板 - 玩家管理/封禁/审计/权限'
author 'ESX Admin Panel'
version '1.0.0'

shared_scripts {
    'config.lua',
    'locales/*.lua',
}

client_scripts {
    'client/utils.lua',
    'client/main.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/permissions.lua',
    'server/audit_log.lua',
    'server/ban_system.lua',
    'server/commands.lua',
    'server/main.lua',
    'server/resource_monitor.lua',
}

ui_page 'client/nui/index.html'

files {
    'client/nui/index.html',
    'client/nui/style.css',
    'client/nui/app.js',
}

lua54 'yes'

dependencies {
    'es_extended',
    'mysql-async',
}
