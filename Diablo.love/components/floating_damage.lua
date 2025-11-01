local function createFloatingDamageComponent(opts)
    opts = opts or {}

    return {
        damage = opts.damage or 0,
        position = {
            x = (opts.position and opts.position.x) or 0,
            y = (opts.position and opts.position.y) or 0,
        },
        velocity = {
            x = (opts.velocity and opts.velocity.x) or 0,
            y = (opts.velocity and opts.velocity.y) or 0,
        },
        timer = opts.timer or 1,
        maxTimer = opts.maxTimer or opts.timer or 1,
        color = {
            (opts.color and opts.color[1]) or 1,
            (opts.color and opts.color[2]) or 1,
            (opts.color and opts.color[3]) or 1,
            (opts.color and opts.color[4]) or 1,
        },
    }
end

return createFloatingDamageComponent
