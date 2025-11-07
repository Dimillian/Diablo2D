local wanderSystem = {}
local vector = require("modules.vector")

local COHESION_RANGE = 120
local COHESION_STRENGTH = 0.1
local SEPARATION_RANGE = 70
local SEPARATION_STRENGTH = 0.5

local function randomDirection()
    local angle = math.random() * math.pi * 2
    return math.cos(angle), math.sin(angle)
end

local function calculateSeparation(entity, world)
    local pos = entity.position
    local size = entity.size or { w = 0, h = 0 }
    local centerX = pos.x + (size.w / 2)
    local centerY = pos.y + (size.h / 2)

    local separationX = 0
    local separationY = 0
    local separationCount = 0

    local otherEntities = world:queryEntities({ "foe", "position", "size" })

    for _, other in ipairs(otherEntities) do
        if other.id == entity.id or other.inactive then
            goto continue
        end

        local otherPos = other.position
        local otherSize = other.size or { w = 0, h = 0 }
        local otherCenterX = otherPos.x + (otherSize.w / 2)
        local otherCenterY = otherPos.y + (otherSize.h / 2)

        local dx = centerX - otherCenterX
        local dy = centerY - otherCenterY
        local distance = vector.length(dx, dy)

        if distance > 0 and distance < SEPARATION_RANGE then
            local ndx, ndy = vector.normalize(dx, dy)
            local strength = (SEPARATION_RANGE - distance) / SEPARATION_RANGE
            separationX = separationX + ndx * strength
            separationY = separationY + ndy * strength
            separationCount = separationCount + 1
        end

        ::continue::
    end

    if separationCount > 0 then
        local sepDx, sepDy, sepLength = vector.normalize(separationX, separationY)
        if sepLength > 0 then
            return sepDx * SEPARATION_STRENGTH, sepDy * SEPARATION_STRENGTH
        end
    end

    return 0, 0
end

local function calculatePackCohesion(entity, world)
    local foe = entity.foe
    if not foe or not foe.packId then
        return 0, 0
    end

    local packMembers = world:queryEntities({ "foe", "position", "movement" })
    local packCenterX = 0
    local packCenterY = 0
    local packCount = 0

    for _, member in ipairs(packMembers) do
        if member.id == entity.id or member.inactive or not member.foe or member.foe.packId ~= foe.packId then
            goto continue
        end

        local dx = member.position.x - entity.position.x
        local dy = member.position.y - entity.position.y
        local distance = vector.length(dx, dy)

        if distance > 0 and distance <= COHESION_RANGE then
            packCenterX = packCenterX + member.position.x
            packCenterY = packCenterY + member.position.y
            packCount = packCount + 1
        end

        ::continue::
    end

    if packCount == 0 then
        return 0, 0
    end

    packCenterX = packCenterX / packCount
    packCenterY = packCenterY / packCount

    local dx = packCenterX - entity.position.x
    local dy = packCenterY - entity.position.y
    local ndx, ndy = vector.normalize(dx, dy)

    return ndx * COHESION_STRENGTH, ndy * COHESION_STRENGTH
end

function wanderSystem.update(world, dt)
    local entities = world:queryEntities({ "wander", "movement" })

    for _, entity in ipairs(entities) do
        if entity.inactive then
            goto continue
        end

        if entity.playerControlled then
            goto continue
        end

        if entity.chase then
            goto continue
        end

        local wander = entity.wander
        local movement = entity.movement

        if not wander.elapsed then
            wander.elapsed = 0
        end

        if not wander.interval or wander.interval <= 0 then
            wander.interval = 3.0
        end

        if not wander.currentInterval then
            local variation = wander.interval * 0.3
            wander.currentInterval = wander.interval + (math.random() * variation * 2 - variation)

            movement.vx, movement.vy = randomDirection()
            if movement.lookDirection then
                movement.lookDirection.x = movement.vx
                movement.lookDirection.y = movement.vy
            else
                movement.lookDirection = { x = movement.vx, y = movement.vy }
            end
        end

        wander.elapsed = wander.elapsed + dt

        if wander.elapsed >= wander.currentInterval then
            wander.elapsed = 0

            local randDx, randDy = randomDirection()
            local cohDx, cohDy = calculatePackCohesion(entity, world)
            local sepDx, sepDy = calculateSeparation(entity, world)

            local combinedDx = randDx + cohDx + sepDx * 1.5
            local combinedDy = randDy + cohDy + sepDy * 1.5
            local ndx, ndy = vector.normalize(combinedDx, combinedDy)

            movement.vx = ndx
            movement.vy = ndy
            if movement.lookDirection then
                movement.lookDirection.x = ndx
                movement.lookDirection.y = ndy
            else
                movement.lookDirection = { x = ndx, y = ndy }
            end

            local variation = wander.interval * 0.3
            wander.currentInterval = wander.interval + (math.random() * variation * 2 - variation)
        else
            local cohDx, cohDy = calculatePackCohesion(entity, world)
            local sepDx, sepDy = calculateSeparation(entity, world)

            if cohDx ~= 0 or cohDy ~= 0 or sepDx ~= 0 or sepDy ~= 0 then
                local currentDx = movement.lookDirection and movement.lookDirection.x or 0
                local currentDy = movement.lookDirection and movement.lookDirection.y or 0

                local combinedDx = currentDx + cohDx * 0.5 + sepDx * 1.2
                local combinedDy = currentDy + cohDy * 0.5 + sepDy * 1.2
                local ndx, ndy = vector.normalize(combinedDx, combinedDy)

                movement.vx = ndx
                movement.vy = ndy
                if movement.lookDirection then
                    movement.lookDirection.x = ndx
                    movement.lookDirection.y = ndy
                end
            else
                if movement.lookDirection then
                    movement.vx = movement.lookDirection.x
                    movement.vy = movement.lookDirection.y
                end
            end
        end

        ::continue::
    end
end

return wanderSystem
