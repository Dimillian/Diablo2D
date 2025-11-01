local function copyVector(source, defaultX, defaultY)
    if source then
        return {
            x = source.x or defaultX,
            y = source.y or defaultY,
        }
    end

    return {
        x = defaultX,
        y = defaultY,
    }
end

local function createMovementComponent(opts)
    opts = opts or {}

    local heading = copyVector(opts.heading, 0, -1)
    local targetHeading = copyVector(opts.targetHeading or opts.heading, heading.x, heading.y)
    local intentStrafe = copyVector(opts.intentStrafe, 0, 0)

    return {
        speed = opts.speed or 140,
        heading = heading,
        targetHeading = targetHeading,
        intentForward = opts.intentForward or false,
        intentStrafe = intentStrafe,
        headingLerp = opts.headingLerp or 0.2,
        vx = opts.vx or 0,
        vy = opts.vy or 0,
    }
end

return createMovementComponent
