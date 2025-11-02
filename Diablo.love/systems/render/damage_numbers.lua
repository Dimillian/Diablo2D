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

    local velocityX = (math.random() - 0.5) * 30
    local velocityY = -40 - math.random() * 20
    local lifetime = 0.9

    local entity = {
        id = string.format("floatingDamage_%d", ensureIds(world)),
        floatingDamage = createFloatingDamage({
            damage = event.amount or 0,
            position = {
                x = event.position.x,
                y = event.position.y,
            },
            velocity = {
                x = velocityX,
                y = velocityY,
            },
            timer = lifetime,
            maxTimer = lifetime,
            color = event.crit and { 1, 0.95, 0.35, 1 } or { 1, 0.3, 0.3, 1 },
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

        floating.position.x = floating.position.x + (floating.velocity.x or 0) * dt
        floating.position.y = floating.position.y + (floating.velocity.y or 0) * dt
        floating.velocity.y = (floating.velocity.y or 0) + gravity * dt

        local alpha = math.max(floating.timer / (floating.maxTimer or 1), 0)

        love.graphics.push("all")
        love.graphics.setColor(
            floating.color[1],
            floating.color[2],
            floating.color[3],
            (floating.color[4] or 1) * alpha
        )

        local text = string.format("%d", math.floor(floating.damage + 0.5))
        love.graphics.print(
            text,
            floating.position.x,
            floating.position.y
        )

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
