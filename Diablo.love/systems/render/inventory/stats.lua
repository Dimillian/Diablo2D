---Render system for inventory stats section
local EquipmentHelper = require("systems.helpers.equipment")
local WindowLayout = require("systems.helpers.window_layout")

local renderInventoryStats = {}

local function snap(value)
    return math.floor(value + 0.5)
end

local attributeDisplayOrder = {
    { key = "strength", label = "Strength", always = true, type = "int" },
    { key = "dexterity", label = "Dexterity", always = true, type = "int" },
    { key = "vitality", label = "Vitality", always = true, type = "int" },
    { key = "intelligence", label = "Intelligence", always = true, type = "int" },
}

local statDisplayOrder = {
    { key = "health", label = "Health", always = true, type = "int" },
    { key = "defense", label = "Defense", type = "int" },
    { key = "critChance", label = "Crit Chance", type = "percent" },
    { key = "attackSpeed", label = "Attack Speed", type = "percent" },
    { key = "lifeSteal", label = "Life Steal", type = "percent" },
    { key = "moveSpeed", label = "Move Speed", type = "percent" },
    { key = "dodgeChance", label = "Dodge Chance", type = "percent" },
    { key = "goldFind", label = "Gold Find", type = "percent" },
    { key = "resistAll", label = "All Resist", type = "percent" },
}

local function buildAttributeLines(baseStats)
    local lines = {}

    if not baseStats then
        return lines
    end

    for _, entry in ipairs(attributeDisplayOrder) do
        local value = baseStats[entry.key] or 0
        if value ~= 0 or entry.always then
            lines[#lines + 1] = string.format("%s: %d", entry.label, math.floor(value + 0.5))
        end
    end

    return lines
end

local function buildSummaryLines(total)
    local lines = {}

    local damageMin = total.damageMin or 0
    local damageMax = total.damageMax or 0
    if damageMin > 0 or damageMax > 0 then
        lines[#lines + 1] = string.format("Damage: %d - %d", math.floor(damageMin + 0.5), math.floor(damageMax + 0.5))
    end

    for _, entry in ipairs(statDisplayOrder) do
        local value = total[entry.key] or 0
        if value ~= 0 or entry.always then
            if entry.type == "percent" then
                lines[#lines + 1] = string.format("%s: %.1f%%", entry.label, value * 100)
            else
                lines[#lines + 1] = string.format("%s: %d", entry.label, math.floor(value + 0.5))
            end
        end
    end

    if #lines == 0 then
        lines[#lines + 1] = "No stats"
    end

    return lines
end

function renderInventoryStats.draw(scene)
    local player = scene.world:getPlayer()
    if not player then
        return
    end

    local layout = scene.windowLayout
    if not layout then
        return
    end

    local areas = layout.inventoryAreas
    if not areas or not areas.stats then
        return
    end

    local statsArea = areas.stats
    if statsArea.height <= 0 then
        return
    end

    -- Split stats area into two columns
    local columns = WindowLayout.calculateColumns({ content = statsArea }, { leftRatio = 0.5, spacing = 16 })
    local leftColumn = columns.left
    local rightColumn = columns.right

    -- Draw divider line
    love.graphics.setColor(0.35, 0.32, 0.28, 1)
    love.graphics.setLineWidth(1)
    love.graphics.line(
        statsArea.x,
        statsArea.y,
        statsArea.x + statsArea.width,
        statsArea.y
    )

    -- Draw vertical divider between columns
    love.graphics.line(
        columns.dividerX,
        statsArea.y,
        columns.dividerX,
        statsArea.y + statsArea.height
    )

    local font = love.graphics.getFont()
    local headerY = statsArea.y + 12
    local lineHeight = font:getHeight() + 4
    local startY = snap(headerY + font:getHeight() + 8)

    -- Initialize attribute rects for hover detection
    scene.attributeRects = scene.attributeRects or {}

    -- Left column: Attributes
    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print("Attributes", leftColumn.x, headerY)

    local baseStats = player.baseStats or {}
    local attributeLines = buildAttributeLines(baseStats)
    love.graphics.setColor(1, 1, 1, 1)

    -- Clear previous rects
    scene.attributeRects = {}

    for index, line in ipairs(attributeLines) do
        local y = startY + (index - 1) * lineHeight
        if y > statsArea.y + statsArea.height - lineHeight then
            break
        end

        -- Store rect for hover detection
        local attributeEntry = attributeDisplayOrder[index]
        if attributeEntry then
            local textWidth = font:getWidth(line)
            scene.attributeRects[#scene.attributeRects + 1] = {
                x = leftColumn.x,
                y = y,
                w = textWidth,
                h = lineHeight,
                attributeKey = attributeEntry.key,
                attributeValue = baseStats[attributeEntry.key] or 0,
            }
        end

        love.graphics.print(line, leftColumn.x, y)
    end

    -- Right column: Derived Stats
    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print("Stats", rightColumn.x, headerY)

    local totalStats = EquipmentHelper.computeTotalStats(player)
    local statLines = buildSummaryLines(totalStats)
    love.graphics.setColor(1, 1, 1, 1)
    for index, line in ipairs(statLines) do
        local y = startY + (index - 1) * lineHeight
        if y > statsArea.y + statsArea.height - lineHeight then
            break
        end
        love.graphics.print(line, rightColumn.x, y)
    end
end

return renderInventoryStats
