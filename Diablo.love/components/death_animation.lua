---Death animation component tracks death animation state and timing
---@param opts table|nil Optional parameters
---@return table Death animation component
local function createDeathAnimation(opts)
    opts = opts or {}
    return {
        timer = opts.timer or 0,
        animationDuration = opts.animationDuration or 0.5, -- Time to play through all frames
        holdDuration = opts.holdDuration or 20.0, -- Time to hold last frame (20 seconds for fun!)
        totalFrames = opts.totalFrames or 8, -- Number of frames in death sprite sheet (8 columns)
        started = opts.started or false,
    }
end

return createDeathAnimation
