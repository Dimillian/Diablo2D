local helper = require("spec.spec_helper")
local TestWorld = require("spec.support.test_world")

local chaseSystem = require("systems.ai.chase")

describe("systems.ai.chase", function()
    local world
    local player

    local function addFoe(opts)
        opts = opts or {}
        local foe = helper.buildEntity({
            id = opts.id or ("foe_" .. tostring(math.random(1000, 9999))),
            position = opts.position or { x = 0, y = 0 },
            size = opts.size or { w = 32, h = 32 },
            movement = {
                speed = opts.speed or 120,
                vx = 0,
                vy = 0,
            },
            chase = {
                targetId = player.id,
                separationBuffer = opts.separationBuffer,
            },
        })

        world:addEntity(foe)
        return foe
    end

    before_each(function()
        world = TestWorld.new()

        function world:getEntity(id)
            return self.entities[id]
        end

        player = helper.buildEntity({
            id = "player_1",
            position = { x = 200, y = 0 },
            size = { w = 32, h = 32 },
            movement = { speed = 0 },
        })

        world:addEntity(player)
    end)

    it("sets movement toward target while respecting separation buffer", function()
        local foe = addFoe({ position = { x = 0, y = 0 } })

        chaseSystem.update(world, 0.016)

        assert.is_true(foe.movement.vx > 0)
        assert.is_true(math.abs(foe.movement.vy) < 0.01)
        assert.is_true((foe.movement.maxDistance or 0) > 0)
    end)

    it("stops movement when within stop distance", function()
        -- Place foe near player within combined radius + buffer
        local foe = addFoe({ position = { x = 160, y = 0 } })

        chaseSystem.update(world, 0.016)

        assert.equal(0, foe.movement.vx)
        assert.equal(0, foe.movement.vy)
        assert.equal(0, foe.movement.maxDistance)
    end)

    it("applies separation between multiple foes chasing same target", function()
        local upperFoe = addFoe({ id = "foe_upper", position = { x = 0, y = -30 } })
        local lowerFoe = addFoe({ id = "foe_lower", position = { x = 0, y = 30 } })

        chaseSystem.update(world, 0.016)

        assert.is_true(
            upperFoe.movement.vy * lowerFoe.movement.vy < 0,
            "foes should diverge vertically due to separation"
        )
    end)

    it("ignores inactive foes", function()
        local foe = addFoe({ position = { x = 0, y = 0 } })
        foe.inactive = true

        chaseSystem.update(world, 0.016)

        assert.equal(0, foe.movement.vx)
        assert.equal(0, foe.movement.vy)
    end)
end)
