local renderWindowChrome = require("systems.render.window.chrome")

local renderPauseMenu = {}

local MENU_ITEM_HEIGHT = 56
local MENU_ITEM_SPACING = 14
local MENU_WIDTH = 320
local MENU_PADDING = 24
local MENU_VERTICAL_PADDING = 16
local MENU_ITEM_COUNT = 5

function renderPauseMenu.draw(scene)
    renderWindowChrome.draw(scene, scene.windowChromeConfig)

    local layout = scene.windowLayout
    if not layout then
        return
    end

    local contentArea = layout.content
    local menuWidth = math.min(MENU_WIDTH, contentArea.width)
    local itemWidth = menuWidth - (MENU_PADDING * 2)
    if itemWidth < 0 then
        itemWidth = 0
    end
    local menuHeight = (MENU_ITEM_HEIGHT * MENU_ITEM_COUNT)
        + (MENU_ITEM_SPACING * (MENU_ITEM_COUNT - 1))
        + (MENU_VERTICAL_PADDING * 2)
    local menuX = contentArea.x + (contentArea.width - menuWidth) / 2
    local menuY = contentArea.y + (contentArea.height - menuHeight) / 2

    -- Only show hover states if this scene is the current top scene
    local isTopScene = false
    if scene.world and scene.world.sceneManager then
        isTopScene = scene.world.sceneManager:current() == scene
    end

    local mouseX, mouseY = love.mouse.getPosition()
    local font = love.graphics.getFont()

    -- Resume button
    local resumeY = menuY + MENU_VERTICAL_PADDING
    local isResumeHovered = isTopScene
        and mouseX >= menuX + MENU_PADDING
        and mouseX <= menuX + menuWidth - MENU_PADDING
        and mouseY >= resumeY
        and mouseY <= resumeY + MENU_ITEM_HEIGHT

    if isResumeHovered then
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle(
            "fill",
            menuX + MENU_PADDING,
            resumeY,
            itemWidth,
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
        and mouseX <= menuX + menuWidth - MENU_PADDING
        and mouseY >= controlsY
        and mouseY <= controlsY + MENU_ITEM_HEIGHT

    if isControlsHovered then
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle(
            "fill",
            menuX + MENU_PADDING,
            controlsY,
            itemWidth,
            MENU_ITEM_HEIGHT,
            4,
            4
        )
    end

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print("Controls", menuX + MENU_PADDING + 10, controlsY + (MENU_ITEM_HEIGHT - font:getHeight()) / 2)

    -- CRT toggle button
    local crtY = controlsY + MENU_ITEM_HEIGHT + MENU_ITEM_SPACING
    local isCRTHovered = isTopScene
        and mouseX >= menuX + MENU_PADDING
        and mouseX <= menuX + menuWidth - MENU_PADDING
        and mouseY >= crtY
        and mouseY <= crtY + MENU_ITEM_HEIGHT

    if isCRTHovered then
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle(
            "fill",
            menuX + MENU_PADDING,
            crtY,
            itemWidth,
            MENU_ITEM_HEIGHT,
            4,
            4
        )
    end

    local crtLabel = "CRT Shader: " .. (scene.isCRTEnabled and scene:isCRTEnabled() and "ON" or "OFF")
    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.print(crtLabel, menuX + MENU_PADDING + 10, crtY + (MENU_ITEM_HEIGHT - font:getHeight()) / 2)

    -- Main menu button
    local mainMenuY = crtY + MENU_ITEM_HEIGHT + MENU_ITEM_SPACING
    local isMainMenuHovered = isTopScene
        and mouseX >= menuX + MENU_PADDING
        and mouseX <= menuX + menuWidth - MENU_PADDING
        and mouseY >= mainMenuY
        and mouseY <= mainMenuY + MENU_ITEM_HEIGHT

    if isMainMenuHovered then
        love.graphics.setColor(0.35, 0.25, 0.25, 1)
        love.graphics.rectangle(
            "fill",
            menuX + MENU_PADDING,
            mainMenuY,
            itemWidth,
            MENU_ITEM_HEIGHT,
            4,
            4
        )
    end

    love.graphics.setColor(0.95, 0.75, 0.75, 1)
    love.graphics.print(
        "Return to Main Menu",
        menuX + MENU_PADDING + 10,
        mainMenuY + (MENU_ITEM_HEIGHT - font:getHeight()) / 2
    )

    -- Quit button
    local quitY = mainMenuY + MENU_ITEM_HEIGHT + MENU_ITEM_SPACING
    local isQuitHovered = isTopScene
        and mouseX >= menuX + MENU_PADDING
        and mouseX <= menuX + menuWidth - MENU_PADDING
        and mouseY >= quitY
        and mouseY <= quitY + MENU_ITEM_HEIGHT

    if isQuitHovered then
        love.graphics.setColor(0.4, 0.2, 0.2, 1)
        love.graphics.rectangle(
            "fill",
            menuX + MENU_PADDING,
            quitY,
            itemWidth,
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
        w = itemWidth,
        h = MENU_ITEM_HEIGHT,
    }
    scene.menuRects.controls = {
        x = menuX + MENU_PADDING,
        y = controlsY,
        w = itemWidth,
        h = MENU_ITEM_HEIGHT,
    }
    scene.menuRects.crt = {
        x = menuX + MENU_PADDING,
        y = crtY,
        w = itemWidth,
        h = MENU_ITEM_HEIGHT,
    }
    scene.menuRects.mainMenu = {
        x = menuX + MENU_PADDING,
        y = mainMenuY,
        w = itemWidth,
        h = MENU_ITEM_HEIGHT,
    }
    scene.menuRects.quit = {
        x = menuX + MENU_PADDING,
        y = quitY,
        w = itemWidth,
        h = MENU_ITEM_HEIGHT,
    }
end

return renderPauseMenu
