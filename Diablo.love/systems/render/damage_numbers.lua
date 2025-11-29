local createFloatingDamage = require("components.floating_damage")

local renderDamageNumbersSystem = {}

local function ensureIds(world)
    world._floatingDamageId = (world._floatingDamageId or 0) + 1
    return world._floatingDamageId
end

local function spawnDamageNumber(world, event)
    if not event.position then
        return
    end

    local isCrit = event.crit or false
    local velocityX = (math.random() - 0.5) * (isCrit and 60 or 30)
    local velocityY = (isCrit and -55 or -40) - math.random() * 25
    local lifetime = isCrit and 1.6 or 1.3
    local color = isCrit and { 1, 0.95, 0.2, 1 } or { 1, 1, 1, 1 }
    local shadowColor = isCrit and { 0.5, 0.3, 0, 0.95 } or { 0, 0, 0, 0.85 }

    local spawnYOffset = isCrit and 26 or 18
    local spawnY = event.position.y - spawnYOffset

    local entity = {
        id = string.format("floatingDamage_%d", ensureIds(world)),
        floatingDamage = createFloatingDamage({
            damage = event.amount or 0,
            position = {
                x = event.position.x,
                y = spawnY,
            },
            velocity = {
                x = velocityX,
                y = velocityY,
            },
            timer = lifetime,
            maxTimer = lifetime,
            color = color,
            shadowColor = shadowColor,
            crit = isCrit,
            scaleStart = isCrit and 3.0 or 2.4,
            scaleEnd = isCrit and 1.0 or 0.7,
            wobbleAmplitude = isCrit and 10 or 4,
            wobbleFrequency = isCrit and 16 or 9,
            flashDuration = isCrit and 0.15 or 0.12,
        }),
    }

    world:addEntity(entity)
end

function renderDamageNumbersSystem.draw(world)
    local events = world.pendingCombatEvents or {}
    for _, event in ipairs(events) do
        if event.type == "damage" and not event._spawnedFloatingDamage then
            spawnDamageNumber(world, event)
            event._spawnedFloatingDamage = true
        end
    end

    local dt = world.lastUpdateDt or 0
    if dt <= 0 then
        dt = 1 / 60
    end

    local gravity = 40
    local toRemove = {}

    love.graphics.push("all")
    love.graphics.setFont(world.damageFont or love.graphics.getFont())
    local camera = world.camera or { x = 0, y = 0 }
    love.graphics.translate(-camera.x, -camera.y)

    local entities = world:queryEntities({ "floatingDamage" })

    for _, entity in ipairs(entities) do
        local floating = entity.floatingDamage
        floating.timer = floating.timer - dt
        floating.elapsed = (floating.elapsed or 0) + dt

        floating.position.x = floating.position.x + (floating.velocity.x or 0) * dt
        floating.position.y = floating.position.y + (floating.velocity.y or 0) * dt
        floating.velocity.y = (floating.velocity.y or 0) + gravity * dt

        local alpha = math.max(floating.timer / (floating.maxTimer or 1), 0)
        local progress = 1 - alpha

        local flashDuration = floating.flashDuration or 0.12
        local flashProgress = math.min(1, (flashDuration - floating.elapsed) / flashDuration)
        flashProgress = math.max(0, flashProgress)

        local easedProgress = 1 - (1 - progress) ^ 3
        local scaleStart = floating.scaleStart or 1
        local scaleEnd = floating.scaleEnd or scaleStart
        local scale = scaleStart + (scaleEnd - scaleStart) * easedProgress

        local wobble = 0
        local wobbleAmplitude = floating.wobbleAmplitude or 0
        local wobbleFrequency = floating.wobbleFrequency or 0
        if wobbleAmplitude ~= 0 and wobbleFrequency ~= 0 then
            wobble = math.sin(wobbleFrequency * (floating.elapsed or 0) + (floating.wobbleOffset or 0))
            wobble = wobble * wobbleAmplitude
        end
        local drawX = floating.position.x + wobble
        local drawY = floating.position.y

        love.graphics.push("all")
        local text = string.format("%d", math.floor(floating.damage + 0.5))

        if flashProgress > 0 then
            local flashAlpha = flashProgress * 0.8 * alpha
            love.graphics.setBlendMode("add", "alphamultiply")
            love.graphics.setColor(1, 1, 1, flashAlpha)
            love.graphics.print(
                text,
                drawX,
                drawY,
                0,
                scale * 1.15,
                scale * 1.15
            )
            love.graphics.setBlendMode("alpha")
        end

        local shadow = floating.shadowColor or floating.color
        love.graphics.setColor(
            shadow[1],
            shadow[2],
            shadow[3],
            (shadow[4] or 1) * alpha
        )
        love.graphics.print(
            text,
            drawX + 2 * scale,
            drawY + 2 * scale,
            0,
            scale,
            scale
        )

        love.graphics.setColor(
            floating.color[1],
            floating.color[2],
            floating.color[3],
            (floating.color[4] or 1) * alpha
        )
        love.graphics.print(
            text,
            drawX,
            drawY,
            0,
            scale,
            scale
        )

        if floating.crit then
            love.graphics.setColor(1, 1, 1, 0.5 * alpha)
            love.graphics.print(
                text,
                drawX,
                drawY - 3,
                0,
                scale * 0.9,
                scale * 0.9
            )
        end

        love.graphics.pop()

        if floating.timer <= 0 then
            toRemove[#toRemove + 1] = entity.id
        end
    end

    love.graphics.pop()

    for _, id in ipairs(toRemove) do
        world:removeEntity(id)
    end
end

return renderDamageNumbersSystem
