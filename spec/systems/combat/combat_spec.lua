local helper = require("spec.spec_helper")
local TestWorld = require("spec.support.test_world")

local combatSystem = require("systems.combat.combat")
local deathDetectionSystem = require("systems.core.death_detection")
local createCombat = require("components.combat")
local createHealth = require("components.health")

local function makeCombatComponent(opts)
    opts = opts or {}
    return createCombat({
        range = opts.range or 50,
        attackSpeed = opts.attackSpeed or 1.0,
        baseDamageMin = opts.damageMin or 5,
        baseDamageMax = opts.damageMax or 5,
    })
end

describe("systems.combat.combat", function()
    local world
    local player
    local foe

    before_each(function()
        world = TestWorld.new()

        world.pendingCombatEvents = {}
        world.time = 0

        function world:getPlayer() -- luacheck: ignore 212/self
            return player
        end

        player = helper.buildEntity({
            id = "player_1",
            playerControlled = true,
            position = { x = 0, y = 0 },
            size = { w = 32, h = 32 },
            combat = makeCombatComponent({ range = 80 }),
            health = createHealth({ max = 100, current = 100 }),
        })

        foe = helper.buildEntity({
            id = "foe_1",
            position = { x = 40, y = 0 },
            size = { w = 32, h = 32 },
            detection = { range = 100, leashExtension = 350 },
            foe = { type = "aggressive", packAggro = true, packId = "pack_1" },
            combat = makeCombatComponent({ range = 50 }),
            health = createHealth({ max = 60, current = 60 }),
        })

        world:addEntity(player)
        world:addEntity(foe)
    end)

    local function queuePlayerAttack(target, range)
        player.combat.queuedAttack = {
            targetId = target.id,
            range = range or player.combat.range,
        }
    end

    it("deals damage to target and emits damage event", function()
        queuePlayerAttack(foe, 80)

        combatSystem.update(world, 0.016)

        assert.is_true(foe.health.current < 60)
        assert.is_nil(player.combat.queuedAttack)

        local event = world.pendingCombatEvents[1]
        assert.is_not_nil(event)
        assert.equal("damage", event.type)
        assert.equal(player.id, event.sourceId)
        assert.equal(foe.id, event.targetId)
    end)

    it("removes target on lethal hit and pushes death event", function()
        foe.health.current = 5
        queuePlayerAttack(foe, 80)

        combatSystem.update(world, 0.016)
        deathDetectionSystem.update(world, 0.016)

        -- Entity should still exist but be marked as dead with death animation
        local deadFoe = world:getEntity(foe.id)
        assert.is_not_nil(deadFoe)
        assert.is_not_nil(deadFoe.dead)
        assert.is_not_nil(deadFoe.deathAnimation)
        assert.equal(0, deadFoe.health.current)

        local foundDeath = false
        for _, event in ipairs(world.pendingCombatEvents) do
            if event.type == "death" then
                foundDeath = true
                assert.equal(foe.id, event.targetId)
                assert.equal(player.id, event.sourceId)
            end
        end
        assert.is_true(foundDeath)
    end)

    it("forces aggro on surviving foes when struck", function()
        queuePlayerAttack(foe, 80)

        combatSystem.update(world, 0.016)

        assert.is_true(foe.detection.forceAggro)
        assert.is_not_nil(foe.chase)
        assert.equal(player.id, foe.chase.targetId)
    end)

    it("clears queued attack when out of range", function()
        player.combat.range = 20
        queuePlayerAttack(foe, 10)

        combatSystem.update(world, 0.016)

        assert.is_nil(player.combat.queuedAttack)
        assert.equal(60, foe.health.current)
        assert.is_true(#world.pendingCombatEvents == 0)
    end)
end)
