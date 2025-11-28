local EmberEffect = require("effects.ember")

local function createBloodBurst(opts)
    opts = opts or {}
    local position = opts.position or { x = 0, y = 0 }

    local emitter = EmberEffect.createRadialEmitter({
        radius = 18,
        rate = 280,
        sizeMin = 2,
        sizeMax = 4,
        lifeBase = 0.32,
        speedMin = 140,
        speedMax = 260,
        driftMin = -70,
        driftMax = 70,
        pixelScale = 1.0,
        startColor = { 0.9, 0.12, 0.08, 0.9 },
        endColor = { 0.5, 0.04, 0.02, 0.0 },
    })
    EmberEffect.setAnchor(emitter, position.x, position.y)
    EmberEffect.update(emitter, 0.04)
    emitter.rate = 0

    return {
        emitter = emitter,
        timeToLive = opts.timeToLive or 0.5,
    }
end

return createBloodBurst
