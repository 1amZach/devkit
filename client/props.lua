dk.props = {}

local keys = dk.keys
local placed = {}
local preview
local lastModel = 'prop_bench_01a'

local axes = { 'yaw', 'pitch', 'roll' }

local function spawn(hash, coords)
    local obj = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)

    SetEntityAlpha(obj, 180, false)
    SetEntityCollision(obj, false, false)
    FreezeEntityPosition(obj, true)

    return obj
end

local function snippet(p)
    return ('{ model = `%s`, coords = %s, rotation = %s },'):format(p.model, dk.vec3(p.coords), dk.vec3(p.rot))
end

local function placement(model, obj)
    local pos = GetEntityCoords(obj)
    local rot = GetEntityRotation(obj, 2)

    return { model = model, coords = pos, rot = rot, entity = obj }
end

local function helpText(axis)
    dk.help({
        ('[Scroll] Rotate %s  [R] Change axis'):format(axes[axis]),
        '[Up/Down] Raise / lower',
        '[G] Snap to ground  [X] Reset rotation',
        '[E] Copy  [Enter] Place',
        '[Shift] Fine steps',
        '[Backspace] Done',
    })
end

local function run(model, hash)
    local rot = { yaw = GetEntityHeading(cache.ped), pitch = 0.0, roll = 0.0 }
    local axis, lift = 1, 0.0
    local pos

    preview = spawn(hash, GetEntityCoords(cache.ped))
    helpText(axis)

    while true do
        dk.blockControls()

        local hit, coords = dk.raycast(1 | 16, preview, 30.0)
        if hit then pos = coords end

        local fine = dk.held(keys.SHIFT)
        local step = fine and 1.0 or 5.0
        local speed = (fine and 0.1 or 1.0) * GetFrameTime()
        local name = axes[axis]

        if dk.pressed(keys.SCROLL_UP) then
            rot[name] = (rot[name] + step) % 360
        elseif dk.pressed(keys.SCROLL_DOWN) then
            rot[name] = (rot[name] - step) % 360
        end

        if dk.held(keys.UP) then lift = lift + speed end
        if dk.held(keys.DOWN) then lift = lift - speed end

        if dk.pressed(keys.R) then
            axis = axis % #axes + 1
            helpText(axis)
        end

        if dk.pressed(keys.X) then
            rot.pitch, rot.roll = 0.0, 0.0
        end

        if pos then
            SetEntityCoordsNoOffset(preview, pos.x, pos.y, pos.z + lift, false, false, false)
            SetEntityRotation(preview, rot.pitch, rot.roll, rot.yaw, 2, false)
        end

        -- let the game settle it, then read back what it chose so the next frame keeps it
        if dk.pressed(keys.G) and pos then
            PlaceObjectOnGroundProperly(preview)
            local settled = GetEntityCoords(preview)
            local r = GetEntityRotation(preview, 2)
            lift = settled.z - pos.z
            rot.pitch, rot.roll = r.x, r.y
        end

        if dk.pressed(keys.E) then
            dk.copy(snippet(placement(model, preview)), model)
        end

        if dk.pressed(keys.ENTER) and pos then
            ResetEntityAlpha(preview)
            SetEntityCollision(preview, true, true)
            placed[#placed + 1] = placement(model, preview)

            preview = spawn(hash, GetEntityCoords(preview))
            lib.notify({ description = ('Placed %s (%d total)'):format(model, #placed) })
        end

        if dk.pressed(keys.BACK) then break end

        Wait(0)
    end

    DeleteEntity(preview)
    preview = nil
end

function dk.props.place(model)
    if not model then
        local input = lib.inputDialog('Place prop', {
            { type = 'input', label = 'Model', default = lastModel, required = true },
        })
        if not input then return end
        model = input[1]
    end

    local hash = tonumber(model) or joaat(model)

    if not IsModelInCdimage(hash) then
        return lib.notify({ description = ('%s is not a valid model'):format(model), type = 'error' })
    end

    if not dk.start('prop placer') then return end

    lastModel = model
    lib.requestModel(hash)

    CreateThread(function()
        run(model, hash)
        SetModelAsNoLongerNeeded(hash)
        dk.stop()
    end)
end

function dk.props.count()
    return #placed
end

function dk.props.copyAll()
    local lines = {}

    for i = 1, #placed do
        lines[i] = snippet(placed[i])
    end

    dk.copy(table.concat(lines, '\n'), ('%d props'):format(#placed))
end

function dk.props.clear()
    for i = 1, #placed do
        if DoesEntityExist(placed[i].entity) then
            DeleteEntity(placed[i].entity)
        end
    end

    placed = {}
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    dk.props.clear()
    if preview then DeleteEntity(preview) end
end)
