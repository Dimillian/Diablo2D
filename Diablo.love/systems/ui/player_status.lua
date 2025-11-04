local UIConfig = require("systems.ui.config")

local uiPlayerStatus = {}

function uiPlayerStatus.draw(world)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Draw debug info in top right corner
    love.graphics.push("all")
    love.graphics.setColor(1, 1, 1, 1)
    local debugText = world.debugMode and "Debug: ON" or "Debug: OFF"
    love.graphics.print(debugText, screenWidth - 120, 16)
    love.graphics.pop()

    -- Draw health bar in bottom left corner
    local player = world:getPlayer()
    if not player then
        return
    end

    local health = player.health
    if not health then
        return
    end

    local maxHealth = health.max
    local currentHealth = math.max(0, math.min(health.current, maxHealth))
    local healthRatio = maxHealth > 0 and (currentHealth / maxHealth) or 0

    local barWidth = math.floor(UIConfig.getHealthBarWidth(screenWidth) + 0.5)
    local barHeight = UIConfig.barHeight
    local barX = UIConfig.barX
    local positions = UIConfig.getBottomBarPositions(screenWidth, screenHeight)
    local manaBarY = positions.manaBarY
    local healthBarY = positions.healthBarY

    love.graphics.push("all")

    -- Draw health bar
    -- Background shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", barX - 4, healthBarY - 4, barWidth + 8, barHeight + 8, 6, 6)

    -- Bar background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", barX, healthBarY, barWidth, barHeight, 4, 4)

    -- Health fill
    love.graphics.setColor(0.8, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", barX, healthBarY, barWidth * healthRatio, barHeight, 4, 4)

    -- Outline
    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", barX, healthBarY, barWidth, barHeight, 4, 4)

    -- Health text
    love.graphics.setColor(1, 1, 1, 1)
    local healthText = string.format("%d / %d", math.floor(currentHealth), math.floor(maxHealth))
    local healthTextY = math.floor(healthBarY + (barHeight / 2) - 6 + 0.5)
    love.graphics.printf(healthText, barX, healthTextY, barWidth, "center")

    -- Draw mana bar
    local mana = player.mana
    if mana then
        local maxMana = mana.max
        local currentMana = math.max(0, math.min(mana.current, maxMana))
        local manaRatio = maxMana > 0 and (currentMana / maxMana) or 0

        -- Background shadow
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", barX - 4, manaBarY - 4, barWidth + 8, barHeight + 8, 6, 6)

        -- Bar background
        love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
        love.graphics.rectangle("fill", barX, manaBarY, barWidth, barHeight, 4, 4)

        -- Mana fill (blue color)
        love.graphics.setColor(0.2, 0.4, 0.9, 1)
        love.graphics.rectangle("fill", barX, manaBarY, barWidth * manaRatio, barHeight, 4, 4)

        -- Outline
        love.graphics.setColor(0.9, 0.85, 0.65, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", barX, manaBarY, barWidth, barHeight, 4, 4)

        -- Mana text
        love.graphics.setColor(1, 1, 1, 1)
        local manaText = string.format("%d / %d", math.floor(currentMana), math.floor(maxMana))
        local manaTextY = math.floor(manaBarY + (barHeight / 2) - 6 + 0.5)
        love.graphics.printf(manaText, barX, manaTextY, barWidth, "center")
    end

    love.graphics.pop()
end

return uiPlayerStatus
