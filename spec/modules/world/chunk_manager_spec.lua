require("spec.spec_helper")

-- luacheck: globals love rawset rawget _G

local originalLove = rawget(_G, "love")

local function buildLoveStub()
    local function isInteger(value)
        return math.floor(value) == value
    end

    local function createStubRng()
        return {
            random = function(_self, minValue, maxValue)
                local base = 0.5

                if minValue and maxValue then
                    if isInteger(minValue) and isInteger(maxValue) then
                        return math.floor(minValue + (maxValue - minValue) * base + 0.5)
                    end
                    return minValue + (maxValue - minValue) * base
                end

                if minValue then
                    if isInteger(minValue) then
                        return math.floor(1 + (minValue - 1) * base + 0.5)
                    end
                    return (minValue - 1) * base + 1
                end

                return base
            end,
        }
    end

    local rngFactory = createStubRng

    return {
        math = {
            noise = function()
                return 0.7
            end,
            newRandomGenerator = function()
                return rngFactory()
            end,
            random = function(minValue, maxValue)
                return rngFactory():random(minValue, maxValue)
            end,
        },
    }
end

rawset(_G, "love", buildLoveStub())
local ChunkManager = require("modules.world.chunk_manager")
local SpawnResolver = require("modules.world.spawn_resolver")

describe("modules.world.chunk_manager", function()
    teardown(function()
        rawset(_G, "love", originalLove)
    end)

    local function buildManager(opts)
        local spawnResolver = SpawnResolver.new({
            chunkSize = opts.chunkSize,
            foeChunkSpawnChance = 1,
            groupsPerChunk = { min = 1, max = 1 },
            foesPerGroup = { min = 1, max = 1 },
        })

        return ChunkManager.new({
            chunkSize = opts.chunkSize,
            activeRadius = opts.activeRadius,
            worldSeed = opts.worldSeed,
            spawnResolver = spawnResolver,
            startBiomeId = opts.startBiomeId,
            startBiomeCenter = opts.startBiomeCenter,
            startBiomeRadius = opts.startBiomeRadius,
            forceStartBiome = opts.forceStartBiome,
        })
    end

    it("forces all chunks within the start biome radius to the configured biome", function()
        local world = {
            generatedChunks = {},
            spawnSafeZone = { chunkKey = "0:0" },
        }

        local manager = buildManager({
            chunkSize = 512,
            activeRadius = 4,
            worldSeed = 123,
            startBiomeId = "forest",
            startBiomeCenter = { chunkX = 0, chunkY = 0 },
            startBiomeRadius = 2,
            forceStartBiome = true,
        })

        local within = {
            { 0, 0 },
            { 1, 0 },
            { -1, 1 },
            { 0, -2 },
        }

        for _, coords in ipairs(within) do
            local chunk = ChunkManager.ensureChunkLoaded(manager, world, coords[1], coords[2])
            assert.equals("forest", chunk.biomeId)
        end

        local outside = ChunkManager.ensureChunkLoaded(manager, world, 3, 0)
        assert.equals("desert", outside.biomeId)
    end)

    it("omits foes inside the spawn safe zone but populates other chunks", function()
        local world = {
            generatedChunks = {},
        }

        local manager = buildManager({
            chunkSize = 512,
            activeRadius = 4,
            worldSeed = 456,
            startBiomeId = "forest",
            startBiomeCenter = { chunkX = 0, chunkY = 0 },
            startBiomeRadius = 2,
            forceStartBiome = true,
        })

        local spawnKey = ChunkManager.getChunkKey(manager, 0, 0)
        world.spawnSafeZone = { chunkKey = spawnKey }

        local spawnChunk = ChunkManager.ensureChunkLoaded(manager, world, 0, 0)
        assert.equals(0, #spawnChunk.descriptors.foes)

        local otherChunk = ChunkManager.ensureChunkLoaded(manager, world, 3, 0)
        assert.is_true(#otherChunk.descriptors.foes > 0)
    end)

    it("generates deterministic foe descriptors for the same chunk seed", function()
        local function generateDescriptors()
            local world = {
                generatedChunks = {},
            }

            local manager = buildManager({
                chunkSize = 512,
                activeRadius = 4,
                worldSeed = 789,
                startBiomeId = "forest",
                startBiomeCenter = { chunkX = 0, chunkY = 0 },
                startBiomeRadius = 2,
                forceStartBiome = false,
            })

            local chunk = ChunkManager.ensureChunkLoaded(manager, world, 4, -1)
            return chunk.descriptors.foes
        end

        local first = generateDescriptors()
        local second = generateDescriptors()

        assert.equals(#first, #second)
        for index, descriptor in ipairs(first) do
            local other = second[index]
            assert.are.same(descriptor.foeType, other.foeType)
            assert.are.same(descriptor.x, other.x)
            assert.are.same(descriptor.y, other.y)
        end
    end)
end)
