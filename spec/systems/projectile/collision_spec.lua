local helper = require("spec.spec_helper")
local TestWorld = require("spec.support.test_world")

package.loaded["systems.helpers.coordinates"] = require("spec.system_helpers.coordinates_stub")
package.loaded["systems.helpers.projectile_effects"] = require("spec.system_helpers.projectile_effects_stub")

local collisionSystem = require("systems.projectile.collision")
local createHealth = require("components.health")
local createCombat = require("components.combat")

describe("systems.projectile.collision", function()
    local world
    local player

    before_each(function()
        world = TestWorld.new()
        world.pendingCombatEvents = {}
        world.time = 0

        player = helper.buildEntity({
            id = "player_1",
            playerControlled = true,
            position = { x = 0, y = 0 },
            size = { w = 32, h = 32 },
            combat = createCombat({
                range = 80,
                baseDamageMin = 8,
                baseDamageMax = 8,
            }),
        })

        world:addEntity(player)
    end)

    local function addFoe(opts)
        opts = opts or {}
        local foe = helper.buildEntity({
            id = opts.id or "foe_1",
            position = opts.position or { x = 40, y = 0 },
            size = opts.size or { w = 32, h = 32 },
            foe = {
                type = "aggressive",
                packAggro = true,
                packId = "pack_1",
            },
            detection = {
                range = 100,
                leashExtension = 350,
            },
            health = createHealth({
                max = opts.health or 60,
                current = opts.health or 60,
            }),
        })

        world:addEntity(foe)
        return foe
    end

    local function addProjectile(opts)
        opts = opts or {}
        local projectile = helper.buildEntity({
            id = opts.id or "projectile_1",
            position = opts.position or { x = 32, y = 0 },
            size = opts.size or { w = 8, h = 8 },
            projectile = {
                ownerId = opts.ownerId or player.id,
                damage = { min = opts.damage or 5, max = opts.damage or 5 },
                state = "flight",
            },
        })

        world:addEntity(projectile)
        return projectile
    end

    it("applies damage, emits event, and forces aggro on hit foes", function()
        local foe = addFoe()
        addProjectile({ position = { x = 40, y = 0 }, damage = 7 })

        collisionSystem.update(world, 0)

        assert.equal(53, foe.health.current)
        assert.is_true(foe.detection.forceAggro)
        assert.equal(player.id, foe.chase.targetId)

        local event = world.pendingCombatEvents[1]
        assert.is_not_nil(event)
        assert.equal("damage", event.type)
        assert.equal(player.id, event.sourceId)
        assert.equal(foe.id, event.targetId)
    end)

    it("handles lethal hits by removing the foe and pushing death event", function()
        local foe = addFoe({ health = 4 })
        addProjectile({ position = { x = 40, y = 0 }, damage = 6 })

        collisionSystem.update(world, 0)

        assert.is_nil(world:getEntity(foe.id))

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

    it("ignores foes outside collision radius", function()
        local foe = addFoe({ position = { x = 200, y = 0 } })
        addProjectile({ position = { x = 40, y = 0 }, damage = 7 })

        collisionSystem.update(world, 0)

        assert.equal(foe.health.max, foe.health.current)
        assert.is_nil(foe.chase)
        assert.equal(0, #world.pendingCombatEvents)
    end)
end)
