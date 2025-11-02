---Render system for inventory stats section
local EquipmentHelper = require("system_helpers.equipment")
local InventoryLayout = require("system_helpers.inventory_layout")

local renderInventoryStats = {}

-- Utility function to snap values to nearest pixel
local function snap(value)
    return math.floor(value + 0.5)
end

-- Configuration for stat display order and formatting
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

---Build formatted stat summary lines from total stats
---@param total table Total stats object
---@return table Array of formatted stat strings
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

---Draw stats section with total stats
---@param scene table Inventory scene
function renderInventoryStats.draw(scene)
    local player = scene.world:getPlayer()
    if not player then
        return
    end

    -- Calculate layout
    local panelLayout = InventoryLayout.calculatePanelLayout()
    local headersLayout = InventoryLayout.calculateHeadersLayout(
        panelLayout.panelX,
        panelLayout.panelY,
        panelLayout.panelWidth
    )
    local equipmentLayout = InventoryLayout.calculateEquipmentLayout(
        panelLayout.panelX,
        panelLayout.panelHeight,
        headersLayout.headerY,
        headersLayout.dividerX,
        headersLayout.equipmentHeaderX
    )

    -- Draw divider line
    love.graphics.setColor(0.35, 0.32, 0.28, 1)
    local dividerLineEndX = equipmentLayout.equipmentAreaX + equipmentLayout.equipmentAreaWidth
    love.graphics.line(
        equipmentLayout.equipmentAreaX,
        equipmentLayout.statsDividerY,
        dividerLineEndX,
        equipmentLayout.statsDividerY
    )

    -- Draw header
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Stats", equipmentLayout.equipmentAreaX, equipmentLayout.statsHeaderY)

    -- Draw stat lines
    local totalStats = EquipmentHelper.computeTotalStats(player)
    local statLines = buildSummaryLines(totalStats)
    local statLineHeight = 18
    for idx, line in ipairs(statLines) do
        local statY = snap(equipmentLayout.statsStartY + (idx - 1) * statLineHeight)
        love.graphics.print(line, equipmentLayout.equipmentAreaX, statY)
    end
end

return renderInventoryStats
