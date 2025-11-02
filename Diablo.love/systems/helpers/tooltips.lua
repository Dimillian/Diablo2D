local Resources = require("modules.resources")

local Tooltips = {}

Tooltips.rarityColors = {
    common = { 0.9, 0.9, 0.9, 1 },
    uncommon = { 0.3, 0.85, 0.4, 1 },
    rare = { 0.35, 0.65, 1, 1 },
    epic = { 0.7, 0.4, 0.9, 1 },
    legendary = { 1, 0.65, 0.2, 1 },
}

local SPRITE_SIZE = 32

local function snap(value)
    return math.floor(value + 0.5)
end

function Tooltips.getRarityColor(rarity)
    return Tooltips.rarityColors[rarity] or Tooltips.rarityColors.common
end

local function formatPercent(value)
    return string.format("+%.1f%%", value * 100)
end

local function compareStat(hoveredValue, equippedValue)
    if not equippedValue or equippedValue == 0 then
        return nil -- No comparison
    end
    local diff = hoveredValue - equippedValue
    if diff == 0 then
        return 0 -- Same
    elseif diff > 0 then
        return diff -- Better
    else
        return diff -- Worse (negative)
    end
end

local function formatComparison(value, diff)
    if diff == nil then
        return string.format("%d", value)
    elseif diff == 0 then
        return string.format("%d", value)
    elseif diff > 0 then
        return string.format("%d (+%d)", value, diff)
    else
        return string.format("%d (%d)", value, diff)
    end
end

local function formatComparisonRange(min, max, diffMin, diffMax)
    if diffMin == nil and diffMax == nil then
        return string.format("%d - %d", min, max)
    elseif diffMin == 0 and diffMax == 0 then
        return string.format("%d - %d", min, max)
    elseif diffMin ~= nil and diffMax ~= nil then
        -- For damage ranges, show average difference
        local avgDiff = math.floor((diffMin + diffMax) / 2 + 0.5)
        if avgDiff > 0 then
            return string.format("%d - %d (+%d)", min, max, avgDiff)
        else
            return string.format("%d - %d (%d)", min, max, avgDiff)
        end
    else
        return string.format("%d - %d", min, max)
    end
end

local function getComparisonColor(diff, isNewStat)
    -- Green for new stats (not on equipped item)
    if isNewStat then
        return { 0.3, 0.85, 0.4, 1 }
    end

    if diff == nil or diff == 0 then
        return { 1, 1, 1, 1 } -- White for no comparison or same
    elseif diff > 0 then
        return { 0.3, 0.85, 0.4, 1 } -- Green for better
    else
        return { 0.85, 0.3, 0.3, 1 } -- Red for worse
    end
end

-- Helper to check if a stat exists on any equipped item
local function hasStatOnEquipped(getValue, equippedItems)
    for _, equippedItem in ipairs(equippedItems) do
        if equippedItem and equippedItem.stats then
            local value = getValue(equippedItem.stats)
            if value and value > 0 then
                return true
            end
        end
    end
    return false
end

-- Helper to get best value from equipped items
local function getBestEquippedValue(getValue, equippedItems)
    local bestValue = nil
    for _, equippedItem in ipairs(equippedItems) do
        if equippedItem and equippedItem.stats then
            local value = getValue(equippedItem.stats)
            if value and value > 0 then
                if bestValue == nil or value > bestValue then
                    bestValue = value
                end
            end
        end
    end
    return bestValue
end

function Tooltips.buildItemStatLines(item, equippedItems, isEquippedItem)
    if not item then
        return { { text = "Unknown item", color = { 1, 1, 1, 1 } } }
    end

    equippedItems = equippedItems or {}
    isEquippedItem = isEquippedItem or false
    local stats = item.stats or {}
    local lines = {}
    local defaultColor = { 1, 1, 1, 1 }
    local separatorColor = { 0.5, 0.5, 0.5, 0.5 } -- Gray separator

    -- If hovering equipped item, show all stats in white (no comparisons)
    if isEquippedItem then
        -- Damage range
        if stats.damageMin and stats.damageMax and (stats.damageMin > 0 or stats.damageMax > 0) then
            lines[#lines + 1] = {
                text = string.format("Damage: %d - %d", stats.damageMin, stats.damageMax),
                color = defaultColor
            }
        end

        -- Defense
        if stats.defense and stats.defense > 0 then
            lines[#lines + 1] = { text = string.format("Defense: %d", stats.defense), color = defaultColor }
        end

        -- Health
        if stats.health and stats.health > 0 then
            lines[#lines + 1] = { text = string.format("+%d Health", stats.health), color = defaultColor }
        end

        -- Percent-based stats
        if stats.critChance and stats.critChance > 0 then
            lines[#lines + 1] = { text = formatPercent(stats.critChance) .. " Crit Chance", color = defaultColor }
        end
        if stats.moveSpeed and stats.moveSpeed > 0 then
            lines[#lines + 1] = { text = formatPercent(stats.moveSpeed) .. " Move Speed", color = defaultColor }
        end
        if stats.dodgeChance and stats.dodgeChance > 0 then
            lines[#lines + 1] = { text = formatPercent(stats.dodgeChance) .. " Dodge Chance", color = defaultColor }
        end
        if stats.goldFind and stats.goldFind > 0 then
            lines[#lines + 1] = { text = formatPercent(stats.goldFind) .. " Gold Find", color = defaultColor }
        end
        if stats.lifeSteal and stats.lifeSteal > 0 then
            lines[#lines + 1] = { text = formatPercent(stats.lifeSteal) .. " Life Steal", color = defaultColor }
        end
        if stats.attackSpeed and stats.attackSpeed > 0 then
            lines[#lines + 1] = { text = formatPercent(stats.attackSpeed) .. " Attack Speed", color = defaultColor }
        end
        if stats.resistAll and stats.resistAll > 0 then
            lines[#lines + 1] = { text = formatPercent(stats.resistAll) .. " All Resist", color = defaultColor }
        end

        if #lines == 0 then
            lines[#lines + 1] = { text = "No bonuses", color = defaultColor }
        end

        return lines
    end

    -- Collect all stats from hovered item (gains/comparisons)
    local hasGains = false

    -- Damage range
    if stats.damageMin and stats.damageMax and (stats.damageMin > 0 or stats.damageMax > 0) then
        local hasEquipped = false
        local bestEquippedAvg = nil
        for _, equippedItem in ipairs(equippedItems) do
            if equippedItem and equippedItem.stats then
                local eqStats = equippedItem.stats
                if eqStats.damageMin and eqStats.damageMax then
                    hasEquipped = true
                    local equippedAvg = (eqStats.damageMin + eqStats.damageMax) / 2
                    if bestEquippedAvg == nil or equippedAvg > bestEquippedAvg then
                        bestEquippedAvg = equippedAvg
                    end
                end
            end
        end

        local avgDiff = nil
        if bestEquippedAvg then
            local hoveredAvg = (stats.damageMin + stats.damageMax) / 2
            avgDiff = hoveredAvg - bestEquippedAvg
        end

        local text = formatComparisonRange(stats.damageMin, stats.damageMax, avgDiff, avgDiff)
        local isNewStat = not hasEquipped
        local color = getComparisonColor(avgDiff, isNewStat)
        lines[#lines + 1] = { text = "Damage: " .. text, color = color }
        hasGains = true
    end

    -- Defense
    if stats.defense and stats.defense > 0 then
        local equippedValue = getBestEquippedValue(function(s) return s.defense end, equippedItems)
        local diff = equippedValue and compareStat(stats.defense, equippedValue) or nil
        local isNewStat = not hasStatOnEquipped(function(s) return s.defense end, equippedItems)
        local text = formatComparison(stats.defense, diff)
        local color = getComparisonColor(diff, isNewStat)
        lines[#lines + 1] = { text = "Defense: " .. text, color = color }
        hasGains = true
    end

    -- Health
    if stats.health and stats.health > 0 then
        local equippedValue = getBestEquippedValue(function(s) return s.health end, equippedItems)
        local diff = equippedValue and compareStat(stats.health, equippedValue) or nil
        local isNewStat = not hasStatOnEquipped(function(s) return s.health end, equippedItems)
        local text = formatComparison(stats.health, diff)
        local color = getComparisonColor(diff, isNewStat)
        lines[#lines + 1] = { text = "+" .. text .. " Health", color = color }
        hasGains = true
    end

    -- Percent-based stats
    local function addPercentStat(label, getValue)
        if getValue(stats) and getValue(stats) > 0 then
            local equippedValue = getBestEquippedValue(getValue, equippedItems)
            local diff = equippedValue and compareStat(getValue(stats), equippedValue) or nil
            local diffPercent = diff and (diff * 100) or nil
            local isNewStat = not hasStatOnEquipped(getValue, equippedItems)

            local text = formatPercent(getValue(stats)) .. " " .. label
            if diffPercent then
                if diffPercent > 0 then
                    text = text .. string.format(" (+%.1f%%)", diffPercent)
                elseif diffPercent < 0 then
                    text = text .. string.format(" (%.1f%%)", diffPercent)
                end
            end
            local color = getComparisonColor(diffPercent, isNewStat)
            lines[#lines + 1] = { text = text, color = color }
            hasGains = true
        end
    end

    addPercentStat("Crit Chance", function(s) return s.critChance end)
    addPercentStat("Move Speed", function(s) return s.moveSpeed end)
    addPercentStat("Dodge Chance", function(s) return s.dodgeChance end)
    addPercentStat("Gold Find", function(s) return s.goldFind end)
    addPercentStat("Life Steal", function(s) return s.lifeSteal end)
    addPercentStat("Attack Speed", function(s) return s.attackSpeed end)
    addPercentStat("All Resist", function(s) return s.resistAll end)

    -- Collect stats from equipped items that are NOT on hovered item (losses)
    -- Show the best loss for each stat type (highest value)
    local losses = {}
    local lossStats = {}

    -- Damage range loss
    if not (stats.damageMin and stats.damageMax) then
        local bestEquippedAvg = nil
        for _, equippedItem in ipairs(equippedItems) do
            if equippedItem and equippedItem.stats then
                local eqStats = equippedItem.stats
                if eqStats.damageMin and eqStats.damageMax then
                    local equippedAvg = (eqStats.damageMin + eqStats.damageMax) / 2
                    if bestEquippedAvg == nil or equippedAvg > bestEquippedAvg then
                        bestEquippedAvg = equippedAvg
                        lossStats.damage = { min = eqStats.damageMin, max = eqStats.damageMax }
                    end
                end
            end
        end
        if lossStats.damage then
            losses[#losses + 1] = {
                text = string.format("Damage: %d - %d", lossStats.damage.min, lossStats.damage.max),
                color = { 0.85, 0.3, 0.3, 1 }
            }
        end
    end

    -- Defense loss
    if not stats.defense or stats.defense == 0 then
        local bestValue = getBestEquippedValue(function(s) return s.defense end, equippedItems)
        if bestValue then
            losses[#losses + 1] = {
                text = string.format("Defense: %d", bestValue),
                color = { 0.85, 0.3, 0.3, 1 }
            }
        end
    end

    -- Health loss
    if not stats.health or stats.health == 0 then
        local bestValue = getBestEquippedValue(function(s) return s.health end, equippedItems)
        if bestValue then
            losses[#losses + 1] = {
                text = string.format("+%d Health", bestValue),
                color = { 0.85, 0.3, 0.3, 1 }
            }
        end
    end

    -- Percent stat losses
    local function checkPercentLoss(label, getValue)
        if not getValue(stats) or getValue(stats) == 0 then
            local bestValue = getBestEquippedValue(getValue, equippedItems)
            if bestValue then
                losses[#losses + 1] = {
                    text = formatPercent(bestValue) .. " " .. label,
                    color = { 0.85, 0.3, 0.3, 1 }
                }
            end
        end
    end

    checkPercentLoss("Crit Chance", function(s) return s.critChance end)
    checkPercentLoss("Move Speed", function(s) return s.moveSpeed end)
    checkPercentLoss("Dodge Chance", function(s) return s.dodgeChance end)
    checkPercentLoss("Gold Find", function(s) return s.goldFind end)
    checkPercentLoss("Life Steal", function(s) return s.lifeSteal end)
    checkPercentLoss("Attack Speed", function(s) return s.attackSpeed end)
    checkPercentLoss("All Resist", function(s) return s.resistAll end)

    -- Add separator if we have both gains and losses
    if hasGains and #losses > 0 then
        lines[#lines + 1] = { text = "---", color = separatorColor, isSeparator = true }
    end

    -- Add losses
    for _, loss in ipairs(losses) do
        lines[#lines + 1] = loss
    end

    if #lines == 0 then
        lines[#lines + 1] = { text = "No bonuses", color = defaultColor }
    end

    return lines
end

local function measureTooltip(font, item, padding, equippedItems, isEquippedItem)
    local lines = Tooltips.buildItemStatLines(item, equippedItems, isEquippedItem)
    local textWidth = font:getWidth(item.name or "Unknown Item")
    textWidth = math.max(textWidth, font:getWidth(item.rarityLabel or ""))

    for _, lineData in ipairs(lines) do
        local lineText = lineData.text or lineData
        textWidth = math.max(textWidth, font:getWidth(lineText))
    end

    -- Width = sprite + sprite padding + text + text padding
    local spritePadding = padding -- Space between sprite and text
    local width = SPRITE_SIZE + spritePadding + textWidth + padding * 2
    local lineHeight = font:getHeight()
    local height = math.max(SPRITE_SIZE + padding * 2, lineHeight * (#lines + 2) + padding * 3)

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
    local equippedItems = opts.equippedItems or {}
    local isEquippedItem = opts.isEquippedItem or false

    local width, height, lines, lineHeight = measureTooltip(font, item, padding, equippedItems, isEquippedItem)

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

    -- Draw inner glow gradient effect with rarity color
    local rarityColor = Tooltips.getRarityColor(item.rarity)
    local glowLayers = 8

    for i = 1, glowLayers do
        local offset = i * 0.8
        local alpha = (0.6 * (glowLayers - i + 1)) / glowLayers
        local glowColor = { rarityColor[1], rarityColor[2], rarityColor[3], alpha }
        love.graphics.setColor(glowColor)
        love.graphics.setLineWidth(1.5)
        love.graphics.rectangle("line", tooltipX + offset, tooltipY + offset,
                               width - offset * 2, height - offset * 2, 6 - offset * 0.4, 6 - offset * 0.4)
    end

    -- Draw main border with rarity color
    love.graphics.setColor(rarityColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", tooltipX, tooltipY, width, height, 6, 6)

    -- Draw sprite on the left side (vertically centered)
    local spritePadding = padding -- Space between sprite and text
    local spriteX = snap(tooltipX + padding)
    local spriteY = snap(tooltipY + height / 2 - SPRITE_SIZE / 2)

    if item.spritePath then
        local sprite = Resources.loadImageSafe(item.spritePath)
        if sprite then
            love.graphics.setColor(1, 1, 1, 1)
            local spriteScaleX = SPRITE_SIZE / sprite:getWidth()
            local spriteScaleY = SPRITE_SIZE / sprite:getHeight()
            love.graphics.draw(
                sprite,
                spriteX,
                spriteY,
                0,
                spriteScaleX,
                spriteScaleY
            )
        end
    end

    -- Draw text on the right side of the sprite
    local textX = snap(tooltipX + padding + SPRITE_SIZE + spritePadding)
    local titleY = snap(tooltipY + padding)

    love.graphics.setColor(rarityColor)
    love.graphics.print(item.name or "Unknown Item", textX, titleY)

    love.graphics.setColor(0.75, 0.75, 0.85, 1)
    love.graphics.print(item.rarityLabel or "", textX, snap(titleY + lineHeight))

    -- Draw stat lines with color coding
    for index, lineData in ipairs(lines) do
        local lineY = snap(titleY + lineHeight * (index + 1))

        -- Handle separator line
        if lineData.isSeparator then
            local separatorColor = lineData.color or { 0.5, 0.5, 0.5, 0.5 }
            love.graphics.setColor(separatorColor)
            local separatorY = lineY + lineHeight / 2
            -- Calculate text area width (full width minus padding on both sides)
            local textAreaWidth = width - padding * 2 - SPRITE_SIZE - spritePadding
            love.graphics.line(textX, separatorY, textX + textAreaWidth, separatorY)
        else
            local lineText = lineData.text or lineData
            local lineColor = lineData.color or { 1, 1, 1, 1 }
            love.graphics.setColor(lineColor)
            love.graphics.print(lineText, textX, lineY)
        end
    end

    love.graphics.pop()
end

return Tooltips
