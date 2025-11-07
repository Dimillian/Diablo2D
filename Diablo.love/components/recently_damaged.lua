local ComponentDefaults = require("data.component_defaults")

local function createRecentlyDamagedComponent()
    return {
        timer = ComponentDefaults.DAMAGE_FLASH_DURATION,
        maxTimer = ComponentDefaults.DAMAGE_FLASH_DURATION,
    }
end

return createRecentlyDamagedComponent
