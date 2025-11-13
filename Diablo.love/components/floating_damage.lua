local function createFloatingDamageComponent(opts)
    opts = opts or {}
    local position = opts.position or {}
    local velocity = opts.velocity or {}
    local color = opts.color or {}
    local shadowColor = opts.shadowColor or {}

    return {
        damage = opts.damage or 0,
        position = {
            x = position.x or 0,
            y = position.y or 0,
        },
        velocity = {
            x = velocity.x or 0,
            y = velocity.y or 0,
        },
        timer = opts.timer or 1,
        maxTimer = opts.maxTimer or opts.timer or 1,
        color = {
            color[1] or 1,
            color[2] or 1,
            color[3] or 1,
            color[4] or 1,
        },
        shadowColor = {
            shadowColor[1] or 0,
            shadowColor[2] or 0,
            shadowColor[3] or 0,
            shadowColor[4] or 0.7,
        },
        crit = opts.crit or false,
        scaleStart = opts.scaleStart or 1,
        scaleEnd = opts.scaleEnd or 0.9,
        wobbleAmplitude = opts.wobbleAmplitude or 0,
        wobbleFrequency = opts.wobbleFrequency or 0,
        wobbleOffset = opts.wobbleOffset or math.random() * math.pi * 2,
        elapsed = 0,
    }
end

return createFloatingDamageComponent
