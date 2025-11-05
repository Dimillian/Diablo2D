local helper = require("spec.spec_helper")
local TestWorld = require("spec.support.test_world")

package.loaded["items.generator"] = require("spec.system_helpers.item_generator_stub")
package.loaded["systems.helpers.tooltips"] = require("spec.system_helpers.tooltips_stub")
package.loaded["entities.loot"] = require("spec.system_helpers.loot_entity_stub")
package.loaded["data.items"] = require("spec.system_helpers.items_data_stub")

local lootDropSystem = require("systems.core.loot_drops")

describe("systems.core.loot_drops", function()
    local world
    local player
    local originalRandom

    before_each(function()
        originalRandom = math.random
        math.random = function(a, b)
            if a and b then
                return a
            elseif a then
                return a
            else
                return 0.5
            end
        end

        world = TestWorld.new()
        world.pendingCombatEvents = {}

        player = helper.buildEntity({
            id = "player_1",
            position = { x = 0, y = 0 },
            potions = {
                healthPotionCount = 0,
                maxHealthPotionCount = 5,
                manaPotionCount = 0,
                maxManaPotionCount = 5,
            },
        })

        function world:getPlayer() -- luacheck: ignore 212/self
            return player
        end

        world:addEntity(player)
    end)

    after_each(function()
        math.random = originalRandom
    end)

    local function countLootEntities()
        local count = 0
        for _, entity in pairs(world.entities) do
            if entity.lootable then
                count = count + 1
            end
        end
        return count
    end

    it("spawns loot and potion entities for death events", function()
        world.pendingCombatEvents[1] = {
            type = "death",
            targetId = "foe_1",
            position = { x = 100, y = 100 },
            sourceId = player.id,
            foeTypeId = "slow",
        }

        lootDropSystem.update(world, 0)

        assert.is_true(countLootEntities() >= 1)
        assert.is_true(world.pendingCombatEvents[1]._spawnedLoot)
    end)

    it("does not spawn duplicate loot when event already processed", function()
        world.pendingCombatEvents[1] = {
            type = "death",
            targetId = "foe_1",
            position = { x = 100, y = 100 },
            sourceId = player.id,
            _spawnedLoot = true,
        }

        local beforeCount = countLootEntities()
        lootDropSystem.update(world, 0)
        assert.equal(beforeCount, countLootEntities())
    end)

    it("ignores events without position", function()
        world.pendingCombatEvents[1] = {
            type = "death",
            targetId = "foe_1",
            sourceId = player.id,
        }

        lootDropSystem.update(world, 0)
        assert.equal(0, countLootEntities())
    end)
end)
