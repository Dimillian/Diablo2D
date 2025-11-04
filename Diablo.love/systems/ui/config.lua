local UIConfig = {}

-- Shared UI positioning constants
UIConfig.barX = 32 -- Left margin for all bars
UIConfig.barHeight = 20 -- Height of all bars
UIConfig.buttonSize = 48 -- Size of potion/bag buttons
UIConfig.bottomOffset = 44 -- 32 + 12, spacing from bottom for bottom bar elements
UIConfig.buttonSpacing = 8 -- Spacing between buttons
UIConfig.sideMargin = 32 -- Left/right margin for experience bar

---Calculate spacing between health/mana bars
---@return number spacing The spacing between bars
function UIConfig.getBarSpacing()
    return UIConfig.buttonSize - (UIConfig.barHeight * 2)
end

---Get health bar width based on screen width
---@param screenWidth number Screen width
---@return number width The health bar width
function UIConfig.getHealthBarWidth(screenWidth)
    return math.min(screenWidth * 0.3, 240)
end

---Get bottom bar positions (mana bar, health bar, button Y positions)
---@param screenWidth number Screen width
---@param screenHeight number Screen height
---@return table positions Table with manaBarY, healthBarY, buttonY
function UIConfig.getBottomBarPositions(screenWidth, screenHeight)
    local spacing = UIConfig.getBarSpacing()
    local manaBarY = screenHeight - UIConfig.barHeight - UIConfig.bottomOffset
    local healthBarY = manaBarY - UIConfig.barHeight - spacing
    local buttonY = healthBarY

    return {
        manaBarY = manaBarY,
        healthBarY = healthBarY,
        buttonY = buttonY,
    }
end

---Get experience bar position and dimensions
---@param screenWidth number Screen width
---@param screenHeight number Screen height
---@return table position Table with barX, barY, barWidth, barHeight
function UIConfig.getExperienceBarPosition(screenWidth, screenHeight)
    local barX = UIConfig.barX
    local barY = screenHeight - UIConfig.barHeight - 8
    local barWidth = screenWidth - barX - UIConfig.sideMargin

    return {
        barX = barX,
        barY = barY,
        barWidth = barWidth,
        barHeight = UIConfig.barHeight,
    }
end

return UIConfig
