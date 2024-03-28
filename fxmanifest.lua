fx_version "cerulean"

description "https://github.com/RafaelRMartins"
author "Rafael Martins"
version '1.0.0'

lua54 'yes'

games {
  "gta5"
}

ui_page 'web/build/index.html'

client_scripts {
	'@vrp/lib/utils.lua',
  'config.lua',
  'client/**/*',
}

files {
  'web/build/index.html',
	'web/build/**/*',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  '@vrp/lib/utils.lua',
  'config.lua',
  'server/**/*',
}