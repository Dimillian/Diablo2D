local Resources = require("modules.resources")

local uiBottomBar = {}

---Draw a UI icon box (reusable component)
---@param x number X position
---@param y number Y position
---@param size number Box size (square)
---@param iconName string Icon name to load (e.g., "bag", "health_potion")
---@param opts table|nil Optional parameters
---@param opts.shadow boolean Whether to draw shadow (default: false)
---@param opts.badgeText string|nil Badge text to draw in top right corner (default: nil)
---@param opts.badgeSize number Badge size (default: 14)
---@param opts.iconPadding number Padding around icon (default: 3 for small boxes, 8 for large)
---@param opts.cornerSize number Size of the bottom-left corner box (default: 16)
local function drawIconBox(x, y, size, iconName, opts)
    opts = opts or {}
    local shadow = opts.shadow or false
    local badgeText = opts.badgeText
    local badgeSize = opts.badgeSize or 14
    local iconPadding = opts.iconPadding or (size >= 40 and 8 or 3)
    local disabled = opts.disabled
    local cooldownRatio = opts.cooldownRatio or 0
    local cornerSize = opts.cornerSize or 16
    local highlightColor = opts.highlightColor

    -- Draw shadow if requested
    if shadow then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 6, 6)
    end

    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    local cornerRadius = size >= 40 and 4 or 3
    love.graphics.rectangle("fill", x, y, size, size, cornerRadius, cornerRadius)

    -- Draw badge background if needed (before border)
    if badgeText then
        local letterBoxX = x + size - badgeSize
        local letterBoxY = y
        love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
        love.graphics.rectangle("fill", letterBoxX, letterBoxY, badgeSize, badgeSize, 0, 0)
    end

    -- Draw border
    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, size, size, cornerRadius, cornerRadius)

    -- Draw icon inside
    local iconImage = Resources.loadUIIcon(iconName)
    if iconImage then
        local iconInnerSize = size - (iconPadding * 2)
        local iconX = x + iconPadding
        local iconY = y + iconPadding

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(iconImage, iconX, iconY, 0,
            iconInnerSize / iconImage:getWidth(),
            iconInnerSize / iconImage:getHeight())
    end

    -- Draw badge if needed
    if badgeText then
        local letterBoxX = x + size - badgeSize
        local letterBoxY = y

        -- Draw badge borders (left and bottom only, merge with main border)
        love.graphics.setColor(0.9, 0.85, 0.65, 1)
        love.graphics.setLineWidth(2)
        love.graphics.line(letterBoxX, letterBoxY, letterBoxX, letterBoxY + badgeSize)
        love.graphics.line(letterBoxX, letterBoxY + badgeSize, letterBoxX + badgeSize, letterBoxY + badgeSize)

        -- Draw badge text
        love.graphics.setColor(0.95, 0.9, 0.7, 1)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(badgeText)
        local textHeight = font:getHeight()
        local textX = letterBoxX + (badgeSize - textWidth) / 2
        local textY = letterBoxY + (badgeSize - textHeight) / 2
        love.graphics.print(badgeText, textX, textY)
    end

    if disabled then
        love.graphics.setColor(0, 0, 0, 0.55)
        love.graphics.rectangle("fill", x, y, size, size, cornerRadius, cornerRadius)
    end

    if cooldownRatio > 0 then
        cooldownRatio = math.min(1, math.max(0, cooldownRatio))
        local overlayHeight = size * cooldownRatio
        love.graphics.setColor(0, 0, 0, 0.45)
        love.graphics.rectangle("fill", x, y, size, overlayHeight, cornerRadius, cornerRadius)
    end

    if highlightColor then
        love.graphics.setColor(highlightColor)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x - 2, y - 2, size + 4, size + 4, cornerRadius + 1, cornerRadius + 1)
    end
end

function uiBottomBar.draw(world)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    world.bottomBarHealthPotionRect = nil
    world.bottomBarManaPotionRect = nil
    world.bottomBarBagRect = nil

    -- Bottom bar positioning - next to health and mana bars
    -- Use the same bar height as player_status.lua (20px, not 24px)
    local healthBarWidth = math.min(screenWidth * 0.3, 240)
    local healthBarX = 32
    local healthBarHeight = 20 -- Match player_status.lua barHeight
    local buttonSize = 48 -- Bag icon height - total height should match this
    local spacing = buttonSize - (healthBarHeight * 2) -- Calculate spacing so both bars + gap = buttonSize
    local manaBarY = screenHeight - healthBarHeight - 32
    local healthBarY = manaBarY - healthBarHeight - spacing

    -- Layout icons horizontally: health/mana bars | health potion | mana potion | bag
    local buttonSpacing = 8
    local healthPotionX = healthBarX + healthBarWidth + buttonSpacing
    local buttonY = healthBarY
    local manaPotionX = healthPotionX + buttonSize + buttonSpacing
    local bagX = manaPotionX + buttonSize + buttonSpacing

    love.graphics.push("all")

    -- Draw bag icon with shadow and badge
    drawIconBox(bagX, buttonY, buttonSize, "bag", {
        shadow = true,
        badgeText = "I",
        iconPadding = 8,
    })

    world.bottomBarBagRect = {
        x = bagX,
        y = buttonY,
        w = buttonSize,
        h = buttonSize,
    }

    local player = world:getPlayer()
    local potions = player and player.potions
    local cooldownRatio = 0

    if potions and potions.cooldownRemaining and potions.cooldownRemaining > 0 then
        local duration = potions.cooldownDuration or 0.5
        if duration > 0 then
            cooldownRatio = potions.cooldownRemaining / duration
        end
    end

    local healthCount = potions and potions.healthPotionCount or 0
    local manaCount = potions and potions.manaPotionCount or 0
    local healthDisabled = healthCount <= 0
    local manaDisabled = manaCount <= 0

    drawIconBox(healthPotionX, buttonY, buttonSize, "health_potion", {
        shadow = true,
        badgeText = "1",
        badgeSize = 16,
        iconPadding = 8,
        disabled = healthDisabled,
        cooldownRatio = cooldownRatio,
    })

    drawIconBox(manaPotionX, buttonY, buttonSize, "mana_potion", {
        shadow = true,
        badgeText = "2",
        badgeSize = 16,
        iconPadding = 8,
        disabled = manaDisabled,
        cooldownRatio = cooldownRatio,
    })

    world.bottomBarHealthPotionRect = {
        x = healthPotionX,
        y = buttonY,
        w = buttonSize,
        h = buttonSize,
    }

    world.bottomBarManaPotionRect = {
        x = manaPotionX,
        y = buttonY,
        w = buttonSize,
        h = buttonSize,
    }

    love.graphics.pop()
end

return uiBottomBar
