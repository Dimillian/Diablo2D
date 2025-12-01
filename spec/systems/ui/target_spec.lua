require("spec.spec_helper")

-- luacheck: globals love rawset rawget _G

local function buildLoveStub()
    return {
        graphics = {
            push = function() end,
            pop = function() end,
            setColor = function() end,
            rectangle = function() end,
            setLineWidth = function() end,
            print = function() end,
            printf = function() end,
            getWidth = function()
                return 800
            end,
            getFont = function()
                return {
                    getHeight = function()
                        return 14
                    end,
                }
            end,
        },
    }
end

rawset(_G, "love", buildLoveStub())

local uiTargetSystem = require("systems.ui.target")
local TestWorld = require("spec.support.test_world")

describe("systems.ui.target", function()
    local world
    local originalLove

    before_each(function()
        originalLove = rawget(_G, "love")
        rawset(_G, "love", buildLoveStub())

        world = TestWorld.new()
        world.camera = { x = 0, y = 0 }
        function world:getPlayer() -- luacheck: ignore 212/self
            return self.player
        end
        local player = {
            id = "player",
            targeting = {},
        }
        world.player = player
        world:addEntity(player)
    end)

    local function addTarget(rarityId)
        local entity = {
            id = "foe_1",
            foe = { rarity = rarityId },
            health = { current = 50, max = 100 },
            position = { x = 0, y = 0 },
            size = { w = 20, h = 20 },
            name = "Test Foe",
        }
        world:addEntity(entity)
        local player = world:getPlayer()
        player.targeting = { currentTargetId = entity.id, keepAlive = 1.5 }
        return entity
    end

    after_each(function()
        rawset(_G, "love", originalLove)
    end)

    it("draws boss frame styling without error", function()
        addTarget("boss")
        uiTargetSystem.draw(world)
    end)

    it("draws elite frame styling without error", function()
        addTarget("elite")
        uiTargetSystem.draw(world)
    end)
end)
