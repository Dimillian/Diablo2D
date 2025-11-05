local function createDetectionComponent(opts)
    opts = opts or {}

    return {
        range = opts.range, -- Detection radius in pixels
        detectedTargetId = nil, -- ID of the target being tracked
        leashExtension = opts.leashExtension, -- Additional distance foes will chase before disengaging
        leashRange = nil, -- Dynamic leash range when aggro is forced
        forceAggro = false, -- Whether the foe is currently forced to stay aggroed
        removeOnDeath = true,
    }
end

return createDetectionComponent
