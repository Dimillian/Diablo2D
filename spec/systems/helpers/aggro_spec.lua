local helper = require("spec.spec_helper")
local TestWorld = require("spec.support.test_world")

local Aggro = require("systems.helpers.aggro")

describe("Aggro.ensureAggro", function()
    local world
    local player

    before_each(function()
        world = TestWorld.new()
        player = helper.buildEntity({
            id = "player_1",
            playerControlled = true,
            position = { x = 100, y = 100 },
            size = { w = 32, h = 32 },
        })

        world:addEntity(player)
    end)

    local foeCounter = 0

    local function buildFoe(opts)
        opts = opts or {}
        foeCounter = foeCounter + 1

        return helper.buildEntity({
            id = opts.id or ("foe_" .. tostring(foeCounter)),
            position = opts.position or { x = 150, y = 150 },
            size = opts.size or { w = 24, h = 24 },
            detection = {
                range = opts.range or 120,
                leashExtension = opts.leashExtension or 350,
            },
            foe = {
                type = opts.type or "aggressive",
                packId = opts.packId,
                packAggro = opts.packAggro or false,
            },
        })
    end

    it("marks a single foe as aggroed and assigns chase target", function()
        local foe = buildFoe({ packAggro = false })
        world:addEntity(foe)

        Aggro.ensureAggro(world, foe, player.id, { target = player })

        assert.is_false(foe.inactive)
        assert.is_true(foe.detection.forceAggro)
        assert.equal(player.id, foe.chase.targetId)
        assert.is_true((foe.detection.leashRange or 0) >= (foe.detection.range + foe.detection.leashExtension))
    end)

    it("propagates aggro to pack members when packAggro is true", function()
        local packId = "pack_1"
        local primary = buildFoe({ id = "foe_primary", packId = packId, packAggro = true })
        local ally = buildFoe({ id = "foe_ally", packId = packId, packAggro = true, position = { x = 200, y = 200 } })

        world:addEntity(primary)
        world:addEntity(ally)

        Aggro.ensureAggro(world, primary, player.id, { target = player })

        assert.is_true(primary.detection.forceAggro)
        assert.equal(player.id, primary.chase.targetId)

        assert.is_true(ally.detection.forceAggro)
        assert.equal(player.id, ally.chase.targetId)
    end)

    it("does not propagate aggro to other packs", function()
        local packId = "pack_1"
        local otherPackId = "pack_2"

        local primary = buildFoe({ id = "foe_primary", packId = packId, packAggro = true })
        local samePack = buildFoe({ id = "foe_same", packId = packId, packAggro = true })
        local differentPack = buildFoe({ id = "foe_other", packId = otherPackId, packAggro = true })

        world:addEntity(primary)
        world:addEntity(samePack)
        world:addEntity(differentPack)

        Aggro.ensureAggro(world, primary, player.id, { target = player })

        assert.is_true(samePack.detection.forceAggro)
        assert.equal(player.id, samePack.chase.targetId)

        assert.is_nil(differentPack.chase)
        assert.is_nil(differentPack.detection.forceAggro)
    end)

    it("respects propagatePack flag", function()
        local packId = "pack_1"
        local primary = buildFoe({ id = "foe_primary", packId = packId, packAggro = true })
        local ally = buildFoe({ id = "foe_ally", packId = packId, packAggro = true })

        world:addEntity(primary)
        world:addEntity(ally)

        Aggro.ensureAggro(world, primary, player.id, {
            target = player,
            propagatePack = false,
        })

        assert.is_truthy(primary.chase)
        assert.is_nil(ally.chase)
    end)

    it("ignores non-player targets", function()
        local foe = buildFoe()
        world:addEntity(foe)

        world:addEntity(helper.buildEntity({ id = "npc_1", playerControlled = false }))

        Aggro.ensureAggro(world, foe, "npc_1")
        assert.is_nil(foe.chase)
        assert.is_nil(foe.detection.forceAggro)
    end)
end)
