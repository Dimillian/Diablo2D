local vector = require("modules.vector")
local Targeting = require("system_helpers.targeting")

local playerAttackSystem = {}

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

local function computeEffectiveAttackSpeed(entity, combat)
    local base = combat.attackSpeed or 1
    local multiplier = 1

    if entity.stats and entity.stats.total and entity.stats.total.attackSpeed then
        multiplier = multiplier + entity.stats.total.attackSpeed
    end

    if multiplier < 0.1 then
        multiplier = 0.1
    end

    return math.max(base * multiplier, 0.1)
end

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

    combat.cooldown = math.max((combat.cooldown or 0) - dt, 0)

    if combat.swingTimer and combat.swingTimer > 0 then
        combat.swingTimer = math.max(combat.swingTimer - dt, 0)
    end

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
        target = Targeting.resolveMouseTarget(world, { range = combat.range }) or target
    end

    if combat.cooldown > 0 then
        return
    end

    if combat.queuedAttack then
        return
    end

    -- Always trigger swing animation and cooldown for visual feedback
    local effectiveAttackSpeed = computeEffectiveAttackSpeed(player, combat)
    local cooldownReset = 1 / effectiveAttackSpeed

    combat.cooldown = cooldownReset
    combat.swingTimer = combat.swingDuration or 0.35
    combat.lastAttackTime = world.time or 0

    -- Only queue damage if valid target exists and is in range
    if not target then
        return
    end

    local targetHealth = target.health
    if not targetHealth or targetHealth.current <= 0 then
        return
    end

    local playerX, playerY = getEntityCenter(player)
    local targetX, targetY = getEntityCenter(target)
    if not playerX or not targetX then
        return
    end

    local range = combat.range or 120
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
