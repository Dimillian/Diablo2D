local wanderSystem = {}
local vector = require("modules.vector")
local coordinates = require("systems.helpers.coordinates")

local function randomDirection()
    local angle = math.random() * math.pi * 2
    return math.cos(angle), math.sin(angle)
end

local function calculateSeparation(entity, world, wander)
    local centerX, centerY = coordinates.getEntityCenter(entity)
    if not centerX or not centerY then
        return 0, 0
    end

    local separationX = 0
    local separationY = 0
    local separationCount = 0

    local otherEntities = world:queryEntities({ "foe", "position", "size" })

    for _, other in ipairs(otherEntities) do
        if other.id == entity.id then
            goto continue
        end

        if other.inactive and other.inactive.isInactive then
            goto continue
        end

        local otherCenterX, otherCenterY = coordinates.getEntityCenter(other)
        if not otherCenterX or not otherCenterY then
            goto continue
        end

        local dx = centerX - otherCenterX
        local dy = centerY - otherCenterY
        local distance = vector.length(dx, dy)

        local separationRange = wander.separationRange
        if distance > 0 and distance < separationRange then
            local ndx, ndy = vector.normalize(dx, dy)
            local strength = (separationRange - distance) / separationRange
            separationX = separationX + ndx * strength
            separationY = separationY + ndy * strength
            separationCount = separationCount + 1
        end

        ::continue::
    end

    if separationCount > 0 then
        local sepDx, sepDy, sepLength = vector.normalize(separationX, separationY)
        if sepLength > 0 then
            return sepDx * wander.separationStrength, sepDy * wander.separationStrength
        end
    end

    return 0, 0
end

local function calculatePackCohesion(entity, world, wander)
    local foe = entity.foe
    if not foe or not foe.packId then
        return 0, 0
    end

    local packMembers = world:queryEntities({ "foe", "position", "movement" })
    local packCenterX = 0
    local packCenterY = 0
    local packCount = 0

    for _, member in ipairs(packMembers) do
        if member.id == entity.id or not member.foe or member.foe.packId ~= foe.packId then
            goto continue
        end

        if member.inactive and member.inactive.isInactive then
            goto continue
        end

        local dx = member.position.x - entity.position.x
        local dy = member.position.y - entity.position.y
        local distance = vector.length(dx, dy)

        if distance > 0 and distance <= wander.cohesionRange then
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

    return ndx * wander.cohesionStrength, ndy * wander.cohesionStrength
end

function wanderSystem.update(world, dt)
    local entities = world:queryEntities({ "wander", "movement" })

    for _, entity in ipairs(entities) do
        if entity.inactive and entity.inactive.isInactive then
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

        if not wander.currentInterval then
            local variation = wander.interval * wander.variance
            wander.currentInterval = wander.interval + (math.random() * variation * 2 - variation)

            movement.vx, movement.vy = randomDirection()
            movement.lookDirection.x = movement.vx
            movement.lookDirection.y = movement.vy
        end

        wander.elapsed = wander.elapsed + dt

        if wander.elapsed >= wander.currentInterval then
            wander.elapsed = 0

            local randDx, randDy = randomDirection()
            local cohDx, cohDy = calculatePackCohesion(entity, world, wander)
            local sepDx, sepDy = calculateSeparation(entity, world, wander)

            local combinedDx = (randDx * wander.randomWeight)
                + (cohDx * wander.cohesionImpulseWeight)
                + (sepDx * wander.separationImpulseWeight)
            local combinedDy = (randDy * wander.randomWeight)
                + (cohDy * wander.cohesionImpulseWeight)
                + (sepDy * wander.separationImpulseWeight)
            local ndx, ndy = vector.normalize(combinedDx, combinedDy)

            if ndx and ndy then
                movement.vx = ndx
                movement.vy = ndy
                movement.lookDirection.x = ndx
                movement.lookDirection.y = ndy
            end

            local variation = wander.interval * wander.variance
            wander.currentInterval = wander.interval + (math.random() * variation * 2 - variation)
        else
            local cohDx, cohDy = calculatePackCohesion(entity, world, wander)
            local sepDx, sepDy = calculateSeparation(entity, world, wander)

            if cohDx ~= 0 or cohDy ~= 0 or sepDx ~= 0 or sepDy ~= 0 then
                local currentDx = movement.lookDirection.x
                local currentDy = movement.lookDirection.y

                local combinedDx = currentDx
                    + (cohDx * wander.cohesionSteeringWeight)
                    + (sepDx * wander.separationSteeringWeight)
                local combinedDy = currentDy
                    + (cohDy * wander.cohesionSteeringWeight)
                    + (sepDy * wander.separationSteeringWeight)
                local ndx, ndy = vector.normalize(combinedDx, combinedDy)

                if ndx and ndy then
                    movement.vx = ndx
                    movement.vy = ndy
                    movement.lookDirection.x = ndx
                    movement.lookDirection.y = ndy
                end
            else
                movement.vx = movement.lookDirection.x
                movement.vy = movement.lookDirection.y
            end
        end

        ::continue::
    end
end

return wanderSystem
