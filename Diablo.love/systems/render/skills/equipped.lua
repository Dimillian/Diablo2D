local Spells = require("data.spells")
local Resources = require("modules.resources")
local renderSkillsEquipped = {}

local function drawSlot(x, y, size, isHovered)
    love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
    love.graphics.rectangle("fill", x, y, size, size, 6, 6)
    love.graphics.setColor(0.6, 0.55, 0.35, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, size, size, 6, 6)

    if isHovered then
        love.graphics.setColor(1, 1, 1, 0.12)
        love.graphics.rectangle("fill", x, y, size, size, 6, 6)
    end
end

local function drawEquippedSpell(spell, x, y, size)
    if not spell then
        love.graphics.setColor(0.3, 0.3, 0.3, 0.35)
        love.graphics.rectangle("line", x + 8, y + 8, size - 16, size - 16, 6, 6)
        return
    end

    local icon = spell.icon and Resources.loadImageSafe(spell.icon)
    if icon then
        love.graphics.setColor(1, 1, 1, 1)
        local scale = math.min((size - 12) / icon:getWidth(), (size - 12) / icon:getHeight())
        local drawWidth = icon:getWidth() * scale
        local drawHeight = icon:getHeight() * scale
        love.graphics.draw(icon, x + (size - drawWidth) / 2, y + (size - drawHeight) / 2, 0, scale, scale)
    end

    local font = love.graphics.getFont()
    local textY = y + size + 6
    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    local label = spell.label or spell.id
    local textWidth = font:getWidth(label)
    love.graphics.print(label, x + (size - textWidth) / 2, textY)
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    local manaText = string.format("Mana: %d", spell.manaCost or 0)
    local manaWidth = font:getWidth(manaText)
    love.graphics.print(manaText, x + (size - manaWidth) / 2, textY + font:getHeight() + 2)
end

function renderSkillsEquipped.draw(scene)
    local player = scene.world and scene.world:getPlayer()
    if not player or not player.skills then
        return
    end

    local layout = scene.windowLayout
    if not layout then
        return
    end

    local area = scene.equippedArea or layout.content
    if not area or area.width <= 0 or area.height <= 0 then
        return
    end
    local padding = layout.padding
    local font = love.graphics.getFont()

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print("Equipped", area.x, area.y)

    local slotsTop = area.y + font:getHeight() + padding * 0.5
    local slotSize = 52
    local slotSpacing = 18
    local availableWidth = math.max(0, area.width)
    local requiredWidth = slotSize * 4 + slotSpacing * 3
    if availableWidth > 0 and requiredWidth > availableWidth then
        local extra = availableWidth - slotSize * 4
        slotSpacing = math.max(8, extra / 3)
    end

    scene.slotRects = {}
    scene.hoveredSlotIndex = nil

    local mouseX, mouseY = love.mouse.getPosition()

    for slotIndex = 1, 4 do
        local slotX = area.x + (slotIndex - 1) * (slotSize + slotSpacing)
        local slotY = slotsTop

        local rect = {
            x = slotX,
            y = slotY,
            w = slotSize,
            h = slotSize,
            index = slotIndex,
        }

        local isHovered = mouseX >= rect.x and mouseX <= rect.x + rect.w
            and mouseY >= rect.y and mouseY <= rect.y + rect.h
        if isHovered then
            scene.hoveredSlotIndex = slotIndex
        end

        local isMenuOpen = scene.equipMenu and scene.equipMenu.slotIndex == slotIndex
        drawSlot(rect.x, rect.y, rect.w, isHovered or isMenuOpen)

        if isMenuOpen then
            scene.equipMenu.slotRect = {
                x = rect.x,
                y = rect.y,
                w = rect.w,
                h = rect.h,
            }
        end

        local spellId = player.skills.equipped[slotIndex]
        local spell = spellId and Spells.types[spellId] or nil
        drawEquippedSpell(spell, rect.x, rect.y, rect.w)

        scene.slotRects[#scene.slotRects + 1] = rect
    end

end

return renderSkillsEquipped
