fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'devkit'
description 'In-game tools for building and mapping out servers'
version '0.1.0'
author 'IamZach'
discord 'https://discord.gg/agn'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/utils.lua',
    'client/coords.lua',
    'client/inspect.lua',
    'client/props.lua',
    'client/zones.lua',
    'client/main.lua',
}

server_script 'server/main.lua'

dependency 'ox_lib'
