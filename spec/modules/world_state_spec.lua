require("spec.spec_helper")

-- luacheck: globals love rawset rawget _G

local originalLove = rawget(_G, "love")
local WorldState = require("modules.world_state")

local function buildLoveStub(overrides)
    overrides = overrides or {}

    local function noop()
        return true
    end

    local stub = {
        filesystem = {
            getInfo = overrides.getInfo or function()
                return nil
            end,
            createDirectory = overrides.createDirectory or noop,
            write = overrides.write or function(_path, contents)
                return #tostring(contents)
            end,
            getDirectoryItems = overrides.getDirectoryItems or function()
                return {}
            end,
            read = overrides.read,
        },
        math = {
            random = function(min, max)
                if not min then
                    return 0.5
                end
                if not max then
                    return min
                end
                return (min + max) / 2
            end,
        },
    }

    return stub
end

local function buildWorldDouble()
    local player = {
        id = "player",
        position = { x = 10, y = 20 },
        movement = { speed = 140 },
        combat = { range = 100 },
        baseStats = { strength = 3 },
        health = { current = 45, max = 50 },
        mana = { current = 20, max = 25 },
        potions = {
            healthPotionCount = 2,
            maxHealthPotionCount = 10,
            manaPotionCount = 1,
            maxManaPotionCount = 10,
            cooldownDuration = 0.5,
            cooldownRemaining = 0.1,
        },
        inventory = {
            items = {
                { id = "item_1", name = "Sword", stats = { damageMin = 5, damageMax = 7 } },
            },
            capacity = 80,
            gold = 12,
        },
        equipment = {
            weapon = { id = "item_1" },
        },
        skills = {
            equipped = { "fireball", "thunder" },
            availablePoints = 1,
            allocations = { fireball = 1 },
        },
        experience = {
            level = 2,
            currentXP = 5,
            xpForNextLevel = 10,
            unallocatedPoints = 0,
        },
    }

    local world = {
        getPlayer = function()
            return player
        end,
        serializeState = function()
            return {
                worldSeed = 123,
                chunkSize = 512,
                activeRadius = 4,
                startBiomeId = "forest",
                startBiomeRadius = 2,
                startBiomeCenter = { chunkX = 0, chunkY = 0 },
                forceStartBiome = true,
                minimapState = { visible = true, zoom = 1.2 },
                visitedChunks = { ["0:0"] = true },
                generatedChunks = {
                    ["0:0"] = {
                        key = "0:0",
                        chunkX = 0,
                        chunkY = 0,
                        biomeId = "forest",
                        descriptors = { foes = {}, structures = {} },
                        props = {},
                        defeatedFoes = {},
                        lootedStructures = {},
                    },
                },
                spawnSafeZone = { chunkKey = "0:0", centerX = 10, centerY = 20, radius = 192 },
                starterGearGenerated = true,
            }
        end,
    }

    return world
end

describe("modules.world_state", function()
    after_each(function()
        rawset(_G, "love", originalLove)
    end)

    it("builds a save payload with normalized player and world data", function()
        rawset(_G, "love", buildLoveStub())

        local payload = WorldState.buildSave(buildWorldDouble())
        assert.is_table(payload)
        assert.equals(WorldState.VERSION, payload.version)
        assert.equals(WorldState.DEFAULT_SLOT, payload.slot)
        assert.is_table(payload.player)
        assert.is_table(payload.world)

        assert.equals(10, payload.player.position.x)
        assert.equals(20, payload.player.position.y)
        assert.same({ "fireball", "thunder" }, payload.player.skills.equipped)
        assert.equals(1, payload.player.skills.availablePoints)
        assert.equals(12, payload.player.inventory.gold)

        assert.equals("forest", payload.world.startBiomeId)
        assert.truthy(payload.world.generatedChunks["0:0"])
        assert.equals(192, payload.world.spawnSafeZone.radius)
    end)

    it("returns ok when save writes successfully", function()
        rawset(_G, "love", buildLoveStub())

        local payload = WorldState.buildSave(buildWorldDouble())
        local ok, err = WorldState.save(payload)
        assert.is_true(ok)
        assert.is_nil(err)
    end)

    it("returns an error when encoding fails", function()
        rawset(_G, "love", buildLoveStub({
            write = function()
                return nil, "write failed"
            end,
        }))

    local payload = WorldState.buildSave(buildWorldDouble())
    local ok, err = WorldState.save(payload)
    assert.is_false(ok)
    assert.matches("write failed", err)
end)

it("roundtrips a save and preserves critical world and player fields", function()
    local written = {}
    rawset(_G, "love", buildLoveStub({
        write = function(path, contents)
            written.path = path
            written.contents = contents
                return #tostring(contents)
            end,
            getInfo = function(path)
                if path == written.path then
                    return { type = "file" }
                end
                return nil
            end,
            read = function(path)
                if path == written.path then
                    return written.contents
                end
                return nil
            end,
        }))

        local payload = WorldState.buildSave(buildWorldDouble())
        local ok = WorldState.save(payload)
        assert.is_true(ok)

        local loaded = WorldState.load(payload.slot)
        assert.is_table(loaded)

        -- Player assertions
        local player = loaded.player
        assert.equals(10, player.position.x)
        assert.equals(20, player.position.y)
        assert.equals(45, player.health.current)
        assert.equals(50, player.health.max)
        assert.equals(20, player.mana.current)
        assert.equals(25, player.mana.max)
        assert.equals(2, player.experience.level)
        assert.equals(5, player.experience.currentXP)
        assert.same({ "fireball", "thunder" }, player.skills.equipped)
        assert.equals(12, player.inventory.gold)
        assert.equals(1, #player.inventory.items)
        assert.equals("item_1", player.equipment.weapon.id)

        -- World assertions
        local world = loaded.world
        assert.equals(123, world.worldSeed)
        assert.equals(512, world.chunkSize)
        assert.equals(4, world.activeRadius)
        assert.equals("forest", world.startBiomeId)
        assert.is_true(world.visitedChunks["0:0"])
        assert.is_table(world.generatedChunks["0:0"])
        assert.equals(192, world.spawnSafeZone.radius)
        assert.is_true(world.starterGearGenerated)

        -- Build world options and ensure passthrough of fields
        local options = WorldState.buildWorldOptions(loaded)
        assert.equals(world.worldSeed, options.worldSeed)
        assert.equals(world.chunkSize, options.chunkSize)
        assert.equals(world.activeRadius, options.activeRadius)
        assert.equals(world.startBiomeId, options.startBiomeId)
        assert.equals(world.startBiomeRadius, options.startBiomeRadius)
        assert.same(world.startBiomeCenter, options.startBiomeCenter)
        assert.same(world.spawnSafeZone, options.spawnSafeZone)
        assert.equals(true, options.starterGearGenerated)
        assert.equals(player.position.x, options.playerX)
        assert.equals(player.position.y, options.playerY)
        assert.same(player, options.playerState)
    end)
end)
