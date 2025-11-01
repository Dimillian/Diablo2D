local function createCombatComponent(opts)
    opts = opts or {}

    return {
        attackSpeed = opts.attackSpeed or 1.0,
        range = opts.range or 120,
        cooldown = opts.cooldown or 0,
        queuedAttack = opts.queuedAttack or nil,
        swingTimer = opts.swingTimer or 0,
        swingDuration = opts.swingDuration or 0.35,
        baseDamageMin = opts.baseDamageMin or 5,
        baseDamageMax = opts.baseDamageMax or 8,
        critChance = opts.critChance or 0,
        lastAttackTime = opts.lastAttackTime,
    }
end

return createCombatComponent
