local UIConfig = {}

-- Shared UI positioning constants
UIConfig.barX = 32 -- Left margin for all bars
UIConfig.barHeight = 20 -- Height of all bars
UIConfig.buttonSize = 48 -- Size of potion/bag buttons
UIConfig.bottomOffset = 44 -- 32 + 12, spacing from bottom for bottom bar elements
UIConfig.buttonSpacing = 8 -- Spacing between buttons
UIConfig.sideMargin = 32 -- Left/right margin for experience bar
UIConfig.iconPadding = {
    small = 3,
    large = 8,
}
UIConfig.defaultBadgeSize = 14
UIConfig.potionBadgeSize = 16

UIConfig.iconBox = {
    shadowColor = { 0, 0, 0, 0.5 },
    shadowOffset = 2,
    backgroundColor = { 0.1, 0.1, 0.1, 0.9 },
    borderColor = { 0.9, 0.85, 0.65, 1 },
    badgeBackgroundColor = { 0.1, 0.1, 0.1, 0.9 },
    badgeTextColor = { 0.95, 0.9, 0.7, 1 },
    disabledOverlayColor = { 0, 0, 0, 0.55 },
    cooldownOverlayColor = { 0, 0, 0, 0.45 },
    highlightLineWidth = 2,
    borderLineWidth = 2,
    smallCornerRadius = 3,
    largeCornerRadius = 4,
}

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
---@param screenHeight number Screen height
---@return table positions Table with manaBarY, healthBarY, buttonY
function UIConfig.getBottomBarPositions(screenHeight)
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
