local Resources = require("modules.resources")
local SkillTree = require("modules.skill_tree")
local renderSkillsList = {}

function renderSkillsList.draw(scene)
    local spells = scene.availableSpells or {}
    local layout = scene.windowLayout
    if not layout then
        return
    end

    local area = scene.listArea or layout.content
    if not area or area.width <= 0 or area.height <= 0 then
        return
    end

    local padding = layout.padding
    local font = love.graphics.getFont()

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print("Spells", area.x, area.y)

    local headerOffset = font:getHeight()
    if not scene.isTreeVisible then
        love.graphics.setColor(0.75, 0.7, 0.55, 1)
        love.graphics.print("Click a spell to open its skill tree", area.x, area.y + headerOffset + 6)
        headerOffset = headerOffset + font:getHeight() + 6
    end
    love.graphics.setColor(0.95, 0.9, 0.7, 1)

    local itemHeight = 54
    local spacing = 12
    local listTop = area.y + headerOffset + padding * 0.5

    scene.spellRects = {}
    scene.hoveredSpellId = nil

    local mouseX, mouseY = love.mouse.getPosition()

    local player = scene.world and scene.world:getPlayer()
    local skills = player and player.skills
    local selectedSpellId = scene.selectedSpellId

    for index, spell in ipairs(spells) do
        local rectY = listTop + (index - 1) * (itemHeight + spacing)
        local rect = {
            x = area.x,
            y = rectY,
            w = area.width,
            h = itemHeight,
            spell = spell,
        }

        local isSelected = selectedSpellId == spell.id
        if isSelected then
            love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
        else
            love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
        end
        love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 6, 6)
        if isSelected then
            love.graphics.setColor(0.95, 0.85, 0.45, 1)
        else
            love.graphics.setColor(0.6, 0.55, 0.35, 1)
        end
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
        love.graphics.print(string.format("Mana: %d", spell.manaCost or 0), rect.x + 72, rect.y + rect.h / 2 - 6)

        if skills then
            local totalPoints = SkillTree.getTotalPoints(skills, spell.id)
            local pointsText = string.format("Points: %d", totalPoints)
            local pointsX = rect.x + 72
            local pointsY = rect.y + rect.h - font:getHeight() - 6
            love.graphics.print(pointsText, pointsX, pointsY)
        end

        if mouseX >= rect.x and mouseX <= rect.x + rect.w and mouseY >= rect.y and mouseY <= rect.y + rect.h then
            love.graphics.setColor(1, 1, 1, 0.15)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 6, 6)
            scene.hoveredSpellId = spell.id
        elseif isSelected then
            love.graphics.setColor(1, 1, 1, 0.08)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, 6, 6)
        end

        scene.spellRects[#scene.spellRects + 1] = rect
    end
end

return renderSkillsList
