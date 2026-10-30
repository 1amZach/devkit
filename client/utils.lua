dk = {}

dk.keys = {
    E = 38,
    G = 47,
    H = 74,
    R = 45,
    X = 73,
    SHIFT = 21,
    ENTER = 191,
    BACK = 194,
    UP = 172,
    DOWN = 173,
    LEFT = 174,
    RIGHT = 175,
    PGUP = 10,
    PGDN = 11,
    SCROLL_UP = 15,
    SCROLL_DOWN = 14,
}

local blocked = {
    14, 15, 16, 17, 24, 25, 37, 38, 44, 45, 47, 73, 74,
    140, 141, 142, 172, 173, 174, 175, 257, 263,
}

function dk.blockControls()
    for i = 1, #blocked do
        DisableControlAction(0, blocked[i], true)
    end
end

function dk.pressed(key)
    return IsDisabledControlJustPressed(0, key)
end

function dk.held(key)
    return IsDisabledControlPressed(0, key)
end

-- Only one interactive tool runs at a time, otherwise the key handling fights itself.
function dk.start(name)
    if dk.active then
        lib.notify({ description = ('Close the %s first'):format(dk.active), type = 'error' })
        return false
    end

    dk.active = name
    return true
end

function dk.stop()
    dk.active = nil
    lib.hideTextUI()
end

function dk.help(lines)
    lib.showTextUI(table.concat(lines, '  \n'), { position = 'left-center' })
end

local fmt = ('%%.%df'):format(Config.decimals)

function dk.num(n)
    return fmt:format(n)
end

function dk.vec3(c)
    return ('vec3(%s, %s, %s)'):format(dk.num(c.x), dk.num(c.y), dk.num(c.z))
end

function dk.vec4(c, w)
    return ('vec4(%s, %s, %s, %s)'):format(dk.num(c.x), dk.num(c.y), dk.num(c.z), dk.num(w))
end

function dk.copy(text, label)
    lib.setClipboard(text)
    lib.notify({ description = ('Copied %s'):format(label or text), type = 'success' })
end

local function camDirection()
    local rot = GetGameplayCamRot(2)
    local pitch, yaw = math.rad(rot.x), math.rad(rot.z)
    local flat = math.abs(math.cos(pitch))

    return vector3(-math.sin(yaw) * flat, math.cos(yaw) * flat, math.sin(pitch))
end

-- Synchronous on purpose. The async probe takes a frame to resolve, which makes
-- anything drawn in the same loop flicker.
function dk.raycast(flags, ignore, dist)
    local from = GetGameplayCamCoord()
    local to = from + camDirection() * (dist or 40.0)
    local ray = StartExpensiveSynchronousShapeTestLosProbe(
        from.x, from.y, from.z, to.x, to.y, to.z, flags or -1, ignore or cache.ped, 7
    )
    local _, hit, coords, normal, entity = GetShapeTestResult(ray)

    return hit == 1 or hit == true, coords, entity, normal
end

function dk.text(x, y, text, scale)
    SetTextFont(4)
    SetTextScale(0.0, scale or 0.4)
    SetTextColour(255, 255, 255, 230)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

function dk.text3d(coords, text, scale)
    local visible, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if not visible then return end

    SetTextCentre(true)
    dk.text(x, y, text, scale or 0.3)
end

function dk.line(a, b, col)
    DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, col[1], col[2], col[3], col[4])
end

-- a, b along the bottom, c, d along the top. DrawPoly is one-sided so draw both windings.
function dk.quad(a, b, c, d, col)
    local r, g, bl, al = col[1], col[2], col[3], col[4]

    DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z, r, g, bl, al)
    DrawPoly(a.x, a.y, a.z, c.x, c.y, c.z, d.x, d.y, d.z, r, g, bl, al)
    DrawPoly(c.x, c.y, c.z, b.x, b.y, b.z, a.x, a.y, a.z, r, g, bl, al)
    DrawPoly(d.x, d.y, d.z, c.x, c.y, c.z, a.x, a.y, a.z, r, g, bl, al)
end

local edges = {
    { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 },
    { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
    { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 },
}

-- corners 1-4 are the bottom face, 5-8 the top, same winding
function dk.drawBox(corners, col)
    for i = 1, #edges do
        local e = edges[i]
        dk.line(corners[e[1]], corners[e[2]], col)
    end
end

function dk.marker(coords, col)
    DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.12, 0.12, 0.12, col[1], col[2], col[3], 200, false, false, 2, false, nil, nil, false)
end
