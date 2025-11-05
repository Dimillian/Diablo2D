---Render system for inventory stats section
local EquipmentHelper = require("systems.helpers.equipment")

local renderInventoryStats = {}

local function snap(value)
    return math.floor(value + 0.5)
end

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

    love.graphics.setColor(0.35, 0.32, 0.28, 1)
    love.graphics.setLineWidth(1)
    love.graphics.line(
        statsArea.x,
        statsArea.y,
        statsArea.x + statsArea.width,
        statsArea.y
    )

    local font = love.graphics.getFont()
    local headerY = statsArea.y + 12
    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print("Stats", statsArea.x, headerY)

    local totalStats = EquipmentHelper.computeTotalStats(player)
    local statLines = buildSummaryLines(totalStats)
    local lineHeight = font:getHeight() + 4
    local startY = snap(headerY + font:getHeight() + 8)

    love.graphics.setColor(1, 1, 1, 1)
    for index, line in ipairs(statLines) do
        local y = startY + (index - 1) * lineHeight
        if y > statsArea.y + statsArea.height - lineHeight then
            break
        end
        love.graphics.print(line, statsArea.x, y)
    end
end

return renderInventoryStats
