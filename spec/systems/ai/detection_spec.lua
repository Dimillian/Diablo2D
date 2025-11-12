local helper = require("spec.spec_helper")
local TestWorld = require("spec.support.test_world")

local detectionSystem = require("systems.ai.detection")
local Aggro = require("systems.helpers.aggro")

describe("systems.ai.detection", function()
    local world
    local player

    local foeCounter = 0

    local function addFoe(opts)
        opts = opts or {}
        foeCounter = foeCounter + 1
        local entity = helper.buildEntity({
            id = opts.id or ("foe_" .. tostring(foeCounter)),
            position = opts.position or { x = 0, y = 0 },
            detection = {
                range = opts.range or 100,
                leashExtension = opts.leashExtension or 350,
            },
            chase = opts.chase,
        })

        if opts.withChase then
            entity.chase = { targetId = player.id }
        end

        world:addEntity(entity)
        return entity
    end

    before_each(function()
        world = TestWorld.new()
        player = helper.buildEntity({
            id = "player_1",
            playerControlled = true,
            position = { x = 100, y = 100 },
        })

        function world:getPlayer() -- luacheck: ignore 212/self
            return player
        end

        world:addEntity(player)
    end)

    it("acquires chase when player enters detection radius", function()
        local foe = addFoe({ position = { x = 50, y = 50 }, range = 120 })

        detectionSystem.update(world, 0)

        assert.is_not_nil(foe.chase)
        assert.equal(player.id, foe.chase.targetId)
        assert.equal(player.id, foe.detection.detectedTargetId)
    end)

    it("drops chase when player leaves detection radius without forced aggro", function()
        local foe = addFoe({ position = { x = 50, y = 50 }, range = 80 })
        detectionSystem.update(world, 0)
        assert.is_not_nil(foe.chase)

        -- Move player beyond range
        player.position.x = 500
        player.position.y = 500
        detectionSystem.update(world, 0)

        assert.is_nil(foe.chase)
        assert.is_nil(foe.detection.detectedTargetId)
    end)

    it("maintains chase while inside forced leash radius and drops after exceeding it", function()
        local foe = addFoe({ position = { x = 0, y = 0 }, range = 80, leashExtension = 200 })

        -- Force aggro (simulates combat hit)
        Aggro.ensureAggro(world, foe, player.id, { target = player })
        assert.is_true(foe.detection.forceAggro)

        -- Move player inside leash range
        player.position.x = 120
        player.position.y = 0
        detectionSystem.update(world, 0)

        assert.is_not_nil(foe.chase)
        assert.is_true(foe.detection.forceAggro)

        -- Move player beyond leash (range + extension)
        player.position.x = 400
        player.position.y = 0
        detectionSystem.update(world, 0)

        assert.is_nil(foe.chase)
        assert.is_false(foe.detection.forceAggro)
        assert.is_nil(foe.detection.leashRange)
    end)

    it("ignores inactive foes", function()
        local foe = addFoe({ position = { x = 70, y = 70 }, range = 120 })
        foe.inactive = { isInactive = true }

        detectionSystem.update(world, 0)

        assert.is_nil(foe.chase)
        assert.is_nil(foe.detection.detectedTargetId)
    end)
end)
