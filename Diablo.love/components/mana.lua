local ComponentDefaults = require("data.component_defaults")

local function createManaComponent(opts)
    opts = opts or {}

    local max = opts.max or ComponentDefaults.PLAYER_STARTING_MANA

    return {
        current = opts.current or max,
        max = max,
    }
end

return createManaComponent
