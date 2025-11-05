local helper = require("spec.spec_helper")
local TestWorld = require("spec.support.test_world")

local experienceSystem = require("systems.core.experience")
local Leveling = require("modules.leveling")

describe("systems.core.experience", function()
    local world
    local player
    local originalGetFoeXP

    before_each(function()
        world = TestWorld.new()
        world.pendingCombatEvents = {}

        player = helper.buildEntity({
            id = "player_1",
            playerControlled = true,
            position = { x = 0, y = 0 },
            experience = {
                level = 1,
                currentXP = 0,
            },
            baseStats = {
                damageMin = 5,
                damageMax = 8,
                defense = 2,
                health = 50,
            },
        })

        function world:getPlayer() -- luacheck: ignore 212/self
            return player
        end

        world:addEntity(player)
        originalGetFoeXP = Leveling.getFoeXP
    end)

    after_each(function()
        Leveling.getFoeXP = originalGetFoeXP
    end)

    local function pushDeathEvent(opts)
        opts = opts or {}
        world.pendingCombatEvents[#world.pendingCombatEvents + 1] = {
            type = "death",
            sourceId = opts.sourceId or player.id,
            targetId = opts.targetId or "foe_1",
            foeLevel = opts.foeLevel or 1,
        }
    end

    it("awards XP when player kills a foe", function()
        pushDeathEvent()

        experienceSystem.update(world, 0)

        assert.is_true(player.experience.currentXP > 0)
        assert.equal(100, player.experience.xpForNextLevel)
        assert.is_true(world.pendingCombatEvents[1]._xpAwarded)
    end)

    it("does not award XP when player is not the killer", function()
        pushDeathEvent({ sourceId = "foe_2" })

        experienceSystem.update(world, 0)

        assert.equal(0, player.experience.currentXP)
        assert.is_true(world.pendingCombatEvents[1]._xpAwarded)
    end)

    it("levels up and applies stat bonuses when XP threshold reached", function()
        player.experience.currentXP = 90
        Leveling.getFoeXP = function()
            return 50
        end
        pushDeathEvent()

        experienceSystem.update(world, 0)

        assert.equal(2, player.experience.level)
        assert.is_true(player.experience.currentXP >= 140)
        assert.is_true(player.baseStats.damageMin > 5)
        assert.is_true(player.baseStats.health > 50)
    end)

    it("does nothing when there are no events", function()
        experienceSystem.update(world, 0)
        assert.equal(0, player.experience.currentXP)
    end)
end)
