local function createPotionsComponent(opts)
    opts = opts or {}
    return {
        healthPotionCount = opts.healthPotionCount or 3,
        maxHealthPotionCount = opts.maxHealthPotionCount or 10, -- max carry limit
        manaPotionCount = opts.manaPotionCount or 2,
        maxManaPotionCount = opts.maxManaPotionCount or 10, -- max carry limit
        lastUseTime = opts.lastUseTime or nil,  -- Track last use time for cooldown
        cooldownRemaining = opts.cooldownRemaining or 0,  -- Current cooldown timer (shared for both potion types)
    }
end

return createPotionsComponent
