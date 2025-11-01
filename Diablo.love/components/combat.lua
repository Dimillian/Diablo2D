local function createCombatComponent(opts)
    opts = opts or {}

    return {
        attackSpeed = opts.attackSpeed or 1.0,
        cooldown = opts.cooldown or 0,
        range = opts.range or 120,
        queuedAttack = opts.queuedAttack or nil,
        swingTimer = opts.swingTimer or 0,
    }
end

return createCombatComponent
