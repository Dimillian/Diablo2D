local Resources = require("modules.resources")

local uiBottomBar = {}

local function snap(value)
    return math.floor(value + 0.5)
end

---Draw a UI icon box (reusable component)
---@param x number X position
---@param y number Y position
---@param size number Box size (square)
---@param iconName string Icon name to load (e.g., "bag", "health_potion")
---@param opts table|nil Optional parameters
---@param opts.shadow boolean Whether to draw shadow (default: false)
---@param opts.badgeText string|nil Badge text to draw in corner (default: nil)
---@param opts.badgeSize number Badge size (default: 14)
---@param opts.iconPadding number Padding around icon (default: 3 for small boxes, 8 for large)
local function drawIconBox(x, y, size, iconName, opts)
    opts = opts or {}
    local shadow = opts.shadow or false
    local badgeText = opts.badgeText
    local badgeSize = opts.badgeSize or 14
    local iconPadding = opts.iconPadding or (size >= 40 and 8 or 3)
    local disabled = opts.disabled
    local cooldownRatio = opts.cooldownRatio or 0
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

    -- Calculate potion positions first (TESTING - hardcoded values for visual testing)
    -- Potion box: height = bar height, width = height (square)
    local potionIconSize = healthBarHeight -- 20px x 20px square (matching actual bar height)
    local potionSpacing = 8
    local healthPotionX = healthBarX + healthBarWidth + potionSpacing
    local healthPotionY = healthBarY -- Align with health bar top
    local manaPotionX = healthPotionX
    local manaPotionY = manaBarY -- Align with mana bar top (which already accounts for spacing)

    -- Bag button size and positioning - adjust to account for potion icons
    -- Potions are 20px wide (matching bar height), so bag should start after potions + spacing
    local buttonX = healthPotionX + potionIconSize + potionSpacing
    local buttonY = healthBarY -- Bars total height equals buttonSize, so align top edges

    -- Store rect for click detection
    world.bottomBarBagRect = {
        x = buttonX,
        y = buttonY,
        w = buttonSize,
        h = buttonSize,
    }

    love.graphics.push("all")

    -- Draw bag icon with shadow and badge
    drawIconBox(buttonX, buttonY, buttonSize, "bag", {
        shadow = true,
        badgeText = "I",
        iconPadding = 8,
    })

    world.bottomBarBagRect = {
        x = buttonX,
        y = buttonY,
        w = buttonSize,
        h = buttonSize,
    }

    local player = world:getPlayer()
    local potions = player and player.potions
    local health = player and player.health
    local mana = player and player.mana
    local cooldownRatio = 0

    if potions and potions.cooldownRemaining and potions.cooldownRemaining > 0 then
        local duration = potions.cooldownDuration or 0.5
        if duration > 0 then
            cooldownRatio = potions.cooldownRemaining / duration
        end
    end

    local healthCount = potions and potions.healthPotionCount or 0
    local healthMax = potions and potions.maxHealthPotionCount or healthCount
    local canUseHealth = potions
        and healthCount > 0
        and health
        and health.current < health.max
        and cooldownRatio == 0
    local healthDisabled = not canUseHealth

    local manaCount = potions and potions.manaPotionCount or 0
    local manaMax = potions and potions.maxManaPotionCount or manaCount
    local canUseMana = potions
        and manaCount > 0
        and mana
        and mana.current < mana.max
        and cooldownRatio == 0
    local manaDisabled = not canUseMana

    drawIconBox(healthPotionX, healthPotionY, potionIconSize, "health_potion", {
        badgeText = "1",
        disabled = healthDisabled,
        cooldownRatio = cooldownRatio,
    })

    drawIconBox(manaPotionX, manaPotionY, potionIconSize, "mana_potion", {
        badgeText = "2",
        disabled = manaDisabled,
        cooldownRatio = cooldownRatio,
    })

    world.bottomBarHealthPotionRect = {
        x = healthPotionX,
        y = healthPotionY,
        w = potionIconSize,
        h = potionIconSize,
    }

    world.bottomBarManaPotionRect = {
        x = manaPotionX,
        y = manaPotionY,
        w = potionIconSize,
        h = potionIconSize,
    }

    if potions then
        local font = love.graphics.getFont()
        local textHeight = font:getHeight()
        local healthTextY = snap(healthPotionY + (potionIconSize - textHeight) / 2)
        local manaTextY = snap(manaPotionY + (potionIconSize - textHeight) / 2)
        local healthText = string.format("%d/%d", healthCount, healthMax)
        local manaText = string.format("%d/%d", manaCount, manaMax)
        local healthTextColor = healthDisabled and { 0.7, 0.7, 0.7, 1 } or { 1, 1, 1, 1 }
        local manaTextColor = manaDisabled and { 0.7, 0.7, 0.7, 1 } or { 1, 1, 1, 1 }

        love.graphics.setColor(healthTextColor)
        love.graphics.print(healthText, snap(healthPotionX + potionIconSize + 6), healthTextY)
        love.graphics.setColor(manaTextColor)
        love.graphics.print(manaText, snap(manaPotionX + potionIconSize + 6), manaTextY)
    end

    love.graphics.pop()
end

return uiBottomBar
