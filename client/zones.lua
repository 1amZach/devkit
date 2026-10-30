dk.zones = {}

local keys = dk.keys
local colors = Config.colors

local function finish(code)
    print(code)
    dk.copy(code, 'zone (also printed to F8)')
end

local function averageZ(points, extra)
    local total, n = 0.0, #points

    for i = 1, n do
        total = total + points[i].z
    end

    if extra then
        total, n = total + extra.z, n + 1
    end

    return n > 0 and total / n or 0.0
end

local function drawWall(a, b, z, half, line, wall)
    local a1, b1 = vector3(a.x, a.y, z - half), vector3(b.x, b.y, z - half)
    local a2, b2 = vector3(a.x, a.y, z + half), vector3(b.x, b.y, z + half)

    dk.line(a1, b1, line)
    dk.line(a2, b2, line)
    dk.line(a1, a2, line)
    dk.quad(a1, b1, b2, a2, wall)
end

local function polyCode(points, thickness)
    local z = averageZ(points)
    local lines = { 'lib.zones.poly({', '    points = {' }

    for i = 1, #points do
        local p = points[i]
        lines[#lines + 1] = ('        vec3(%s, %s, %s),'):format(dk.num(p.x), dk.num(p.y), dk.num(z))
    end

    lines[#lines + 1] = '    },'
    lines[#lines + 1] = ('    thickness = %s,'):format(dk.num(thickness))
    lines[#lines + 1] = '})'

    return table.concat(lines, '\n')
end

function dk.zones.poly()
    if not dk.start('zone builder') then return end

    dk.help({
        '[E] Add point  [X] Undo point',
        '[Scroll] Thickness',
        '[Enter] Copy zone',
        '[Backspace] Cancel',
    })

    CreateThread(function()
        local points = {}
        local thickness = 4.0

        while true do
            dk.blockControls()

            local hit, cursor = dk.raycast(1 | 16, nil, 60.0)
            local count = #points
            local z = averageZ(points, hit and cursor)
            local half = thickness / 2

            for i = 1, count do
                local nextPoint = points[i + 1]
                if nextPoint then
                    drawWall(points[i], nextPoint, z, half, colors.line, colors.wall)
                end
                dk.marker(points[i], colors.line)
            end

            if hit then
                dk.marker(cursor, colors.preview)

                if count > 0 then
                    drawWall(points[count], cursor, z, half, colors.preview, colors.wall)
                end

                if count > 1 then
                    drawWall(cursor, points[1], z, half, colors.preview, colors.wall)
                end
            elseif count > 2 then
                drawWall(points[count], points[1], z, half, colors.preview, colors.wall)
            end

            local step = dk.held(keys.SHIFT) and 0.1 or 0.5

            if dk.pressed(keys.SCROLL_UP) then
                thickness = thickness + step
            elseif dk.pressed(keys.SCROLL_DOWN) then
                thickness = math.max(0.5, thickness - step)
            end

            if dk.pressed(keys.E) and hit then
                points[count + 1] = cursor
            elseif dk.pressed(keys.X) then
                points[count] = nil
            end

            if dk.pressed(keys.ENTER) then
                if count < 3 then
                    lib.notify({ description = 'A poly zone needs at least 3 points', type = 'error' })
                else
                    finish(polyCode(points, thickness))
                    break
                end
            end

            if dk.pressed(keys.BACK) then break end

            Wait(0)
        end

        dk.stop()
    end)
end

local function boxCorners(c, size, heading)
    local r = math.rad(heading)
    local cos, sin = math.cos(r), math.sin(r)
    local hx, hy, hz = size.x / 2, size.y / 2, size.z / 2

    local function at(x, y, z)
        return vector3(c.x + x * cos - y * sin, c.y + x * sin + y * cos, c.z + z)
    end

    return {
        at(-hx, -hy, -hz), at(hx, -hy, -hz), at(hx, hy, -hz), at(-hx, hy, -hz),
        at(-hx, -hy, hz), at(hx, -hy, hz), at(hx, hy, hz), at(-hx, hy, hz),
    }
end

local function boxCode(center, size, heading)
    return table.concat({
        'lib.zones.box({',
        ('    coords = %s,'):format(dk.vec3(center)),
        ('    size = %s,'):format(dk.vec3(size)),
        ('    rotation = %s,'):format(dk.num(heading)),
        '})',
    }, '\n')
end

function dk.zones.box()
    if not dk.start('zone builder') then return end

    dk.help({
        '[Left/Right] Width  [Up/Down] Length',
        '[PgUp/PgDn] Height  [Scroll] Rotate',
        '[E] Lock / unlock position',
        '[Enter] Copy zone',
        '[Backspace] Cancel',
    })

    CreateThread(function()
        local size = vector3(4.0, 4.0, 3.0)
        local heading = GetEntityHeading(cache.ped)
        local center
        local locked = false

        while true do
            dk.blockControls()

            local fine = dk.held(keys.SHIFT)
            local rate = (fine and 0.5 or 3.0) * GetFrameTime()
            local sx, sy, sz = size.x, size.y, size.z

            if dk.held(keys.RIGHT) then sx = sx + rate end
            if dk.held(keys.LEFT) then sx = sx - rate end
            if dk.held(keys.UP) then sy = sy + rate end
            if dk.held(keys.DOWN) then sy = sy - rate end
            if dk.held(keys.PGUP) then sz = sz + rate end
            if dk.held(keys.PGDN) then sz = sz - rate end

            size = vector3(math.max(0.25, sx), math.max(0.25, sy), math.max(0.25, sz))

            local step = fine and 1.0 or 5.0

            if dk.pressed(keys.SCROLL_UP) then
                heading = (heading + step) % 360
            elseif dk.pressed(keys.SCROLL_DOWN) then
                heading = (heading - step) % 360
            end

            if not locked then
                local hit, cursor = dk.raycast(1 | 16, nil, 60.0)
                if hit then
                    center = cursor + vector3(0.0, 0.0, size.z / 2)
                end
            end

            if dk.pressed(keys.E) and center then
                locked = not locked
            end

            if center then
                local corners = boxCorners(center, size, heading)
                local col = locked and colors.line or colors.preview

                dk.drawBox(corners, col)
                for i = 1, 4 do
                    local j = i % 4 + 1
                    dk.quad(corners[i], corners[j], corners[j + 4], corners[i + 4], colors.wall)
                end

                dk.text3d(center, ('%s x %s x %s'):format(dk.num(size.x), dk.num(size.y), dk.num(size.z)))
            end

            if dk.pressed(keys.ENTER) and center then
                finish(boxCode(center, size, heading))
                break
            end

            if dk.pressed(keys.BACK) then break end

            Wait(0)
        end

        dk.stop()
    end)
end
