dk.inspect = {}

local keys = dk.keys
local typeNames = { 'ped', 'vehicle', 'object' }

local function modelName(entity)
    local name = GetEntityArchetypeName(entity)
    if name and name ~= '' then return name end
end

local function hashHex(hash)
    return ('0x%08X'):format(hash & 0xFFFFFFFF)
end

local function bounds(entity)
    local min, max = GetModelDimensions(GetEntityModel(entity))
    local function at(x, y, z) return GetOffsetFromEntityInWorldCoords(entity, x, y, z) end

    return {
        at(min.x, min.y, min.z), at(max.x, min.y, min.z), at(max.x, max.y, min.z), at(min.x, max.y, min.z),
        at(min.x, min.y, max.z), at(max.x, min.y, max.z), at(max.x, max.y, max.z), at(min.x, max.y, max.z),
    }
end

local function describe(entity)
    local model = GetEntityModel(entity)
    local pos = GetEntityCoords(entity)
    local net = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)

    return {
        name = modelName(entity),
        model = model,
        type = typeNames[GetEntityType(entity)] or 'unknown',
        net = net,
        pos = pos,
        heading = GetEntityHeading(entity),
    }
end

local function snippet(info)
    local model = info.name and ('`%s`'):format(info.name) or tostring(info.model)
    return ('{ model = %s, coords = %s },'):format(model, dk.vec4(info.pos, info.heading))
end

local function tick()
    local hit, _, entity = dk.raycast(-1, cache.ped, 60.0)
    if not hit or entity == 0 or not DoesEntityExist(entity) or GetEntityType(entity) == 0 then return end

    local info = describe(entity)
    dk.drawBox(bounds(entity), Config.colors.entity)

    dk.text3d(info.pos, table.concat({
        ('~b~%s~s~ %s'):format(info.type, info.name or '?'),
        ('%d  %s'):format(info.model, hashHex(info.model)),
        dk.vec4(info.pos, info.heading),
        info.net and ('net %d'):format(info.net) or 'local',
    }, '~n~'))

    if dk.pressed(keys.E) then
        dk.copy(snippet(info), info.name or 'entity')
    elseif dk.pressed(keys.H) then
        dk.copy(tostring(info.model))
    elseif dk.pressed(keys.G) then
        dk.copy(dk.vec4(info.pos, info.heading))
    end
end

function dk.inspect.start()
    if not dk.start('entity inspector') then return end

    dk.help({
        '[E] Copy model + coords',
        '[H] Copy hash',
        '[G] Copy vec4',
        '[Backspace] Close',
    })

    CreateThread(function()
        while not dk.pressed(keys.BACK) do
            dk.blockControls()
            tick()
            Wait(0)
        end

        dk.stop()
    end)
end
