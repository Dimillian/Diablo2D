local Resources = require("modules.resources")
local InventoryLayout = require("systems.helpers.inventory_layout")

local renderInventoryGold = {}

local function selectGoldIcon(amount)
    if amount <= 2 then
        return "gold/gold_1"
    elseif amount <= 6 then
        return "gold/gold_2"
    end

    return "gold/gold_3"
end

local function formatGoldAmount(amount)
    local value = math.floor(amount + 0.5)
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

    local formatted = table.concat(parts, ",")
    return sign .. formatted
end

function renderInventoryGold.draw(scene)
    local player = scene.world:getPlayer()
    if not player or not player.inventory then
        return
    end

    local gold = player.inventory.gold or 0

    local panelLayout = InventoryLayout.calculatePanelLayout()
    local headersLayout = InventoryLayout.calculateHeadersLayout(
        panelLayout.panelX,
        panelLayout.panelY,
        panelLayout.panelWidth
    )
    local gridLayout = InventoryLayout.calculateInventoryLayout(
        headersLayout.inventoryHeaderX,
        headersLayout.headerY,
        panelLayout.panelX,
        panelLayout.panelY,
        panelLayout.panelWidth,
        panelLayout.panelHeight
    )

    local displayHeight = 26
    local font = love.graphics.getFont()
    local iconAreaWidth = displayHeight
    local labelText = "Gold"
    local amountText = formatGoldAmount(gold)
    local textWidth = math.max(font:getWidth(labelText), font:getWidth(amountText))
    local horizontalPadding = 16
    local displayWidth = iconAreaWidth + horizontalPadding + textWidth + 16

    local displayX = headersLayout.inventoryHeaderX
    local minY = headersLayout.headerY + 4
    local maxY = gridLayout.gridStartY - displayHeight - 6
    local displayY = math.max(minY, maxY)

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", displayX, displayY, displayWidth, displayHeight, 5, 5)

    love.graphics.setColor(0.95, 0.85, 0.5, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", displayX, displayY, displayWidth, displayHeight, 5, 5)

    local iconName = selectGoldIcon(gold)
    local icon = Resources.loadUIIcon(iconName)
    if icon then
        local iconSize = displayHeight - 8
        local iconMaxDimension = math.max(icon:getWidth(), icon:getHeight())
        local iconScale = iconSize / iconMaxDimension
        local drawWidth = icon:getWidth() * iconScale
        local drawHeight = icon:getHeight() * iconScale
        local iconX = displayX + 6 + (iconSize - drawWidth) / 2
        local iconY = displayY + (displayHeight - drawHeight) / 2

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(icon, iconX, iconY, 0, iconScale, iconScale)
    end

    local textX = displayX + iconAreaWidth + horizontalPadding
    local labelY = displayY + 2
    local amountY = labelY + font:getHeight()

    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print(labelText, textX, labelY)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(amountText, textX, amountY)
end

return renderInventoryGold
