fx_version "cerulean"
game "gta5"
lua54 "yes"
use_fxv2_oal "yes"

shared_script "config.lua"
client_script "client.lua"
server_script {
    "@mysql-async/lib/MySQL.lua",
    "@oxmysql/lib/MySQL.lua",
    "server.lua"
}

files {
    "html/index.html",
    "html/script.js",
    "html/style.css"
}
ui_page "html/index.html"

dependency "loaf_lib"