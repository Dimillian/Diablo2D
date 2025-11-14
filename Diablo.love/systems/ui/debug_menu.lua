local experienceSystem = require("systems.core.experience")

local debugMenu = {}

local PANEL_WIDTH = 200
local PANEL_PADDING = 16
local BUTTON_HEIGHT = 32
local BUTTON_SPACING = 8

local function drawButton(x, y, width, height, text, isHovered)
    local cornerRadius = 4

    -- Background
    if isHovered then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
    else
        love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
    end
    love.graphics.rectangle("fill", x, y, width, height, cornerRadius, cornerRadius)

    -- Border
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, cornerRadius, cornerRadius)

    -- Text
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    local textX = x + (width - textWidth) / 2
    local textY = y + (height - textHeight) / 2
    love.graphics.print(text, textX, textY)

    love.graphics.setLineWidth(1)
end

function debugMenu.draw(world)
    if not world.debugMode then
        world.debugMenuButtonRects = nil
        return
    end

    local screenWidth = love.graphics.getWidth()

    local panelX = screenWidth - PANEL_WIDTH - PANEL_PADDING
    local panelY = PANEL_PADDING

    local mouseX, mouseY = love.mouse.getPosition()

    love.graphics.push("all")

    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    local titleText = "Debug Menu"
    local font = love.graphics.getFont()
    local titleWidth = font:getWidth(titleText)
    local titleX = panelX + (PANEL_WIDTH - titleWidth) / 2
    local titleY = panelY + PANEL_PADDING
    local titleHeight = font:getHeight()

    -- Button area
    local buttonAreaY = titleY + titleHeight + PANEL_PADDING
    local buttonWidth = PANEL_WIDTH - (PANEL_PADDING * 2)

    -- Initialize button rects table
    world.debugMenuButtonRects = {}

    -- Button labels
    local buttonLabels = {
        "Level Up",
        "Regen World",
        "Add Attr Point",
        "Add Skill Point",
    }

    -- Calculate panel height dynamically based on number of buttons
    local numButtons = #buttonLabels
    local buttonAreaHeight = (numButtons * BUTTON_HEIGHT) + ((numButtons - 1) * BUTTON_SPACING)
    local panelHeight = titleY - panelY + titleHeight + PANEL_PADDING + buttonAreaHeight + PANEL_PADDING

    -- Panel background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle("fill", panelX, panelY, PANEL_WIDTH, panelHeight, 6, 6)

    -- Panel border
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, PANEL_WIDTH, panelHeight, 6, 6)

    -- Draw title
    love.graphics.print(titleText, titleX, titleY)

    -- Draw buttons
    for i, label in ipairs(buttonLabels) do
        local buttonY = buttonAreaY + ((i - 1) * (BUTTON_HEIGHT + BUTTON_SPACING))
        local buttonX = panelX + PANEL_PADDING

        local rect = {
            x = buttonX,
            y = buttonY,
            w = buttonWidth,
            h = BUTTON_HEIGHT,
        }

        world.debugMenuButtonRects[i] = rect

        local isHovered = mouseX >= rect.x
            and mouseX <= rect.x + rect.w
            and mouseY >= rect.y
            and mouseY <= rect.y + rect.h

        drawButton(buttonX, buttonY, buttonWidth, BUTTON_HEIGHT, label, isHovered)
    end

    love.graphics.pop()
end

---Handle mouse clicks on debug menu buttons.
---@param world WorldScene The world scene
---@param x number Mouse X position
---@param y number Mouse Y position
---@return boolean True if click was handled by debug menu
function debugMenu.handleClick(world, x, y)
    if not world.debugMode or not world.debugMenuButtonRects then
        return false
    end

    local function pointInRect(rect)
        return rect
            and x >= rect.x
            and x <= rect.x + rect.w
            and y >= rect.y
            and y <= rect.y + rect.h
    end

    local player = world:getPlayer()
    if not player then
        return false
    end

    -- Level Up button (index 1)
    if pointInRect(world.debugMenuButtonRects[1]) then
        experienceSystem.triggerLevelUp(world, player)
        return true
    end

    -- Regenerate World button (index 2)
    if pointInRect(world.debugMenuButtonRects[2]) then
        world:resetWorld()
        return true
    end

    -- Add Attribute Point button (index 3)
    if pointInRect(world.debugMenuButtonRects[3]) then
        if player.experience then
            player.experience.unallocatedPoints = (player.experience.unallocatedPoints or 0) + 1
        end
        return true
    end

    -- Add Skill Point button (index 4)
    if pointInRect(world.debugMenuButtonRects[4]) then
        if player.skills then
            player.skills.availablePoints = (player.skills.availablePoints or 0) + 1
        end
        return true
    end

    return false
end

return debugMenu
