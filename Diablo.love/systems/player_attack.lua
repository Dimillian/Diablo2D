local EquipmentHelper = require("system_helpers.equipment")
local targeting = require("system_helpers.targeting")

local playerAttackSystem = {}

function playerAttackSystem.update(scene, dt)
    local entities = scene:queryEntities({ "combat", "playerControlled" })

    for _, entity in ipairs(entities) do
        local combat = entity.combat

        -- Decrement cooldown
        if combat.cooldown > 0 then
            combat.cooldown = math.max(0, combat.cooldown - dt)
        end

        -- Decrement swing timer
        if combat.swingTimer > 0 then
            combat.swingTimer = math.max(0, combat.swingTimer - dt)
        end

        -- Check for attack input
        if love.mouse.isDown(1) and combat.cooldown <= 0 then
            -- Acquire target
            local target = targeting.acquireTarget(scene, entity, combat.range)

            if target and target.health and target.health.current > 0 then
                -- Compute effective attack speed from stats
                local totalStats = EquipmentHelper.computeTotalStats(entity)
                local baseAttackSpeed = 1.0
                local effectiveAttackSpeed = baseAttackSpeed * (1 + (totalStats.attackSpeed or 0))

                -- Queue attack
                combat.queuedAttack = {
                    targetId = target.id,
                    time = scene.time or 0,
                }

                -- Update combat stats
                combat.attackSpeed = effectiveAttackSpeed
                combat.cooldown = 1.0 / effectiveAttackSpeed
                combat.swingTimer = 0.3
            end
        end
    end
end

return playerAttackSystem
