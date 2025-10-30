local detectionSystem = {}

local function distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function detectionSystem.update(world, _dt)
    local player = world:getPlayer()
    if not player or not player.position then
        return
    end

    local foes = world:queryEntities({ "detection", "position" })

    for _, foe in ipairs(foes) do
        local detection = foe.detection
        local foePos = foe.position
        local playerPos = player.position

        local dist = distance(foePos.x, foePos.y, playerPos.x, playerPos.y)

        -- Check if player is within detection range
        if dist <= detection.range then
            -- Player detected: add chase component if not already chasing
            if not foe.chase then
                local createChase = require("components.chase")
                foe.chase = createChase({ targetId = player.id })
                -- Update component sets
                if world.componentSets.chase then
                    world.componentSets.chase[foe.id] = true
                else
                    world.componentSets.chase = { [foe.id] = true }
                end
            end
            detection.detectedTargetId = player.id
        else
            -- Player out of range: remove chase component
            if foe.chase then
                foe.chase = nil
                if world.componentSets.chase then
                    world.componentSets.chase[foe.id] = nil
                end
            end
            detection.detectedTargetId = nil
        end
    end
end

return detectionSystem
