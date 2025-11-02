local Targeting = require("systems.helpers.targeting")

local uiTargetSystem = {}

function uiTargetSystem.draw(world)
    local target = Targeting.getCurrentTarget(world)
    if not target then
        return
    end

    local health = target.health
    if not health then
        return
    end

    local maxHealth = health.max or 1
    local current = math.max(0, math.min(health.current or 0, maxHealth))
    local ratio = maxHealth > 0 and (current / maxHealth) or 0

    local screenWidth = love.graphics.getWidth()

    local frameWidth = math.min(screenWidth * 0.5, 320)
    local frameHeight = 72
    local frameX = (screenWidth - frameWidth) / 2
    local frameY = 20

    love.graphics.push("all")

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", frameX - 6, frameY - 6, frameWidth + 12, frameHeight + 12, 10, 10)

    love.graphics.setColor(0.12, 0.12, 0.16, 0.95)
    love.graphics.rectangle("fill", frameX, frameY, frameWidth, frameHeight, 8, 8)

    love.graphics.setColor(0.75, 0.7, 0.5, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", frameX, frameY, frameWidth, frameHeight, 8, 8)

    local padding = 16
    local nameY = frameY + padding
    local barHeight = 18
    local barSpacing = 12
    local barY = frameY + padding + barSpacing + love.graphics.getFont():getHeight()
    local name = target.name or "Unknown"

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print(name, frameX + padding, nameY)

    love.graphics.setColor(0.2, 0.2, 0.25, 1)
    love.graphics.rectangle("fill", frameX + padding, barY, frameWidth - padding * 2, barHeight, 6, 6)

    love.graphics.setColor(0.85, 0.25, 0.25, 1)
    love.graphics.rectangle(
        "fill",
        frameX + padding,
        barY,
        (frameWidth - padding * 2) * ratio,
        barHeight,
        6,
        6
    )

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.setLineWidth(1.5)
    love.graphics.rectangle("line", frameX + padding, barY, frameWidth - padding * 2, barHeight, 6, 6)

    local text = string.format("%d / %d", math.floor(current + 0.5), math.floor(maxHealth + 0.5))
    love.graphics.printf(text, frameX + padding, barY + 2, frameWidth - padding * 2, "center")

    love.graphics.pop()
end

return uiTargetSystem
