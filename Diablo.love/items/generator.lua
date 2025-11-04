local ItemData = require("data.items")

local ItemGenerator = {}

local idCounter = 0

-- Map item types to sprite folder names and sprite file prefixes
local spriteFolders = {
    sword = { folder = "weapons/sword", prefix = "sword" },
    axe = { folder = "weapons/axe", prefix = "axe" },
    hammer = { folder = "weapons/mace", prefix = "mace" },
    dagger = { folder = "weapons/dagger", prefix = "dagger" },
    helmet = { folder = "armor/helmet", prefix = "helmet" },
    chest = { folder = "armor/torso", prefix = "torso" },
    boots = { folder = "armor/feet", prefix = "feet" },
    gloves = { folder = "armor/gauntlet", prefix = "gauntlet" },
    ring = { folder = "armor/ring", prefix = "ring" },
    amulet = { folder = "armor/amulet", prefix = "amulet" },
}

-- Map rarity IDs to icon number ranges (2 icons per tier)
local rarityIconRanges = {
    common = { min = 1, max = 2 },
    uncommon = { min = 3, max = 4 },
    rare = { min = 5, max = 6 },
    epic = { min = 7, max = 8 },
    legendary = { min = 9, max = 10 },
}

local function selectRandomSprite(itemTypeId, rarity)
    local folderInfo = spriteFolders[itemTypeId]
    if not folderInfo then
        return nil
    end

    -- Rings and amulets use full sprite sets regardless of rarity
    if itemTypeId == "ring" then
        local spriteNumber = math.random(1, 40)
        local spritePath = string.format("resources/%s/%s_%d.png", folderInfo.folder, folderInfo.prefix, spriteNumber)
        return spritePath
    elseif itemTypeId == "amulet" then
        local spriteNumber = math.random(1, 60)
        local spritePath = string.format("resources/%s/%s_%d.png", folderInfo.folder, folderInfo.prefix, spriteNumber)
        return spritePath
    end

    -- For other items, use rarity-based icon ranges
    local iconRange = rarityIconRanges[rarity.id]
    if not iconRange then
        -- Fallback to common if rarity not found
        iconRange = rarityIconRanges.common
    end

    -- Randomly select one icon from the two available for this tier
    local spriteNumber = math.random(iconRange.min, iconRange.max)
    local spritePath = string.format("resources/%s/%s_%d.png", folderInfo.folder, folderInfo.prefix, spriteNumber)
    return spritePath
end

local function nextId()
    idCounter = idCounter + 1
    return "item_" .. idCounter
end

local function toArray(map, filterFn)
    local list = {}
    for _, value in pairs(map) do
        if not filterFn or filterFn(value) then
            list[#list + 1] = value
        end
    end
    return list
end

local rarityPool = toArray(ItemData.rarities)
local typePool = toArray(ItemData.types, function(entry)
    return not entry.excludeFromRandom
end)

local function chooseWeighted(entries)
    local total = 0
    for _, entry in ipairs(entries) do
        total = total + entry.weight
    end

    local roll = math.random() * total
    local acc = 0

    for _, entry in ipairs(entries) do
        acc = acc + entry.weight
        if roll <= acc then
            return entry
        end
    end

    return entries[#entries]
end

local function chooseRandom(list)
    if #list == 0 then
        return nil
    end
    local index = math.random(1, #list)
    return list[index], index
end

local function takeRandom(list)
    if #list == 0 then
        return nil
    end
    local index = math.random(1, #list)
    local value = list[index]
    table.remove(list, index)
    return value
end

local function createBaseStats(itemType, rarity)
    local stats = {
        damageMin = 0,
        damageMax = 0,
        defense = 0,
        critChance = 0,
        moveSpeed = 0,
        health = 0,
        dodgeChance = 0,
        goldFind = 0,
        lifeSteal = 0,
        attackSpeed = 0,
        resistAll = 0,
    }

    local baseDamage = itemType.base.damage
    if baseDamage then
        local function rollDamage()
            local minVal = baseDamage.min or baseDamage[1] or 0
            local maxVal = baseDamage.max or baseDamage[2] or minVal
            if minVal >= maxVal then
                return minVal
            end
            return math.random(minVal, maxVal)
        end

        local rolledMin = rollDamage()
        local rolledMax = rollDamage()
        if rolledMax < rolledMin then
            rolledMin, rolledMax = rolledMax, rolledMin
        end
        stats.damageMin = rolledMin
        stats.damageMax = rolledMax
    end

    local baseDefense = itemType.base.defense
    if baseDefense then
        if type(baseDefense) == "table" then
            local minVal = baseDefense.min or baseDefense[1] or 0
            local maxVal = baseDefense.max or baseDefense[2] or minVal
            if minVal >= maxVal then
                stats.defense = minVal
            else
                stats.defense = math.random(minVal, maxVal)
            end
        else
            stats.defense = baseDefense
        end
    end

    if itemType.base.critChance then
        stats.critChance = itemType.base.critChance
    end

    if itemType.base.moveSpeed then
        stats.moveSpeed = itemType.base.moveSpeed
    end

    local multiplier = rarity.baseStatMultiplier or 1
    stats.damageMin = stats.damageMin * multiplier
    stats.damageMax = stats.damageMax * multiplier
    stats.defense = stats.defense * multiplier

    return stats
end

local function applyFlat(stats, key, value)
    stats[key] = (stats[key] or 0) + value
end

local function applyPercent(stats, key, value)
    if key == "damage" then
        stats.damageMin = stats.damageMin * (1 + value)
        stats.damageMax = stats.damageMax * (1 + value)
        return
    end

    if key == "defense" then
        stats.defense = stats.defense * (1 + value)
        return
    end

    stats[key] = (stats[key] or 0) + value
end

local function rollRange(range)
    if not range then
        return 0
    end
    local min, max = range[1], range[2]
    if not min or not max then
        return min or max or 0
    end
    return min + math.random() * (max - min)
end

local function applyStats(stats, definition)
    for key, modifiers in pairs(definition.stats) do
        if key == "damage" then
            if modifiers.flat then
                local value = rollRange(modifiers.flat)
                stats.damageMin = stats.damageMin + value
                stats.damageMax = stats.damageMax + value
            end
            if modifiers.percent then
                local value = rollRange(modifiers.percent)
                stats.damageMin = stats.damageMin * (1 + value)
                stats.damageMax = stats.damageMax * (1 + value)
            end
        else
            if modifiers.flat then
                applyFlat(stats, key, rollRange(modifiers.flat))
            end
            if modifiers.percent then
                applyPercent(stats, key, rollRange(modifiers.percent))
            end
        end
    end
end

local function round(value)
    return math.floor(value + 0.5)
end

local MAX_STAT_CAPS = {
    critChance = 0.5,
    dodgeChance = 0.6,
    lifeSteal = 0.35,
    attackSpeed = 0.6,
    resistAll = 0.75,
}

local function capStat(stats, key)
    local cap = MAX_STAT_CAPS[key]
    if not cap then
        return
    end

    if stats[key] > cap then
        stats[key] = cap
    end
end

local function finalizeStats(stats)
    stats.damageMin = round(stats.damageMin)
    stats.damageMax = round(stats.damageMax)
    stats.defense = round(stats.defense)
    stats.health = round(stats.health)

    stats.critChance = math.max(0, stats.critChance)
    stats.moveSpeed = math.max(0, stats.moveSpeed)
    stats.dodgeChance = math.max(0, stats.dodgeChance)
    stats.goldFind = math.max(0, stats.goldFind)
    stats.lifeSteal = math.max(0, stats.lifeSteal)
    stats.attackSpeed = math.max(0, stats.attackSpeed)
    stats.resistAll = math.max(0, stats.resistAll)
    stats.manaRegen = math.max(0, stats.manaRegen or 0)

    capStat(stats, "critChance")
    capStat(stats, "dodgeChance")
    capStat(stats, "lifeSteal")
    capStat(stats, "attackSpeed")
    capStat(stats, "resistAll")

    return stats
end

function ItemGenerator.randomRarity()
    return chooseWeighted(rarityPool)
end

function ItemGenerator.randomItemType()
    return chooseRandom(typePool)
end

local function appliesToSlot(entry, slot)
    local slots = entry.slots
    if not slots or slot == nil then
        return true
    end

    for _, allowed in ipairs(slots) do
        if allowed == slot then
            return true
        end
    end

    return false
end

-- Rarity tier order for comparison
local rarityTiers = {
    common = 1,
    uncommon = 2,
    rare = 3,
    epic = 4,
    legendary = 5,
}

local function meetsRarityRequirement(affix, rarityId)
    -- Check minRarity requirement
    if affix.minRarity then
        local affixTier = rarityTiers[affix.minRarity]
        local itemTier = rarityTiers[rarityId]
        if affixTier and itemTier and itemTier < affixTier then
            return false -- Item rarity is too low
        end
    end

    -- Check maxRarity requirement
    if affix.maxRarity then
        local affixTier = rarityTiers[affix.maxRarity]
        local itemTier = rarityTiers[rarityId]
        if affixTier and itemTier and itemTier > affixTier then
            return false -- Item rarity is too high
        end
    end

    return true
end

local function rollAffixes(pool, count, slot, rarityId)
    local available = {}
    for _, entry in ipairs(pool) do
        if appliesToSlot(entry, slot) and meetsRarityRequirement(entry, rarityId) then
            available[#available + 1] = entry
        end
    end

    local affixes = {}
    if count <= 0 then
        return affixes
    end

    local allowDuplicates = #available < count

    local function weightedTake(list)
        local totalWeight = 0
        for _, entry in ipairs(list) do
            totalWeight = totalWeight + (entry.weight or 1)
        end

        if totalWeight <= 0 then
            return nil, nil
        end

        local roll = math.random() * totalWeight
        local acc = 0

        for index, entry in ipairs(list) do
            acc = acc + (entry.weight or 1)
            if roll <= acc then
                return entry, index
            end
        end

        local lastIndex = #list
        return list[lastIndex], lastIndex
    end

    while #affixes < count do
        if #available == 0 then
            break
        end

        local affix, index = weightedTake(available)
        if not affix then
            break
        end

        affixes[#affixes + 1] = affix

        if allowDuplicates then
            goto continue
        end

        table.remove(available, index)

        ::continue::
    end

    if allowDuplicates and #affixes < count and #available > 0 then
        while #affixes < count do
            local affix = available[math.random(1, #available)]
            affixes[#affixes + 1] = affix
        end
    end

    return affixes
end

local function buildName(baseLabel, prefixes, suffixes)
    local name = baseLabel

    if #prefixes > 0 then
        local prefixNames = {}
        for _, prefix in ipairs(prefixes) do
            prefixNames[#prefixNames + 1] = prefix.name
        end
        name = table.concat(prefixNames, " ") .. " " .. name
    end

    if #suffixes > 0 then
        local suffixNames = {}
        for _, suffix in ipairs(suffixes) do
            suffixNames[#suffixNames + 1] = suffix.name
        end
        name = name .. " " .. table.concat(suffixNames, " ")
    end

    return name
end

local function serializeAffixList(list)
    local serialized = {}
    for _, entry in ipairs(list) do
        serialized[#serialized + 1] = {
            name = entry.name,
            stats = entry.stats,
        }
    end
    return serialized
end

function ItemGenerator.generate(opts)
    opts = opts or {}

    local rarity = opts.rarity or ItemGenerator.randomRarity()
    local itemType = opts.itemType or ItemGenerator.randomItemType()

    -- Common rings and amulets get 1 random prefix instead of 0
    local prefixCount = rarity.prefixCount
    if rarity.id == "common" and (itemType.slot == "ring" or itemType.slot == "amulet") then
        prefixCount = 1
    end

    local prefixes = rollAffixes(ItemData.prefixes, prefixCount, itemType.slot, rarity.id)
    local suffixes = rollAffixes(ItemData.suffixes, rarity.suffixCount, itemType.slot, rarity.id)

    local stats = createBaseStats(itemType, rarity)
    for _, prefix in ipairs(prefixes) do
        applyStats(stats, prefix)
    end

    for _, suffix in ipairs(suffixes) do
        applyStats(stats, suffix)
    end

    finalizeStats(stats)

    local spritePath = selectRandomSprite(itemType.id, rarity)

    local item = {
        id = nextId(),
        name = buildName(itemType.label, prefixes, suffixes),
        type = itemType.id,
        slot = itemType.slot,
        rarity = rarity.id,
        rarityLabel = rarity.label,
        stats = stats,
        spritePath = spritePath,
        affixes = {
            prefixes = serializeAffixList(prefixes),
            suffixes = serializeAffixList(suffixes),
        },
    }

    -- Add source tag if provided (e.g., "starter" for filtering later)
    if opts.source then
        item.source = opts.source
    end

    return item
end

---Roll an item with optional rarity and type overrides.
---Supports weighted defaults for normal drops, or forced options for special cases.
---@param opts table|nil Optional parameters:
---   - rarity: String rarity ID (e.g., "common") or ItemData.rarities entry
---   - itemType: String type ID (e.g., "sword") or ItemData.types entry
---   - allowedTypes: Array of string type IDs (e.g., {"sword", "axe"}) or entries
---   - source: String tag (e.g., "starter") for filtering/labeling purposes
---@return table Generated item payload
function ItemGenerator.roll(opts)
    opts = opts or {}

    -- Resolve rarity: if string, look up in ItemData.rarities
    local rarity = opts.rarity
    if type(rarity) == "string" and ItemData.rarities[rarity] then
        rarity = ItemData.rarities[rarity]
    end

    -- Resolve itemType: handle allowedTypes (array of strings or entries) or single itemType
    local itemType = opts.itemType
    if opts.allowedTypes and #opts.allowedTypes > 0 then
        -- Randomly select from allowedTypes
        local selected = chooseRandom(opts.allowedTypes)
        -- If it's a string, look it up; otherwise use the entry directly
        if type(selected) == "string" and ItemData.types[selected] then
            itemType = ItemData.types[selected]
        else
            itemType = selected
        end
    elseif type(itemType) == "string" and ItemData.types[itemType] then
        -- Single itemType provided as string, look it up
        itemType = ItemData.types[itemType]
    end

    -- Build generate options
    local generateOpts = {
        rarity = rarity,
        itemType = itemType,
        source = opts.source,
    }

    return ItemGenerator.generate(generateOpts)
end

return ItemGenerator
