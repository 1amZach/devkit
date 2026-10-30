Config = {}

-- Players need this ace to use anything. Example for server.cfg:
--   add_ace group.admin devkit allow
Config.ace = 'devkit'

Config.command = 'devkit'
Config.key = 'F7' -- false to skip registering a keybind

-- decimal places used when copying coords
Config.decimals = 2

Config.colors = {
    line = { 255, 170, 30, 255 },
    wall = { 255, 170, 30, 50 },
    preview = { 255, 255, 255, 120 },
    entity = { 80, 200, 255, 255 },
}
