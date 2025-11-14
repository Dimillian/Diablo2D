local Spells = require("data.spells")
local Resources = require("modules.resources")
local WindowLayout = require("systems.helpers.window_layout")

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
        local font = love.graphics.getFont()
        local placeholder = "Empty"
        local placeholderWidth = font:getWidth(placeholder)
        love.graphics.setColor(0.6, 0.55, 0.35, 0.9)
        love.graphics.print(placeholder, x + (size - placeholderWidth) / 2, y + size + 12)
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
    local label = spell.label or spell.id
    local labelWidth = font:getWidth(label)
    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print(label, x + (size - labelWidth) / 2, y + size + 6)

    local manaText = string.format("Mana: %d", spell.manaCost or 0)
    local manaWidth = font:getWidth(manaText)
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.print(manaText, x + (size - manaWidth) / 2, y + size + 24)
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

    local columns = layout.columns or WindowLayout.calculateColumns(layout, { leftRatio = 0.35 })
    layout.columns = columns
    local leftColumn = columns.left
    local area = scene.equippedArea or leftColumn
    local padding = layout.padding
    local font = love.graphics.getFont()

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print("Equipped", area.x, area.y)

    local slotsTop = area.y + font:getHeight() + padding * 0.5
    local slotSize = 52
    local slotSpacing = 18
    local slotCount = 4

    local maxWidth = area.width
    local totalWidth = slotSize * slotCount + slotSpacing * (slotCount - 1)
    if totalWidth > maxWidth then
        local availableSpacing = maxWidth - slotSize * slotCount
        slotSpacing = math.max(8, availableSpacing / math.max(1, slotCount - 1))
        totalWidth = slotSize * slotCount + slotSpacing * (slotCount - 1)
    end

    local slotsLeft = area.x + math.max(0, (maxWidth - totalWidth) / 2)

    scene.slotRects = {}
    scene.hoveredSlotIndex = nil

    local mouseX, mouseY = love.mouse.getPosition()

    for slotIndex = 1, 4 do
        local slotX = slotsLeft + (slotIndex - 1) * (slotSize + slotSpacing)
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

        drawSlot(rect.x, rect.y, rect.w, isHovered)

        local spellId = player.skills.equipped[slotIndex]
        local spell = spellId and Spells.types[spellId] or nil
        drawEquippedSpell(spell, rect.x, rect.y, rect.w)

        scene.slotRects[#scene.slotRects + 1] = rect
    end
end

return renderSkillsEquipped
