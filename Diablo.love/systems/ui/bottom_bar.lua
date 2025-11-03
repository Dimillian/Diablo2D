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
---@param opts.countBadge number|nil Count badge to draw in bottom left corner (default: nil)
---@param opts.disabled boolean Whether icon is disabled (grayed out) (default: false)
local function drawIconBox(x, y, size, iconName, opts)
    opts = opts or {}
    local shadow = opts.shadow or false
    local badgeText = opts.badgeText
    local badgeSize = opts.badgeSize or 14
    local iconPadding = opts.iconPadding or (size >= 40 and 8 or 3)
    local countBadge = opts.countBadge
    local disabled = opts.disabled or false

    -- Draw shadow if requested
    if shadow then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 6, 6)
    end

    -- Draw background
    local bgAlpha = disabled and 0.5 or 0.9
    love.graphics.setColor(0.1, 0.1, 0.1, bgAlpha)
    local cornerRadius = size >= 40 and 4 or 3
    love.graphics.rectangle("fill", x, y, size, size, cornerRadius, cornerRadius)

    -- Draw badge background if needed (top right corner)
    if badgeText then
        local badgeBoxX = x + size - badgeSize
        local badgeBoxY = y
        love.graphics.setColor(0.1, 0.1, 0.1, bgAlpha)
        love.graphics.rectangle("fill", badgeBoxX, badgeBoxY, badgeSize, badgeSize, 0, 0)
    end

    -- Draw count badge background if needed (bottom left corner)
    if countBadge ~= nil then
        local countBoxX = x
        local countBoxY = y + size - badgeSize
        love.graphics.setColor(0.1, 0.1, 0.1, bgAlpha)
        love.graphics.rectangle("fill", countBoxX, countBoxY, badgeSize, badgeSize, 0, 0)
    end

    -- Draw border
    local borderAlpha = disabled and 0.4 or 1
    love.graphics.setColor(0.9, 0.85, 0.65, borderAlpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, size, size, cornerRadius, cornerRadius)

    -- Draw icon inside
    local iconImage = Resources.loadUIIcon(iconName)
    if iconImage then
        local iconInnerSize = size - (iconPadding * 2)
        local iconX = x + iconPadding
        local iconY = y + iconPadding

        local iconAlpha = disabled and 0.4 or 1
        love.graphics.setColor(1, 1, 1, iconAlpha)
        love.graphics.draw(iconImage, iconX, iconY, 0,
            iconInnerSize / iconImage:getWidth(),
            iconInnerSize / iconImage:getHeight())
    end

    -- Draw badge if needed (top right corner)
    if badgeText then
        local badgeBoxX = x + size - badgeSize
        local badgeBoxY = y

        -- Draw badge borders (left and bottom only, merge with main border)
        love.graphics.setColor(0.9, 0.85, 0.65, borderAlpha)
        love.graphics.setLineWidth(2)
        love.graphics.line(badgeBoxX, badgeBoxY, badgeBoxX, badgeBoxY + badgeSize)
        love.graphics.line(badgeBoxX, badgeBoxY + badgeSize, badgeBoxX + badgeSize, badgeBoxY + badgeSize)

        -- Draw badge text
        local badgeAlpha = disabled and 0.4 or 1
        love.graphics.setColor(0.95, 0.9, 0.7, badgeAlpha)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(badgeText)
        local textHeight = font:getHeight()
        local textX = badgeBoxX + (badgeSize - textWidth) / 2
        local textY = badgeBoxY + (badgeSize - textHeight) / 2
        love.graphics.print(badgeText, textX, textY)
    end

    -- Draw count badge if needed (bottom left corner)
    if countBadge ~= nil then
        local countBoxX = x
        local countBoxY = y + size - badgeSize

        -- Draw count badge borders (top and right only, merge with main border)
        love.graphics.setColor(0.9, 0.85, 0.65, borderAlpha)
        love.graphics.setLineWidth(2)
        love.graphics.line(countBoxX, countBoxY, countBoxX + badgeSize, countBoxY)
        love.graphics.line(countBoxX + badgeSize, countBoxY, countBoxX + badgeSize, countBoxY + badgeSize)

        -- Draw count badge text
        local countAlpha = disabled and 0.4 or 1
        love.graphics.setColor(0.95, 0.9, 0.7, countAlpha)
        local font = love.graphics.getFont()
        local countText = string.format("%d", countBadge)
        local textWidth = font:getWidth(countText)
        local textHeight = font:getHeight()
        local textX = countBoxX + (badgeSize - textWidth) / 2
        local textY = countBoxY + (badgeSize - textHeight) / 2
        love.graphics.print(countText, textX, textY)
    end
end

function uiBottomBar.draw(world)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Bottom bar positioning - next to health and mana bars
    -- Use the same bar height as player_status.lua (20px, not 24px)
    local healthBarWidth = math.min(screenWidth * 0.3, 240)
    local healthBarX = 32
    local healthBarHeight = 20 -- Match player_status.lua barHeight
    local buttonSize = 48 -- Bag icon height - total height should match this
    local spacing = buttonSize - (healthBarHeight * 2) -- Calculate spacing so both bars + gap = buttonSize
    local manaBarY = screenHeight - healthBarHeight - 32
    local healthBarY = manaBarY - healthBarHeight - spacing

    -- Layout: Health/Mana bars | Health potion | Mana potion | Bag icon
    local iconSpacing = 8
    local healthPotionX = healthBarX + healthBarWidth + iconSpacing
    local healthPotionY = healthBarY -- Align with top of health bar (covers both bars height)
    local manaPotionX = healthPotionX + buttonSize + iconSpacing
    local manaPotionY = healthPotionY
    local bagButtonX = manaPotionX + buttonSize + iconSpacing
    local bagButtonY = healthPotionY

    -- Get player for potion counts
    local player = world:getPlayer()
    local healthPotionCount = player and player.potions and player.potions.healthPotionCount or 0
    local manaPotionCount = player and player.potions and player.potions.manaPotionCount or 0

    -- Store rects for click detection
    world.bottomBarBagRect = {
        x = bagButtonX,
        y = bagButtonY,
        w = buttonSize,
        h = buttonSize,
    }

    world.bottomBarHealthPotionRect = {
        x = healthPotionX,
        y = healthPotionY,
        w = buttonSize,
        h = buttonSize,
    }
    world.bottomBarManaPotionRect = {
        x = manaPotionX,
        y = manaPotionY,
        w = buttonSize,
        h = buttonSize,
    }

    love.graphics.push("all")

    -- Draw health potion icon
    drawIconBox(healthPotionX, healthPotionY, buttonSize, "health_potion", {
        shadow = true,
        badgeText = "1", -- Hotkey in top right
        countBadge = healthPotionCount, -- Count in bottom left
        disabled = healthPotionCount == 0, -- Disabled if no potions
        iconPadding = 8,
    })

    -- Draw mana potion icon
    drawIconBox(manaPotionX, manaPotionY, buttonSize, "mana_potion", {
        shadow = true,
        badgeText = "2", -- Hotkey in top right
        countBadge = manaPotionCount, -- Count in bottom left
        disabled = manaPotionCount == 0, -- Disabled if no potions
        iconPadding = 8,
    })

    -- Draw bag icon with shadow and badge
    drawIconBox(bagButtonX, bagButtonY, buttonSize, "bag", {
        shadow = true,
        badgeText = "I",
        iconPadding = 8,
    })

    love.graphics.pop()
end

return uiBottomBar
