local allowed

local function canUse()
    if allowed == nil then
        allowed = lib.callback.await('devkit:canUse', false) == true
    end

    return allowed
end

local function openMenu()
    local props = dk.props.count()

    lib.registerContext({
        {
            id = 'devkit',
            title = 'Devkit',
            options = {
                {
                    title = 'Coords overlay',
                    description = dk.coords.showing() and 'On' or 'Off',
                    icon = 'location-crosshairs',
                    onSelect = dk.coords.toggle,
                },
                { title = 'Copy coords', icon = 'copy', menu = 'devkit_coords' },
                { title = 'Entity inspector', icon = 'magnifying-glass', onSelect = dk.inspect.start },
                { title = 'Place prop', icon = 'cube', onSelect = function() dk.props.place() end },
                {
                    title = 'Placed props',
                    description = ('%d placed'):format(props),
                    icon = 'boxes-stacked',
                    menu = 'devkit_props',
                    disabled = props == 0,
                },
                { title = 'Poly zone', icon = 'draw-polygon', onSelect = dk.zones.poly },
                { title = 'Box zone', icon = 'vector-square', onSelect = dk.zones.box },
            },
        },
        {
            id = 'devkit_coords',
            title = 'Copy coords',
            menu = 'devkit',
            options = {
                { title = 'vec3', onSelect = dk.coords.copy, args = 'vec3' },
                { title = 'vec4', onSelect = dk.coords.copy, args = 'vec4' },
                { title = 'Heading', onSelect = dk.coords.copy, args = 'heading' },
                { title = 'Where I\'m looking', onSelect = dk.coords.copy, args = 'aim' },
            },
        },
        {
            id = 'devkit_props',
            title = 'Placed props',
            menu = 'devkit',
            options = {
                { title = 'Copy all', icon = 'copy', onSelect = dk.props.copyAll },
                { title = 'Delete all', icon = 'trash', onSelect = dk.props.clear },
            },
        },
    })

    lib.showContext('devkit')
end

local shortcuts = {
    coords = dk.coords.toggle,
    inspect = dk.inspect.start,
    prop = dk.props.place,
    poly = dk.zones.poly,
    box = dk.zones.box,
}

RegisterCommand(Config.command, function(_, args)
    if not canUse() then
        return lib.notify({ description = 'You don\'t have access to this', type = 'error' })
    end

    local shortcut = shortcuts[args[1]]

    if shortcut then
        shortcut(args[2])
    else
        openMenu()
    end
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.command, 'Open the devkit menu', {
    { name = 'tool', help = 'coords, inspect, prop, poly or box (optional)' },
    { name = 'model', help = 'prop model, only used with prop' },
})

if Config.key then
    RegisterKeyMapping(Config.command, 'Open devkit', 'keyboard', Config.key)
end
