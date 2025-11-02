local vector = require("modules.vector")

local foeAttackSystem = {}

local function getEntityCenter(entity)
    if not entity or not entity.position then
        return nil, nil
    end

    local x = entity.position.x
    local y = entity.position.y

    if entity.size then
        x = x + (entity.size.w or 0) / 2
        y = y + (entity.size.h or 0) / 2
    end

    return x, y
end

function foeAttackSystem.update(world, dt)
    -- Query entities with foe, chase, combat, position, and health components
    local entities = world:queryEntities({ "foe", "chase", "combat", "position" })

    for _, foe in ipairs(entities) do
        -- Skip inactive entities
        if foe.inactive then
            goto continue
        end

        local combat = foe.combat
        if not combat then
            goto continue
        end

        -- Decrement cooldown each frame (like player_attack.lua does)
        combat.cooldown = math.max((combat.cooldown or 0) - dt, 0)

        -- Skip if already has a queued attack
        if combat.queuedAttack then
            goto continue
        end

        -- Skip if cooldown is not ready
        if combat.cooldown > 0 then
            goto continue
        end

        -- Get player entity
        local player = world:getPlayer()
        if not player or not player.health or player.health.current <= 0 or player.dead then
            goto continue
        end

        -- Calculate distance between foe center and player center
        local foeX, foeY = getEntityCenter(foe)
        local playerX, playerY = getEntityCenter(player)
        if not foeX or not playerX then
            goto continue
        end

        local distance = vector.distance(foeX, foeY, playerX, playerY)
        local attackRange = combat.range or 80

        -- Check if foe is within attack range
        if distance <= attackRange then
            -- Set queued attack
            combat.queuedAttack = {
                targetId = player.id,
                range = attackRange,
            }

            -- Set cooldown: slower than player (default 0.8 attack speed)
            local attackSpeed = combat.attackSpeed or 0.8
            combat.cooldown = 1 / attackSpeed

            -- Set swing timer
            combat.swingTimer = combat.swingDuration or 0.3
        end

        ::continue::
    end
end

return foeAttackSystem
