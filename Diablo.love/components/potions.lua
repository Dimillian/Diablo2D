local ComponentDefaults = require("data.component_defaults")

local function createPotionsComponent()
    return {
        healthPotionCount = ComponentDefaults.HEALTH_POTION_STARTING_COUNT,
        maxHealthPotionCount = ComponentDefaults.MAX_HEALTH_POTION_COUNT,
        manaPotionCount = ComponentDefaults.MANA_POTION_STARTING_COUNT,
        maxManaPotionCount = ComponentDefaults.MAX_MANA_POTION_COUNT,
        cooldownDuration = ComponentDefaults.POTION_COOLDOWN_DURATION,
        cooldownRemaining = 0,
    }
end

return createPotionsComponent
