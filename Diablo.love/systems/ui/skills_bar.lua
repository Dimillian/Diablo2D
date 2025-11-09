local Spells = require("data.spells")
local Resources = require("modules.resources")

local uiSkillsBarSystem = {}

local SLOT_SIZE = 32
local SLOT_SPACING = 8

local function drawSlotBackground(x, y)
    love.graphics.setColor(0.08, 0.08, 0.08, 0.95)
    love.graphics.rectangle("fill", x, y, SLOT_SIZE, SLOT_SIZE, 4, 4)
end

local function drawSlotBorder(x, y)
    love.graphics.setColor(0.8, 0.75, 0.5, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, SLOT_SIZE, SLOT_SIZE, 4, 4)
end

local function drawSkillIcon(x, y, spell)
    if not spell or not spell.icon then
        return
    end

    local icon = Resources.loadImageSafe(spell.icon)
    if not icon then
        return
    end

    love.graphics.setColor(1, 1, 1, 1)
    local scale = math.min((SLOT_SIZE - 6) / icon:getWidth(), (SLOT_SIZE - 6) / icon:getHeight())
    local drawWidth = icon:getWidth() * scale
    local drawHeight = icon:getHeight() * scale
    love.graphics.draw(icon, x + (SLOT_SIZE - drawWidth) / 2, y + (SLOT_SIZE - drawHeight) / 2, 0, scale, scale)
end

function uiSkillsBarSystem.draw(world)
    local player = world:getPlayer()
    if not player or not player.skills then
        return
    end

    local startX
    local baseRect = world.bottomBarWorldMapRect or world.bottomBarBagRect or world.bottomBarManaPotionRect
    if baseRect then
        startX = baseRect.x + baseRect.w + 12
    else
        local screenWidth = love.graphics.getWidth()
        startX = screenWidth - (SLOT_SIZE + SLOT_SPACING) * 4 - 32
    end

    local startY
    local yBaseRect = world.bottomBarWorldMapRect or world.bottomBarBagRect
    if yBaseRect then
        startY = yBaseRect.y + (yBaseRect.h - SLOT_SIZE) / 2
    else
        startY = love.graphics.getHeight() - SLOT_SIZE - 32
    end

    love.graphics.push("all")

    for slotIndex = 1, 4 do
        local slotX = startX + (slotIndex - 1) * (SLOT_SIZE + SLOT_SPACING)
        local slotY = startY

        -- Draw hotkey number above the slot
        local font = love.graphics.getFont()
        local hotkeyText = tostring(slotIndex)
        local textWidth = font:getWidth(hotkeyText)
        local textHeight = font:getHeight()
        local textX = slotX + (SLOT_SIZE - textWidth) / 2
        local textY = slotY - textHeight - 4

        love.graphics.setColor(0.95, 0.9, 0.7, 1)
        love.graphics.print(hotkeyText, textX, textY)

        drawSlotBackground(slotX, slotY)
        drawSlotBorder(slotX, slotY)

        local spellId = player.skills.equipped[slotIndex]
        local spell = spellId and Spells.types[spellId] or nil
        if spell then
            drawSkillIcon(slotX, slotY, spell)

            local hasMana = player.mana and (player.mana.current or 0) >= (spell.manaCost or 0)
            if not hasMana then
                love.graphics.setColor(0, 0, 0, 0.55)
                love.graphics.rectangle("fill", slotX, slotY, SLOT_SIZE, SLOT_SIZE, 4, 4)
            end
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 0.4)
            love.graphics.rectangle("line", slotX + 6, slotY + 6, SLOT_SIZE - 12, SLOT_SIZE - 12, 4, 4)
        end
    end

    love.graphics.pop()
end

return uiSkillsBarSystem
