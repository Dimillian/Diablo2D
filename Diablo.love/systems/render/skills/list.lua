local Resources = require("modules.resources")
local SkillsLayout = require("systems.helpers.skills_layout")

local renderSkillsList = {}

function renderSkillsList.draw(scene)
    local spells = scene.availableSpells or {}
    local layout = scene._skillsLayout or {}
    local panel = layout.panel or SkillsLayout.calculatePanel()
    local columns = layout.columns or SkillsLayout.calculateColumns(panel)
    local listArea = SkillsLayout.calculateListArea(panel, columns)
    scene._skillsLayout.list = listArea

    scene.spellRects = {}
    scene.hoveredSpellId = nil

    local mouseX, mouseY = love.mouse.getPosition()

    for index, spell in ipairs(spells) do
        local itemY = listArea.y + (index - 1) * (listArea.itemHeight + listArea.spacing)
        local rect = {
            x = listArea.x,
            y = itemY,
            w = listArea.width,
            h = listArea.itemHeight,
            spell = spell,
        }

        love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 6, 6)
        love.graphics.setColor(0.6, 0.55, 0.35, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, 6, 6)

        local icon = spell.icon and Resources.loadImageSafe(spell.icon)
        if icon then
            love.graphics.setColor(1, 1, 1, 1)
            local iconSize = rect.h - 16
            local scale = math.min(iconSize / icon:getWidth(), iconSize / icon:getHeight())
            local drawHeight = icon:getHeight() * scale
            love.graphics.draw(icon, rect.x + 12, rect.y + (rect.h - drawHeight) / 2, 0, scale, scale)
        end

        love.graphics.setColor(0.95, 0.9, 0.7, 1)
        love.graphics.print(spell.label or spell.id, rect.x + 72, rect.y + 8)

        love.graphics.setColor(0.8, 0.75, 0.5, 1)
        local manaText = string.format("Mana: %d", spell.manaCost or 0)
        love.graphics.print(manaText, rect.x + 72, rect.y + rect.h / 2)

        if mouseX >= rect.x and mouseX <= rect.x + rect.w and mouseY >= rect.y and mouseY <= rect.y + rect.h then
            love.graphics.setColor(1, 1, 1, 0.15)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 6, 6)
            scene.hoveredSpellId = spell.id
        end

        scene.spellRects[#scene.spellRects + 1] = rect
    end
end

return renderSkillsList
