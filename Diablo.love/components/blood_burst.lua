local EmberEffect = require("effects.ember")

local function createBloodBurst(opts)
    opts = opts or {}
    local position = opts.position or { x = 0, y = 0 }

    local emitter = EmberEffect.createRadialEmitter({
        radius = 22,
        rate = 380,
        sizeMin = 2,
        sizeMax = 5,
        lifeBase = 0.4,
        speedMin = 160,
        speedMax = 300,
        driftMin = -80,
        driftMax = 80,
        pixelScale = 1.0,
        startColor = { 1.0, 0.15, 0.1, 1.0 },
        endColor = { 0.6, 0.05, 0.03, 0.0 },
    })
    EmberEffect.setAnchor(emitter, position.x, position.y)
    EmberEffect.update(emitter, 0.04)
    emitter.rate = 0

    return {
        emitter = emitter,
        timeToLive = opts.timeToLive or 0.65,
    }
end

return createBloodBurst
