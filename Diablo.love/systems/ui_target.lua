local uiTargetSystem = {}

function uiTargetSystem.draw(world)
    if not world.currentTargetId then
        return
    end

    local target = world:getEntity(world.currentTargetId)

    -- Clear target if it doesn't exist or is dead
    if not target or target.dead or not target.health then
        world.currentTargetId = nil
        return
    end

    local health = target.health
    local maxHealth = health.max
    local currentHealth = math.max(0, math.min(health.current, maxHealth))
    local ratio = maxHealth > 0 and (currentHealth / maxHealth) or 0

    local screenWidth = love.graphics.getWidth()
    local barWidth = 200
    local barHeight = 20
    local barX = (screenWidth / 2) - (barWidth / 2)
    local barY = 32

    love.graphics.push("all")

    -- Background shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", barX - 4, barY - 4, barWidth + 8, barHeight + 8, 6, 6)

    -- Bar background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 4, 4)

    -- Health fill
    love.graphics.setColor(0.8, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", barX, barY, barWidth * ratio, barHeight, 4, 4)

    -- Outline
    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 4, 4)

    -- Text
    love.graphics.setColor(1, 1, 1, 1)
    local text = string.format("%d / %d", math.floor(currentHealth), math.floor(maxHealth))
    local textY = math.floor(barY + (barHeight / 2) - 6 + 0.5)
    love.graphics.printf(text, barX, textY, barWidth, "center")

    love.graphics.pop()
end

return uiTargetSystem
