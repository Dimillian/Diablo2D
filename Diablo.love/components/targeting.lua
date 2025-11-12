local ComponentDefaults = require("data.component_defaults")

local function createTargetingComponent(opts)
    opts = opts or {}

    return {
        currentTargetId = opts.currentTargetId,
        displayTimer = opts.displayTimer or 0,
        keepAlive = opts.keepAlive or ComponentDefaults.TARGET_KEEP_ALIVE,
    }
end

return createTargetingComponent
