local vector = require("modules.vector")
local coordinates = require("systems.helpers.coordinates")
local combatTiming = require("systems.helpers.combat_timing")

local foeAttackSystem = {}

function foeAttackSystem.update(world, dt)
    -- Query entities with foe, chase, combat, position, and health components
    local entities = world:queryEntities({ "foe", "chase", "combat", "position" })

    for _, foe in ipairs(entities) do
        -- Skip inactive entities
        if foe.inactive and foe.inactive.isInactive then
            goto continue
        end

        local combat = foe.combat
        if not combat then
            goto continue
        end

        -- Decrement cooldown and swing timer each frame
        combatTiming.updateTimers(combat, dt, { clearAttackAnimationTime = true })

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
        local foeX, foeY = coordinates.getEntityCenter(foe)
        local playerX, playerY = coordinates.getEntityCenter(player)
        if not foeX or not playerX then
            goto continue
        end

        local distance = vector.distance(foeX, foeY, playerX, playerY)
        local attackRange = combatTiming.getRange(combat)

        -- Check if foe is within attack range
        if distance <= attackRange then
            -- Set queued attack
            combat.queuedAttack = {
                targetId = player.id,
                range = attackRange,
                time = world.time or 0,
            }

            combatTiming.beginSwing(combat, { timeStamp = world.time or 0 })
        end

        ::continue::
    end
end

return foeAttackSystem
