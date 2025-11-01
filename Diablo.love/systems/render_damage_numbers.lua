local renderDamageNumbersSystem = {}

-- Cache font to avoid recreating it every frame
local cachedFont = nil

function renderDamageNumbersSystem.draw(world, dt)
    dt = dt or 0

    local entities = world:queryEntities({ "floatingDamage", "position" })

    if #entities == 0 then
        return
    end

    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    -- Use cached font or create once
    if not cachedFont then
        cachedFont = love.graphics.newFont(16)
    end
    love.graphics.setFont(cachedFont)

    for _, entity in ipairs(entities) do
        local floatingDamage = entity.floatingDamage
        local pos = entity.position

        -- Decrement timer
        floatingDamage.timer = floatingDamage.timer - dt

        if floatingDamage.timer > 0 then
            -- Update position (gravity effect)
            pos.y = pos.y + floatingDamage.velocity.y * dt
            floatingDamage.velocity.y = floatingDamage.velocity.y - 200 * dt

            -- Compute opacity
            local opacity = math.max(0, floatingDamage.timer / 1.5)

            -- Draw damage number
            local text = string.format("%d", floatingDamage.damage)
            if floatingDamage.isCritical then
                text = text .. "!"
            end

            love.graphics.setColor(floatingDamage.color[1], floatingDamage.color[2], floatingDamage.color[3], opacity)
            love.graphics.print(text, pos.x, pos.y)
        else
            -- Remove entity when timer expires
            world:removeEntity(entity.id)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderDamageNumbersSystem
