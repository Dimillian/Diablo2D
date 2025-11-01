local tooltips = {}

local rarityColors = {
    common = { 0.9, 0.9, 0.9, 1 },
    uncommon = { 0.3, 0.85, 0.4, 1 },
    rare = { 0.35, 0.65, 1, 1 },
    epic = { 0.7, 0.4, 0.9, 1 },
    legendary = { 1, 0.65, 0.2, 1 },
}

local function formatStatLines(item)
    local stats = item.stats or {}
    local lines = {}

    if stats.damageMin and stats.damageMax and (stats.damageMin > 0 or stats.damageMax > 0) then
        lines[#lines + 1] = string.format("Damage: %d - %d", stats.damageMin, stats.damageMax)
    end

    if stats.defense and stats.defense > 0 then
        lines[#lines + 1] = string.format("Defense: %d", stats.defense)
    end

    if stats.health and stats.health > 0 then
        lines[#lines + 1] = string.format("+%d Health", stats.health)
    end

    local function formatPercent(value)
        return string.format("+%.1f%%", value * 100)
    end

    if stats.critChance and stats.critChance > 0 then
        lines[#lines + 1] = formatPercent(stats.critChance) .. " Crit Chance"
    end

    if stats.moveSpeed and stats.moveSpeed > 0 then
        lines[#lines + 1] = formatPercent(stats.moveSpeed) .. " Move Speed"
    end

    if stats.dodgeChance and stats.dodgeChance > 0 then
        lines[#lines + 1] = formatPercent(stats.dodgeChance) .. " Dodge Chance"
    end

    if stats.goldFind and stats.goldFind > 0 then
        lines[#lines + 1] = formatPercent(stats.goldFind) .. " Gold Find"
    end

    if stats.lifeSteal and stats.lifeSteal > 0 then
        lines[#lines + 1] = formatPercent(stats.lifeSteal) .. " Life Steal"
    end

    if stats.attackSpeed and stats.attackSpeed > 0 then
        lines[#lines + 1] = formatPercent(stats.attackSpeed) .. " Attack Speed"
    end

    if stats.resistAll and stats.resistAll > 0 then
        lines[#lines + 1] = formatPercent(stats.resistAll) .. " All Resist"
    end

    if #lines == 0 then
        lines[#lines + 1] = "No bonuses"
    end

    return lines
end

---Draw a tooltip for an item at the specified position
---@param item table Item payload
---@param x number Screen X coordinate
---@param y number Screen Y coordinate
function tooltips.drawItemTooltip(item, x, y)
    if not item then
        return
    end

    local lines = formatStatLines(item)
    local rarityColor = rarityColors[item.rarity] or rarityColors.common
    local font = love.graphics.getFont()
    local padding = 10
    local lineHeight = font:getHeight()

    local function snap(value)
        return math.floor(value + 0.5)
    end

    local width = font:getWidth(item.name)
    width = math.max(width, font:getWidth(item.rarityLabel or ""))
    for _, line in ipairs(lines) do
        width = math.max(width, font:getWidth(line))
    end

    width = math.ceil(width + padding * 2)

    local height = math.ceil(lineHeight * (#lines + 1) + padding * 3)

    local tooltipX = snap(x + 16)
    local tooltipY = snap(y + 16)

    local screenWidth, screenHeight = love.graphics.getDimensions()

    if tooltipX + width > screenWidth then
        tooltipX = screenWidth - width - 8
    end

    if tooltipY + height > screenHeight then
        tooltipY = screenHeight - height - 8
    end

    love.graphics.push("all")

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", tooltipX, tooltipY, width, height, 6, 6)

    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", tooltipX, tooltipY, width, height, 6, 6)

    local titleY = tooltipY + padding
    love.graphics.setColor(rarityColor)
    love.graphics.print(item.name, snap(tooltipX + padding), snap(titleY))

    love.graphics.setColor(0.75, 0.75, 0.85, 1)
    love.graphics.print(item.rarityLabel, snap(tooltipX + padding), snap(titleY + lineHeight))

    love.graphics.setColor(1, 1, 1, 1)
    for index, line in ipairs(lines) do
        love.graphics.print(
            line,
            snap(tooltipX + padding),
            snap(titleY + lineHeight * (index + 1))
        )
    end

    love.graphics.pop()
end

tooltips.rarityColors = rarityColors

return tooltips
