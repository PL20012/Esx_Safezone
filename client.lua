local zones    = Config.Zones
local debug    = Config.Debug
local vehicle  = Config.VehicleBlock
local notify   = Config.Notification
local controls = Config.DisabledControls

local playerInZone  = false
local currentZone   = nil
local lastZoneCheck = 0

local Framework = {
    name   = Config.Framework or "standalone",
    object = nil,
    ready  = false,
}

local function initFramework()
    local fw = Framework.name

    if fw == "qb" then
        if GetResourceState("qb-core") == "started" then
            Framework.object = exports["qb-core"]:GetCoreObject()
            Framework.ready  = true
        else
            Framework.name  = "standalone"
            Framework.ready = true
        end

    elseif fw == "qbox" then
        if GetResourceState("qbx_core") == "started" then
            Framework.object = exports.qbx_core
            Framework.ready  = true
        elseif GetResourceState("qb-core") == "started" then
            Framework.object = exports["qb-core"]:GetCoreObject()
            Framework.ready  = true
        else
            Framework.name  = "standalone"
            Framework.ready = true
        end

    elseif fw == "ox" then
        if GetResourceState("ox_core") == "started" then
            Framework.object = exports.ox_core
            Framework.ready  = true
        else
            Framework.name  = "standalone"
            Framework.ready = true
        end

    elseif fw == "esx" then
        if GetResourceState("es_extended") == "started" then
            Framework.object = exports["es_extended"]:getSharedObject()
            Framework.ready  = true
        else
            Framework.name  = "standalone"
            Framework.ready = true
        end

    else
        Framework.name  = "standalone"
        Framework.ready = true
    end
end

local function pointInPolygon(px, py, points)
    local inside, n = false, #points
    local j = n
    for i = 1, n do
        local xi, yi = points[i].x, points[i].y
        local xj, yj = points[j].x, points[j].y
        if ((yi > py) ~= (yj > py)) and
           (px < (xj - xi) * (py - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

local function getPolygonCenter(zone)
    local cx, cy = 0, 0
    for i = 1, #zone.points do
        cx = cx + zone.points[i].x
        cy = cy + zone.points[i].y
    end
    return vector3(cx / #zone.points, cy / #zone.points, (zone.minZ + zone.maxZ) / 2)
end

local function isInZone(coords, zone)
    if zone.shape == "circle" then
        return #(coords - zone.coords) <= zone.radius
    elseif zone.shape == "polygon" then
        if coords.z < zone.minZ or coords.z > zone.maxZ then return false end
        return pointInPolygon(coords.x, coords.y, zone.points)
    end
    return false
end

local function getBorderPoint(zone, vehCoords)
    if zone.shape == "circle" then
        local dir = vehCoords - zone.coords
        dir = vector3(dir.x, dir.y, 0)
        local dist = #dir
        if dist == 0 then return zone.coords + vector3(zone.radius, 0, 0) end
        return zone.coords + (dir / dist) * (zone.radius - 1.5)
    end

    local closest, closestDist = nil, math.huge
    local points = zone.points
    for i = 1, #points do
        local a, b = points[i], points[(i % #points) + 1]
        local abx, aby = b.x - a.x, b.y - a.y
        local t = ((vehCoords.x - a.x) * abx + (vehCoords.y - a.y) * aby) / (abx * abx + aby * aby)
        t = math.max(0, math.min(1, t))
        local cx, cy = a.x + abx * t, a.y + aby * t
        local dist = (vehCoords.x - cx)^2 + (vehCoords.y - cy)^2
        if dist < closestDist then
            closestDist, closest = dist, vector2(cx, cy)
        end
    end

    if not closest then return nil end

    local dx, dy = vehCoords.x - closest.x, vehCoords.y - closest.y
    local len = math.sqrt(dx^2 + dy^2)
    if len > 0 then dx, dy = dx / len, dy / len else dx, dy = 1, 0 end
    return vector3(closest.x + dx * 2.0, closest.y + dy * 2.0, vehCoords.z)
end

local function drawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    local dist  = #(GetGameplayCamCoords() - vector3(x, y, z))
    local scale = math.min(math.max((1.0 / dist) * 2.5, 0.25), 0.65)

    SetTextScale(scale, scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(sx, sy)
end

local function drawCircleZone(zone, playerCoords)
    local dist = #(playerCoords - zone.coords)
    if dist > debug.markerDrawDist then return end

    local mc    = zone.markerColor
    local alpha = math.max(40, mc.a - math.floor(dist * 0.5))
    local c     = zone.coords

    DrawMarker(1, c.x, c.y, c.z - 1.0, 0,0,0, 0,0,0,
        zone.radius * 2, zone.radius * 2, 1.5,
        mc.r, mc.g, mc.b, alpha, false, true, 2, nil, nil, false)

    DrawMarker(0, c.x, c.y, c.z, 0,0,0, 0,0,0, 0.8, 0.8, 0.8,
        255, 255, 255, 200, false, true, 2, nil, nil, false)

    if dist < debug.labelDrawDist then
        drawText3D(c.x, c.y, c.z + 2.0,
            zone.name .. "\nRadius: " .. zone.radius .. "  |  " ..
            (zone.allowVehicle and "~g~Vehicle: ON" or "~r~Vehicle: OFF"))
    end
end

local function drawPolygonZone(zone, playerCoords)
    local center = getPolygonCenter(zone)
    if #(playerCoords - center) > debug.markerDrawDist then return end

    local mc     = zone.markerColor
    local points = zone.points

    for i = 1, #points do
        local a, b = points[i], points[(i % #points) + 1]
        for s = 0, 20 do
            local t  = s / 20
            local lx = a.x + (b.x - a.x) * t
            local ly = a.y + (b.y - a.y) * t
            DrawMarker(28, lx, ly, zone.minZ + 0.05, 0,0,0, 0,0,0, 0.3, 0.3, 0.3,
                mc.r, mc.g, mc.b, 150, false, true, 2, nil, nil, false)
        end
        DrawMarker(0, a.x, a.y, zone.minZ + 1.0, 0,0,0, 0,0,0, 0.5, 0.5, 0.5,
            mc.r, mc.g, mc.b, 220, false, true, 2, nil, nil, false)
    end

    if #(playerCoords - center) < debug.labelDrawDist then
        drawText3D(center.x, center.y, center.z + 2.0,
            zone.name .. "\nPolygon | Z: " .. zone.minZ .. " - " .. zone.maxZ .. "\n" ..
            (zone.allowVehicle and "~g~Vehicle: ON" or "~r~Vehicle: OFF"))
    end
end

CreateThread(function()
    initFramework()
end)

CreateThread(function()
    while true do
        local wait = 500
        if debug.showMarkers then
            wait = 0
            local coords = GetEntityCoords(PlayerPedId(), true)
            for i = 1, #zones do
                local z = zones[i]
                if z.shape == "circle" then
                    drawCircleZone(z, coords)
                else
                    drawPolygonZone(z, coords)
                end
            end
        end
        Wait(wait)
    end
end)

CreateThread(function()
    local frozenZone = nil

    while true do
        Wait(0)

        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            frozenZone = nil
        else
            local veh       = GetVehiclePedIsIn(ped, false)
            local vehCoords = GetEntityCoords(veh, true)
            local vel       = GetEntityVelocity(veh)
            local velLen    = math.sqrt(vel.x^2 + vel.y^2 + vel.z^2)

            if velLen > 0.5 then
                local lookahead = vector3(
                    vehCoords.x + (vel.x / velLen) * vehicle.lookahead,
                    vehCoords.y + (vel.y / velLen) * vehicle.lookahead,
                    vehCoords.z
                )

                local hitZone = nil
                for i = 1, #zones do
                    local z = zones[i]
                    if not z.allowVehicle and (isInZone(lookahead, z) or isInZone(vehCoords, z)) then
                        hitZone = z
                        break
                    end
                end

                if hitZone then
                    frozenZone = hitZone
                    local border = getBorderPoint(hitZone, vehCoords)
                    if border then
                        SetEntityCoords(veh, border.x, border.y, border.z, false, false, false, false)
                    end
                    SetEntityVelocity(veh, 0.0, 0.0, 0.0)
                    FreezeEntityPosition(veh, true)
                    Wait(vehicle.freezeDuration)
                    FreezeEntityPosition(veh, false)
                elseif frozenZone and not isInZone(vehCoords, frozenZone) then
                    frozenZone = nil
                end
            end
        end
    end
end)

local function disableCombat(ped)
    CreateThread(function()
        while playerInZone do
            Wait(0)
            for _, c in ipairs(controls) do
                DisableControlAction(c.group, c.control, true)
            end
            DisablePlayerFiring(ped, true)
        end
    end)
end

CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Wait(0) end
    Wait(1000)

    while true do
        Wait(100)

        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped, true)
        local now    = GetGameTimer()
        local found  = nil

        for i = 1, #zones do
            if isInZone(coords, zones[i]) then
                found = zones[i]
                break
            end
        end

        local inside = found ~= nil
        if (now - lastZoneCheck) > notify.debounceMs and inside ~= playerInZone then
            playerInZone  = inside
            currentZone   = found
            lastZoneCheck = now

            if inside then
                SendNUIMessage({
                    type     = "safezone",
                    status   = true,
                    zoneName = found.name,
                    file     = notify.soundFile,
                })
                disableCombat(ped)
            else
                SendNUIMessage({ type = "safezone", status = false })
            end
        end
    end
end)

RegisterCommand('checkzone', function()
    local coords = GetEntityCoords(PlayerPedId(), true)
    local found  = false

    for i = 1, #zones do
        if isInZone(coords, zones[i]) then
            found = true
        end
    end
end, false)