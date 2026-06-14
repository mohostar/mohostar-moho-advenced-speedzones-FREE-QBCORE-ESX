fx_version 'cerulean'
game 'gta5'

author 'MOHO'
description 'Slow Zone | @mohostar67'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

shared_script '@ox_lib/init.lua'
shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'