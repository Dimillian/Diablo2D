local Leveling = require("modules.leveling")

local function createExperienceComponent(opts)
    opts = opts or {}

    local level = opts.level or 1
    local currentXP = opts.currentXP or 0
    local xpForNextLevel = Leveling.getXPRequiredForNextLevel(level)

    return {
        level = level,
        currentXP = currentXP,
        xpForNextLevel = xpForNextLevel,
    }
end

return createExperienceComponent
