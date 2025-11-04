local Spells = require("data.spells")

local renderSkillsTooltip = {}

local function findSpell(scene)
    local spellId = scene.hoveredSpellId
    if spellId then
        return Spells.types[spellId]
    end

    local slotIndex = scene.hoveredSlotIndex
    if slotIndex and scene.world then
        local player = scene.world:getPlayer()
        if player and player.skills then
            local equippedId = player.skills.equipped[slotIndex]
            if equippedId then
                return Spells.types[equippedId]
            end
        end
    end
end

local function buildTooltipLines(spell)
    local lines = {}
    lines[#lines + 1] = spell.label or spell.id
    if spell.description then
        lines[#lines + 1] = spell.description
    end
    if spell.damage then
        local minDamage = spell.damage.min or 0
        local maxDamage = spell.damage.max or spell.damage.min or 0
        lines[#lines + 1] = string.format("Damage: %d - %d", minDamage, maxDamage)
    end
    lines[#lines + 1] = string.format("Mana Cost: %d", spell.manaCost or 0)
    return lines
end

function renderSkillsTooltip.draw(scene)
    local spell = findSpell(scene)
    if not spell then
        return
    end

    local lines = buildTooltipLines(spell)
    local font = love.graphics.getFont()
    local maxWidth = 0
    for _, line in ipairs(lines) do
        maxWidth = math.max(maxWidth, font:getWidth(line))
    end

    local padding = 10
    local height = #lines * (font:getHeight() + 2) + padding
    local width = maxWidth + padding * 2

    local mouseX, mouseY = love.mouse.getPosition()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local x = mouseX + 20
    local y = mouseY + 20

    if x + width > screenWidth then
        x = screenWidth - width - 12
    end
    if y + height > screenHeight then
        y = screenHeight - height - 12
    end

    love.graphics.push("all")
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", x, y, width, height, 6, 6)
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 6, 6)

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    local cursorY = y + padding / 2
    for _, line in ipairs(lines) do
        love.graphics.print(line, x + padding, cursorY)
        cursorY = cursorY + font:getHeight() + 2
    end

    love.graphics.pop()
end

return renderSkillsTooltip
