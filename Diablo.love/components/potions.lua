local function createPotionsComponent(opts)
    opts = opts or {}

    return {
        healthPotionCount = opts.healthPotionCount or 3,
        maxHealthPotionCount = opts.maxHealthPotionCount or 10,
        manaPotionCount = opts.manaPotionCount or 2,
        maxManaPotionCount = opts.maxManaPotionCount or 10,
        cooldownDuration = opts.cooldownDuration or 0.5,
        cooldownRemaining = opts.cooldownRemaining or 0,
    }
end

return createPotionsComponent
