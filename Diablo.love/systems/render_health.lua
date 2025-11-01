local renderHealthSystem = {}

function renderHealthSystem.draw(world, dt)
    dt = dt or 0

    local entities = world:queryEntities({ "health", "position", "recentlyDamaged" })

    if #entities == 0 then
        return
    end

    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)

    for _, entity in ipairs(entities) do
        -- Skip inactive or dead entities
        if entity.inactive or entity.dead then
            goto continue
        end

        local health = entity.health
        local pos = entity.position
        local size = entity.size or { w = 20, h = 20 }

        -- Compute health ratio
        local ratio = health.max > 0 and (health.current / health.max) or 0

        -- Bar dimensions
        local barWidth = size.w * 1.2
        local barHeight = 4
        local barX = pos.x + (size.w / 2) - (barWidth / 2)
        local barY = pos.y - size.h - 8

        -- Draw background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

        -- Draw fill
        love.graphics.setColor(0.8, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", barX, barY, barWidth * ratio, barHeight)

        -- Draw outline
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", barX, barY, barWidth, barHeight)

        -- Decrement timer
        if entity.recentlyDamaged then
            entity.recentlyDamaged.timer = entity.recentlyDamaged.timer - dt
            if entity.recentlyDamaged.timer <= 0 then
                world:removeComponent(entity.id, "recentlyDamaged")
            end
        end

        ::continue::
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return renderHealthSystem
