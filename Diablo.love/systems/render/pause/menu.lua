local renderWindowChrome = require("systems.render.window.chrome")

local renderPauseMenu = {}

local MENU_ITEM_HEIGHT = 56
local MENU_ITEM_SPACING = 14
local MENU_WIDTH = 320
local MENU_PADDING = 24
local MENU_VERTICAL_PADDING = 12
local STATUS_MARGIN_TOP = 22

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
    local menuX = contentArea.x + (contentArea.width - menuWidth) / 2

    local itemIds = { "resume", "save", "load", "controls", "crt", "mainMenu", "quit" }
    local totalMenuHeight = (#itemIds * MENU_ITEM_HEIGHT) + ((#itemIds - 1) * MENU_ITEM_SPACING)
    local availableHeight = contentArea.height
    local startOffset = (availableHeight - totalMenuHeight) / 2
    if startOffset < MENU_VERTICAL_PADDING then
        startOffset = MENU_VERTICAL_PADDING
    end
    local menuY = contentArea.y + startOffset

    -- Only show hover states if this scene is the current top scene
    local isTopScene = false
    if scene.world and scene.world.sceneManager then
        isTopScene = scene.world.sceneManager:current() == scene
    end

    local mouseX, mouseY = love.mouse.getPosition()
    local font = love.graphics.getFont()

    local y = menuY
    scene.menuRects = scene.menuRects or {}
    local crtLabel = "CRT Shader: " .. (scene.isCRTEnabled and scene:isCRTEnabled() and "ON" or "OFF")
    local labels = {
        resume = "Resume",
        save = "Save Game",
        load = "Load Game",
        controls = "Controls",
        crt = crtLabel,
        mainMenu = "Return to Main Menu",
        quit = "Quit",
    }

    for _, id in ipairs(itemIds) do
        local rect = {
            x = menuX + MENU_PADDING,
            y = y,
            w = itemWidth,
            h = MENU_ITEM_HEIGHT,
        }

        local hovered = isTopScene
            and mouseX >= rect.x
            and mouseX <= rect.x + rect.w
            and mouseY >= rect.y
            and mouseY <= rect.y + rect.h

        if hovered then
            local baseColor = { 0.3, 0.3, 0.3, 1 }
            if id == "mainMenu" then
                baseColor = { 0.35, 0.25, 0.25, 1 }
            elseif id == "quit" then
                baseColor = { 0.4, 0.2, 0.2, 1 }
            end
            love.graphics.setColor(baseColor)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 4, 4)
        end

        local textColor = { 0.95, 0.9, 0.7, 1 }
        if id == "mainMenu" then
            textColor = { 0.95, 0.75, 0.75, 1 }
        elseif id == "quit" then
            textColor = { 0.95, 0.7, 0.7, 1 }
        elseif id == "crt" then
            textColor = { 0.9, 0.85, 0.65, 1 }
        end

        love.graphics.setColor(textColor)
        love.graphics.print(labels[id], rect.x + 10, rect.y + (MENU_ITEM_HEIGHT - font:getHeight()) / 2)

        scene.menuRects[id] = rect
        y = y + MENU_ITEM_HEIGHT + MENU_ITEM_SPACING
    end

    -- Status message
    if scene.statusMessage then
        love.graphics.setColor(0.9, 0.85, 0.8, 0.9)
        love.graphics.printf(
            scene.statusMessage,
            menuX,
            y + STATUS_MARGIN_TOP,
            menuWidth,
            "center"
        )
    end
end

return renderPauseMenu
