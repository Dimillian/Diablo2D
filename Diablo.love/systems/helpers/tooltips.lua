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
local TITLE_SEPARATOR_MARGIN = 4
local TITLE_SEPARATOR_HEIGHT = 2
local SUBTITLE_BOTTOM_SPACING = 6
local SECTION_HEADER_TOP_PADDING = 6
local SECTION_HEADER_BOTTOM_PADDING = 2
local SECTION_DIVIDER_HEIGHT = 10

local SECTION_HEADER_COLOR = { 0.95, 0.9, 0.75, 1 }
local SECTION_DIVIDER_COLOR = { 0.35, 0.35, 0.45, 0.65 }

local SECTION_ORDER = {
    { key = "base", label = "Base Power" },
    { key = "defense", label = "Defense" },
    { key = "offense", label = "Offense" },
    { key = "utility", label = "Utility" },
    { key = "comparison", label = "Compared To Equipped" },
}

local STAT_CATEGORY_MAP = {
    damage = "base",
    defense = "base",
    health = "defense",
    critChance = "offense",
    moveSpeed = "utility",
    dodgeChance = "defense",
    goldFind = "utility",
    lifeSteal = "offense",
    attackSpeed = "offense",
    resistAll = "defense",
    manaRegen = "utility",
}

local fontCache = {}

local function getOrCreateFontLike(baseFont, size)
    size = math.max(8, math.floor(size + 0.5))
    if size <= 0 then
        return baseFont
    end

    local filename = baseFont.getFilename and baseFont:getFilename()
    if not filename then
        return baseFont
    end

    local cacheKey = filename .. ":" .. size
    if not fontCache[cacheKey] then
        fontCache[cacheKey] = love.graphics.newFont(filename, size)
    end

    return fontCache[cacheKey]
end

local function resolveTooltipFonts(bodyFont)
    local bodyHeight = bodyFont:getHeight()
    local titleSize = math.max(bodyHeight + 2, math.floor(bodyHeight * 1.18))
    local subtitleSize = math.max(bodyHeight + 1, math.floor(bodyHeight * 1.08))
    local sectionSize = math.max(bodyHeight, math.floor(bodyHeight * 1.02))

    return {
        body = bodyFont,
        title = getOrCreateFontLike(bodyFont, titleSize),
        subtitle = getOrCreateFontLike(bodyFont, subtitleSize),
        section = getOrCreateFontLike(bodyFont, sectionSize),
    }
end

local function drawText(font, text, x, y, color, isBold)
    love.graphics.setFont(font)
    love.graphics.setColor(color)
    love.graphics.print(text, x, y)
    if isBold then
        love.graphics.print(text, x + 1, y)
    end
end

local function sectionKeyForStat(statKey)
    return STAT_CATEGORY_MAP[statKey] or "utility"
end

local function addSectionLine(sectionLines, sectionKey, lineData)
    sectionKey = sectionKey or "utility"
    sectionLines[sectionKey] = sectionLines[sectionKey] or {}
    local bucket = sectionLines[sectionKey]
    bucket[#bucket + 1] = lineData
end

local function flattenSections(sectionLines, defaultColor)
    local flattened = {}
    local hasSections = false

    for _, section in ipairs(SECTION_ORDER) do
        local bucket = sectionLines[section.key]
        if bucket and #bucket > 0 then
            hasSections = true

            if #flattened > 0 then
                flattened[#flattened + 1] = {
                    isSeparator = true,
                    color = SECTION_DIVIDER_COLOR,
                }
            end

            flattened[#flattened + 1] = {
                text = section.label,
                color = SECTION_HEADER_COLOR,
                isSectionHeader = true,
            }

            for _, line in ipairs(bucket) do
                flattened[#flattened + 1] = line
            end
        end
    end

    if not hasSections then
        return {
            {
                text = SECTION_ORDER[1].label,
                color = SECTION_HEADER_COLOR,
                isSectionHeader = true,
            },
            {
                text = "No bonuses",
                color = defaultColor,
            },
        }
    end

    return flattened
end

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
    local defaultColor = { 1, 1, 1, 1 }
    local sectionLines = {}
    local compareValues = not isEquippedItem

    local function addLine(sectionKey, lineData)
        addSectionLine(sectionLines, sectionKey, lineData)
    end

    -- Damage range
    if stats.damageMin and stats.damageMax and (stats.damageMin > 0 or stats.damageMax > 0) then
        if compareValues then
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
            addLine("base", { text = "Damage: " .. text, color = color })
        else
            addLine("base", {
                text = string.format("Damage: %d - %d", stats.damageMin, stats.damageMax),
                color = defaultColor,
            })
        end
    end

    -- Defense
    if stats.defense and stats.defense > 0 then
        if compareValues then
            local equippedValue = getBestEquippedValue(function(s) return s.defense end, equippedItems)
            local diff = equippedValue and compareStat(stats.defense, equippedValue) or nil
            local isNewStat = not hasStatOnEquipped(function(s) return s.defense end, equippedItems)
            local text = formatComparison(stats.defense, diff)
            local color = getComparisonColor(diff, isNewStat)
            addLine("base", { text = "Defense: " .. text, color = color })
        else
            addLine("base", { text = string.format("Defense: %d", stats.defense), color = defaultColor })
        end
    end

    -- Health
    if stats.health and stats.health > 0 then
        if compareValues then
            local equippedValue = getBestEquippedValue(function(s) return s.health end, equippedItems)
            local diff = equippedValue and compareStat(stats.health, equippedValue) or nil
            local isNewStat = not hasStatOnEquipped(function(s) return s.health end, equippedItems)
            local text = formatComparison(stats.health, diff)
            local color = getComparisonColor(diff, isNewStat)
            addLine("defense", { text = "+" .. text .. " Health", color = color })
        else
            addLine("defense", { text = string.format("+%d Health", stats.health), color = defaultColor })
        end
    end

    -- Percent-based stats
    local function addPercentStat(label, statKey)
        local value = stats[statKey]
        if value and value > 0 then
            if compareValues then
                local getValue = function(s) return s[statKey] end
                local equippedValue = getBestEquippedValue(getValue, equippedItems)
                local diff = equippedValue and compareStat(value, equippedValue) or nil
                local diffPercent = diff and (diff * 100) or nil
                local isNewStat = not hasStatOnEquipped(getValue, equippedItems)
                local text = formatPercent(value) .. " " .. label
                if diffPercent then
                    if diffPercent > 0 then
                        text = text .. string.format(" (+%.1f%%)", diffPercent)
                    elseif diffPercent < 0 then
                        text = text .. string.format(" (%.1f%%)", diffPercent)
                    end
                end
                local color = getComparisonColor(diffPercent, isNewStat)
                addLine(sectionKeyForStat(statKey), { text = text, color = color })
            else
                addLine(
                    sectionKeyForStat(statKey),
                    { text = formatPercent(value) .. " " .. label, color = defaultColor }
                )
            end
        end
    end

    addPercentStat("Crit Chance", "critChance")
    addPercentStat("Move Speed", "moveSpeed")
    addPercentStat("Dodge Chance", "dodgeChance")
    addPercentStat("Gold Find", "goldFind")
    addPercentStat("Life Steal", "lifeSteal")
    addPercentStat("Attack Speed", "attackSpeed")
    addPercentStat("All Resist", "resistAll")

    if compareValues then
        -- Collect stats from equipped items that are NOT on hovered item (losses)
        -- Show the best loss for each stat type (highest value)
        local function addLoss(lineData)
            addLine("comparison", lineData)
        end

        -- Damage range loss
        if not (stats.damageMin and stats.damageMax and (stats.damageMin > 0 or stats.damageMax > 0)) then
            local bestEquippedAvg = nil
            local lossStats = {}
            for _, equippedItem in ipairs(equippedItems) do
                if equippedItem and equippedItem.stats then
                    local eqStats = equippedItem.stats
                    if eqStats.damageMin and eqStats.damageMax then
                        local equippedAvg = (eqStats.damageMin + eqStats.damageMax) / 2
                        if bestEquippedAvg == nil or equippedAvg > bestEquippedAvg then
                            bestEquippedAvg = equippedAvg
                            lossStats = { min = eqStats.damageMin, max = eqStats.damageMax }
                        end
                    end
                end
            end
            if lossStats.min and (lossStats.min > 0 or lossStats.max > 0) then
                addLoss({
                    text = string.format("Damage: %d - %d", lossStats.min, lossStats.max),
                    color = { 0.85, 0.3, 0.3, 1 },
                })
            end
        end

        -- Defense loss
        if not stats.defense or stats.defense == 0 then
            local bestValue = getBestEquippedValue(function(s) return s.defense end, equippedItems)
            if bestValue and bestValue > 0 then
                addLoss({
                    text = string.format("Defense: %d", bestValue),
                    color = { 0.85, 0.3, 0.3, 1 },
                })
            end
        end

        -- Health loss
        if not stats.health or stats.health == 0 then
            local bestValue = getBestEquippedValue(function(s) return s.health end, equippedItems)
            if bestValue and bestValue > 0 then
                addLoss({
                    text = string.format("+%d Health", bestValue),
                    color = { 0.85, 0.3, 0.3, 1 },
                })
            end
        end

        -- Percent stat losses
        local function checkPercentLoss(label, statKey)
            if not stats[statKey] or stats[statKey] == 0 then
                local getValue = function(s) return s[statKey] end
                local bestValue = getBestEquippedValue(getValue, equippedItems)
                if bestValue and bestValue > 0 then
                    addLoss({
                        text = formatPercent(bestValue) .. " " .. label,
                        color = { 0.85, 0.3, 0.3, 1 },
                    })
                end
            end
        end

        checkPercentLoss("Crit Chance", "critChance")
        checkPercentLoss("Move Speed", "moveSpeed")
        checkPercentLoss("Dodge Chance", "dodgeChance")
        checkPercentLoss("Gold Find", "goldFind")
        checkPercentLoss("Life Steal", "lifeSteal")
        checkPercentLoss("Attack Speed", "attackSpeed")
        checkPercentLoss("All Resist", "resistAll")
    end

    return flattenSections(sectionLines, defaultColor)
end

local function measureTooltip(fonts, item, padding, equippedItems, isEquippedItem)
    local lines = Tooltips.buildItemStatLines(item, equippedItems, isEquippedItem)
    local name = item.name or "Unknown Item"
    local rarityLabel = item.rarityLabel or ""

    local textWidth = math.max(
        fonts.title:getWidth(name),
        fonts.subtitle:getWidth(rarityLabel)
    )

    for _, lineData in ipairs(lines) do
        if not lineData.isSeparator then
            local lineText = lineData.text or ""
            if lineData.isSectionHeader then
                textWidth = math.max(textWidth, fonts.section:getWidth(lineText))
            else
                textWidth = math.max(textWidth, fonts.body:getWidth(lineText))
            end
        end
    end

    local spritePadding = padding
    local width = SPRITE_SIZE + spritePadding + textWidth + padding * 2

    local contentHeight = fonts.title:getHeight()
    contentHeight = contentHeight + TITLE_SEPARATOR_MARGIN + TITLE_SEPARATOR_HEIGHT + TITLE_SEPARATOR_MARGIN
    contentHeight = contentHeight + fonts.subtitle:getHeight() + SUBTITLE_BOTTOM_SPACING

    local previousWasSeparator = true
    for _, lineData in ipairs(lines) do
        if lineData.isSeparator then
            contentHeight = contentHeight + SECTION_DIVIDER_HEIGHT
            previousWasSeparator = true
        elseif lineData.isSectionHeader then
            if not previousWasSeparator then
                contentHeight = contentHeight + SECTION_HEADER_TOP_PADDING
            end
            contentHeight = contentHeight + fonts.section:getHeight() + SECTION_HEADER_BOTTOM_PADDING
            previousWasSeparator = false
        else
            contentHeight = contentHeight + fonts.body:getHeight()
            previousWasSeparator = false
        end
    end

    local height = math.max(SPRITE_SIZE + padding * 2, contentHeight + padding * 2)
    return snap(width), snap(height), lines
end

function Tooltips.drawItemTooltip(item, pointerX, pointerY, opts)
    if not item then
        return
    end

    opts = opts or {}

    local font = opts.font or love.graphics.getFont()
    local fonts = resolveTooltipFonts(font)
    local padding = opts.padding or 10
    local offsetX = opts.offsetX or 16
    local offsetY = opts.offsetY or 16
    local clampToScreen = opts.clamp ~= false
    local equippedItems = opts.equippedItems or {}
    local isEquippedItem = opts.isEquippedItem or false

    local width, height, lines = measureTooltip(fonts, item, padding, equippedItems, isEquippedItem)

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
    local textAreaWidth = width - padding * 2 - SPRITE_SIZE - spritePadding
    local currentY = snap(tooltipY + padding)
    local defaultTextColor = { 1, 1, 1, 1 }

    drawText(fonts.title, item.name or "Unknown Item", textX, currentY, rarityColor, true)

    currentY = currentY + fonts.title:getHeight() + TITLE_SEPARATOR_MARGIN

    love.graphics.setColor(rarityColor[1], rarityColor[2], rarityColor[3], 0.65)
    love.graphics.rectangle("fill", textX, currentY, textAreaWidth, TITLE_SEPARATOR_HEIGHT)

    currentY = currentY + TITLE_SEPARATOR_HEIGHT + TITLE_SEPARATOR_MARGIN

    drawText(fonts.subtitle, item.rarityLabel or "", textX, currentY, { 0.75, 0.75, 0.85, 1 }, true)

    currentY = currentY + fonts.subtitle:getHeight() + SUBTITLE_BOTTOM_SPACING

    -- Draw stat lines with color coding
    local previousWasSeparator = true
    for _, lineData in ipairs(lines) do
        if lineData.isSeparator then
            local separatorColor = lineData.color or SECTION_DIVIDER_COLOR
            love.graphics.setColor(separatorColor)
            local separatorY = currentY + SECTION_DIVIDER_HEIGHT / 2
            love.graphics.setLineWidth(1)
            love.graphics.line(textX, separatorY, textX + textAreaWidth, separatorY)
            currentY = currentY + SECTION_DIVIDER_HEIGHT
            previousWasSeparator = true
        elseif lineData.isSectionHeader then
            if not previousWasSeparator then
                currentY = currentY + SECTION_HEADER_TOP_PADDING
            end
            love.graphics.setFont(fonts.section)
            love.graphics.setColor(lineData.color or SECTION_HEADER_COLOR)
            love.graphics.print(lineData.text or "", textX, currentY)
            currentY = currentY + fonts.section:getHeight() + SECTION_HEADER_BOTTOM_PADDING
            love.graphics.setFont(fonts.body)
            previousWasSeparator = false
        else
            local lineText = lineData.text or lineData
            local lineColor = lineData.color or defaultTextColor
            love.graphics.setFont(fonts.body)
            love.graphics.setColor(lineColor)
            love.graphics.print(lineText, textX, currentY)
            currentY = currentY + fonts.body:getHeight()
            previousWasSeparator = false
        end
    end

    love.graphics.pop()
end

---Build tooltip lines for an attribute showing how it affects stats
---@param attributeKey string The attribute key (strength, dexterity, vitality, intelligence)
---@param attributeValue number The current attribute value
---@return table lines Array of { text, color } tables
function Tooltips.buildAttributeTooltipLines(attributeKey, attributeValue)
    local lines = {}
    local highlightColor = { 0.3, 0.85, 0.4, 1 } -- Green for derived stats
    local infoColor = { 0.7, 0.7, 0.7, 1 } -- Gray for formula info

    attributeValue = attributeValue or 0

    if attributeKey == "strength" then
        local damage = attributeValue * 0.2
        lines[#lines + 1] = { text = string.format("Damage: %.1f", damage), color = highlightColor }
        lines[#lines + 1] = { text = "5 Strength = +1 Damage", color = infoColor }
    elseif attributeKey == "dexterity" then
        local critChance = attributeValue * 0.0002
        lines[#lines + 1] = { text = string.format("Crit Chance: %.2f%%", critChance * 100), color = highlightColor }
        lines[#lines + 1] = { text = "5 Dexterity = +0.1% Crit", color = infoColor }
    elseif attributeKey == "vitality" then
        lines[#lines + 1] = { text = string.format("Health: %d", attributeValue), color = highlightColor }
        lines[#lines + 1] = { text = "1 Vitality = +1 Health", color = infoColor }
    elseif attributeKey == "intelligence" then
        lines[#lines + 1] = { text = string.format("Mana: %d", attributeValue), color = highlightColor }
        lines[#lines + 1] = { text = "1 Intelligence = +1 Mana", color = infoColor }
    end

    return lines
end

---Draw a simple text tooltip (no sprite, no rarity border)
---@param title string Tooltip title
---@param lines table Array of { text, color } tables
---@param pointerX number Mouse X position
---@param pointerY number Mouse Y position
---@param opts table|nil Options { font, padding, offsetX, offsetY, clamp }
function Tooltips.drawSimpleTooltip(title, lines, pointerX, pointerY, opts)
    if not title or not lines then
        return
    end

    opts = opts or {}
    local font = opts.font or love.graphics.getFont()
    local padding = opts.padding or 10
    local offsetX = opts.offsetX or 16
    local offsetY = opts.offsetY or 16
    local clampToScreen = opts.clamp ~= false

    -- Calculate width
    local textWidth = font:getWidth(title)
    for _, lineData in ipairs(lines) do
        local lineText = lineData.text or lineData
        textWidth = math.max(textWidth, font:getWidth(lineText))
    end

    local width = textWidth + padding * 2
    local lineHeight = font:getHeight()
    local height = lineHeight * (#lines + 1) + padding * 3

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

    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", tooltipX, tooltipY, width, height, 6, 6)

    -- Draw border
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", tooltipX, tooltipY, width, height, 6, 6)

    -- Draw title
    local titleY = snap(tooltipY + padding)
    love.graphics.setColor(0.95, 0.9, 0.7, 1)
    love.graphics.print(title, tooltipX + padding, titleY)

    -- Draw lines
    for index, lineData in ipairs(lines) do
        local lineY = snap(titleY + lineHeight * (index + 1))
        local lineText = lineData.text or lineData
        local lineColor = lineData.color or { 1, 1, 1, 1 }
        love.graphics.setColor(lineColor)
        love.graphics.print(lineText, tooltipX + padding, lineY)
    end

    love.graphics.pop()
end

return Tooltips
