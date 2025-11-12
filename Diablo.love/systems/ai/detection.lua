local vector = require("modules.vector")
local createChase = require("components.chase")

local detectionSystem = {}

local function ensureChase(world, foe, targetId)
    if foe.chase then
        foe.chase.targetId = targetId
        return
    end

    world:addComponent(foe.id, "chase", createChase({ targetId = targetId }))
end

function detectionSystem.update(world, _dt)
    local player = world:getPlayer()
    if not player or not player.position then
        return
    end

    local foes = world:queryEntities({ "detection", "position" })

    for _, foe in ipairs(foes) do
        -- Skip inactive entities (too far from player)
        if foe.inactive and foe.inactive.isInactive then
            goto continue
        end

        local detection = foe.detection
        local foePos = foe.position
        local playerPos = player.position

        local distSquared = vector.distanceSquared(foePos.x, foePos.y, playerPos.x, playerPos.y)
        local range = detection.range or 0
        local rangeSquared = range * range
        local detected = false
        local hasForcedAggro = detection.forceAggro and detection.detectedTargetId == player.id

        if hasForcedAggro then
            local leashRange = detection.leashRange
            if not leashRange then
                local extension = detection.leashExtension or 0
                leashRange = math.max(range, range + extension)
                detection.leashRange = leashRange
            end

            local leashSquared = (detection.leashRange or range) * (detection.leashRange or range)
            if distSquared <= leashSquared then
                detected = true
            else
                detection.forceAggro = false
                detection.leashRange = nil
            end
        elseif distSquared <= rangeSquared then
            detected = true
            detection.leashRange = nil
        end

        if detected then
            detection.detectedTargetId = player.id
            ensureChase(world, foe, player.id)
        else
            detection.detectedTargetId = nil
            if foe.chase then
                world:removeComponent(foe.id, "chase")
            end
        end

        ::continue::
    end
end

return detectionSystem
