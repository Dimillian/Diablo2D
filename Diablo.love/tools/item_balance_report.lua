local scriptDir = debug.getinfo(1, "S").source:sub(2):match("(.*/)") or "./"
local repoRoot = scriptDir .. ".."

package.path = table.concat({
    package.path,
    repoRoot .. "/?.lua",
    repoRoot .. "/?/init.lua",
}, ";")

local ItemsData = require("data.items")
local ItemGenerator = require("items.generator")
local FoeRarities = require("data.foe_rarities")

math.randomseed(os.time())

local SAMPLE_COUNT = tonumber(arg and arg[1]) or 10000
local DROP_SAMPLE_COUNT = tonumber(arg and arg[2]) or SAMPLE_COUNT
local FOE_TIER = tonumber(arg and arg[3]) or 1
FOE_TIER = math.max(1, math.floor(FOE_TIER))
local rarityArg = (arg and arg[4]) or "common,elite,boss"
local ITEM_DROP_CHANCE = 0.7
local rarityOrder = { "common", "uncommon", "rare", "epic", "legendary" }
local trackedStats = {
    "damageMin",
    "damageMax",
    "defense",
    "health",
    "critChance",
    "attackSpeed",
    "lifeSteal",
    "resistAll",
    "dodgeChance",
}

local STAT_CAPS = {
    critChance = 0.5,
    dodgeChance = 0.6,
    lifeSteal = 0.35,
    attackSpeed = 0.6,
    resistAll = 0.75,
}

local function ensureResultTable()
    return {
        sums = {},
        max = {},
        capHits = {},
        prefixFreq = {},
        suffixFreq = {},
    }
end

local function accumulateStat(result, statKey, value)
    result.sums[statKey] = (result.sums[statKey] or 0) + value
    if not result.max[statKey] or value > result.max[statKey] then
        result.max[statKey] = value
    end

    local cap = STAT_CAPS[statKey]
    if cap and value >= cap - 1e-5 then
        result.capHits[statKey] = (result.capHits[statKey] or 0) + 1
    end
end

local function bumpFrequency(map, name)
    if not name then
        return
    end
    map[name] = (map[name] or 0) + 1
end

local function sortFrequencies(freqMap)
    local items = {}
    for name, count in pairs(freqMap) do
        items[#items + 1] = { name = name, count = count }
    end
    table.sort(items, function(a, b)
        if a.count == b.count then
            return a.name < b.name
        end
        return a.count > b.count
    end)
    return items
end

-- luacheck: ignore 212/totalSamples
local function formatStat(statKey, average, maximum, capHits, totalSamples)
    if statKey == "damageMin" or statKey == "damageMax" or statKey == "defense" or statKey == "health" then
        return string.format("%.1f (max %.1f)", average, maximum or 0)
    end

    local capHitsText = capHits > 0 and string.format(", %d hits cap", capHits) or ""
    return string.format("%.2f (max %.2f%s)", average, maximum or 0, capHitsText)
end

local resultsByRarity = {}

local function increment(map, key)
    map[key] = (map[key] or 0) + 1
end

local function splitList(input)
    local list = {}
    if not input or input == "" then
        return list
    end

    for entry in string.gmatch(input, "[^,]+") do
        list[#list + 1] = entry
    end

    return list
end

for _, rarityId in ipairs(rarityOrder) do
    local rarity = ItemsData.rarities[rarityId]
    if rarity then
        local result = ensureResultTable()

        for _ = 1, SAMPLE_COUNT do
            local item = ItemGenerator.generate({ rarity = rarity, foeTier = FOE_TIER })
            local stats = item.stats or {}

            for _, statKey in ipairs(trackedStats) do
                accumulateStat(result, statKey, stats[statKey] or 0)
            end

            for _, prefix in ipairs(item.affixes.prefixes or {}) do
                bumpFrequency(result.prefixFreq, prefix.name)
            end

            for _, suffix in ipairs(item.affixes.suffixes or {}) do
                bumpFrequency(result.suffixFreq, suffix.name)
            end
        end

        resultsByRarity[rarityId] = result
    end
end

local dropRarityCount = {}
local dropSlotCount = {}
local dropSimulations = {}

for _ = 1, DROP_SAMPLE_COUNT do
    local item = ItemGenerator.generate({ foeTier = FOE_TIER })
    increment(dropRarityCount, item.rarity)
    increment(dropSlotCount, item.slot or "unknown")
end

local function simulateDropsForFoeRarity(foeRarityId)
    local rarity = FoeRarities.getById(foeRarityId)
    local dropChance = math.min(1, ITEM_DROP_CHANCE * (rarity.itemDropChanceMultiplier or 1))
    local range = rarity.itemDropCount or { min = 1, max = 1 }
    local minCount = math.max(1, range.min or 1)
    local maxCount = math.max(minCount, range.max or minCount)

    local result = {
        rarityId = rarity.id,
        rarityLabel = rarity.label,
        attempts = DROP_SAMPLE_COUNT,
        successful = 0,
        items = 0,
        itemRarityCounts = {},
    }

    for _ = 1, DROP_SAMPLE_COUNT do
        if math.random() < dropChance then
            result.successful = result.successful + 1
            local count = math.random(minCount, maxCount)
            for _ = 1, count do
                local item = ItemGenerator.generate({ foeTier = FOE_TIER })
                increment(result.itemRarityCounts, item.rarity)
                result.items = result.items + 1
            end
        end
    end

    return result
end

for _, foeRarityId in ipairs(splitList(rarityArg)) do
    local trimmed = foeRarityId:gsub("%s+", "")
    if trimmed ~= "" then
        dropSimulations[#dropSimulations + 1] = simulateDropsForFoeRarity(trimmed)
    end
end

local function printHeader()
    print(string.format("Tier sampled: %d", FOE_TIER))
    print(string.rep("=", 60))
    print("Item Balance Monte Carlo Report")
    print(string.format("Samples per rarity: %d", SAMPLE_COUNT))
    print(string.format("Random drop samples: %d", DROP_SAMPLE_COUNT))
    print(string.rep("=", 60))
end

local function printRaritySummary(rarityId, rarity, result)
    local prefixList = sortFrequencies(result.prefixFreq)
    local suffixList = sortFrequencies(result.suffixFreq)
    local totalSamples = SAMPLE_COUNT

    print("")
    print(string.format("%s (%s)", rarity.label, rarityId))
    print(string.rep("-", 40))

    for _, statKey in ipairs(trackedStats) do
        local sum = result.sums[statKey] or 0
        local average = sum / totalSamples
        local maximum = result.max[statKey] or 0
        local capHits = result.capHits[statKey] or 0
        print(string.format("  %-12s %s", statKey, formatStat(statKey, average, maximum, capHits, totalSamples)))
    end

    local function printAffixList(label, list)
        print(string.format("  %s:", label))
        local limit = math.min(#list, 5)
        if limit == 0 then
            print("    (none)")
            return
        end
        for index = 1, limit do
            local entry = list[index]
            print(string.format("    %-2d %-20s %6.2f%%", index, entry.name, (entry.count / totalSamples) * 100))
        end
    end

    printAffixList("Top Prefixes", prefixList)
    printAffixList("Top Suffixes", suffixList)
end

local function formatPercent(count, total)
    if total == 0 then
        return "0.00%"
    end
    return string.format("%.2f%%", (count / total) * 100)
end

printHeader()
for _, rarityId in ipairs(rarityOrder) do
    local rarity = ItemsData.rarities[rarityId]
    local result = resultsByRarity[rarityId]
    if rarity and result then
        printRaritySummary(rarityId, rarity, result)
    end
end

print("")
print("Overall Drop Distribution")
print(string.rep("-", 40))
print("Rarity spread:")
for _, rarityId in ipairs(rarityOrder) do
    local count = dropRarityCount[rarityId] or 0
    local label = ItemsData.rarities[rarityId] and ItemsData.rarities[rarityId].label or rarityId
    print(string.format("  %-10s %s", label, formatPercent(count, DROP_SAMPLE_COUNT)))
end

print("Slot spread:")
local slotEntries = {}
for slot, count in pairs(dropSlotCount) do
    slotEntries[#slotEntries + 1] = { slot = slot, count = count }
end
table.sort(slotEntries, function(a, b)
    if a.count == b.count then
        return a.slot < b.slot
    end
    return a.count > b.count
end)
for _, entry in ipairs(slotEntries) do
    print(string.format("  %-10s %s", entry.slot, formatPercent(entry.count, DROP_SAMPLE_COUNT)))
end

if #dropSimulations > 0 then
    print("")
    print("Drop Simulation by Foe Rarity")
    print(string.rep("-", 40))
    for _, sim in ipairs(dropSimulations) do
        local avgItems = sim.attempts > 0 and (sim.items / sim.attempts) or 0
        local successRate = formatPercent(sim.successful, sim.attempts)
        print(string.format(
            "%s (%s): success %s, avg items/kill %.2f",
            sim.rarityLabel,
            sim.rarityId,
            successRate,
            avgItems
        ))
        print("  Item rarity split:")
        for _, rarityId in ipairs(rarityOrder) do
            local count = sim.itemRarityCounts[rarityId] or 0
            print(string.format("    %-10s %s", rarityId, formatPercent(count, sim.items)))
        end
    end
end
