local vector = require("modules.vector")
local Targeting = require("systems.helpers.targeting")
local coordinates = require("systems.helpers.coordinates")
local combatTiming = require("systems.helpers.combat_timing")

local playerAttackSystem = {}

function playerAttackSystem.update(world, dt)
    Targeting.tick(world, dt)

    local player = world:getPlayer()
    if not player then
        return
    end

    local combat = player.combat
    if not combat then
        return
    end

    combatTiming.updateTimers(combat, dt)

    local input =
        world.input and world.input.mouse and world.input.mouse.primary
    if not input then
        return
    end

    local wantsAttack = input.held or input.pressed
    if not wantsAttack then
        return
    end

    if input.consumedClickId == input.clickId then
        return
    end

    local target = Targeting.getCurrentTarget(world)
    if wantsAttack then
        local desiredRange = combatTiming.getRange(combat)
        target = Targeting.resolveMouseTarget(world, { range = desiredRange }) or target
    end

    if combat.cooldown > 0 then
        return
    end

    if combat.queuedAttack then
        return
    end

    -- Always trigger swing animation and cooldown for visual feedback
    local effectiveAttackSpeed = combatTiming.computeEffectiveAttackSpeed(player)
    combatTiming.beginSwing(combat, {
        attackSpeed = effectiveAttackSpeed,
        timeStamp = world.time or 0,
    })

    -- Only queue damage if valid target exists and is in range
    if not target then
        return
    end

    local targetHealth = target.health
    if not targetHealth or targetHealth.current <= 0 then
        return
    end

    local playerX, playerY = coordinates.getEntityCenter(player)
    local targetX, targetY = coordinates.getEntityCenter(target)
    if not playerX or not targetX then
        return
    end

    local range = combatTiming.getRange(combat)
    local distance = vector.distance(playerX, playerY, targetX, targetY)
    if distance > range then
        return
    end

    -- Queue the attack for damage computation
    combat.queuedAttack = {
        targetId = target.id,
        time = world.time or 0,
        range = range,
    }
end

return playerAttackSystem
