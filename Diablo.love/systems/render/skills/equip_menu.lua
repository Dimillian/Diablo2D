local Resources = require("modules.resources")

local renderSkillsEquipMenu = {}

local MENU_WIDTH = 260
local MENU_ITEM_HEIGHT = 48
local MENU_PADDING = 12

local function buildOptions(scene)
    local options = {
        { label = "Empty", spellId = nil },
    }

    for _, spell in ipairs(scene.availableSpells or {}) do
        options[#options + 1] = {
            label = spell.label or spell.id,
            spellId = spell.id,
            icon = spell.icon,
        }
    end

    return options
end

local function positionMenu(layout, slotRect, optionsCount)
    local height = optionsCount * MENU_ITEM_HEIGHT + MENU_PADDING * 2
    local x = slotRect.x + slotRect.w + 16
    local y = slotRect.y

    local screenWidth = layout and layout.screenWidth or love.graphics.getWidth()
    local screenHeight = layout and layout.screenHeight or love.graphics.getHeight()

    if x + MENU_WIDTH > screenWidth - 24 then
        x = slotRect.x - MENU_WIDTH - 16
    end
    if x < 24 then
        x = 24
    end

    if y + height > screenHeight - 24 then
        y = screenHeight - height - 24
    end
    if y < 24 then
        y = 24
    end

    return x, y, MENU_WIDTH, height
end

function renderSkillsEquipMenu.draw(scene)
    local menu = scene.equipMenu
    if not menu or not menu.slotIndex or not menu.slotRect then
        return
    end

    local layout = scene.windowLayout
    if not layout then
        return
    end

    local options = buildOptions(scene)
    if #options == 0 then
        return
    end

    local x, y, width, height = positionMenu(layout, menu.slotRect, #options)

    love.graphics.push("all")

    love.graphics.setColor(0.08, 0.08, 0.08, 0.94)
    love.graphics.rectangle("fill", x, y, width, height, 8, 8)
    love.graphics.setColor(0.75, 0.7, 0.5, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 8, 8)

    local mouseX, mouseY = love.mouse.getPosition()
    local cursorY = y + MENU_PADDING

    menu.optionRects = {}

    local player = scene.world and scene.world:getPlayer()
    local currentSpellId = player and player.skills and player.skills.equipped[menu.slotIndex] or nil

    for _, option in ipairs(options) do
        local optionRect = {
            x = x + MENU_PADDING,
            y = cursorY,
            w = width - MENU_PADDING * 2,
            h = MENU_ITEM_HEIGHT,
            spellId = option.spellId,
        }

        local isHovered = mouseX >= optionRect.x and mouseX <= optionRect.x + optionRect.w
            and mouseY >= optionRect.y and mouseY <= optionRect.y + optionRect.h

        if isHovered then
            love.graphics.setColor(1, 1, 1, 0.12)
            love.graphics.rectangle("fill", optionRect.x, optionRect.y, optionRect.w, optionRect.h, 6, 6)
        end

        local isSelected = option.spellId == currentSpellId or (not option.spellId and not currentSpellId)
        if isSelected then
            love.graphics.setColor(0.95, 0.85, 0.45, 1)
        else
            love.graphics.setColor(0.95, 0.9, 0.7, 1)
        end

        if option.icon then
            local icon = Resources.loadImageSafe(option.icon)
            if icon then
                local iconSize = MENU_ITEM_HEIGHT - 12
                local scale = math.min(iconSize / icon:getWidth(), iconSize / icon:getHeight())
                local drawHeight = icon:getHeight() * scale
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(
                    icon,
                    optionRect.x + 6,
                    optionRect.y + (MENU_ITEM_HEIGHT - drawHeight) / 2,
                    0,
                    scale,
                    scale
                )
                if isSelected then
                    love.graphics.setColor(0.95, 0.85, 0.45, 1)
                else
                    love.graphics.setColor(0.95, 0.9, 0.7, 1)
                end
                love.graphics.print(option.label, optionRect.x + iconSize + 12, optionRect.y + 12)
            else
                love.graphics.print(option.label, optionRect.x + 6, optionRect.y + 12)
            end
        else
            love.graphics.print(option.label, optionRect.x + 6, optionRect.y + 12)
        end

        menu.optionRects[#menu.optionRects + 1] = optionRect
        cursorY = cursorY + MENU_ITEM_HEIGHT
    end

    menu.bounds = { x = x, y = y, w = width, h = height }

    love.graphics.pop()
end

return renderSkillsEquipMenu
