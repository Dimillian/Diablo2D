local ComponentDefaults = require("data.component_defaults")

local function createHealthComponent(opts)
    opts = opts or {}

    local max = opts.max or ComponentDefaults.PLAYER_STARTING_HEALTH

    return {
        current = opts.current or max,
        max = max,
    }
end

return createHealthComponent
