local function createPotionsComponent()
    return {
        healthPotionCount = 3,
        maxHealthPotionCount = 10,
        manaPotionCount = 2,
        maxManaPotionCount = 10,
        cooldownDuration = 0.5,
        cooldownRemaining = 0,
    }
end

return createPotionsComponent
