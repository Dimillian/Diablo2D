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

    -- Calculate badge position before drawing (needed for background)
    local letterBoxSize = 14
    local borderWidth = 2
    local letterBoxX = buttonX + buttonSize - letterBoxSize
    local letterBoxY = buttonY

    -- Badge background - drawn before button border so border appears on top
    -- Matches button background color
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", letterBoxX, letterBoxY, letterBoxSize, letterBoxSize, 0, 0)

    -- Button border (drawn after badge background so it appears on top)
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

    -- Draw only left and bottom borders (top and right borders are shared with button)
    -- These merge with the button's border to create a seamless corner badge
    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(2)
    -- Left border (vertical line) - aligns with button edge
    love.graphics.line(letterBoxX, letterBoxY, letterBoxX, letterBoxY + letterBoxSize)
    -- Bottom border (horizontal line) - aligns with button edge
    love.graphics.line(letterBoxX, letterBoxY + letterBoxSize, letterBoxX + letterBoxSize, letterBoxY + letterBoxSize)

    -- Draw "I" letter - center it in the badge area
    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth("I")
    local textHeight = font:getHeight()
    love.graphics.print("I", letterBoxX + (letterBoxSize - textWidth) / 2, letterBoxY + (letterBoxSize - textHeight) / 2)

    love.graphics.pop()
end

return uiBottomBar
