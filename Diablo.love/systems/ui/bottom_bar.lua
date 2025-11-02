local Resources = require("modules.resources")

local uiBottomBar = {}

function uiBottomBar.draw(world)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Bottom bar positioning - next to health bar
    local healthBarWidth = math.min(screenWidth * 0.3, 240)
    local healthBarX = 32
    local healthBarHeight = 24
    local healthBarY = screenHeight - healthBarHeight - 32

    -- Bag button size and positioning
    local buttonSize = 48
    local buttonX = healthBarX + healthBarWidth + 16
    local buttonY = healthBarY + (healthBarHeight - buttonSize) / 2

    -- Store rect for click detection
    world.bottomBarBagRect = {
        x = buttonX,
        y = buttonY,
        w = buttonSize,
        h = buttonSize,
    }

    love.graphics.push("all")

    -- Button background/shadow
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", buttonX - 2, buttonY - 2, buttonSize + 4, buttonSize + 4, 6, 6)

    -- Button background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", buttonX, buttonY, buttonSize, buttonSize, 4, 4)

    -- Button border
    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", buttonX, buttonY, buttonSize, buttonSize, 4, 4)

    -- Load and draw bag icon
    local bagImage = Resources.loadImageSafe("resources/icons/bag.png")
    if bagImage then
        local iconSize = buttonSize - 16
        local iconX = buttonX + (buttonSize - iconSize) / 2
        local iconY = buttonY + (buttonSize - iconSize) / 2

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(bagImage, iconX, iconY, 0, iconSize / bagImage:getWidth(), iconSize / bagImage:getHeight())
    end

    -- Draw "I" letter overlay in a small box
    local letterBoxSize = 16
    local letterBoxX = buttonX + buttonSize - letterBoxSize - 4
    local letterBoxY = buttonY + 4

    -- Letter box background
    love.graphics.setColor(0.2, 0.2, 0.25, 0.95)
    love.graphics.rectangle("fill", letterBoxX, letterBoxY, letterBoxSize, letterBoxSize, 2, 2)

    -- Letter box border
    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", letterBoxX, letterBoxY, letterBoxSize, letterBoxSize, 2, 2)

    -- Draw "I" letter
    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth("I")
    local textHeight = font:getHeight()
    love.graphics.print("I", letterBoxX + (letterBoxSize - textWidth) / 2, letterBoxY + (letterBoxSize - textHeight) / 2)

    love.graphics.pop()
end

return uiBottomBar
