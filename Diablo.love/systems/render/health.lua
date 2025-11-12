local renderHealthSystem = {}

function renderHealthSystem.draw(world)
    local camera = world.camera or { x = 0, y = 0 }

    love.graphics.push("all")
    love.graphics.translate(-camera.x, -camera.y)

    -- Query foes with health (only show health bars for foes, not player)
    local entities = world:queryEntities({ "foe", "health", "position" })

    for _, entity in ipairs(entities) do
        if (entity.inactive and entity.inactive.isInactive) or entity.dead then
            goto continue
        end

        local health = entity.health
        local pos = entity.position
        local size = entity.size or { w = 20, h = 20 }

        local maxHealth = health.max or 1
        local current = math.max(0, math.min(health.current or 0, maxHealth))

        -- Only show health bar if foe has lost health
        if current >= maxHealth then
            goto continue
        end

        local ratio = maxHealth > 0 and (current / maxHealth) or 0

        local barWidth = math.max(size.w, 32)
        local barHeight = 6
        local barX = pos.x + (size.w - barWidth) / 2
        local barY = pos.y - 26

        love.graphics.push("all")

        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", barX - 2, barY - 2, barWidth + 4, barHeight + 4, 3, 3)

        love.graphics.setColor(0.15, 0.15, 0.18, 0.9)
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 3, 3)

        love.graphics.setColor(0.85, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", barX, barY, barWidth * ratio, barHeight, 3, 3)

        love.graphics.setColor(0.9, 0.85, 0.65, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 3, 3)

        love.graphics.pop()

        ::continue::
    end

    love.graphics.pop()
end

return renderHealthSystem
