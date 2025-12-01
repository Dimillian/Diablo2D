require("spec.spec_helper")

local LootDrops = require("systems.core.loot_drops")
local TestWorld = require("spec.support.test_world")
local FoeTypes = require("data.foe_types")

describe("systems.core.loot_drops rarity scaling", function()
    local world
    local originalRandom

    before_each(function()
        world = TestWorld.new()
        world.generatedChunks = {}
        world.pendingCombatEvents = {}
        world.addedLoot = {}

        function world:addEntity(entity)
            self.addedLoot[#self.addedLoot + 1] = entity
        end

        originalRandom = math.random
        math.random = function(min, max)
            if min and max then
                return min
            end
            return 0.1
        end
    end)

    after_each(function()
        math.random = originalRandom
    end)

    local function pushDeathEvent(rarityId)
        local foeTypeId = "orc3"
        local foeConfig = FoeTypes.getConfig(foeTypeId)
        assert.is_not_nil(foeConfig)

        world.pendingCombatEvents[#world.pendingCombatEvents + 1] = {
            type = "death",
            foeTypeId = foeTypeId,
            foeRarityId = rarityId,
            position = { x = 0, y = 0 },
        }
    end

    it("bosses drop multiple items", function()
        pushDeathEvent("boss")

        LootDrops.update(world, 0)

        local itemLoot = {}
        for _, entry in ipairs(world.addedLoot) do
            if entry.lootable and entry.lootable.item then
                itemLoot[#itemLoot + 1] = entry
            end
        end

        assert.is_true(#itemLoot >= 2)
    end)

    it("boss drop bypasses base chance gate", function()
        -- Force chance roll high to ensure boss override still drops
        math.random = function(min, max)
            if min and max then
                return min
            end
            return 0.99
        end

        pushDeathEvent("boss")
        LootDrops.update(world, 0)

        local hasItem = false
        for _, entry in ipairs(world.addedLoot) do
            if entry.lootable and entry.lootable.item then
                hasItem = true
                break
            end
        end

        assert.is_true(hasItem)
    end)

    it("elites increase gold amount compared to common", function()
        pushDeathEvent("common")
        LootDrops.update(world, 0)
        local commonGold = nil
        for _, entry in ipairs(world.addedLoot) do
            if entry.lootable and entry.lootable.gold then
                commonGold = entry.lootable.gold
            end
        end

        world.pendingCombatEvents = {}
        world.addedLoot = {}
        pushDeathEvent("elite")
        LootDrops.update(world, 0)
        local eliteGold = nil
        for _, entry in ipairs(world.addedLoot) do
            if entry.lootable and entry.lootable.gold then
                eliteGold = entry.lootable.gold
            end
        end

        assert.is_not_nil(commonGold)
        assert.is_not_nil(eliteGold)
        assert.is_true(eliteGold > commonGold)
    end)
end)
