local Resources = require("modules.resources")
local InventoryLayout = require("systems.helpers.inventory_layout")

local renderInventoryBottomBar = {}

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

    local left = 1
    local right = #parts
    while left < right do
        parts[left], parts[right] = parts[right], parts[left]
        left = left + 1
        right = right - 1
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
        local drawX = iconX + (iconSize - drawWidth) / 2
        local drawY = iconY + (iconSize - drawHeight) / 2

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(icon, drawX, drawY, 0, iconScale, iconScale)
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

    local inventory = player.inventory or {}
    local potions = player.potions or {}

    local goldAmount = inventory.gold or 0
    local healthCount = potions.healthPotionCount or 0
    local healthMax = potions.maxHealthPotionCount
    local manaCount = potions.manaPotionCount or 0
    local manaMax = potions.maxManaPotionCount

    local panelLayout = InventoryLayout.calculatePanelLayout()
    local headersLayout = InventoryLayout.calculateHeadersLayout(
        panelLayout.panelX,
        panelLayout.panelY,
        panelLayout.panelWidth
    )

    local barHeight = InventoryLayout.BOTTOM_BAR_HEIGHT
    local barX = headersLayout.inventoryHeaderX
    local panelRight = panelLayout.panelX + panelLayout.panelWidth - 40
    local barWidth = panelRight - barX
    local barY = panelLayout.panelY + panelLayout.panelHeight - barHeight
    local dividerY = barY - 8

    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(1)
    love.graphics.line(barX, dividerY, barX + barWidth, dividerY)

    local entries = {
        {
            icon = selectGoldIcon(goldAmount),
            text = formatGoldAmount(goldAmount),
        },
        {
            icon = "health_potion",
            text = formatPotionCount(healthCount, healthMax),
        },
        {
            icon = "mana_potion",
            text = formatPotionCount(manaCount, manaMax),
        },
    }

    local entryCount = #entries
    if entryCount == 0 then
        return
    end

    local separatorColor = { 0.6, 0.5, 0.3, 1 }
    local iconSize = 16
    local textSpacing = 8
    local gap = 48
    local font = love.graphics.getFont()
    local entryWidths = {}

    for index, entry in ipairs(entries) do
        local width = iconSize + textSpacing + font:getWidth(entry.text)
        entryWidths[index] = width
    end

    local currentX = barX
    local separatorTop = barY + 8
    local separatorBottom = barY + barHeight - 8

    for index, entry in ipairs(entries) do
        drawEntry(entry, currentX, barY, barHeight, iconSize, textSpacing)
        local entryRight = currentX + entryWidths[index]

        if index < entryCount then
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
