local vector = require("modules.vector")

local detectionSystem = {}

function detectionSystem.update(world, _dt)
    local player = world:getPlayer()
    if not player or not player.position then
        return
    end

    local foes = world:queryEntities({ "detection", "position" })

    for _, foe in ipairs(foes) do
        -- Skip inactive entities (too far from player)
        if foe.inactive then
            goto continue
        end

        local detection = foe.detection
        local foePos = foe.position
        local playerPos = player.position

        local dist = vector.distance(foePos.x, foePos.y, playerPos.x, playerPos.y)

        -- Check if player is within detection range
        if dist <= detection.range then
            -- Player detected: add chase component if not already chasing
            if not foe.chase then
                local createChase = require("components.chase")
                world:addComponent(foe.id, "chase", createChase({ targetId = player.id }))
            end
            detection.detectedTargetId = player.id
        else
            -- Player out of range: remove chase component
            if foe.chase then
                world:removeComponent(foe.id, "chase")
            end
            detection.detectedTargetId = nil
        end

        ::continue::
    end
end

return detectionSystem
