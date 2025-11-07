local vector = require("modules.vector")

local chaseSystem = {}

local DEFAULT_SEPARATION_BUFFER = 20
local DEFAULT_FOE_SEPARATION_RADIUS = 40
local DEFAULT_FOE_SEPARATION_STRENGTH = 0.6

local function getCenterAndRadius(entity)
    local pos = entity.position
    local size = entity.size or { w = 0, h = 0 }

    local width = size.w or 0
    local height = size.h or 0

    local centerX = pos.x + width * 0.5
    local centerY = pos.y + height * 0.5
    local radius = math.max(width, height) * 0.5

    return centerX, centerY, radius
end

-- Calculate separation force from nearby foes to prevent stacking
local function calculateFoeSeparation(entity, world, myCenterX, myCenterY)
    local separationRadius = DEFAULT_FOE_SEPARATION_RADIUS
    local separationStrength = DEFAULT_FOE_SEPARATION_STRENGTH

    local separationX = 0
    local separationY = 0
    local separationCount = 0

    -- Query all other entities with chase component (other foes)
    local otherEntities = world:queryEntities({ "chase", "position", "size" })

    for _, other in ipairs(otherEntities) do
        -- Skip self and inactive entities
        if other.id == entity.id or other.inactive then
            goto continue
        end

        local otherCenterX, otherCenterY = getCenterAndRadius(other)

        -- Calculate distance to other foe
        local dx = myCenterX - otherCenterX
        local dy = myCenterY - otherCenterY
        local distance = vector.length(dx, dy)

        -- If within separation radius, add repulsion force
        if distance > 0 and distance < separationRadius then
            -- Normalize direction away from other foe
            local ndx, ndy = vector.normalize(dx, dy)

            -- Strength increases as distance decreases (inverse relationship)
            local strength = (separationRadius - distance) / separationRadius
            separationX = separationX + ndx * strength
            separationY = separationY + ndy * strength
            separationCount = separationCount + 1
        end

        ::continue::
    end

    -- Normalize and scale separation force
    if separationCount > 0 then
        local sepDx, sepDy, sepLength = vector.normalize(separationX, separationY)
        if sepLength > 0 then
            return sepDx * separationStrength, sepDy * separationStrength
        end
    end

    return 0, 0
end

function chaseSystem.update(world, _dt)
    local entities = world:queryEntities({ "chase", "movement", "position" })

    for _, entity in ipairs(entities) do
        -- Skip inactive entities (too far from player)
        if entity.inactive then
            goto continue
        end

        local chase = entity.chase
        local target = world:getEntity(chase.targetId)

        if not target or not target.position then
            goto continue
        end

        local myCenterX, myCenterY, myRadius = getCenterAndRadius(entity)
        local targetCenterX, targetCenterY, targetRadius = getCenterAndRadius(target)

        -- Calculate direction to target
        local dx = targetCenterX - myCenterX
        local dy = targetCenterY - myCenterY
        local ndx, ndy, distance = vector.normalize(dx, dy)

        if distance <= 0 then
            entity.movement.vx = 0
            entity.movement.vy = 0
            entity.movement.maxDistance = 0
            goto continue
        end

        local separationBuffer = chase.separationBuffer or DEFAULT_SEPARATION_BUFFER
        local stopDistance = math.max(0, (myRadius + targetRadius) + separationBuffer)

        if distance <= stopDistance then
            entity.movement.vx = 0
            entity.movement.vy = 0
            entity.movement.maxDistance = 0
            goto continue
        end

        -- Calculate separation force from nearby foes
        local sepDx, sepDy = calculateFoeSeparation(entity, world, myCenterX, myCenterY)

        -- Combine chase direction with separation force
        -- Separation is weighted less so chase still takes priority
        local combinedDx = ndx + sepDx
        local combinedDy = ndy + sepDy
        local combinedNdx, combinedNdy = vector.normalize(combinedDx, combinedDy)

        -- Ensure lookDirection exists
        if not entity.movement.lookDirection then
            entity.movement.lookDirection = { x = 0, y = -1 }
        end

        entity.movement.lookDirection.x = combinedNdx
        entity.movement.lookDirection.y = combinedNdy
        entity.movement.vx = combinedNdx
        entity.movement.vy = combinedNdy
        entity.movement.maxDistance = distance - stopDistance

        ::continue::
    end
end

return chaseSystem
