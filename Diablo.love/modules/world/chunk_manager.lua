local vector = require("modules.vector")
local biomes = require("data.biomes")
local BiomeResolver = require("modules.world.biome_resolver")

local ChunkManager = {}
ChunkManager.__index = ChunkManager

local HASH_PRIME_X = 73856093
local HASH_PRIME_Y = 19349663
local HASH_PRIME_SEED = 83492791

local function buildKey(chunkX, chunkY)
    return tostring(chunkX) .. ":" .. tostring(chunkY)
end

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function applyStartBiome(manager, chunk)
    if not manager.startBiomeId or manager.forceStartBiome == false then
        return
    end

    local center = manager.startBiomeCenter
    local radius = manager.startBiomeRadius or 0
    if not center then
        return
    end

    local dx = chunk.chunkX - center.chunkX
    local dy = chunk.chunkY - center.chunkY
    if (dx * dx + dy * dy) > radius * radius then
        return
    end

    local biome = biomes.getById(manager.startBiomeId)
    chunk.biomeId = manager.startBiomeId
    chunk.biomeLabel = biome and biome.label or manager.startBiomeId
    chunk.transition = chunk.transition or {}
    chunk.transition.noiseValue = chunk.transition.noiseValue or 0
    chunk.transition.normalized = 0.5
    chunk.transition.transitionStrength = 0
    chunk.transition.neighbors = chunk.transition.neighbors or {}
end

function ChunkManager.new(opts)
    opts = opts or {}

    local manager = {
        chunkSize = opts.chunkSize,
        activeRadius = opts.activeRadius,
        worldSeed = opts.worldSeed or 0,
        spawnResolver = opts.spawnResolver,
        startBiomeId = opts.startBiomeId,
        startBiomeCenter = opts.startBiomeCenter,
        startBiomeRadius = math.max(0, opts.startBiomeRadius or 0),
        forceStartBiome = opts.forceStartBiome,
    }

    return setmetatable(manager, ChunkManager)
end

function ChunkManager.getChunkCoords(manager, x, y)
    local chunkSize = manager.chunkSize
    local chunkX = math.floor(x / chunkSize)
    local chunkY = math.floor(y / chunkSize)
    return chunkX, chunkY
end

function ChunkManager.hashSeed(manager, chunkX, chunkY)
    return manager.worldSeed * HASH_PRIME_SEED + chunkX * HASH_PRIME_X + chunkY * HASH_PRIME_Y
end

function ChunkManager.ensureChunkLoaded(manager, world, chunkX, chunkY)
    world.generatedChunks = world.generatedChunks or {}
    local key = buildKey(chunkX, chunkY)
    local chunk = world.generatedChunks[key]
    if chunk then
        chunk.descriptors = chunk.descriptors or {}
        chunk.descriptors.foes = chunk.descriptors.foes or {}
        chunk.descriptors.structures = chunk.descriptors.structures or {}
        chunk.spawnedEntities = chunk.spawnedEntities or {}
        chunk.defeatedFoes = chunk.defeatedFoes or {}
        chunk.lootedStructures = chunk.lootedStructures or {}
        chunk.props = chunk.props or {}
        applyStartBiome(manager, chunk)
        return chunk
    end

    local seed = ChunkManager.hashSeed(manager, chunkX, chunkY)
    local biomeId, transition = BiomeResolver.resolveChunk(manager.worldSeed, chunkX, chunkY)
    local biome = biomes.getById(biomeId)

    chunk = {
        key = key,
        chunkX = chunkX,
        chunkY = chunkY,
        worldSeed = manager.worldSeed,
        seed = seed,
        biomeId = biomeId,
        biomeLabel = biome and biome.label or biomeId,
        transition = transition,
        descriptors = {},
        spawnedEntities = {},
        defeatedFoes = {},
        lootedStructures = {},
        props = {},
    }

    applyStartBiome(manager, chunk)

    if manager.spawnResolver then
        manager.spawnResolver:populateChunk(world, chunk)
    end

    world.generatedChunks[key] = chunk
    return chunk
end

function ChunkManager.iterateActiveChunks(manager, world)
    local player = world:getPlayer()
    if not player or not player.position then
        return {}
    end

    local playerX = player.position.x
    local playerY = player.position.y
    local chunkX, chunkY = ChunkManager.getChunkCoords(manager, playerX, playerY)

    local activeChunks = {}
    for dx = -manager.activeRadius, manager.activeRadius do
        for dy = -manager.activeRadius, manager.activeRadius do
            local distance = vector.length(dx, dy)
            if distance <= manager.activeRadius + 0.5 then
                local cx = chunkX + dx
                local cy = chunkY + dy
                local chunk = ChunkManager.ensureChunkLoaded(manager, world, cx, cy)
                activeChunks[#activeChunks + 1] = chunk
            end
        end
    end

    return activeChunks
end

function ChunkManager.getChunkKey(_manager, chunkX, chunkY)
    return buildKey(chunkX, chunkY)
end

function ChunkManager.computeChunkBounds(manager, chunkX, chunkY)
    local chunkSize = manager.chunkSize
    local originX = chunkX * chunkSize
    local originY = chunkY * chunkSize
    return {
        x = originX,
        y = originY,
        w = chunkSize,
        h = chunkSize,
    }
end

function ChunkManager.computeTransitionColor(chunk, axis)
    local transitionStrength = chunk.transition and chunk.transition.transitionStrength or 0
    transitionStrength = clamp(transitionStrength, 0, 1)
    return transitionStrength * (axis == "x" and 0.5 or 0.35)
end

return ChunkManager
