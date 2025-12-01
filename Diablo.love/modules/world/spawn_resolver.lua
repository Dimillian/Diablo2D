local biomes = require("data.biomes")
local foeTypes = require("data.foe_types")
local foeRarity = require("modules.world.foe_rarity")
local BossNameGenerator = require("modules.world.boss_name_generator")

local SpawnResolver = {}
SpawnResolver.__index = SpawnResolver

local function weightedChoice(rng, weights)
    if not weights or #weights == 0 then
        return nil
    end

    local total = 0
    for _, entry in ipairs(weights) do
        total = total + (entry.weight or 0)
    end

    if total <= 0 then
        return weights[1].id
    end

    local roll = rng:random() * total
    local cumulative = 0

    for _, entry in ipairs(weights) do
        cumulative = cumulative + (entry.weight or 0)
        if roll <= cumulative then
            return entry.id
        end
    end

    return weights[#weights].id
end

local function randomInChunk(rng, chunkX, chunkY, chunkSize, padding)
    padding = padding or 0
    local minX = chunkX * chunkSize + padding
    local minY = chunkY * chunkSize + padding
    local maxX = (chunkX + 1) * chunkSize - padding
    local maxY = (chunkY + 1) * chunkSize - padding

    return rng:random(minX, maxX), rng:random(minY, maxY)
end

function SpawnResolver.new(opts)
    opts = opts or {}
    local resolver = {
        chunkSize = opts.chunkSize,
        foeChunkSpawnChance = opts.foeChunkSpawnChance or 0.45,
        groupsPerChunk = opts.groupsPerChunk or { min = 0, max = 2 },
        foesPerGroup = opts.foesPerGroup or { min = 2, max = 3 },
        groupSpreadRadius = opts.groupSpreadRadius or 120,
        structuresPerChunk = opts.structuresPerChunk or { min = 1, max = 3 },
        propsPerChunk = opts.propsPerChunk or { min = 3, max = 8 },
        bossPackElites = opts.bossPackElites or { min = 2, max = 5 },
        bossPackPadding = opts.bossPackPadding or 140,
        bossPackSpreadRadius = opts.bossPackSpreadRadius or 160,
    }

    return setmetatable(resolver, SpawnResolver)
end

local function chooseBossFoeType(biome)
    local bestId
    local bestTier = -math.huge

    for _, entry in ipairs(biome and biome.foeWeights or {}) do
        local config = foeTypes.getConfig(entry.id)
        local tier = (config and config.tier) or 0
        if tier > bestTier then
            bestTier = tier
            bestId = entry.id
        end
    end

    return bestId or foeTypes.getRandomType()
end

local function ensureBossPack(self, world, chunk, biome)
    if not world or not chunk or not chunk.zoneName then
        return
    end

    world.bossPacks = world.bossPacks or {}
    chunk.descriptors = chunk.descriptors or {}
    chunk.descriptors.foes = chunk.descriptors.foes or {}

    local safeZone = world.spawnSafeZone
    local isSafeChunk = safeZone and safeZone.chunkKey == chunk.key
    local packInfo = world.bossPacks[chunk.zoneName]

    if packInfo and packInfo.chunkKey ~= chunk.key then
        return
    end

    if packInfo and packInfo.defeated then
        return
    end

    if not packInfo then
        if isSafeChunk then
            return
        end

        packInfo = {
            id = chunk.zoneName .. ":boss_pack",
            chunkKey = chunk.key,
            seed = (chunk.zoneSeed or chunk.seed or 0) + 1337,
            defeated = false,
        }
        world.bossPacks[chunk.zoneName] = packInfo
    end

    for _, descriptor in ipairs(chunk.descriptors.foes) do
        if descriptor.packId == packInfo.id then
            chunk.bossPackId = chunk.bossPackId or packInfo.id
            return
        end
    end

    local packRng = love.math.newRandomGenerator(packInfo.seed)
    local bossCenterX, bossCenterY = randomInChunk(
        packRng,
        chunk.chunkX,
        chunk.chunkY,
        self.chunkSize,
        self.bossPackPadding
    )
    local bossType = chooseBossFoeType(biome)

    local bossDescriptor = foeRarity.withDefaults({
        id = chunk.key .. ":boss_pack:boss",
        foeType = bossType,
        x = bossCenterX,
        y = bossCenterY,
        packId = packInfo.id,
        rarity = "boss",
        name = BossNameGenerator.generate(packInfo.seed),
    })
    chunk.descriptors.foes[#chunk.descriptors.foes + 1] = bossDescriptor

    local minElites = math.max(0, self.bossPackElites.min or 0)
    local maxElites = math.max(minElites, self.bossPackElites.max or minElites)
    local eliteCount = packRng:random(minElites, maxElites)

    for index = 1, eliteCount do
        local angle = packRng:random() * math.pi * 2
        local distance = packRng:random() * self.bossPackSpreadRadius
        local x = bossCenterX + math.cos(angle) * distance
        local y = bossCenterY + math.sin(angle) * distance

        local eliteDescriptor = foeRarity.withDefaults({
            id = chunk.key .. ":boss_pack:elite:" .. index,
            foeType = weightedChoice(packRng, biome and biome.foeWeights or nil) or foeTypes.getRandomType(),
            x = x,
            y = y,
            packId = packInfo.id,
            groupId = "boss_pack",
            rarity = "elite",
        })
        chunk.descriptors.foes[#chunk.descriptors.foes + 1] = eliteDescriptor
    end

    chunk.bossPackId = packInfo.id
end

function SpawnResolver.populateChunk(self, world, chunk)
    local rng = love.math.newRandomGenerator(chunk.seed)
    local biome = biomes.getById(chunk.biomeId)

    chunk.descriptors = chunk.descriptors or {}
    chunk.descriptors.foes = chunk.descriptors.foes or {}
    chunk.descriptors.structures = chunk.descriptors.structures or {}
    chunk.props = chunk.props or {}

    local safeZone = world.spawnSafeZone
    local isSafeChunk = safeZone and safeZone.chunkKey == chunk.key
    local groupCount = 0
    if not isSafeChunk and rng:random() <= self.foeChunkSpawnChance then
        local minGroups = math.max(0, self.groupsPerChunk.min or 0)
        local maxGroups = math.max(minGroups, self.groupsPerChunk.max or minGroups)
        groupCount = rng:random(minGroups, maxGroups)
    end

    for groupIndex = 1, groupCount do
        local centerX, centerY = randomInChunk(rng, chunk.chunkX, chunk.chunkY, self.chunkSize, 96)
        local packId = chunk.key .. ":pack:" .. groupIndex

        local minGroupSize = math.max(1, self.foesPerGroup.min or 1)
        local maxGroupSize = math.max(minGroupSize, self.foesPerGroup.max or minGroupSize)
        local groupSize = rng:random(minGroupSize, maxGroupSize)

        for memberIndex = 1, groupSize do
            -- Select foe type per individual foe for better diversity
            local foeTypeId = weightedChoice(rng, biome and biome.foeWeights or nil) or foeTypes.getRandomType()
            local angle = (memberIndex / groupSize) * math.pi * 2 + rng:random() * 0.35
            local spread = rng:random() * self.groupSpreadRadius
            local x = centerX + math.cos(angle) * spread
            local y = centerY + math.sin(angle) * spread

            local descriptor = {
                id = chunk.key .. ":foe_group:" .. groupIndex .. ":" .. memberIndex,
                foeType = foeTypeId,
                x = x,
                y = y,
                groupId = groupIndex,
                packId = packId,
            }
            chunk.descriptors.foes[#chunk.descriptors.foes + 1] = foeRarity.withDefaults(descriptor)
        end
    end

    local structureCount = rng:random(self.structuresPerChunk.min, self.structuresPerChunk.max)
    for i = 1, structureCount do
        local structureId = weightedChoice(rng, biome and biome.structureWeights or nil)
        if structureId then
            local x, y = randomInChunk(rng, chunk.chunkX, chunk.chunkY, self.chunkSize, 32)
            chunk.descriptors.structures[#chunk.descriptors.structures + 1] = {
                id = chunk.key .. ":structure:" .. i,
                structureId = structureId,
                x = x,
                y = y,
                rotation = rng:random() * math.pi * 2,
            }
        end
    end

    local propCount = rng:random(self.propsPerChunk.min, self.propsPerChunk.max)
    for i = 1, propCount do
        local propId = weightedChoice(rng, biome and biome.propWeights or nil) or "shrub"
        local radius = rng:random(12, 36)
        local x, y = randomInChunk(rng, chunk.chunkX, chunk.chunkY, self.chunkSize, radius)
        chunk.props[#chunk.props + 1] = {
            id = chunk.key .. ":prop:" .. i,
            kind = propId,
            x = x,
            y = y,
            radius = radius,
            jitter = rng:random(),
        }
    end

    ensureBossPack(self, world, chunk, biome)

    world.generatedChunks[chunk.key] = chunk
end

return SpawnResolver
