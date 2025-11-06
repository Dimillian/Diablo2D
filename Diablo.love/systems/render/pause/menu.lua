local renderPauseMenu = {}

local MENU_ITEM_HEIGHT = 50
local MENU_ITEM_SPACING = 10
local MENU_WIDTH = 300
local MENU_PADDING = 20

function renderPauseMenu.draw(scene)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Dimmed backdrop
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Calculate menu position (centered)
    local menuHeight = (MENU_ITEM_HEIGHT * 3) + (MENU_ITEM_SPACING * 2) + (MENU_PADDING * 2)
    local menuX = (screenWidth - MENU_WIDTH) / 2
    local menuY = (screenHeight - menuHeight) / 2

    -- Menu background
    love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
    love.graphics.rectangle("fill", menuX, menuY, MENU_WIDTH, menuHeight, 8, 8)

    -- Menu border
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", menuX, menuY, MENU_WIDTH, menuHeight, 8, 8)

    -- Only show hover states if this scene is the current top scene
    local isTopScene = false
    if scene.world and scene.world.sceneManager then
        isTopScene = scene.world.sceneManager:current() == scene
    end

    local mouseX, mouseY = love.mouse.getPosition()
    local font = love.graphics.getFont()

    -- Resume button
    local resumeY = menuY + MENU_PADDING
    local isResumeHovered = isTopScene
        and mouseX >= menuX + MENU_PADDING
        and mouseX <= menuX + MENU_WIDTH - MENU_PADDING
        and mouseY >= resumeY
        and mouseY <= resumeY + MENU_ITEM_HEIGHT

    if isResumeHovered then
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle(
            "fill",
            menuX + MENU_PADDING,
            resumeY,
            MENU_WIDTH - (MENU_PADDING * 2),
            MENU_ITEM_HEIGHT,
            4,
            4
        )
    end

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print("Resume", menuX + MENU_PADDING + 10, resumeY + (MENU_ITEM_HEIGHT - font:getHeight()) / 2)

    -- Controls button
    local controlsY = resumeY + MENU_ITEM_HEIGHT + MENU_ITEM_SPACING
    local isControlsHovered = isTopScene
        and mouseX >= menuX + MENU_PADDING
        and mouseX <= menuX + MENU_WIDTH - MENU_PADDING
        and mouseY >= controlsY
        and mouseY <= controlsY + MENU_ITEM_HEIGHT

    if isControlsHovered then
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle(
            "fill",
            menuX + MENU_PADDING,
            controlsY,
            MENU_WIDTH - (MENU_PADDING * 2),
            MENU_ITEM_HEIGHT,
            4,
            4
        )
    end

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print("Controls", menuX + MENU_PADDING + 10, controlsY + (MENU_ITEM_HEIGHT - font:getHeight()) / 2)

    -- Quit button
    local quitY = controlsY + MENU_ITEM_HEIGHT + MENU_ITEM_SPACING
    local isQuitHovered = isTopScene
        and mouseX >= menuX + MENU_PADDING
        and mouseX <= menuX + MENU_WIDTH - MENU_PADDING
        and mouseY >= quitY
        and mouseY <= quitY + MENU_ITEM_HEIGHT

    if isQuitHovered then
        love.graphics.setColor(0.4, 0.2, 0.2, 1)
        love.graphics.rectangle(
            "fill",
            menuX + MENU_PADDING,
            quitY,
            MENU_WIDTH - (MENU_PADDING * 2),
            MENU_ITEM_HEIGHT,
            4,
            4
        )
    end

    love.graphics.setColor(0.95, 0.7, 0.7, 1)
    love.graphics.print("Quit", menuX + MENU_PADDING + 10, quitY + (MENU_ITEM_HEIGHT - font:getHeight()) / 2)

    -- Store rects for click detection
    scene.menuRects = scene.menuRects or {}
    scene.menuRects.resume = {
        x = menuX + MENU_PADDING,
        y = resumeY,
        w = MENU_WIDTH - (MENU_PADDING * 2),
        h = MENU_ITEM_HEIGHT,
    }
    scene.menuRects.controls = {
        x = menuX + MENU_PADDING,
        y = controlsY,
        w = MENU_WIDTH - (MENU_PADDING * 2),
        h = MENU_ITEM_HEIGHT,
    }
    scene.menuRects.quit = {
        x = menuX + MENU_PADDING,
        y = quitY,
        w = MENU_WIDTH - (MENU_PADDING * 2),
        h = MENU_ITEM_HEIGHT,
    }
end

return renderPauseMenu
