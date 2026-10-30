dk.coords = {}

local showing = false

local function streetName(pos)
    local street, cross = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
    local name = GetStreetNameFromHashKey(street)

    if cross ~= 0 then
        name = ('%s / %s'):format(name, GetStreetNameFromHashKey(cross))
    end

    return name
end

local function draw()
    local pos = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    local zone = GetLabelText(GetNameOfZone(pos.x, pos.y, pos.z))
    local interior = GetInteriorFromEntity(cache.ped)

    dk.text(0.01, 0.30, ('~y~x~s~ %s   ~y~y~s~ %s   ~y~z~s~ %s   ~y~h~s~ %s'):format(
        dk.num(pos.x), dk.num(pos.y), dk.num(pos.z), dk.num(heading)
    ))
    dk.text(0.01, 0.33, ('%s, %s'):format(streetName(pos), zone), 0.32)

    if interior ~= 0 then
        dk.text(0.01, 0.355, ('interior %d  room %d'):format(interior, GetRoomKeyFromEntity(cache.ped)), 0.32)
    end

    local hit, aim = dk.raycast(1 | 16)

    if hit then
        dk.marker(aim, Config.colors.line)
        dk.text(0.01, 0.38, ('~y~aim~s~ %s'):format(dk.vec3(aim)), 0.32)
    end
end

function dk.coords.showing()
    return showing
end

function dk.coords.toggle()
    showing = not showing
    if not showing then return end

    CreateThread(function()
        while showing do
            draw()
            Wait(0)
        end
    end)
end

function dk.coords.copy(kind)
    local pos = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)

    if kind == 'vec3' then
        dk.copy(dk.vec3(pos))
    elseif kind == 'vec4' then
        dk.copy(dk.vec4(pos, heading))
    elseif kind == 'heading' then
        dk.copy(dk.num(heading))
    elseif kind == 'aim' then
        local hit, aim = dk.raycast(1 | 16, nil, 100.0)
        if not hit then
            return lib.notify({ description = 'Not looking at anything', type = 'error' })
        end
        dk.copy(dk.vec3(aim))
    end
end
