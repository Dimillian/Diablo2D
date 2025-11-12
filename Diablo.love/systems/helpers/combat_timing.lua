local ComponentDefaults = require("data.component_defaults")

local combatTiming = {}

---Update combat cooldown and swing timer for an entity.
---@param combat table|nil
---@param dt number
---@param opts table|nil
function combatTiming.updateTimers(combat, dt, opts)
    if not combat then
        return
    end

    opts = opts or {}

    combat.cooldown = math.max((combat.cooldown or 0) - dt, 0)

    if combat.swingTimer and combat.swingTimer > 0 then
        combat.swingTimer = math.max(combat.swingTimer - dt, 0)
        if combat.swingTimer <= 0 and opts.clearAttackAnimationTime then
            combat.attackAnimationTime = nil
        end
    end
end

---Compute the effective attack speed for an entity, including stat modifiers.
---@param entity table
---@return number
function combatTiming.computeEffectiveAttackSpeed(entity)
    if not entity or not entity.combat then
        return ComponentDefaults.BASE_ATTACK_SPEED
    end

    local combat = entity.combat
    local baseSpeed = combat.attackSpeed or ComponentDefaults.BASE_ATTACK_SPEED
    local multiplier = 1 + ((entity.stats and entity.stats.total and entity.stats.total.attackSpeed) or 0)
    multiplier = math.max(multiplier, ComponentDefaults.MIN_ATTACK_SPEED_MULTIPLIER)

    local effective = baseSpeed * multiplier
    return math.max(effective, ComponentDefaults.MIN_ATTACK_SPEED)
end

---Start a new swing, applying cooldown and swing timer.
---@param combat table|nil
---@param opts table|nil
function combatTiming.beginSwing(combat, opts)
    if not combat then
        return
    end

    opts = opts or {}

    local attackSpeed = opts.attackSpeed or combat.attackSpeed or ComponentDefaults.BASE_ATTACK_SPEED
    attackSpeed = math.max(attackSpeed, ComponentDefaults.MIN_ATTACK_SPEED)

    combat.cooldown = 1 / attackSpeed
    combat.swingTimer = opts.swingDuration or combat.swingDuration or ComponentDefaults.COMBAT_SWING_DURATION

    if opts.timeStamp then
        combat.lastAttackTime = opts.timeStamp
    end
end

---Get the combat range with a fallback to defaults.
---@param combat table|nil
---@return number
function combatTiming.getRange(combat)
    if not combat then
        return ComponentDefaults.DEFAULT_COMBAT_RANGE
    end

    return combat.range or ComponentDefaults.DEFAULT_COMBAT_RANGE
end

return combatTiming
