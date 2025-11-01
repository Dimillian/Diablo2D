local function createFloatingDamageComponent(opts)
    opts = opts or {}

    return {
        damage = opts.damage or 0,
        velocity = opts.velocity or { x = 0, y = -60 },
        timer = opts.timer or 1.5,
        color = opts.color or { 1, 0, 0, 1 },
        isCritical = opts.isCritical or false,
    }
end

return createFloatingDamageComponent
