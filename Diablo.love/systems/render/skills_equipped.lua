local Spells = require("data.spells")
local Resources = require("modules.resources")
local SkillsLayout = require("systems.helpers.skills_layout")

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

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print(spell.label or spell.id, x + size + 12, y + 6)
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.print(string.format("Mana: %d", spell.manaCost or 0), x + size + 12, y + 26)
end

function renderSkillsEquipped.draw(scene)
    local player = scene.world and scene.world:getPlayer()
    if not player or not player.skills then
        return
    end

    local layout = scene._skillsLayout or {}
    local panel = layout.panel or SkillsLayout.calculatePanel()
    local columns = layout.columns or SkillsLayout.calculateColumns(panel)
    local slotsLayout = SkillsLayout.calculateSlotsArea(panel, columns)

    scene.slotRects = {}
    scene.hoveredSlotIndex = nil

    local mouseX, mouseY = love.mouse.getPosition()

    for slotIndex = 1, 4 do
        local slotX = slotsLayout.x
        local slotY = slotsLayout.y + (slotIndex - 1) * (slotsLayout.slotSize + slotsLayout.slotSpacing)

        local rect = {
            x = slotX,
            y = slotY,
            w = slotsLayout.slotSize,
            h = slotsLayout.slotSize,
            index = slotIndex,
        }

        local isHovered = mouseX >= rect.x and mouseX <= rect.x + rect.w and mouseY >= rect.y and mouseY <= rect.y + rect.h
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
