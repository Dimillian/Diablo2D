local function createDetectionComponent(opts)
    opts = opts or {}

    return {
        range = opts.range or 150, -- Detection radius in pixels
        detectedTargetId = nil, -- ID of the target being tracked
        removeOnDeath = true,
    }
end

return createDetectionComponent
