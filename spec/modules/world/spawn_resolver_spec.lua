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
                local base = 0.42

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
                return 0.5
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

local SpawnResolver = require("modules.world.spawn_resolver")

describe("modules.world.spawn_resolver", function()
    teardown(function()
        rawset(_G, "love", originalLove)
    end)

    local function buildChunk()
        return {
            chunkX = 0,
            chunkY = 0,
            key = "0:0",
            seed = 999,
            biomeId = "forest",
            zoneName = "test_zone",
            zoneSeed = 777,
            descriptors = {
                foes = {},
                structures = {},
            },
            spawnedEntities = {},
            defeatedFoes = {},
            lootedStructures = {},
            props = {},
        }
    end

    it("places a deterministic boss pack with boss and elites per zone", function()
        local resolver = SpawnResolver.new({
            chunkSize = 512,
            foeChunkSpawnChance = 0,
            structuresPerChunk = { min = 0, max = 0 },
            propsPerChunk = { min = 0, max = 0 },
            bossPackElites = { min = 2, max = 2 },
        })

        local world = { generatedChunks = {}, bossPacks = {} }
        local chunk = buildChunk()

        resolver:populateChunk(world, chunk)

        local packInfo = world.bossPacks["test_zone"]
        assert.is_not_nil(packInfo)
        assert.equals("0:0", packInfo.chunkKey)

        local foes = chunk.descriptors.foes
        assert.equals(3, #foes)

        local bossCount, eliteCount = 0, 0
        local packId = packInfo.id
        local bossName
        for _, descriptor in ipairs(foes) do
            assert.equals(packId, descriptor.packId)
            if descriptor.rarity == "boss" then
                bossCount = bossCount + 1
                bossName = descriptor.name
            elseif descriptor.rarity == "elite" then
                eliteCount = eliteCount + 1
            end
        end

        assert.equals(1, bossCount)
        assert.equals(2, eliteCount)
        assert.is_string(bossName)
        assert.is_true(#bossName > 0)
    end)

    it("skips boss pack placement inside the spawn safe zone", function()
        local resolver = SpawnResolver.new({
            chunkSize = 512,
            foeChunkSpawnChance = 0,
            structuresPerChunk = { min = 0, max = 0 },
            propsPerChunk = { min = 0, max = 0 },
        })

        local world = {
            generatedChunks = {},
            bossPacks = {},
            spawnSafeZone = { chunkKey = "0:0" },
        }
        local chunk = buildChunk()

        resolver:populateChunk(world, chunk)

        assert.is_nil(world.bossPacks["test_zone"])
        assert.equals(0, #chunk.descriptors.foes)
    end)
end)
