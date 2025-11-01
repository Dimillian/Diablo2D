local Tooltips = {}

Tooltips.rarityColors = {
    common = { 0.9, 0.9, 0.9, 1 },
    uncommon = { 0.3, 0.85, 0.4, 1 },
    rare = { 0.35, 0.65, 1, 1 },
    epic = { 0.7, 0.4, 0.9, 1 },
    legendary = { 1, 0.65, 0.2, 1 },
}

local function snap(value)
    return math.floor(value + 0.5)
end

function Tooltips.getRarityColor(rarity)
    return Tooltips.rarityColors[rarity] or Tooltips.rarityColors.common
end

local function formatPercent(value)
    return string.format("+%.1f%%", value * 100)
end

function Tooltips.buildItemStatLines(item)
    if not item then
        return { "Unknown item" }
    end

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

local function measureTooltip(font, item, padding)
    local lines = Tooltips.buildItemStatLines(item)
    local width = font:getWidth(item.name or "Unknown Item")
    width = math.max(width, font:getWidth(item.rarityLabel or ""))

    for _, line in ipairs(lines) do
        width = math.max(width, font:getWidth(line))
    end

    width = width + padding * 2
    local lineHeight = font:getHeight()
    local height = lineHeight * (#lines + 2) + padding * 3

    return snap(width), snap(height), lines, lineHeight
end

function Tooltips.drawItemTooltip(item, pointerX, pointerY, opts)
    if not item then
        return
    end

    opts = opts or {}

    local font = opts.font or love.graphics.getFont()
    local padding = opts.padding or 10
    local offsetX = opts.offsetX or 16
    local offsetY = opts.offsetY or 16
    local clampToScreen = opts.clamp ~= false

    local width, height, lines, lineHeight = measureTooltip(font, item, padding)

    local tooltipX = snap(pointerX + offsetX)
    local tooltipY = snap(pointerY + offsetY)

    if clampToScreen then
        local screenWidth, screenHeight = love.graphics.getDimensions()

        if tooltipX + width > screenWidth then
            tooltipX = screenWidth - width - 8
        end

        if tooltipY + height > screenHeight then
            tooltipY = screenHeight - height - 8
        end
    end

    love.graphics.push("all")

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", tooltipX, tooltipY, width, height, 6, 6)

    love.graphics.setColor(0.9, 0.85, 0.65, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", tooltipX, tooltipY, width, height, 6, 6)

    local rarityColor = Tooltips.getRarityColor(item.rarity)

    local titleX = snap(tooltipX + padding)
    local titleY = snap(tooltipY + padding)

    love.graphics.setColor(rarityColor)
    love.graphics.print(item.name or "Unknown Item", titleX, titleY)

    love.graphics.setColor(0.75, 0.75, 0.85, 1)
    love.graphics.print(item.rarityLabel or "", titleX, snap(titleY + lineHeight))

    love.graphics.setColor(1, 1, 1, 1)
    for index, line in ipairs(lines) do
        love.graphics.print(
            line,
            titleX,
            snap(titleY + lineHeight * (index + 1))
        )
    end

    love.graphics.pop()
end

return Tooltips
