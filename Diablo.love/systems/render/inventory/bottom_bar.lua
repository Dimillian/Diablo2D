local Resources = require("modules.resources")

local renderInventoryBottomBar = {}

local BAR_HEIGHT = 32
renderInventoryBottomBar.HEIGHT = BAR_HEIGHT

local function selectGoldIcon(amount)
    if amount <= 2 then
        return "gold/gold_1"
    elseif amount <= 6 then
        return "gold/gold_2"
    end
    return "gold/gold_3"
end

local function formatGoldAmount(amount)
    local value = math.floor((amount or 0) + 0.5)
    local sign = value < 0 and "-" or ""
    value = math.abs(value)

    local digits = tostring(value)
    local reversed = digits:reverse()
    local parts = {}

    for index = 1, #reversed, 3 do
        parts[#parts + 1] = reversed:sub(index, index + 2):reverse()
    end

    for left = 1, math.floor(#parts / 2) do
        local right = #parts - left + 1
        parts[left], parts[right] = parts[right], parts[left]
    end

    return sign .. table.concat(parts, ",")
end

local function formatPotionCount(current, max)
    current = current or 0
    if max and max > 0 then
        return string.format("%d/%d", current, max)
    end
    return tostring(current)
end

local function drawEntry(entry, x, y, height, iconSize, textSpacing)
    local icon = entry.icon and Resources.loadUIIcon(entry.icon)
    local font = love.graphics.getFont()
    local centerY = y + height / 2
    local iconX = x
    local iconY = centerY - iconSize / 2

    if icon then
        local iconMaxDimension = math.max(icon:getWidth(), icon:getHeight())
        local iconScale = iconSize / iconMaxDimension
        local drawWidth = icon:getWidth() * iconScale
        local drawHeight = icon:getHeight() * iconScale
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            icon,
            iconX + (iconSize - drawWidth) / 2,
            iconY + (iconSize - drawHeight) / 2,
            0,
            iconScale,
            iconScale
        )
    end

    local textX = iconX + iconSize + textSpacing
    local textY = centerY - font:getHeight() / 2

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(entry.text, textX, textY)
end

function renderInventoryBottomBar.draw(scene)
    local player = scene.world:getPlayer()
    if not player then
        return
    end

    local layout = scene.windowLayout
    if not layout or not layout.footer then
        return
    end

    local inventory = player.inventory or {}
    local potions = player.potions or {}

    local goldAmount = inventory.gold or 0
    local healthCount = potions.healthPotionCount or 0
    local healthMax = potions.maxHealthPotionCount
    local manaCount = potions.manaPotionCount or 0
    local manaMax = potions.maxManaPotionCount

    local footer = layout.footer
    local entries = {
        { icon = selectGoldIcon(goldAmount), text = formatGoldAmount(goldAmount) },
        { icon = "health_potion", text = formatPotionCount(healthCount, healthMax) },
        { icon = "mana_potion", text = formatPotionCount(manaCount, manaMax) },
    }

    local font = love.graphics.getFont()
    local iconSize = 16
    local textSpacing = 8
    local gap = 48
    local currentX = footer.x

    love.graphics.setColor(0.4, 0.35, 0.25, 1)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(
        footer.x,
        footer.y - 8,
        footer.x + footer.width,
        footer.y - 8
    )

    local separatorTop = footer.y + 8
    local separatorBottom = footer.y + footer.height - 8
    local separatorColor = { 0.6, 0.5, 0.3, 1 }

    for index, entry in ipairs(entries) do
        drawEntry(entry, currentX, footer.y, footer.height, iconSize, textSpacing)
        local entryWidth = iconSize + textSpacing + font:getWidth(entry.text)
        local entryRight = currentX + entryWidth

        if index < #entries then
            local separatorX = entryRight + gap / 2
            love.graphics.setColor(separatorColor)
            love.graphics.setLineWidth(1)
            love.graphics.line(separatorX, separatorTop, separatorX, separatorBottom)
            currentX = entryRight + gap
        else
            currentX = entryRight
        end
    end
end

return renderInventoryBottomBar
