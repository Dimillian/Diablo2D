local helper = require("spec.spec_helper")
local TestWorld = require("spec.support.test_world")

package.loaded["systems.helpers.coordinates"] = require("spec.system_helpers.coordinates_stub")
local movementSystem = require("systems.projectile.movement")

describe("systems.projectile.movement", function()
    local world
    local target

    before_each(function()
        world = TestWorld.new()
        target = helper.buildEntity({
            id = "target_1",
            position = { x = 200, y = 200 },
            size = { w = 32, h = 32 },
            health = { current = 100 },
        })
        world:addEntity(target)

        function world:getEntity(id)
            return self.entities[id]
        end
    end)

    local function buildProjectile(opts)
        opts = opts or {}
        local projectile = helper.buildEntity({
            id = opts.id or "projectile_1",
            position = opts.position or { x = 100, y = 100 },
            size = opts.size or { w = 8, h = 8 },
            movement = {
                vx = 0,
                vy = 0,
                speed = opts.speed or 150,
            },
            projectile = {
                targetId = opts.targetId,
                targetX = opts.targetX,
                targetY = opts.targetY,
                lifetime = opts.lifetime or 1,
                speed = opts.speed or 150,
            },
        })
        world:addEntity(projectile)
        return projectile
    end

    it("updates movement direction toward live target entity", function()
        local projectile = buildProjectile({ targetId = target.id })

        movementSystem.update(world, 0.016)

        assert.is_not_equal(0, projectile.movement.vx)
        assert.is_not_equal(0, projectile.movement.vy)
        assert.is_not_nil(projectile.projectile.lastDirectionX)
        assert.is_not_nil(projectile.projectile.lastDirectionY)
    end)

    it("falls back to target coordinates when targetId cleared", function()
        local projectile = buildProjectile({
            targetId = "missing",
            targetX = 210,
            targetY = 210,
        })

        movementSystem.update(world, 0.016)

        assert.is_not_equal(0, projectile.movement.vx)
        assert.is_not_equal(0, projectile.movement.vy)
        assert.equal(210, projectile.projectile.targetX)
    end)

    it("triggers impact when no target reference remains", function()
        local projectile = buildProjectile({
            targetId = "missing",
            targetX = nil,
            targetY = nil,
        })

        local removed = false
        function world:removeEntity(id) -- luacheck: ignore 212/self
            if id == projectile.id then
                removed = true
            end
        end

        movementSystem.update(world, 0.016)

        assert.is_false(removed, "impact effect should set state, removal handled separately")
        assert.equal("impact", projectile.projectile.state)
    end)
end)
