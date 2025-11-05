local helper = require("spec.spec_helper")
local TestWorld = require("spec.support.test_world")

local movementSystem = require("systems.core.movement")

describe("systems.core.movement", function()
    local world

    before_each(function()
        world = TestWorld.new()
    end)

    local function addEntity(opts)
        opts = opts or {}
        local entity = helper.buildEntity({
            id = opts.id or ("entity_" .. tostring(math.random(1000, 9999))),
            position = opts.position or { x = 0, y = 0 },
            movement = {
                speed = opts.speed or 100,
                vx = opts.vx or 1,
                vy = opts.vy or 0,
                maxDistance = opts.maxDistance,
            },
        })

        if opts.knockback then
            entity.knockback = opts.knockback
        end

        world:addEntity(entity)
        return entity
    end

    it("moves entity along normalized velocity vector", function()
        local entity = addEntity({
            position = { x = 0, y = 0 },
            speed = 120,
            vx = 1,
            vy = 0,
        })

        movementSystem.update(world, 0.5)

        assert.is_true(entity.position.x > 0)
        assert.equal(0, entity.position.y)
    end)

    it("clamps distance when maxDistance is set", function()
        local entity = addEntity({
            position = { x = 0, y = 0 },
            speed = 200,
            vx = 1,
            vy = 0,
            maxDistance = 5,
        })

        movementSystem.update(world, 0.5)

        assert.is_true(entity.position.x <= 5 + 1e-6)
    end)

    it("applies and then removes knockback after timer expires", function()
        local entity = addEntity({
            position = { x = 0, y = 0 },
            speed = 0,
            vx = 0,
            vy = 0,
            knockback = {
                x = 1,
                y = 0,
                timer = 0.1,
                maxTimer = 0.1,
                strength = 50,
            },
        })

        movementSystem.update(world, 0.05)
        assert.is_true(entity.position.x > 0)
        assert.is_not_nil(entity.knockback)

        movementSystem.update(world, 0.1)
        assert.is_nil(entity.knockback)
    end)

    it("skips inactive entities", function()
        local entity = addEntity({
            position = { x = 0, y = 0 },
            speed = 120,
            vx = 1,
            vy = 0,
        })
        entity.inactive = true

        movementSystem.update(world, 0.5)

        assert.equal(0, entity.position.x)
        assert.equal(0, entity.position.y)
    end)
end)
