local ComponentDefaults = require("data.component_defaults")

local function createInactiveComponent(opts)
    opts = opts or {}

    return {
        isInactive = opts.isInactive or ComponentDefaults.INACTIVE_STATE,
    }
end

return createInactiveComponent
