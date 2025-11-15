local Spells = require("data.spells")
local coordinates = require("systems.helpers.coordinates")

local renderProjectileSystem = {}

local TWO_PI = math.pi * 2

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function resolveColor(color, fallback)
    local source = color or fallback or { 1, 1, 1, 1 }
    local r = source[1] or 1
    local g = source[2] or 1
    local b = source[3] or 1
    local a = source[4]
    if a == nil then
        a = 1
    end
    return { r, g, b, a }
end

local function normalizeDirection(dx, dy)
    local length = math.sqrt((dx or 0) * (dx or 0) + (dy or 0) * (dy or 0))
    if length == 0 then
        return 1, 0
    end
    return dx / length, dy / length
end

local function drawSimpleImpact(args)
    local baseColor = args.baseColor
    local timer = args.timer or 0
    local duration = args.duration or 0.3
    if duration <= 0 then
        duration = 0.001
    end

    local progress = clamp(1 - (timer / duration), 0, 1)
    local currentRadius = args.radius * (1.2 + progress)
    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], baseColor[4] * (1 - progress))
    love.graphics.circle("fill", args.centerX, args.centerY, currentRadius)
end

local function drawFlyingFireball(args)
    local centerX, centerY = args.centerX, args.centerY
    local radius = args.radius
    local baseColor = args.colors.base
    local secondary = args.colors.secondary
    local core = args.colors.core
    local dirX, dirY = args.dirX, args.dirY
    local time = args.time
    local seed = args.seed
    local lifeRatio = args.lifeRatio
    local progress = args.progress

    local trailLength = radius * (3.0 + progress * 2.0)
    local swirl = radius * 0.35
    local glowPulse = math.sin((time * 8) + seed * 5)

    love.graphics.setBlendMode("add")
    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], 0.35 + 0.25 * (1 - lifeRatio))
    love.graphics.circle("fill", centerX, centerY, radius * (1.8 + 0.1 * glowPulse))
    love.graphics.setBlendMode("alpha")

    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], baseColor[4])
    love.graphics.circle("fill", centerX, centerY, radius)

    love.graphics.setColor(core[1], core[2], core[3], core[4])
    love.graphics.circle("fill", centerX + dirX * radius * 0.2, centerY + dirY * radius * 0.2, radius * 0.65)

    love.graphics.setBlendMode("add")
    love.graphics.setColor(1.0, 0.95, 0.8, 0.65)
    love.graphics.circle("fill", centerX + dirX * radius * 0.45, centerY + dirY * radius * 0.45, radius * 0.45)

    local trailCount = 5
    for i = 1, trailCount do
        local t = i / (trailCount + 1)
        local wave = math.sin((time * (6 + i * 0.5)) + seed * 7 + i)
        local offsetX = -dirX * trailLength * t + (-dirY) * wave * swirl
        local offsetY = -dirY * trailLength * t + dirX * wave * swirl
        local alpha = 0.7 * (1 - t) * (0.8 + 0.2 * (1 - lifeRatio))
        local sparkleRadius = radius * (0.35 - 0.08 * t) * (1 + 0.15 * wave)
        love.graphics.setColor(secondary[1], secondary[2], secondary[3], alpha)
        love.graphics.circle("fill", centerX + offsetX, centerY + offsetY, sparkleRadius)
    end

    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], 0.3)
    love.graphics.circle("fill", centerX - dirX * radius * 0.35, centerY - dirY * radius * 0.35, radius * 0.7)

    love.graphics.setBlendMode("alpha")

    local orbitCount = 6
    for i = 1, orbitCount do
        local angle = (i / orbitCount) * TWO_PI + (time * 5) + seed * 3
        local wobble = 0.2 * math.sin(time * 6 + i)
        local distance = radius * (0.8 + wobble)
        local sparkleSize = radius * (0.25 + 0.05 * math.sin(time * 7 + i * 1.7))
        love.graphics.setColor(core[1], core[2], core[3], 0.55)
        local sparkleX = centerX + math.cos(angle) * distance
        local sparkleY = centerY + math.sin(angle) * distance
        love.graphics.circle("fill", sparkleX, sparkleY, sparkleSize)
    end

    love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.45)
    love.graphics.circle("line", centerX, centerY, radius * (1.05 + 0.05 * glowPulse))
end

local function drawImpactFireball(args)
    local centerX, centerY = args.centerX, args.centerY
    local radius = args.radius
    local baseColor = args.colors.base
    local secondary = args.colors.secondary
    local core = args.colors.core
    local time = args.time
    local timer = args.timer or 0
    local duration = args.duration or 0.3

    if duration <= 0 then
        duration = 0.001
    end

    local progress = clamp(1 - (timer / duration), 0, 1)
    local eased = progress * progress
    local outerRadius = radius * (2.6 + progress * 1.4)
    local shockwaveRadius = outerRadius * (0.75 + 0.15 * math.sin(time * 10))
    local emberCount = 8

    love.graphics.setBlendMode("add")
    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], 0.55 * (1 - progress * 0.6))
    love.graphics.circle("fill", centerX, centerY, outerRadius)

    love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.45 * (1 - progress * 0.4))
    love.graphics.circle("fill", centerX, centerY, outerRadius * 0.7)

    love.graphics.setColor(core[1], core[2], core[3], 0.8 * (1 - progress))
    love.graphics.circle("fill", centerX, centerY, radius * (0.9 - 0.3 * progress))

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 0.85, 0.5, 0.6 * (1 - progress))
    love.graphics.setLineWidth(math.max(1, radius * 0.4))
    love.graphics.circle("line", centerX, centerY, shockwaveRadius)

    love.graphics.setBlendMode("add")
    for i = 1, emberCount do
        local angle = (i / emberCount) * TWO_PI + time * 4
        local emberDistance = outerRadius * (0.4 + eased + 0.1 * math.sin(time * 6 + i))
        local emberSize = radius * (0.3 * (1 - progress) + 0.08)
        love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.8 * (1 - progress))
        local emberX = centerX + math.cos(angle) * emberDistance
        local emberY = centerY + math.sin(angle) * emberDistance
        love.graphics.circle("fill", emberX, emberY, emberSize)
    end

    love.graphics.setBlendMode("alpha")
    love.graphics.setLineWidth(1)
end

local function drawFlyingThunder(args)
    local centerX, centerY = args.centerX, args.centerY
    local radius = args.radius
    local baseColor = args.colors.base
    local secondary = args.colors.secondary
    local core = args.colors.core
    local dirX, dirY = normalizeDirection(args.dirX or 0, args.dirY or 1)
    local time = args.time or 0
    local seed = args.seed or 0
    local lifeRatio = clamp(args.lifeRatio or 0, 0, 1)
    local boltLength = args.boltLength or (radius * 6)
    local progress = clamp(args.progress or 0, 0, 1)

    local startX = centerX - dirX * boltLength
    local startY = centerY - dirY * boltLength
    local endX = centerX
    local endY = centerY
    local perpX = -dirY
    local perpY = dirX

    local jitterAmplitude = radius * (1.4 + 0.8 * (1 - lifeRatio) + 0.3 * progress)
    local lightningPoints = {}
    local segmentCount = 9
    for i = 0, segmentCount do
        local t = i / segmentCount
        local basePointX = startX + dirX * boltLength * t
        local basePointY = startY + dirY * boltLength * t
        local wave = math.sin((time * 24) + seed * 9 + t * 15)
        local flicker = math.sin((time * 32) + seed * 13 + i * 2.4)
        local offset = (wave + flicker) * 0.5 * jitterAmplitude * (0.25 + 0.75 * (1 - lifeRatio))
        local pointX = basePointX + perpX * offset
        local pointY = basePointY + perpY * offset
        lightningPoints[#lightningPoints + 1] = pointX
        lightningPoints[#lightningPoints + 1] = pointY
    end

    if #lightningPoints >= 4 then
        love.graphics.setBlendMode("add")
        love.graphics.setLineJoin("miter")
        love.graphics.setLineWidth(math.max(2, radius * 0.85))
        love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], 0.35)
        love.graphics.line(startX, startY, endX, endY)

        love.graphics.setLineWidth(math.max(2, radius * 0.45))
        love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.8 * (1 - lifeRatio * 0.5))
        love.graphics.line(lightningPoints)

        love.graphics.setLineWidth(math.max(1.5, radius * 0.25))
        love.graphics.setColor(core[1], core[2], core[3], 0.95)
        love.graphics.line(lightningPoints)

        local sparkCount = 5
        for i = 1, sparkCount do
            local t = i / (sparkCount + 1)
            local baseX = startX + dirX * boltLength * t
            local baseY = startY + dirY * boltLength * t
            local sparkJitter = math.sin(time * 40 + seed * (6 + i) + i * 1.7)
            local sparkOffset = sparkJitter * jitterAmplitude * 0.25
            local sparkX = baseX + perpX * sparkOffset
            local sparkY = baseY + perpY * sparkOffset
            local sparkRadius = radius * (0.45 - 0.1 * t) * (1 + 0.2 * math.sin(time * 30 + i))
            love.graphics.setColor(core[1], core[2], core[3], 0.8)
            love.graphics.circle("fill", sparkX, sparkY, sparkRadius)
            love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.5)
            love.graphics.circle("line", sparkX, sparkY, sparkRadius * 1.1)
        end

        love.graphics.setBlendMode("alpha")
    end

    love.graphics.setLineWidth(1)

    local glowRadius = radius * (1.2 + 0.4 * (1 - lifeRatio) + 0.2 * progress)
    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], 0.25)
    love.graphics.circle("fill", centerX, centerY, glowRadius)
    love.graphics.setColor(core[1], core[2], core[3], 0.45)
    love.graphics.circle("fill", centerX, centerY, glowRadius * 0.6)
end

local function drawImpactThunder(args)
    local centerX, centerY = args.centerX, args.centerY
    local radius = args.radius
    local baseColor = args.colors.base
    local secondary = args.colors.secondary
    local core = args.colors.core
    local time = args.time or 0
    local timer = args.timer or 0
    local duration = args.duration or 0.35

    if duration <= 0 then
        duration = 0.001
    end

    local progress = clamp(1 - (timer / duration), 0, 1)
    local eased = progress * (2 - progress)

    love.graphics.setBlendMode("add")
    love.graphics.setColor(core[1], core[2], core[3], 0.9 * (1 - progress * 0.7))
    love.graphics.circle("fill", centerX, centerY, radius * (0.95 + 0.2 * eased))

    love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.75 * (1 - progress * 0.5))
    love.graphics.circle("fill", centerX, centerY, radius * (1.6 + 0.8 * eased))

    local shockwaveRadius = radius * (2.4 + 1.2 * eased)
    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], 0.6 * (1 - progress))
    love.graphics.setLineWidth(math.max(2, radius * 0.6))
    love.graphics.circle("line", centerX, centerY, shockwaveRadius)

    local arcCount = 7
    for i = 1, arcCount do
        local angle = (i / arcCount) * TWO_PI + time * 5
        local length = radius * (2.2 + eased * 1.4 + 0.2 * math.sin(time * 12 + i))
        local endX = centerX + math.cos(angle) * length
        local endY = centerY + math.sin(angle) * length
        love.graphics.setColor(secondary[1], secondary[2], secondary[3], 0.55 * (1 - progress))
        love.graphics.setLineWidth(math.max(1.5, radius * 0.35 * (1 - progress * 0.6)))
        love.graphics.line(centerX, centerY, endX, endY)
    end

    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], 0.35 * (1 - progress))
    love.graphics.circle("fill", centerX, centerY, radius * (1.3 + 0.4 * (1 - progress)))
    love.graphics.setLineWidth(1)
end

function renderProjectileSystem.draw(world)
    local projectiles = world:queryEntities({ "projectile", "position", "size", "renderable" })
    if #projectiles == 0 then
        return
    end

    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    local time = world.time or 0

    for _, projectile in ipairs(projectiles) do
        local projectileComponent = projectile.projectile
        if not projectileComponent then
            goto continue
        end

        local renderable = projectile.renderable or {}
        local spell = projectileComponent.spellId and Spells.types[projectileComponent.spellId]

        local baseColor = resolveColor(renderable.color, spell and spell.projectileColor)
        local secondaryDefault = { baseColor[1], baseColor[2], baseColor[3], 0.9 }
        local secondaryColor = resolveColor(renderable.secondaryColor, secondaryDefault)
        local coreColor = resolveColor(renderable.coreColor, { 1, 0.9, 0.7, 1 })

        local radius = (projectile.size.w or projectile.size.h or 0) / 2
        local centerX, centerY = coordinates.getEntityCenter(projectile)
        if not centerX or not centerY then
            goto continue
        end

        local state = projectileComponent.state or "flying"
        if projectile.inactive and projectile.inactive.isInactive and state ~= "impact" then
            goto continue
        end
        local seed = renderable.sparkleSeed or 0
        local maxLifetime = projectileComponent.maxLifetime or 1
        if maxLifetime <= 0 then
            maxLifetime = 1
        end
        local remainingLifetime = clamp(projectileComponent.lifetime or 0, 0, maxLifetime)
        local lifeRatio = clamp(remainingLifetime / maxLifetime, 0, 1)
        local progress = 1 - lifeRatio

        if renderable.kind == "image" and renderable.sprite then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(renderable.sprite, projectile.position.x, projectile.position.y)
            goto continue
        end

        if state == "impact" then
            local impactPosition = projectileComponent.impactPosition
            if impactPosition and impactPosition.x and impactPosition.y then
                centerX = impactPosition.x
                centerY = impactPosition.y
            end

            if renderable.kind == "fireball" then
                drawImpactFireball({
                    centerX = centerX,
                    centerY = centerY,
                    radius = radius,
                    colors = {
                        base = baseColor,
                        secondary = secondaryColor,
                        core = coreColor,
                    },
                    time = time,
                    timer = projectileComponent.impactTimer,
                    duration = projectileComponent.impactDuration,
                })
            elseif renderable.kind == "thunder" then
                drawImpactThunder({
                    centerX = centerX,
                    centerY = centerY,
                    radius = radius,
                    colors = {
                        base = baseColor,
                        secondary = secondaryColor,
                        core = coreColor,
                    },
                    time = time,
                    timer = projectileComponent.impactTimer,
                    duration = projectileComponent.impactDuration,
                })
            else
                drawSimpleImpact({
                    centerX = centerX,
                    centerY = centerY,
                    radius = radius,
                    baseColor = baseColor,
                    timer = projectileComponent.impactTimer,
                    duration = projectileComponent.impactDuration,
                })
            end

            goto continue
        end

        if renderable.kind == "fireball" then
            local lastDirX = projectileComponent.lastDirectionX
            local lastDirY = projectileComponent.lastDirectionY
            local dirX, dirY = normalizeDirection(lastDirX, lastDirY)
            drawFlyingFireball({
                centerX = centerX,
                centerY = centerY,
                radius = radius,
                colors = {
                    base = baseColor,
                    secondary = secondaryColor,
                    core = coreColor,
                },
                dirX = dirX,
                dirY = dirY,
                time = time,
                seed = seed,
                lifeRatio = lifeRatio,
                progress = progress,
            })
        elseif renderable.kind == "thunder" then
            local lastDirX = projectileComponent.lastDirectionX
            local lastDirY = projectileComponent.lastDirectionY
            local dirX, dirY = normalizeDirection(lastDirX, lastDirY)
            local boltLength = radius * 6
            if spell and spell.projectileBoltLength then
                boltLength = spell.projectileBoltLength
            end

            drawFlyingThunder({
                centerX = centerX,
                centerY = centerY,
                radius = radius,
                colors = {
                    base = baseColor,
                    secondary = secondaryColor,
                    core = coreColor,
                },
                dirX = dirX,
                dirY = dirY,
                time = time,
                seed = seed,
                lifeRatio = lifeRatio,
                progress = progress,
                boltLength = boltLength,
            })
        else
            love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], baseColor[4])
            love.graphics.circle("fill", centerX, centerY, radius)
        end

        ::continue::
    end

    love.graphics.pop()
end

return renderProjectileSystem
