local Resources = require("modules.resources")
local UIConfig = require("systems.ui.config")

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
local function drawIconBox(x, y, size, iconName, opts)
    opts = opts or {}
    local shadow = opts.shadow or false
    local badgeText = opts.badgeText
    local badgeSize = opts.badgeSize or UIConfig.defaultBadgeSize
    local iconPadding = opts.iconPadding or (size >= 40 and UIConfig.iconPadding.large or UIConfig.iconPadding.small)
    local disabled = opts.disabled
    local cooldownRatio = opts.cooldownRatio or 0
    local highlightColor = opts.highlightColor
    local highlightPulse = opts.highlightPulse

    local boxConfig = UIConfig.iconBox
    local cornerRadius = size >= 40 and boxConfig.largeCornerRadius or boxConfig.smallCornerRadius
    local shadowOffset = boxConfig.shadowOffset or 0

    -- Draw shadow if requested
    if shadow then
        love.graphics.setColor(boxConfig.shadowColor)
        love.graphics.rectangle(
            "fill",
            x - shadowOffset,
            y - shadowOffset,
            size + shadowOffset * 2,
            size + shadowOffset * 2,
            cornerRadius,
            cornerRadius
        )
    end

    -- Draw background
    love.graphics.setColor(boxConfig.backgroundColor)
    love.graphics.rectangle("fill", x, y, size, size, cornerRadius, cornerRadius)

    -- Draw badge background if needed (before border)
    if badgeText then
        local letterBoxX = x + size - badgeSize
        local letterBoxY = y
        love.graphics.setColor(boxConfig.badgeBackgroundColor)
        love.graphics.rectangle("fill", letterBoxX, letterBoxY, badgeSize, badgeSize, 0, 0)
    end

    -- Draw border
    love.graphics.setColor(boxConfig.borderColor)
    love.graphics.setLineWidth(boxConfig.borderLineWidth)
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
        love.graphics.setColor(boxConfig.borderColor)
        love.graphics.setLineWidth(boxConfig.borderLineWidth)
        love.graphics.line(letterBoxX, letterBoxY, letterBoxX, letterBoxY + badgeSize)
        love.graphics.line(letterBoxX, letterBoxY + badgeSize, letterBoxX + badgeSize, letterBoxY + badgeSize)

        -- Draw badge text
        love.graphics.setColor(boxConfig.badgeTextColor)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(badgeText)
        local textHeight = font:getHeight()
        local textX = letterBoxX + (badgeSize - textWidth) / 2
        local textY = letterBoxY + (badgeSize - textHeight) / 2
        love.graphics.print(badgeText, textX, textY)
    end

    if disabled then
        love.graphics.setColor(boxConfig.disabledOverlayColor)
        love.graphics.rectangle("fill", x, y, size, size, cornerRadius, cornerRadius)
    end

    if cooldownRatio > 0 then
        cooldownRatio = math.min(1, math.max(0, cooldownRatio))
        local overlayHeight = size * cooldownRatio
        love.graphics.setColor(boxConfig.cooldownOverlayColor)
        love.graphics.rectangle("fill", x, y, size, overlayHeight, cornerRadius, cornerRadius)
    end

    if highlightColor then
        local r = highlightColor[1] or highlightColor.r or 1
        local g = highlightColor[2] or highlightColor.g or 1
        local b = highlightColor[3] or highlightColor.b or 1
        local baseAlpha = highlightColor[4] or highlightColor.a or 1

        if highlightPulse and love and love.timer and love.timer.getTime then
            local t = love.timer.getTime()
            local normalized = (math.sin(t * 4) + 1) / 2
            baseAlpha = baseAlpha * (0.65 + 0.35 * normalized)
        end

        local highlightLineWidth = boxConfig.highlightLineWidth or 2

        love.graphics.setColor(r, g, b, baseAlpha * 0.12)
        love.graphics.rectangle(
            "fill",
            x - 4,
            y - 4,
            size + 8,
            size + 8,
            cornerRadius + 2,
            cornerRadius + 2
        )

        love.graphics.setColor(r, g, b, baseAlpha * 0.45)
        love.graphics.setLineWidth(math.max(1, highlightLineWidth - 0.5))
        love.graphics.rectangle(
            "line",
            x - 4,
            y - 4,
            size + 8,
            size + 8,
            cornerRadius + 2,
            cornerRadius + 2
        )

        love.graphics.setColor(r, g, b, baseAlpha)
        love.graphics.setLineWidth(highlightLineWidth)
        love.graphics.rectangle(
            "line",
            x - 2,
            y - 2,
            size + 4,
            size + 4,
            cornerRadius + 1,
            cornerRadius + 1
        )
    end
end

local function drawIconButton(world, config)
    local rect = {
        x = config.x,
        y = config.y,
        w = config.size,
        h = config.size,
    }

    drawIconBox(config.x, config.y, config.size, config.iconName, config.opts)

    if config.rectField then
        world[config.rectField] = rect
    end

    return rect
end

function uiBottomBar.draw(world)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    world.bottomBarHealthPotionRect = nil
    world.bottomBarManaPotionRect = nil
    world.bottomBarBookRect = nil
    world.bottomBarBagRect = nil
    world.bottomBarWorldMapRect = nil

    -- Bottom bar positioning - next to health and mana bars
    local healthBarWidth = UIConfig.getHealthBarWidth(screenWidth)
    local healthBarX = UIConfig.barX
    local buttonSize = UIConfig.buttonSize
    local positions = UIConfig.getBottomBarPositions(screenHeight)
    local buttonY = positions.buttonY

    -- Layout icons horizontally: health/mana bars | health potion | mana potion | book | bag | world map
    local buttonSpacing = UIConfig.buttonSpacing
    local healthPotionX = healthBarX + healthBarWidth + buttonSpacing

    love.graphics.push("all")

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
    local buttonDescriptors = {
        {
            rectField = "bottomBarHealthPotionRect",
            iconName = "health_potion",
            badgeText = "5",
            badgeSize = UIConfig.potionBadgeSize,
            dynamicOpts = function()
                return {
                    disabled = healthDisabled,
                    cooldownRatio = cooldownRatio,
                }
            end,
        },
        {
            rectField = "bottomBarManaPotionRect",
            iconName = "mana_potion",
            badgeText = "6",
            badgeSize = UIConfig.potionBadgeSize,
            dynamicOpts = function()
                return {
                    disabled = manaDisabled,
                    cooldownRatio = cooldownRatio,
                }
            end,
        },
        {
            rectField = "bottomBarBookRect",
            iconName = "book",
            badgeText = "K",
        },
        {
            rectField = "bottomBarBagRect",
            iconName = "bag",
            badgeText = "I",
            dynamicOpts = function()
                local experience = player and player.experience
                local unallocated = experience and (experience.unallocatedPoints or 0) or 0

                if unallocated > 0 then
                    return {
                        highlightColor = { 1, 0.84, 0.3, 1 },
                        highlightPulse = true,
                    }
                end

                return nil
            end,
        },
        {
            rectField = "bottomBarWorldMapRect",
            iconName = "scroll",
            badgeText = "M",
        },
    }

    local currentX = healthPotionX

    for _, descriptor in ipairs(buttonDescriptors) do
        local opts = {
            shadow = true,
            iconPadding = UIConfig.iconPadding.large,
        }

        if descriptor.badgeText then
            opts.badgeText = descriptor.badgeText
        end

        if descriptor.badgeSize then
            opts.badgeSize = descriptor.badgeSize
        end

        if descriptor.dynamicOpts then
            local dynamicValues = descriptor.dynamicOpts()
            if dynamicValues then
                for key, value in pairs(dynamicValues) do
                    opts[key] = value
                end
            end
        end

        drawIconButton(world, {
            x = currentX,
            y = buttonY,
            size = buttonSize,
            iconName = descriptor.iconName,
            rectField = descriptor.rectField,
            opts = opts,
        })

        currentX = currentX + buttonSize + buttonSpacing
    end

    love.graphics.pop()
end

return uiBottomBar
