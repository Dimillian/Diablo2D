local vector = require("modules.vector")

local chaseSystem = {}

local DEFAULT_SEPARATION_BUFFER = 20

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

        -- Instruct movement to advance only up to the separation threshold
        entity.movement.vx = ndx
        entity.movement.vy = ndy
        entity.movement.maxDistance = distance - stopDistance

        ::continue::
    end
end

return chaseSystem
